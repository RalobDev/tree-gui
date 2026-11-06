--- Rendering context shared by every Widget while a Tree is drawing.
--- @class TreeGUI.Render
local Render = {}

local current_alpha = 1 --- @type number
local stack = {} --- @type number[]
local depth = 0 --- @type number


--#region Public

--- Multiplies the inherited alpha by `alpha`. Must be paired with `popModulateAlpha`.
--- @param alpha number
function Render.pushModulateAlpha(alpha)
    depth = depth + 1
    stack[depth] = current_alpha
    current_alpha = current_alpha * alpha
end

--- Restores theninherited alpha from before the last `pushModulateAlpha`.
function Render.popModulateAlpha()
    if depth ~= 0 then
        current_alpha = stack[depth]
        stack[depth] = nil
        depth = depth - 1
    end
end

--- Resets the context. Called at the start of each Tree draw,
--- so an error thrown mid-draw (and caught with pcall) can't leave a staled alpha behind.
function Render.resetModulateAlpha()
    current_alpha = 1
    for i = depth, 1, -1 do stack[i] = nil end
    depth = 0
end

--#endregion


--#region Setters

--- Sets the draw color, multiplying its alpha by inherited alpha.
--- @overload fun(color: TreeGUI.Color)
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
function Render.setColor(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = unpack(r)
    end

    love.graphics.setColor(r, g, b, (a or 1) * current_alpha)
end

--#endregion


--#region Getters

--- Returns the alpha inherited from the ancestors of the Widget being draw.
--- @nodiscard
--- @return number alpha
function Render.getModulateAlpha()
    return current_alpha
end

--#endregion


return Render
