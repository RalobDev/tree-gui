local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Theme = require(ROOT .. ".resources.theme") --- @type TreeGUI.Theme
local DefaultColor = require(ROOT .. ".resources.default_color") --- @type TreeGUI.DefaultColor
local StyleBox = require(ROOT .. ".resources.style_box") --- @type TreeGUI.StyleBox
local TextSettings = require(ROOT .. ".resources.text_settings") --- @type TreeGUI.TextSettings

local COLOR = DefaultColor.dark

local theme = Theme:new {
    lock = true,
    data = {
        Widget = {
            margin_left = 0,
            margin_top = 0,
            margin_right = 0,
            margin_bottom = 0
        },
        Button = {
            text_settings = TextSettings:new { lock = true },
            style_box_normal = StyleBox:new {
                lock = true,
                color = COLOR.primary,
                corners_radius = 16
            },
            style_box_hover = StyleBox:new {
                lock = true,
                color = COLOR.primary_hover,
                corners_radius = 16
            },
            style_box_pressed = StyleBox:new {
                lock = true,
                color = COLOR.primary_pressed,
                corners_radius = 16
            },
            style_box_focus = StyleBox:new {
                lock = true,
                draw_center = false,
                corners_radius = 20,
                border_color = COLOR.border_focus,
                borders_width = 2,
                expand_margins = 4
            },
            style_box_disabled = StyleBox:new {
                lock = true,
                color = COLOR.primary_disabled,
                corners_radius = 16
            },
            font_normal_color = COLOR.on_primary,
            font_disabled_color = COLOR.on_primary_disabled,
        },
        Container = {
            padding_left = 0,
            padding_top = 0,
            padding_right = 0,
            padding_bottom = 0
        },
        Label = { text_settings = TextSettings:new { lock = true } },
        Panel = {
            style_box = StyleBox:new {
                lock = true,
                color = COLOR.surface,
                corners_radius = 8,
                borders_width = 2,
                border_color = COLOR.border
            }
        },
        StackContainer = { separation = 4 },
        StackContainerH = { separation = 4 },
        StackContainerV = { separation = 4 },
    }
}

return theme
