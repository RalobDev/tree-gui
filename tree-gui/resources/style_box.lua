local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Resource = require(ROOT .. ".resources.resource") --- @type TreeGUI.Resource

--- @class TreeGUI.StyleBox: TreeGUI.Resource
--- @field private _color TreeGUI.Color
--- @field private _draw_center boolean
--- @field private _skew_x number
--- @field private _skew_y number
--- @field private _border_width_left number
--- @field private _border_width_top number
--- @field private _border_width_right number
--- @field private _border_width_bottom number
--- @field private _border_color TreeGUI.Color
--- @field private _border_blend boolean
--- @field private _corner_radius_top_left number
--- @field private _corner_radius_top_right number
--- @field private _corner_radius_bottom_right number
--- @field private _corner_radius_bottom_left number
--- @field private _corner_detail number
--- @field private _expand_margin_left number
--- @field private _expand_margin_top number
--- @field private _expand_margin_right number
--- @field private _expand_margin_bottom number
--- @field private _shadow_color TreeGUI.Color
--- @field private _shadow_size number
--- @field private _shadow_offset_x number
--- @field private _shadow_offset_y number
--- @field private _anti_aliasing boolean
--- @field private _anti_aliasing_size number
local StyleBox = Resource:extend("StyleBox")


--#region Definitions

--- @class TreeGUI.StyleBox.Props
--- @field color TreeGUI.Color?
--- @field draw_center boolean?
--- @field skew_x number?
--- @field skew_y number?
--- @field border_width_left number?
--- @field border_width_top number?
--- @field border_width_right number?
--- @field border_width_bottom number?
--- @field border_color TreeGUI.Color?
--- @field border_blend boolean?
--- @field corner_radius_top_left number?
--- @field corner_radius_top_right number?
--- @field corner_radius_bottom_right number?
--- @field corner_radius_bottom_left number?
--- @field corner_detail number?
--- @field expand_margin_left number?
--- @field expand_margin_top number?
--- @field expand_margin_right number?
--- @field expand_margin_bottom number?
--- @field shadow_color TreeGUI.Color?
--- @field shadow_size number?
--- @field shadow_offset_x number?
--- @field shadow_offset_y number?
--- @field anti_aliasing boolean?
--- @field anti_aliasing_size number?

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

    obj._color = { 0.6, 0.6, 0.6, 1 }
    obj._draw_center = true
    obj._skew_x = 0
    obj._skew_y = 0
    obj._border_width_left = 0
    obj._border_width_top = 0
    obj._border_width_right = 0
    obj._border_width_bottom = 0
    obj._border_color = { 0.8, 0.8, 0.8, 1 }
    obj._border_blend = false
    obj._corner_radius_top_left = 0
    obj._corner_radius_top_right = 0
    obj._corner_radius_bottom_right = 0
    obj._corner_radius_bottom_left = 0
    obj._corner_detail = 8
    obj._expand_margin_left = 0
    obj._expand_margin_top = 0
    obj._expand_margin_right = 0
    obj._expand_margin_bottom = 0
    obj._shadow_color = { 0, 0, 0, 0 }
    obj._shadow_size = 0
    obj._shadow_offset_x = 0
    obj._shadow_offset_y = 0
    obj._anti_aliasing = true
    obj._anti_aliasing_size = 1

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
    -- Apply properties with setters.
end

--#endregion


return StyleBox
