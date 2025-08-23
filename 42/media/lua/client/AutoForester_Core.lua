-- AutoForester_Core.lua
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

-- Rect helpers ---------------------------------------------------------------
local function rect_order(a,b) if a>b then return b,a else return a,b end end
function AFCore.normalizeRect(rect)
  if type(rect)~="table" then return nil end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  if not x1 or not y1 or not x2 or not y2 then return nil end
  x1,x2 = rect_order(tonumber(x1), tonumber(x2))
  y1,y2 = rect_order(tonumber(y1), tonumber(y2))
  return { x1,y1,x2,y2,z }
end
function AFCore.rectWidth(rect)  rect = AFCore.normalizeRect(rect); return rect and (rect[3]-rect[1]+1) or 0 end
function AFCore.rectHeight(rect) rect = AFCore.normalizeRect(rect); return rect and (rect[4]-rect[2]+1) or 0 end

-- Mouse -> square (current Z) ------------------------------------------------
-- Returns IsoGridSquare under the player’s mouse, without needing a click.
function AFCore.getMouseSquare(p)
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local z = (p and p:getZ()) or 0
  local wx = ISCoordConversion.ToWorldX(mx,my,0)
  local wy = ISCoordConversion.ToWorldY(mx,my,0)
  local cell = getCell(); if not cell then return nil end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- --------- stockpile marker -------------------------------------------------
AFCore._pileSq = AFCore._pileSq or nil
function AFCore.setStockpile(sq)
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then
    AFCore._pileSq:setHighlighted(false)
  end
  AFCore._pileSq = sq
  if sq and sq.setHighlighted then
    sq:setHighlighted(true)
    if sq.setHighlightColor then sq:setHighlightColor(0.9,0.8,0.2) end
  end
  AFLOG("PILE","set at", sq and (sq:getX()..","..sq:getY()..","..sq:getZ()) or "nil")
end
function AFCore.getStockpile() return AFCore._pileSq end
function AFCore.clearStockpile()
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then
    AFCore._pileSq:setHighlighted(false)
  end
  AFCore._pileSq = nil
  AFLOG("PILE","cleared")
end

-- ---------- Trees -----------------------------------------------------------
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
  rect = AFCore.normalizeRect(rect); if not rect then return {} end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
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
