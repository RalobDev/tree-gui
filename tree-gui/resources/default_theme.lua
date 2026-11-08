local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Theme = require(ROOT .. ".resources.theme") --- @type TreeGUI.Theme
local DefaultColor = require(ROOT .. ".resources.default_color") --- @type TreeGUI.DefaultColor
local StyleBox = require(ROOT .. ".resources.style_box") --- @type TreeGUI.StyleBox

local COLOR = DefaultColor.dark

local theme = Theme:new {
    data = {
        Widget = {
            margin_left = 0,
            margin_top = 0,
            margin_right = 0,
            margin_bottom = 0
        },
        Container = {
            padding_left = 0,
            padding_top = 0,
            padding_right = 0,
            padding_bottom = 0
        },
        Panel = {
            style_box = StyleBox:new {
                color = COLOR.surface,
                corner_radius_top_left = 8,
                corner_radius_top_right = 8,
                corner_radius_bottom_right = 8,
                corner_radius_bottom_left = 8,
                border_width_left = 2,
                border_width_top = 2,
                border_width_right = 2,
                border_width_bottom = 2,
                border_color = COLOR.border
            }
        },
        StackContainer = { separation = 4 },
        HStackContainer = { separation = 4 },
        VStackContainer = { separation = 4 },
    }
}

return theme
