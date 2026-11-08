local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget

--- @class TreeGUI.Panel: TreeGUI.Widget
local Panel = Widget:extend("Panel")


--#region Definitions

--- @class TreeGUI.Panel.Props: TreeGUI.Widget.Props

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

--- Configures the ColorRect according to the values ​​passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Panel.Props
function Panel:configure(props)
    Widget.configure(self, props)
end

--#endregion


return Panel
