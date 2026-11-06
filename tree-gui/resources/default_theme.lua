local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Theme = require(ROOT .. ".resources.theme") --- @type TreeGUI.Theme

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
        }
    }
}

return theme
