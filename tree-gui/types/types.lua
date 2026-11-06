--- Way in which a Widget is positioned.
--- @alias TreeGUI.LayoutMode
--- | "POSITION" Positions the Widget using its position.
--- | "ANCHOR" Positions the Widget using anchors relative to the parent.

--- How a Widget positions and sizes in a Container.
--- @alias TreeGUI.SizeFlags
--- | "FILL"
--- | "SHRINK_BEGIN"
--- | "SHRINK_CENTER"
--- | "SHRINK_END"
--- | "EXPAND_FILL"
--- | "EXPAND_SHRINK_BEGIN"
--- | "EXPAND_SHRINK_CENTER"
--- | "EXPAND_SHRINK_END"

--- Represents the alignment of a Widget's SizeFlags.
--- @alias TreeGUI.SizeFlagsAlignment
--- | "BEGIN"
--- | "CENTER"
--- | "END"
--- | "FILL"

--- Direction in which the Widget will grow.
--- @alias TreeGUI.GrowDirection
--- | "BEGIN"
--- | "END"
--- | "BOTH"

--- @alias TreeGUI.AnchorPreset
--- | "TOP_LEFT"
--- | "TOP_CENTER"
--- | "TOP_RIGHT"
--- | "CENTER_LEFT"
--- | "CENTER"
--- | "CENTER_RIGHT"
--- | "BOTTOM_LEFT"
--- | "BOTTOM_CENTER"
--- | "BOTTOM_RIGHT"
--- | "HORIZONTAL_WIDE_BEGIN"
--- | "HORIZONTAL_WIDE_CENTER"
--- | "HORIZONTAL_WIDE_END"
--- | "VERTICAL_WIDE_BEGIN"
--- | "VERTICAL_WIDE_CENTER"
--- | "VERTICAL_WIDE_END"
--- | "FULL_RECT"

--- @alias TreeGUI.DebugMode
--- | "INHERITED"
--- | "ENABLED"
--- | "DISABLED"

--- @alias TreeGUI.MouseFilter
--- | "STOP" Receives the event and consumes it.
--- | "PASS" Receives the event; if not consumed by the handler, it goes to the parent.
--- | "IGNORE" Never the target of mouse events (its children still can be).

--- @alias TreeGUI.FocusMode
--- | "NONE"  Cannot be focused.
--- | "CLICK" Focus only by mouse click.
--- | "ALL"   Focus by click and by keyboard navigation.

--- @alias TreeGUI.FocusSide
--- | "left"
--- | "top"
--- | "right"
--- | "bottom"
--- | "next"
--- | "previous"
