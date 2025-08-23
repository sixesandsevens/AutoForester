-- AF_Instant.lua
AFInstant = ISBaseTimedAction:derive("AFInstant")
function AFInstant:isValid() return true end
function AFInstant:start() end
function AFInstant:update() end
function AFInstant:stop() end
function AFInstant:perform() if self.cb then self.cb() end ISBaseTimedAction.perform(self) end
function AFInstant:new(p, cb) local o = {} setmetatable(o, self); self.__index = self; o.character=p; o.cb=cb; o.maxTime=1; return o end
