local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local StackContainer = require(ROOT .. ".containers.stack-containers.stack_container") --- @type TreeGUI.StackContainer

--- Container that arranges its children ONLY in a single vertical line.
--- @class TreeGUI.StackContainerV: TreeGUI.StackContainer
local StackContainerV = StackContainer:extend("StackContainerV")


--#region Public

--- Instantiates a new StackContainerV.
--- @nodiscard
--- @param props TreeGUI.StackContainer.Props?
--- @return self
function StackContainerV:new(props)
    local obj = StackContainer.new(self, props)
    return obj
end

--#endregion


--#region Protected

--- @protected
--- @return TreeGUI.Orientation
function StackContainerV:_getOrientation()
    return "VERTICAL"
end

--#endregion


--#region Setters

--- The orientation of an StackContainerV is fixed.
function StackContainerV:setOrientation()
    error("StackContainerV has a fixed orientation. Use StackContainer to change it.")
end

--#endregion


return StackContainerV
