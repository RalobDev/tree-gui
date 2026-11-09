--- Text measuring and drawing shared by Label, Button...
--- @class TreeGUI.Text
local Text = {}

--- @type table<TreeGUI.Enums.TextAlignmentHorizontal, love.AlignMode>
local H_ALIGN = { BEGIN = "left", CENTER = "center", END = "right", JUSTIFY = "justify" }

--- Fraction of the free space placed before the text block.
--- @type table<TreeGUI.Enums.TextAlignmentHorizontal, number>
local H_FACTOR = { BEGIN = 0, CENTER = 0.5, END = 1, JUSTIFY = 0 }

--- @type table<TreeGUI.Enums.TextAlignmentVertical, number>
local V_FACTOR = { BEGIN = 0, CENTER = 0.5, END = 1 }


--#region Definitions

--- @alias TreeGUI.Text.MeasureCache { font: love.Font, text: string, limit: number, width: number, height: number }

--#endregion


--#region Public

--- Size of `text` for a font and wrap limit (`math.huge` = no wrap).
--- `cache` is a table owned by the caller (one per widget); it keeps the last result,
--- since this is requested on every layout and every draw.
--- @param cache TreeGUI.Text.MeasureCache
--- @param font love.Font
--- @param text string
--- @param limit number
--- @return number width, number height
function Text.measure(cache, font, text, limit)
    if cache.font == font and cache.text == text and cache.limit == limit then
        return cache.width, cache.height
    end

    local width, lines = font:getWrap(text, limit)
    local line_height = font:getHeight()
    local height = line_height * font:getLineHeight() * (math.max(#lines, 1) - 1) + line_height

    cache.font, cache.text, cache.limit, cache.width, cache.height = font, text, limit, width, height
    return width, height
end

--- Draws `text` aligned inside the rect (x, y, width, height), in the current transform.
--- Does NOT set the color: call Render.setColor before.
--- Without `wrap`, the text block is positioned as a whole, so overflow stays aligned too.
--- @param text string
--- @param font love.Font
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param align_h TreeGUI.Enums.TextAlignmentHorizontal
--- @param align_v TreeGUI.Enums.TextAlignmentVertical
--- @param wrap boolean
--- @param text_width number Result of `measure` (for the same text/limit).
--- @param text_height number
function Text.draw(text, font, x, y, width, height, align_h, align_v, wrap, text_width, text_height)
    local block_width = wrap and width or text_width

    -- Floored to avoid blurry text.
    local bx = math.floor(x + (width - block_width) * H_FACTOR[align_h])
    local by = math.floor(y + math.max(0, height - text_height) * V_FACTOR[align_v])

    love.graphics.printf(text, font, bx, by, block_width, H_ALIGN[align_h])
end

--#endregion


return Text
