# GrowBloxia asset workspace

## Current status

The source subset needed by the first farming MVP has been copied from the
licensed Google Drive folder into `assets/source/`:

```text
assets/
  source/
    tiles/      # source tile, seed, and water sprite sheets
    gui/        # panel, item-slot, and selection frames
    effects/    # break/particle/grid-overlay sheets
  ASSET_CATALOG.md
```

See [`ASSET_CATALOG.md`](ASSET_CATALOG.md) for the Drive source IDs, dimensions,
intended game use, and exact `AssetManifest.lua` mapping fields.

## Important: source files vs. Roblox runtime assets

The PNG files in this directory are for version control and upload preparation.
A published Roblox game cannot reference a Google Drive URL or a local PNG path
directly. Upload a source PNG through Creator Dashboard / Studio Asset Manager,
then place the generated Roblox asset ID in:

```text
src/ReplicatedStorage/Shared/AssetManifest.lua
```

Blank values are intentional and keep the procedural fallback active. The current
HUD already automatically skins its panels and hotbar once the three UI IDs are
filled:

- `UI.panelFrame`
- `UI.itemBox`
- `UI.inventorySelection`

## Adding more assets later

Use descriptive names and keep raw content grouped by purpose:

```text
assets/
  source/
    models/       # .rbxm exports: crop, tile, decorative models
    textures/     # .png / .jpg sprite sheets, icons, UI panels
    audio/        # .mp3 / .ogg source audio
    fonts/        # font source/licence if applicable
    references/   # style guides, mockups, placement notes
```

When we implement shops, weather, character cosmetics, or effects, I can pull the
matching source files from the same Google Drive hierarchy and extend the catalog.
