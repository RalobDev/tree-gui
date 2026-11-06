local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local Container = require(ROOT .. ".containers.container") --- @type TreeGUI.Container

--- Container that arranges its children in a single line (horizontal or vertical).
--- @class TreeGUI.StackContainer: TreeGUI.Container
--- @field private _orientation TreeGUI.Orientation
--- @field protected _style_override TreeGUI.Theme.StackContainerStyle
local StackContainer = Container:extend("StackContainer")


--#region Definitions

--- @class TreeGUI.StackContainer.Props: TreeGUI.Container.Props
--- @field orientation TreeGUI.Orientation?
--- @field separation number?

--#endregion


--#region Public

--- Instantiates a new StackContainer.
--- @nodiscard
--- @generic T: TreeGUI.StackContainer
--- @param self T
--- @param props TreeGUI.StackContainer.Props?
--- @return T
function StackContainer:new(props)
    local obj = Container.new(self, props) --- @cast obj TreeGUI.StackContainer
    return obj
end

--#endregion


return StackContainer
