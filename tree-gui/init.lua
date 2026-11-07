-- TODO: Transform all types (types.lua) into real and accessible values.
-- TODO: Better organize the Widget's configure() method. Organizing it into regions is a good solution.
--       Keep the order dependency documented: anchor_preset must come BEFORE anchors/offsets/grow_direction.
-- TODO: Theme-related properties: the getter returns the RESOLVED value (override > theme > default),
--       and each property gets getXOverride() / setXOverride() (nil = follow the Theme).
--       Remove the old setX(). Apply to margins, paddings and separation (StackContainer).
--       Consider a protected _setStyleOverride(key, value) helper to avoid repeating boilerplate.
--       Props in configure() (e.g. margin_left) keep their names and write the override.

-- ?PERF: getStyleValue() climbs the parent chain on every call. If profiling shows it as a bottleneck
--        (most likely in _draw, called every frame), add a per-widget cache keyed by a global Theme.revision.
--        Keep the override OUT of the cache (check it first), bump the revision on any Theme mutation,
--        setTheme/setThemeVariant, Tree:setTheme and _setTree, and invalidate lazily on read.
--        Measure first: e.g. 1000 widgets drawing for 10s, with and without the cache.

local ROOT = ... --- @type string

ROOT = ROOT:gsub("%.init$", "") -- Remove ".init" from the ROOT path.
ROOT = ROOT:gsub("/", ".") -- Change the "/" separator to "." to avoid bugs.

local DrawDebug = require(ROOT .. ".tools.debug_tool") --- @type TreeGUI.DebugDraw

--- @class TreeGUI
local TreeGUI = {
    ColorRect = require(ROOT .. ".visual.color_rect"), --- @type TreeGUI.ColorRect
    Container = require(ROOT .. ".containers.container"), --- @type TreeGUI.Container
    Enums = require(ROOT .. ".types.enums"), --- @type TreeGUI.Enums
    StackContainer = require(ROOT .. ".containers.stack-containers.stack_container"), --- @type TreeGUI.StackContainer
    StackContainerH = require(ROOT .. ".containers.stack-containers.stack_container_h"), --- @type TreeGUI.StackContainerH
    StackContainerV = require(ROOT .. ".containers.stack-containers.stack_container_v"), --- @type TreeGUI.StackContainerV
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
