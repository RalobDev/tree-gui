local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local BaseButton = require(ROOT .. ".core.buttons.base_button") --- @type TreeGUI.BaseButton

--- @class TreeGUI.Button: TreeGUI.BaseButton
local Button = BaseButton:extend("Button")


--#region Definitions

--- @class TreeGUI.Button.Props: TreeGUI.BaseButton.Props

--#endregion


--#region Public

--- Instantiates a new Button.
--- @nodiscard
--- @generic T: TreeGUI.Button
--- @param self T
--- @param props TreeGUI.Button.Props?
--- @return T
function Button:new(props)
    local obj = BaseButton.new(self) --- @cast obj TreeGUI.Button

    if props then obj:configure(props) end

    return obj
end

--- Configures the Button according to the values passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Button.Props
function Button:configure(props)
    BaseButton.configure(self, props)
end

--#endregion


return Button
