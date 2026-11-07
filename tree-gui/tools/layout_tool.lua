local ROOT = (...):match("^(.*)" .. string.rep("%.[^%.]+", 2) .. "$") --- @type string

local Enums = require(ROOT .. ".types.enums") --- @type TreeGUI.Enums

--- @class TreeGUI.Layout
local Layout = {}

local FLAGS = {
    FILL                 = { expand = false, align = Enums.SizeFlagsAlignment.FILL   },
    SHRINK_BEGIN         = { expand = false, align = Enums.SizeFlagsAlignment.BEGIN  },
    SHRINK_CENTER        = { expand = false, align = Enums.SizeFlagsAlignment.CENTER },
    SHRINK_END           = { expand = false, align = Enums.SizeFlagsAlignment.END    },
    EXPAND_FILL          = { expand = true,  align = Enums.SizeFlagsAlignment.FILL   },
    EXPAND_SHRINK_BEGIN  = { expand = true,  align = Enums.SizeFlagsAlignment.BEGIN  },
    EXPAND_SHRINK_CENTER = { expand = true,  align = Enums.SizeFlagsAlignment.CENTER },
    EXPAND_SHRINK_END    = { expand = true,  align = Enums.SizeFlagsAlignment.END    },
}


--#region Public

--- Returns flags data.
--- @nodiscard
--- @param flags TreeGUI.Enums.SizeFlags
--- @return boolean expand
--- @return TreeGUI.Enums.SizeFlagsAlignment align
function Layout.parseFlags(flags)
    local data = FLAGS[flags]
    if not data then error(string.format("Invalid SizeFlags: %s.", tostring(flags))) end
    return data.expand, data.align
end

--- Positions a child within the available space of an axis.
--- @nodiscard
--- @param align TreeGUI.Enums.SizeFlagsAlignment
--- @param available number
--- @param min number
--- @return number size, number offset
function Layout.align(align, available, min)
    if align == Enums.SizeFlagsAlignment.FILL then return math.max(available, min), 0 end
    if align == Enums.SizeFlagsAlignment.BEGIN then return min, 0 end
    if align == Enums.SizeFlagsAlignment.CENTER then return min, math.floor((available - min) / 2) end
    return min, available - min -- END
end

--- Offset to apply when `size` exceeds the `available` space, following the grow direction.
--- Returns 0 when there is no overflow.
--- @nodiscard
--- @param grow TreeGUI.Enums.GrowDirection
--- @param available number
--- @param size number
--- @return number offset
function Layout.growOffset(grow, available, size)
    local overflow = size - available
    if overflow <= 0 then return 0 end

    if grow == Enums.GrowDirection.BEGIN then return -overflow end
    if grow == Enums.GrowDirection.BOTH then return -math.floor(overflow / 2) end
    return 0 -- END
end

--- Resolves an axis from ANCHOR mode.
--- @nodiscard
--- @param anchor_begin number
--- @param anchor_end number
--- @param parent_size number
--- @param offset_begin number
--- @param offset_end number
--- @param min number
--- @param grow TreeGUI.Enums.GrowDirection
--- @return number position, number size
function Layout.anchorAxis(anchor_begin, anchor_end, parent_size, offset_begin, offset_end, min, grow)
    local begin_position = parent_size * anchor_begin + offset_begin
    local end_position = parent_size * anchor_end + offset_end
    local size = end_position - begin_position

    if size < min then
        local diff = min - size
        if grow == Enums.GrowDirection.BEGIN then
            begin_position = begin_position - diff
        elseif grow == Enums.GrowDirection.BOTH then
            begin_position = begin_position - diff / 2
        end -- END
        size = min
    end

    return begin_position, size
end

--#endregion


return Layout
