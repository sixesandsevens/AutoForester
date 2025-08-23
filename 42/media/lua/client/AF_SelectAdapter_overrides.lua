-- AF_SelectAdapter_overrides.lua (patch build)
-- Coerces "rect == 0" to nil in callbacks so callers can just test "not rect".

local function wrapPickArea()
    if not AF_Select or not AF_Select.pickArea or _G.__AF_PICKAREA_WRAPPED then return end
    local orig = AF_Select.pickArea
    AF_Select.pickArea = function(worldobjects, p, cb, tag)
        return orig(worldobjects, p, function(rect, area)
            if rect == 0 then rect = nil end
            cb(rect, area)
        end, tag)
    end
    _G.__AF_PICKAREA_WRAPPED = true
    print("AutoForester (patch): AF_Select.pickArea wrapped")
end

Events.OnGameStart.Add(wrapPickArea)
