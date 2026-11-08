local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget
local Render = require(ROOT .. ".tools.render_tool") --- @type TreeGUI.Render

--- @class TreeGUI.Panel: TreeGUI.Widget
--- @field private _style_override TreeGUI.Theme.PanelStyle
local Panel = Widget:extend("Panel")


--#region Definitions

--- @class TreeGUI.Panel.Props: TreeGUI.Widget.Props
--- @field style_box TreeGUI.StyleBox?

--#endregion


--#region Public

--- Instantiates a new Panel.
--- @nodiscard
--- @param props TreeGUI.Panel.Props?
--- @return self
function Panel:new(props)
    local obj = Widget.new(self, props)

    return obj
end

--- Configures the Panel according to the values ​​passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Panel.Props
function Panel:configure(props)
    Widget.configure(self, props)

    if props.style_box then self:setStyleBox(props.style_box) end
end

--#endregion


--#region Protected

--- Draws the Panel.
--- @protected
function Panel:_draw()
    Render.setColor(1, 1, 1)
    self:getStyleBox():draw(0, 0, self:getDimensions())
end

--- @protected
function Panel:_onClearStyleOverrides()
    Widget._onClearStyleOverrides(self)

    self._style_override.style_box = nil
end

--#endregion


--#region Setters

--- Sets the StyleBox that is rendered in the Panel. The override value takes priority over the theme.
--- If `style_box` is `nil`, remove the override.
--- @param style_box TreeGUI.StyleBox?
function Panel:setStyleBox(style_box)
    self:_setStyleOverride("style_box", style_box)
end

--#endregion


--#region Getters

--- Returns the Panel's resolved StyleBox,
--- this includes the one defined by Theme if overrides have not been defined.
--- @nodiscard
--- @return TreeGUI.StyleBox style_box
function Panel:getStyleBox()
    return self:_getStyleValue("style_box")
end

--- Returns the StyleBox override by the Panel. Does not include the one used by Theme.
--- @nodiscard
--- @return TreeGUI.StyleBox? style_box
function Panel:getStyleBoxOverride()
    return self._style_override.style_box
end

--#endregion


return Panel
