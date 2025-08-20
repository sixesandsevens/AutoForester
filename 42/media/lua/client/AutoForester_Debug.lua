-- AutoForester_Debug.lua
AFDBG = { on = true }  -- flip to false to silence

local prefix = "[AF] "

function AFLOG(tag, ...)
    if not AFDBG.on then return end
    local msg = table.concat({ ... }, " ")
    print(prefix .. tag .. "> " .. msg)
    if getPlayer() then getPlayer():Say(tag .. ": " .. msg) end
end

function AFSAY(p, msg)
    if not p then return end
    if AFDBG.on then p:Say(msg) end
end
