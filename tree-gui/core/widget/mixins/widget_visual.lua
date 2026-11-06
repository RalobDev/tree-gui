--- @class TreeGUI.Widget.VisualState
--- @field offset_x number
--- @field offset_y number
--- @field scale_x number
--- @field scale_y number
--- @field rotation number
--- @field pivot_x number
--- @field pivot_y number

--- @class TreeGUI.Widget
local Widget = {}


--#region Private

--- Apllies the visual transform to the current graphics state.
--- @private
function Widget:_applyVisualTransform()
    local visual = self._visual

    if
        visual.offset_x == 0
        and visual.offset_y == 0
        and visual.rotation == 0
        and visual.scale_x == 1
        and visual.scale_y == 1
    then
        return
    end

    local pivot_x, pivot_y = self._width * visual.pivot_x, self._height * visual.pivot_y

    love.graphics.translate(pivot_x + visual.offset_x, pivot_y + visual.offset_y)
    love.graphics.rotate(visual.rotation)
    love.graphics.scale(visual.scale_x, visual.scale_y)
    love.graphics.translate(-pivot_x, -pivot_y)
end

--#endregion


--#region Setters

--- Returns the visual transform to the defautl (no offset, no scale, no rotation). The pivot is kept.
--- @return self
function Widget:resetVisualTransform()
    local visual = self._visual
    visual.offset_x, visual.offset_y, visual.scale_x, visual.scale_y, visual.rotation = 0, 0, 1, 1, 0
    return self
end

--- Sets the visual offset, in pixels. It does not affect the layout.
--- @param offset_x number
--- @param offset_y number
--- @return self
function Widget:setVisualOffset(offset_x, offset_y)
    self._visual.offset_x, self._visual.offset_y = offset_x, offset_y
    return self
end

--- Sets the X visual offset, in pixels. It does not affect the layout.
--- @param offset_x number
--- @return self
function Widget:setVisualOffsetX(offset_x)
    self._visual.offset_x = offset_x
    return self
end

--- Sets the Y visual offset, in pixels. It does not affect the layout.
--- @param offset_y number
--- @return self
function Widget:setVisualOffsetY(offset_y)
    self._visual.offset_y = offset_y
    return self
end

--- Sets the visual scale. If `scale_y` is omitted, `scale_x` is used on both axis. It does not affect the layout.
--- @param scale_x number
--- @param scale_y number?
--- @return self
function Widget:setVisualScale(scale_x, scale_y)
    self._visual.scale_x, self._visual.scale_y = scale_x, scale_y or scale_x
    return self
end

--- Sets the X visual scale. It does not affect the layout.
--- @param scale_x number
--- @return self
function Widget:setVisualScaleX(scale_x)
    self._visual.scale_x = scale_x
    return self
end

--- Sets the Y visual scale. It does not affect the layout.
--- @param scale_y number
--- @return self
function Widget:setVisualScaleY(scale_y)
    self._visual.scale_y = scale_y
    return self
end

--- Sets the visual rotation, in radians. It does not affect the layout.
--- @param rotation number
--- @return self
function Widget:setVisualRotation(rotation)
    self._visual.rotation = rotation
    return self
end

--- Sets the X pivot of visual scale and visual rotation, as a fraction of the Widget width.
--- @param pivot_x number
--- @return self
function Widget:setVisualPivotX(pivot_x)
    self._visual.pivot_x = pivot_x
    return self
end

--- Sets the Y pivot of visual scale and visual rotation, as a fraction of the Widget height.
--- @param pivot_y number
--- @return self
function Widget:setVisualPivotY(pivot_y)
    self._visual.pivot_y = pivot_y
    return self
end

--#endregion


--#region Getters

--- Returns the visual offset, in pixels.
--- @nodiscard
--- @return number offset_x, number offset_y
function Widget:getVisualOffset()
    return self._visual.offset_x, self._visual.offset_y
end

--- Returns the X visual offset, in pixels.
--- @nodiscard
--- @return number offset_x
function Widget:getVisualOffsetX()
    return self._visual.offset_x
end

--- Returns the Y visual offset, in pixels.
--- @nodiscard
--- @return number offset_y
function Widget:getVisualOffsetY()
    return self._visual.offset_y
end

--- Returns the visual scale.
--- @nodiscard
--- @return number scale_x, number scale_y
function Widget:getVisualScale()
    return self._visual.scale_x, self._visual.scale_y
end

--- Returns the X visual scale.
--- @nodiscard
--- @return number scale_x
function Widget:getVisualScaleX()
    return self._visual.scale_x
end

--- Returns the Y visual scale.
--- @nodiscard
--- @return number scale_y
function Widget:getVisualScaleY()
    return self._visual.scale_y
end

--- Returns the visual rotation, in radians.
--- @nodiscard
--- @return number rotation
function Widget:getVisualRotation()
    return self._visual.rotation
end

--- Returns the X pivot of visual scale and visual rotation, as a fraction of the Widget width.
--- @nodiscard
--- @return number pivot_x
function Widget:getVisualPivotX()
    return self._visual.pivot_x
end

--- Returns the Y pivot of visual scale and visual rotation, as a fraction of the Widget height.
--- @nodiscard
--- @return number pivot_y
function Widget:getVisualPivotY()
    return self._visual.pivot_y
end

--#endregion


return Widget
