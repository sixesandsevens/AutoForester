AF_DEBUG = true  -- flip to false when stable

local function tsq(sq)
  if not sq then return "nil" end
  return string.format("(%d,%d,%d)", sq:getX(), sq:getY(), sq:getZ())
end

function AFLOG(...)     if AF_DEBUG then print("[AF]", ...) end end
function AFSAY(p, msg)  if AF_DEBUG and p then p:Say(tostring(msg)) end end

function AF_DUMP(where, t)
  if not AF_DEBUG then return end
  t = t or AutoChopTask or {}
  local p = t.player
  AFLOG("DUMP@"..tostring(where),
        "phase="..tostring(t.phase),
        "player="..tostring(p),
        "chopRect="..tostring(t.chopRect),
        "gatherRect="..tostring(t.gatherRect),
        "queue="..((t.queue and #t.queue) or 0))
end

function AF_LIST_SQ_OBJS(sq, tag)
  if not AF_DEBUG then return end
  if not sq then AFLOG("SQ=nil @", tag); return end
  local objs = sq:getObjects()
  AFLOG("SQ", tsq(sq), "objs=", objs and objs:size() or 0, "@", tag or "?")
  if objs then
    for i=0, objs:size()-1 do
      local o = objs:get(i)
      local spr = o.getSprite and o:getSprite() or nil
      local name = spr and spr:getName() or "NO_SPRITE"
      AFLOG("  •", tostring(o), "sprite=", name)
    end
  end
end
