# GrowBloxia asset catalog

## Imported source subset

These source files were copied from the licensed `GrowBloxia/Asset` folder in the
connected Google Drive on 2026-10-18. They cover the current farming MVP's tile,
hotbar, and effect needs. They are **source files**, not runtime Roblox image
assets yet.

| Local source file | Drive file ID | Dimensions | Planned use | `AssetManifest` field |
| --- | --- | ---: | --- | --- |
| `source/tiles/tiles_page1.png` | `1F7mPVJlzp-UocfbyHwzFjjIIBcBmCtAo` | 1024×1024 | Tile atlas / future 2D world presentation | `Tiles.page1` |
| `source/tiles/tiles_page2.png` | `1S0uv4g0si8T1E_LbeSSs_8J-JG2Ma6eq` | 1024×1024 | Tile atlas / future 2D world presentation | `Tiles.page2` |
| `source/tiles/seed.png` | `1VuUbSjrP1yhLwybtMwJoOmk5FMm5h6XD` | 256×32 | Seed strip | `Tiles.seedStrip` |
| `source/tiles/water.png` | `1HM0puXtOOQUceEs27X1xgqStQKvHT8IZ` | 256×256 | Water animation sheet | `Tiles.waterSheet` |
| `source/gui/gui_box.png` | `1QbeMUA5euOKLhJwM2PjBPShj9smp-WgV` | 32×32 | Sliceable pixel UI panel frame | `UI.panelFrame` |
| `source/gui/gui_itembox.png` | `1iovuadTMZ2L_lRLPpDhd5vdvb56GyaKv` | 256×256 | Hotbar slot frame atlas | `UI.itemBox` |
| `source/gui/inv_select.png` | `1hfLb8nrP9CGoqMl5qQ9n2V47sU0G3nRa` | 64×64 | Selected-hotbar marker | `UI.inventorySelection` |
| `source/effects/crack.png` | `1PbHT2ZHcOOfQ1Gcov7C3cHvyq5SoOmsy` | 128×32 | Block-break effect strip | `Effects.breakCrack` |
| `source/effects/particles.png` | `1NsYf93mkCGAElg4WeNHpmSzOOoeW-4gK` | 512×512 | Particle sheet | `Effects.particles` |
| `source/effects/tile_grid_overlay.png` | `1Zgt8Mkqj4u1entnZqWWSFAsWr-oKRns5` | 160×32 | Tile-grid overlay | `Effects.tileGridOverlay` |

## Publish for Roblox runtime

Roblox cannot display an image directly from Google Drive or from the local
`assets/` folder in a published experience. For each source file that will be
shown in-game:

1. Open the Roblox Creator Dashboard or **Asset Manager** in Roblox Studio.
2. Bulk-upload the required PNG files from `assets/source/` as **Images**.
3. Copy each resulting asset ID.
4. Paste the ID into the matching field in
   `src/ReplicatedStorage/Shared/AssetManifest.lua`.
5. Run Play Test. Empty fields keep the no-asset procedural fallback active.

The HUD already reads `UI.panelFrame`, `UI.itemBox`, and
`UI.inventorySelection` when those IDs are populated. The remaining mappings are
reserved for the next art pass, where the world tiles and particles are replaced
with atlas-aware 2D/billboard visuals.

## Source-of-truth note

The complete Drive folder also contains banners, clothing, weather, store, and
character assets. They are intentionally not bulk-copied into this first MVP
commit because they are not needed by the current farming loop. They remain
available in Google Drive and can be pulled into the catalog when the related
features are implemented.
