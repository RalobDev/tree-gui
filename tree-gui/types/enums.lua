--- @class TreeGUI.Enums
local Enums = {}

--- @enum TreeGUI.Enums.ClassName
Enums.ClassName = {
    Class = "Class",
    ColorRect = "ColorRect",
    Container = "Container",
    Panel = "Panel",
    Resource = "Resource",
    Signal = "Signal",
    StackContainer = "StackContainer",
    StackContainerH = "StackContainerH",
    StackContainerV = "StackContainerV",
    StyleBox = "StyleBox",
    Theme = "Theme",
    Tree = "Tree",
    Widget = "Widget",
}

--- @enum TreeGUI.Enums.ThemeType
Enums.ThemeType = {
    ColorRect = "ColorRect",
    Container = "Container",
    Panel = "Panel",
    StackContainer = "StackContainer",
    StackContainerH = "StackContainerH",
    StackContainerV = "StackContainerV",
    Widget = "Widget"
}

--- Way in which a Widget is positioned.
--- @enum TreeGUI.Enums.LayoutMode
Enums.LayoutMode = {
    POSITION = "POSITION", -- Positions the Widget using anchors relative to the parent.
    ANCHOR = "ANCHOR"      -- Positions the Widget using its position.
}

--- How a Widget positions and sizes in a Container.
--- @enum TreeGUI.Enums.SizeFlags
Enums.SizeFlags = {
    FILL = "FILL",
    SHRINK_BEGIN = "SHRINK_BEGIN",
    SHRINK_CENTER = "SHRINK_CENTER",
    SHRINK_END = "SHRINK_END",
    EXPAND_FILL = "EXPAND_FILL",
    EXPAND_SHRINK_BEGIN = "EXPAND_SHRINK_BEGIN",
    EXPAND_SHRINK_CENTER = "EXPAND_SHRINK_CENTER",
    EXPAND_SHRINK_END = "EXPAND_SHRINK_END"
}

--- Represents the alignment of a Widget's SizeFlags.
--- @enum TreeGUI.Enums.SizeFlagsAlignment
Enums.SizeFlagsAlignment = {
    BEGIN = "BEGIN",
    CENTER = "CENTER",
    END = "END",
    FILL = "FILL"
}

--- Direction in which the Widget will grow.
--- @enum TreeGUI.Enums.GrowDirection
Enums.GrowDirection = {
    BEGIN = "BEGIN",
    END = "END",
    BOTH = "BOTH"
}

--- @enum TreeGUI.Enums.AnchorPreset
Enums.AnchorPreset = {
    TOP_LEFT = "TOP_LEFT",
    TOP_CENTER = "TOP_CENTER",
    TOP_RIGHT = "TOP_RIGHT",
    CENTER_LEFT = "CENTER_LEFT",
    CENTER = "CENTER",
    CENTER_RIGHT = "CENTER_RIGHT",
    BOTTOM_LEFT = "BOTTOM_LEFT",
    BOTTOM_CENTER = "BOTTOM_CENTER",
    BOTTOM_RIGHT = "BOTTOM_RIGHT",
    HORIZONTAL_WIDE_BEGIN = "HORIZONTAL_WIDE_BEGIN",
    HORIZONTAL_WIDE_CENTER = "HORIZONTAL_WIDE_CENTER",
    HORIZONTAL_WIDE_END = "HORIZONTAL_WIDE_END",
    VERTICAL_WIDE_BEGIN = "VERTICAL_WIDE_BEGIN",
    VERTICAL_WIDE_CENTER = "VERTICAL_WIDE_CENTER",
    VERTICAL_WIDE_END = "VERTICAL_WIDE_END",
    FULL_RECT = "FULL_RECT"
}

--- @enum TreeGUI.Enums.DebugMode
Enums.DebugMode = {
    INHERITED = "INHERITED",
    ENABLED = "ENABLED",
    DISABLED = "DISABLED"
}

--- @enum TreeGUI.Enums.MouseFilter
Enums.MouseFilter = {
    STOP = "STOP",  -- Receives the event and consumes it.
    PASS = "PASS",  -- Receives the event; if not consumed by the handler, it goes to the parent.
    IGNORE = "IGNORE" -- Never the target of mouse events (its children still can be).
}

--- @enum TreeGUI.Enums.FocusMode
Enums.FocusMode = {
    NONE = "NONE",  -- Cannot be focused.
    CLICK = "CLICK", -- Focus only by mouse click.
    ALL = "ALL"    -- Focus by click and by keyboard navigation.
}

--- @enum TreeGUI.Enums.FocusSide
Enums.FocusSide = {
    LEFT = "LEFT",
    TOP = "TOP",
    RIGHT = "RIGHT",
    BOTTOM = "BOTTOM",
    NEXT = "NEXT",
    PREVIOUS = "PREVIOUS"
}

--- @enum TreeGUI.Enums.Orientation
Enums.Orientation = {
    HORIZONTAL = "HORIZONTAL",
    VERTICAL = "VERTICAL"
}

return Enums
