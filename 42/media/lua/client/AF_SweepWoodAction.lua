require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISPickupWorldItemAction"

AF_SweepWoodAction = ISBaseTimedAction:derive("AF_SweepWoodAction")

function AF_SweepWoodAction:isValid() return true end
function AF_SweepWoodAction:update() end
function AF_SweepWoodAction:start() end
function AF_SweepWoodAction:stop() ISBaseTimedAction.stop(self) end
function AF_SweepWoodAction:perform()
  local p = self.character
  local rect = self.areaRect
  if p and rect and AutoChopTask and AutoChopTask.isWood then
    local cell = getCell()
    for x = rect[1], rect[3] do
      for y = rect[2], rect[4] do
        local sq = cell:getGridSquare(x, y, rect[5] or 0)
        if sq then
          local wios = sq:getWorldObjects()
          if wios then
            for i = 0, wios:size()-1 do
              local wio = wios:get(i)
              local it = wio and wio:getItem()
              if it and AutoChopTask.isWood(it) then
                ISTimedActionQueue.add(ISPickupWorldItemAction:new(p, it, x, y, sq:getZ()))
              end
            end
          end
        end
      end
    end
  end
  ISBaseTimedAction.perform(self)
end

function AF_SweepWoodAction:new(character, areaRect)
  local o = ISBaseTimedAction.new(self, character)
  o.areaRect = areaRect
  o.maxTime = 1
  return o
end

return AF_SweepWoodAction
