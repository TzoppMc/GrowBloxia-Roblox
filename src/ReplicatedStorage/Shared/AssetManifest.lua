-- Runtime asset bindings for GrowBloxia.
--
-- The source PNGs live under /assets/source, but Roblox experiences cannot load
-- images directly from a local folder or Google Drive URL at runtime. Upload the
-- PNGs with Roblox Creator Dashboard / Asset Manager first, then paste either a
-- numeric asset ID or rbxassetid://<ID> below.
--
-- Leaving a value blank is safe: the game keeps its procedural fallback visual.

return {
	UI = {
		-- assets/source/gui/gui_box.png
		panelFrame = "",
		-- assets/source/gui/gui_itembox.png (the blue 64x64 cell at 0,0)
		itemBox = "",
		-- assets/source/gui/inv_select.png
		inventorySelection = "",
	},
	Tiles = {
		-- Source sheets are retained for future 2D tile / billboard integration.
		page1 = "", -- assets/source/tiles/tiles_page1.png
		page2 = "", -- assets/source/tiles/tiles_page2.png
		seedStrip = "", -- assets/source/tiles/seed.png
		waterSheet = "", -- assets/source/tiles/water.png
	},
	Effects = {
		breakCrack = "", -- assets/source/effects/crack.png
		particles = "", -- assets/source/effects/particles.png
		tileGridOverlay = "", -- assets/source/effects/tile_grid_overlay.png
	},
	Audio = {
		plant = "",
		harvest = "",
		water = "",
	},
}
