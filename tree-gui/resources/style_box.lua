local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Resource = require(ROOT .. ".resources.resource") --- @type TreeGUI.Resource

--- @class TreeGUI.StyleBox: TreeGUI.Resource
--- @field private _color TreeGUI.Color
--- @field private _draw_center boolean
--- @field private _skew_x number
--- @field private _skew_y number
--- @field private _border_width_left number
--- @field private _border_width_top number
--- @field private _border_width_right number
--- @field private _border_width_bottom number
--- @field private _border_color TreeGUI.Color
--- @field private _border_blend boolean
--- @field private _corner_radius_top_left number
--- @field private _corner_radius_top_right number
--- @field private _corner_radius_bottom_right number
--- @field private _corner_radius_bottom_left number
--- @field private _corner_detail number
--- @field private _expand_margin_left number
--- @field private _expand_margin_top number
--- @field private _expand_margin_right number
--- @field private _expand_margin_bottom number
--- @field private _shadow_color TreeGUI.Color
--- @field private _shadow_size number
--- @field private _shadow_offset_x number
--- @field private _shadow_offset_y number
--- @field private _anti_aliasing boolean
--- @field private _anti_aliasing_size number
local StyleBox = Resource:extend("StyleBox")

local SHADER = love.graphics.newShader(ROOT:gsub("%.", "/") .. "/resources/shaders/style_box_shader.glsl")

local PIXEL = (function()
    local data = love.image.newImageData(1, 1)
    data:setPixel(0, 0, 1, 1, 1, 1)
    return love.graphics.newImage(data)
end)()


--#region Definitions

--- @class TreeGUI.StyleBox.Props: TreeGUI.Resource.Props
--- @field color TreeGUI.Color?
--- @field draw_center boolean?
--- @field skew_x number?
--- @field skew_y number?
--- @field borders_width number?
--- @field border_width_left number?
--- @field border_width_top number?
--- @field border_width_right number?
--- @field border_width_bottom number?
--- @field border_color TreeGUI.Color?
--- @field border_blend boolean?
--- @field corners_radius number?
--- @field corner_radius_top_left number?
--- @field corner_radius_top_right number?
--- @field corner_radius_bottom_right number?
--- @field corner_radius_bottom_left number?
--- @field corner_detail number?
--- @field expand_margins number?
--- @field expand_margin_left number?
--- @field expand_margin_top number?
--- @field expand_margin_right number?
--- @field expand_margin_bottom number?
--- @field shadow_color TreeGUI.Color?
--- @field shadow_size number?
--- @field shadow_offset_x number?
--- @field shadow_offset_y number?
--- @field anti_aliasing boolean?
--- @field anti_aliasing_size number?

--#endregion


--#region Local

--- @nodiscard
--- @param t table?
--- @param default table
--- @return table
local function copy4(t, default)
    t = t or default
    return { t[1], t[2], t[3], t[4] }
end

--- @nodiscard
--- @param v number|table
--- @param default table
--- @return table
local function four(v, default)
    if type(v) == "number" then return { v, v, v, v } end
    if type(v) == "table" then return copy4(v, default) end
    return copy4(default, default)
end

--- Reduces the radii proportionally if they do not fit in the rectangle.
--- @nodiscard
--- @param r number[]
--- @param w number
--- @param h number
--- @return table
local function fitRadii(r, w, h)
    local f = 1
    local function chk(sum, len)
        if sum > len and sum > 0 then f = math.min(f, len / sum) end
    end
    chk(r[1] + r[2], w)
    chk(r[4] + r[3], w)
    chk(r[1] + r[4], h)
    chk(r[2] + r[3], h)
    return { r[1] * f, r[2] * f, r[3] * f, r[4] * f }
end

--- @param sh love.Shader
--- @param name string
--- @param value any
local function send(sh, name, value)
    if sh:hasUniform(name) then sh:send(name, value) end
end

--#endregion


--#region Public

--- Instantiates a new StyleBox.
--- @nodiscard
--- @generic T: TreeGUI.StyleBox
--- @param self T
--- @param props TreeGUI.StyleBox.Props?
--- @return T self
function StyleBox:new(props)
    local obj = Resource.new(self) --- @class TreeGUI.StyleBox

    obj._color = { 0.6, 0.6, 0.6, 1 }
    obj._draw_center = true
    obj._skew_x = 0
    obj._skew_y = 0
    obj._border_width_left = 0
    obj._border_width_top = 0
    obj._border_width_right = 0
    obj._border_width_bottom = 0
    obj._border_color = { 0.8, 0.8, 0.8, 1 }
    obj._border_blend = false
    obj._corner_radius_top_left = 0
    obj._corner_radius_top_right = 0
    obj._corner_radius_bottom_right = 0
    obj._corner_radius_bottom_left = 0
    obj._corner_detail = 8
    obj._expand_margin_left = 0
    obj._expand_margin_top = 0
    obj._expand_margin_right = 0
    obj._expand_margin_bottom = 0
    obj._shadow_color = { 0, 0, 0, 0 }
    obj._shadow_size = 0
    obj._shadow_offset_x = 0
    obj._shadow_offset_y = 0
    obj._anti_aliasing = true
    obj._anti_aliasing_size = 1

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.StyleBox.Props
--- @return self
function StyleBox:configure(props)
    self:_checkLock()
    self:_batch(self._applyProps, props)

    Resource.configure(self, props)
    return self
end

--- Draws the StyleBox in the rectangle (x, y, width, height).
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function StyleBox:draw(x, y, width, height)
    local em = {
        self._expand_margin_left,
        self._expand_margin_top,
        self._expand_margin_right,
        self._expand_margin_bottom,
    }
    local bw = {
        self._border_width_left,
        self._border_width_top,
        self._border_width_right,
        self._border_width_bottom,
    }
    local corner_radius = {
        self._corner_radius_top_left,
        self._corner_radius_top_right,
        self._corner_radius_bottom_right,
        self._corner_radius_bottom_left
    }
    local aa = self._anti_aliasing and math.max(self._anti_aliasing_size, 0) or 0

    -- Outer rectangle (with Expand Margins)
    local ox0, oy0 = x - em[1], y - em[2]
    local ox1, oy1 = x + width + em[3], y + height + em[4]
    local ow, oh = ox1 - ox0, oy1 - oy0
    if ow <= 0 or oh <= 0 then return end
    local cx, cy = (ox0 + ox1) / 2, (oy0 + oy1) / 2

    local outerR = fitRadii(corner_radius, ow, oh)

    -- Internal rectangle (discounting the edges). Borderless sides are
    -- "pushed" outwards, so the anti-aliasing of the external shape is never
    -- lets the border color bleed.
    local ext = math.max(aa, 1) + 1
    local ix0 = ox0 + (bw[1] > 0 and bw[1] or -ext)
    local iy0 = oy0 + (bw[2] > 0 and bw[2] or -ext)
    local ix1 = ox1 - (bw[3] > 0 and bw[3] or -ext)
    local iy1 = oy1 - (bw[4] > 0 and bw[4] or -ext)
    local ihx = math.max((ix1 - ix0) / 2, 0)
    local ihy = math.max((iy1 - iy0) / 2, 0)
    local lim = math.min(ihx, ihy)

    local function inner(r, a, b) return math.min(math.max(r - math.max(a, b), 0), lim) end
    local innerR = {
        inner(outerR[1], bw[1], bw[2]), -- TL
        inner(outerR[2], bw[3], bw[2]), -- TR
        inner(outerR[3], bw[3], bw[4]), -- BR
        inner(outerR[4], bw[1], bw[4]), -- BL
    }

    -- Quad large enough to contain shadow, skew and anti-aliasing
    local pad = self._shadow_size
                + math.max(math.abs(self._shadow_offset_x), math.abs(self._shadow_offset_y))
                + math.abs(self._skew_x) + math.abs(self._skew_y)
                + aa + 2
    local qx, qy = ox0 - pad, oy0 - pad
    local qw, qh = ow + pad * 2, oh + pad * 2

    send(SHADER, "quadPos",  { qx, qy })
    send(SHADER, "quadSize", { qw, qh })
    send(SHADER, "bgColor",      self._color)
    send(SHADER, "drawCenter",   self._draw_center and 1 or 0)
    send(SHADER, "skew",         { self._skew_x, self._skew_y })
    send(SHADER, "borderColor",  self._border_color)
    send(SHADER, "borderBlend",  self._border_blend and 1 or 0)
    send(SHADER, "shadowColor",  self._shadow_color)
    send(SHADER, "shadowSize",   self._shadow_size)
    send(SHADER, "shadowOffset", { self._shadow_offset_x, self._shadow_offset_y })
    send(SHADER, "aaSize",       aa)
    send(SHADER, "cornerDetail", math.max(math.floor(self._corner_detail + 0.5), 0))
    send(SHADER, "boxCenter",    { cx, cy })
    send(SHADER, "boxHalf",      { ow / 2, oh / 2 })
    send(SHADER, "outerRadii",   outerR)
    send(SHADER, "innerOffset",  { (ix0 + ix1) / 2 - cx, (iy0 + iy1) / 2 - cy })
    send(SHADER, "innerHalf",    { ihx, ihy })
    send(SHADER, "innerRadii",   innerR)

    local prev = love.graphics.getShader()
    love.graphics.setShader(SHADER)
    love.graphics.draw(PIXEL, qx, qy, 0, qw, qh)
    love.graphics.setShader(prev)
end

--#endregion


--#region Private

--- @private
--- @param props TreeGUI.StyleBox.Props
function StyleBox:_applyProps(props)
    if props.color ~= nil then self:setColorTable(props.color) end
    if props.draw_center ~= nil then self:setDrawCenter(props.draw_center) end
    if props.skew_x ~= nil then self:setSkewX(props.skew_x) end
    if props.skew_y ~= nil then self:setSkewY(props.skew_y) end
    if props.borders_width ~= nil then self:setBordersWidth(props.borders_width) end
    if props.border_width_left ~= nil then self:setBorderWidthLeft(props.border_width_left) end
    if props.border_width_top ~= nil then self:setBorderWidthTop(props.border_width_top) end
    if props.border_width_right ~= nil then self:setBorderWidthRight(props.border_width_right) end
    if props.border_width_bottom ~= nil then self:setBorderWidthBottom(props.border_width_bottom) end
    if props.border_color ~= nil then self:setBorderColorTable(props.border_color) end
    if props.border_blend ~= nil then self:setBorderBlend(props.border_blend) end
    if props.corners_radius ~= nil then self:setCornersRadius(props.corners_radius) end
    if props.corner_radius_top_left ~= nil then self:setCornerRadiusTopLeft(props.corner_radius_top_left) end
    if props.corner_radius_top_right ~= nil then self:setCornerRadiusTopRight(props.corner_radius_top_right) end
    if props.corner_radius_bottom_right ~= nil then self:setCornerRadiusBottomRight(props.corner_radius_bottom_right) end
    if props.corner_radius_bottom_left ~= nil then self:setCornerRadiusBottomLeft(props.corner_radius_bottom_left) end
    if props.corner_detail ~= nil then self:setCornerDetail(props.corner_detail) end
    if props.expand_margins ~= nil then self:setExpandMargins(props.expand_margins) end
    if props.expand_margin_left ~= nil then self:setExpandMarginLeft(props.expand_margin_left) end
    if props.expand_margin_top ~= nil then self:setExpandMarginTop(props.expand_margin_top) end
    if props.expand_margin_right ~= nil then self:setExpandMarginRight(props.expand_margin_right) end
    if props.expand_margin_bottom ~= nil then self:setExpandMarginBottom(props.expand_margin_bottom) end
    if props.shadow_color ~= nil then self:setShadowColorTable(props.shadow_color) end
    if props.shadow_size ~= nil then self:setShadowSize(props.shadow_size) end
    if props.shadow_offset_x ~= nil then self:setShadowOffsetX(props.shadow_offset_x) end
    if props.shadow_offset_y ~= nil then self:setShadowOffsetY(props.shadow_offset_y) end
    if props.anti_aliasing ~= nil then self:setAntiAliasing(props.anti_aliasing) end
    if props.anti_aliasing_size ~= nil then self:setAntiAliasingSize(props.anti_aliasing_size) end
end

--#endregion


--#region Setters

--- Sets the color of the StyleBox.
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
function StyleBox:setColor(r, g, b, a)
    self:_checkLock()
    if self:_writeColor(self._color, r, g, b, a) then
        self:_emitChanged()
    end
end

--- Sets the color of the StyleBox.
--- @param color TreeGUI.Color
function StyleBox:setColorTable(color)
    self:_checkLock()
    self:setColor(unpack(color))
end

--- If `enabled` is `true`, the center of the StyleBox will be drawn.
--- @param enabled boolean?
function StyleBox:setDrawCenter(enabled)
    self:_checkLock()
    enabled = enabled ~= false
    if self._draw_center ~= enabled then
        self._draw_center = enabled
        self:_emitChanged()
    end
end

--- Sets the skew of the StyleBox.
--- @param x number
--- @param y number
function StyleBox:setSkew(x, y)
    self:_checkLock()
    if self._skew_x ~= x or self._skew_y ~= y then
        self._skew_x = x
        self._skew_y = y
        self:_emitChanged()
    end
end

--- Sets the X skew of the StyleBox.
--- @param x number
function StyleBox:setSkewX(x)
    self:_checkLock()
    self:setSkew(x, self._skew_y)
end

--- Sets the Y skew of the StyleBox.
--- @param y number
function StyleBox:setSkewY(y)
    self:_checkLock()
    self:setSkew(self._skew_x, y)
end

--- Sets the border width on all sides.
--- @param width number
function StyleBox:setBordersWidth(width)
    self:_checkLock()
    if
        self._border_width_left ~= width
        or self._border_width_top ~= width
        or self._border_width_right ~= width
        or self._border_width_bottom ~= width
    then
        self._border_width_left = width
        self._border_width_top = width
        self._border_width_right = width
        self._border_width_bottom = width
        self:_emitChanged()
    end
end

--- Sets the left border width.
--- @param width number
function StyleBox:setBorderWidthLeft(width)
    self:_checkLock()
    if self._border_width_left ~= width then
        self._border_width_left = width
        self:_emitChanged()
    end
end

--- Sets the top border width.
--- @param width number
function StyleBox:setBorderWidthTop(width)
    self:_checkLock()
    if self._border_width_top ~= width then
        self._border_width_top = width
        self:_emitChanged()
    end
end

--- Sets the right border width.
--- @param width number
function StyleBox:setBorderWidthRight(width)
    self:_checkLock()
    if self._border_width_right ~= width then
        self._border_width_right = width
        self:_emitChanged()
    end
end

--- Sets the bottom border width.
--- @param width number
function StyleBox:setBorderWidthBottom(width)
    self:_checkLock()
    if self._border_width_bottom ~= width then
        self._border_width_bottom = width
        self:_emitChanged()
    end
end

--- Sets the border color.
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
function StyleBox:setBorderColor(r, g, b, a)
    self:_checkLock()
    if self:_writeColor(self._border_color, r, g, b, a) then
        self:_emitChanged()
    end
end

--- Sets the border color.
--- @param color TreeGUI.Color
function StyleBox:setBorderColorTable(color)
    self:_checkLock()
    self:setBorderColor(unpack(color))
end

--- If `enabled` is `true`, there will be a smooth transition from the border color to the StyleBox color.
--- @param enabled boolean
function StyleBox:setBorderBlend(enabled)
    self:_checkLock()
    enabled = enabled ~= false
    if self._border_blend ~= enabled then
        self._border_blend = enabled
        self:_emitChanged()
    end
end

--- Sets the radius of all corners.
--- @param radius number
function StyleBox:setCornersRadius(radius)
    self:_checkLock()
    if
        self._corner_radius_top_left ~= radius
        or self._corner_radius_top_right ~= radius
        or self._corner_radius_bottom_right ~= radius
        or self._corner_radius_bottom_left ~= radius
    then
        self._corner_radius_top_left = radius
        self._corner_radius_top_right = radius
        self._corner_radius_bottom_right = radius
        self._corner_radius_bottom_left = radius
        self:_emitChanged()
    end
end

--- Sets the radius of the top left corner.
--- @param radius number
function StyleBox:setCornerRadiusTopLeft(radius)
    self:_checkLock()
    if self._corner_radius_top_left ~= radius then
        self._corner_radius_top_left = radius
        self:_emitChanged()
    end
end

--- Sets the radius of the top right corner.
--- @param radius number
function StyleBox:setCornerRadiusTopRight(radius)
    self:_checkLock()
    if self._corner_radius_top_right ~= radius then
        self._corner_radius_top_right = radius
        self:_emitChanged()
    end
end

--- Sets the radius of the bottom right corner.
--- @param radius number
function StyleBox:setCornerRadiusBottomRight(radius)
    self:_checkLock()
    if self._corner_radius_bottom_right ~= radius then
        self._corner_radius_bottom_right = radius
        self:_emitChanged()
    end
end

--- Sets the radius of the bottom left corner.
--- @param radius number
function StyleBox:setCornerRadiusBottomLeft(radius)
    self:_checkLock()
    if self._corner_radius_bottom_left ~= radius then
        self._corner_radius_bottom_left = radius
        self:_emitChanged()
    end
end

--- Sets the level of detail/corner segments.
--- If `detail` is 0, the corners will be a perfectly circular arc.
--- @param detail number
function StyleBox:setCornerDetail(detail)
    self:_checkLock()
    detail = math.max(detail, 0)
    if self._corner_detail ~= detail then
        self._corner_detail = detail
        self:_emitChanged()
    end
end

--- Sets how much the margins on all sides will expand.
--- @param width number
function StyleBox:setExpandMargins(width)
    self:_checkLock()
    if
        self._expand_margin_left ~= width
        or self._expand_margin_top ~= width
        or self._expand_margin_right ~= width
        or self._expand_margin_bottom ~= width
    then
        self._expand_margin_left = width
        self._expand_margin_top = width
        self._expand_margin_right = width
        self._expand_margin_bottom = width
        self:_emitChanged()
    end
end

--- Sets how much the left margin will expand.
--- @param width number
function StyleBox:setExpandMarginLeft(width)
    self:_checkLock()
    if self._expand_margin_left ~= width then
        self._expand_margin_left = width
        self:_emitChanged()
    end
end

--- Sets how much the top margin will expand.
--- @param width number
function StyleBox:setExpandMarginTop(width)
    self:_checkLock()
    if self._expand_margin_top ~= width then
        self._expand_margin_top = width
        self:_emitChanged()
    end
end

--- Sets how much the right margin will expand.
--- @param width number
function StyleBox:setExpandMarginRight(width)
    self:_checkLock()
    if self._expand_margin_right ~= width then
        self._expand_margin_right = width
        self:_emitChanged()
    end
end

--- Sets how much the bottom margin will expand.
--- @param width number
function StyleBox:setExpandMarginBottom(width)
    self:_checkLock()
    if self._expand_margin_bottom ~= width then
        self._expand_margin_bottom = width
        self:_emitChanged()
    end
end

--- Sets the shadow color.
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
function StyleBox:setShadowColor(r, g, b, a)
    self:_checkLock()
    if self:_writeColor(self._shadow_color, r, g, b, a) then
        self:_emitChanged()
    end
end

--- Sets the shadow color.
--- @param color TreeGUI.Color
function StyleBox:setShadowColorTable(color)
    self:_checkLock()
    self:setShadowColor(unpack(color))
end

--- Sets the shadow size.
--- @param size number
function StyleBox:setShadowSize(size)
    self:_checkLock()
    if self._shadow_size ~= size then
        self._shadow_size = size
        self:_emitChanged()
    end
end

--- Sets the shadow offset.
--- @param x number
--- @param y number
function StyleBox:setShadowOffset(x, y)
    self:_checkLock()
    if self._shadow_offset_x ~= x or self._shadow_offset_y ~= y then
        self._shadow_offset_x = x
        self._shadow_offset_y = y
        self:_emitChanged()
    end
end

--- Sets the X shadow offset.
--- @param x number
function StyleBox:setShadowOffsetX(x)
    self:_checkLock()
    self:setShadowOffset(x, self._shadow_offset_y)
end

--- Sets the Y shadow offset.
--- @param y number
function StyleBox:setShadowOffsetY(y)
    self:_checkLock()
    self:setShadowOffset(self._shadow_offset_x, y)
end

--- If `enabled` is `true`, anti-aliasing will be applied to the StyleBox.
--- @param enabled boolean?
function StyleBox:setAntiAliasing(enabled)
    self:_checkLock()
    enabled = enabled ~= false
    if self._anti_aliasing ~= enabled then
        self._anti_aliasing = enabled
        self:_emitChanged()
    end
end

--- Sets the anti-aliasing size.
--- @param size number
function StyleBox:setAntiAliasingSize(size)
    self:_checkLock()
    size = math.max(size, 0)
    if self._anti_aliasing_size ~= size then
        self._anti_aliasing_size = size
        self:_emitChanged()
    end
end

--#endregion


--#region Getters

--- Gets the color of the StyleBox.
--- @nodiscard
--- @return number r, number g, number b, number a
function StyleBox:getColor()
    local color = self._color
    return color[1], color[2], color[3], color[4]
end

--- Gets whether the StyleBox center drawing is enabled.
--- @nodiscard
--- @return boolean enabled
function StyleBox:getDrawCenter()
    return self._draw_center
end

--- Gets the skew of the StyleBox.
--- @nodiscard
--- @return number x, number y
function StyleBox:getSkew()
    return self._skew_x, self._skew_y
end

--- Gets the X skew of the StyleBox.
--- @nodiscard
--- @return number x
function StyleBox:getSkewX()
    return self._skew_x
end

--- Gets the Y skew of the StyleBox.
--- @nodiscard
--- @return number y
function StyleBox:getSkewY()
    return self._skew_y
end

--- Gets the border width on all sides.
--- @nodiscard
--- @return number left_width, number top_width, number right_width, number bottom_width
function StyleBox:getBordersWidth()
    return self._border_width_left,
           self._border_width_top,
           self._border_width_right,
           self._border_width_bottom
end

--- Gets the left border width.
--- @nodiscard
--- @return number width
function StyleBox:getBorderWidthLeft()
    return self._border_width_left
end

--- Gets the top border width.
--- @nodiscard
--- @return number width
function StyleBox:getBorderWidthTop()
    return self._border_width_top
end

--- Gets the right border width.
--- @nodiscard
--- @return number width
function StyleBox:getBorderWidthRight()
    return self._border_width_right
end

--- Gets the bottom border width.
--- @nodiscard
--- @return number width
function StyleBox:getBorderWidthBottom()
    return self._border_width_bottom
end

--- Gets the border color.
--- @nodiscard
--- @return number r, number g, number b, number a
function StyleBox:getBorderColor()
    local color = self._border_color
    return color[1], color[2], color[3], color[4]
end

--- Gets whether border blending is on.
--- If `true`, then there is a smooth transition from the border color to the StyleBox color.
--- @nodiscard
--- @return boolean enabled
function StyleBox:getBorderBlend()
    return self._border_blend
end

--- Gets the radius of all corners.
--- @nodiscard
--- @return number top_left_radius, number top_right_radius, number bottom_right_radius, number bottom_left_radius
function StyleBox:getCornersRadius()
    return self._corner_radius_top_left,
           self._corner_radius_top_right,
           self._corner_radius_bottom_right,
           self._corner_radius_bottom_left
end


--- Gets the radius of the top left corner.
--- @nodiscard
--- @return number radius
function StyleBox:getCornerRadiusTopLeft()
    return self._corner_radius_top_left
end

--- Gets the radius of the top right corner.
--- @nodiscard
--- @return number radius
function StyleBox:getCornerRadiusTopRight()
    return self._corner_radius_top_right
end

--- Gets the radius of the bottom right corner.
--- @nodiscard
--- @return number radius
function StyleBox:getCornerRadiusBottomRight()
    return self._corner_radius_bottom_right
end

--- Gets the radius of the bottom left corner.
--- @nodiscard
--- @return number radius
function StyleBox:getCornerRadiusBottomLeft()
    return self._corner_radius_bottom_left
end

--- Gets the level of detail/corner segments.
--- If `detail` is 0, the corners will be a perfectly circular arc.
--- @return number detail
function StyleBox:getCornerDetail()
    return self._corner_detail
end

--- Gets how much the margins on all sides will expand.
--- @nodiscard
--- @return number left_width, number top_width, number right_width, number bottom_width
function StyleBox:getExpandMargins()
    return self._expand_margin_left,
           self._expand_margin_top,
           self._expand_margin_right,
           self._expand_margin_bottom
end

--- Gets how much the left margin will expand.
--- @nodiscard
--- @return number width
function StyleBox:getExpandMarginLeft()
    return self._expand_margin_left
end

--- Gets how much the top margin will expand.
--- @nodiscard
--- @return number width
function StyleBox:getExpandMarginTop()
    return self._expand_margin_top
end

--- Gets how much the right margin will expand.
--- @nodiscard
--- @return number width
function StyleBox:getExpandMarginRight()
    return self._expand_margin_right
end

--- Gets how much the bottom margin will expand.
--- @nodiscard
--- @return number width
function StyleBox:getExpandMarginBottom()
    return self._expand_margin_bottom
end

--- Gets the shadow color.
--- @nodiscard
--- @return number r, number g, number b, number a
function StyleBox:getShadowColor()
    local color = self._shadow_color
    return color[1], color[2], color[3], color[4]
end

--- Gets the shadow size.
--- @nodiscard
--- @return number size
function StyleBox:getShadowSize()
    return self._shadow_size
end

--- Gets the shadow offset.
--- @nodiscard
--- @return number x, number y
function StyleBox:getShadowOffset()
    return self._shadow_offset_x, self._shadow_offset_y
end

--- Gets the X shadow offset.
--- @nodiscard
--- @return number x
function StyleBox:getShadowOffsetX()
    return self._shadow_offset_x
end

--- Gets the Y shadow offset.
--- @nodiscard
--- @return number y
function StyleBox:getShadowOffsetY()
    return self._shadow_offset_y
end

--- If `enabled` is `true`, anti-aliasing will be applied to the StyleBox.
--- @nodiscard
--- @return boolean enabled
function StyleBox:getAntiAliasing()
    return self._anti_aliasing
end

--- Gets the anti-aliasing size.
--- @nodiscard
--- @return number size
function StyleBox:getAntiAliasingSize()
    return self._anti_aliasing_size
end

--#endregion


return StyleBox
