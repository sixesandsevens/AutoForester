require "TimedActions/ISBaseTimedAction"

AF_DropNowAction = ISBaseTimedAction:derive("AF_DropNowAction")

function AF_DropNowAction:isValid() return true end
function AF_DropNowAction:update() end
function AF_DropNowAction:start() end
function AF_DropNowAction:stop() ISBaseTimedAction.stop(self) end
function AF_DropNowAction:perform()
  if AutoChopTask and AutoChopTask.dropWoodNow then
    AutoChopTask.dropWoodNow(self.character)
  end
  ISBaseTimedAction.perform(self)
end

function AF_DropNowAction:new(character)
  local o = ISBaseTimedAction.new(self, character)
  o.maxTime = 1
  return o
end

return AF_DropNowAction
