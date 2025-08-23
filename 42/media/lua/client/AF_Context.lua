
-- media/lua/client/AF_Context.lua
local AFCore   = require "AF_Core"
local AF_Log   = require "AF_Logger"
local AF_Select= require "AF_TwoClickSelect"
local AF_Worker= require "AF_Worker"

local function addEntries(player, context, worldobjects, test)
    if test then return end
    local p = getSpecificPlayer(player) or getPlayer()
    if not p then return end
    local sq = AFCore.worldSquareUnderMouse(p:getZ() or 0)
    if not sq then return end

    -- Always: Designate Wood Pile
    context:addOption(getTextOrNull("IGUI_AF_DesignateWoodPile") or "Designate Wood Pile Here", worldobjects, function()
        local s = AFCore.worldSquareUnderMouse(p:getZ() or 0)
        if s then AFCore.setWoodPile(s:getX(), s:getY(), s:getZ()) end
    end)

    -- Start AutoForester: prefer JB selection if active, otherwise two-click picker.
    context:addOption(getTextOrNull("IGUI_AF_Start") or "Start AutoForester", worldobjects, function()
        local rect = AFCore.readJBSelectionRect()
        if rect then
            AF_Log.info("Using JB selection rect.")
            AF_Worker.start(p, rect, p:getZ() or 0)
            return
        end

        AF_Select.pickArea(worldobjects, p, function(player, pickedRect, z, tag)
            AF_Worker.start(player, pickedRect, z)
        end, "AutoForester")
    end)
end

Events.OnFillWorldObjectContextMenu.Add(addEntries)
