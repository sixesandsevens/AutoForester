-- AutoForester_Core.lua
require "ISCoordConversion"
AFCore = AFCore or {}

-- ---------- Stockpile marker ----------
AFCore._pileSq = AFCore._pileSq or nil

function AFCore.setStockpile(sq)
  if AFCore._pileSq and AFCore._pileSq.setHighlighted then AFCore._pileSq:setHighlighted(false) end
  AFCore._pileSq = sq
  if sq and sq.setHighlighted then sq:setHighlighted(true) end
end

function AFCore.getStockpile() return AFCore._pileSq end

-- tile under mouse at player's Z
function AFCore.getMouseSquare(p)
  local z  = (p and p.getZ and p:getZ()) or 0
  local mx = getMouseXScaled()
  local my = getMouseYScaled()
  local wx = ISCoordConversion.ToWorldX(mx, my, z)
  local wy = ISCoordConversion.ToWorldY(mx, my, z)
  local cell = getCell(); if not cell then return nil end
  return cell:getGridSquare(math.floor(wx), math.floor(wy), z)
end

-- ---------- Rect helpers ----------
function AFCore.normalizeRect(r)
  if not r then return nil end
  -- {sqA,sqB}
  if type(r[1])=="table" and r[1].getX then
    local a,b=r[1],r[2]; if not a or not b then return nil end
    local x1,y1,z=a:getX(),a:getY(),a:getZ() or 0
    local x2,y2=b:getX(),b:getY()
    if x2<x1 then x1,x2=x2,x1 end
    if y2<y1 then y1,y2=y2,y1 end
    return {x1,y1,x2,y2,z}
  end
  local x1=tonumber(r.x1 or r.minX or r[1]); if not x1 then return nil end
  local y1=tonumber(r.y1 or r.minY or r[2]); if not y1 then return nil end
  local x2=tonumber(r.x2 or r.maxX or r[3] or x1)
  local y2=tonumber(r.y2 or r.maxY or r[4] or y1)
  local z =tonumber(r.z  or r[5]) or 0
  if x2<x1 then x1,x2=x2,x1 end
  if y2<y1 then y1,y2=y2,y1 end
  return {x1,y1,x2,y2,z}
end

-- ---------- Tree helpers ----------
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

function AFCore.treesInRect(rect)
  rect = AFCore.normalizeRect(rect)
  if not rect then return {} end
  local x1,y1,x2,y2,z = rect[1],rect[2],rect[3],rect[4],rect[5] or 0
  local out = {}; local cell = getCell(); if not cell then return out end
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
      if ISWorldObjectContextMenu and ISWorldObjectContextMenu.doChopTree then
        ISWorldObjectContextMenu.doChopTree(p, tree)
      elseif ISChopTreeAction then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(p, tree:getSquare()))
        ISTimedActionQueue.add(ISChopTreeAction:new(p, tree))
      else
        -- last resort
        ISWorldObjectContextMenu.onChopTree(p, tree)
      end
      n = n + 1
    end
  end
  return n
end
