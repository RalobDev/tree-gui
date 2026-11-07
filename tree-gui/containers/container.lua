local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget
local Layout = require(ROOT .. ".tools.layout_tool") --- @type TreeGUI.Layout
local DebugDraw = require(ROOT .. ".tools.debug_tool") --- @type TreeGUI.DebugDraw
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- Base class for all containers. A Container takes control of the position and size of its children.
--- @class TreeGUI.Container: TreeGUI.Widget
--- @field protected _style_override TreeGUI.Theme.ContainerStyle Overrides for margins (from Widget) and paddings.
local Container = Widget:extend("Container")


--#region Definitions

--- @class TreeGUI.Container.Props: TreeGUI.Widget.Props
--- @field padding_left number?
--- @field padding_top number?
--- @field padding_right number?
--- @field padding_bottom number?

--#endregion


--#region Public

--- Instantiates a new Container.
--- @nodiscard
--- @generic T: TreeGUI.Container
--- @param self T
--- @param props TreeGUI.Container.Props?
--- @return T self
function Container:new(props)
    local obj = Widget.new(self, props) --- @cast obj TreeGUI.Container

    if not (props and props.mouse_filter) then
        obj:setMouseFilter(Enums.MouseFilter.PASS)
    end

    return obj
end

--- Configures the Container according to the values ​​passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Container.Props
function Container:configure(props)
    Widget.configure(self, props)

    if props.padding_left then self:setPaddingLeftOverride(props.padding_left) end
    if props.padding_top then self:setPaddingTopOverride(props.padding_top) end
    if props.padding_right then self:setPaddingRightOverride(props.padding_right) end
    if props.padding_bottom then self:setPaddingBottomOverride(props.padding_bottom) end
end

--#endregion


--#region Protected

--- Draws Container debugging.
function Container:_drawDebug()
    -- Padding: between the Container rectangle and the content area (dashed outline on the inner edge).
    Widget._drawDebug(self)

    if DebugDraw.layers.padding then
        local x, y, width, height = self:_getContentRect()
        DebugDraw.drawFrame("padding", 0, 0, self._width, self._height, x, y, width, height, true)
    end
end

--- Positions and sizes a child within a cell (which includes the child's margins),
--- respecting the size flags, and then tells the son to organize his own children.
--- @protected
--- @param child TreeGUI.Widget
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Container:_fitChildInRect(child, x, y, width, height)
    local _, align_h = Layout.parseFlags(child._size_flags_horizontal)
    local _, align_v = Layout.parseFlags(child._size_flags_vertical)
    local margin_left = child:_getStyleValue("margin_left")
    local margin_top = child:_getStyleValue("margin_top")
    local margin_right = child:_getStyleValue("margin_right")
    local margin_bottom = child:_getStyleValue("margin_bottom")

    local available_width = width - margin_left - margin_right
    local available_height = height - margin_top - margin_bottom

    local cw, ox = Layout.align(align_h, available_width, child._combined_min_width)
    local ch, oy = Layout.align(align_v, available_height, child._combined_min_height)

    if align_h == Enums.SizeFlagsAlignment.FILL then
        ox = ox + Layout.growOffset(child._grow_direction_horizontal, available_width, cw)
    end
    if align_v == Enums.SizeFlagsAlignment.FILL then
        oy = oy + Layout.growOffset(child._grow_direction_vertical, available_height, ch)
    end

    child._x, child._y = x + margin_left + ox, y + margin_top + oy
    child._width, child._height = cw, ch

    child:_layoutChildren()
end

--- Organize your children. Overwrite in containers.
--- Default: all occupy the content area.
--- @protected
function Container:_sortChildren()
    local x, y, width, height = self:_getContentRect()
    for _, child in ipairs(self:_getManagedChildren()) do
        self:_fitChildInRect(child, x, y, width, height)
    end
end

--- Pass 2 (top-down).
--- @protected
function Container:_layoutChildren()
    for _, child in ipairs(self._children) do
        if child._is_internal and child._visible then
            child:_resolveFreeLayout(self._width, self._height)
            child:_layoutChildren()
        end
    end
    self:_sortChildren()
end

--- Called to clear Theme related properties.
--- @protected
function Container:_onClearStyleOverrides()
    Widget._onClearStyleOverrides(self)

    self._style_override.padding_left = nil
    self._style_override.padding_top = nil
    self._style_override.padding_right = nil
    self._style_override.padding_bottom = nil
end

--- Children controlled by this Container: visible and not internal.
--- Subclasses (boxes, grids...) must iterate this instead of `_children`.
--- @protected
--- @nodiscard
--- @return TreeGUI.Widget[]
function Container:_getManagedChildren()
    local list = {} --- @type TreeGUI.Widget[]
    for _, child in ipairs(self._children) do
        if child._visible and not child._is_internal then
            list[#list+1] = child
        end
    end
    return list
end

--#endregion


--#region Setters

--- Sets all Container's paddings. The override value takes priority over the theme.
--- If `paddings` is `nil`, remove the override.
--- @param paddings number?
function Container:setPaddingsOverride(paddings)
    self:_setStyleOverride("padding_left", paddings)
    self:_setStyleOverride("padding_top", paddings)
    self:_setStyleOverride("padding_right", paddings)
    self:_setStyleOverride("padding_bottom", paddings)
end

--- Sets the Container's left padding. The override value takes priority over the theme.
--- If `padding` is `nil`, remove the override.
--- @param padding number?
function Container:setPaddingLeftOverride(padding)
    self:_setStyleOverride("padding_left", padding)
end

--- Sets the Container's top padding. The override value takes priority over the theme.
--- If `padding` is `nil`, remove the override.
--- @param padding number?
function Container:setPaddingTopOverride(padding)
    self:_setStyleOverride("padding_top", padding)
end

--- Sets the Container's right padding. The override value takes priority over the theme.
--- If `padding` is `nil`, remove the override.
--- @param padding number?
function Container:setPaddingRightOverride(padding)
    self:_setStyleOverride("padding_right", padding)
end

--- Sets the Container's bottom padding. The override value takes priority over the theme.
--- If `padding` is `nil`, remove the override.
--- @param padding number?
function Container:setPaddingBottomOverride(padding)
    self:_setStyleOverride("padding_bottom", padding)
end

--#endregion


--#region Getters

--- Gets the Container's resolved paddings,
--- this includes those defined by Theme if overrides have not been defined.
--- @nodiscard
--- @return number padding_left, number paddign_top, number padding_right, number padding_bottom
function Container:getPaddings()
    return self:_getStyleValue("padding_left"),
           self:_getStyleValue("padding_top"),
           self:_getStyleValue("padding_right"),
           self:_getStyleValue("padding_bottom")
end

--- Returns the Container's resolved left padding,
--- this includes the one defined by Theme if overrides have not been defined.
--- @nodiscard
--- @return number padding_left
function Container:getPaddingLeft()
    return self:_getStyleValue("padding_left")
end

--- Returns the Container's resolved top padding,
--- this includes the one defined by Theme if overrides have not been defined.
--- @nodiscard
--- @return number padding_top
function Container:getPaddingTop()
    return self:_getStyleValue("padding_top")
end

--- Returns the Container's resolved right padding,
--- this includes the one defined by Theme if overrides have not been defined.
--- @nodiscard
--- @return number padding_right
function Container:getPaddingRight()
    return self:_getStyleValue("padding_right")
end

--- Returns the Container's resolved bottom padding,
--- this includes the one defined by Theme if overrides have not been defined.
--- @nodiscard
--- @return number padding_bottom
function Container:getPaddingBottom()
    return self:_getStyleValue("padding_bottom")
end

--- Returns the paddings overrides by the Container. Does not include those used by Theme.
--- @nodiscard
--- @return number? padding_left, number? paddign_top, number? padding_right, number? padding_bottom
function Container:getPaddingsOverride()
    return self._style_override.padding_left,
           self._style_override.padding_top,
           self._style_override.padding_right,
           self._style_override.padding_bottom
end

--- Returns the left padding override by the Container. Does not include the one used by Theme.
--- @nodiscard
--- @return number? padding_left
function Container:getPaddingLeftOverride()
    return self._style_override.padding_left
end

--- Returns the top padding override by the Container. Does not include the one used by Theme.
--- @nodiscard
--- @return number? padding_top
function Container:getPaddingTopOverride()
    return self._style_override.padding_top
end

--- Returns the right padding override by the Container. Does not include the one used by Theme.
--- @nodiscard
--- @return number? padding_right
function Container:getPaddingRightOverride()
    return self._style_override.padding_right
end

--- Returns the bottom padding override by the Container. Does not include the one used by Theme.
--- @nodiscard
--- @return number? padding_bottom
function Container:getPaddingBottomOverride()
    return self._style_override.padding_bottom
end

--#endregion


--#region Protected Getters

--- Area (related to the Container) available for children, without padding.
--- @protected
--- @nodiscard
--- @return number x, number y, number width, number height
function Container:_getContentRect()
    local padding_left = self:_getStyleValue("padding_left")
    local padding_top = self:_getStyleValue("padding_top")
    local padding_right = self:_getStyleValue("padding_right")
    local padding_bottom = self:_getStyleValue("padding_bottom")

    return padding_left,
           padding_top,
           math.max(0, self._width - padding_left - padding_right),
           math.max(0, self._height - padding_top - padding_bottom)
end

--- Minimum required only for children (no padding). Overwrite in containers.
--- Pattern: stacked, so the biggest goes.
--- @protected
--- @nodiscard
--- @return number width, number height
function Container:_getChildrenMinimumDimensions()
    local width, height = 0, 0
    for _, child in ipairs(self:_getManagedChildren()) do
        local cw, ch = child:_getOuterMinimumSize()
        width, height = math.max(width, cw), math.max(height, ch)
    end
    return width, height
end

--- Returns the minimum size of the Container's content, without margins.
--- @protected
--- @nodiscard
--- @return number min_width, number min_height
function Container:_getContentMinimumDimensions()
    local padding_left = self:_getStyleValue("padding_left")
    local padding_top = self:_getStyleValue("padding_top")
    local padding_right = self:_getStyleValue("padding_right")
    local padding_bottom = self:_getStyleValue("padding_bottom")

    local width, height = self:_getChildrenMinimumDimensions()
    return width + padding_left + padding_right,
           height + padding_top + padding_bottom
end

--#endregion


return Container
