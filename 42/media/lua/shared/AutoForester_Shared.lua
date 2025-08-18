-- Shared constants & data (PZ B42)
AutoForester_Shared = AutoForester_Shared or {}

-- items we’ll haul
AutoForester_Shared.ITEM_TYPES = {
  Log = true, TreeBranch = true, Twigs = true,
}

-- persistent stockpile (saved in ModData for this save)
local MD = ModData.getOrCreate("AutoForester")
AutoForester_Shared.Stockpile = MD.Stockpile or nil
local function save() MD.Stockpile = AutoForester_Shared.Stockpile end

-- defaults (tweak later with ModOptions if you like)
AutoForester_Shared.cfg = {
  radius = 15,        -- search radius in tiles (kept moderate)
  sweepRadius = 1,    -- pick up drops in 3x3 around stump
  say = true,
}

function AutoForester_Shared.say(p, txt)
  if AutoForester_Shared.cfg.say and p and p.Say then p:Say(txt) end
end

function AutoForester_Shared.setPile(sq)
  if not sq then return end
  AutoForester_Shared.Stockpile = {x=sq:getX(), y=sq:getY(), z=sq:getZ()}
  save()
end

function AutoForester_Shared.clearPile()
  AutoForester_Shared.Stockpile = nil
  save()
end

function AutoForester_Shared.getPileSquare()
  local sp = AutoForester_Shared.Stockpile
  if not sp then return nil end
  return getCell():getGridSquare(sp.x, sp.y, sp.z)
end

return AutoForester_Shared
