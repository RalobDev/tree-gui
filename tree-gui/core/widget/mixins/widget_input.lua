--- @diagnostic disable: invisible

--- @class TreeGUI.Widget
local Widget = {}

local FOCUS_PROPS = {
    left = "focus_neighbor_left",
    top = "focus_neighbor_top",
    right = "focus_neighbor_right",
    bottom = "focus_neighbor_bottom",
    next = "focus_next",
    previous = "focus_previous",
}


--#region Public

--- Make the Widget receive all mouse press/release/move events, even if the mouse is outside of it.
function Widget:captureMouse()
    if self._tree then self._tree:_setMouseCapture(self) end
end

--- Makes the Widget stop capturing the mouse.
function Widget:releaseMouse()
    local tree = self._tree
    if tree and tree:getMouseCapture() == self then
        tree:_setMouseCapture(nil)
    end
end

function Widget:grabFocus()
    if self._tree and self._focus_mode ~= "NONE" and self:isVisibleInTree() then
        self._tree:setFocusOwner(self)
    end
end

function Widget:releaseFocus()
    local tree = self._tree
    if tree and tree:getFocusOwner() == self then
        tree:setFocusOwner(nil)
    end
end

--#endregion


--#region Protected

--- @protected
--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
--- @param presses number
--- @return boolean consumed
function Widget:_onMousePressed(x, y, button, istouch, presses) return false end

--- @protected
--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
--- @param presses number
--- @return boolean consumed
function Widget:_onMouseReleased(x, y, button, istouch, presses) return false end

--- @protected
--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
--- @param istouch boolean
--- @return boolean consumed
function Widget:_onMouseMoved(x, y, dx, dy, istouch) return false end

--- @protected
--- @param x number
--- @param y number
--- @param wheel_x number
--- @param wheel_y number
--- @return boolean consumed
function Widget:_onWheelMoved(x, y, wheel_x, wheel_y) return false end

--- @protected
--- @param key love.KeyConstant
--- @param scancode love.Scancode
--- @param isrepeat boolean
--- @return boolean consumed
function Widget:_onKeyPressed(key, scancode, isrepeat) return false end

--- @protected
--- @param key love.KeyConstant
--- @param scancode love.Scancode
--- @return boolean consumed
function Widget:_onKeyReleased(key, scancode) return false end

--- @protected
function Widget:_onMouseEntered() end

--- @protected
function Widget:_onMouseExited() end

--- @protected
function Widget:_onFocusEntered() end

--- @protected
function Widget:_onFocusExited() end

--#endregion


--#region Private

--- @private
--- @param props TreeGUI.Widget.Props
function Widget:_configureInput(props)
    if props.mouse_filter then self._mouse_filter = props.mouse_filter end
    if props.focus_mode then self._focus_mode = props.focus_mode end

    for side, prop in pairs(FOCUS_PROPS) do
        if props[prop] then self._focus_neighbors[side] = props[prop] end
    end
end

--- Finds the top-most Widget under (x, y). Coordinates are relative to the PARENT's origin.
--- Uses the real rect (_x, _y, _width, _height), never the visual transform.
--- @private
--- @param x number
--- @param y number
--- @return TreeGUI.Widget?
function Widget:_pickInput(x, y)
    if not self._visible or self._opacity <= 0 then return nil end

    local lx, ly = x - self._x, y - self._y
    local inside = lx >= 0 and ly >= 0 and lx < self._width and ly < self._height

    -- Clipped content is invisible outside the rect, so it cannot be picked there either.
    if self._clip_content and not inside then return nil end

    for i = #self._children, 1, -1 do
        local hit = self._children[i]:_pickInput(lx, ly)
        if hit then return hit end
    end

    if inside and self._mouse_filter ~= "IGNORE" then
        return self
    end
    return nil
end

--- Converts tree-space coords to local and calls a mouse handler.
--- @private
--- @param handler string
--- @param tx number
--- @param ty number
--- @param ... any
--- @return boolean consumed
function Widget:_receiveMouse(handler, tx, ty, ...)
    local lx, ly = self:toLocal(tx, ty)
    return self[handler](self, lx, ly, ...) == true
end

--- Releases focus, capture and hover of this Widget and its descendants.
--- @private
function Widget:_releaseInputState()
    local tree = self._tree
    if not tree then return end

    tree:_onWidgetLeaving(self)
    for _, child in ipairs(self._children) do
        child:_releaseInputState()
    end
end

--#endregion


--#region Setters

--- @param mode TreeGUI.FocusMode
function Widget:setFocusMode(mode)
    if mode == "NONE" then self:releaseFocus() end
    self._focus_mode = mode
end

--- @param side TreeGUI.FocusSide
--- @param widget TreeGUI.Widget?
function Widget:setFocusNeighbor(side, widget)
    self._focus_neighbors[side] = widget
end

--- @param filter TreeGUI.MouseFilter
function Widget:setMouseFilter(filter)
    self._mouse_filter = filter
end

--#endregion


--#region Getters

--- @nodiscard
--- @return boolean has_focus
function Widget:hasFocus()
    return self._tree ~= nil and self._tree:getFocusOwner() == self
end

--- @nodiscard
--- @return boolean is_hovered
function Widget:isHovered()
    return self._tree ~= nil and self._tree:getHovered() == self
end

--- Returns `true` if the Widget is capturing the mouse.
--- @nodiscard
--- @return boolean is_captured
function Widget:isMouseCaptured()
    return self._tree ~= nil and self._tree:getMouseCapture() == self
end

--- @nodiscard
--- @return TreeGUI.FocusMode mode
function Widget:getFocusMode()
    return self._focus_mode
end

--- @nodiscard
--- @param side TreeGUI.FocusSide
--- @return TreeGUI.Widget? widget
function Widget:getFocusNeighbor(side)
    return self._focus_neighbors[side]
end

--- @nodiscard
--- @return TreeGUI.MouseFilter filter
function Widget:getMouseFilter()
    return self._mouse_filter
end

--#endregion


--#region Private Getters

--- Returns the explicit neighbor for `side` if it is valid and keyboard-focusable.
--- @private
--- @nodiscard
--- @param side TreeGUI.FocusSide
--- @return TreeGUI.Widget?
function Widget:_getFocusNeighbor(side)
    local neighbor = self._focus_neighbors[side]
    if
        neighbor
        and not neighbor._is_destroyed
        and neighbor._tree == self._tree
        and neighbor._focus_mode == "ALL"
        and neighbor:isVisibleInTree()
    then
        return neighbor
    end
    return nil
end

--#endregion


return Widget
