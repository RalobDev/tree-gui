-- TODO: Transform all types (types.lua) into real and accessible values.

local ROOT = ... --- @type string

ROOT = ROOT:gsub("%.init$", "") -- Remove ".init" from the ROOT path.
ROOT = ROOT:gsub("/", ".") -- Change the "/" separator to "." to avoid bugs.

local DrawDebug = require(ROOT .. ".tools.debug_tool") --- @type TreeGUI.DebugDraw

--- @class TreeGUI
local TreeGUI = {
    ColorRect = require(ROOT .. ".visual.color_rect"), --- @type TreeGUI.ColorRect
    Container = require(ROOT .. ".containers.container"), --- @type TreeGUI.Container
    Theme = require(ROOT .. ".resources.theme"), --- @type TreeGUI.Theme
    Tree = require(ROOT .. ".core.tree"), --- @type TreeGUI.Tree
    Widget = require(ROOT .. ".core.widget.widget") --- @type TreeGUI.Widget
}


--#region Setters

--- @param layer TreeGUI.DebugDraw.Layers
--- @param enabled boolean?
function TreeGUI.setDebugLayerEnabled(layer, enabled)
    DrawDebug.layers[layer] = enabled ~= false
end

--#endregion


--#region Getters

--- @nodiscard
--- @param layer TreeGUI.DebugDraw.Layers
--- @return boolean enabled
function TreeGUI.isDebugLayerEnabled(layer)
    return DrawDebug.layers[layer]
end

--#endregion


return TreeGUI
