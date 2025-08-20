AFInstant = ISBaseTimedAction:derive("AFInstant")

function AFInstant:new(player, fn)
  local o = ISBaseTimedAction.new(self, player)
  o.stopOnWalk = false
  o.stopOnRun = false
  o.maxTime = 1
  o.fn = fn
  return o
end

function AFInstant:perform()
  if self.fn then self.fn() end
  ISBaseTimedAction.perform(self)
end

function AFInstant:update() end
function AFInstant:start() end
function AFInstant:stop() ISBaseTimedAction.stop(self) end

return AFInstant
