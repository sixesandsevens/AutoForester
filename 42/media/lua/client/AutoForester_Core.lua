-- AutoForester_Core.lua
require "ISCoordConversion"
AFCore = AFCore or {}

-- --------- debug toggle ----------
AF_DEBUG = AF_DEBUG ~= false
local function DBG(tag, ...) if AF_DEBUG then print("[AF]["..tostring(tag).."]", ...) end end
local function SAY(p, msg) if p and p.Say then p:Say(msg) end end

-- --------- soft-detect JB selector ----------
-- DO NOT require by name; workshop name can vary. The JB lib usually exposes a global table.
local hasJB = type(JB_ASSUtils) == "table"

-- --------- player / square helpers ----------
function AF_getPlayer(maybePi)
  local idx = 0
  if type(maybePi) == "number" then idx = maybePi
  elseif type(maybePi) == "table" and maybePi.getPlayerNum then idx = maybePi:getPlayerNum()
  end
  local p = getSpecificPlayer(idx)
  if p and p:isAlive() then return p, idx end
  DBG("getPlayer","failed idx",idx)
  return nil, idx
end

-- WorldObjects → a sensible IsoGridSquare, else mouse square
function AF_getContextSquare(worldobjects)
  -- from worldobjects first
  if worldobjects then
    for i=1,#worldobjects do
      local o = worldobjects[i]
      if o and o.getSquare then
        local sq = o:getSquare()
        if sq then return sq end
      end
    end
  end
  -- mouse fallback
  local p = getSpecificPlayer(0)
  local z = (p and p:getZ()) or 0
  local mx, my = getMouseXScaled(), getMouseYScaled()
  local wx = ISCoordConversion.ToWorldX(mx,my,0)
  local wy = ISCoordConversion.ToWorldY(mx,my,0)
  local cell = getCell(); if not cell then return nil end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- --------- stockpile marker ----------
AFCore.pileSq = AFCore.pileSq or nil

function AFCore.setStockpile(sq)
  AFCore.pileSq = sq
  if sq and sq.setHighlighted then
    sq:setHighlighted(true)
    if sq.setHighlightColor then sq:setHighlightColor(0.95,0.85,0.20) end
  end
  DBG("PILE","set", sq and sq:getX(), sq and sq:getY(), sq and sq:getZ())
end

function AFCore.clearStockpile()
  if AFCore.pileSq and AFCore.pileSq.setHighlighted then AFCore.pileSq:setHighlighted(false) end
  AFCore.pileSq = nil
end

function AFCore.getStockpile() return AFCore.pileSq end

-- --------- trees ----------
local function squareHasTree(sq)
  if not sq then return false end
  if sq.HasTree and sq:HasTree() then return true end
  local os = sq:getObjects()
  for i=0,(os and os:size() or 0)-1 do
    if instanceof(os:get(i), "IsoTree") then return true end
  end
  return false
end

local function getTreeFromSquare(sq)
  if not sq then return nil end
  if sq.getTree and sq:HasTree() then return sq:getTree() end
  local os = sq:getObjects()
  for i=0,(os and os:size() or 0)-1 do
    local o = os:get(i)
    if instanceof(o, "IsoTree") then return o end
  end
  return nil
end

function AFCore.treesInRect(r)
  local res, cell = {}, getCell(); if not (r and cell) then return res end
  local x1,y1,x2,y2,z = r[1],r[2],r[3],r[4],r[5] or 0
  for y=y1,y2 do for x=x1,x2 do
    local sq = cell:getGridSquare(x,y,z)
    if squareHasTree(sq) then table.insert(res, sq) end
  end end
  DBG("TREES","in rect", #res)
  return res
end

-- Queue chops using vanilla actions (no custom TA required to validate flow)
function AFCore.queueChops(p, squares)
  local n=0
  for _,sq in ipairs(squares) do
    local tree = getTreeFromSquare(sq)
    if tree then
      ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
      -- vanilla helper schedules swing(s):
      ISWorldObjectContextMenu.doChopTree(p, tree)
      n = n + 1
    end
  end
  return n
end

-- Immediately drop heavy loot after some chops so we don’t stall on weight
function AFCore.dropTreeLootNow(p)
  local inv = p and p:getInventory(); if not inv then return end
  local types = { "Base.Log", "Base.TreeBranch", "Base.LargeBranch", "Base.Twigs", "Base.Sapling" }
  for _,full in ipairs(types) do
    local items = inv:getItemsFromFullType(full)
    if items then
      for i=0,items:size()-1 do
        ISTimedActionQueue.add(ISDropItemAction:new(p, items:get(i)))
      end
    end
  end
end

-- --------- area job entry (chop only; sweep/haul can follow) ----------
function AFCore.startAreaJob(pOrIndex, chopRect, gatherRect)
  local p = AF_getPlayer(pOrIndex); if not p then return end
  if not chopRect then SAY(p,"Set chop area first."); return end
  if not AFCore.getStockpile() then SAY(p,"Designate wood pile first."); return end

  local list = AFCore.treesInRect(chopRect)
  if #list == 0 then SAY(p,"No trees in chop area."); return end

  local n = AFCore.queueChops(p, list)
  -- yield + drop now
  ISTimedActionQueue.add(ISBaseTimedAction:new(p)) -- micro-yield
  ISTimedActionQueue.add(ISBaseTimedAction:new(p)) -- micro-yield
  ISTimedActionQueue.add(ISBaseTimedAction:new(p)) -- keep simple
  AFCore.dropTreeLootNow(p)

  SAY(p, ("Queued %d tree(s)."):format(n))
  DBG("JOB","queued", n)
end
