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


--#region Definitions

--- @class TreeGUI.StyleBox.Props
--- @field color TreeGUI.Color?
--- @field draw_center boolean?
--- @field skew_x number?
--- @field skew_y number?
--- @field border_width_left number?
--- @field border_width_top number?
--- @field border_width_right number?
--- @field border_width_bottom number?
--- @field border_color TreeGUI.Color?
--- @field border_blend boolean?
--- @field corner_radius_top_left number?
--- @field corner_radius_top_right number?
--- @field corner_radius_bottom_right number?
--- @field corner_radius_bottom_left number?
--- @field corner_detail number?
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
function StyleBox:configure(props)
    self:_batch(self._applyProps, props)
end

--#endregion


--#region Private

--- @private
--- @param props TreeGUI.StyleBox.Props
function StyleBox:_applyProps(props)
    -- Apply properties with setters.
end

--#endregion


--#region Setters

--- Sets the color of the StyleBox.
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
function StyleBox:setColor(r, g, b, a)
    local color = self._color
    if
        color[1] ~= r
        or color[2] ~= g
        or color[3] ~= b
        or color[4] ~= a
    then
        color[1], color[2], color[3], color[4] = r, g, b, a or 1
        self:_emitChanged()
    end
end

--- Sets the color of the StyleBox.
--- @param color TreeGUI.Color
function StyleBox:setColorTable(color)
    self:setColor(unpack(color))
end

--- If `enabled` is `true`, the center of the StyleBox will be drawn.
--- @param enabled boolean?
function StyleBox:setDrawCenter(enabled)
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
    if self._skew_x ~= x or self._skew_y ~= y then
        self._skew_x = x
        self._skew_y = y
        self:_emitChanged()
    end
end

--- Sets the X skew of the StyleBox.
--- @param x number
function StyleBox:setSkewX(x)
    self:setSkew(x, self._skew_y)
end

--- Sets the Y skew of the StyleBox.
--- @param y number
function StyleBox:setSkewY(y)
    self:setSkew(self._skew_x, y)
end

--- Sets the border width on all sides.
--- @param width number
function StyleBox:setBordersWidth(width)
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
    if self._border_width_left ~= width then
        self._border_width_left = width
        self:_emitChanged()
    end
end

--- Sets the top border width.
--- @param width number
function StyleBox:setBorderWidthTop(width)
    if self._border_width_top ~= width then
        self._border_width_top = width
        self:_emitChanged()
    end
end

--- Sets the right border width.
--- @param width number
function StyleBox:setBorderWidthRight(width)
    if self._border_width_right ~= width then
        self._border_width_right = width
        self:_emitChanged()
    end
end

--- Sets the bottom border width.
--- @param width number
function StyleBox:setBorderWidthBottom(width)
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
    local color = self._border_color
    if
        color[1] ~= r
        or color[2] ~= g
        or color[3] ~= b
        or color[4] ~= a
    then
        color[1], color[2], color[3], color[4] = r, g, b, a or 1
        self:_emitChanged()
    end
end

--- Sets the border color.
--- @param color TreeGUI.Color
function StyleBox:setBorderColorTable(color)
    self:setColor(unpack(color))
end

--- If `enabled` is `true`, there will be a smooth transition from the border color to the StyleBox color.
--- @param enabled boolean
function StyleBox:setBorderBlend(enabled)
    enabled = enabled ~= false
    if self._border_blend ~= enabled then
        self._border_blend = enabled
        self:_emitChanged()
    end
end

--- Sets the radius of all corners.
--- @param radius number
function StyleBox:setCornersRadius(radius)
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
    if self._corner_radius_top_left ~= radius then
        self._corner_radius_top_left = radius
        self:_emitChanged()
    end
end

--- Sets the radius of the top right corner.
--- @param radius number
function StyleBox:setCornerRadiusTopRight(radius)
    if self._corner_radius_top_right ~= radius then
        self._corner_radius_top_right = radius
        self:_emitChanged()
    end
end

--- Sets the radius of the bottom right corner.
--- @param radius number
function StyleBox:setCornerRadiusBottomRight(radius)
    if self._corner_radius_bottom_right ~= radius then
        self._corner_radius_bottom_right = radius
        self:_emitChanged()
    end
end

--- Sets the radius of the bottom left corner.
--- @param radius number
function StyleBox:setCornerRadiusBottomLeft(radius)
    if self._corner_radius_bottom_left ~= radius then
        self._corner_radius_bottom_left = radius
        self:_emitChanged()
    end
end

--- Sets the level of detail/corner segments.
--- If `detail` is 0, the corners will be a perfectly circular arc.
--- @param detail number
function StyleBox:setCornerDetail(detail)
    detail = math.max(detail, 0)
    if self._corner_detail ~= detail then
        self._corner_detail = detail
        self:_emitChanged()
    end
end

--- Sets how much the margins on all sides will expand.
--- @param width number
function StyleBox:setExpandMargins(width)
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
    if self._expand_margin_left ~= width then
        self._expand_margin_left = width
        self:_emitChanged()
    end
end

--- Sets how much the top margin will expand.
--- @param width number
function StyleBox:setExpandMarginTop(width)
    if self._expand_margin_top ~= width then
        self._expand_margin_top = width
        self:_emitChanged()
    end
end

--- Sets how much the right margin will expand.
--- @param width number
function StyleBox:setExpandMarginRight(width)
    if self._expand_margin_right ~= width then
        self._expand_margin_right = width
        self:_emitChanged()
    end
end

--- Sets how much the bottom margin will expand.
--- @param width number
function StyleBox:setExpandMarginBottom(width)
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
    local color = self._shadow_color
    if
        color[1] ~= r
        or color[2] ~= g
        or color[3] ~= b
        or color[4] ~= a
    then
        color[1], color[2], color[3], color[4] = r, g, b, a or 1
        self:_emitChanged()
    end
end

--- Sets the shadow color.
--- @param color TreeGUI.Color
function StyleBox:setShadowColorTable(color)
    self:setColor(unpack(color))
end

--- Sets the shadow size.
--- @param size number
function StyleBox:setShadowSize(size)
    if self._shadow_size ~= size then
        self._shadow_size = size
        self:_emitChanged()
    end
end

--- Sets the shadow offset.
--- @param x number
--- @param y number
function StyleBox:setShadowOffset(x, y)
    if self._shadow_offset_x ~= x or self._shadow_offset_y ~= y then
        self._shadow_offset_x = x
        self._shadow_offset_y = y
        self:_emitChanged()
    end
end

--- Sets the X shadow offset.
--- @param x number
function StyleBox:setShadowOffsetX(x)
    self:setShadowOffset(x, self._shadow_offset_y)
end

--- Sets the Y shadow offset.
--- @param y number
function StyleBox:setShadowOffsetY(y)
    self:setShadowOffset(self._shadow_offset_x, y)
end

--- If `enabled` is `true`, anti-aliasing will be applied to the StyleBox.
--- @param enabled boolean?
function StyleBox:setAntiAliasing(enabled)
    enabled = enabled ~= false
    if self._anti_aliasing ~= enabled then
        self._anti_aliasing = enabled
        self:_emitChanged()
    end
end

--- Sets the anti-aliasing size.
--- @param size number
function StyleBox:setAntiAliasingSize(size)
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
