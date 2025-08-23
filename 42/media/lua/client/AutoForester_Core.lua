-- media/lua/client/AutoForester_Core.lua
require "ISCoordConversion"
require "AutoForester_Debug"

AFCore = AFCore or {}

-- Player helper
function AFCore.getPlayer(pOrIndex)
  local idx = 0
  if type(pOrIndex) == "number" then idx = pOrIndex
  elseif type(pOrIndex) == "table" and pOrIndex.getPlayerNum then idx = pOrIndex:getPlayerNum()
  end
  return getSpecificPlayer(idx)
end

-- Mouse -> square (current Z)
function AFCore.squareUnderMouse(p)
  local pz = (p and p:getZ()) or 0
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local wx = ISCoordConversion.ToWorldX(mx,my,0)
  local wy = ISCoordConversion.ToWorldY(mx,my,0)
  local cell = getCell(); if not cell then return nil end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), pz)
end

-- ---------- Stockpile marker ----------
AFCore._pileSq = AFCore._pileSq or nil

function AFCore.setStockpile(sq)
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then
    AFCore._pileSq:setHighlighted(false)
  end
  AFCore._pileSq = sq
  if sq and sq.setHighlighted then
    sq:setHighlighted(true)
    if sq.setHighlightColor then sq:setHighlightColor(0.9, 0.8, 0.2) end
  end
  AFLOG("PILE","set", sq and sq:getX(), sq and sq:getY(), sq and sq:getZ())
end

function AFCore.getStockpile() return AFCore._pileSq end

function AFCore.clearStockpile()
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then
    AFCore._pileSq:setHighlighted(false)
  end
  AFCore._pileSq = nil
  AFLOG("PILE","cleared")
end

-- ---------- Trees ----------
function AFCore.squareHasTree(sq)
  if not sq then return false end
  local objs = sq:getObjects()
  for i=0,(objs and objs:size() or 0)-1 do
    if instanceof(objs:get(i), "IsoTree") then return true end
  end
  return false
end

function AFCore.getTreeFromSquare(sq)
  if not sq then return nil end
  local objs = sq:getObjects()
  for i=0,(objs and objs:size() or 0)-1 do
    local o = objs:get(i)
    if instanceof(o, "IsoTree") then return o end
  end
  return nil
end

function AFCore.treesInRect(rect)
  if not rect then return {} end
  local x1 = tonumber(rect[1]); local y1 = tonumber(rect[2])
  local x2 = tonumber(rect[3]); local y2 = tonumber(rect[4])
  local z  = tonumber(rect[5]) or 0
  if not (x1 and y1 and x2 and y2) then return {} end
  local out = {}
  local cell = getCell(); if not cell then return out end
  for y=y1,y2 do
    for x=x1,x2 do
      local sq = cell:getGridSquare(x,y,z)
      if AFCore.squareHasTree(sq) then table.insert(out, sq) end
    end
  end
  return out
end

function AFCore.queueChops(p, squares)
  local n = 0
  for _,sq in ipairs(squares or {}) do
    local tree = AFCore.getTreeFromSquare(sq)
    if tree then
      ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
      ISWorldObjectContextMenu.onChopTree(p, tree)
      AFLOG("CHOP","queued",sq:getX(),sq:getY(),sq:getZ())
      n = n + 1
    end
  end
  return n
end
