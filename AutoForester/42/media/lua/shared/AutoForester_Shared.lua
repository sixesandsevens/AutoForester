-- Shared config/constants & small helpers

AutoForester_Shared = {}

AutoForester_Shared.ITEM_TYPES = {
    Log = true,
    TreeBranch = true,
    Twigs = true,
}

AutoForester_Shared.DefaultCfg = {
    radius = 20,
    stopWhenExerted = true,
    minAxeCondition = 0.20,
    sayFeedback = true,
}

function AutoForester_Shared.Say(player, text)
    if not player or not AutoForester_Shared.DefaultCfg.sayFeedback then return end
    player:Say(text)
end

return AutoForester_Shared
