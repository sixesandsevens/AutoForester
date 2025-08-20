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
  -- unhighlight previous
  if AFCore.pileSq and AFCore.pileSq.setHighlighted then
    AFCore.pileSq:setHighlighted(false)
  end
  AFCore.pileSq = sq
  if sq and sq.setHighlighted then
    sq:setHighlighted(true)
    if sq.setHighlightColor then sq:setHighlightColor(0.9, 0.8, 0.2) end
  end
  AFLOG("PILE", "set at", sq and sq:getX(), sq and sq:getY(), sq and sq:getZ())
end

function AFCore.clearStockpile()
  if AFCore.pileSq and AFCore.pileSq.setHighlighted then
    AFCore.pileSq:setHighlighted(false)
  end
  AFCore.pileSq = nil
  AFLOG("PILE", "cleared")
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
  local out = {}
  if not rect then return out end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local cell = getCell(); if not cell then return out end
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if AFCore.squareHasTree(sq) then table.insert(out, sq) end
    end
  end
  if #out > 0 then
    local f = out[1]
    local l = out[#out]
    AFLOG("TREES", "found", #out, "from", f:getX(), f:getY(), "to", l:getX(), l:getY())
  else
    AFLOG("TREES", "found", 0)
  end
  return out
end

-- Queue chops using vanilla actions (no custom TA required to validate flow)
function AFCore.queueChops(player, squares)
  local n = 0
  for _,sq in ipairs(squares) do
    local tree = AFCore.getTreeFromSquare(sq)
    if tree then
      ISTimedActionQueue.add(ISWalkToTimedAction:new(player, sq))
      -- use vanilla helper to enqueue correct chop TA:
      ISWorldObjectContextMenu.onChopTree(player, tree)
      AFLOG("CHOP", "queued", sq:getX(), sq:getY(), sq:getZ())
      n = n + 1
    end
  end
  return n
end

