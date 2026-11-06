--- @class TreeGUI.Layout
local Layout = {}

local FLAGS = {
    FILL                 = { expand = false, align = "FILL"   },
    SHRINK_BEGIN         = { expand = false, align = "BEGIN"  },
    SHRINK_CENTER        = { expand = false, align = "CENTER" },
    SHRINK_END           = { expand = false, align = "END"    },
    EXPAND_FILL          = { expand = true,  align = "FILL"   },
    EXPAND_SHRINK_BEGIN  = { expand = true,  align = "BEGIN"  },
    EXPAND_SHRINK_CENTER = { expand = true,  align = "CENTER" },
    EXPAND_SHRINK_END    = { expand = true,  align = "END"    },
}


--#region Public

--- Returns flags data.
--- @nodiscard
--- @param flags TreeGUI.SizeFlags
--- @return boolean expand
--- @return TreeGUI.SizeFlagsAlignment align
function Layout.parseFlags(flags)
    local data = FLAGS[flags]
    if not data then error(string.format("Invalid SizeFlags: %s.", tostring(flags))) end
    return data.expand, data.align
end

--- Positions a child within the available space of an axis.
--- @nodiscard
--- @param align TreeGUI.SizeFlagsAlignment
--- @param available number
--- @param min number
--- @return number size, number offset
function Layout.align(align, available, min)
    if align == "FILL" then return math.max(available, min), 0 end
    if align == "BEGIN" then return min, 0 end
    if align == "CENTER" then return min, math.floor((available - min) / 2) end
    return min, available - min -- END
end

--- Resolves an axis from ANCHOR mode.
--- @nodiscard
--- @param anchor_begin number
--- @param anchor_end number
--- @param parent_size number
--- @param offset_begin number
--- @param offset_end number
--- @param min number
--- @param grow TreeGUI.GrowDirection
--- @return number position, number size
function Layout.anchorAxis(anchor_begin, anchor_end, parent_size, offset_begin, offset_end, min, grow)
    local begin_position = parent_size * anchor_begin + offset_begin
    local end_position = parent_size * anchor_end + offset_end
    local size = end_position - begin_position

    if size < min then
        local diff = min - size
        if grow == "BEGIN" then
            begin_position = begin_position - diff
        elseif grow == "BOTH" then
            begin_position = begin_position - diff / 2
        end -- END
        size = min
    end

    return begin_position, size
end

--#endregion


return Layout
