AF = AF or {}
AF.Run = AF.Run or {}

local function safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil, (ok and nil or mod)
end

local function getAreas()
    local md = ModData.getOrCreate("AutoForester")
    local a  = md and md.areas or {}
    return a and a.chop, a and a.pile
end

function AF_Run_start(playerObj)
    local p = playerObj or getSpecificPlayer(0) or getPlayer()
    if not p then return end

    local chop, pile = getAreas()
    if not chop then p:Say("Set a Chop/Gather area first.") return end
    if not pile then p:Say("Set a Wood Pile area first.") return end

    local Worker, err = safeRequire("AF_Worker")
    if not Worker or type(Worker.start) ~= "function" then
        print("[AutoForester][E] worker not loaded:", tostring(err))
        p:Say("AutoForester: worker not loaded (see console).")
        return
    end

    print("[AutoForester][I] starting")
    Worker.start(p, chop, pile)
end

return AF.Run
