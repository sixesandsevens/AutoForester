AF = AF or {}
AF.Run = AF.Run or {}

-- Fetch the saved chop + pile designations.
local function getAreas()
    local md = ModData.getOrCreate("AutoForester")
    local a = md and md.areas or {}
    return a and a.chop, a and a.pile
end

function AF.Run.start(playerObj)
    local p = playerObj or getSpecificPlayer(0) or getPlayer()
    if not p then return end

    local chop, pile = getAreas()
    if not chop then if p.Say then p:Say("Set a Chop/Gather area first.") end; return end
    if not pile then if p.Say then p:Say("Set a Wood Pile area first.") end; return end

    -- Robustly load AF_Worker.
    local okW, AF_Worker = pcall(require, "AF_Worker")
    if not okW or type(AF_Worker) ~= "table" or type(AF_Worker.start) ~= "function" then
        print("[AutoForester][E] Failed to load AF_Worker: " .. tostring(AF_Worker))
        if p.Say then p:Say("AutoForester: worker not loaded (see console).") end
        return
    end

    print("[AutoForester] AutoForester starting…")
    AF_Worker.start(p, chop, pile)
end

return AF.Run
