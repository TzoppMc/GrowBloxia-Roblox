# Asset drop zone

Upload the game art here before the art-integration pass. Recommended structure:

```text
assets/
  models/       # .rbxm exports: crop, tile, decorative models
  textures/     # .png / .jpg sprite sheets, icons, UI panels
  audio/        # .mp3 / .ogg source audio
  fonts/        # font source/licence if applicable
  references/   # style guides, mockups, placement notes
```

## What to include with each asset

- A descriptive filename, such as `turnip_stage_3.rbxm` or `hotbar_seed.png`.
- A note about where it belongs, if that is not obvious.
- Roblox asset IDs if an asset is already uploaded to Creator Dashboard.

The playable prototype currently uses procedural pixel-style blocks. Once the real
assets are here, map published IDs in `src/ReplicatedStorage/Shared/AssetManifest.lua`
or import the models into Studio and replace the procedural builders in
`WorldService.lua`.
