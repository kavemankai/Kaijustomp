class_name SimulationManager
extends Node3D

const MAX_BULLETS: int = 2500
const MAX_ENEMIES: int = 500
const MAX_DEBRIS: int = 400
const OFF_SCREEN_REST := Vector3(0.0, -9999.0, 0.0)

var spatial_hash := SpatialHash3D.new(3.0)
var player_ref: Node3D
var city_ref: Node3D
var nav_map_rid: RID

# --- FLAT BULLET POOLS ---
var bullet_pos := PackedVector3Array()
var bullet_vel := PackedVector3Array()
var bullet_life := PackedFloat32Array()
var bullet_active := PackedByteArray()
var bullet_head: int = 0

# --- FLAT ENEMY POOLS ---
var enemy_pos := PackedVector3Array()
var enemy_waypoint := PackedVector3Array()
var enemy_hp := PackedFloat32Array()
var enemy_active := PackedByteArray()
var enemy_head: int = 0
var active_enemy_count: int = 0
var total_kills: int = 0

# --- FLAT DEBRIS POOLS ---
var debris_pos := PackedVector3Array()
var debris_vel := PackedVector3Array()
var debris_life := PackedFloat32Array()
var debris_active := PackedByteArray()
var debris_head: int = 0

# --- MULTIMESH BATCH RENDERERS ---
var bullet_mmi: MultiMeshInstance3D
var enemy_mmi: MultiMeshInstance3D
var debris_mmi: MultiMeshInstance3D

var frame_counter: int = 0
var spawn_timer: float = 0.0

func _ready() -> void:
	_init_pools()
	_setup_multimeshes()

func _init_pools() -> void:
	bullet_pos.resize(MAX_BULLETS)
	bullet_vel.resize(MAX_BULLETS)
	bullet_life.resize(MAX_BULLETS)
	bullet_active.resize(MAX_BULLETS)
	bullet_active.fill(0)
	
	enemy_pos.resize(MAX_ENEMIES)
	enemy_waypoint.resize(MAX_ENEMIES)
	enemy_hp.resize(MAX_ENEMIES)
	enemy_active.resize(MAX_ENEMIES)
	enemy_active.fill(0)
	
	debris_pos.resize(MAX_DEBRIS)
	debris_vel.resize(MAX_DEBRIS)
	debris_life.resize(MAX_DEBRIS)
	debris_active.resize(MAX_DEBRIS)
	debris_active.fill(0)

func _setup_multimeshes() -> void:
	var ps1_shader := load("res://shaders/ps1_retro_model.gdshader") as Shader
	
	var b_mat := ShaderMaterial.new()
	b_mat.shader = ps1_shader
	bullet_mmi = _create_mmi(MAX_BULLETS, RetroMeshFactory.create_bullet_crystal_mesh(b_mat))
	add_child(bullet_mmi)
	
	var e_mat := ShaderMaterial.new()
	e_mat.shader = ps1_shader
	enemy_mmi = _create_mmi(MAX_ENEMIES, RetroMeshFactory.create_enemy_tank_mesh(e_mat))
	add_child(enemy_mmi)
	
	var d_mat := ShaderMaterial.new()
	d_mat.shader = ps1_shader
	debris_mmi = _create_mmi(MAX_DEBRIS, RetroMeshFactory.create_debris_chunk_mesh(d_mat))
	add_child(debris_mmi)

func _create_mmi(count: int, mesh: Mesh) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = mesh
	
	var hide_xform := Transform3D(Basis(), OFF_SCREEN_REST)
	for i in range(count):
		mm.set_instance_transform(i, hide_xform)
		
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	return mmi

func reset_simulation() -> void:
	bullet_active.fill(0)
	enemy_active.fill(0)
	debris_active.fill(0)
	active_enemy_count = 0
	total_kills = 0
	
	var hide_xform := Transform3D(Basis(), OFF_SCREEN_REST)
	for i in range(MAX_BULLETS):
		bullet_mmi.multimesh.set_instance_transform(i, hide_xform)
	for i in range(MAX_ENEMIES):
		enemy_mmi.multimesh.set_instance_transform(i, hide_xform)
	for i in range(MAX_DEBRIS):
		debris_mmi.multimesh.set_instance_transform(i, hide_xform)

func spawn_bullet(pos: Vector3, vel: Vector3, lifetime: float = 2.5) -> void:
	for _i in range(MAX_BULLETS):
		var idx: int = bullet_head
		bullet_head = (bullet_head + 1) % MAX_BULLETS
		if bullet_active[idx] == 0:
			bullet_active[idx] = 1
			bullet_pos[idx] = pos
			bullet_vel[idx] = vel
			bullet_life[idx] = lifetime
			return

func spawn_enemy(pos: Vector3, hp: float = 20.0) -> void:
	for _i in range(MAX_ENEMIES):
		var idx: int = enemy_head
		enemy_head = (enemy_head + 1) % MAX_ENEMIES
		if enemy_active[idx] == 0:
			enemy_active[idx] = 1
			enemy_pos[idx] = pos
			enemy_waypoint[idx] = pos
			enemy_hp[idx] = hp
			active_enemy_count += 1
			return

func spawn_debris_burst(center: Vector3, count: int = 12) -> void:
	for _c in range(count):
		var idx: int = debris_head
		debris_head = (debris_head + 1) % MAX_DEBRIS
		debris_active[idx] = 1
		debris_pos[idx] = center + Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 2.5), randf_range(-1.0, 1.0))
		debris_vel[idx] = Vector3(randf_range(-8.0, 8.0), randf_range(6.0, 14.0), randf_range(-8.0, 8.0))
		debris_life[idx] = randf_range(0.6, 1.4)

func _query_next_waypoint(from_pos: Vector3, target_pos: Vector3) -> Vector3:
	if not nav_map_rid.is_valid():
		return target_pos
	var path: PackedVector3Array = NavigationServer3D.map_get_path(nav_map_rid, from_pos, target_pos, true)
	if path.size() >= 2:
		var wp: Vector3 = path[1]
		if Vector2(from_pos.x, from_pos.z).distance_squared_to(Vector2(wp.x, wp.z)) < 0.35 and path.size() >= 3:
			wp = path[2]
		return Vector3(wp.x, 0.0, wp.z)
	return target_pos

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return
	var hide_xform := Transform3D(Basis(), OFF_SCREEN_REST)
	if player_ref.get("is_dead") == true:
		# Horde and bullets freeze on death; debris keeps falling so the death burst is visible.
		_update_debris(delta, hide_xform)
		return
		
	frame_counter += 1
	var player_pos: Vector3 = player_ref.global_position
	
	# 1. Continuous Horde Spawning Ring around Player
	spawn_timer += delta
	if spawn_timer >= 0.10 and active_enemy_count < MAX_ENEMIES - 10:
		spawn_timer = 0.0
		for _s in range(3):
			# Retry a few times so tanks do not spawn inside a building.
			for _attempt in range(4):
				var angle: float = randf() * TAU
				var dist: float = randf_range(26.0, 38.0)
				var s_pos := Vector3(player_pos.x + cos(angle) * dist, 0.0, player_pos.z + sin(angle) * dist)
				if is_instance_valid(city_ref) and city_ref.has_method("is_cell_blocked") and city_ref.is_cell_blocked(s_pos):
					continue
				spawn_enemy(s_pos, 20.0)
				break

	# 2. Update Enemies, Amortized Navmesh Pathfinding, & Contact Damage
	spatial_hash.clear()
	var tick_group: int = frame_counter & 15
	var enemy_mm: MultiMesh = enemy_mmi.multimesh
	var enemy_speed: float = 4.4
	var contact_damage_this_frame: float = 0.0
	
	for i in range(MAX_ENEMIES):
		if enemy_active[i] == 0:
			continue
		var e_pos: Vector3 = enemy_pos[i]
		var to_player_x: float = player_pos.x - e_pos.x
		var to_player_z: float = player_pos.z - e_pos.z
		var player_dist_sq: float = to_player_x * to_player_x + to_player_z * to_player_z
		
		# Refresh navmesh waypoint on enemy's assigned 16-frame tick group
		if (i & 15) == tick_group:
			enemy_waypoint[i] = _query_next_waypoint(e_pos, player_pos)
			
		var wp: Vector3 = enemy_waypoint[i]
		var dx: float = wp.x - e_pos.x
		var dz: float = wp.z - e_pos.z
		var wp_dist_sq: float = dx * dx + dz * dz
		if wp_dist_sq < 0.25:
			dx = to_player_x
			dz = to_player_z
			wp_dist_sq = player_dist_sq

		# Off-screen interleaved movement (> 28 units from player)
		if player_dist_sq > 784.0:
			if (i & 15) == tick_group and wp_dist_sq > 0.01:
				var inv_d: float = 1.0 / sqrt(wp_dist_sq)
				e_pos.x += dx * inv_d * enemy_speed * (delta * 16.0)
				e_pos.z += dz * inv_d * enemy_speed * (delta * 16.0)
				enemy_pos[i] = e_pos
				enemy_mm.set_instance_transform(i, Transform3D(Basis(), e_pos))
		else:
			# Melee contact check against Kaiju player
			if player_dist_sq < 2.4:
				contact_damage_this_frame += 14.0 * delta
				if player_dist_sq > 0.001:
					var push_inv: float = 1.0 / sqrt(player_dist_sq)
					e_pos.x -= to_player_x * push_inv * 2.0 * delta
					e_pos.z -= to_player_z * push_inv * 2.0 * delta
			elif wp_dist_sq > 0.01:
				var inv_d: float = 1.0 / sqrt(wp_dist_sq)
				e_pos.x += dx * inv_d * enemy_speed * delta
				e_pos.z += dz * inv_d * enemy_speed * delta
				
			enemy_pos[i] = e_pos
			var look_dir := Vector3(dx, 0.0, dz)
			var basis := Basis.looking_at(look_dir.normalized(), Vector3.UP) if look_dir.length_squared() > 0.001 else Basis()
			enemy_mm.set_instance_transform(i, Transform3D(basis, e_pos))
			spatial_hash.insert_entity(i, e_pos)

	if contact_damage_this_frame > 0.0 and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage_this_frame)

	# 3. Update Bullets & Evaluate Spatial Hash Broadphase Collisions
	var bullet_mm: MultiMesh = bullet_mmi.multimesh
	var hit_radius_sq: float = 1.15 * 1.15
	
	for i in range(MAX_BULLETS):
		if bullet_active[i] == 0:
			continue
		var life: float = bullet_life[i] - delta
		if life <= 0.0:
			bullet_active[i] = 0
			bullet_mm.set_instance_transform(i, hide_xform)
			continue
			
		bullet_life[i] = life
		var b_vel: Vector3 = bullet_vel[i]
		var b_pos: Vector3 = bullet_pos[i] + b_vel * delta
		bullet_pos[i] = b_pos
		
		var candidates: PackedInt32Array = spatial_hash.query_radius(b_pos, 1.2)
		var hit: bool = false
		
		for c_idx in range(candidates.size()):
			var e_id: int = candidates[c_idx]
			if enemy_active[e_id] == 1:
				var e_pos: Vector3 = enemy_pos[e_id]
				var edx: float = b_pos.x - e_pos.x
				var edz: float = b_pos.z - e_pos.z
				if (edx * edx + edz * edz) <= hit_radius_sq:
					hit = true
					enemy_hp[e_id] -= 10.0
					if enemy_hp[e_id] <= 0.0:
						enemy_active[e_id] = 0
						active_enemy_count -= 1
						total_kills += 1
						enemy_mm.set_instance_transform(e_id, hide_xform)
						spawn_debris_burst(e_pos, 5)
					break
					
		if hit:
			bullet_active[i] = 0
			bullet_mm.set_instance_transform(i, hide_xform)
		else:
			var b_basis := Basis.looking_at(b_vel.normalized(), Vector3.UP)
			bullet_mm.set_instance_transform(i, Transform3D(b_basis, b_pos))

	# 4. Update Destruction Debris Particles
	_update_debris(delta, hide_xform)

func _update_debris(delta: float, hide_xform: Transform3D) -> void:
	var debris_mm: MultiMesh = debris_mmi.multimesh
	for i in range(MAX_DEBRIS):
		if debris_active[i] == 0:
			continue
		var d_life: float = debris_life[i] - delta
		if d_life <= 0.0:
			debris_active[i] = 0
			debris_mm.set_instance_transform(i, hide_xform)
			continue
		debris_life[i] = d_life
		var d_vel: Vector3 = debris_vel[i]
		d_vel.y -= 24.0 * delta
		var d_pos: Vector3 = debris_pos[i] + d_vel * delta
		if d_pos.y < 0.25:
			d_pos.y = 0.25
			d_vel.x *= 0.6
			d_vel.z *= 0.6
			d_vel.y = abs(d_vel.y) * 0.4
		debris_vel[i] = d_vel
		debris_pos[i] = d_pos
		debris_mm.set_instance_transform(i, Transform3D(Basis(), d_pos))
