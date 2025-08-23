-- AutoForester_Core.lua
require "AutoForester_Debug"
AFCore = AFCore or {}

-- Stockpile marker
AFCore._pileSq = AFCore._pileSq or nil
function AFCore.setStockpile(sq)
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then AFCore._pileSq:setHighlighted(false) end
  AFCore._pileSq = sq
  if sq and sq.setHighlighted then sq:setHighlighted(true); if sq.setHighlightColor then sq:setHighlightColor(0.9,0.8,0.2) end end
  AFLOG("PILE","set", sq and sq:getX(), sq and sq:getY(), sq and sq:getZ())
end
function AFCore.getStockpile() return AFCore._pileSq end

-- Tree helpers
function AFCore.squareHasTree(sq)
  if not sq then return false end
  local objs = sq:getObjects(); local n = objs and objs:size() or 0
  for i=0,n-1 do if instanceof(objs:get(i), "IsoTree") then return true end end
  return false
end
function AFCore.getTreeFromSquare(sq)
  if not sq then return nil end
  local objs = sq:getObjects(); local n = objs and objs:size() or 0
  for i=0,n-1 do local o=objs:get(i); if instanceof(o,"IsoTree") then return o end end
  return nil
end

function AFCore.treesInRect(rect)
  if not rect then return {} end
  local x1=tonumber(rect[1]); local y1=tonumber(rect[2]); local x2=tonumber(rect[3]); local y2=tonumber(rect[4]); local z=tonumber(rect[5]) or 0
  if not (x1 and y1 and x2 and y2) then return {} end
  local out = {}; local cell = getCell(); if not cell then return out end
  for y=y1,y2 do for x=x1,x2 do local sq = cell:getGridSquare(x,y,z); if AFCore.squareHasTree(sq) then table.insert(out, sq) end end end
  return out
end

-- Chop a single tree without cursor.
local function enqueueChopAction(p, tree)
  if ISWorldObjectContextMenu and ISWorldObjectContextMenu.doChopTree then
    ISWorldObjectContextMenu.doChopTree(p, tree); return true
  end
  if ISChopTreeAction then
    local act; local ok = pcall(function() act = ISChopTreeAction:new(p, tree) end)
    if not ok or not act then ok = pcall(function() act = ISChopTreeAction:new(p, tree, 0) end) end
    if act then ISTimedActionQueue.add(act); return true end
  end
  return false
end

function AFCore.queueChops(p, squares)
  local n = 0
  for _,sq in ipairs(squares or {}) do
    local tree = AFCore.getTreeFromSquare(sq)
    if tree then
      ISTimedActionQueue.add(ISWalkToTimedAction:new(p, sq))
      if enqueueChopAction(p, tree) then
        AFLOG("CHOP","queued",sq:getX(),sq:getY(),sq:getZ()); n = n + 1
      else
        AFLOG("CHOP","no action",sq:getX(),sq:getY(),sq:getZ()); p:Say("Can't chop here.")
      end
    end
  end
  return n
end
