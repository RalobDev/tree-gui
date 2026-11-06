local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

--- @class TreeGUI.DebugDraw
--- @field layers {margin: boolean, padding: boolean, content: boolean, anchors: boolean, hover: boolean, focus: boolean}
local DebugDraw = {}

local COLORS = {
    margin = { 0.97, 0.62, 0.25 },
    padding = { 0.35, 0.78, 0.45 },
    content = { 0.30, 0.55, 1.00 },
    anchor = { 0.95, 0.30, 0.75 },
    hover = { 1.00, 0.85, 0.20 },
    focus = { 0.20, 0.90, 0.95 },
}

local FILL_ALPHA = 0.28
local FONT = love.graphics.newFont(ROOT:gsub("%.", "/") .. "/fonts/ProggyVector-Regular.ttf", 16)

--- @enum (key) TreeGUI.DebugDraw.Layers
DebugDraw.layers = { margin = true, padding = true, content = true, anchors = true, hover = true, focus = true }


--#region Local

--- Sets the color of the graphic state.
--- @param kind string
--- @param alpha number
local function setColor(kind, alpha)
    local c = COLORS[kind]
    love.graphics.setColor(c[1], c[2], c[3], alpha)
end

--- Write the text centered in an area, ignoring it if it doesn't fit.
--- @param text string
--- @param x number
--- @param y number
--- @param width number
--- @param height number
local function label(text, x, y, width, height)
    local tw, th = FONT:getWidth(text), FONT:getHeight()

    -- If the text is larger than the rectangle, it is not drawn.
    if tw > width or th > height then return end

    love.graphics.print(text, math.floor(x + (width - tw) / 2), math.floor(y + (height - th) / 2))
end

--- Draw the shape of a diamond.
--- @param x number
--- @param y number
--- @param radius number
local function diamond(x, y, radius)
    love.graphics.polygon("fill", x, y - radius, x + radius, y, x, y + radius, x - radius, y)
end

--#endregion


--#region Public

--- Draws a dashed line.
--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @param dash number?
--- @param gap number?
function DebugDraw.dashedLine(x1, y1, x2, y2, dash, gap)
    dash, gap = dash or 4, gap or 3
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return end

    local ux, uy = dx / len, dy / len
    local pos = 0
    while pos < len do
        local stop = math.min(pos + dash, len)
        love.graphics.line(x1 + ux * pos, y1 + uy * pos, x1 + ux * stop, y1 + uy * stop)
        pos = pos + dash + gap
    end
end

--- Draws a dashed rectangle.
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function DebugDraw.dashedRect(x, y, width, height)
    DebugDraw.dashedLine(x, y, x + width, y)
    DebugDraw.dashedLine(x + width, y, x + width, y + height)
    DebugDraw.dashedLine(x + width, y + height, x, y + height)
    DebugDraw.dashedLine(x, y + height, x, y)
end

--- Draws the frame between an outer and inner rectangle (margin or padding)
--- @param kind "margin"|"padding"
--- @param ox number
--- @param oy number
--- @param ow number
--- @param oh number
--- @param ix number
--- @param iy number
--- @param iw number
--- @param ih number
--- @param outline_inner boolean?
function DebugDraw.drawFrame(kind, ox, oy, ow, oh, ix, iy, iw, ih, outline_inner)
    local top, left = iy - oy, ix - ox
    local bottom, right = (oy + oh) - (iy + ih), (ox + ow) - (ix + iw)
    if top <= 0 and left <= 0 and bottom <= 0 and right <= 0 then return end

    local pr, pg, pb, pa = love.graphics.getColor()
    local prev_font = love.graphics.getFont()
    love.graphics.setFont(FONT)

    -- Padding: top and base occupy the entire width, left and right only the middle strip.
    setColor(kind, FILL_ALPHA)
    if top > 0 then love.graphics.rectangle("fill", ox, oy, ow, top) end
    if bottom > 0 then love.graphics.rectangle("fill", ox, iy + ih, ow, bottom) end
    if left > 0 then love.graphics.rectangle("fill", ox, iy, left, ih) end
    if right > 0 then love.graphics.rectangle("fill", ix + iw, iy, right, ih) end

    -- Outline.
    setColor(kind, 0.8)
    if outline_inner then
        DebugDraw.dashedRect(ix + 0.5, iy + 0.5, math.max(iw - 1, 0), math.max(ih - 1, 0))
    else
        love.graphics.rectangle("line", ox + 0.5, oy + 0.5, math.max(ow - 1, 0), math.max(oh - 1, 0))
    end

    -- Values.
    setColor(kind, 1)
    if top > 0 then label(string.format("%g", top), ox, oy, ow, top) end
    if bottom > 0 then label(string.format("%g", bottom), ox, iy + ih, ow, bottom) end
    if left > 0 then label(string.format("%g", left), ox, iy, left, ih) end
    if right > 0 then label(string.format("%g", right), ix + iw, iy, right, ih) end

    love.graphics.setFont(prev_font)
    love.graphics.setColor(pr, pg, pb, pa)
end

--- Draws the content rectangle, an X when a dimension is zero, and the size in the corner.
--- @param width number
--- @param height number
function DebugDraw.drawContent(width, height)
    local pr, pg, pb, pa = love.graphics.getColor()
    setColor("content", 1)

    if width > 0 and height > 0 then
        love.graphics.rectangle("line", 0.5, 0.5, math.max(width - 1, 0), math.max(height - 1, 0))
    else
        -- Zero dimension: the rectangle disappears, then mark the position with an X.
        local size = 6
        love.graphics.line(-size, -size, size, size)
        love.graphics.line(-size, size, size, -size)
    end

    love.graphics.setColor(pr, pg, pb, pa)
end

--- Draw the anchors.
--- @param ax1 number
--- @param ay1 number
--- @param ax2 number
--- @param ay2 number
--- @param wx number
--- @param wy number
--- @param ww number
--- @param wh number
function DebugDraw.drawAnchors(ax1, ay1, ax2, ay2, wx, wy, ww, wh)
    local pr, pg, pb, pa = love.graphics.getColor()

    setColor("anchor", 0.8)
    DebugDraw.dashedRect(ax1, ay1, ax2 - ax1, ay2 - ay1)

    setColor("anchor", 0.45)
    love.graphics.line(ax1, ay1, wx, wy)
    love.graphics.line(ax2, ay1, wx + ww, wy)
    love.graphics.line(ax2, ay2, wx + ww, wy + wh)
    love.graphics.line(ax1, ay2, wx, wy + wh)

    setColor("anchor", 1)
    diamond(ax1, ay1, 4)
    diamond(ax2, ay1, 4)
    diamond(ax2, ay2, 4)
    diamond(ax1, ay2, 4)

    love.graphics.setColor(pr, pg, pb, pa)
end

--- Draws the hover/focus highlight over a rectangle (in the current coordinate space).
--- @param kind "hover"|"focus"
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param text string?
--- @param tag_above boolean?
function DebugDraw.drawHighlight(kind, x, y, width, height, text, tag_above)
    local pr, pg, pb, pa = love.graphics.getColor()
    local prev_width = love.graphics.getLineWidth()

    if kind == "hover" then
        setColor("hover", 0.15)
        love.graphics.rectangle("fill", x, y, width, height)

        setColor("hover", 0.9)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", x + 0.5, y + 0.5, math.max(width - 1, 0), math.max(height - 1, 0))
    else
        -- Drawn outside the rectangle so it does not hide the hover outline.
        setColor("focus", 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x - 2, y - 2, width + 4, height + 4)
    end

    love.graphics.setLineWidth(prev_width)
    love.graphics.setColor(pr, pg, pb, pa)
end

--#endregion


return DebugDraw
