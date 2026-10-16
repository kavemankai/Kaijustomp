class_name RetroTextureAtlas
extends RefCounted

static var _cached_atlas: ImageTexture

static func get_atlas_texture() -> ImageTexture:
	if _cached_atlas != null:
		return _cached_atlas

	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)

	# Q0 (Top-Left 0..127, 0..127): Reptile Scales
	for y in range(128):
		for x in range(128):
			var row: int = y / 8
			var offset_x: int = (x + (row & 1) * 4) % 8
			var offset_y: int = y % 8
			var border: bool = (offset_x == 0 or offset_y == 0)
			var highlight: bool = (offset_x == 2 and offset_y == 2)
			var v: float = 0.58 if border else (0.95 if highlight else 0.80)
			img.set_pixel(x, y, Color(v, v, v, 1.0))

	# Q1 (Top-Right 128..255, 0..127): Skyscraper Concrete & Lit Window Grid
	for y in range(128):
		for x in range(128, 256):
			var lx: int = x - 128
			var wx: int = lx % 16
			var wy: int = y % 16
			var is_frame: bool = (wx < 3 or wx > 13 or wy < 3 or wy > 13)
			if is_frame:
				var seam: float = 0.55 if (lx % 16 == 0 or y % 16 == 0) else 0.72
				img.set_pixel(x, y, Color(seam, seam, seam, 1.0))
			else:
				# Deterministic pseudo-random lit vs dark office windows
				var cell_hash: int = ((lx / 16) * 73 + (y / 16) * 37) % 5
				var win_v: float = 1.0 if cell_hash != 0 else 0.35
				img.set_pixel(x, y, Color(win_v, win_v, win_v, 1.0))

	# Q2 (Bottom-Left 0..127, 128..255): Military Armor Plating, Rivets & Treads
	for y in range(128, 256):
		for x in range(128):
			var ly: int = y - 128
			var px: int = x % 32
			var py: int = ly % 32
			var panel_edge: bool = (px == 0 or py == 0 or px == 31 or py == 31)
			var rivet: bool = ((px == 3 or px == 28) and (py == 3 or py == 28))
			var tread_rib: bool = (x > 96 and (ly % 6 < 2))
			var v: float = 0.45 if (panel_edge or tread_rib) else (1.0 if rivet else 0.78)
			img.set_pixel(x, y, Color(v, v, v, 1.0))

	# Q3 (Bottom-Right 128..255, 128..255): Plasma Lattice & Rubble Cracks
	for y in range(128, 256):
		for x in range(128, 256):
			var lx: int = x - 128
			var ly: int = y - 128
			var grid_line: bool = ((lx + ly) % 12 < 2) or ((lx - ly + 128) % 12 < 2)
			var v: float = 1.0 if grid_line else 0.68
			img.set_pixel(x, y, Color(v, v, v, 1.0))

	_cached_atlas = ImageTexture.create_from_image(img)
	return _cached_atlas
