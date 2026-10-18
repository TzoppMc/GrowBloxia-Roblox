# GrowBloxia — Roblox block-farming MVP

A playable, original Roblox **block-farming** foundation with a pixel-inspired UI.
It is designed as a genre-inspired starting point for your own game, not as a copy
of Growtopia branding, art, maps, or proprietary gameplay content.

## What is already playable

- Server-generated grid world with grass and starter farmland.
- Server-authoritative click/tap interaction with distance and rate validation.
- Till grass with a hoe or place a dirt block to make a farm plot.
- Plant turnip and carrot seeds.
- Crop growth stages, water boost, mature-crop harvesting, and seed returns.
- Session inventory + five-slot hotbar.
- Pixel-styled HUD, toast notifications, target outline, keyboard/mouse/touch controls.
- Crop/tile placeholders generated entirely from Roblox Parts, so the prototype runs
  before final art is imported.

## Controls

| Input | Action |
| --- | --- |
| `1`–`5` | Select a hotbar item |
| Left click / tap | Use selected item, plant, water, or harvest |
| Right click | Pull up a crop or return an empty farm plot to grass |
| HUD action buttons | Touch-friendly use / break alternatives |

## Open the project in Roblox Studio

This repository uses [Rojo](https://rojo.space/) layout conventions.

1. Install the Rojo CLI and Roblox Studio plugin.
2. From the repository root, run:
   ```bash
   rojo serve default.project.json
   ```
3. In a new Roblox Studio place, use the Rojo plugin to connect to the server.
4. Press **Play** (or **Start** with multiple players) to test the loop.
5. Publish the place under your own Roblox experience when ready.

You can also create an editable place file with:

```bash
rojo build default.project.json -o GrowBloxia.rbxlx
```

## Project structure

```text
src/
  ReplicatedStorage/Shared/
    GameConfig.lua       # item, crop, world, and balancing values
    AssetManifest.lua    # published Roblox asset IDs to replace placeholders
  ServerScriptService/
    Bootstrap.server.lua # remotes, world setup, lighting, character spawn
    Services/
      WorldService.lua   # authoritative grid and procedural world visuals
      InventoryService.lua
      FarmService.lua    # validation, crop growth, planting, watering, harvest
  StarterPlayer/StarterPlayerScripts/
    GrowBloxiaClient.client.lua # HUD, hotbar, desktop/mobile input
assets/
  README.md              # where to put the supplied source assets
```

## Bringing in your assets

Put exports, textures, UI art, audio, and placement notes under `assets/` using the
structure in [`assets/README.md`](assets/README.md). Then either:

- publish them through Creator Dashboard and enter their IDs in
  `src/ReplicatedStorage/Shared/AssetManifest.lua`, or
- import `.rbxm` models in Studio and swap the generated visuals in
  `WorldService.lua`.

The gameplay data is deliberately separate from the visuals. For example, crop
speed/yield lives in `GameConfig.lua`, while `WorldService:RefreshPlantVisual` is
the single place that will be replaced with your crop models.

## Current MVP boundary

Inventory lasts for the active server session. Persistent DataStore profiles,
trading, shops, crafting, multiplayer world ownership/locking, moderation, and
asset-specific animation are intentionally left for the next development pass.
