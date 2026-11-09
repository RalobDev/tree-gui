--- RGBA color with components in the 0-1 range.
--- @alias TreeGUI.Color [number, number, number, number?]

--- Theme data: one optional style table per Widget type name.
--- @class TreeGUI.Theme.Data
--- @field Button TreeGUI.Theme.ButtonStyle?
--- @field ColorRect TreeGUI.Theme.WidgetStyle?
--- @field Container TreeGUI.Theme.ContainerStyle?
--- @field Label TreeGUI.Theme.LabelStyle?
--- @field Panel TreeGUI.Theme.PanelStyle?
--- @field StackContainer TreeGUI.Theme.StackContainerStyle?
--- @field StackContainerH TreeGUI.Theme.StackContainerStyle?
--- @field StackContainerV TreeGUI.Theme.StackContainerStyle?
--- @field Widget TreeGUI.Theme.WidgetStyle?

--- @class TreeGUI.Theme.Variants
--- @field Button table<string, TreeGUI.Theme.ButtonStyle>?
--- @field ColorRect table<string, TreeGUI.Theme.WidgetStyle>?
--- @field Container table<string, TreeGUI.Theme.ContainerStyle>?
--- @field Label table<string, TreeGUI.Theme.LabelStyle>?
--- @field Panel table<string, TreeGUI.Theme.PanelStyle>?
--- @field StackContainer table<string, TreeGUI.Theme.StackContainerStyle>?
--- @field StackContainerH table<string, TreeGUI.Theme.StackContainerStyle>?
--- @field StackContainerV table<string, TreeGUI.Theme.StackContainerStyle>?
--- @field Widget table<string, TreeGUI.Theme.WidgetStyle>?

--- Style properties shared by every Widget.
--- @class TreeGUI.Theme.WidgetStyle
--- @field margin_left number?
--- @field margin_top number?
--- @field margin_right number?
--- @field margin_bottom number?

--- @class TreeGUI.Theme.ButtonStyle

--- @class TreeGUI.Theme.ContainerStyle: TreeGUI.Theme.WidgetStyle
--- @field padding_left number?
--- @field padding_top number?
--- @field padding_right number?
--- @field padding_bottom number?

--- @class TreeGUI.Theme.LabelStyle: TreeGUI.Theme.WidgetStyle
--- @field text_settings TreeGUI.TextSettings?

--- @class TreeGUI.Theme.PanelStyle: TreeGUI.Theme.WidgetStyle
--- @field style_box TreeGUI.StyleBox?

--- @class TreeGUI.Theme.StackContainerStyle: TreeGUI.Theme.ContainerStyle
--- @field separation number?
