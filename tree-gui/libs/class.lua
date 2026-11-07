--- @diagnostic disable
--
-- Class (based on classic)
--
-- Original library: classic
-- Author: rxi
-- Copyright (c) 2014 rxi
--
-- Modifications and extensions:
-- Copyright (c) 2026 Rafael Lopes
--
-- Licensed under the MIT License
-- See LICENSE for details
--

--- @class TreeGUI.Class
--- @field private _class_name TreeGUI.Enums.ClassName Unique class name.
--- @field private _inheritances string[] Parent class name in the inheritance tree.
local Class = {}
Class.__index = Class
Class._class_name = "Class"


--#region Public

--- Creates a new instance of Class.
--- @nodiscard
--- @generic T: TreeGUI.Class
--- @param self T
--- @return T
function Class:new()
    local obj = setmetatable({}, self)
    return obj
end

--- Extends the class.
--- @nodiscard
--- @generic T : TreeGUI.Class
--- @param self T
--- @param class_name TreeGUI.Enums.ClassName Unique class name.
--- @return T
function Class:extend(class_name)
    local cls = {}
    for k, v in pairs(self) do
        if k:find("__") == 1 then
            cls[k] = v
        end
    end

    cls.__index = cls
    cls._class_name = class_name

    local inheritances = {}
    --- @diagnostic disable-next-line: undefined-field
    local parent_inheritances = self._inheritances

    if parent_inheritances then
        for _, inheritance in ipairs(parent_inheritances) do
            inheritances[#inheritances + 1] = inheritance
        end
    end

    --- @diagnostic disable-next-line: undefined-field
    inheritances[#inheritances + 1] = self._class_name
    cls._inheritances = inheritances

    setmetatable(cls, self)
    return cls
end

--- Implements the methods of a mixin.
--- @param ... table
function Class:implement(...)
    for _, cls in pairs({ ... }) do
        for k, v in pairs(cls) do
            if self[k] == nil and type(v) == "function" then
                self[k] = v
            end
        end
    end
end

--- Returns true if then class name matches the given name.
--- @nodiscard
--- @param class_name TreeGUI.Enums.ClassName Unique class name.
--- @return boolean
function Class:is(class_name)
    if self._class_name == class_name then
        return true
    end

    for _, inheritance in ipairs(self._inheritances) do
        if inheritance == class_name then
            return true
        end
    end

    return false
end

--- Returns the name of the class.
--- @nodiscard
--- @return TreeGUI.Enums.ClassName
function Class:getClassName()
    return self._class_name
end

--- Returns the inheritances of the class.
--- @nodiscard
--- @return TreeGUI.Enums.ClassName[]
function Class:getInheritances()
    local inheritances = {}
    for _, inheri in ipairs(self._inheritances) do
        inheritances[#inheritances+1] = inheri
    end
    return inheritances
end

--#endregion


return Class
