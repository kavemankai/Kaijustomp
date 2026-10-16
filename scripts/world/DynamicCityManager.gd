class_name DynamicCityManager
extends Node3D

const CELL_SIZE: float = 4.0
const CITY_EXTENTS: int = 12

var grid_map: GridMap
var nav_region: NavigationRegion3D
var nav_mesh: NavigationMesh
var source_geometry: NavigationMeshSourceGeometryData3D
var is_baking: bool = false
var pending_rebake: bool = false

var sim_manager: SimulationManager
var building_heights: Array[float] = [4.5, 7.5]

func _ready() -> void:
	_setup_navigation()
	_setup_city_gridmap()
	_deferred_initial_bake()

func _deferred_initial_bake() -> void:
	# GridMap creates its colliders on a deferred call. Baking sooner produces a navmesh without buildings.
	await get_tree().process_frame
	await get_tree().physics_frame
	trigger_building_destruction_rebake()

func get_nav_map_rid() -> RID:
	return nav_region.get_navigation_map()

func _setup_navigation() -> void:
	nav_region = NavigationRegion3D.new()
	nav_mesh = NavigationMesh.new()
	nav_mesh.agent_radius = 0.5
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)
	
	source_geometry = NavigationMeshSourceGeometryData3D.new()
	
	var ground_body := StaticBody3D.new()
	var ground_col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 0.2, 200.0)
	ground_col.shape = box
	ground_body.add_child(ground_col)
	
	var ground_mesh_inst := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(200.0, 0.2, 200.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.16, 0.18, 0.2)
	ground_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground_mesh.material = ground_mat
	ground_mesh_inst.mesh = ground_mesh
	ground_body.add_child(ground_mesh_inst)
	
	nav_region.add_child(ground_body)

func _setup_city_gridmap() -> void:
	var mesh_lib := MeshLibrary.new()
	var ps1_shader := load("res://shaders/ps1_retro_model.gdshader") as Shader
	var colors: Array[Color] = [Color(0.45, 0.5, 0.58), Color(0.6, 0.52, 0.45)]
	
	for id in range(2):
		var h: float = building_heights[id]
		var mat := ShaderMaterial.new()
		mat.shader = ps1_shader
		var b_mesh: ArrayMesh = RetroMeshFactory.create_skyscraper_mesh(h, colors[id], mat)
		
		mesh_lib.create_item(id)
		mesh_lib.set_item_mesh(id, b_mesh)
		
		var shape := BoxShape3D.new()
		shape.size = Vector3(3.2, h, 3.2)
		mesh_lib.set_item_shapes(id, [shape, Transform3D.IDENTITY])

	grid_map = GridMap.new()
	grid_map.mesh_library = mesh_lib
	grid_map.cell_size = Vector3(CELL_SIZE, 1.0, CELL_SIZE)
	nav_region.add_child(grid_map)
	
	_populate_city_cells()

func _populate_city_cells() -> void:
	grid_map.clear()
	for x in range(-CITY_EXTENTS, CITY_EXTENTS):
		for z in range(-CITY_EXTENTS, CITY_EXTENTS):
			if abs(x) <= 2 and abs(z) <= 2:
				continue
			if (x % 3 != 0) and (z % 3 != 0) and randf() < 0.75:
				var type_id: int = randi() % 2
				grid_map.set_cell_item(Vector3i(x, int(building_heights[type_id] * 0.5), z), type_id)

func reset_city() -> void:
	_populate_city_cells()
	_deferred_initial_bake()

func is_cell_blocked(world_pos: Vector3) -> bool:
	var map_pos: Vector3i = grid_map.local_to_map(world_pos)
	for y_check in [2, 3]:
		if grid_map.get_cell_item(Vector3i(map_pos.x, y_check, map_pos.z)) != GridMap.INVALID_CELL_ITEM:
			return true
	return false

func crush_buildings_near(world_pos: Vector3, radius: float = 2.6) -> void:
	var map_pos: Vector3i = grid_map.local_to_map(world_pos)
	var crushed_any: bool = false
	
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for y_check in [2, 3]:
				var cell := Vector3i(map_pos.x + dx, y_check, map_pos.z + dz)
				if grid_map.get_cell_item(cell) != GridMap.INVALID_CELL_ITEM:
					var cell_world: Vector3 = grid_map.map_to_local(cell)
					if Vector2(world_pos.x, world_pos.z).distance_to(Vector2(cell_world.x, cell_world.z)) <= radius:
						grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
						crushed_any = true
						if is_instance_valid(sim_manager):
							sim_manager.spawn_debris_burst(cell_world, 16)
							
	if crushed_any:
		Input.vibrate_handheld(120)
		trigger_building_destruction_rebake()

func trigger_building_destruction_rebake() -> void:
	if is_baking:
		pending_rebake = true
		return
		
	is_baking = true
	pending_rebake = false
	source_geometry.clear()
	
	NavigationServer3D.parse_source_geometry_data(nav_mesh, source_geometry, nav_region)
	NavigationServer3D.bake_from_source_geometry_data_async(
		nav_mesh,
		source_geometry,
		_on_navmesh_baking_completed
	)

func _on_navmesh_baking_completed() -> void:
	NavigationServer3D.region_set_navigation_mesh(nav_region.get_rid(), nav_mesh)
	is_baking = false
	if pending_rebake:
		trigger_building_destruction_rebake()
