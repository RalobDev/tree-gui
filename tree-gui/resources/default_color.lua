--- @class TreeGUI.DefaultColor
local DefaultColor = {}

DefaultColor.light = {
    -- Backgrounds
    background           = { 0.957, 0.969, 0.941, 1.0 },
    surface              = { 0.898, 0.929, 0.878, 1.0 },
    surface_variant      = { 0.796, 0.851, 0.765, 1.0 },

    -- Primary
    primary              = { 0.204, 0.345, 0.227, 1.0 },
    primary_hover        = { 0.271, 0.420, 0.290, 1.0 },
    primary_pressed      = { 0.153, 0.263, 0.176, 1.0 },
    on_primary           = { 0.957, 0.969, 0.941, 1.0 },
    primary_disabled     = { 0.765, 0.808, 0.745, 1.0 },
    on_primary_disabled  = { 0.490, 0.545, 0.478, 1.0 },

    -- Secondary
    secondary             = { 0.322, 0.463, 0.290, 1.0 },
    secondary_hover       = { 0.420, 0.549, 0.365, 1.0 },
    on_secondary          = { 0.980, 0.988, 0.969, 1.0 },
    secondary_disabled    = { 0.831, 0.863, 0.800, 1.0 },
    on_secondary_disabled = { 0.580, 0.627, 0.549, 1.0 },

    -- Text
    text                  = { 0.145, 0.208, 0.157, 1.0 },
    text_secondary        = { 0.365, 0.431, 0.365, 1.0 },
    text_disabled         = { 0.580, 0.627, 0.565, 1.0 },

    -- Borders
    border                = { 0.765, 0.816, 0.729, 1.0 },
    border_focus          = { 0.322, 0.463, 0.290, 1.0 },

    -- Feedback
    success               = { 0.267, 0.541, 0.337, 1.0 },
    warning               = { 0.780, 0.580, 0.267, 1.0 },
    error                 = { 0.733, 0.298, 0.267, 1.0 },
    info                  = { 0.310, 0.506, 0.596, 1.0 },

    -- Misc
    shadow                = { 0.102, 0.157, 0.110, 0.12 },
    overlay               = { 0.102, 0.157, 0.110, 0.40 },
}

DefaultColor.dark = {
    -- Backgrounds
    background            = { 0.082, 0.110, 0.090, 1.0 },
    surface               = { 0.118, 0.161, 0.129, 1.0 },
    surface_variant       = { 0.161, 0.220, 0.176, 1.0 },

    -- Primary
    primary               = { 0.643, 0.745, 0.569, 1.0 },
    primary_hover         = { 0.733, 0.824, 0.647, 1.0 },
    primary_pressed       = { 0.510, 0.643, 0.439, 1.0 },
    primary_disabled      = { 0.263, 0.329, 0.271, 1.0 },
    on_primary            = { 0.102, 0.157, 0.110, 1.0 },
    on_primary_disabled   = { 0.510, 0.565, 0.478, 1.0 },

    -- Secondary
    secondary             = { 0.447, 0.576, 0.424, 1.0 },
    secondary_hover       = { 0.549, 0.678, 0.510, 1.0 },
    secondary_disabled    = { 0.200, 0.267, 0.208, 1.0 },
    on_secondary          = { 0.082, 0.110, 0.090, 1.0 },
    on_secondary_disabled = { 0.447, 0.510, 0.408, 1.0 },

    -- Text
    text                  = { 0.835, 0.894, 0.788, 1.0 },
    text_secondary        = { 0.643, 0.714, 0.608, 1.0 },
    text_disabled         = { 0.400, 0.471, 0.400, 1.0 },

    -- Borders
    border                = { 0.247, 0.329, 0.259, 1.0 },
    border_focus          = { 0.643, 0.745, 0.569, 1.0 },

    -- Feedback
    success               = { 0.478, 0.725, 0.510, 1.0 },
    warning               = { 0.875, 0.698, 0.388, 1.0 },
    error                 = { 0.878, 0.478, 0.427, 1.0 },
    info                  = { 0.510, 0.694, 0.769, 1.0 },

    -- Misc
    shadow                = { 0.0, 0.0, 0.0, 0.30 },
    overlay               = { 0.0, 0.0, 0.0, 0.55 },
}

return DefaultColor
