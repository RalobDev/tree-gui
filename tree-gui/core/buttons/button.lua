local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local BaseButton = require(ROOT .. ".core.buttons.base_button") --- @type TreeGUI.BaseButton
local Render = require(ROOT .. ".tools.render_tool") --- @type TreeGUI.Render
local Text = require(ROOT .. ".tools.text_tool") --- @type TreeGUI.Text
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.Button: TreeGUI.BaseButton
--- @field private _text string
--- @field private _flat boolean
--- @field private _alignment_horizontal TreeGUI.Enums.TextAlignmentHorizontal
--- @field private _measure_cache TreeGUI.Text.MeasureCache
--- @field private _style_override TreeGUI.Theme.ButtonStyle
local Button = BaseButton:extend("Button")

--- @type table<TreeGUI.Enums.DrawMode, string>
local STYLE_BOX_KEYS = {
    [Enums.DrawMode.NORMAL] = "style_box_normal",
    [Enums.DrawMode.HOVER] = "style_box_hover",
    [Enums.DrawMode.PRESSED] = "style_box_pressed",
    [Enums.DrawMode.HOVER_PRESSED] = "style_box_hover_pressed",
    [Enums.DrawMode.DISABLED] = "style_box_disabled",
}

--- @type table<TreeGUI.Enums.DrawMode, string>
local FONT_COLOR_KEYS = {
    [Enums.DrawMode.NORMAL] = "font_normal_color",
    [Enums.DrawMode.HOVER] = "font_hover_color",
    [Enums.DrawMode.PRESSED] = "font_pressed_color",
    [Enums.DrawMode.HOVER_PRESSED] = "font_hover_pressed_color",
    [Enums.DrawMode.DISABLED] = "font_disabled_color",
}

--- When a state has no value in the theme, the next one is tried.
--- @type table<TreeGUI.Enums.DrawMode, TreeGUI.Enums.DrawMode>
local FALLBACK = {
    [Enums.DrawMode.HOVER_PRESSED] = Enums.DrawMode.PRESSED,
    [Enums.DrawMode.PRESSED] = Enums.DrawMode.NORMAL,
    [Enums.DrawMode.HOVER] = Enums.DrawMode.NORMAL,
    [Enums.DrawMode.DISABLED] = Enums.DrawMode.NORMAL,
}

local FOCUS_STYLE_BOX_KEY = "style_box_focus"


--#region Definitions

--- @class TreeGUI.Button.Props: TreeGUI.BaseButton.Props
--- @field text string?
--- @field text_settings TreeGUI.TextSettings?
--- @field flat boolean?
--- @field alignment_horizontal TreeGUI.Enums.TextAlignmentHorizontal?
--- @field style_box_normal TreeGUI.StyleBox?
--- @field style_box_hover TreeGUI.StyleBox?
--- @field style_box_pressed TreeGUI.StyleBox?
--- @field style_box_hover_pressed TreeGUI.StyleBox?
--- @field style_box_disabled TreeGUI.StyleBox?
--- @field style_box_focus TreeGUI.StyleBox?
--- @field font_color TreeGUI.Color?
--- @field font_hover_color TreeGUI.Color?
--- @field font_pressed_color TreeGUI.Color?
--- @field font_hover_pressed_color TreeGUI.Color?
--- @field font_disabled_color TreeGUI.Color?

--#endregion


--#region Local

--- @param mode TreeGUI.Enums.DrawMode
--- @return string key
local function styleBoxKey(mode)
    return STYLE_BOX_KEYS[mode] or error(string.format('Invalid draw mode: "%s".', tostring(mode)), 3)
end

--- @param mode TreeGUI.Enums.DrawMode
--- @return string key
local function fontColorKey(mode)
    return FONT_COLOR_KEYS[mode] or error(string.format('Invalid draw mode: "%s".', tostring(mode)), 3)
end

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

    obj._text = ""
    obj._flat = false
    obj._alignment_horizontal = Enums.TextAlignmentHorizontal.CENTER
    obj._measure_cache = {}

    if props then obj:configure(props) end

    return obj
end

--- Configures the Button according to the values passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Button.Props
function Button:configure(props)
    BaseButton.configure(self, props)

    if props.text ~= nil then self:setText(props.text) end
    if props.text_settings ~= nil then self:setTextSettings(props.text_settings) end
    if props.flat ~= nil then self:setFlat(props.flat) end
    if props.alignment_horizontal ~= nil then self:setAlignmentHorizontal(props.alignment_horizontal) end

    for _, key in pairs(STYLE_BOX_KEYS) do
        if props[key] ~= nil then self:_setStyleOverride(key, props[key]) end
    end
    if props[FOCUS_STYLE_BOX_KEY] ~= nil then self:_setStyleOverride(FOCUS_STYLE_BOX_KEY, props[FOCUS_STYLE_BOX_KEY]) end

    for _, key in pairs(FONT_COLOR_KEYS) do
        if props[key] ~= nil then self:_setStyleOverride(key, props[key]) end
    end
end

--#endregion


--#region Protected

--- @protected
--- @param resource TreeGUI.Resource
function Button:_onResourceChanged(resource)
    BaseButton._onResourceChanged(self, resource)
    self:_queueLayout()
end

--- @protected
function Button:_onClearStyleOverrides()
    BaseButton._onClearStyleOverrides(self)

    local override = self._style_override
    override.text_settings = nil
    override[FOCUS_STYLE_BOX_KEY] = nil
    for _, key in pairs(STYLE_BOX_KEYS) do override[key] = nil end
    for _, key in pairs(FONT_COLOR_KEYS) do override[key] = nil end
end

--- The text size plus paddings is the minimum size of the Button.
--- @protected
--- @nodiscard
--- @return number min_width, number min_height
function Button:_getContentMinimumDimensions()
    local font = self:getTextSettings():getFont()
    return Text.measure(self._measure_cache, font, self._text, math.huge)
end

--- @protected
function Button:_draw()
    local width, height = self._width, self._height
    local mode = self:getDrawMode()

    -- Background (a flat button only shows its decoration while interacted with).
    if not (self._flat and (mode == Enums.DrawMode.NORMAL or mode == Enums.DrawMode.DISABLED)) then
        local style_box = self:getStyleBox(mode)
        if style_box then
            Render.setColor(1, 1, 1)
            style_box:draw(0, 0, width, height)
        end
    end

    if self:hasFocus() then
        local focus_box = self:_getStyleValue(FOCUS_STYLE_BOX_KEY) --- @type TreeGUI.StyleBox?
        if focus_box then
            Render.setColor(1, 1, 1)
            focus_box:draw(0, 0, width, height)
        end
    end

    if self._text == "" then return end

    local font = self:getTextSettings():getFont()
    local text_width, text_height = Text.measure(self._measure_cache, font, self._text, math.huge)

    Render.setColor(self:getFontColor(mode))
    Text.draw(self._text, font, 0, 0, self._width, self._height,
    self._alignment_horizontal, Enums.TextAlignmentVertical.CENTER, false, text_width, text_height)
end

--#endregion


--#region Setters

--- Sets the text of the Button.
--- @param text string
function Button:setText(text)
    text = text == nil and "" or tostring(text)
    if self._text ~= text then
        self._text = text
        self:_queueLayout()
    end
end

--- Sets the TextSettings (font, size, default color). The override value takes priority over the theme.
--- If `text_settings` is `nil`, remove the override.
--- @param text_settings TreeGUI.TextSettings?
function Button:setTextSettings(text_settings)
    self:_setStyleOverride("text_settings", text_settings)
    self:_queueLayout()
end

--- If `enabled` is `true`, the Button does not draw its background in the NORMAL and DISABLED states.
--- @param enabled boolean?
function Button:setFlat(enabled)
    self._flat = enabled ~= false
end

--- Sets the horizontal alignment of the text (BEGIN, CENTER or END).
--- @param alignment TreeGUI.Enums.TextAlignmentHorizontal
function Button:setAlignmentHorizontal(alignment)
    self._alignment_horizontal = alignment
end

--- Sets the StyleBox used in a state. The override value takes priority over the theme.
--- If `style_box` is `nil`, remove the override.
--- @param mode TreeGUI.Enums.DrawMode
--- @param style_box TreeGUI.StyleBox?
function Button:setStyleBox(mode, style_box)
    self:_setStyleOverride(styleBoxKey(mode), style_box)
end

--- Sets the StyleBox drawn over the Button while it has focus.
--- @param style_box TreeGUI.StyleBox?
function Button:setFocusStyleBox(style_box)
    self:_setStyleOverride(FOCUS_STYLE_BOX_KEY, style_box)
end

--- Sets the text color used in a state. If `color` is `nil`, remove the override.
--- @param mode TreeGUI.Enums.DrawMode
--- @param color TreeGUI.Color?
function Button:setFontColor(mode, color)
    self:_setStyleOverride(fontColorKey(mode), color)
end

--#endregion


--#region Getters

--- Returns the text of the Button.
--- @nodiscard
--- @return string text
function Button:getText()
    return self._text
end

--- Returns the Button's resolved TextSettings (override, then theme).
--- @nodiscard
--- @return TreeGUI.TextSettings
function Button:getTextSettings()
    return self:_getStyleValue("text_settings")
end

--- Returns the TextSettings override by the Button. Does not include the one used by Theme.
--- @nodiscard
--- @return TreeGUI.TextSettings?
function Button:getTextSettingsOverride()
    return self._style_override.text_settings
end

--- @nodiscard
--- @return boolean
function Button:isFlat()
    return self._flat
end

--- @nodiscard
--- @return TreeGUI.Enums.TextAlignmentHorizontal
function Button:getAlignmentHorizontal()
    return self._alignment_horizontal
end

--- Returns the resolved StyleBox of a state. A state without value falls back to
--- HOVER_PRESSED -> PRESSED -> NORMAL (HOVER and DISABLED fall back to NORMAL).
--- @nodiscard
--- @param mode TreeGUI.Enums.DrawMode
--- @return TreeGUI.StyleBox? style_box
function Button:getStyleBox(mode)
    styleBoxKey(mode) -- validates
    local current = mode --- @type TreeGUI.Enums.DrawMode?
    while current do
        local style_box = self:_getStyleValue(STYLE_BOX_KEYS[current])
        if style_box then return style_box end
        current = FALLBACK[current]
    end
    return nil
end

--- Returns the StyleBox override of a state. Does not include the one used by Theme.
--- @nodiscard
--- @param mode TreeGUI.Enums.DrawMode
--- @return TreeGUI.StyleBox?
function Button:getStyleBoxOverride(mode)
    return self._style_override[styleBoxKey(mode)]
end

--- Returns the resolved focus StyleBox (override, then theme).
--- @nodiscard
--- @return TreeGUI.StyleBox?
function Button:getFocusStyleBox()
    return self:_getStyleValue(FOCUS_STYLE_BOX_KEY)
end

--- Returns the focus StyleBox override. Does not include the one used by Theme.
--- @nodiscard
--- @return TreeGUI.StyleBox?
function Button:getFocusStyleBoxOverride()
    return self._style_override[FOCUS_STYLE_BOX_KEY]
end

--- Returns the resolved text color of a state (default: the current draw mode).
--- Falls back like `getStyleBox`, ending at the TextSettings color.
--- @nodiscard
--- @param mode TreeGUI.Enums.DrawMode?
--- @return TreeGUI.Color color
function Button:getFontColor(mode)
    local current = mode or self:getDrawMode() --- @type TreeGUI.Enums.DrawMode
    fontColorKey(current)
    while current do
        local color = self:_getStyleValue(FONT_COLOR_KEYS[current])
        if color then return color end
        current = FALLBACK[current]
    end
    return { self:getTextSettings():getColor() }
end

--- Returns the font color override of a state. Does not include the one used by Theme.
--- @nodiscard
--- @param mode TreeGUI.Enums.DrawMode
--- @return TreeGUI.Color?
function Button:getFontColorOverride(mode)
    return self._style_override[fontColorKey(mode)]
end

--#endregion


return Button
