-- AF_SelectAdapter.lua
AF_Select = AF_Select or {}

local function say(playerObj, msg)
  if playerObj and playerObj.Say then playerObj:Say(msg) end
end

local function probeJB()
  local jb = rawget(_G, "JB") or rawget(_G, "JB_ASSUtils") or rawget(_G, "ASS") or nil
  if jb and type(jb) == "table" then
    if jb.AreaSelect and (jb.AreaSelect.pick or jb.AreaSelect.Pick or jb.AreaSelect.Start) then
      return "JB.AreaSelect", jb.AreaSelect
    end
    if jb.Select and (jb.Select.pick or jb.Select.Pick or jb.Select.Start) then
      return "JB.Select", jb.Select
    end
  end
  local pick = rawget(_G, "ASS_PickArea") or rawget(_G, "JB_PickArea")
  if pick and type(pick) == "function" then
    return "FUNC", { pick = pick }
  end
  return nil, nil
end

function AF_Select.pickArea(worldObjects, playerObj, cb, tag)
  local kind, mod = probeJB()
  if kind and mod then
    local picker = mod.pick or mod.Pick or mod.Start
    if type(picker) == "function" then
      local ok, err = pcall(function()
        picker(worldObjects, playerObj, function(rect, area)
          local r = rect
          if r and r.x1 then r = { r.x1, r.y1, r.x2 or r.x1, r.y2 or r.y1 } end
          cb(r, area)
        end, tag)
      end)
      if not ok then
        say(playerObj, "AutoForester: selection lib error.")
        print("AF_SelectAdapter: picker failed: "..tostring(err))
        cb(nil, nil)
      end
      return
    end
  end
  say(playerObj, "AutoForester: JB_ASSUtils selection not found.")
  print("AF_SelectAdapter: JB selection library not found; returning nil area.")
  cb(nil, nil)
end

return AF_Select
