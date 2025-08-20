require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISWalkToTimedAction"

AF_HaulWoodToPileAction = ISBaseTimedAction:derive("AF_HaulWoodToPileAction")

function AF_HaulWoodToPileAction:isValid() return true end
function AF_HaulWoodToPileAction:update() end
function AF_HaulWoodToPileAction:start() end
function AF_HaulWoodToPileAction:stop() ISBaseTimedAction.stop(self) end
function AF_HaulWoodToPileAction:perform()
  local p = self.character
  local pileSq = self.pileSq
  if p and pileSq then
    ISTimedActionQueue.add(ISWalkToTimedAction:new(p, pileSq))
    ISTimedActionQueue.add(AF_DropNowAction:new(p))
  end
  ISBaseTimedAction.perform(self)
end

function AF_HaulWoodToPileAction:new(character, pileSq)
  local o = ISBaseTimedAction.new(self, character)
  o.pileSq = pileSq
  o.maxTime = 1
  return o
end

return AF_HaulWoodToPileAction
