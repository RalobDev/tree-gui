local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget
local Render = require(ROOT .. ".tools.render_tool") --- @type TreeGUI.Render
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.Label: TreeGUI.Widget
--- @field private _text string
--- @field private _wrap boolean
--- @field private _alignment_horizontal TreeGUI.Enums.TextAlignmentHorizontal
--- @field private _alignment_vertical TreeGUI.Enums.TextAlignmentVertical
--- @field private _wrapped_width number? Width used by the last minimum-size measurement (wrap only).
--- @field private _measure_cache { font: love.Font, text: string, limit: number, width: number, height: number }?
--- @field private _style_override TreeGUI.Theme.LabelStyle
local Label = Widget:extend("Label")

--- @type table<TreeGUI.Enums.TextAlignmentHorizontal, love.AlignMode>
local HORIZONTAL_ALIGN = {
    BEGIN = "left",
    CENTER = "center",
    END = "right",
    JUSTIFY = "justify",
}

--- Fraction of the free vertical space placed above the text.
--- @type table<TreeGUI.Enums.TextAlignmentVertical, number>
local VERTICAL_ALIGN = {
    BEGIN = 0,
    CENTER = 0.5,
    END = 1,
}


--#region Definitions

--- @class TreeGUI.Label.Props: TreeGUI.Widget.Props
--- @field text string?
--- @field text_settings TreeGUI.TextSettings?
--- @field wrap boolean?
--- @field alignment_horizontal TreeGUI.Enums.TextAlignmentHorizontal?
--- @field alignment_vertical TreeGUI.Enums.TextAlignmentVertical?

--#endregion


--#region Local

--- Converts any value to the string stored by the Label.
--- @nodiscard
--- @param text any
--- @return string
local function toText(text)
    if text == nil then return "" end
    return tostring(text)
end

--#endregion


--#region Public

--- Instantiates a new Label.
--- @nodiscard
--- @param props TreeGUI.Label.Props?
--- @return self
function Label:new(props)
    local obj = Widget.new(self, props)

    obj._text = obj._text or ""
    obj._wrap = obj._wrap or false
    obj._alignment_horizontal = obj._alignment_horizontal or Enums.TextAlignmentHorizontal.BEGIN
    obj._alignment_vertical = obj._alignment_vertical or Enums.TextAlignmentVertical.BEGIN

    return obj
end

--- Configures the Label according to the values ​​passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Label.Props
function Label:configure(props)
    Widget.configure(self, props)

    if props.text ~= nil then self:setText(props.text) end
    if props.text_settings ~= nil then self:setTextSettings(props.text_settings) end
    if props.wrap ~= nil then self:setWrap(props.wrap) end
    if props.alignment_horizontal ~= nil then self:setAlignmentHorizontal(props.alignment_horizontal) end
    if props.alignment_vertical ~= nil then self:setAlignmentVertical(props.alignment_vertical) end
end

--#endregion


--#region Protected

--- Called when the Theme or the TextSettings used by the Label changes (e.g. font size):
--- the text may now have another size, so the layout must be recalculated.
--- @protected
--- @param resource TreeGUI.Resource
function Label:_onResourceChanged(resource)
    Widget._onResourceChanged(self, resource)
    self:_queueLayout()
end

--- The text size is the minimum size of the Label.
--- With wrap, the width is free (0) and only the height is required, using the last arranged width.
--- @protected
--- @nodiscard
--- @return number min_width, number min_height
function Label:_getContentMinimumDimensions()
    local font = self:getTextSettings():getFont()

    if self._wrap then
        -- The width is only known after the layout, so this uses the one from the previous pass
        -- (`_draw` requests a new pass if it changed).
        self._wrapped_width = self._width
        local _, height = self:_measure(font, self:_getWrapLimit())
        return 0, height
    end

    return self:_measure(font, math.huge)
end

--- Draws the Label.
--- @protected
function Label:_draw()
    local text = self._text
    local wrap = self._wrap
    local width, height = self._width, self._height

    -- The minimum height was measured with another width: measure again on the next layout.
    if wrap and width ~= self._wrapped_width then self:_queueLayout() end

    if text == "" or (wrap and width <= 0) then return end

    local font = self:getTextSettings():getFont()
    local text_width, text_height = self:_measure(font, wrap and self:_getWrapLimit() or math.huge)

    -- Without wrap the limit can never be smaller than the text, or printf would break the line.
    local limit = wrap and width or math.max(width, text_width)

    -- Floored to avoid blurry text.
    local y = math.floor(math.max(0, height - text_height) * VERTICAL_ALIGN[self._alignment_vertical])

    Render.setColor(self:getTextSettings():getColor())
    love.graphics.printf(text, font, 0, y, limit, HORIZONTAL_ALIGN[self._alignment_horizontal])
end

--- @protected
function Label:_onClearStyleOverrides()
    Widget._onClearStyleOverrides(self)

    self._style_override.text_settings = nil
end

--#endregion


--#region Private

--- Width at which the text wraps: the Label width, or no limit while it has not been arranged yet.
--- @private
--- @nodiscard
--- @return number limit
function Label:_getWrapLimit()
    return self._width > 0 and self._width or math.huge
end

--- Size of the text for a font and wrap limit. The last result is cached,
--- since it is requested on every layout and every draw.
--- @private
--- @nodiscard
--- @param font love.Font
--- @param limit number
--- @return number width, number height
function Label:_measure(font, limit)
    local text = self._text
    local cache = self._measure_cache

    if cache and cache.font == font and cache.text == text and cache.limit == limit then
        return cache.width, cache.height
    end

    local width, lines = font:getWrap(text, limit)
    local line_height = font:getHeight()
    local height = line_height * font:getLineHeight() * (math.max(#lines, 1) - 1) + line_height

    self._measure_cache = { font = font, text = text, limit = limit, width = width, height = height }

    return width, height
end

--#endregion


--#region Setters

--- Sets the text of the Label.
--- @param text string
function Label:setText(text)
    text = toText(text)
    if self._text ~= text then
        self._text = text
        self:_queueLayout()
    end
end

--- Sets a TextSettings da Label. The override value takes priority over the theme.
--- If `text_settings` is `nil`, remove the override.
--- @param text_settings TreeGUI.TextSettings?
function Label:setTextSettings(text_settings)
    self:_setStyleOverride("text_settings", text_settings)
    self:_queueLayout()
end

--- If `enabled` is `true`, the text breaks into lines to fit the width of the Label.
--- @param enabled boolean?
function Label:setWrap(enabled)
    enabled = enabled ~= false
    if self._wrap ~= enabled then
        self._wrap = enabled
        self:_queueLayout()
    end
end

--- Sets the horizontal alignment of the text.
--- @param alignment TreeGUI.Enums.TextAlignmentHorizontal
function Label:setAlignmentHorizontal(alignment)
    self._alignment_horizontal = alignment
end

--- Sets the vertical alignment of the text inside the Label.
--- @param alignment TreeGUI.Enums.TextAlignmentVertical
function Label:setAlignmentVertical(alignment)
    self._alignment_vertical = alignment
end

--#endregion


--#region Getters

--- Returns the text of the Label.
--- @nodiscard
--- @return string text
function Label:getText()
    return self._text
end

--- Returns the Label's resolved TextSettings,
--- this includes the one defined by Theme if overrides have not been defined.
--- @nodiscard
--- @return TreeGUI.TextSettings
function Label:getTextSettings()
    return self:_getStyleValue("text_settings")
end

--- Returns the TextSettings override by the Label. Does not include the one used by Theme.
--- @nodiscard
--- @return TreeGUI.TextSettings?
function Label:getTextSettingsOverride()
    return self._style_override.text_settings
end

--- Returns `true` if the text wraps to fit the width of the Label.
--- @nodiscard
--- @return boolean enabled
function Label:isWrapping()
    return self._wrap
end

--- Returns the horizontal alignment of the text.
--- @nodiscard
--- @return TreeGUI.Enums.TextAlignmentHorizontal alignment
function Label:getAlignmentHorizontal()
    return self._alignment_horizontal
end

--- Returns the vertical alignment of the text.
--- @nodiscard
--- @return TreeGUI.Enums.TextAlignmentVertical alignment
function Label:getAlignmentVertical()
    return self._alignment_vertical
end

--#endregion


return Label
