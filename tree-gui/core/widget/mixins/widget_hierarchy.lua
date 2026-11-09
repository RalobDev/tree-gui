local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 4) .. "$") --- @type string

local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.Widget
local Widget = {}


--#region Public

--- Removes the Widget's child that is in a given index.
--- @param index number
function Widget:removeChildAt(index)
    self._content_proxy:_extractChildAt(index)
end

--- Remove child from Widget.
--- @param child TreeGUI.Widget
function Widget:removeChild(child)
    self._content_proxy:_extractChild(child)
end

--- Remove children from the Widget.
--- @param children TreeGUI.Widget[]
function Widget:removeChildren(children)
    for _, child in ipairs(children) do
        self:removeChild(child)
    end
end

--- Adds child to the Widget.
--- @param child TreeGUI.Widget
function Widget:addChild(child)
    self._content_proxy:_insertChild(child)
end

--- Adds children to the Widget.
--- @param children TreeGUI.Widget[]
function Widget:addChildren(children)
    for _, child in ipairs(children) do
        self:addChild(child)
    end
end

--#endregion


--#region Protected

--- Removes the child that is in the index directly from the Widget, bypassing the content proxy.
--- @protected
--- @param index number
function Widget:_extractChildAt(index)
    local child = self._children[index]
    if child then
        self:_queueLayout()
        table.remove(self._children, index)
        child._parent = nil
        child:_setTree(nil)
        if not child._is_internal then self:_emitSignal(self.on_child_exited, child) end
    end
end

--- Removes child directly from the Widget, bypassing the content proxy.
--- @protected
--- @param child TreeGUI.Widget
function Widget:_extractChild(child)
    for i, cur_child in ipairs(self._children) do
        if cur_child == child then
            self:_extractChildAt(i)
            break
        end
    end
end

--- Inserts the child directly into the Widget, bypassing the content proxy.
--- @protected
--- @param child TreeGUI.Widget
function Widget:_insertChild(child)
    if type(child) ~= "table" or not (child.is and child:is(Enums.ClassName.Widget)) then
        error(string.format('Cannot add "%s" (%s) as child, expected widget.', child, type(child)))
    elseif child._is_destroyed then
        error(string.format("Cannot add a destroyed child (%s).", child))
    end

    local widget = self
    while widget do
        if widget == child then error(string.format("Cannot add an ancestor (%s) as a child (cycle).", widget)) end
        widget = widget._parent
    end

    -- If child is in another Widget, remove it so it can be reparented.
    if child._parent then
        if child._parent == self then return end -- Closes the method, as it is not necessary to add your own child.
        child._parent:_extractChild(child)
    elseif child._tree then
        child._tree:removeChild(child)
    end

    self._children[#self._children+1] = child
    child._parent = self
    child:_setTree(self._tree)
    if not child._is_internal then self:_emitSignal(self.on_child_entered, child) end
    self:_queueLayout()
    self:queueUpdateTheme()
end

--- Adds an internal child that cannot be accessed by the user.
--- @protected
--- @param child TreeGUI.Widget
function Widget:_addInternalChild(child)
    child._is_internal = true
    self:_insertChild(child)
end

--- @protected
--- @param tree TreeGUI.Tree
function Widget:_onTreeExited(tree)
end

--#endregion


--#region Getters

--- Returns the Widget Tree. If it is not in one, returns `nil`.
--- @nodiscard
--- @return TreeGUI.Tree? tree
function Widget:getTree()
    return self._tree
end

--- Returns the Widget's relative.
--- @nodiscard
--- @return TreeGUI.Widget? parent
function Widget:getParent()
    return self._parent
end

--- Returns the number of Widget children.
--- @nodiscard
--- @return number
function Widget:getChildCount()
    local count = 0
    for _, child in ipairs(self._children) do
        if not child._is_internal then count = count + 1 end
    end
    return count
end

--- Returns the child that matches index. If it does not exist, returns `nil`.
--- @nodiscard
--- @return TreeGUI.Widget?
function Widget:getChild(index)
    local child = self._children[index]
    if child and not child._is_internal then
        return child
    end
end

--- Returns a copy of the Widget's children table.
--- @nodiscard
--- @return TreeGUI.Widget[]
function Widget:getChildren()
    local children = {} --- @type TreeGUI.Widget[]
    for _, child in ipairs(self._children) do
        if not child._is_internal then
            children[#children+1] = child
        end
    end
    return children
end

--#endregion


return Widget
