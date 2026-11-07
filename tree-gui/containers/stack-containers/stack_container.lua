local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local Container = require(ROOT .. ".containers.container") --- @type TreeGUI.Container
local Layout = require(ROOT .. ".tools.layout_tool") --- @type TreeGUI.Layout
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- Container that arranges its children in a single line (horizontal or vertical).
--- @class TreeGUI.StackContainer: TreeGUI.Container
--- @field private _orientation TreeGUI.Enums.Orientation Axis of the line. Ignored by StackContainerH/V, which fix it via _getOrientation().
--- @field protected _style_override TreeGUI.Theme.StackContainerStyle Overrides for margins, paddings and separation.
local StackContainer = Container:extend("StackContainer")


--#region Definitions

--- @class TreeGUI.StackContainer.Props: TreeGUI.Container.Props
--- @field orientation TreeGUI.Enums.Orientation?
--- @field separation number?

--#endregion


--#region Public

--- Instantiates a new StackContainer.
--- @nodiscard
--- @generic T: TreeGUI.StackContainer
--- @param self T
--- @param props TreeGUI.StackContainer.Props?
--- @return T
function StackContainer:new(props)
    local obj = Container.new(self, props) --- @cast obj TreeGUI.StackContainer

    obj._orientation = obj._orientation or Enums.Orientation.VERTICAL

    return obj
end

--- @param props TreeGUI.StackContainer.Props
function StackContainer:configure(props)
    Container.configure(self, props)

    if props.orientation then self:setOrientation(props.orientation) end
    if props.separation then self:setSeparation(props.separation) end
end

--#endregion


--#region Protected

--- @protected
function StackContainer:_sortChildren()
    local children = self:_getManagedChildren()
    local count = #children
    if count == 0 then return end

    local vertical = self:_getOrientation() == Enums.Orientation.VERTICAL
    local separation = self:_getStyleValue("separation")
    local x, y, width, height = self:_getContentRect()

    local main_size = vertical and height or width
    local cross_size = vertical and width or height

    local sizes, ratios = {}, {} --- @type number[], number[]
    local total_min, total_ratio = 0, 0

    for i, child in ipairs(children) do
        local cw, ch = child:_getOuterMinimumSize()
        sizes[i] = vertical and ch or cw
        total_min = total_min + sizes[i]

        local flags = vertical and child._size_flags_vertical or child._size_flags_horizontal
        local expand = Layout.parseFlags(flags)

        ratios[i] = (expand and child._stretch_ratio > 0) and child._stretch_ratio or 0
        total_ratio = total_ratio + ratios[i]
    end

    -- Leftover space is shared among the expanding children, proportional to stretch_ratio.
    local free = main_size - total_min - separation * (count - 1)
    if free > 0 and total_ratio > 0 then
        for i = 1, count do
            sizes[i] = sizes[i] + free * ratios[i] / total_ratio
        end
    end

    local cursor = vertical and y or x
    for i, child in ipairs(children) do
        if vertical then
            self:_fitChildInRect(child, x, cursor, cross_size, sizes[i])
        else
            self:_fitChildInRect(child, cursor, y, sizes[i], cross_size)
        end
        cursor = cursor + sizes[i] + separation
    end
end

--- @protected
function StackContainer:_onClearStyleOverrides()
    Container._onClearStyleOverrides(self)

    self._style_override.separation = nil
end

--#endregion


--#region Setters

--- Sets the orientation of the StackContainer.
--- @param orientation TreeGUI.Enums.Orientation
function StackContainer:setOrientation(orientation)
    if orientation ~= Enums.Orientation.HORIZONTAL and orientation ~= Enums.Orientation.VERTICAL then
        error(string.format('Invalid orientation: "%s".', tostring(orientation)))
    end

    if orientation ~= self._orientation then
        self._orientation = orientation
        self:_queueLayout()
    end
end

--- Sets the StackContainer's separation (space between children). The override value takes priority over the theme.
--- If `separation` is `nil`, remove the override.
--- @param separation number?
function StackContainer:setSeparation(separation)
    self:_setStyleOverride("separation", separation)
end

--#endregion


--#region Getters

--- Returns the orientation of the StackContainer.
--- @nodiscard
--- @return TreeGUI.Enums.Orientation orientation
function StackContainer:getOrientation()
    return self:_getOrientation()
end

--- Returns the StackContainer's resolved separation,
--- this includes the one defined by Theme if overrides have not been defined.
--- @nodiscard
--- @return number separation
function StackContainer:getSeparation()
    return self:_getStyleValue("separation")
end

--- Returns the separation override by the StackContainer. Does not include the one used by Theme.
--- @nodiscard
--- @return number? separation
function StackContainer:getSeparationOverride()
    return self._style_override.separation
end

--#endregion


--#region Protected Getters

--- Returns the orientation used by the layout. StackContainerH/StackContainerV override this with a constant.
--- @protected
--- @nodiscard
--- @return TreeGUI.Enums.Orientation orientation
function StackContainer:_getOrientation()
    return self._orientation
end

--- @protected
--- @nodiscard
--- @return number width, number height
function StackContainer:_getChildrenMinimumDimensions()
    local vertical = self:_getOrientation() == Enums.Orientation.VERTICAL
    local children = self:_getManagedChildren()

    local main, cross = 0, 0
    for _, child in ipairs(children) do
        local cw, ch = child:_getOuterMinimumSize()
        if vertical then
            main, cross = main + ch, math.max(cross, cw)
        else
            main, cross = main + cw, math.max(cross, ch)
        end
    end

    if #children > 1 then
        main = main + self:_getStyleValue("separation") * (#children - 1)
    end

    if vertical then return cross, main end
    return main, cross
end

--#endregion


return StackContainer
