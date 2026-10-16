class_name RetroMeshFactory
extends RefCounted

const UV_Q0_SCALES := Rect2(0.02, 0.02, 0.46, 0.46)
const UV_Q1_WINDOWS := Rect2(0.52, 0.02, 0.46, 0.46)
const UV_Q2_ARMOR := Rect2(0.02, 0.52, 0.46, 0.46)
const UV_Q3_PLASMA := Rect2(0.52, 0.52, 0.46, 0.46)

static func _add_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, col: Color, uv_rect: Rect2 = UV_Q2_ARMOR) -> void:
	var n: Vector3 = (v2 - v0).cross(v1 - v0).normalized()
	var u0: float = uv_rect.position.x
	var v_0: float = uv_rect.position.y
	var u1: float = uv_rect.end.x
	var v_1: float = uv_rect.end.y
	
	st.set_normal(n)
	st.set_color(col)
	st.set_uv(Vector2(u0, v_0))
	st.add_vertex(v0)
	st.set_uv(Vector2(u1, v_0))
	st.add_vertex(v1)
	st.set_uv(Vector2(u1, v_1))
	st.add_vertex(v2)
	
	st.set_normal(n)
	st.set_color(col)
	st.set_uv(Vector2(u0, v_0))
	st.add_vertex(v0)
	st.set_uv(Vector2(u1, v_1))
	st.add_vertex(v2)
	st.set_uv(Vector2(u0, v_1))
	st.add_vertex(v3)

static func _add_box(st: SurfaceTool, center: Vector3, size: Vector3, col: Color, top_scale: float = 1.0, uv_rect: Rect2 = UV_Q2_ARMOR) -> void:
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
	
	_add_quad(st, t0, t1, t2, t3, col.lightened(0.15), uv_rect)
	_add_quad(st, b3, b2, b1, b0, col.darkened(0.25), uv_rect)
	_add_quad(st, t0, t3, b3, b0, col.darkened(0.10), uv_rect)
	_add_quad(st, t2, t1, b1, b2, col.darkened(0.05), uv_rect)
	_add_quad(st, t1, t0, b0, b1, col, uv_rect)
	_add_quad(st, t3, t2, b2, b3, col.darkened(0.15), uv_rect)

static func create_kaiju_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var skin := Color(0.18, 0.72, 0.34)
	var belly := Color(0.32, 0.58, 0.28)
	var spine := Color(0.20, 1.00, 0.95)
	
	# Legs & Clawed Feet
	_add_box(st, Vector3(-0.55, 0.55, 0.0), Vector3(0.55, 1.1, 0.65), skin.darkened(0.15), 0.85, UV_Q0_SCALES)
	_add_box(st, Vector3( 0.55, 0.55, 0.0), Vector3(0.55, 1.1, 0.65), skin.darkened(0.15), 0.85, UV_Q0_SCALES)
	_add_box(st, Vector3(-0.55, 0.15, -0.35), Vector3(0.6, 0.3, 0.7), skin.darkened(0.25), 0.9, UV_Q0_SCALES)
	_add_box(st, Vector3( 0.55, 0.15, -0.35), Vector3(0.6, 0.3, 0.7), skin.darkened(0.25), 0.9, UV_Q0_SCALES)
	
	# Torso & Armored Chest
	_add_box(st, Vector3(0.0, 1.75, 0.0), Vector3(1.55, 1.85, 1.35), skin, 0.75, UV_Q0_SCALES)
	_add_box(st, Vector3(0.0, 1.70, -0.55), Vector3(1.0, 1.5, 0.35), belly, 0.75, UV_Q0_SCALES)
	
	# Arms
	_add_box(st, Vector3(-0.95, 2.0, -0.25), Vector3(0.35, 0.4, 0.85), skin, 0.7, UV_Q0_SCALES)
	_add_box(st, Vector3( 0.95, 2.0, -0.25), Vector3(0.35, 0.4, 0.85), skin, 0.7, UV_Q0_SCALES)
	
	# Head, Snout & Lower Jaw
	_add_box(st, Vector3(0.0, 2.95, -0.15), Vector3(0.95, 0.75, 1.0), skin.lightened(0.05), 0.85, UV_Q0_SCALES)
	_add_box(st, Vector3(0.0, 2.90, -0.80), Vector3(0.70, 0.38, 0.65), skin, 0.75, UV_Q0_SCALES)
	_add_box(st, Vector3(0.0, 2.60, -0.75), Vector3(0.62, 0.20, 0.60), belly, 0.85, UV_Q0_SCALES)
	
	# 3-Segment Tail
	_add_box(st, Vector3(0.0, 0.95, 0.95), Vector3(0.85, 0.75, 1.1), skin.darkened(0.08), 0.75, UV_Q0_SCALES)
	_add_box(st, Vector3(0.0, 0.65, 1.85), Vector3(0.55, 0.50, 1.0), skin.darkened(0.15), 0.65, UV_Q0_SCALES)
	_add_box(st, Vector3(0.0, 0.45, 2.60), Vector3(0.30, 0.30, 0.8), skin.darkened(0.20), 0.50, UV_Q0_SCALES)
	
	# Glowing Atomic Dorsal Plates
	_add_box(st, Vector3(0.0, 2.35, 0.68), Vector3(0.24, 0.65, 0.45), spine, 0.25, UV_Q3_PLASMA)
	_add_box(st, Vector3(0.0, 1.65, 0.78), Vector3(0.28, 0.75, 0.55), spine, 0.25, UV_Q3_PLASMA)
	_add_box(st, Vector3(0.0, 1.25, 1.25), Vector3(0.20, 0.45, 0.40), spine, 0.25, UV_Q3_PLASMA)
	
	st.set_material(material)
	return st.commit()

static func create_enemy_tank_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var hull_col := Color(0.78, 0.26, 0.20)
	var tread_col := Color(0.25, 0.23, 0.23)
	var barrel_col := Color(0.95, 0.60, 0.22)
	
	_add_box(st, Vector3(-0.42, 0.20, 0.0), Vector3(0.24, 0.40, 1.25), tread_col, 1.0, UV_Q2_ARMOR)
	_add_box(st, Vector3( 0.42, 0.20, 0.0), Vector3(0.24, 0.40, 1.25), tread_col, 1.0, UV_Q2_ARMOR)
	_add_box(st, Vector3(0.0, 0.32, 0.0), Vector3(0.72, 0.36, 1.15), hull_col, 0.82, UV_Q2_ARMOR)
	_add_box(st, Vector3(0.0, 0.64, 0.08), Vector3(0.52, 0.32, 0.62), hull_col.lightened(0.12), 0.78, UV_Q2_ARMOR)
	_add_box(st, Vector3(0.0, 0.66, -0.55), Vector3(0.14, 0.14, 0.80), barrel_col, 1.0, UV_Q2_ARMOR)
	
	st.set_material(material)
	return st.commit()

static func create_enemy_mech_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var steel := Color(0.35, 0.55, 0.85)
	var visor := Color(1.0, 0.85, 0.20)
	var pods := Color(0.85, 0.25, 0.25)
	
	# Bipedal Legs
	_add_box(st, Vector3(-0.28, 0.35, 0.0), Vector3(0.22, 0.70, 0.28), steel.darkened(0.2), 0.85, UV_Q2_ARMOR)
	_add_box(st, Vector3( 0.28, 0.35, 0.0), Vector3(0.22, 0.70, 0.28), steel.darkened(0.2), 0.85, UV_Q2_ARMOR)
	# Mech Torso & Visor
	_add_box(st, Vector3(0.0, 0.95, 0.0), Vector3(0.68, 0.60, 0.55), steel, 0.85, UV_Q2_ARMOR)
	_add_box(st, Vector3(0.0, 1.02, -0.28), Vector3(0.48, 0.22, 0.12), visor, 1.0, UV_Q3_PLASMA)
	# Twin Shoulder Missile Pods
	_add_box(st, Vector3(-0.48, 1.18, 0.05), Vector3(0.26, 0.38, 0.45), pods, 0.9, UV_Q2_ARMOR)
	_add_box(st, Vector3( 0.48, 1.18, 0.05), Vector3(0.26, 0.38, 0.45), pods, 0.9, UV_Q2_ARMOR)
	
	st.set_material(material)
	return st.commit()

static func create_enemy_heli_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var body_col := Color(0.28, 0.36, 0.28)
	var glass_col := Color(0.95, 0.75, 0.20)
	var rotor_col := Color(0.18, 0.18, 0.20)
	
	# Fuselage & Cockpit Nose (-Z forward)
	_add_box(st, Vector3(0.0, 0.0, 0.0), Vector3(0.58, 0.45, 1.05), body_col, 0.80, UV_Q2_ARMOR)
	_add_box(st, Vector3(0.0, -0.04, -0.62), Vector3(0.42, 0.30, 0.45), glass_col, 0.65, UV_Q3_PLASMA)
	# Stub Wings
	_add_box(st, Vector3(0.0, 0.0, 0.05), Vector3(1.35, 0.10, 0.32), body_col.lightened(0.1), 0.90, UV_Q2_ARMOR)
	# Tail Boom & Vertical Fin
	_add_box(st, Vector3(0.0, 0.06, 0.85), Vector3(0.18, 0.20, 0.85), body_col.darkened(0.15), 0.60, UV_Q2_ARMOR)
	_add_box(st, Vector3(0.0, 0.26, 1.20), Vector3(0.08, 0.38, 0.28), body_col, 0.70, UV_Q2_ARMOR)
	# Cross Rotor Blades
	_add_box(st, Vector3(0.0, 0.32, 0.0), Vector3(1.65, 0.04, 0.12), rotor_col, 1.0, UV_Q2_ARMOR)
	_add_box(st, Vector3(0.0, 0.32, 0.0), Vector3(0.12, 0.04, 1.65), rotor_col, 1.0, UV_Q2_ARMOR)
	
	st.set_material(material)
	return st.commit()

static func create_pickup_xp_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var col := Color(0.35, 1.0, 0.45)
	_add_box(st, Vector3(0.0, 0.35, 0.0), Vector3(0.38, 0.55, 0.38), col, 0.55, UV_Q3_PLASMA)
	_add_box(st, Vector3(0.0, 0.35, 0.0), Vector3(0.52, 0.22, 0.52), Color(0.85, 1.0, 0.4), 0.85, UV_Q3_PLASMA)
	
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
		st.set_uv(UV_Q3_PLASMA.position)
		st.add_vertex(tip_f)
		st.set_uv(Vector2(UV_Q3_PLASMA.end.x, UV_Q3_PLASMA.position.y))
		st.add_vertex(a)
		st.set_uv(UV_Q3_PLASMA.end)
		st.add_vertex(b)
		
		var n_b: Vector3 = (a - tip_b).cross(b - tip_b).normalized()
		st.set_normal(n_b)
		st.set_color(col.darkened(0.15))
		st.set_uv(UV_Q3_PLASMA.position)
		st.add_vertex(tip_b)
		st.set_uv(UV_Q3_PLASMA.end)
		st.add_vertex(b)
		st.set_uv(Vector2(UV_Q3_PLASMA.end.x, UV_Q3_PLASMA.position.y))
		st.add_vertex(a)
		
	st.set_material(material)
	return st.commit()

static func create_debris_chunk_mesh(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3.ZERO, Vector3(0.55, 0.42, 0.48), Color(0.58, 0.55, 0.50), 0.62, UV_Q3_PLASMA)
	st.set_material(material)
	return st.commit()

static func create_skyscraper_mesh(height: float, base_col: Color, material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var main_h: float = height * 0.78
	var top_h: float = height * 0.22
	var bottom_y: float = -height * 0.5
	
	_add_box(st, Vector3(0.0, bottom_y + main_h * 0.5, 0.0), Vector3(3.2, main_h, 3.2), base_col, 0.96, UV_Q1_WINDOWS)
	var top_center_y: float = bottom_y + main_h + top_h * 0.5
	_add_box(st, Vector3(0.0, top_center_y, 0.0), Vector3(2.3, top_h, 2.3), base_col.lightened(0.08), 0.90, UV_Q1_WINDOWS)
	_add_box(st, Vector3(0.0, height * 0.5 + 0.35, 0.0), Vector3(0.9, 0.7, 0.9), base_col.darkened(0.25), 0.6, UV_Q2_ARMOR)
	
	st.set_material(material)
	return st.commit()

static func create_industrial_building_mesh(height: float, base_col: Color, material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var bottom_y: float = -height * 0.5
	var hall_h: float = height * 0.55
	# Factory Hall Base
	_add_box(st, Vector3(0.0, bottom_y + hall_h * 0.5, 0.0), Vector3(3.3, hall_h, 3.3), base_col, 0.95, UV_Q1_WINDOWS)
	# Twin Smokestack Silos
	var stack_h: float = height * 0.45
	var stack_y: float = bottom_y + hall_h + stack_h * 0.5
	_add_box(st, Vector3(-0.75, stack_y, -0.65), Vector3(0.75, stack_h, 0.75), Color(0.75, 0.42, 0.32), 0.75, UV_Q2_ARMOR)
	_add_box(st, Vector3( 0.75, stack_y,  0.65), Vector3(0.75, stack_h, 0.75), Color(0.75, 0.42, 0.32), 0.75, UV_Q2_ARMOR)
	
	st.set_material(material)
	return st.commit()

static func create_radio_tower_mesh(height: float, base_col: Color, material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var bottom_y: float = -height * 0.5
	var podium_h: float = height * 0.30
	var shaft_h: float = height * 0.50
	var spire_h: float = height * 0.20
	
	_add_box(st, Vector3(0.0, bottom_y + podium_h * 0.5, 0.0), Vector3(3.1, podium_h, 3.1), base_col, 0.85, UV_Q1_WINDOWS)
	_add_box(st, Vector3(0.0, bottom_y + podium_h + shaft_h * 0.5, 0.0), Vector3(1.6, shaft_h, 1.6), base_col.lightened(0.1), 0.55, UV_Q1_WINDOWS)
	# Observation Deck Ring
	_add_box(st, Vector3(0.0, bottom_y + podium_h + shaft_h * 0.82, 0.0), Vector3(2.2, 0.55, 2.2), Color(0.25, 0.85, 0.95), 0.9, UV_Q3_PLASMA)
	# Red/White Antenna Spire
	_add_box(st, Vector3(0.0, bottom_y + podium_h + shaft_h + spire_h * 0.5, 0.0), Vector3(0.32, spire_h, 0.32), Color(0.95, 0.25, 0.25), 0.2, UV_Q2_ARMOR)
	
	st.set_material(material)
	return st.commit()
