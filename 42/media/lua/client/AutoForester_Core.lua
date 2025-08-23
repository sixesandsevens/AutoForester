-- AutoForester_Core.lua
require "ISCoordConversion"
require "AutoForester_Debug"

AFCore = AFCore or {}

function AFCore.getPlayer(pOrIndex)
  local idx = 0
  if type(pOrIndex) == "number" then idx = pOrIndex
  elseif type(pOrIndex) == "table" and pOrIndex.getPlayerNum then idx = pOrIndex:getPlayerNum()
  end
  return getSpecificPlayer(idx)
end

-- Tolerant rect normalize: accepts arrays (x1,y1,x2,y2[,z]) or keyed tables.
function AFCore.normalizeRect(rect)
  if not rect or type(rect) ~= "table" then return nil end
  local x1,y1,x2,y2,z

  if rect.x1 or rect.y1 or rect.x2 or rect.y2 then
    x1 = rect.x1 or rect[1]; y1 = rect.y1 or rect[2]
    x2 = rect.x2 or rect[3]; y2 = rect.y2 or rect[4]
    z  = rect.z  or rect[5] or 0
  elseif rect.x and rect.y and rect.w and rect.h then
    x1, y1 = rect.x, rect.y
    x2, y2 = rect.x + rect.w - 1, rect.y + rect.h - 1
    z = rect.z or 0
  else
    x1,y1,x2,y2,z = rect[1], rect[2], rect[3], rect[4], rect[5] or 0
  end

  x1 = math.floor(tonumber(x1) or x1 or 0)
  y1 = math.floor(tonumber(y1) or y1 or 0)
  x2 = math.floor(tonumber(x2) or x2 or 0)
  y2 = math.floor(tonumber(y2) or y2 or 0)
  z  = math.floor(tonumber(z)  or z  or 0)

  if x1 > x2 then x1,x2 = x2,x1 end
  if y1 > y2 then y1,y2 = y2,y1 end
  return {x1,y1,x2,y2,z}
end

function AFCore.rectWidth(rect)  rect = AFCore.normalizeRect(rect); return rect and (rect[3]-rect[1]+1) or 0 end
function AFCore.rectHeight(rect) rect = AFCore.normalizeRect(rect); return rect and (rect[4]-rect[2]+1) or 0 end

-- Mouse -> square at player's z (no click)
function AFCore.getMouseSquare(p)
  local mx,my = getMouseXScaled(), getMouseYScaled()
  local z = (p and p:getZ()) or 0
  local wx = ISCoordConversion.ToWorldX(mx,my,0)
  local wy = ISCoordConversion.ToWorldY(mx,my,0)
  local cell = getCell(); if not cell then return nil end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- Stockpile marker
AFCore._pileSq = AFCore._pileSq or nil
function AFCore.setStockpile(sq)
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then AFCore._pileSq:setHighlighted(false) end
  AFCore._pileSq = sq
  if sq and sq.setHighlighted then
    sq:setHighlighted(true)
    if sq.setHighlightColor then sq:setHighlightColor(0.9,0.8,0.2) end
  end
  AFLOG("PILE","set", sq and (sq:getX()..","..sq:getY()..","..sq:getZ()) or "nil")
end
function AFCore.getStockpile() return AFCore._pileSq end
function AFCore.clearStockpile() if AFCore._pileSq and AFCore._pileSq.setHighlighted then AFCore._pileSq:setHighlighted(false) end AFCore._pileSq=nil end

-- Trees helpers
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
      n = n + 1
    end
  end
  return n
end
