local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Class = require(ROOT .. ".libs.class") --- @type TreeGUI.Class

--- @class TreeGUI.Theme: TreeGUI.Class
--- @field private _data TreeGUI.Theme.Data Styles by Widget type name (e.g. "Container").
--- @field private _variants TreeGUI.Theme.Variants Styles by Widget type name and variant name.
--- @field private _owners table<TreeGUI.Widget|TreeGUI.Tree, true> Widgets/Trees using this Theme, notified on changes. Weak keys, so it does not keep them alive.
local Theme = Class:extend("Theme")


--#region Definitions

--- @class TreeGUI.Theme.Props
--- @field data TreeGUI.Theme.Data?
--- @field variants TreeGUI.Theme.Variants?

--#endregion


--#region Local

--- Shallow-copies a table.
--- @param t table
--- @return table
local function shallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    return copy
end

--#endregion


--#region Public

--- Instantiates a new Theme.
--- The style tables are copied, so mutating `data` afterwards does not affect the Theme.
--- @nodiscard
--- @param props TreeGUI.Theme.Props?
--- @return TreeGUI.Theme self
function Theme:new(props)
    local obj = Class.new(self)

    obj._data = {}
    obj._variants = {}
    obj._owners = setmetatable({}, { __mode = "k" }) -- weak keys: the theme does not prevent widgets from being GC.

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.Theme.Props
function Theme:configure(props)
    if props.data then
        for type_name, style in pairs(props.data) do
            self._data[type_name] = shallowCopy(style)
        end
    end
    if props.variants then
        for type_name, type_variants in pairs(props.variants) do
            self._variants[type_name] = {}
            for variant_name, style in pairs(type_variants) do
                self._variants[type_name][variant_name] = shallowCopy(style)
            end
        end
    end
end

--#endregion


--#region Private

--- Marks owners to update their Theme.
--- @private
function Theme:_queueUpdate()
    for owner in pairs(self._owners) do
        owner:queueUpdateTheme()
    end
end

--- Adds a Widget as a Theme owner.
--- @private
--- @param widget TreeGUI.Widget|TreeGUI.Tree
function Theme:_addOwner(widget)
    self._owners[widget] = true
end

--- Removes a Widget as a Theme owner.
--- @private
--- @param widget TreeGUI.Widget|TreeGUI.Tree
function Theme:_removeOwner(widget)
    self._owners[widget] = nil
end

--#endregion


--#region Setters

--- Sets (replaces) the style of a Widget type.
--- @param type_name TreeGUI.Enums.ThemeType
--- @param style TreeGUI.Theme.WidgetStyle
function Theme:setStyle(type_name, style)
    self._data[type_name] = shallowCopy(style)
    self:_queueUpdate()
end

--- Sets (replaces) the style of a variant of a Widget type.
--- @param type_name TreeGUI.Enums.ThemeType
--- @param variant_name string
--- @param style TreeGUI.Theme.WidgetStyle
function Theme:setVariantStyle(type_name, variant_name, style)
    self._variants[type_name] = self._variants[type_name] or {}
    self._variants[type_name][variant_name] = shallowCopy(style)
    self:_queueUpdate()
end

--- Sets (replaces) the value of a Widget style. Creates the style of the type if it doesn't exist.
--- @param type_name TreeGUI.Enums.ThemeType
--- @param key string
--- @param value any
function Theme:setStyleValue(type_name, key, value)
    local data = self._data[type_name]
    if not data then
        data = {}
        self._data[type_name] = data
    end

    if data[key] ~= value then
        data[key] = value
        self:_queueUpdate()
    end
end

--- Sets (replaces) the value of a variant of a Widget style.
--- Creates the style of the type if it doesn't exist.
--- @param type_name TreeGUI.Enums.ThemeType
--- @param variant_name string
--- @param key string
--- @param value any
function Theme:setVariantStyleValue(type_name, variant_name, key, value)
    self._variants[type_name] = self._variants[type_name] or {}
    self._variants[type_name][variant_name] = self._variants[type_name][variant_name] or {}

    local style = self._variants[type_name][variant_name] --- @cast style TreeGUI.Theme.WidgetStyle
    if style[key] ~= value then
        style[key] = value
        self:_queueUpdate()
    end
end

--#endregion


--#region Getters

--- Returns the value of a Widget style. `false` is a valid value; only absence returns `nil`.
--- @nodiscard
--- @param type_name TreeGUI.Enums.ThemeType
--- @param key string
--- @return any value
function Theme:getStyleValue(type_name, key)
    local data = self._data[type_name]
    if data then return data[key] end
    return nil
end

--- Returns the value of variant of a Widget style. `false` is a valid value; only absence returns `nil`.
--- @nodiscard
--- @param type_name TreeGUI.Enums.ThemeType
--- @param variant_name string
--- @param key string
--- @return any value
function Theme:getVariantStyleValue(type_name, variant_name, key)
    local type_variants = self._variants[type_name]
    if type_variants then
        local style = type_variants[variant_name] --- @cast style TreeGUI.Theme.WidgetStyle?
        if style then
            return style[key]
        end
    end
    return nil
end

--#endregion


return Theme
