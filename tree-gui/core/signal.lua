local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Class = require(ROOT .. ".libs.class") --- @type TreeGUI.Class

--- Event dispatching object that allows subscribing, unsubscribing, and emitting signals to multiple listener callbacks.
--- @class TreeGUI.Signal<T>: TreeGUI.Class
--- @field private _callbacks table<T, boolean>?
--- @field private _connection_count number
--- @field connect fun(self: TreeGUI.Signal<T>, callback: T): T
--- @field disconnect fun(self: TreeGUI.Signal<T>, callback: T)
local Signal = Class:extend("Signal")


--#region Public

--- Creates and initializes a new Signal instance with an empty set of callbacks.
--- @nodiscard
--- @return TreeGUI.Signal<any> signal The newly created Signal instance.
function Signal:new()
    local obj = Class.new(self) --- @cast obj TreeGUI.Signal<any>

    obj._connection_count = 0

    return obj
end

--- Connects a callback function to listen for emissions from this signal.
--- @generic T
--- @param callback T The callback function to execute on signal emission.
--- @return T callback The connected callback function.
function Signal:connect(callback)
    self._callbacks = self._callbacks or {}

    if not self._callbacks[callback] then
        self._callbacks[callback] = true
        self._connection_count = self._connection_count + 1
    end
    return callback
end

--- Disconnects a previously connected callback function from this signal.
--- @param callback any The callback function to remove.
function Signal:disconnect(callback)
    if self._callbacks then
        if self._callbacks[callback] then
            self._callbacks[callback] = nil
            self._connection_count = self._connection_count - 1

            if self._connection_count == 0 then self._callbacks = nil end
        end
    end
end

--- Removes all connected callbacks from this signal.
function Signal:disconnectAll()
    self._callbacks = nil
    self._connection_count = 0
end

--#endregion


--#region Private

--- Invokes all connected callback functions, passing any provided arguments.
--- @private
--- @param ... any Arguments to forward to each connected callback.
function Signal:_emit(...)
    if self._callbacks then
        for callback in pairs(self._callbacks) do
            callback(...)
        end
    end
end

--#endregion


--#region Getters

--- Returns `true` if the callback is connected to the signal.
--- @nodiscard
--- @return boolean is_connected
function Signal:isConnected(callback)
    if self._callbacks then
        return self._callbacks[callback] ~= nil
    end
    return false
end

--#endregion


return Signal
