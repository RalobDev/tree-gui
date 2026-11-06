--- @diagnostic disable: duplicate-set-field

local debug_hint = true
local TreeGUI = require("tree-gui.init")
    .setDebugLayerEnabled("margin", true)
    .setDebugLayerEnabled("padding", true)
    .setDebugLayerEnabled("content", true)
    .setDebugLayerEnabled("anchors", true)

local Tree = TreeGUI.Tree:new {
    debug = true
}

--- @param dt number
function love.update(dt)
    Tree:update(dt)
end

function love.draw()
    Tree:draw()

    if debug_hint then
        local hint = {
            "Show/Hide Hints: F1",
            string.format("Show/Hide Debug: F2 (%s)", Tree:isDebugEnabled()),
            string.format("Show/Hide Margin: F3 (%s)", TreeGUI.isDebugLayerEnabled("margin")),
            string.format("Show/Hide Padding: F4 (%s)", TreeGUI.isDebugLayerEnabled("padding")),
            string.format("Show/Hide Content: F5 (%s)", TreeGUI.isDebugLayerEnabled("content")),
            string.format("Show/Hide Anchors: F6 (%s)", TreeGUI.isDebugLayerEnabled("anchors")),
            string.format("Show/Hide Hover: F7 (%s)", TreeGUI.isDebugLayerEnabled("hover")),
            string.format("Show/Hide Focus: F8 (%s)", TreeGUI.isDebugLayerEnabled("focus")),
        }

        local font = love.graphics.getFont()
        local width = 0
        local height = #hint * font:getHeight()

        for _, msg in ipairs(hint) do
            width = math.max(width, font:getWidth(msg))
        end

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, width + 12, height + 12)
        love.graphics.setColor(1, 1, 1, 1)

        for i, msg in ipairs(hint) do
            local y = (i - 1) * font:getHeight()
            love.graphics.print(msg, 6, 6 + y)
        end
    end
end

--- @param w number
--- @param h number
function love.resize(w, h)
    Tree:setDimensions(w, h)
end

--- @param key love.KeyConstant
--- @param scancode love.Scancode
--- @param isrepeat boolean
function love.keypressed(key, scancode, isrepeat)
    Tree:keypressed(key, scancode, isrepeat)

    if key == "f1" then
        debug_hint = not debug_hint
    elseif key == "f2" then
        Tree:setDebugEnabled(not Tree:isDebugEnabled())
    elseif key == "f3" then
        TreeGUI.setDebugLayerEnabled("margin", not TreeGUI.isDebugLayerEnabled("margin"))
    elseif key == "f4" then
        TreeGUI.setDebugLayerEnabled("padding", not TreeGUI.isDebugLayerEnabled("padding"))
    elseif key == "f5" then
        TreeGUI.setDebugLayerEnabled("content", not TreeGUI.isDebugLayerEnabled("content"))
    elseif key == "f6" then
        TreeGUI.setDebugLayerEnabled("anchors", not TreeGUI.isDebugLayerEnabled("anchors"))
    elseif key == "f7" then
        TreeGUI.setDebugLayerEnabled("hover", not TreeGUI.isDebugLayerEnabled("hover"))
    elseif key == "f8" then
        TreeGUI.setDebugLayerEnabled("focus", not TreeGUI.isDebugLayerEnabled("focus"))
    end
end

--- @param key love.KeyConstant
--- @param scancode love.Scancode
function love.keyreleased(key, scancode)
    Tree:keyreleased(key, scancode)
end

--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
--- @param presses number
function love.mousepressed(x, y, button, istouch, presses)
    Tree:mousepressed(x, y, button, istouch, presses)
end

--- @param x number
--- @param y number
--- @param button number
--- @param istouch boolean
--- @param presses number
function love.mousereleased(x, y, button, istouch, presses)
    Tree:mousereleased(x, y, button, istouch, presses)
end

--- @param x number
--- @param y number
--- @param dx number
--- @param dy number
--- @param istouch boolean
function love.mousemoved(x, y, dx, dy, istouch)
    Tree:mousemoved(x, y, dx, dy, istouch)
end

--- @param x number
--- @param y number
function love.wheelmoved(x, y)
    Tree:wheelmoved(x, y)
end
