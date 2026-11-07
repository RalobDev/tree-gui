local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 4) .. "$") --- @type string

local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.Widget
local Widget = {}


--#region Local

--- Converts desired position/size of an axis into offsets (inverse of Layout.anchorAxis).
--- `pos` and `size` nil maintain the current value, calculated from the offsets.
--- @nodiscard
--- @param pos number?
--- @param size number?
--- @param parent_size number?
--- @param margin_begin number
--- @param margin_end number
--- @param anchor_begin number
--- @param anchor_end number
--- @param offset_begin number
--- @param offset_end number
--- @return number offset_begin, number offset_end
local function rectToOffsets(pos, size, parent_size, margin_begin, margin_end, anchor_begin, anchor_end, offset_begin, offset_end)
    local area = math.max(0, parent_size - margin_begin - margin_end)
    local begin_pos = area * anchor_begin + offset_begin
    local end_pos = area * anchor_end + offset_end

    if pos == nil then pos = begin_pos + margin_begin end
    if size == nil then size = end_pos - begin_pos end

    local b = pos - margin_begin
    return b - area * anchor_begin, b + size - area * anchor_end
end

--#endregion


--#region Public

--- Converts global screen coordinates into local coordinates relative to this Widget.
--- @param x number
--- @param y number
--- @return number localX
--- @return number localY
function Widget:toLocal(x, y)
    local gx, gy = self:getGlobalPosition()
    return x - gx, y - gy
end

--- Converts local coordinates relative to this Widget into global screen coordinates.
--- @nodiscard
--- @param x number
--- @param y number
--- @return number globalX
--- @return number globalY
function Widget:toGlobal(x, y)
    local gx, gy = self:getGlobalPosition()
    return gx + x, gy + y
end

--#endregion


--#region Protected

--- @protected
--- @param x number?
--- @param y number?
--- @param width number?
--- @param height number?
function Widget:_setRect(x, y, width, height)
    local changed = false

    if self._layout_mode == Enums.LayoutMode.ANCHOR then
        local pw, ph = self:_getReferenceSize()
        if pw then
            changed = self:_applyAnchoredRect(x, y, width, height, pw, ph)
        else
            -- Not attached yet: keep the request until the first layout.
            local r = self._pending_rect or {}
            r.x, r.y, r.w, r.h = x or r.x, y or r.y, width or r.w, height or r.h
            self._pending_rect = r
            return
        end
    else -- POSITION
        if x ~= nil and x ~= self._x then self._x, changed = x, true end
        if y ~= nil and y ~= self._y then self._y, changed = y, true end
        if width ~= nil and width ~= self._width then self._width, changed = width, true end
        if height ~= nil and height ~= self._height then self._height, changed = height, true end
    end

    if changed then self:_queueLayout() end
end

--- Converts the requested rectangle into offsets. `nil` holds the current value of the axis.
--- @protected
--- @param x number?
--- @param y number?
--- @param width number?
--- @param height number?
--- @param parent_width number?
--- @param parent_height number?
--- @return boolean changed
function Widget:_applyAnchoredRect(x, y, width, height, parent_width, parent_height)
    local margin_left = self:getStyleValue("margin_left")
    local margin_right = self:getStyleValue("margin_right")
    local margin_top = self:getStyleValue("margin_top")
    local margin_bottom = self:getStyleValue("margin_bottom")

    local left, right = rectToOffsets(
        x, width, parent_width, margin_left, margin_right,
        self._anchor_left, self._anchor_right, self._offset_left, self._offset_right
    )
    local top, bottom = rectToOffsets(
        y, height, parent_height, margin_top, margin_bottom,
        self._anchor_top, self._anchor_bottom, self._offset_top, self._offset_bottom
    )

    local changed = left ~= self._offset_left or right ~= self._offset_right
        or top ~= self._offset_top or bottom ~= self._offset_bottom

    self._offset_left, self._offset_right = left, right
    self._offset_top, self._offset_bottom = top, bottom

    return changed
end

--#endregion


--#region Setters

--- Sets the local X and Y position of the Widget relative to its parent.
--- @param x number
--- @param y number
function Widget:setPosition(x, y)
    self:_setRect(x, y, nil, nil)
end

--- Sets the local X position of the Widget relative to its parent.
--- @param x number
function Widget:setX(x)
    self:_setRect(x, nil, nil, nil)
end

--- Sets the local Y position of the Widget relative to its parent.
--- @param y number
function Widget:setY(y)
    self:_setRect(nil, y, nil, nil)
end

--- Sets the absolute position of the Widget in global screen space.
--- Automatically converts global coordinates into local space based on the parent's global position.
--- @param gx number
--- @param gy number
function Widget:setGlobalPosition(gx, gy)
    local px, py = 0, 0

    if self._parent then
        px, py = self._parent:getGlobalPosition()
    end
    self:setPosition(gx - px, gy - py)
end

--- Sets the absolute X position of the Widget in global screen space while preserving its global Y position.
--- @param gx number
function Widget:setGlobalX(gx)
    self:setGlobalPosition(gx, self:getGlobalY())
end

--- Sets the absolute Y position of the Widget in global screen space while preserving its global X position.
--- @param gy number
function Widget:setGlobalY(gy)
    self:setGlobalPosition(self:getGlobalX(), gy)
end

--- Sets the dimensions of the Widget.
--- @param width number
--- @param height number
function Widget:setDimensions(width, height)
    self:_setRect(nil, nil, width, height)
end

--- Sets the width of the Widget.
--- @param width number
function Widget:setWidth(width)
    self:_setRect(nil, nil, width, nil)
end

--- Sets the height of the Widget.
--- @param height number
function Widget:setHeight(height)
    self:_setRect(nil, nil, nil, height)
end

--- Sets the minimum dimensions of the Widget.
--- @param min_width number
--- @param min_height number
function Widget:setMinimumDimensions(min_width, min_height)
    if min_width ~= self._min_width or min_height ~= self._min_height then
        self._min_width, self._min_height = min_width, min_height
        self:_queueLayout()
    end
end

--- Sets the minimum width of the Widget.
--- @param min_width number
function Widget:setMinimumWidth(min_width)
    self:setMinimumDimensions(min_width, self._min_height)
end

--- Sets the minimum height of the Widget.
--- @param min_height number
function Widget:setMinimumHeight(min_height)
    self:setMinimumDimensions(self._min_width, min_height)
end

--#endregion


--#region Getters

--- Gets the local position of the Widget relative to its parent.
--- @nodiscard
--- @return number x, number y
function Widget:getPosition()
    return self._x, self._y
end

--- Gets the local X position of the Widget relative to its parent.
--- @nodiscard
--- @return number x
function Widget:getX()
    return self._x
end

--- Gets the local Y position of the Widget relative to its parent.
--- @nodiscard
--- @return number y
function Widget:getY()
    return self._y
end

--- Calculates the absolute position of the Widget in global screen coordinates
--- by walking up the parent tree.
--- @nodiscard
--- @return number gx, number gy
function Widget:getGlobalPosition()
    local gx, gy = self._x, self._y
    local current = self._parent

    while current do
        gx = gx + current._x
        gy = gy + current._y
        current = current._parent
    end
    return gx, gy
end

--- Calculates the absolute X position of the Widget in global screen coordinates.
--- @nodiscard
--- @return number gx
function Widget:getGlobalX()
    local gx, _ = self:getGlobalPosition()
    return gx
end

--- Calculates the absolute Y position of the Widget in global screen coordinates.
--- @nodiscard
--- @return number gy
function Widget:getGlobalY()
    local _, gy = self:getGlobalPosition()
    return gy
end

--- Gets the current width and height of the Widget in pixels.
--- @nodiscard
--- @return number width, number height
function Widget:getDimensions()
    return self._width, self._height
end

--- Gets the current width of the Widget in pixels.
--- @nodiscard
--- @return number width
function Widget:getWidth()
    return self._width
end

--- Gets the current height of the Widget in pixels.
--- @nodiscard
--- @return number height
function Widget:getHeight()
    return self._height
end

--- Gets the minimum dimensions of the Widget in pixels.
--- @nodiscard
--- @return number min_width, number min_height
function Widget:getMinimumDimensions()
    return self._min_width, self._min_height
end

--- Gets the minimum width of the Widget in pixels.
--- @nodiscard
--- @return number min_width
function Widget:getMinimumWidth()
    return self._min_width
end

--- Gets the minimum height of the Widget in pixels.
--- @nodiscard
--- @return number min_height
function Widget:getMinimumHeight()
    return self._min_height
end

--#endregion


return Widget
