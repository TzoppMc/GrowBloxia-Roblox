# GrowBloxia — Roblox 2D block-farming MVP

A playable **2D side-view block-farming** foundation for Roblox with pixel-style
presentation. The world is a server-owned X/Y tile grid viewed through a locked
side camera, so it supports platform movement, break/place blocks, and farming.
It is an original foundation for your own game and branding.

## What is already playable

- 72×28 server-generated **side-view tile world** with sky, ground layers, and a
  starter farm.
- Locked X/Y character plane, side camera, A/D movement, jumping, and touch buttons.
- Server-authoritative tile interaction with distance/rate validation.
- Break grass, dirt, and stone blocks to receive their block item drops.
- Place supported dirt/grass/stone blocks into adjacent empty cells.
- Till grass or dirt with a hoe to make farmland.
- Plant turnip and carrot seeds, water them, wait for growth stages, and harvest.
- Session inventory + five-slot hotbar, contextual target outline, and pixel HUD.
- Procedural fallback tiles/crops that keep the game playable before final Roblox
  image IDs are published.

## Controls

| Input | Action |
| --- | --- |
| `A` / `D` or arrow keys | Move left / right |
| `Space` or ↑ | Jump |
| `1`–`7` | Select a hotbar item |
| Left click / tap | Use selected item, plant, water, harvest, or place a block |
| Right click | Break a block or pull up a crop |
| HUD action buttons | Touch-friendly use / break alternatives |

When a block is selected, click near a tile edge to place it in the adjacent empty
cell. The server rejects floating blocks and out-of-range placement.

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
    GameConfig.lua          # 2D grid geometry, item/crop/world balancing
    AssetManifest.lua       # published Roblox asset IDs to replace placeholders
    AssetResolver.lua       # safe runtime Roblox asset-ID normalization
  ServerScriptService/
    Bootstrap.server.lua    # remotes, world setup, lighting, character spawn
    Services/
      WorldService.lua      # authoritative side-view tile grid and visuals
      InventoryService.lua
      FarmService.lua       # break/place, farming, growth, harvest validation
  StarterPlayer/StarterPlayerScripts/
    GrowBloxiaClient.client.lua    # HUD, hotbar, tile interaction
    SideViewController.client.lua  # side camera, 2D plane, movement controls
assets/
  source/                   # imported source sprites
  ASSET_CATALOG.md          # Drive origin and Roblox runtime mappings
```

## Bringing in your assets

A core source subset from the connected `GrowBloxia/Asset` Google Drive folder is
already stored under `assets/source/`. See [`assets/ASSET_CATALOG.md`](assets/ASSET_CATALOG.md)
for the source files and their intended mappings.

Roblox cannot render a Google Drive URL or local PNG directly in a published game.
Upload the source images through Creator Dashboard / Studio Asset Manager and enter
the resulting IDs in `src/ReplicatedStorage/Shared/AssetManifest.lua`. The HUD
will automatically use the panel, hotbar-slot, and selection frame assets once
those IDs are present; blank IDs safely retain the built-in fallback visuals.

For the world atlas, the next art pass will use `Tiles.page1` / `Tiles.page2` with
`ImageRectOffset` and `ImageRectSize` on side-view tiles. Gameplay is deliberately
separate from art: crop speed/yield lives in `GameConfig.lua`, while
`WorldService:RefreshPlantVisual` is the visual replacement point for crops.

## Current MVP boundary

Inventory lasts for the active server session. Persistent DataStore profiles,
trading, shops, crafting, multiplayer world ownership/locking, player sprite
customization, atlas-specific tile art, moderation, and sound/particle animation
are intentionally left for the next development passes.
