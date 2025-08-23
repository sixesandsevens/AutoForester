AutoForester – small patch (drop‑in)
-----------------------------------
Copy the files in this zip into your local AutoForester mod folder so they end up at:

  Zomboid/mods/AutoForester/media/lua/client/AutoForester_Context.lua
  Zomboid/mods/AutoForester/media/lua/client/AFCore_overrides.lua
  Zomboid/mods/AutoForester/media/lua/client/AF_SelectAdapter_overrides.lua

What this does:
- Defers context‑menu registration until a save is actually loaded (fixes the main‑menu
  “Object tried to call nil” error that prevented the mod from appearing at all).
- Hardens AFCore.getMouseSquare to always use the player’s Z and the scaled mouse coords.
- Normalizes selection rectangles and treats “rect == 0” as “no selection”.

After copying, restart to menu -> load your save. You should see
“AutoForester (patch): …” messages near the top of console when Lua loads.
