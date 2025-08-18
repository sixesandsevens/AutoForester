AutoForester_Shared = AutoForester_Shared or {}

local MD = ModData.getOrCreate("AutoForester")

AutoForester_Shared.ITEM_TYPES = { Log=true, TreeBranch=true, Twigs=true }

AutoForester_Shared.cfg = { radius=15, sweepRadius=1, say=true }

local function save() MD.Stockpile = AutoForester_Shared.Stockpile end

function AutoForester_Shared.say(p, txt)
  if AutoForester_Shared.cfg.say and p and p.Say then p:Say(txt) end
end

function AutoForester_Shared.setPile(sq)
  if not sq then return end
  AutoForester_Shared.Stockpile = {x=sq:getX(), y=sq:getY(), z=sq:getZ()}
  save()
end

function AutoForester_Shared.clearPile() AutoForester_Shared.Stockpile=nil; save() end

function AutoForester_Shared.getPileSquare()
  local sp = AutoForester_Shared.Stockpile
  if not sp then return nil end
  return getCell():getGridSquare(sp.x, sp.y, sp.z)
end

return AutoForester_Shared
