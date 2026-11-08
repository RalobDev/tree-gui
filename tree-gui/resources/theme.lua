local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Resource = require(ROOT .. ".resources.resource") --- @type TreeGUI.Resource
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.Theme: TreeGUI.Resource
--- @field private _data TreeGUI.Theme.Data Styles by Widget type name (e.g. "Container").
--- @field private _variants TreeGUI.Theme.Variants Styles by Widget type name and variant name.
local Theme = Resource:extend("Theme")


--#region Definitions

--- @class TreeGUI.Theme.Props: TreeGUI.Resource.Props
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

--- @param value any
--- @return boolean
local function isResource(value)
    return type(value) == "table" and value.is ~= nil and value:is(Enums.ClassName.Resource) == true
end

--- Appends the values of a style to `list`.
--- @param style table?
--- @param list any[]
local function collectValues(style, list)
    if style then
        for _, value in pairs(style) do list[#list + 1] = value end
    end
end

--#endregion


--#region Public

--- Instantiates a new Theme.
--- The style tables are copied, so mutating `data` afterwards does not affect the Theme.
--- @nodiscard
--- @param props TreeGUI.Theme.Props?
--- @return TreeGUI.Theme self
function Theme:new(props)
    local obj = Resource.new(self)

    obj._data = {}
    obj._variants = {}

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.Theme.Props
function Theme:configure(props)
    self:_checkLock()

    self:_batch(self._applyProps, props)

    Resource.configure(self, props)
end

--#endregion


--#region Private

--- @private
--- @param props TreeGUI.Theme.Props
function Theme:_applyProps(props)
    if props.data then
        for type_name, style in pairs(props.data) do
            self:setStyle(type_name --[[@as TreeGUI.Enums.ThemeType]], style)
        end
    end
    if props.variants then
        for type_name, type_variants in pairs(props.variants) do
            local old_values = {} --- @type any[]
            for _, old_style in pairs(self._variants[type_name] or {}) do collectValues(old_style, old_values) end

            local new_variants = {}
            for variant_name, style in pairs(type_variants) do
                new_variants[variant_name] = shallowCopy(style)
                self:_adoptStyleValues(new_variants[variant_name])
            end
            self._variants[type_name] = new_variants

            self:_releaseValues(old_values)
            self:_emitChanged()
        end
    end
end

--- Starts observing the Resources inside a style.
--- @private
--- @param style table
function Theme:_adoptStyleValues(style)
    for _, value in pairs(style) do
        if isResource(value) then self:_adoptSubResource(value) end
    end
end

--- Stops observing the Resources in `values` that are no longer referenced by any style.
--- @private
--- @param values any[]
function Theme:_releaseValues(values)
    for _, value in ipairs(values) do
        if isResource(value) and not self:_isReferenced(value) then
            self:_releaseSubResource(value)
        end
    end
end

--- @private
--- @param value any
--- @return boolean
function Theme:_isReferenced(value)
    for _, style in pairs(self._data) do
        for _, v in pairs(style) do
            if v == value then return true end
        end
    end
    for _, type_variants in pairs(self._variants) do
        for _, style in pairs(type_variants) do
            for _, v in pairs(style) do
                if v == value then return true end
            end
        end
    end
    return false
end

--#endregion


--#region Setters

--- Sets (replaces) the style of a Widget type.
--- @param type_name TreeGUI.Enums.ThemeType
--- @param style TreeGUI.Theme.WidgetStyle
function Theme:setStyle(type_name, style)
    self:_checkLock()
    local old_values = {} --- @type any[]
    collectValues(self._data[type_name], old_values)

    local copy = shallowCopy(style)
    self._data[type_name] = copy
    self:_adoptStyleValues(copy)
    self:_releaseValues(old_values)
    self:_emitChanged()
end

--- Sets (replaces) the style of a variant of a Widget type.
--- @param type_name TreeGUI.Enums.ThemeType
--- @param variant_name string
--- @param style TreeGUI.Theme.WidgetStyle
function Theme:setVariantStyle(type_name, variant_name, style)
    self:_checkLock()
    self._variants[type_name] = self._variants[type_name] or {}

    local old_values = {} --- @type any[]
    collectValues(self._variants[type_name][variant_name], old_values)

    local copy = shallowCopy(style)
    self._variants[type_name][variant_name] = copy
    self:_adoptStyleValues(copy)
    self:_releaseValues(old_values)
    self:_emitChanged()
end

--- Sets (replaces) the value of a Widget style. Creates the style of the type if it doesn't exist.
--- @param type_name TreeGUI.Enums.ThemeType
--- @param key string
--- @param value any
function Theme:setStyleValue(type_name, key, value)
    self:_checkLock()
    local data = self._data[type_name]
    if not data then
        data = {}
        self._data[type_name] = data
    end

    local old = data[key]
    if old ~= value then
        data[key] = value
        if isResource(value) then self:_adoptSubResource(value) end
        self:_releaseValues({ old })
        self:_emitChanged()
    end
end

--- Sets (replaces) the value of a variant of a Widget style.
--- Creates the style of the type if it doesn't exist.
--- @param type_name TreeGUI.Enums.ThemeType
--- @param variant_name string
--- @param key string
--- @param value any
function Theme:setVariantStyleValue(type_name, variant_name, key, value)
    self:_checkLock()
    self._variants[type_name] = self._variants[type_name] or {}
    self._variants[type_name][variant_name] = self._variants[type_name][variant_name] or {}

    local style = self._variants[type_name][variant_name] --- @cast style TreeGUI.Theme.WidgetStyle
    local old = style[key]
    if old ~= value then
        style[key] = value
        if isResource(value) then self:_adoptSubResource(value) end
        self:_releaseValues({ old })
        self:_emitChanged()
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
