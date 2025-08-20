-- AutoForester_Core.lua
require "ISCoordConversion"
require "AutoForester_Debug"
AFCore = AFCore or {}

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
  AFLOG("getPlayer", "failed idx", idx)
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
  AFLOG("PILE","set", sq and sq:getX(), sq and sq:getY(), sq and sq:getZ())
end

function AFCore.clearStockpile()
  if AFCore.pileSq and AFCore.pileSq.setHighlighted then AFCore.pileSq:setHighlighted(false) end
  AFCore.pileSq = nil
end

function AFCore.getStockpile() return AFCore.pileSq end

-- --------- trees ----------
function AFCore.squareHasTree(sq)
  if not sq then return false end
  if sq.HasTree and sq:HasTree() then return true end
  local objs = sq:getObjects()
  for i=0,(objs and objs:size() or 0)-1 do
    if instanceof(objs:get(i), "IsoTree") then return true end
  end
  return false
end

function AFCore.getTreeFromSquare(sq)
  if not sq then return nil end
  if sq.getTree and sq:HasTree() then return sq:getTree() end
  local objs = sq:getObjects()
  for i=0,(objs and objs:size() or 0)-1 do
    local o = objs:get(i)
    if instanceof(o, "IsoTree") then return o end
  end
  return nil
end

function AFCore.treesInRect(rect)
  local res = {}
  if not rect then return res end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell(); if not cell then return res end
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if AFCore.squareHasTree(sq) then table.insert(res, sq) end
    end
  end
  AFLOG("TREES","in rect", #res)
  return res
end

-- Queue chops using vanilla actions (no custom TA required to validate flow)
function AFCore.queueChops(p, squares)
  local n=0
  for _,sq in ipairs(squares) do
    local tree = AFCore.getTreeFromSquare(sq)
    if tree then
      ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
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

-- (area job moved to AutoChopTask.startAreaJob)
