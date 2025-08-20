-- AF_SelectAdapter.lua
AF_Select = AF_Select or {}

local function hasJB() return type(JB_ASSUtils) == "table" end

-- Pick a single square (used by “Designate wood pile”)
function AF_Select.pickSquare(worldObjects, p, cb)
  if hasJB() and JB_ASSUtils.SelectSingleSquare then
    return JB_ASSUtils.SelectSingleSquare(worldObjects, p, cb)
  end
  -- Fallback: use current mouse square immediately
  local sq = AF_getContextSquare(worldObjects)
  cb(sq, p)
end

-- Pick an area (drag & release). If JB exists, delegate; else fallback tool.
function AF_Select.pickArea(worldObjects, p, cb, kind)
  if hasJB() and JB_ASSUtils.SelectArea then
    return JB_ASSUtils.SelectArea(worldObjects, p, cb, kind)
  end
  require "AF_SelectArea"      -- ensures fallback exists
  AF_SelectArea.start(kind or "generic", function(rect, area) cb(rect, area) end)
end
