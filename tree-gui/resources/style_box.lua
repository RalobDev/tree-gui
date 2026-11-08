local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Resource = require(ROOT .. ".resources.resource") --- @type TreeGUI.Resource

--- @class TreeGUI.StyleBox: TreeGUI.Resource
local StyleBox = Resource:extend("StyleBox")


--#region Definitions

--- @class TreeGUI.StyleBox.Props

--#endregion


--#region Public

--- Instantiates a new StyleBox.
--- @nodiscard
--- @generic T: TreeGUI.StyleBox
--- @param self T
--- @param props TreeGUI.StyleBox.Props?
--- @return T self
function StyleBox:new(props)
    local obj = Resource.new(self) --- @class TreeGUI.StyleBox

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.StyleBox.Props
function StyleBox:configure(props)
    self:_batch(self._applyProps, props)
end

--#endregion


--#region Private

--- @private
--- @param props TreeGUI.StyleBox.Props
function StyleBox:_applyProps(props)
end

--#endregion


return StyleBox
