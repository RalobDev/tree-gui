local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Class = require(ROOT .. ".libs.class") --- @type TreeGUI.Class
local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.Resource: TreeGUI.Class, TreeGUI.Resource.Owner
--- @field _owners table<TreeGUI.Resource.Owner, boolean>
--- @field _batch_depth number
--- @field _batch_pending boolean
--- @field _emitting boolean
--- @field _locked boolean
local Resource = Class:extend("Resource")

--- Fields owned by the Resource: never copied by `duplicate()`.
local RESERVED = {
    _owners = true,
    _batch_depth = true,
    _batch_pending = true,
    _emitting = true,
    _locked = true
}


--#region Definitions

--- @class TreeGUI.Resource.Props
--- @field lock boolean?

--- Anything that can observe a Resource.
--- @class TreeGUI.Resource.Owner
--- @field _onResourceChanged fun(self: TreeGUI.Resource.Owner, resource: TreeGUI.Resource)

--- Maps original objects (Resources and plain tables) to their clones during a `duplicate()`.
--- @alias TreeGUI.Resource.Memo table<table, table>

--#endregion


--#region Local

--- @param value any
--- @return boolean
local function isResource(value)
    return type(value) == "table" and value.is ~= nil and value:is(Enums.ClassName.Resource) == true
end

--#endregion


--#region Public

--- Instantiates a new Resource.
--- @nodiscard
--- @generic T: TreeGUI.Resource
--- @param self T
--- @param props TreeGUI.Resource.Props?
--- @return T self
function Resource:new(props)
    local obj = Class.new(self) --- @class TreeGUI.Resource

    obj._owners = setmetatable({}, { __mode = "k" }) -- weak keys: a Resource never keeps its owners alive.
    obj._batch_depth = 0
    obj._batch_pending = false
    obj._emitting = false
    obj._locked = false

    if props then obj:configure(props) end

    return obj
end

--- NOTE: Must be called after `_batch()` in configure. Calling beforehand causes an error, as the Resource is locked.
--- @param props TreeGUI.Resource.Props
--- @return self
function Resource:configure(props)
    self._locked = props.lock == true
    return self
end

--- Returns a deep copy of the Resource.
--- @nodiscard
--- @generic T: TreeGUI.Resource
--- @param self T
--- @return T clone
function Resource:duplicate()
    return self:_cloneSubResource(self, {})
end

--#endregion


--#region Protected

--- It must be called at the beginning of each method (setters) that modifies the Resource.
--- Generates an error if the Resource is locked.
--- @protected
function Resource:_checkLock()
    if self._locked then error(string.format("It is not possible to modify a locked Resource (%s).", self), 2) end
end

--- Notifies every owner that the Resource changed.
--- @protected
function Resource:_emitChanged()
    if self._batch_depth > 0 then
        self._batch_pending = true
        return
    end
    if self._emitting or next(self._owners) == nil then return end

    self._emitting = true

    -- Iterate over a snapshot: owners may be added/removed from inside the callbacks.
    local snapshot, count = {}, 0
    for owner in pairs(self._owners) do
        count = count + 1
        snapshot[count] = owner
    end

    local first_error = nil
    for i = 1, count do
        local owner = snapshot[i]
        if self._owners[owner] then -- skips owners removed during this emission.
            local ok, err = pcall(owner._onResourceChanged, owner, self)
            if not ok and first_error == nil then first_error = err end
        end
    end

    self._emitting = false
    if first_error ~= nil then error(first_error, 0) end
end

--- Called by a sub-resource when it changes.
--- @protected
--- @param source TreeGUI.Resource
function Resource:_onResourceChanged(source)
    self:_emitChanged()
end

--- Starts a batch of changes: `_emitChanged` only marks the change as pending until the matching `_endChange`.
--- @protected
function Resource:_beginChange()
    self._batch_depth = self._batch_depth + 1
end

--- Ends a batch of changes. The outermost call emits `changed` once if something changed.
--- @protected
function Resource:_endChange()
    if self._batch_depth == 0 then error("Unbalanced _endChange (no matching _beginChange).") end

    self._batch_depth = self._batch_depth - 1
    if self._batch_depth == 0 and self._batch_pending then
        self._batch_pending = false
        self:_emitChanged()
    end
end

--- Runs `fn(self, ...)` inside a batch. The batch is always closed, even if `fn` raises (the error is re-thrown).
--- @protected
--- @param fn fun(self: any, ...: any)
--- @param ... any
function Resource:_batch(fn, ...)
    self:_beginChange()
    local ok, err = pcall(fn, self, ...)
    self:_endChange()
    if not ok then error(err, 0) end
end

--- Connects a sub-resource: this Resource becomes its owner and is notified when it changes.
--- @protected
--- @param res TreeGUI.Resource
function Resource:_adoptSubResource(res)
    res:_addOwner(self)
end

--- Disconnects a sub-resource previously adopted with `_adoptSubResource`.
--- @protected
--- @param res TreeGUI.Resource
function Resource:_releaseSubResource(res)
    res:_removeOwner(self)
end

--- Fills `clone` with the data of this Resource. Subclasses extend it (call the base first).
--- By default every field is copied: Resources are cloned (through `memo`) and adopted by `clone`,
--- plain tables are copied, everything else (numbers, strings, functions, userdata) is shared.
--- @protected
--- @param clone TreeGUI.Resource
--- @param memo TreeGUI.Resource.Memo
function Resource:_duplicateInto(clone, memo)
    for key, value in pairs(self) do
        if not RESERVED[key] then
            clone[key] = clone:_duplicateValue(value, memo)
        end
    end
end

--- Copies one value for `_duplicateInto`. `self` is the clone, which adopts the cloned sub-resources.
--- @protected
--- @param value any
--- @param memo TreeGUI.Resource.Memo
--- @return any
function Resource:_duplicateValue(value, memo)
    if type(value) ~= "table" then return value end

    if isResource(value) then
        local sub = self:_cloneSubResource(value, memo)
        self:_adoptSubResource(sub)
        return sub
    end

    if getmetatable(value) ~= nil then return value end -- foreign object: shared, not cloned.

    local copy = memo[value]
    if copy then return copy end

    copy = {}
    memo[value] = copy
    for k, v in pairs(value) do
        copy[k] = self:_duplicateValue(v, memo)
    end
    return copy
end

--- Clones a Resource creating the instance with its own class (`getmetatable`), or returns the clone already
--- made for it in this duplication. The clone never emits while it is being filled.
--- @protected
--- @generic T: TreeGUI.Resource
--- @param res T
--- @param memo TreeGUI.Resource.Memo
--- @return T
function Resource:_cloneSubResource(res, memo)
    local existing = memo[res]
    if existing then return existing end

    local cls = getmetatable(res) --- @type TreeGUI.Resource
    local clone = cls:new()
    memo[res] = clone

    clone._batch_depth = clone._batch_depth + 1
    res:_duplicateInto(clone, memo)
    clone._batch_depth = clone._batch_depth - 1
    clone._batch_pending = false

    return clone
end

--- Validates and copies a color into `target`. Returns `true` if the stored value changed.
--- @protected
--- @param target TreeGUI.Color
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
--- @return boolean changed
function Resource:_writeColor(target, r, g, b, a)
    if
        type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number"
        or (a ~= nil and type(a) ~= "number")
        or r ~= r or g ~= g or b ~= b or a ~= a
    then
        error("Invalid color: expected r, g, b (and optional a) as numbers, or a { r, g, b, a? } table.")
    end

    a = a or 1
    if target[1] == r and target[2] == g and target[3] == b and target[4] == a then return false end

    target[1], target[2], target[3], target[4] = r, g, b, a
    return true
end

--#endregion


--#region Private

--- Adds an observer.
--- @private
--- @param owner TreeGUI.Resource.Owner
function Resource:_addOwner(owner)
    if type(owner) ~= "table" or type(owner._onResourceChanged) ~= "function" then
        error(string.format(
            'Cannot add "%s" (%s) as owner, expected a table with an _onResourceChanged method.',
            tostring(owner), type(owner)
        ))
    end
    self._owners[owner] = true
end

--- Removes an observer.
--- @private
--- @param owner TreeGUI.Resource.Owner
function Resource:_removeOwner(owner)
    self._owners[owner] = nil
end

--#endregion


--#region Setters

--- Locks the Resource from being modified. Trying to modify it generates an error.
function Resource:lock()
   self._locked = true
end

--#endregion


--#region Getters

--- Returns `true` if the Resource is locked. When locked, a resource cannot be modified.
--- @nodiscard
--- @return boolean is_locked
function Resource:isLocked()
    return self._locked
end

--#endregion


return Resource
