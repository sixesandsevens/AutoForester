-- AF_Instant.lua
local AFInstant = ISBaseTimedAction:derive("AFInstant")
function AFInstant:isValid() return true end
function AFInstant:start() end
function AFInstant:update() end
function AFInstant:stop() ISBaseTimedAction.stop(self) end
function AFInstant:perform() if self.func then self.func() end; ISBaseTimedAction.perform(self) end
function AFInstant:new(player, func) local o = ISBaseTimedAction.new(self, player); o.maxTime = 1; o.func = func; return o end
return AFInstant
