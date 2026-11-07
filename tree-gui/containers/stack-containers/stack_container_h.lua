local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local StackContainer = require(ROOT .. ".containers.stack-containers.stack_container") --- @type TreeGUI.StackContainer
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- Container that arranges its children ONLY in a single horizontal line.
--- @class TreeGUI.StackContainerH: TreeGUI.StackContainer
local StackContainerH = StackContainer:extend("StackContainerH")


--#region Public

--- Instantiates a new StackContainerH.
--- @nodiscard
--- @param props TreeGUI.StackContainer.Props?
--- @return self
function StackContainerH:new(props)
    local obj = StackContainer.new(self, props)
    return obj
end

--#endregion


--#region Protected

--- @protected
--- @return TreeGUI.Enums.Orientation
function StackContainerH:_getOrientation()
    return Enums.Orientation.HORIZONTAL
end

--#endregion


--#region Setters

--- The orientation of an StackContainerH is fixed.
function StackContainerH:setOrientation()
    error("StackContainerH has a fixed orientation. Use StackContainer to change it.")
end

--#endregion


return StackContainerH
