-- media/lua/client/AutoForester_Core.lua
require "AutoForester_Debug"

AFCore = AFCore or {}

-- ---------- Stockpile marker ----------
AFCore._pileSq = AFCore._pileSq or nil

function AFCore.setStockpile(sq)
  -- Un-highlight previous
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then
    AFCore._pileSq:setHighlighted(false)
  end
  AFCore._pileSq = sq
  if sq and sq.setHighlighted then
    sq:setHighlighted(true) -- Avoid setHighlightColor; not reliable in B42
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

-- ---------- Trees & chopping ----------
local function _squareHasTree(sq)
  if not sq then return false end
  local objs = sq:getObjects()
  for i=0,(objs and objs:size() or 0)-1 do
    if instanceof(objs:get(i), "IsoTree") then return true end
  end
  return false
end
AFCore.squareHasTree = _squareHasTree

function AFCore.getTreeFromSquare(sq)
  if not sq then return nil end
  local objs = sq:getObjects()
  for i=0,(objs and objs:size() or 0)-1 do
    local o = objs:get(i)
    if instanceof(o, "IsoTree") then return o end
  end
  return nil
end

-- Normalize rect to numbers
function AFCore.normalizeRect(rect)
  if not rect then return nil end
  local x1 = math.floor(tonumber(rect[1] or rect.x1 or 0) or 0)
  local y1 = math.floor(tonumber(rect[2] or rect.y1 or 0) or 0)
  local x2 = math.floor(tonumber(rect[3] or rect.x2 or x1) or x1)
  local y2 = math.floor(tonumber(rect[4] or rect.y2 or y1) or y1)
  local z  = math.floor(tonumber(rect[5] or rect.z or 0) or 0)
  if x2 < x1 then x1,x2 = x2,x1 end
  if y2 < y1 then y1,y2 = y2,y1 end
  return {x1,y1,x2,y2,z}
end

function AFCore.treesInRect(rect)
  rect = AFCore.normalizeRect(rect)
  if not rect then return {} end
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

local function _queueChopAction(p, tree)
  if ISChopTreeAction then
    ISTimedActionQueue.add(ISWalkToTimedAction:new(p, tree:getSquare()))
    ISTimedActionQueue.add(ISChopTreeAction:new(p, tree))
  else
    ISWorldObjectContextMenu.onChopTree(p, tree)
  end
end

function AFCore.queueChops(p, squares)
  local n = 0
  for _,sq in ipairs(squares or {}) do
    local tree = AFCore.getTreeFromSquare(sq)
    if tree then
      _queueChopAction(p, tree)
      AFLOG("CHOP","queued",sq:getX(),sq:getY(),sq:getZ())
      n = n + 1
    end
  end
  return n
end
