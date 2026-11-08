--- @diagnostic disable: invisible

local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Class = require(ROOT .. ".libs.class") --- @type TreeGUI.Class
local Render = require(ROOT .. ".tools.render_tool") --- @type TreeGUI.Render
local DebugDraw = require(ROOT .. ".tools.debug_tool") --- @type TreeGUI.DebugDraw
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums
local Signal = require(ROOT .. ".core.signal") --- @type TreeGUI.Signal

--- Responsible for handling input, updating, managing states and rendering Widget's.
--- Without a Tree, a Widget becomes a ghost object.
--- @class TreeGUI.Tree: TreeGUI.Class
--- @field on_child_entered TreeGUI.Signal<fun(child: TreeGUI.Widget)> Called when a child enters the Tree.
--- @field on_child_exited TreeGUI.Signal<fun(child: TreeGUI.Widget)> Called when a child leaves the Tree.
--- @field on_layout_updated TreeGUI.Signal<fun()> Called when the Tree layout is updated.
--- @field on_focus_changed TreeGUI.Signal<fun(new_owner: TreeGUI.Widget?, old_owner: TreeGUI.Widget?)> Called when the focus of the Tree changes.
--- @field on_hovered_changed TreeGUI.Signal<fun(new_hovered: TreeGUI.Widget?, old_hovered: TreeGUI.Widget?)> Called when the element hovered by the mouse in the Tree changes.
--- @field on_keypressed TreeGUI.Signal<fun(key: love.KeyConstant, scancode: love.Scancode, isrepeat: boolean)> Called when the Tree receives a key pressed.
--- @field on_keyreleased TreeGUI.Signal<fun(key: love.KeyConstant, scancode: love.Scancode)> Called when the Tree receives a key released.
--- @field on_mousepressed TreeGUI.Signal<fun(x: number, y: number, button: number, istouch: boolean, presses: number)> Called when the Tree receives a mouse pressed.
--- @field on_mousereleased TreeGUI.Signal<fun(x: number, y: number, button: number, istouch: boolean, presses: number)> Called when the Tree receives a mouse released.
--- @field on_mousemoved TreeGUI.Signal<fun(x: number, y: number, dx: number, dy: number, istouch: boolean)> Called when the Tree receives a mouse moved.
--- @field on_wheelmoved TreeGUI.Signal<fun(x: number, y: number)> Called when the Tree receives a wheel moved.
--- @field private _children TreeGUI.Widget[] Root Widgets.
--- @field private _x number X Screen position of the Tree area.
--- @field private _y number Y Screen position of the Tree area.
--- @field private _width number Reference width for ANCHOR layouts of the root Widgets.
--- @field private _height number Reference height for ANCHOR layouts of the root Widgets.
--- @field private _theme TreeGUI.Theme? Falls back to the default Theme when `nil`.
--- @field private _layout_dirty boolean Layout is recalculated on the next update().
--- @field private _theme_dirty boolean Theme-dependent values are refreshed on the next update().
--- @field private _debug boolean
--- @field private _hovered TreeGUI.Widget? Re-picked every frame in update().
--- @field private _focus_owner TreeGUI.Widget?
--- @field private _mouse_capture TreeGUI.Widget? While set, it receives all mouse events.
--- @field private _press_targets table<number, TreeGUI.Widget> Per mouse button: Widget that consumed the press, so it also gets the release.
local Tree = Class:extend("Tree")

local NAV_KEYS = {
    left = Enums.FocusSide.LEFT,
    up = Enums.FocusSide.TOP,
    right = Enums.FocusSide.RIGHT,
    down = Enums.FocusSide.BOTTOM
}


--#region Definitions

--- @class TreeGUI.Tree.Props
--- @field children TreeGUI.Widget[]?
--- @field x number?
--- @field y number?
--- @field width number?
--- @field height number?
--- @field theme TreeGUI.Theme?
--- @field debug boolean?

--#endregion


--#region Local

--- Bubbles a mouse event from `target` up through its parents, respecting mouse filters.
--- @param target TreeGUI.Widget?
--- @param handler string
--- @param x number
--- @param y number
--- @param ... any
--- @return boolean consumed
local function bubbleMouse(target, handler, x, y, ...)
    local w = target
    while w do
        local filter = w._mouse_filter
        if filter ~= Enums.MouseFilter.IGNORE then
            if w:_receiveMouse(handler, x, y, ...) or filter == Enums.MouseFilter.STOP then
                return true
            end
        end
        w = w._parent
    end
    return false
end

--- Depth-first (draw order) list of widgets reachable by keyboard.
--- @param widget TreeGUI.Widget
--- @param list TreeGUI.Widget[]
local function collectFocusable(widget, list)
    if not widget._visible or widget._opacity <= 0 then return end
    if widget._focus_mode == Enums.FocusMode.ALL then list[#list+1] = widget end
    for _, child in ipairs(widget._children) do
        collectFocusable(child, list)
    end
end

--- Automatic directional focus: nearest widget in the given direction (by center).
--- @param owner TreeGUI.Widget
--- @param list TreeGUI.Widget[]
--- @param side TreeGUI.Enums.FocusSide
local function findSpatial(owner, list, side)
    local ox, oy = owner:getGlobalPosition()
    ox, oy = ox + owner._width / 2, oy + owner._height / 2

    local best, best_score = nil, math.huge
    for _, w in ipairs(list) do
        if w ~= owner then
            local cx, cy = w:getGlobalPosition()
            local dx, dy = cx + w._width / 2 - ox, cy + w._height / 2 - oy

            local primary, secondary
            if side == Enums.FocusSide.LEFT then primary, secondary = -dx, dy
            elseif side == Enums.FocusSide.RIGHT then primary, secondary = dx, dy
            elseif side == Enums.FocusSide.TOP then primary, secondary = -dy, dx
            else primary, secondary = dy, dx end

            if primary > 0 then
                -- Penalizes being off-axis so aligned widgets win.
                local score = primary * primary + 4 * secondary * secondary
                if score < best_score then best, best_score = w, score end
            end
        end
    end
    return best
end

--- Draws the hover/focus highlight of a Widget using its REAL rect (never the visual transform).
--- @param kind "hover"|"focus"
--- @param widget TreeGUI.Widget
local function drawInputHighlight(kind, widget)
    if not DebugDraw.layers[kind] then return end

    local gx, gy = widget:getGlobalPosition()
    local text = string.format("%s %gx%g", widget:getClassName(), widget._width, widget._height)

    DebugDraw.drawHighlight(kind, gx, gy, widget._width, widget._height, text, kind == "hover")
end

--#endregion


--#region Public

--- Instantiates a new Tree.
--- @nodiscard
--- @param props TreeGUI.Tree.Props?
--- @return TreeGUI.Tree self
function Tree:new(props)
    local obj = Class.new(self)

    obj.on_child_entered = Signal:new()
    obj.on_child_exited = Signal:new()
    obj.on_layout_updated = Signal:new()
    obj.on_focus_changed = Signal:new()
    obj.on_hovered_changed = Signal:new()
    obj.on_keypressed = Signal:new()
    obj.on_keyreleased = Signal:new()
    obj.on_mousepressed = Signal:new()
    obj.on_mousereleased = Signal:new()
    obj.on_mousemoved = Signal:new()
    obj.on_wheelmoved = Signal:new()
    obj._children = {}
    obj._x = 0
    obj._y = 0
    obj._width = love.graphics.getWidth()
    obj._height = love.graphics.getHeight()
    obj._layout_dirty = true
    obj._theme_dirty = true
    obj._debug = false
    obj._theme = nil
    obj._focus_owner = nil
    obj._hovered = nil
    obj._mouse_capture = nil
    obj._press_targets = {}

    if props then obj:configure(props) end

    obj:queueUpdateTheme()

    return obj
end

--- Configures the Tree according to the values ​​passed in props.
--- NOTE: This method always updates the layout of the Widget and its children, so don't call it every frame.
--- @param props TreeGUI.Tree.Props
function Tree:configure(props)
    if props.x then self._x = props.x end
    if props.y then self._y = props.y end
    if props.width then self._width = props.width end
    if props.height then self._height = props.height end
    if props.debug then self._debug = props.debug end

    if props.children then self:addChildren(props.children) end
    if props.theme then self:setTheme(props.theme) end

    self:queueLayout()
    self:queueUpdateTheme()
end

--- Updates all Widgets contained in the Tree.
function Tree:update(dt)
    -- Removes children marked as _is_queued_destroy.
    for i = #self._children, 1, -1 do
        local child = self._children[i]
        child:_processDestroyQueue()
        if child._is_queued_destroy then
            self:removeChildAt(i)
            child:_onDestroy()
        end
    end

    if self._theme_dirty then
        self:_updateTheme()
    end

    if self._layout_dirty then
        self:_updateLayout()
    end

    self:_updateHover()
end

--- Draws all Widgets contained in the Tree.
function Tree:draw()
    local r, g, b, a = love.graphics.getColor()
    Render.resetModulateAlpha()

    love.graphics.push()
    love.graphics.translate(self._x, self._y)

    for _, child in ipairs(self._children) do
        child:_render()
        child:_renderDebug(self._debug)
    end

    if self._debug then
        if self._hovered then drawInputHighlight("hover", self._hovered) end
        if self._focus_owner then drawInputHighlight("focus", self._focus_owner) end

        Render.setColor(1, 1, 1)
        love.graphics.rectangle("line", 0, 0, self._width, self._height)
    end

    love.graphics.pop()

    love.graphics.setColor(r, g, b, a)
end

--- Removes the child from the Tree that is at a given index.
--- @param index number
function Tree:removeChildAt(index)
    local child = self._children[index]
    if child then
        table.remove(self._children, index)
        self._layout_dirty = true
        child:_setTree(nil)
        self:_emitSignal(self.on_child_exited, child)
    end
end

--- Remove child from Tree.
--- @param child TreeGUI.Widget
function Tree:removeChild(child)
    for i, cur_child in ipairs(self._children) do
        if cur_child == child then
            self:removeChildAt(i)
            break
        end
    end
end

--- Remove children from the Tree.
--- @param children TreeGUI.Widget[]
function Tree:removeChildren(children)
    for _, child in ipairs(children) do
        self:removeChild(child)
    end
end

--- Adds child to Tree.
--- @param child TreeGUI.Widget
function Tree:addChild(child)
    if type(child) ~= "table" or not (child.is and child:is(Enums.ClassName.Widget)) then
        error(string.format('Cannot add "%s" (%s) as child, expected widget.', child, type(child)))
    elseif child._is_destroyed then
        error(string.format("Cannot add a destroyed child (%s).", child))
    end

    -- If child is in another Tree, remove it so it can be reparented.
    if child._parent then
        child._parent:_extractChild(child)
    elseif child._tree then
        if child._tree == self then return end -- Closes the method, as it is not necessary to add your own child.
        child._tree:removeChild(child)
    end

    self._children[#self._children+1] = child
    self._layout_dirty = true
    self._theme_dirty = true
    child:_setTree(self)
    self:_emitSignal(self.on_child_entered, child)
end

--- Adds children to Tree.
--- @param children TreeGUI.Widget[]
function Tree:addChildren(children)
    for _, child in ipairs(children) do
        self:addChild(child)
    end
end

--- Marks that the layout needs to be recalculated.
function Tree:queueLayout()
    self._layout_dirty = true
end

--- Marks the Tree para atualizar os valores relacionado ao tema dos filhos.
--- No need to call manually this method, as Theme's already do this automatically.
function Tree:queueUpdateTheme()
    self._theme_dirty = true
end

--- Moves focus following explicit neighbors, falling back to automatic navigation.
--- @param side TreeGUI.Enums.FocusSide
--- @return boolean moved
function Tree:navigateFocus(side)
    local owner = self._focus_owner
    local target = owner and owner:_getFocusNeighbor(side)

    if not target then
        local list = {}
        for _, child in ipairs(self._children) do collectFocusable(child, list) end
        if #list == 0 then return false end

        if not owner then
            target = (side == Enums.FocusSide.PREVIOUS) and list[#list] or list[1]
        elseif side == Enums.FocusSide.NEXT or side == Enums.FocusSide.PREVIOUS then
            local index
            for i, w in ipairs(list) do
                if w == owner then index = i break end
            end
            if index then
                local step = side == Enums.FocusSide.NEXT and 1 or -1
                target = list[(index - 1 + step) % #list + 1] -- wraps around
            else
                target = list[1]
            end
        else
            target = findSpatial(owner, list, side)
        end
    end

    if not target then return false end
    self:_setFocusOwner(target)
    return true
end

--- @return boolean moved
function Tree:focusNext()
    return self:navigateFocus(Enums.FocusSide.NEXT)
end

--- @return boolean moved
function Tree:focusPrevious()
    return self:navigateFocus(Enums.FocusSide.PREVIOUS)
end

--- @param key love.KeyConstant
--- @param scancode love.Scancode
--- @param isrepeat boolean
--- @return boolean consumed
function Tree:keypressed(key, scancode, isrepeat)
    self:_emitSignal(self.on_keypressed, key, scancode, isrepeat)

    local owner = self._focus_owner
    if owner then
        self:_emitSignal(owner.on_keypressed, key, scancode, isrepeat)
        if owner:_onKeyPressed(key, scancode, isrepeat) then return true end
    end

    local side = NAV_KEYS[key]
    if key == "tab" then
        side = love.keyboard.isDown("lshift", "rshift") and Enums.FocusSide.PREVIOUS or Enums.FocusSide.NEXT
    end
    if side then return self:navigateFocus(side) end

    return false
end

--- @param key love.KeyConstant
--- @param scancode love.Scancode
--- @return boolean consumed
function Tree:keyreleased(key, scancode)
    self:_emitSignal(self.on_keyreleased, key, scancode)

    local owner = self._focus_owner
    if owner then
        self:_emitSignal(owner.on_mousereleased, key, scancode)
    end
    return owner ~= nil and owner:_onKeyReleased(key, scancode) == true
end

--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
--- @param presses number
--- @return boolean consumed
function Tree:mousepressed(x, y, button, istouch, presses)
    x, y = x - self._x, y - self._y

    self:_emitSignal(self.on_mousepressed, x, y, button, istouch, presses)

    local capture = self._mouse_capture
    if capture then
        capture:_receiveMouse("_onMousePressed", x, y, button, istouch, presses)
        return true
    end

    local consumed_by, focus_taken = nil, false
    local w = self:_pickWidget(x, y)

    while w do
        local filter = w._mouse_filter
        if filter ~= Enums.MouseFilter.IGNORE then
            -- First widget in the chain that accepts click-focus gets it (before its handler runs).
            if not focus_taken and w._focus_mode ~= Enums.FocusMode.NONE then
                self:_setFocusOwner(w)
                focus_taken = true
            end
            if w:_receiveMouse("_onMousePressed", x, y, button, istouch, presses) or filter == Enums.MouseFilter.STOP then
                consumed_by = w
                break
            end
        end
        w = w._parent
    end

    -- Clicked something that can't take focus (or nothing): lose focus.
    if not focus_taken then self:_setFocusOwner(nil) end

    if consumed_by then self._press_targets[button] = consumed_by end
    return consumed_by ~= nil
end

--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
--- @param presses number
--- @return boolean consumed
function Tree:mousereleased(x, y, button, istouch, presses)
    x, y = x - self._x, y - self._y

    self:_emitSignal(self.on_mousereleased, x, y, button, istouch, presses)

    local press_target = self._press_targets[button]
    self._press_targets[button] = nil

    -- Capture has priority; otherwise the release goes to whoever consumed the press.
    local receiver = self._mouse_capture or press_target
    if not receiver then return false end

    receiver:_receiveMouse("_onMouseReleased", x, y, button, istouch, presses)
    return true
end

--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
--- @param istouch boolean
--- @return boolean consumed
function Tree:mousemoved(x, y, dx, dy, istouch)
    x, y = x - self._x, y - self._y

    self:_emitSignal(self.on_mousemoved, x, y, dx, dy, istouch)

    local capture = self._mouse_capture
    if capture then
        capture:_receiveMouse("_onMouseMoved", x, y, dx, dy, istouch)
        return true
    end

    local target = self:_pickWidget(x, y)
    self:_setHovered(target)

    return bubbleMouse(target, "_onMouseMoved", x, y, dx, dy, istouch)
end

--- @param x number
--- @param y number
--- @return boolean consumed
function Tree:wheelmoved(x, y)
    self:_emitSignal(self.on_wheelmoved, x, y)

    local mx, my = love.mouse.getPosition()
    mx, my = mx - self._x, my - self._y

    return bubbleMouse(self:_pickWidget(mx, my), "_onWheelMoved", mx, my, x, y)
end

--#endregion


--#region Private

--- @private
--- @param signal TreeGUI.Signal
--- @param ... any
function Tree:_emitSignal(signal, ...)
    signal:_emit(...)
end

--- Updates the layout of the children following two phases (bottom-up) and (top-down).
--- @private
function Tree:_updateLayout()
    -- (bottom-up)
    for _, child in ipairs(self._children) do
        if child._visible then child:_updateMinimumDimensions() end
    end
    -- (top-down)
    for _, child in ipairs(self._children) do
        if child._visible then
            child:_resolveFreeLayout(self._width, self._height)
            child:_layoutChildren()
        end
    end
    self._layout_dirty = false
    self:_emitSignal(self.on_layout_updated)
end

--- Updates the values ​​of the children related to the Theme.
--- @private
function Tree:_updateTheme()
    for _, child in ipairs(self._children) do
        child:_callThemeChanged()
    end
    self._theme_dirty = false
end

--- Re-picks the widget under the mouse. Runs every frame, so hover stays correct
--- when widgets move, appear or disappear while the mouse is still.
--- @private
function Tree:_updateHover()
    if self._mouse_capture then return end

    if not love.window.hasMouseFocus() then
        self:_setHovered(nil)
        return
    end

    local mx, my = love.mouse.getPosition()
    self:_setHovered(self:_pickWidget(mx - self._x, my - self._y))
end

--- Called by Widget:_setTree when a Widget leaves this Tree (removed, destroyed, reparented).
--- @private
--- @param widget TreeGUI.Widget
function Tree:_onWidgetLeaving(widget)
    if self._focus_owner == widget then self:_setFocusOwner(nil) end
    if self._mouse_capture == widget then self._mouse_capture = nil end
    if self._hovered == widget then self:_setHovered(nil) end

    for button, target in pairs(self._press_targets) do
        if target == widget then self._press_targets[button] = nil end
    end
end

--- @private
--- @param x number
--- @param y number
--- @return TreeGUI.Widget?
function Tree:_pickWidget(x, y)
    for i = #self._children, 1, -1 do
        local hit = self._children[i]:_pickInput(x, y)
        if hit then return hit end
    end
    return nil
end

--#endregion


--#region Setters

--- Enables or disables Tree debugging.
--- @param enabled boolean?
function Tree:setDebugEnabled(enabled)
    self._debug = enabled ~= false
end

--- Defines the Tree Theme. If it is `nil`, it will use the default Theme.
--- @param theme TreeGUI.Theme?
function Tree:setTheme(theme)
    if theme ~= self._theme then
        if self._theme then self._theme:_removeOwner(self) end
        if theme then theme:_addOwner(self) end

        self._theme = theme
        self:queueUpdateTheme()
    end
end

--- Defines the dimensions of the Tree area.
--- @param width number
--- @param height number
function Tree:setDimensions(width, height)
    self._width, self._height = width, height
    self._layout_dirty = true
end

--- Define the Widget that owns the focus. If `nil`, no widget will have focus.
--- @param widget TreeGUI.Widget?
function Tree:setFocusOwner(widget)
    if widget == nil or widget._tree == self then
        self:_setFocusOwner(widget)
    end
end

--#endregion


--#region Getters

--- Returns `true` if Tree debugging is enabled.
--- @nodiscard
--- @return boolean enabled
function Tree:isDebugEnabled()
    return self._debug
end

--- Returns the number of children of the Tree.
--- @nodiscard
--- @return number child_count
function Tree:getChildCount()
    return #self._children
end

--- Returns the child that matches index. If it does not exist, returns `nil`.
--- @nodiscard
--- @return TreeGUI.Widget?
function Tree:getChild(index)
    return self._children[index]
end

--- Returns a copy of the Tree children table.
--- @nodiscard
--- @return TreeGUI.Widget[]
function Tree:getChildren()
    local children = {} --- @type TreeGUI.Widget[]
    for _, child in ipairs(self._children) do
        children[#children+1] = child
    end
    return children
end

--- Returns the dimensions of the Tree.
--- @nodiscard
--- @return number width, number height
function Tree:getDimensions()
    return self._width, self._height
end

--- Returns the Theme set directly on this Tree (`nil` if it inherits from the default theme).
--- @nodiscard
--- @return TreeGUI.Theme? theme
function Tree:getTheme()
    return self._theme
end

--- @nodiscard
--- @return TreeGUI.Widget? widget
function Tree:getFocusOwner()
    return self._focus_owner
end

--- @nodiscard
--- @return TreeGUI.Widget? widget
function Tree:getHovered()
    return self._hovered
end

--- Returns the Widget that has the mouse captured. If it returns `nil`, no widget captured the mouse.
--- @nodiscard
--- @return TreeGUI.Widget? widget
function Tree:getMouseCapture()
    return self._mouse_capture
end

--#endregion


--#region Private Setters

--- @private
--- @param widget TreeGUI.Widget?
function Tree:_setMouseCapture(widget)
    self._mouse_capture = widget
end

--- @private
--- @param widget TreeGUI.Widget?
function Tree:_setFocusOwner(widget)
    local old = self._focus_owner
    if old == widget then return end

    self._focus_owner = widget
    if old then
        old:_onFocusExited()
        self:_emitSignal(old.on_focus_changed, false)
    end
    if widget then
        widget:_onFocusEntered()
        self:_emitSignal(widget.on_focus_changed, true)
    end

    self:_emitSignal(self.on_focus_changed, widget, old)
end

--- @private
--- @param widget TreeGUI.Widget?
function Tree:_setHovered(widget)
    local old = self._hovered
    if old == widget then return end

    self._hovered = widget
    if old then
        old:_onMouseExited()
        self:_emitSignal(old.on_hovered_changed, false)
    end
    if widget then
        widget:_onMouseEntered()
        self:_emitSignal(widget.on_hovered_changed, true)
    end

    self:_emitSignal(self.on_hovered_changed, widget, old)
end

--#endregion


return Tree
