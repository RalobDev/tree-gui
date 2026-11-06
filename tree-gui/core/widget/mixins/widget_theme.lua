--- @diagnostic disable: invisible

local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 4) .. "$") --- @type string

--- @class TreeGUI.Widget
local Widget = {}

local DEFAULT_THEME = require(ROOT .. ".resources.default_theme") --- @type TreeGUI.Theme


--#region Local

local chain_cache = {} --- @type table<string, string[]>

--- Returns the type names used to look up styles, from most to least specific
--- (e.g. { "Button", "Container", "Widget" }). Cached per class name.
--- @param widget TreeGUI.Widget
--- @return string[]
local function getStyleChain(widget)
    local name = widget:getClassName()
    local chain = chain_cache[name]
    if chain then return chain end

    chain = { name }
    local inheritances = widget:getInheritances() -- root -> direct parent, e.g. { "Class", "Widget", "Container" }
    for i = #inheritances, 1, -1 do
        if inheritances[i] ~= "Class" then
            chain[#chain + 1] = inheritances[i]
        end
    end

    chain_cache[name] = chain
    return chain
end

--- Looks up `key` in `theme` following the type chain.
--- @param theme TreeGUI.Theme
--- @param chain string[]
--- @param key string
--- @return any
local function lookup(theme, chain, key)
    for _, type_name in ipairs(chain) do
        local value = theme:getStyleValue(type_name, key)
        if value ~= nil then return value end
    end
    return nil
end

--#endregion


--#region Public

--- Marks the Widget to update its values related to its Theme in the next update of its Tree.
--- No need to call manually this method, as Theme's already do this automatically.
function Widget:queueUpdateTheme()
    if self._tree then
        self._tree:queueUpdateTheme()
    end
end

--- Clears Theme-related properties. This way they become affected by the Widget Theme.
function Widget:clearStyleOverrides()
    self:_onClearStyleOverrides()
end

--#endregion


--#region Protected

--- Called when a change occurs in the Theme that affects this Widget.
--- Styles are read on demand (lazy), so there is nothing to cache here by default.
--- @protected
function Widget:_onThemeChanged()
end

--- Called to clear Theme related properties.
--- @protected
function Widget:_onClearStyleOverrides()
    self._style_override.margin_left = nil
    self._style_override.margin_top = nil
    self._style_override.margin_right = nil
    self._style_override.margin_bottom = nil
end

--#endregion


--#region Private

--- Called by the Widget Tree when the theme is updated. Recursive.
--- Since margins are read on demand, the layout must be recalculated.
--- @private
function Widget:_callThemeChanged()
    self:_onThemeChanged()
    self:_queueLayout()

    for _, child in ipairs(self._children) do
        child:_callThemeChanged()
    end
end

--#endregion


--#region Setters

--- Defines the Widget Theme. If it is `nil`, it will use the parent's Theme.
--- @param theme TreeGUI.Theme?
function Widget:setTheme(theme)
    if theme ~= self._theme then
        if self._theme then self._theme:_removeOwner(self) end
        if theme then theme:_addOwner(self) end

        self._theme = theme
        self:queueUpdateTheme()
    end
end

--- Sets the theme variant applied to the Widget. If `nil`, no variants are used during
--- Theme resolution.
--- @param theme_variant string?
function Widget:setThemeVariant(theme_variant)
    if theme_variant ~= self._theme_variant then
        self._theme_variant = theme_variant
        self:queueUpdateTheme()
    end
end

--#endregion


--#region Getters

--- Resolves a style value. Priority:
--- 1. Widget override (only for the widget itself).
--- 2. Theme of the widget, then of each ancestor, looking up the type of THIS widget
---    (and its base types, e.g. Button -> Container -> Widget).
--- 3. Default theme.
--- @nodiscard
--- @param key string
--- @param ignore_override boolean?
--- @return any?
function Widget:getStyleValue(key, ignore_override)
    if not ignore_override then
        local override_value = self._style_override[key] --- @type any
        if override_value ~= nil then return override_value end
    end

    local chain = getStyleChain(self)
    local type_name = self:getClassName() --- @cast type_name TreeGUI.Theme.WidgetType

    local current = self --- @type TreeGUI.Widget?
    while current do
        if current._theme then
            local value = nil

            if self._theme_variant then
                value = current._theme:getVariantStyleValue(type_name, self._theme_variant, key)
                if value ~= nil then return value end
            end

            value = lookup(current._theme, chain, key)
            if value ~= nil then return value end
        end
        current = current._parent
    end

    if self._tree then
        local tree_theme = self._tree:getTheme()
        if tree_theme then
            local value = nil

            if self._theme_variant then
                value = tree_theme:getVariantStyleValue(type_name, self._theme_variant, key)
                if value ~= nil then return value end
            end

            value = lookup(tree_theme, chain, key)
            if value ~= nil then return value end
        end
    end

    return lookup(DEFAULT_THEME, chain, key)
end

--- Returns the Theme set directly on this Widget (`nil` if it inherits from the parent).
--- @nodiscard
--- @return TreeGUI.Theme? theme
function Widget:getTheme()
    return self._theme
end

--- Returns the theme variant applied to the Widget. If `nil`, no variants are used during
--- Theme resolution.
--- @nodiscard
--- @return string? theme_variant
function Widget:getThemeVariant()
    return self._theme_variant
end

--#endregion


return Widget
