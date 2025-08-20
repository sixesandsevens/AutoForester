-- AutoForester_Core.lua
require "AutoForester_Debug"

-- Optional JB_ASSUtils soft dependency
local ok, lib = pcall(require, "JB_ASSUtils")
AF_HasASS = ok and type(lib) == "table"
JB_ASSUtils = ok and lib or nil

AFCore = AFCore or {}

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
  return res
end

function AFCore.queueChops(player, squares)
  local n=0
  for _,sq in ipairs(squares) do
    local tree = AFCore.getTreeFromSquare(sq)
    if tree then
      ISTimedActionQueue.add(ISWalkToTimedAction:new(player, sq))
      ISWorldObjectContextMenu.doChopTree(player, tree)
      n = n + 1
    end
  end
  return n
end

function AFCore.dropTreeLootNow(player)
  local inv = player:getInventory()
  local types = { "Base.Log", "Base.TreeBranch", "Base.LargeBranch", "Base.Twigs", "Base.Sapling" }
  for _,full in ipairs(types) do
    local items = inv:getItemsFromFullType(full)
    if items then
      for i=0, items:size()-1 do
        ISTimedActionQueue.add(ISDropItemAction:new(player, items:get(i)))
      end
    end
  end
end

function AFCore.setStockpile(sq)
  AFCore.pileSq = sq
  if sq and sq.setHighlighted then
    sq:setHighlighted(true); if sq.setHighlightColor then sq:setHighlightColor(0.95,0.85,0.2) end
  end
end

function AFCore.getStockpile() return AFCore.pileSq end
