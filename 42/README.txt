# AutoForester (Build 42)

This mod lets you:
- **Start AutoForester**: two-click select an area, then automatically chop trees, sweep ground clutter, and haul logs.
- **Designate Wood Pile Here**: where logs get hauled/dropped.

Optional: If you also enable **JB_ASSUtils**, AutoForester will use its area-selection if an active selection exists; otherwise the built-in two-click picker is used.

### How to use
1) Right‑click ground → **Designate Wood Pile Here** on the target drop tile.
2) Right‑click ground → **Start AutoForester** → pick two corners of the area.
3) The mod will queue: walk to each tree → chop → pick up logs → walk to wood pile → drop logs. It will also sweep grass/bushes on the way.

### Notes
- The player must have an axe (Axe or Stone Axe) to chop trees.
- Hauling uses inventory weight rules; actions will repeat until the area is handled.
- You can cancel at any time by clearing the timed action queue.

### Troubleshooting
- If **Start AutoForester** is missing, ensure the mod is enabled (and loaded after UI overhaul mods).  
- If JB selection exists but the mod says "No area", clear the JB selection and try again.  
- Check the console for messages prefixed with `[AF]`.

