local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Resource = require(ROOT .. ".resources.resource") --- @type TreeGUI.Resource

--- @class TreeGUI.TextSettings: TreeGUI.Resource
local TextSettings = Resource:extend("TextSettings")


--#region Definitions

--- @class TreeGUI.TextSettings.Props: TreeGUI.Resource.Props

--#endregion


--#region Public

--- Instantiates a new TextSettings.
--- @nodiscard
--- @generic T: TreeGUI.TextSettings
--- @param self T
--- @param props TreeGUI.TextSettings.Props?
--- @return T self
function TextSettings:new(props)
    local obj = Resource.new(self)

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.TextSettings.Props
function TextSettings:configure(props)
    self:_checkLock()
    self:_batch(self._applyProps, props)

    Resource.configure(self, props)
end

--#endregion


--#region Private

--- @private
--- @param props TreeGUI.TextSettings.Props
function TextSettings:_applyProps(props)
end

--#endregion


return TextSettings
