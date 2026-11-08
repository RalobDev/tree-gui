local ROOT = ... --- @type string

ROOT = ROOT:gsub("%.init$", "") -- Remove ".init" from the ROOT path.
ROOT = ROOT:gsub("/", ".") -- Change the "/" separator to "." to avoid bugs.

local DrawDebug = require(ROOT .. ".tools.debug_tool") --- @type TreeGUI.DebugDraw

--- @class TreeGUI
local TreeGUI = {
    Button = require(ROOT .. ".core.buttons.button"), --- @type TreeGUI.Button
    ColorRect = require(ROOT .. ".visual.color_rect"), --- @type TreeGUI.ColorRect
    Container = require(ROOT .. ".containers.container"), --- @type TreeGUI.Container
    Enums = require(ROOT .. ".types.enums"), --- @type TreeGUI.Enums
    Label = require(ROOT .. ".visual.label"), --- @type TreeGUI.Label
    Panel = require(ROOT .. ".visual.panel"), --- @type TreeGUI.Panel
    StackContainer = require(ROOT .. ".containers.stack-containers.stack_container"), --- @type TreeGUI.StackContainer
    StackContainerH = require(ROOT .. ".containers.stack-containers.stack_container_h"), --- @type TreeGUI.StackContainerH
    StackContainerV = require(ROOT .. ".containers.stack-containers.stack_container_v"), --- @type TreeGUI.StackContainerV
    StyleBox = require(ROOT .. ".resources.style_box"), --- @type TreeGUI.StyleBox
    TextSettings = require(ROOT .. ".resources.text_settings"), --- @type TreeGUI.TextSettings
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
