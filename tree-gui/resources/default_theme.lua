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
        Container = {
            padding_left = 0,
            padding_top = 0,
            padding_right = 0,
            padding_bottom = 0
        },
        Label = { text_settings = TextSettings:new() },
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
        HStackContainer = { separation = 4 },
        VStackContainer = { separation = 4 },
    }
}

return theme
