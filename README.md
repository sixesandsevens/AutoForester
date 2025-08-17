# AutoForester (Build 42)

Auto-chops nearby trees, gathers logs/branches/twigs, and drops them at a stockpile you designate.

## Install (dev)
1. Clone this repo into your `Zomboid/workshop/` folder as `AutoForester/`
2. Launch PZ → **Mods** → enable **AutoForester (B42)** → restart when prompted.

## How to use
- Right-click ground → **Designate Wood Pile Here**
- Right-click ground → **Auto-Chop Nearby Trees**
- Watch console for `[AutoForester]` messages.

## Roadmap
- Mod Options (radius, stamina/weight guard, axe condition threshold)
- Multi stockpiles by item type
- Small sweep around stump to pick scattered drops
- Pause/resume when overweight or exerted

## Build zips from GitHub Actions
Every push builds a `AutoForester_B42.zip` and stores it as a workflow artifact.
Tag a commit like `v0.1.0` to produce a release with the zip attached.
