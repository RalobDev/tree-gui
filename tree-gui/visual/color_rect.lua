local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget
local Render = require(ROOT .. ".tools.render_tool") --- @type TreeGUI.Render

--- @class TreeGUI.ColorRect: TreeGUI.Widget
--- @field private _color TreeGUI.Color
local ColorRect = Widget:extend("ColorRect")


--#region Definitions

--- @class TreeGUI.ColorRect.Props: TreeGUI.Widget.Props
--- @field color TreeGUI.Color?

--#endregion


--#region Public

--- Instantiates a new ColorRect.
--- @nodiscard
--- @param props TreeGUI.ColorRect.Props?
--- @return self
function ColorRect:new(props)
    local obj = Widget.new(self, props)

    obj._color = {1, 1, 1, 1}

    if props then obj:configure(props) end

    return obj
end

--- Configures the ColorRect according to the values ​​passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.ColorRect.Props
function ColorRect:configure(props)
    Widget.configure(self, props)

    if props.color then self._color = props.color end
end

--#endregion


--#region Protected

--- Draws the ColorRect.
--- @protected
function ColorRect:_draw()
    Render.setColor(self._color)
    love.graphics.rectangle("fill", 0, 0, self:getWidth(), self:getHeight())
end

--#endregion


--#region Setters

--- Sets the ColorRect color.
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
function ColorRect:setColor(r, g, b, a)
    self._color[1], self._color[2], self._color[3], self._color[4] = r, g, b, a or 1
end

--- Sets the ColorRect color.
--- @param color TreeGUI.Color
function ColorRect:setColorTable(color)
    self:setColor(unpack(color))
end

--#endregion


--#region Getters

--- Returns the ColorRect color.
--- @nodiscard
--- @return number r, number g, number b, number a
function ColorRect:getColor()
    return self._color[1], self._color[2], self._color[3], self._color[4]
end

--#endregion


return ColorRect
