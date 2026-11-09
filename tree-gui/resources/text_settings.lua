local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Resource = require(ROOT .. ".resources.resource") --- @type TreeGUI.Resource

--- @class TreeGUI.TextSettings: TreeGUI.Resource
--- @field private _font love.Font?
--- @field private _file string?
--- @field private _size number
--- @field private _hinting love.HintingMode
--- @field private _dpiscale number
--- @field private _color TreeGUI.Color
--- @field private _fallbacks love.Font[]?
--- @field private _filter_min love.FilterMode
--- @field private _filter_mag love.FilterMode
--- @field private _filter_anisotropy number
--- @field private _line_height number
local TextSettings = Resource:extend("TextSettings")

local HINTING_MODES = { normal = true, light = true, mono = true, none = true }
local FILTER_MODES = { linear = true, nearest = true }

--- Fonts already built, shared between TextSettings with identical settings.
--- Weak values: a Font stays alive only while some TextSettings uses it.
--- @type table<string, love.Font>
local FONT_CACHE = setmetatable({}, { __mode = "v" })


--#region Definitions

--- @class TreeGUI.TextSettings.Props: TreeGUI.Resource.Props
--- @field file string|false? Path to a font file. `false` resets to LÖVE's default font.
--- @field size number?
--- @field hinting love.HintingMode?
--- @field dpiscale number?
--- @field color TreeGUI.Color?
--- @field fallbacks love.Font[]? An empty table clears the fallbacks.
--- @field filter_min love.FilterMode?
--- @field filter_mag love.FilterMode?
--- @field filter_anisotropy number?
--- @field line_height number?

--#endregion


--#region Local

--- Validates whether a file path points to a readable font file supported by LÖVE.
--- @nodiscard
--- @param file string
--- @return boolean is_valid
local function isFontValid(file)
    local info = love.filesystem.getInfo(file)
    if not info or info.type ~= "file" then return false end

    local ok, result = pcall(love.graphics.newFont, file)
    if ok then
        result:release()
        return true
    end

    return false
end

--- @nodiscard
--- @param value any
--- @return boolean
local function isFont(value)
    return type(value) == "userdata" and value.typeOf ~= nil and value:typeOf("Font") == true
end

--- @param value any
--- @param name string
local function checkPositiveNumber(value, name)
    if type(value) ~= "number" or value ~= value or value <= 0 then
        error(string.format("Invalid %s: expected a number greater than 0, got %s.", name, tostring(value)), 3)
    end
end

--- Validates the list and returns a private copy of it (or `nil` if it is empty).
--- @nodiscard
--- @param fonts love.Font[]
--- @return love.Font[]?
local function copyFallbacks(fonts)
    local copy = {}
    for i = 1, #fonts do
        if not isFont(fonts[i]) then
            error(string.format("Invalid fallback #%d: expected a love.Font, got %s.", i, tostring(fonts[i])), 3)
        end
        copy[i] = fonts[i]
    end

    if #copy == 0 then return nil end
    return copy
end

--- @nodiscard
--- @param a love.Font[]?
--- @param b love.Font[]?
--- @return boolean
local function sameFallbacks(a, b)
    if a == nil or b == nil then return a == b end
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end

--#endregion


--#region Public

--- Instantiates a new TextSettings.
--- @nodiscard
--- @generic T: TreeGUI.TextSettings
--- @param self T
--- @param props TreeGUI.TextSettings.Props?
--- @return T self
function TextSettings:new(props)
    local obj = Resource.new(self) --- @cast obj TreeGUI.TextSettings

    obj._font = nil
    obj._file = nil
    obj._size = 12
    obj._hinting = "normal"
    obj._dpiscale = love.graphics.getDPIScale()
    obj._color = { 1, 1, 1, 1 }
    obj._fallbacks = nil
    obj._filter_min, obj._filter_mag, obj._filter_anisotropy = love.graphics.getDefaultFilter()
    obj._line_height = 1

    if props then obj:configure(props) end

    return obj
end

--- @param props TreeGUI.TextSettings.Props
--- @return self
function TextSettings:configure(props)
    self:_checkLock()
    self:_batch(self._applyProps, props)

    Resource.configure(self, props)
    return self
end

--#endregion


--#region Private

--- @private
--- @param props TreeGUI.TextSettings.Props
function TextSettings:_applyProps(props)
    if props.file ~= nil then self:setFile(props.file or nil) end
    if props.size ~= nil then self:setSize(props.size) end
    if props.hinting ~= nil then self:setHinting(props.hinting) end
    if props.dpiscale ~= nil then self:setDPIScale(props.dpiscale) end
    if props.color ~= nil then self:setColorTable(props.color) end
    if props.fallbacks ~= nil then self:setFallbacksTable(props.fallbacks) end
    if props.filter_min ~= nil then self:setFilterMin(props.filter_min) end
    if props.filter_mag ~= nil then self:setFilterMag(props.filter_mag) end
    if props.filter_anisotropy ~= nil then self:setFilterAnisotropy(props.filter_anisotropy) end
    if props.line_height ~= nil then self:setLineHeight(props.line_height) end
end

--- Discards the current `love.Font` (it is rebuilt on the next `getFont()`) and notifies the owners.
--- @private
function TextSettings:_invalidateFont()
    self._font = nil
    self:_emitChanged()
end

--- Builds (or fetches from the cache) the `love.Font` for the current settings.
--- @private
--- @nodiscard
--- @return love.Font
function TextSettings:_buildFont()
    local fallbacks = self._fallbacks

    local parts = {
        self._file or "",
        self._size,
        self._hinting,
        self._dpiscale,
        self._filter_min,
        self._filter_mag,
        self._filter_anisotropy,
        self._line_height,
    }
    if fallbacks then
        for i = 1, #fallbacks do parts[#parts + 1] = tostring(fallbacks[i]) end
    end

    local key = table.concat(parts, "|")
    local cached = FONT_CACHE[key]
    if cached then return cached end

    local font --- @type love.Font
    if self._file then
        font = love.graphics.newFont(self._file, self._size, self._hinting, self._dpiscale)
    else
        font = love.graphics.newFont(self._size, self._hinting, self._dpiscale)
    end

    if fallbacks then font:setFallbacks(unpack(fallbacks)) end
    font:setFilter(self._filter_min, self._filter_mag, self._filter_anisotropy)
    font:setLineHeight(self._line_height)

    FONT_CACHE[key] = font
    return font
end

--#endregion


--#region Setters

--- Sets the font file. Pass `nil` to go back to LÖVE's default font.
--- @param file string?
function TextSettings:setFile(file)
    self:_checkLock()
    if self._file ~= file then
        if file ~= nil and (type(file) ~= "string" or not isFontValid(file)) then
            error(string.format('The file "%s" is not a valid font.', tostring(file)), 2)
        end

        self._file = file
        self:_invalidateFont()
    end
end

--- Sets the font size in points.
--- @param size number
function TextSettings:setSize(size)
    self:_checkLock()
    checkPositiveNumber(size, "font size")
    if self._size ~= size then
        self._size = size
        self:_invalidateFont()
    end
end

--- Sets the font hinting mode.
--- @param hinting love.HintingMode
function TextSettings:setHinting(hinting)
    self:_checkLock()
    if not HINTING_MODES[hinting] then
        error(string.format('Invalid hinting mode "%s".', tostring(hinting)), 2)
    end
    if self._hinting ~= hinting then
        self._hinting = hinting
        self:_invalidateFont()
    end
end

--- Sets the DPI scale used to rasterize the font.
--- @param dpiscale number
function TextSettings:setDPIScale(dpiscale)
    self:_checkLock()
    checkPositiveNumber(dpiscale, "font DPI scale")
    if self._dpiscale ~= dpiscale then
        self._dpiscale = dpiscale
        self:_invalidateFont()
    end
end

--- Sets the text color. The color does not affect the `love.Font`, so it never rebuilds it.
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
function TextSettings:setColor(r, g, b, a)
    self:_checkLock()
    if self:_writeColor(self._color, r, g, b, a) then
        self:_emitChanged()
    end
end

--- Sets the text color. The color does not affect the `love.Font`, so it never rebuilds it.
--- @param color TreeGUI.Color
function TextSettings:setColorTable(color)
    self:_checkLock()
    self:setColor(unpack(color))
end

--- Sets the fallback fonts used for missing glyphs. Pass nothing to clear them.
--- @param ... love.Font
function TextSettings:setFallbacks(...)
    self:_checkLock()
    self:setFallbacksTable({ ... })
end

--- Sets the fallback fonts used for missing glyphs. An empty table clears them.
--- @param fonts love.Font[]
function TextSettings:setFallbacksTable(fonts)
    self:_checkLock()
    local fallbacks = copyFallbacks(fonts)
    if not sameFallbacks(self._fallbacks, fallbacks) then
        self._fallbacks = fallbacks
        self:_invalidateFont()
    end
end

--- Sets the minification, magnification and anisotropy filters of the font texture.
--- @param min love.FilterMode
--- @param mag love.FilterMode
--- @param anisotropy number?
function TextSettings:setFilter(min, mag, anisotropy)
    self:_checkLock()
    if not FILTER_MODES[min] then error(string.format('Invalid minification filter "%s".', tostring(min)), 2) end
    if not FILTER_MODES[mag] then error(string.format('Invalid magnification filter "%s".', tostring(mag)), 2) end
    anisotropy = anisotropy or 1
    checkPositiveNumber(anisotropy, "font anisotropy")

    if
        self._filter_min ~= min
        or self._filter_mag ~= mag
        or self._filter_anisotropy ~= anisotropy
    then
        self._filter_min = min
        self._filter_mag = mag
        self._filter_anisotropy = anisotropy
        self:_invalidateFont()
    end
end

--- Sets the minification filter of the font texture.
--- @param min love.FilterMode
function TextSettings:setFilterMin(min)
    self:_checkLock()
    self:setFilter(min, self._filter_mag, self._filter_anisotropy)
end

--- Sets the magnification filter of the font texture.
--- @param mag love.FilterMode
function TextSettings:setFilterMag(mag)
    self:_checkLock()
    self:setFilter(self._filter_min, mag, self._filter_anisotropy)
end

--- Sets the anisotropy of the font texture.
--- @param anisotropy number
function TextSettings:setFilterAnisotropy(anisotropy)
    self:_checkLock()
    self:setFilter(self._filter_min, self._filter_mag, anisotropy)
end

--- Sets the line height multiplier for multi-line text (1 is the font's natural spacing).
--- @param height number
function TextSettings:setLineHeight(height)
    self:_checkLock()
    checkPositiveNumber(height, "font line height")
    if self._line_height ~= height then
        self._line_height = height
        self:_invalidateFont()
    end
end

--#endregion


--#region Getters

--- Gets the `love.Font` for the current settings, building it if needed.
--- NOTE: The Font can be shared with other TextSettings that have identical settings.
--- Do not change it directly (`setFilter`, `setLineHeight`, ...), use the TextSettings setters instead.
--- @nodiscard
--- @return love.Font font
function TextSettings:getFont()
    local font = self._font
    if not font then
        font = self:_buildFont()
        self._font = font
    end
    return font
end

--- Gets the font file, or `nil` if the default font is used.
--- @nodiscard
--- @return string? file
function TextSettings:getFile()
    return self._file
end

--- Gets the font size in points.
--- @nodiscard
--- @return number size
function TextSettings:getSize()
    return self._size
end

--- Gets the font hinting mode.
--- @nodiscard
--- @return love.HintingMode hinting
function TextSettings:getHinting()
    return self._hinting
end

--- Gets the DPI scale used to rasterize the font.
--- @nodiscard
--- @return number dpiscale
function TextSettings:getDPIScale()
    return self._dpiscale
end

--- Gets the text color.
--- @nodiscard
--- @return number r, number g, number b, number a
function TextSettings:getColor()
    local color = self._color
    return color[1], color[2], color[3], color[4]
end

--- Gets a copy of the fallback fonts list, or `nil` if there are none.
--- @nodiscard
--- @return love.Font[]? fallbacks
function TextSettings:getFallbacks()
    local fallbacks = self._fallbacks
    if not fallbacks then return nil end

    local copy = {}
    for i = 1, #fallbacks do copy[i] = fallbacks[i] end
    return copy
end

--- Gets the minification, magnification and anisotropy filters of the font texture.
--- @nodiscard
--- @return love.FilterMode min, love.FilterMode mag, number anisotropy
function TextSettings:getFilter()
    return self._filter_min, self._filter_mag, self._filter_anisotropy
end

--- Gets the minification filter of the font texture.
--- @nodiscard
--- @return love.FilterMode min
function TextSettings:getFilterMin()
    return self._filter_min
end

--- Gets the magnification filter of the font texture.
--- @nodiscard
--- @return love.FilterMode mag
function TextSettings:getFilterMag()
    return self._filter_mag
end

--- Gets the anisotropy of the font texture.
--- @nodiscard
--- @return number anisotropy
function TextSettings:getFilterAnisotropy()
    return self._filter_anisotropy
end

--- Gets the line height multiplier.
--- @nodiscard
--- @return number height
function TextSettings:getLineHeight()
    return self._line_height
end

--#endregion


return TextSettings
