local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget

--- @class TreeGUI.BaseButton: TreeGUI.Widget
local BaseButton = Widget:extend("BaseButton")


--#region Definitions

--- @class TreeGUI.BaseButton.Props: TreeGUI.Widget.Props

--#endregion


--#region Public

--- Instantiates a new BaseButton.
--- @nodiscard
--- @generic T: TreeGUI.BaseButton
--- @param self T
--- @param props TreeGUI.BaseButton.Props?
--- @return T
function BaseButton:new(props)
    local obj = Widget.new(self) --- @cast obj TreeGUI.BaseButton

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.BaseButton.Props
function BaseButton:configure(props)
    Widget.configure(self, props)
end

--#endregion


return BaseButton
