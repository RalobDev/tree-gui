local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 3) .. "$") --- @type string

local Class = require(ROOT .. ".libs.class") --- @type TreeGUI.Class
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums
local Signal = require(ROOT .. ".core.signal") --- @type TreeGUI.Signal

--- Base class for all GUI elements.
--- @class TreeGUI.Widget: TreeGUI.Class
--- @field on_tree_entered TreeGUI.Signal<fun(tree: TreeGUI.Tree)> Called when the Widget enters a Tree.
--- @field on_tree_exited TreeGUI.Signal<fun(tree: TreeGUI.Tree)> Called when the Widget leaves a Tree.
--- @field on_child_entered TreeGUI.Signal<fun(child: TreeGUI.Widget)> Called when a child enters the Widget.
--- @field on_child_exited TreeGUI.Signal<fun(child: TreeGUI.Widget)> Called when a child leaves the Widget.
--- @field on_layout_updated TreeGUI.Signal<fun()> Called when the Widget layout is updated.
--- @field on_focus_changed TreeGUI.Signal<fun(is_focused: boolean)> Called when the Widget's focus changes.
--- @field on_hovered_changed TreeGUI.Signal<fun(is_hovered: boolean)> Called when the mouse hovered over the Widget changes.
--- @field on_queued_destroy TreeGUI.Signal<fun()> Called when the Widget enters the queue to be destroyed. It usually occurs a few frames before it is actually destroyed.
--- @field on_destroyed TreeGUI.Signal<fun()> Called when the Widget is destroyed. CAUTION: Destroyed widgets are unstable as they should no longer exist.
--- @field on_draw TreeGUI.Signal<fun()> Called when the Widget is drawn. (0, 0) is local to the Widget.
--- @field on_visibilty_changed TreeGUI.Signal<fun(is_visible: boolean)> Called when the Widget's visibility changes.
--- @field on_keypressed TreeGUI.Signal<fun(key: love.KeyConstant, scancode: love.Scancode, isrepeat: boolean)> Called when the Widget receives a key pressed.
--- @field on_keyreleased TreeGUI.Signal<fun(key: love.KeyConstant, scancode: love.Scancode)> Called when the Widget receives a key released.
--- @field on_mousepressed TreeGUI.Signal<fun(x: number, y: number, button: number, istouch: boolean, presses: number)> Called when the Widget receives a mouse pressed.
--- @field on_mousereleased TreeGUI.Signal<fun(x: number, y: number, button: number, istouch: boolean, presses: number)> Called when the Widget receives a mouse released.
--- @field on_mousemoved TreeGUI.Signal<fun(x: number, y: number, dx: number, dy: number, istouch: boolean)> Called when the Widget receives a mouse moved.
--- @field on_wheelmoved TreeGUI.Signal<fun(x: number, y: number)> Called when the Widget receives a wheel moved.
--- @field protected _tree TreeGUI.Tree? Widget this Widget belongs to (`nil` while detached).
--- @field protected _parent TreeGUI.Widget?
--- @field protected _children TreeGUI.Widget[] Includes internal children.
--- @field protected _content_proxy TreeGUI.Widget Widget that receives the user's children (defaults to self).
--- @field protected _is_internal boolean Created by the Widget itself: hidden from getChildren() and ignored by Containers.
--- @field private _is_destroyed boolean
--- @field private _is_queued_destroy boolean
--- @field protected _x number X Local position, relative to the parent.
--- @field protected _y number Y Local position, relative to the parent.
--- @field protected _width number
--- @field protected _height number
--- @field protected _min_width number User-defined minimum width.
--- @field protected _min_height number User-defined minimum height.
--- @field private _layout_mode TreeGUI.Enums.LayoutMode Ignored when the Widget is a child of a Container.
--- @field protected _size_flags_horizontal TreeGUI.Enums.SizeFlags Only used by Containers.
--- @field protected _size_flags_vertical TreeGUI.Enums.SizeFlags Only used by Containers.
--- @field protected _stretch_ratio number Share of the free space among expanding siblings (Containers only).
--- @field protected _combined_min_width number Minimum width after pass 1: max(_min_width, content), without margins.
--- @field protected _combined_min_height number Minimum height after pass 1: max(_min_height, content), without margins.
--- @field protected _anchor_left number
--- @field protected _anchor_top number
--- @field protected _anchor_right number
--- @field protected _anchor_bottom number
--- @field protected _offset_left number
--- @field protected _offset_top number
--- @field protected _offset_right number
--- @field protected _offset_bottom number
--- @field protected _grow_direction_horizontal TreeGUI.Enums.GrowDirection
--- @field protected _grow_direction_vertical TreeGUI.Enums.GrowDirection
--- @field private _pending_rect { x: number?, y: number?, w: number?, h: number? }? Rect requested in ANCHOR mode before the Widget was attached; applied on the first layout.
--- @field protected _theme TreeGUI.Theme? Theme set directly on this Widget (`nil` = inherits).
--- @field protected _theme_variant string?
--- @field protected _style_override TreeGUI.Theme.WidgetStyle Values set directly on the Widget; they win over the Theme.
--- @field private _focus_mode TreeGUI.Enums.FocusMode
--- @field private _focus_neighbors table<TreeGUI.Enums.FocusSide, TreeGUI.Widget?>
--- @field private _mouse_filter TreeGUI.Enums.MouseFilter
--- @field protected _visible boolean Hidden Widgets are not drawn, get no input and are ignored by Containers.
--- @field private _opacity number Range 0-1.
--- @field private _clip_content boolean
--- @field private _debug_mode TreeGUI.Enums.DebugMode
--- @field private _visual TreeGUI.Widget.VisualState Draw-only transform (offset, scale, rotation); never affects layout or input.
local Widget = Class:extend("Widget")

Widget:implement(require(ROOT .. ".core.widget.mixins.widget_box"))
Widget:implement(require(ROOT .. ".core.widget.mixins.widget_hierarchy"))
Widget:implement(require(ROOT .. ".core.widget.mixins.widget_input"))
Widget:implement(require(ROOT .. ".core.widget.mixins.widget_layout"))
Widget:implement(require(ROOT .. ".core.widget.mixins.widget_render"))
Widget:implement(require(ROOT .. ".core.widget.mixins.widget_theme"))
Widget:implement(require(ROOT .. ".core.widget.mixins.widget_visual"))


--#region Definitions

--- @class TreeGUI.Widget.Props
--- @field children TreeGUI.Widget[]?
--- @field x number?
--- @field y number?
--- @field width number?
--- @field height number?
--- @field min_width number?
--- @field min_height number?
--- @field layout_mode TreeGUI.Enums.LayoutMode?
--- @field size_flags_horizontal TreeGUI.Enums.SizeFlags?
--- @field size_flags_vertical TreeGUI.Enums.SizeFlags?
--- @field stretch_ratio number?
--- @field margins number?
--- @field margin_left number?
--- @field margin_top number?
--- @field margin_right number?
--- @field margin_bottom number?
--- @field anchor_preset TreeGUI.Enums.AnchorPreset?
--- @field anchor_left number?
--- @field anchor_top number?
--- @field anchor_right number?
--- @field anchor_bottom number?
--- @field offset_left number?
--- @field offset_top number?
--- @field offset_right number?
--- @field offset_bottom number?
--- @field grow_direction_horizontal TreeGUI.Enums.GrowDirection?
--- @field grow_direction_vertical TreeGUI.Enums.GrowDirection?
--- @field theme TreeGUI.Theme?
--- @field theme_variant string?
--- @field focus_mode TreeGUI.Enums.FocusMode?
--- @field focus_neighbors table<TreeGUI.Enums.FocusSide, TreeGUI.Widget>?
--- @field mouse_filter TreeGUI.Enums.MouseFilter?
--- @field visible boolean?
--- @field opacity number? (number in the range 0-1)
--- @field clip_content boolean?
--- @field visual_offset_x number?
--- @field visual_offset_y number?
--- @field visual_scale_x number?
--- @field visual_scale_y number?
--- @field visual_rotation number?
--- @field visual_pivot_x number?
--- @field visual_pivot_y number?
--- @field debug_mode TreeGUI.Enums.DebugMode?

--#endregion


--#region Public

--- Instantiates a new Widget.
--- @nodiscard
--- @generic T: TreeGUI.Widget
--- @param self T
--- @param props TreeGUI.Widget.Props?
--- @return T self
function Widget:new(props)
    local obj = Class.new(self) --- @class TreeGUI.Widget

    obj.on_tree_entered = Signal:new()
    obj.on_tree_exited = Signal:new()
    obj.on_child_entered = Signal:new()
    obj.on_child_exited = Signal:new()
    obj.on_layout_updated = Signal:new()
    obj.on_focus_changed = Signal:new()
    obj.on_hovered_changed = Signal:new()
    obj.on_queued_destroy = Signal:new()
    obj.on_destroyed = Signal:new()
    obj.on_draw = Signal:new()
    obj.on_visibilty_changed = Signal:new()
    obj.on_keypressed = Signal:new()
    obj.on_keyreleased = Signal:new()
    obj.on_mousepressed = Signal:new()
    obj.on_mousereleased = Signal:new()
    obj.on_mousemoved = Signal:new()
    obj.on_wheelmoved = Signal:new()
    obj._tree = nil
    obj._parent = nil
    obj._children = {}
    obj._content_proxy = obj
    obj._x = 0
    obj._y = 0
    obj._width = 0
    obj._height = 0
    obj._min_width = 0
    obj._min_height = 0
    obj._size_flags_horizontal = Enums.SizeFlags.FILL
    obj._size_flags_vertical = Enums.SizeFlags.FILL
    obj._stretch_ratio = 1
    obj._combined_min_width = 0
    obj._combined_min_height = 0
    obj._anchor_left = 0
    obj._anchor_top = 0
    obj._anchor_right = 0
    obj._anchor_bottom = 0
    obj._offset_left = 0
    obj._offset_top = 0
    obj._offset_right = obj._offset_left + obj._width
    obj._offset_bottom = obj._offset_top + obj._height
    obj._grow_direction_horizontal = Enums.GrowDirection.END
    obj._grow_direction_vertical = Enums.GrowDirection.END
    obj._is_internal = false
    obj._theme = nil
    obj._theme_variant = nil
    obj._style_override = {}
    obj._is_destroyed = false
    obj._is_queued_destroy = false
    obj._layout_mode = Enums.LayoutMode.POSITION
    obj._debug_mode = Enums.DebugMode.INHERITED
    obj._pending_rect = nil
    obj._opacity = 1
    obj._visual = {
        offset_x = 0, offset_y = 0,
        scale_x = 1, scale_y = 1,
        rotation = 0,
        pivot_x = 0.5, pivot_y = 0.5
    }
    obj._focus_mode = Enums.FocusMode.NONE
    obj._focus_neighbors = {}
    obj._mouse_filter = Enums.MouseFilter.STOP
    obj._clip_content = false
    obj._visible = true

    if props then obj:configure(props) end

    obj:queueUpdateTheme()
    obj:_queueLayout()

    return obj
end

--- Configures the Widget according to the values ​​passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Widget.Props
function Widget:configure(props)
    if props.x then self._x = props.x end
    if props.y then self._y = props.y end
    if props.width then self._width = props.width end
    if props.height then self._height = props.height end
    if props.min_width then self._min_width = props.min_width end
    if props.min_height then self._min_height = props.min_height end
    if props.margins then self:setMarginsOverride(props.margins) end
    if props.margin_left then self._style_override.margin_left = props.margin_left end
    if props.margin_top then self._style_override.margin_top = props.margin_top end
    if props.margin_right then self._style_override.margin_right = props.margin_right end
    if props.margin_bottom then self._style_override.margin_bottom = props.margin_bottom end
    if props.size_flags_horizontal then self._size_flags_horizontal = props.size_flags_horizontal end
    if props.size_flags_vertical then self._size_flags_vertical = props.size_flags_vertical end
    if props.stretch_ratio then self._stretch_ratio = props.stretch_ratio end
    if props.anchor_preset then self:setAnchorPreset(props.anchor_preset) end
    if props.anchor_left then self._anchor_left = props.anchor_left end
    if props.anchor_top then self._anchor_top = props.anchor_top end
    if props.anchor_right then self._anchor_right = props.anchor_right end
    if props.anchor_bottom then self._anchor_bottom = props.anchor_bottom end
    if props.offset_left then self._offset_left = props.offset_left end
    if props.offset_top then self._offset_top = props.offset_top end
    if props.offset_right then self._offset_right = props.offset_right end
    if props.offset_bottom then self._offset_bottom = props.offset_bottom end
    if props.grow_direction_horizontal then self._grow_direction_horizontal =  props.grow_direction_horizontal end
    if props.grow_direction_vertical then self._grow_direction_vertical =  props.grow_direction_vertical end
    if props.layout_mode then self._layout_mode = props.layout_mode end
    if props.debug_mode then self._debug_mode = props.debug_mode end
    if props.visual_offset_x then self._visual.offset_x = props.visual_offset_x end
    if props.visual_offset_y then self._visual.offset_y = props.visual_offset_y end
    if props.visual_scale_x then self._visual.scale_x = props.visual_scale_x end
    if props.visual_scale_y then self._visual.scale_y = props.visual_scale_y end
    if props.visual_rotation then self._visual.rotation = props.visual_rotation end
    if props.visual_pivot_x then self._visual.pivot_x = props.visual_pivot_x end
    if props.visual_pivot_y then self._visual.pivot_y = props.visual_pivot_y end
    if props.clip_content ~= nil then self._clip_content = props.clip_content end
    if props.visible ~= nil then self:setVisible(props.visible) end

    self._theme_variant = props.theme_variant

    if props.opacity then self:setOpacity(props.opacity) end
    if props.children then self:addChildren(props.children) end
    if props.theme then self:setTheme(props.theme) end

    self:_configureInput(props)
    self:queueUpdateTheme()
    self:_queueLayout()
end

--- Adds the Widget to the destruction queue, automatically removing it on the next Tree update.
function Widget:queueDestroy()
    if not self._is_queued_destroy then
        self._is_queued_destroy = true
        self:_emitSignal(self.on_queued_destroy)
    end
end

--#endregion


--#region Protected

--- @protected
--- @param signal TreeGUI.Signal
--- @param ... any
function Widget:_emitSignal(signal, ...)
    signal:_emit(...) --- @diagnostic disable-line: invisible
end

--#endregion


--#region Private

--- Called when the Widget is destroyed at the beginning of the Tree update.
--- @private
function Widget:_onDestroy()
    self._is_destroyed = true
    self._is_queued_destroy = false

    if self._theme then self._theme:_removeOwner(self) end --- @diagnostic disable-line: invisible

    for _, child in ipairs(self._children) do
        child:_onDestroy()
    end

    self:_emitSignal(self.on_destroyed)
end

--- Processa os filhos na fila de destruição.
--- @private
function Widget:_processDestroyQueue()
    for i = #self._children, 1, -1 do
        local child = self._children[i]
        child:_processDestroyQueue()
        if child._is_queued_destroy then
            self:_extractChildAt(i)
            child:_onDestroy()
        end
    end
end

--endregion


--#region Setters

--- Enables or disables Widget debugging. If `debug_mode` is `INHERITED`, it follows the parent's debug.
--- @param debug_mode TreeGUI.Enums.DebugMode
function Widget:setDebugMode(debug_mode)
    self._debug_mode = debug_mode
end

--#endregion


--#region Getters

--- Returns whether Widget debugging is enabled or not. If it is `INHERITED`,
--- means that he follows his father's purification.
--- @nodiscard
--- @return TreeGUI.Enums.DebugMode debug_mode
function Widget:getDebugMode()
    return self._debug_mode
end

--- Returns `true` if the Widget is queued to be destroyed in the next Tree update.
--- @nodiscard
--- @return boolean is_destroyed
function Widget:isQueuedDestroyed()
    return self._is_queued_destroy
end

--- Returns `true` if the Widget is destroyed.
--- @nodiscard
--- @return boolean
function Widget:isDestroyed()
    return self._is_destroyed
end

--#endregion


--#region Private Setters

--- Defines the Widget Tree and recursively updates the new reference among its children.
--- @private
--- @param tree TreeGUI.Tree?
function Widget:_setTree(tree)
    local old_tree = self._tree
    if old_tree and old_tree ~= tree then
        old_tree:_onWidgetLeaving(self) --- @diagnostic disable-line: invisible
    end

    self._tree = tree

    for _, child in ipairs(self._children) do
        child:_setTree(tree)
    end

    if self._tree then
        self:_emitSignal(self.on_tree_entered, self._tree)
    elseif old_tree then
        self:_emitSignal(self.on_tree_exited, old_tree)
    end
end

--- Sets the content proxy and moves the Widget's non-internal children to it.
--- It should only be called in the constructor to avoid problems.
--- @private
--- @param content_proxy TreeGUI.Widget
function Widget:_setContentProxy(content_proxy)
    local moved = {} --- @type TreeGUI.Widget[]
    for i = #self._children, 1, -1 do
        local child = self._children[i]
        if child ~= content_proxy and not child._is_internal then
            table.remove(self._children, i)
            child._parent = nil
            table.insert(moved, 1, child)
        end
    end

    self._content_proxy = content_proxy
    content_proxy:addChildren(moved)
end

--#endregion


return Widget
