local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget
local Render = require(ROOT .. ".tools.render_tool") --- @type TreeGUI.Render

--- @class TreeGUI.Label: TreeGUI.Widget
--- @field private _style_override TreeGUI.Theme.LabelStyle
local Label = Widget:extend("Label")


--#region Definitions

--- @class TreeGUI.Label.Props: TreeGUI.Widget.Props

--#endregion


--#region Public

--- Instantiates a new Label.
--- @nodiscard
--- @param props TreeGUI.Label.Props?
--- @return self
function Label:new(props)
    local obj = Widget.new(self, props)

    return obj
end

--- Configures the Label according to the values ​​passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Label.Props
function Label:configure(props)
    Widget.configure(self, props)
end

--#endregion


--#region Protected

--- Draws the Label.
--- @protected
function Label:_draw()
end

--#endregion


return Label
