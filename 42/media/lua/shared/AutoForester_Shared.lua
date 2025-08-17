-- Shared config/constants & small helpers

AutoForester_Shared = {}

AutoForester_Shared.ITEM_TYPES = {
    Log = true,
    TreeBranch = true,
    Twigs = true,
}

AutoForester_Shared.DefaultCfg = {
    radius = 20,                 -- tiles to search from player
    sweepRadius = 1,             -- tiles around stump to scavenge (Manhattan 1)
    stopWhenExerted = true,      -- pause when exerted
    minAxeCondition = 0.20,      -- stop queuing when axe < 20%
    sayFeedback = true,          -- player:Say(...) chatter
}

function AutoForester_Shared.Say(player, text)
    if not player or not AutoForester_Shared.DefaultCfg.sayFeedback then return end
    player:Say(text)
end

function AutoForester_Shared.IsOverEncumbered(player)
    if not player then return false end
    -- Some builds expose isOverEncumbered(); guard with pcall.
    local ok, res = pcall(function() return player:isOverEncumbered() end)
    return ok and res or false
end

return AutoForester_Shared
