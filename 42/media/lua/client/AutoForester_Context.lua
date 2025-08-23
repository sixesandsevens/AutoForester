-- AutoForester_Context.lua  (drop-in patch)
require "AF_TwoClickSelect"
require "AFCore"
require "AF_Log"

-- Optional: your task module if present; otherwise we no-op the calls
local hasAutoChop = false
if pcall(function() require "AutoChopTask" end) then hasAutoChop = true end

local function setChopRect(rect, area)
    if hasAutoChop and AutoChopTask and AutoChopTask.setChopRect then
        AutoChopTask.setChopRect(rect, area)
    else
        AF_Log.info("ChopRect set", rect and table.concat(rect, ",") or "nil", "area=", area or 0)
        _G.__AF_DEBUG_CHOP = rect
    end
end
local function setGatherRect(rect, area)
    if hasAutoChop and AutoChopTask and AutoChopTask.setGatherRect then
        AutoChopTask.setGatherRect(rect, area)
    else
        AF_Log.info("GatherRect set", rect and table.concat(rect, ",") or "nil", "area=", area or 0)
        _G.__AF_DEBUG_GATHER = rect
    end
end
local function startAreaJob(p)
    if hasAutoChop and AutoChopTask and AutoChopTask.startAreaJob then
        AutoChopTask.startAreaJob(p)
    else
        AF_Log.info("StartAreaJob (stub)")
    end
end

local function addMenu(playerIndex, context, worldobjects, test)
    if test then return end
    local p = getSpecificPlayer(playerIndex or 0) or getPlayer()
    if not p or not p:isAlive() then return end

    -- Designate wood pile: take the square under the clicked menu (worldobjects[1])
    context:addOption("Designate Wood Pile Here", worldobjects, function()
        local sq
        if worldobjects and worldobjects[1] then
            local obj = worldobjects[1]
            if obj.getSquare then sq = obj:getSquare()
            elseif obj.square then sq = obj.square end
        end
        if not sq then sq = p:getSquare() end
        if not sq then if p.Say then p:Say("No tile.") end return end
        AF_Log.safe("setStockpile", function() AFCore.setStockpile(sq) end)
        if p.Say then p:Say("Wood pile set.") end
    end)

    -- Set Chop Area
    context:addOption("Set Chop Area...", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            rect = AFCore.normalizeRect(rect)
            if not rect then if p.Say then p:Say("No area.") end return end
            setChopRect(rect, area)
            local w = AFCore.rectWidth(rect)
            local h = AFCore.rectHeight(rect)
            if p.Say then p:Say(("Chop area: %dx%d."):format(w, h)) end
        end, "chop")
    end)

    -- Set Gather Area
    context:addOption("Set Gather Area...", worldobjects, function()
        AF_Select.pickArea(worldobjects, p, function(rect, area)
            rect = AFCore.normalizeRect(rect)
            if not rect then if p.Say then p:Say("No area.") end return end
            setGatherRect(rect, area)
            local w = AFCore.rectWidth(rect)
            local h = AFCore.rectHeight(rect)
            if p.Say then p:Say(("Gather area: %dx%d."):format(w, h)) end
        end, "gather")
    end)

    -- Start
    context:addOption("Start AutoForester (Area)", worldobjects, function() startAreaJob(p) end)
end

local function hook()
    if not Events or not Events.OnFillWorldObjectContextMenu then
        return
    end
    -- Always re-register cleanly
    if Events.OnFillWorldObjectContextMenu.RemoveByName then
        Events.OnFillWorldObjectContextMenu.RemoveByName("AutoForester-Context")
    end
    Events.OnFillWorldObjectContextMenu.Add(addMenu)
    AF_Log.info("context menu registered")
end

Events.OnGameStart.Add(hook)
Events.OnCreatePlayer.Add(hook)
-- also hook on reload (dev mode)
if Events.OnLoad then Events.OnLoad.Add(hook) end
