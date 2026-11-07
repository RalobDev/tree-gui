local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 4) .. "$") --- @type string

local DebugDraw = require(ROOT .. ".tools.debug_tool") --- @type TreeGUI.DebugDraw
local Render = require(ROOT .. ".tools.render_tool") --- @type TreeGUI.Render
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.Widget
local Widget = {}


--#region Local

--- Intersects the current scissor with the rect (0, 0, width, height) in the CURRENT transform.
--- Returns the previous scissor so it can be restored.
--- NOTE: the scissor is axis-aligned, so with a visual rotation it uses the bounding box.
--- @param width number
--- @param height number
--- @return number? x, number? y, number? w, number? h
local function pushClip(width, height)
    local px, py, pw, ph = love.graphics.getScissor()

    -- The scissor ignores the transform stack, so convert the rect to screen space.
    local x1, y1 = love.graphics.transformPoint(0, 0)
    local x2, y2 = love.graphics.transformPoint(width, 0)
    local x3, y3 = love.graphics.transformPoint(width, height)
    local x4, y4 = love.graphics.transformPoint(0, height)

    local left = math.floor(math.min(x1, x2, x3, x4))
    local top = math.floor(math.min(y1, y2, y3, y4))
    local right = math.ceil(math.max(x1, x2, x3, x4))
    local bottom = math.ceil(math.max(y1, y2, y3, y4))

    -- Nested clips: intersectScissor can only shrink the current area.
    love.graphics.intersectScissor(left, top, right - left, bottom - top)

    return px, py, pw, ph
end

--#endregion


--#region Protected

--- Prepares the Widget to draw, respecting local position, clip, etc.
--- @protected
function Widget:_pushDraw()
    love.graphics.push()
    love.graphics.translate(self._x, self._y)
end

--- @protected
function Widget:_popDraw()
    love.graphics.pop()
end

--- Draws the Widget.
--- @protected
function Widget:_draw()
end

--- Draws Widget debugging.
--- @protected
function Widget:_drawDebug()
    local w, h = self._width, self._height
    local margin_left = self:getStyleValue("margin_left")
    local margin_right = self:getStyleValue("margin_right")
    local margin_top = self:getStyleValue("margin_top")
    local margin_bottom = self:getStyleValue("margin_bottom")

    -- Margin: between the outer rectangle (with margins) and the Widget.
    if DebugDraw.layers.margin then
        DebugDraw.drawFrame(
            "margin",
            -margin_left, -margin_top,
            w + margin_left + margin_right,
            h + margin_top + margin_bottom,
            0, 0, w, h
        )
    end

    if DebugDraw.layers.content then DebugDraw.drawContent(w, h) end
    if DebugDraw.layers.anchors then self:_drawAnchorsDebug() end
end

--- Draws the Widget anchors. Only appears in ANCHOR mode and outside of Containers,
--- because there the anchors are ignored.
--- @protected
function Widget:_drawAnchorsDebug()
    if self._layout_mode ~= Enums.LayoutMode.ANCHOR then return end

    local parent = self._parent
    if parent and not self._is_internal and parent:is(Enums.ClassName.Container) then return end

    local pw, ph
    if parent then
        pw, ph = parent._width, parent._height
    elseif self._tree then
        pw, ph = self._tree:getDimensions()
    else
        return
    end

    local margin_left = self:getStyleValue("margin_left")
    local margin_right = self:getStyleValue("margin_right")
    local margin_top = self:getStyleValue("margin_top")
    local margin_bottom = self:getStyleValue("margin_bottom")

    local aw = math.max(0, pw - margin_left - margin_right)
    local ah = math.max(0, ph - margin_top - margin_bottom)

    local ax1 = margin_left + aw * self._anchor_left
    local ax2 = margin_left + aw * self._anchor_right
    local ay1 = margin_top + ah * self._anchor_top
    local ay2 = margin_top + ah * self._anchor_bottom

    -- Debug is in the Widget's local space, and anchors are in the relative's.
    love.graphics.push()
    love.graphics.translate(-self._x, -self._y)
    DebugDraw.drawAnchors(ax1, ay1, ax2, ay2, self._x, self._y, self._width, self._height)
    love.graphics.pop()
end

--#endregion


--#region Private

--- Renders the Widget, internally calling _draw().
--- @private
function Widget:_render()
    local opacity = self._opacity
    if not self._visible then return end

    self:_pushDraw()
    self:_applyVisualTransform()
    Render.pushModulateAlpha(opacity)

    -- Applied after the visual transform, so the clip follows what is drawn.
    local clip = self._clip_content
    local px, py, pw, ph
    if clip then px, py, pw, ph = pushClip(self._width, self._height) end

    self:_draw()

    for _, child in ipairs(self._children) do
        child:_render()
    end

    if clip then love.graphics.setScissor(px, py, pw, ph) end --- @diagnostic disable-line: param-type-mismatch

    Render.popModulateAlpha()
    self:_popDraw()
end

--- Renders the Widget debug, internally calling _drawDebug().
--- @private
--- @param inherited boolean
function Widget:_renderDebug(inherited)
    if not self._visible then return end

    local enabled = inherited
    if self._debug_mode == Enums.DebugMode.ENABLED then
        enabled = true
    elseif self._debug_mode == Enums.DebugMode.DISABLED then
        enabled = false
    end

    self:_pushDraw()

    if enabled then self:_drawDebug() end

    for _, child in ipairs(self._children) do
        child:_renderDebug(inherited)
    end

    self:_popDraw()
end

--#endregion


--#region Setters

--- Sets the opacity (number in the range 0-1) of the Widget.
--- @param opacity number
function Widget:setOpacity(opacity)
    self._opacity = math.min(1, math.max(opacity, 0))
    self._visible = self._opacity == 0 and false or true
end

--- Enables or disables clipping of the Widget's drawing and children to its own rect.
--- Input follows the same rule: children outside the rect cannot be picked.
--- @param enabled boolean?
function Widget:setClipContent(enabled)
    self._clip_content = enabled ~= false
end

--- Shows or hides the Widget. A hidden Widget (and its children) is not drawn,
--- does not receive input, cannot be focused and is ignored by Containers.
--- @param visible boolean?
function Widget:setVisible(visible)
    visible = visible ~= false
    if visible == self._visible then return end

    self._opacity = visible and self._opacity or 0

    self._visible = visible
    self:_queueLayout()
    if not visible then self:_releaseInputState() end
end

--#endregion


--#region Getters

--- Returns the opacity (number in the range 0-1) of the Widget.
--- @nodiscard
--- @return number opacity
function Widget:getOpacity()
    return self._opacity
end

--- @nodiscard
--- @return boolean enabled
function Widget:isClippingContent()
    return self._clip_content
end

--- Returns the Widget's own visibility flag.
--- @nodiscard
--- @return boolean visible
function Widget:isVisible()
    return self._visible
end

--- Returns `true` if the Widget and all its ancestors are visible.
--- @nodiscard
--- @return boolean visible
function Widget:isVisibleInTree()
    local widget = self --- @type TreeGUI.Widget?
    while widget do
        if not widget._visible then return false end
        widget = widget._parent
    end
    return true
end

--#endregion


return Widget
