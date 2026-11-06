local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 4) .. "$") --- @type string

local Layout = require(ROOT .. ".tools.layout_tool") --- @type TreeGUI.Layout

--- @class TreeGUI.Widget
local Widget = {}

local POINT_PRESETS = {
    TOP_LEFT      = { 0,   0   }, TOP_CENTER    = { 0.5, 0   }, TOP_RIGHT    = { 1,   0   },
    CENTER_LEFT   = { 0,   0.5 }, CENTER        = { 0.5, 0.5 }, CENTER_RIGHT = { 1,   0.5 },
    BOTTOM_LEFT   = { 0,   1   }, BOTTOM_CENTER = { 0.5, 1   }, BOTTOM_RIGHT = { 1,   1   },
}

local WIDE_SIDE = { BEGIN = 0, CENTER = 0.5, END = 1 }


--#region Local

--- Axis anchored to a point: The Widget attaches to the anchor point and grows to the opposite side of the edge.
--- @nodiscard
--- @param anchor number
--- @param size number
--- @return number, number, number, number, TreeGUI.GrowDirection
local function pointAxis(anchor, size)
    local grow = anchor == 0 and "END" or (anchor == 1 and "BEGIN" or "BOTH")
    return anchor, anchor, -size * anchor, size * (1 - anchor), grow
end

--- Stretched axis: occupies 100% of the parent.
--- @nodiscard
--- @return number, number, number, number, TreeGUI.GrowDirection
local function wideAxis()
    return 0, 1, 0, 0, "END"
end

--#endregion


--#region Protected

--- Marks that the layout needs to be recalculated.
--- Also call setters that affect layout (min, margins, flags, anchors, paddings...).
--- @protected
function Widget:_queueLayout()
    if self._tree then self._tree:queueLayout() end
end

--- Pass 2 (top-down): position the children. Here the children are "free" (POSITION/ANCHOR).
--- Container overrides this.
--- @protected
function Widget:_layoutChildren()
    for _, child in ipairs(self._children) do
        if child._visible then
            child:_resolveFreeLayout(self._width, self._height)
            child:_layoutChildren()
        end
    end
end

--- Size of the area used as anchor reference, or nil if the Widget is not attached.
--- @protected
--- @nodiscard
--- @return number? width, number? height
function Widget:_getReferenceSize()
    local parent = self._parent
    if parent then return parent._width, parent._height end
    if self._tree then return self._tree:getDimensions() end
end

--- Calculates the rectangle of a Widget that is not under the control of a Container.
--- @protected
--- @param parent_width number
--- @param parent_height number
function Widget:_resolveFreeLayout(parent_width, parent_height)
    local min_width, min_height = self._combined_min_width, self._combined_min_height

    if self._layout_mode == "ANCHOR" then
        local r = self._pending_rect
        if r then
            self._pending_rect = nil
            self:_applyAnchoredRect(r.x, r.y, r.w, r.h, parent_width, parent_height)
        end

        local margin_left = self:getStyleValue("margin_left")
        local margin_top = self:getStyleValue("margin_top")
        local margin_right = self:getStyleValue("margin_right")
        local margin_bottom = self:getStyleValue("margin_bottom")

        local area_width = math.max(0, parent_width - margin_left - margin_right)
        local area_height = math.max(0, parent_height - margin_top - margin_bottom)

        local x, w = Layout.anchorAxis(
            self._anchor_left, self._anchor_right, area_width,
            self._offset_left, self._offset_right, min_width, self._grow_direction_horizontal
        )
        local y, h = Layout.anchorAxis(
            self._anchor_top, self._anchor_bottom, area_height,
            self._offset_top, self._offset_bottom, min_height, self._grow_direction_vertical
        )

        self._x, self._width = x + margin_left, w
        self._y, self._height = y + margin_top, h
    else -- POSITION
        self._width = math.max(self._width, min_width)
        self._height = math.max(self._height, min_height)
    end
end

--#endregion


--#region Private

--- Pass 1 (bottom-up): calculates the minimum combined size.
--- @private
function Widget:_updateMinimumDimensions()
    if not self._visible then return end

    for _, child in ipairs(self._children) do
        child:_updateMinimumDimensions()
    end

    local content_width, content_height = self:_getContentMinimumDimensions()
    self._combined_min_width = math.max(self._min_width, content_width)
    self._combined_min_height = math.max(self._min_height, content_height)
end

--#endregion


--#region Setters

--- Sets the layout mode of the Widget. In `POSITION` mode, it positions itself freely according to your
--- position; In `ANCHOR` mode, it positions itself according to its anchors and offsets.
--- NOTE: layout mode is ignored when the Widget is a child of a Container.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param layout_mode TreeGUI.LayoutMode
--- @return T
function Widget:setLayoutMode(layout_mode)
    if layout_mode ~= self._layout_mode then
        self._layout_mode = layout_mode
        self:_queueLayout()
    end

    return self
end

--- Applies a preset of anchors and offsets.
--- Without `width/height`, use the Widget's current dimensions as the desired size.
--- If this size is smaller than the minimum, the Widget grows in the direction of the preset.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param preset TreeGUI.AnchorPreset
--- @param width number?
--- @param height number?
--- @return T
function Widget:setAnchorPreset(preset, width, height)
    local w, h = width or self._width, height or self._height
    local anchor_l, anchor_r, off_l, off_r, grow_h -- horizontal
    local anchor_t, anchor_b, off_t, off_b, grow_v -- horizontal

    local point = POINT_PRESETS[preset]
    if point then
        anchor_l, anchor_r, off_l, off_r, grow_h = pointAxis(point[1], w)
        anchor_t, anchor_b, off_t, off_b, grow_v = pointAxis(point[2], h)
    elseif preset == "FULL_RECT" then
        anchor_l, anchor_r, off_l, off_r, grow_h = wideAxis()
        anchor_t, anchor_b, off_t, off_b, grow_v = wideAxis()
    else
        local kind, side = tostring(preset):match("^(%u+)_WIDE_(%u+)$")
        local anchor = WIDE_SIDE[side]
        if not anchor or (kind ~= "HORIZONTAL" and kind ~= "VERTICAL") then
            error(string.format('AnchorPreset inválido: "%s".', tostring(preset)))
        end

        if kind == "HORIZONTAL" then
            anchor_l, anchor_r, off_l, off_r, grow_h = wideAxis()
            anchor_t, anchor_b, off_t, off_b, grow_v = pointAxis(anchor, h)
        else
            anchor_t, anchor_b, off_t, off_b, grow_v = wideAxis()
            anchor_l, anchor_r, off_l, off_r, grow_h = pointAxis(anchor, w)

        end
    end

    self._layout_mode = "ANCHOR"
    self._anchor_left, self._anchor_right, self._offset_left, self._offset_right = anchor_l, anchor_r, off_l, off_r
    self._grow_direction_horizontal = grow_h
    self._anchor_top, self._anchor_bottom, self._offset_top, self._offset_bottom = anchor_t, anchor_b, off_t, off_b
    self._grow_direction_vertical = grow_v

    self:_queueLayout()

    return self
end

--- Sets the anchors of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param anchors number
--- @return T
function Widget:setAnchors(anchors)
    if
        anchors ~= self._anchor_left
        or anchors ~= self._anchor_top
        or anchors ~= self._anchor_right
        or anchors ~= self._anchor_bottom
    then
        self._anchor_left = anchors
        self._anchor_top = anchors
        self._anchor_right = anchors
        self._anchor_bottom = anchors
        self:_queueLayout()
    end

    return self
end

--- Sets then left anchor of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param anchor number
--- @return T
function Widget:setAnchorLeft(anchor)
    if anchor ~= self._anchor_left then
        self._anchor_left = anchor
        self:_queueLayout()
    end

    return self
end

--- Sets then top anchor of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param anchor number
--- @return T
function Widget:setAnchorTop(anchor)
    if anchor ~= self._anchor_top then
        self._anchor_top = anchor
        self:_queueLayout()
    end

    return self
end

--- Sets then right anchor of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param anchor number
--- @return T
function Widget:setAnchorRight(anchor)
    if anchor ~= self._anchor_right then
        self._anchor_right = anchor
        self:_queueLayout()
    end

    return self
end

--- Sets then bottom anchor of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param anchor number
--- @return T
function Widget:setAnchorBottom(anchor)
    if anchor ~= self._anchor_bottom then
        self._anchor_bottom = anchor
        self:_queueLayout()
    end

    return self
end

--- Sets the offsets of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param offsets number
--- @return T
function Widget:setOffsets(offsets)
    if
        offsets ~= self._offset_left
        or offsets ~= self._offset_top
        or offsets ~= self._offset_right
        or offsets ~= self._offset_bottom
    then
        self._offset_left = offsets
        self._offset_top = offsets
        self._offset_right = offsets
        self._offset_bottom = offsets
        self:_queueLayout()
    end

    return self
end

--- Sets the left offset of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param offset number
--- @return T
function Widget:setOffsetLeft(offset)
    if offset ~= self._offset_left then
        self._offset_left = offset
        self:_queueLayout()
    end

    return self
end

--- Sets the top offset of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param offset number
--- @return T
function Widget:setOffsetTop(offset)
    if offset ~= self._offset_top then
        self._offset_top = offset
        self:_queueLayout()
    end

    return self
end

--- Sets the right offset of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param offset number
--- @return T
function Widget:setOffsetRight(offset)
    if offset ~= self._offset_right then
        self._offset_right = offset
        self:_queueLayout()
    end

    return self
end

--- Sets the bottom offset of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param offset number
--- @return T
function Widget:setOffsetBottom(offset)
    if offset ~= self._offset_bottom then
        self._offset_bottom = offset
        self:_queueLayout()
    end

    return self
end

--- Sets the margins of the Widget. If margins is `nil`, the Theme's margins will be used.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param margins number?
--- @return T
function Widget:setMargins(margins)
    if
        margins ~= self._style_override.margin_left
        or margins ~= self._style_override.margin_top
        or margins ~= self._style_override.margin_right
        or margins ~= self._style_override.margin_bottom
    then
        self._style_override.margin_left = margins
        self._style_override.margin_top = margins
        self._style_override.margin_right = margins
        self._style_override.margin_bottom = margins
        self:_queueLayout()

        if not margins then self:queueUpdateTheme() end
    end

    return self
end

--- Sets their left margin of the Widget. If margin is `nil`, the Theme's margin will be used.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param margin number?
--- @return T
function Widget:setMarginLeft(margin)
    if margin ~= self._style_override.margin_left then
        self._style_override.margin_left = margin
        self:_queueLayout()

        if not margin then self:queueUpdateTheme() end
    end

    return self
end

--- Sets the top margin of the Widget. If margin is `nil`, the Theme's margin will be used.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param margin number?
--- @return T
function Widget:setMarginTop(margin)
    if margin ~= self._style_override.margin_top then
        self._style_override.margin_top = margin
        self:_queueLayout()

        if not margin then self:queueUpdateTheme() end
    end

    return self
end

--- Sets the right margin of the Widget. If margin is `nil`, the Theme's margin will be used.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param margin number?
--- @return T
function Widget:setMarginRight(margin)
    if margin ~= self._style_override.margin_right then
        self._style_override.margin_right = margin
        self:_queueLayout()

        if not margin then self:queueUpdateTheme() end
    end

    return self
end

--- Sets the bottom margin of the Widget. If margin is `nil`, the Theme's margin will be used.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param margin number?
--- @return T
function Widget:setMarginBottom(margin)
    if margin ~= self._style_override.margin_bottom then
        self._style_override.margin_bottom = margin
        self:_queueLayout()

        if not margin then self:queueUpdateTheme() end
    end

    return self
end

--- Sets the size flags horizontal of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param size_flags TreeGUI.SizeFlags
--- @return T
function Widget:setSizeFlagsHorizontal(size_flags)
    if size_flags ~= self._size_flags_horizontal then
        self._size_flags_horizontal = size_flags
        self:_queueLayout()
    end

    return self
end

--- Sets the size flags vertical of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param size_flags TreeGUI.SizeFlags
--- @return T
function Widget:setSizeFlagsVertical(size_flags)
    if size_flags ~= self._size_flags_vertical then
        self._size_flags_vertical = size_flags
        self:_queueLayout()
    end

    return self
end

--- Sets the Widget's stretch ratio when it is a child of a Container.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param stretch_ratio number
--- @return T
function Widget:setStretchRatio(stretch_ratio)
    if stretch_ratio ~= self._stretch_ratio then
        self._stretch_ratio = stretch_ratio
        self:_queueLayout()
    end

    return self
end

--- Sets the grow direction horizontal of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param grow_direction TreeGUI.GrowDirection
--- @return T
function Widget:setGrowDirectionHorizontal(grow_direction)
    if grow_direction ~= self._grow_direction_horizontal then
        self._grow_direction_horizontal = grow_direction
        self:_queueLayout()
    end

    return self
end

--- Sets the grow direction vertical of the Widget.
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param grow_direction TreeGUI.GrowDirection
--- @return T
function Widget:setGrowDirectionVertical(grow_direction)
    if grow_direction ~= self._grow_direction_vertical then
        self._grow_direction_vertical = grow_direction
        self:_queueLayout()
    end

    return self
end

--#endregion


--#region Getters

--- Returns the layout mode of the Widget. Basically it is the way the Widget is positioned in relation to the parent.
--- NOTE: layout mode has no influence when it is a child of a Container.
--- @nodiscard
--- @return TreeGUI.LayoutMode layout_mode
function Widget:getLayoutMode(layout_mode)
    return self._layout_mode
end

--- Gets the margins of then Widget in pixels. If margins is `nil`, the Theme's margins will be used.
--- @nodiscard
--- @return number? margin_left, number? margin_top, number? margin_right, number? margin_bottom
function Widget:getMargins()
    return self._style_override.margin_left, self._style_override.margin_top, self._style_override.margin_right, self._style_override.margin_bottom
end

--- Gets the left margin of then Widget in pixels. If margin is `nil`, the Theme's margin will be used.
--- @nodiscard
--- @return number? margin_left
function Widget:getMarginLeft()
    return self._style_override.margin_left
end

--- Gets the top margin of then Widget in pixels. If margin is `nil`, the Theme's margin will be used.
--- @nodiscard
--- @return number? margin_top
function Widget:getMarginTop()
    return self._style_override.margin_top
end

--- Gets the right margin of then Widget in pixels. If margin is `nil`, the Theme's margin will be used.
--- @nodiscard
--- @return number? margin_right
function Widget:getMarginRight()
    return self._style_override.margin_right
end

--- Gets the bottom margin of then Widget in pixels. If margin is `nil`, the Theme's margin will be used.
--- @nodiscard
--- @return number? margin_bottom
function Widget:getMarginBottom()
    return self._style_override.margin_bottom
end

--- Gets the size flags horizontal of the Widget.
--- @nodiscard
--- @return TreeGUI.SizeFlags size_flags
function Widget:getSizeFlagsHorizontal()
    return self._size_flags_horizontal
end

--- Gets the size flags vertical of the Widget.
--- @nodiscard
--- @return TreeGUI.SizeFlags size_flags
function Widget:getSizeFlagsVertical()
    return self._size_flags_vertical
end

--- Gets the Widget's stretch ratio when it is a child of a Container.
--- @nodiscard
--- @return number stretch_ratio
function Widget:getStretchRatio()
    return self._stretch_ratio
end

--- Gets the anchors of the Widget.
--- @nodiscard
--- @return number anchor_left, number anchor_top, number anchor_right, number anchor_bottom
function Widget:getAnchors()
    return self._anchor_left, self._anchor_top, self._anchor_right, self._anchor_bottom
end

--- Gets then left anchor of then Widget.
--- @nodiscard
--- @return number anchor
function Widget:getAnchorLeft()
    return self._anchor_left
end

--- Gets then top anchor of then Widget.
--- @nodiscard
--- @return number anchor
function Widget:getAnchorTop()
    return self._anchor_top
end

--- Gets then right anchor of then Widget.
--- @nodiscard
--- @return number anchor
function Widget:getAnchorRight()
    return self._anchor_right
end

--- Gets then bottom anchor of then Widget.
--- @nodiscard
--- @return number anchor
function Widget:getAnchorBottom()
    return self._anchor_bottom
end

--- Gets the offsets of the Widget.
--- @nodiscard
--- @return number offset_left, number offset_top, number offset_right, number offset_bottom
function Widget:getOffsets()
    return self._offset_left, self._offset_top, self._offset_right, self._offset_bottom
end

--- Gets the left offset of the Widget.
--- @nodiscard
--- @return number offset
function Widget:getOffsetLeft()
    return self._offset_left
end

--- Gets the top offset of the Widget.
--- @nodiscard
--- @return number offset
function Widget:getOffsetTop()
    return self._offset_top
end

--- Gets the right offset of the Widget.
--- @nodiscard
--- @return number offset
function Widget:getOffsetRight()
    return self._offset_right
end

--- Gets the bottom offset of the Widget.
--- @nodiscard
--- @return number offset
function Widget:getOffsetBottom()
    return self._offset_bottom
end

--- Gets the grow direction horizontal of the Widget.
--- @nodiscard
--- @return TreeGUI.GrowDirection grow_direction
function Widget:getGrowDirectionHorizontal()
    return self._grow_direction_horizontal
end

--- Gets the grow direction vertical of the Widget.
--- @nodiscard
--- @return TreeGUI.GrowDirection grow_direction
function Widget:getGrowDirectionVertical()
    return self._grow_direction_vertical
end

--#endregion


--#region Protected Getters

--- Returns the minimum size of the Widget content, without margins.
--- @protected
--- @nodiscard
--- @return number min_width, number min_height
function Widget:_getContentMinimumDimensions()
    return 0, 0
end

--- Minimum total size, including margins (what the parent "sees").
--- @protected
--- @return number w, number h
function Widget:_getOuterMinimumSize()
    local margin_left = self:getStyleValue("margin_left")
    local margin_top = self:getStyleValue("margin_top")
    local margin_right = self:getStyleValue("margin_right")
    local margin_bottom = self:getStyleValue("margin_bottom")

    return self._combined_min_width  + margin_left + margin_right,
           self._combined_min_height + margin_top  + margin_bottom
end

--#endregion


return Widget
