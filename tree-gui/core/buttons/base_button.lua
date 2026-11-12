local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget
local Signal = require(ROOT .. ".core.signal") --- @type TreeGUI.Signal
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.BaseButton: TreeGUI.Widget
--- @field on_pressed TreeGUI.Signal<fun()> Called when the button is activated (click, Enter/Space).
--- @field on_button_down TreeGUI.Signal<fun()> Called when the press starts.
--- @field on_button_up TreeGUI.Signal<fun()> Called when the press ends. Not emitted when the press is cancelled.
--- @field on_toggled TreeGUI.Signal<fun(is_pressed: boolean)> Called when a toggle button changes state.
--- @field private _disabled boolean
--- @field private _toggle_mode boolean
--- @field private _pressed boolean Toggle state (only meaningful with `_toggle_mode`).
--- @field private _action_mode TreeGUI.Enums.ActionMode
--- @field private _keep_pressed_outside boolean
--- @field private _button_mask table<number, boolean> Mouse buttons that can activate it.
--- @field private _press_attempt boolean A press is in progress.
--- @field private _pressing_inside boolean The pointer is inside while pressing.
--- @field private _press_source number|"key"|nil What holds the press: a mouse button, the keyboard, or nothing.
local BaseButton = Widget:extend("BaseButton")

local ACCEPT_KEYS = { ["return"] = true, kpenter = true, space = true }


--#region Definitions

--- @class TreeGUI.BaseButton.Props: TreeGUI.Widget.Props
--- @field on_pressed fun()?
--- @field on_button_down fun()?
--- @field on_button_up fun()?
--- @field on_toggled fun(is_pressed: boolean)?
--- @field disabled boolean?
--- @field toggle_mode boolean?
--- @field pressed boolean? Initial toggle state (no signal emitted). Requires `toggle_mode`.
--- @field action_mode TreeGUI.Enums.ActionMode?
--- @field keep_pressed_outside boolean?
--- @field button_mask number[]? Mouse buttons that activate it.

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

    obj.on_pressed = Signal:new()
    obj.on_button_down = Signal:new()
    obj.on_button_up = Signal:new()
    obj.on_toggled = Signal:new()
    obj._disabled = false
    obj._toggle_mode = false
    obj._pressed = false
    obj._action_mode = Enums.ActionMode.RELEASE
    obj._keep_pressed_outside = false
    obj._button_mask = { [1] = true }
    obj._press_attempt = false
    obj._pressing_inside = false
    obj._press_source = nil

    obj:setFocusMode(Enums.FocusMode.ALL)

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.BaseButton.Props
function BaseButton:configure(props)
    Widget.configure(self, props)

    if props.on_pressed then self.on_pressed:connect(props.on_pressed) end
    if props.on_button_down then self.on_button_down:connect(props.on_button_down) end
    if props.on_button_up then self.on_button_up:connect(props.on_button_up) end
    if props.on_toggled then self.on_toggled:connect(props.on_toggled) end

    if props.disabled ~= nil then self:setDisabled(props.disabled) end
    if props.toggle_mode ~= nil then self:setToggleMode(props.toggle_mode) end
    if props.pressed ~= nil then self:setPressedNoSignal(props.pressed) end
    if props.action_mode ~= nil then self:setActionMode(props.action_mode) end
    if props.keep_pressed_outside ~= nil then self:setKeepPressedOutside(props.keep_pressed_outside) end
    if props.button_mask ~= nil then self:setButtonMask(props.button_mask) end
end

--#endregion


--#region Protected

--- @protected
--- @nodiscard
--- @return boolean is_focusable
function BaseButton:_checkFocusable()
    return not self._disabled
end

--- @protected
--- @param tree TreeGUI.Tree
function BaseButton:_onTreeExited(tree)
    self:_cancelPress()
end

--- @protected
--- @param is_visible boolean
function BaseButton:_onVisibilityChanged(is_visible)
    if not is_visible then self:_cancelPress() end
end

--- Called when the button is activated, right before `on_pressed`.
--- @protected
function BaseButton:_onPressed()
end

--- Called when a toggle button changes state, right before `on_toggled`.
--- @protected
--- @param is_pressed boolean
function BaseButton:_onToggled(is_pressed) end

--- @protected
--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
--- @param presses number
--- @return boolean consumed
function BaseButton:_onMousePressed(x, y, button, istouch, presses)
    if not self._button_mask[button] then return false end
    if self._press_source ~= nil then return true end

    self._press_source = button
    self:captureMouse() -- keeps receiving move/release even when the pointer leaves the button
    self:_startPress()
    return true
end

--- @protected
--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
--- @param presses number
--- @return boolean consumed
function BaseButton:_onMouseReleased(x, y, button, istouch, presses)
    if self._press_source ~= button then return false end

    self:releaseMouse()
    self._pressing_inside = self:_hasPoint(x, y)
    self:_endPress()
    return true
end

--- @protected
--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
--- @param istouch boolean
--- @return boolean consumed
function BaseButton:_onMouseMoved(x, y, dx, dy, istouch)
    if self._press_attempt and type(self._press_source) == "number" then
        self._pressing_inside = self:_hasPoint(x, y)
    end
    return false
end

--- @protected
--- @param key love.KeyConstant
--- @param scancode love.Scancode
--- @param isrepeat boolean
--- @return boolean consumed
function BaseButton:_onKeyPressed(key, scancode, isrepeat)
    if self._disabled or not ACCEPT_KEYS[key] then return false end
    if isrepeat or self._press_source ~= nil then return true end

    self._press_source = "key"
    self:_startPress()
    return true
end

--- @protected
--- @param key love.KeyConstant
--- @param scancode love.Scancode
--- @return boolean consumed
function BaseButton:_onKeyReleased(key, scancode)
    if self._press_source ~= "key" or not ACCEPT_KEYS[key] then return false end

    self._pressing_inside = true
    self:_endPress()
    return true
end

--- Losing focus while Enter/Space is held cancels the press.
--- @protected
function BaseButton:_onFocusExited()
    if self._press_source == "key" then self:_cancelPress() end
end

--#endregion


--#region Private

--- @private
--- @nodiscard
--- @param x number Local X.
--- @param y number Local Y.
--- @return boolean
function BaseButton:_hasPoint(x, y)
    return x >= 0 and y >= 0 and x < self._width and y < self._height
end

--- @private
function BaseButton:_startPress()
    self._press_attempt = true
    self._pressing_inside = true
    self:_emitSignal(self.on_button_down)

    if self._action_mode == Enums.ActionMode.PRESS then
        -- A toggle flips immediately, so the visual must follow the new state, not the press.
        if self._toggle_mode then
            self._press_attempt = false
            self._pressing_inside = false
        end
        self:_activate()
    end
end

--- @private
function BaseButton:_endPress()
    if self._press_attempt and self._pressing_inside and self._action_mode == Enums.ActionMode.RELEASE then
        self:_activate()
    end

    self._press_attempt = false
    self._pressing_inside = false
    self._press_source = nil
    self:_emitSignal(self.on_button_up)
end

--- Aborts the current press without activating the button.
--- @private
function BaseButton:_cancelPress()
    local source = self._press_source
    if source == nil then return end

    self._press_attempt = false
    self._pressing_inside = false
    self._press_source = nil
    if type(source) == "number" then self:releaseMouse() end
end

--- @private
function BaseButton:_activate()
    if self._toggle_mode then
        self._pressed = not self._pressed
        self:_onPressed()
        self:_emitSignal(self.on_pressed)
        self:_onToggled(self._pressed)
        self:_emitSignal(self.on_toggled, self._pressed)
    else
        self:_onPressed()
        self:_emitSignal(self.on_pressed)
    end
end

--#endregion


--#region Setters

--- Disables or enables the button. A disabled button ignores input and cannot keep focus.
--- @param disabled boolean?
function BaseButton:setDisabled(disabled)
    disabled = disabled ~= false
    if self._disabled == disabled then return end

    self._disabled = disabled
    if disabled then
        self:_cancelPress()
        self:releaseFocus()
    end
end

--- Enables or disables toggle mode. Leaving toggle mode un-presses the button.
--- @param enabled boolean?
function BaseButton:setToggleMode(enabled)
    enabled = enabled ~= false
    if not enabled then self:setPressed(false) end
    self._toggle_mode = enabled
end

--- Sets the toggle state, emitting `on_toggled` if it changes. Only works in toggle mode.
--- @param pressed boolean
function BaseButton:setPressed(pressed)
    pressed = pressed == true
    if not self._toggle_mode or self._pressed == pressed then return end

    self._pressed = pressed
    self:_onToggled(pressed)
    self:_emitSignal(self.on_toggled, pressed)
end

--- Same as `setPressed`, but without emitting `on_toggled`.
--- @param pressed boolean
function BaseButton:setPressedNoSignal(pressed)
    if self._toggle_mode then self._pressed = pressed == true end
end

--- Defines whether the button activates when pressed or when released (default).
--- @param action_mode TreeGUI.Enums.ActionMode
function BaseButton:setActionMode(action_mode)
    self._action_mode = action_mode
end

--- If `true`, the button keeps looking pressed while the pointer is outside of it.
--- @param enabled boolean?
function BaseButton:setKeepPressedOutside(enabled)
    self._keep_pressed_outside = enabled ~= false
end

--- Sets which mouse buttons activate the button (e.g. `{ 1, 2 }`).
--- @param buttons number[]
function BaseButton:setButtonMask(buttons)
    local mask = {}
    for _, button in ipairs(buttons) do mask[button] = true end
    self._button_mask = mask
end

--#endregion


--#region Getters

--- Returns `true` if the button is disabled.
--- @nodiscard
--- @return boolean
function BaseButton:isDisabled()
    return self._disabled
end

--- Returns `true` if the button is in toggle mode.
--- @nodiscard
--- @return boolean
function BaseButton:isToggleMode()
    return self._toggle_mode
end

--- Returns the toggle state (always `false` outside toggle mode).
--- @nodiscard
--- @return boolean
function BaseButton:isPressed()
    return self._pressed
end

--- @nodiscard
--- @return TreeGUI.Enums.ActionMode
function BaseButton:getActionMode()
    return self._action_mode
end

--- @nodiscard
--- @return boolean
function BaseButton:isKeepPressedOutside()
    return self._keep_pressed_outside
end

--- Returns the mouse buttons that activate the button.
--- @nodiscard
--- @return number[]
function BaseButton:getButtonMask()
    local list = {}
    for button in pairs(self._button_mask) do list[#list + 1] = button end
    table.sort(list)
    return list
end

--- Returns how the button should be drawn right now.
--- @nodiscard
--- @return TreeGUI.Enums.DrawMode
function BaseButton:getDrawMode()
    if self._disabled then return Enums.DrawMode.DISABLED end

    if not self._press_attempt and self:isHovered() then
        return self._pressed and Enums.DrawMode.HOVER_PRESSED or Enums.DrawMode.HOVER
    end

    local pressing
    if self._press_attempt then
        pressing = self._pressing_inside or self._keep_pressed_outside
        if self._pressed then pressing = not pressing end -- pressing a toggled button previews "un-toggled"
    else
        pressing = self._pressed
    end

    return pressing and Enums.DrawMode.PRESSED or Enums.DrawMode.NORMAL
end

--#endregion


return BaseButton
