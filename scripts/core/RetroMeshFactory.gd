class_name RetroMeshFactory
extends RefCounted

static func _add_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, col: Color) -> void:
	var n: Vector3 = (v2 - v0).cross(v1 - v0).normalized()
	st.set_normal(n)
	st.set_color(col)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(v1)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(v2)
	
	st.set_normal(n)
	st.set_color(col)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(v2)
	st.set_uv(Vector2(0.0, 1.0))
	st.add_vertex(v3)

static func _add_box(st: SurfaceTool, center: Vector3, size: Vector3, col: Color, top_scale: float = 1.0) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var thx: float = hx * top_scale
	var thz: float = hz * top_scale
	
	var b0 := center + Vector3(-hx, -hy, -hz)
	var b1 := center + Vector3( hx, -hy, -hz)
	var b2 := center + Vector3( hx, -hy,  hz)
	var b3 := center + Vector3(-hx, -hy,  hz)
	
	var t0 := center + Vector3(-thx,  hy, -thz)
	var t1 := center + Vector3( thx,  hy, -thz)
	var t2 := center + Vector3( thx,  hy,  thz)
	var t3 := center + Vector3(-thx,  hy,  thz)
	
	_add_quad(st, t0, t1, t2, t3, col.lightened(0.15)) # Top
	_add_quad(st, b3, b2, b1, b0, col.darkened(0.25))  # Bottom
	_add_quad(st, t0, t3, b3, b0, col.darkened(0.10))  # Left
	_add_quad(st, t2, t1, b1, b2, col.darkened(0.05))  # Right
	_add_quad(st, t1, t0, b0, b1, col)                 # Front (-Z)
	_add_quad(st, t3, t2, b2, b3, col.darkened(0.15))  # Back (+Z)

static func create_kaiju_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var skin := Color(0.16, 0.68, 0.30)
	var belly := Color(0.28, 0.52, 0.26)
	var spine := Color(0.20, 1.00, 0.95)
	
	# Legs & Feet
	_add_box(st, Vector3(-0.55, 0.55, 0.0), Vector3(0.55, 1.1, 0.65), skin.darkened(0.15), 0.85)
	_add_box(st, Vector3( 0.55, 0.55, 0.0), Vector3(0.55, 1.1, 0.65), skin.darkened(0.15), 0.85)
	_add_box(st, Vector3(-0.55, 0.15, -0.35), Vector3(0.6, 0.3, 0.7), skin.darkened(0.25))
	_add_box(st, Vector3( 0.55, 0.15, -0.35), Vector3(0.6, 0.3, 0.7), skin.darkened(0.25))
	
	# Torso & Chest
	_add_box(st, Vector3(0.0, 1.75, 0.0), Vector3(1.55, 1.85, 1.35), skin, 0.75)
	_add_box(st, Vector3(0.0, 1.70, -0.55), Vector3(1.0, 1.5, 0.35), belly, 0.75)
	
	# Arms
	_add_box(st, Vector3(-0.95, 2.0, -0.25), Vector3(0.35, 0.4, 0.85), skin, 0.7)
	_add_box(st, Vector3( 0.95, 2.0, -0.25), Vector3(0.35, 0.4, 0.85), skin, 0.7)
	
	# Head & Snout (faces -Z)
	_add_box(st, Vector3(0.0, 2.95, -0.15), Vector3(0.95, 0.75, 1.0), skin.lightened(0.05), 0.85)
	_add_box(st, Vector3(0.0, 2.80, -0.80), Vector3(0.70, 0.45, 0.65), skin, 0.75)
	
	# Segmented Tail (extends +Z)
	_add_box(st, Vector3(0.0, 0.95, 0.95), Vector3(0.85, 0.75, 1.1), skin.darkened(0.08), 0.75)
	_add_box(st, Vector3(0.0, 0.65, 1.85), Vector3(0.55, 0.50, 1.0), skin.darkened(0.15), 0.65)
	_add_box(st, Vector3(0.0, 0.45, 2.60), Vector3(0.30, 0.30, 0.8), skin.darkened(0.20), 0.50)
	
	# Glowing Atomic Dorsal Spines
	_add_box(st, Vector3(0.0, 2.35, 0.68), Vector3(0.24, 0.65, 0.45), spine, 0.25)
	_add_box(st, Vector3(0.0, 1.65, 0.78), Vector3(0.28, 0.75, 0.55), spine, 0.25)
	_add_box(st, Vector3(0.0, 1.25, 1.25), Vector3(0.20, 0.45, 0.40), spine, 0.25)
	
	st.set_material(material)
	return st.commit()

static func create_enemy_tank_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var hull_col := Color(0.75, 0.22, 0.18)
	var tread_col := Color(0.22, 0.20, 0.20)
	var barrel_col := Color(0.95, 0.55, 0.20)
	
	# Treads
	_add_box(st, Vector3(-0.42, 0.20, 0.0), Vector3(0.24, 0.40, 1.25), tread_col)
	_add_box(st, Vector3( 0.42, 0.20, 0.0), Vector3(0.24, 0.40, 1.25), tread_col)
	# Sloped Main Hull
	_add_box(st, Vector3(0.0, 0.32, 0.0), Vector3(0.72, 0.36, 1.15), hull_col, 0.82)
	# Turret
	_add_box(st, Vector3(0.0, 0.64, 0.08), Vector3(0.52, 0.32, 0.62), hull_col.lightened(0.12), 0.78)
	# Cannon Barrel pointing -Z (forward)
	_add_box(st, Vector3(0.0, 0.66, -0.55), Vector3(0.14, 0.14, 0.80), barrel_col)
	
	st.set_material(material)
	return st.commit()

static func create_bullet_crystal_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var col := Color(0.25, 1.0, 0.92)
	var tip_f := Vector3(0.0, 0.0, -0.55)
	var tip_b := Vector3(0.0, 0.0,  0.55)
	var r: float = 0.22
	var ring: Array[Vector3] = [
		Vector3(0.0,  r, 0.0),
		Vector3(  r, 0.0, 0.0),
		Vector3(0.0, -r, 0.0),
		Vector3( -r, 0.0, 0.0)
	]
	for i in range(4):
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		var n_f: Vector3 = (b - tip_f).cross(a - tip_f).normalized()
		st.set_normal(n_f)
		st.set_color(col.lightened(0.2))
		st.add_vertex(tip_f)
		st.add_vertex(a)
		st.add_vertex(b)
		
		var n_b: Vector3 = (a - tip_b).cross(b - tip_b).normalized()
		st.set_normal(n_b)
		st.set_color(col.darkened(0.15))
		st.add_vertex(tip_b)
		st.add_vertex(b)
		st.add_vertex(a)
		
	st.set_material(material)
	return st.commit()

static func create_debris_chunk_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3.ZERO, Vector3(0.55, 0.42, 0.48), Color(0.52, 0.50, 0.46), 0.62)
	st.set_material(material)
	return st.commit()

static func create_skyscraper_mesh(height: float, base_col: Color, material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var win_col := Color(0.85, 0.92, 1.0)
	var main_h: float = height * 0.78
	var top_h: float = height * 0.22
	
	# Lower Tier (centered around origin Y=0 for GridMap compatibility)
	var bottom_y: float = -height * 0.5
	_add_box(st, Vector3(0.0, bottom_y + main_h * 0.5, 0.0), Vector3(3.2, main_h, 3.2), base_col, 0.96)
	
	# Illuminated Window Bands
	var band_count: int = int(main_h / 1.4)
	for b in range(band_count):
		var by: float = bottom_y + 0.9 + float(b) * 1.35
		_add_box(st, Vector3(0.0, by, 0.0), Vector3(3.26, 0.32, 2.7), win_col)
		_add_box(st, Vector3(0.0, by, 0.0), Vector3(2.7, 0.32, 3.26), win_col)
	
	# Upper Setback Tier & Roof Penthouse
	var top_center_y: float = bottom_y + main_h + top_h * 0.5
	_add_box(st, Vector3(0.0, top_center_y, 0.0), Vector3(2.3, top_h, 2.3), base_col.darkened(0.1), 0.90)
	_add_box(st, Vector3(0.0, height * 0.5 + 0.35, 0.0), Vector3(0.9, 0.7, 0.9), base_col.darkened(0.25), 0.6)
	
	st.set_material(material)
	return st.commit()
