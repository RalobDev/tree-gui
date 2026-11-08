local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Class = require(ROOT .. ".libs.class") --- @type TreeGUI.Class

--- @class TreeGUI.Resource: TreeGUI.Class
local Resource = Class:extend("Resource")


--#region Definitions

--- @class TreeGUI.Resource.Props

--#endregion


--#region Public

--- Instantiates a new Resource.
--- @nodiscard
--- @generic T: TreeGUI.Resource
--- @param self T
--- @param props TreeGUI.Resource.Props?
--- @return T self
function Resource:new(props)
    local obj = Class.new(self) --- @class TreeGUI.Resource

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.Resource.Props
function Resource:configure(props)
end

--#endregion


return Resource
