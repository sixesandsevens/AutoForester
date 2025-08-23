-- media/lua/client/AF_Context.lua
if rawget(_G, "AF_ContextLoaded") then return end
_G.AF_ContextLoaded = true

require "AF_Core"
require "AF_TwoClickSelect"
require "ISUI/ISCoordConversion"

AF_Context = AF_Context or {}

local function addOnce()
    if AF_Context._hooked then return end
    Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldobjects, test)
        AF_Context.onFill(playerNum, context, worldobjects, test)
    end)
    AF_Context._hooked = true
end

function AF_Context.onFill(playerNum, context, worldobjects, test)
    if test then return end
    local player = getSpecificPlayer(playerNum) or getPlayer()
    if not player then return end

    local added = {}

    local function add(label, fn)
        if added[label] then return end
        added[label] = true
        context:addOption(label, nil, fn)
    end

    add("Designate Wood Pile Here", function()
        local sq = AFCore.getMouseSquare(player)
        if sq then
            AFCore.setStockpile(sq)
            if player.Say then player:Say("Wood pile set.") end
        else
            if player.Say then player:Say("No square under mouse.") end
        end
    end)

    add("Set Chop Area...", function()
        AF_Select.pickArea(worldobjects, player, function(r)
            AFCore.ChopArea = r
            if player.Say then player:Say(string.format("Chop area: %d,%d to %d,%d", r.x1, r.y1, r.x2, r.y2)) end
        end, "chop area")
    end)

    add("Set Gather Area...", function()
        AF_Select.pickArea(worldobjects, player, function(r)
            AFCore.GatherArea = r
            if player.Say then player:Say("Gather area set.") end
        end, "gather area")
    end)

    add("Start AutoForester (Area)", function()
        if not AFCore.ChopArea then if player.Say then player:Say("Set chop area first.") end return end
        if not AFCore.getStockpile() then if player.Say then player:Say("Designate a wood pile first.") end return end
        if player.Say then player:Say("AutoForester starting… (stub)") end
    end)
end

addOnce()
