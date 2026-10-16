class_name SimulationManager
extends Node3D

const MAX_BULLETS: int = 2500
const MAX_ENEMIES: int = 500
const MAX_PICKUPS: int = 400
const MAX_DEBRIS: int = 400
const OFF_SCREEN_REST := Vector3(0.0, -9999.0, 0.0)

const ENEMY_TANK: int = 0
const ENEMY_MECH: int = 1
const ENEMY_HELI: int = 2
const HELI_ALTITUDE: float = 5.2

var spatial_hash := SpatialHash3D.new(3.0)
var player_ref: Node3D
var city_ref: Node3D
var audio_bank: RetroAudioBank
var progression: ProgressionManager
var nav_map_rid: RID

# --- FLAT BULLET POOLS ---
var bullet_pos := PackedVector3Array()
var bullet_vel := PackedVector3Array()
var bullet_life := PackedFloat32Array()
var bullet_damage := PackedFloat32Array()
var bullet_pierce := PackedInt32Array()
var bullet_last_hit := PackedInt32Array()
var bullet_active := PackedByteArray()
var bullet_head: int = 0

# --- FLAT ENEMY POOLS ---
var enemy_pos := PackedVector3Array()
var enemy_waypoint := PackedVector3Array()
var enemy_hp := PackedFloat32Array()
var enemy_type := PackedByteArray()
var enemy_active := PackedByteArray()
var enemy_head: int = 0
var active_enemy_count: int = 0
var total_kills: int = 0

# --- FLAT XP PICKUP POOLS ---
var pickup_pos := PackedVector3Array()
var pickup_val := PackedInt32Array()
var pickup_active := PackedByteArray()
var pickup_head: int = 0

# --- FLAT DEBRIS POOLS ---
var debris_pos := PackedVector3Array()
var debris_vel := PackedVector3Array()
var debris_life := PackedFloat32Array()
var debris_active := PackedByteArray()
var debris_head: int = 0

# --- MULTIMESH BATCH RENDERERS ---
var bullet_mmi: MultiMeshInstance3D
var tank_mmi: MultiMeshInstance3D
var mech_mmi: MultiMeshInstance3D
var heli_mmi: MultiMeshInstance3D
var pickup_mmi: MultiMeshInstance3D
var debris_mmi: MultiMeshInstance3D

var frame_counter: int = 0
var spawn_timer: float = 0.0
var run_time: float = 0.0
var defcon_level: int = 5

func _ready() -> void:
	_init_pools()
	_setup_multimeshes()

func _init_pools() -> void:
	bullet_pos.resize(MAX_BULLETS)
	bullet_vel.resize(MAX_BULLETS)
	bullet_life.resize(MAX_BULLETS)
	bullet_damage.resize(MAX_BULLETS)
	bullet_pierce.resize(MAX_BULLETS)
	bullet_last_hit.resize(MAX_BULLETS)
	bullet_active.resize(MAX_BULLETS)
	bullet_active.fill(0)
	
	enemy_pos.resize(MAX_ENEMIES)
	enemy_waypoint.resize(MAX_ENEMIES)
	enemy_hp.resize(MAX_ENEMIES)
	enemy_type.resize(MAX_ENEMIES)
	enemy_active.resize(MAX_ENEMIES)
	enemy_active.fill(0)
	
	pickup_pos.resize(MAX_PICKUPS)
	pickup_val.resize(MAX_PICKUPS)
	pickup_active.resize(MAX_PICKUPS)
	pickup_active.fill(0)
	
	debris_pos.resize(MAX_DEBRIS)
	debris_vel.resize(MAX_DEBRIS)
	debris_life.resize(MAX_DEBRIS)
	debris_active.resize(MAX_DEBRIS)
	debris_active.fill(0)

func _setup_multimeshes() -> void:
	var ps1_shader := load("res://shaders/ps1_retro_model.gdshader") as Shader
	var atlas: ImageTexture = RetroTextureAtlas.get_atlas_texture()
	
	var shared_mat := ShaderMaterial.new()
	shared_mat.shader = ps1_shader
	shared_mat.set_shader_parameter("albedo_tex", atlas)
	
	bullet_mmi = _create_mmi(MAX_BULLETS, RetroMeshFactory.create_bullet_crystal_mesh(shared_mat))
	add_child(bullet_mmi)
	
	tank_mmi = _create_mmi(MAX_ENEMIES, RetroMeshFactory.create_enemy_tank_mesh(shared_mat))
	add_child(tank_mmi)
	
	mech_mmi = _create_mmi(MAX_ENEMIES, RetroMeshFactory.create_enemy_mech_mesh(shared_mat))
	add_child(mech_mmi)
	
	heli_mmi = _create_mmi(MAX_ENEMIES, RetroMeshFactory.create_enemy_heli_mesh(shared_mat))
	add_child(heli_mmi)
	
	pickup_mmi = _create_mmi(MAX_PICKUPS, RetroMeshFactory.create_pickup_xp_mesh(shared_mat))
	add_child(pickup_mmi)
	
	debris_mmi = _create_mmi(MAX_DEBRIS, RetroMeshFactory.create_debris_chunk_mesh(shared_mat))
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

func _hide_enemy_slot(idx: int) -> void:
	var hide_xform := Transform3D(Basis(), OFF_SCREEN_REST)
	tank_mmi.multimesh.set_instance_transform(idx, hide_xform)
	mech_mmi.multimesh.set_instance_transform(idx, hide_xform)
	heli_mmi.multimesh.set_instance_transform(idx, hide_xform)

func _set_enemy_slot_transform(idx: int, e_type: int, xform: Transform3D) -> void:
	if e_type == ENEMY_TANK:
		tank_mmi.multimesh.set_instance_transform(idx, xform)
	elif e_type == ENEMY_MECH:
		mech_mmi.multimesh.set_instance_transform(idx, xform)
	else:
		heli_mmi.multimesh.set_instance_transform(idx, xform)

func reset_simulation() -> void:
	bullet_active.fill(0)
	enemy_active.fill(0)
	pickup_active.fill(0)
	debris_active.fill(0)
	active_enemy_count = 0
	total_kills = 0
	run_time = 0.0
	defcon_level = 5
	
	var hide_xform := Transform3D(Basis(), OFF_SCREEN_REST)
	for i in range(MAX_BULLETS):
		bullet_mmi.multimesh.set_instance_transform(i, hide_xform)
	for i in range(MAX_ENEMIES):
		_hide_enemy_slot(i)
	for i in range(MAX_PICKUPS):
		pickup_mmi.multimesh.set_instance_transform(i, hide_xform)
	for i in range(MAX_DEBRIS):
		debris_mmi.multimesh.set_instance_transform(i, hide_xform)

func spawn_bullet(pos: Vector3, vel: Vector3, lifetime: float = 2.5, damage: float = 12.0, pierce: int = 0) -> void:
	for _i in range(MAX_BULLETS):
		var idx: int = bullet_head
		bullet_head = (bullet_head + 1) % MAX_BULLETS
		if bullet_active[idx] == 0:
			bullet_active[idx] = 1
			bullet_pos[idx] = pos
			bullet_vel[idx] = vel
			bullet_life[idx] = lifetime
			bullet_damage[idx] = damage
			bullet_pierce[idx] = pierce
			bullet_last_hit[idx] = -1
			return

func spawn_enemy(pos: Vector3, e_type: int = ENEMY_TANK, hp: float = 20.0) -> void:
	for _i in range(MAX_ENEMIES):
		var idx: int = enemy_head
		enemy_head = (enemy_head + 1) % MAX_ENEMIES
		if enemy_active[idx] == 0:
			_hide_enemy_slot(idx)
			enemy_active[idx] = 1
			enemy_type[idx] = e_type
			var spawn_y: float = HELI_ALTITUDE if e_type == ENEMY_HELI else 0.0
			enemy_pos[idx] = Vector3(pos.x, spawn_y, pos.z)
			enemy_waypoint[idx] = enemy_pos[idx]
			enemy_hp[idx] = hp
			active_enemy_count += 1
			return

func _collect_pickup(idx: int) -> void:
	var val: int = pickup_val[idx]
	if is_instance_valid(player_ref) and player_ref.has_method("add_xp"):
		player_ref.add_xp(val)
	if is_instance_valid(progression):
		progression.add_g_cells(val)

func spawn_pickup(pos: Vector3, val: int = 1) -> void:
	for _i in range(MAX_PICKUPS):
		var idx: int = pickup_head
		pickup_head = (pickup_head + 1) % MAX_PICKUPS
		if pickup_active[idx] == 0:
			pickup_active[idx] = 1
			pickup_pos[idx] = Vector3(pos.x, 0.0, pos.z)
			pickup_val[idx] = val
			return
	# Pool is full. Pay out the oldest gem instead of discarding it, or most XP is lost at high kill rates.
	var oldest: int = pickup_head
	pickup_head = (pickup_head + 1) % MAX_PICKUPS
	_collect_pickup(oldest)
	pickup_active[oldest] = 1
	pickup_pos[oldest] = Vector3(pos.x, 0.0, pos.z)
	pickup_val[oldest] = val

func spawn_debris_burst(center: Vector3, count: int = 12) -> void:
	for _c in range(count):
		var idx: int = debris_head
		debris_head = (debris_head + 1) % MAX_DEBRIS
		debris_active[idx] = 1
		debris_pos[idx] = center + Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 2.5), randf_range(-1.0, 1.0))
		debris_vel[idx] = Vector3(randf_range(-8.0, 8.0), randf_range(6.0, 14.0), randf_range(-8.0, 8.0))
		debris_life[idx] = randf_range(0.6, 1.4)

func trigger_seismic_shockwave(center: Vector3, radius: float, damage: float) -> void:
	var candidates: PackedInt32Array = spatial_hash.query_radius(center, radius)
	var r_sq: float = radius * radius
	for i in range(candidates.size()):
		var e_id: int = candidates[i]
		if enemy_active[e_id] == 1:
			var e_pos: Vector3 = enemy_pos[e_id]
			var dx: float = e_pos.x - center.x
			var dz: float = e_pos.z - center.z
			if (dx * dx + dz * dz) <= r_sq:
				_damage_enemy(e_id, damage)
	spawn_debris_burst(center, 14)

func _damage_enemy(e_id: int, dmg: float) -> void:
	enemy_hp[e_id] -= dmg
	if enemy_hp[e_id] <= 0.0:
		var e_pos: Vector3 = enemy_pos[e_id]
		var e_type: int = enemy_type[e_id]
		enemy_active[e_id] = 0
		active_enemy_count -= 1
		total_kills += 1
		_hide_enemy_slot(e_id)
		spawn_debris_burst(e_pos, 5)
		spawn_pickup(e_pos, 3 if e_type == ENEMY_MECH else (2 if e_type == ENEMY_HELI else 1))
		if is_instance_valid(audio_bank):
			audio_bank.play_sfx("enemy_explode", 0.05)

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

func _update_defcon_escalation(delta: float) -> void:
	run_time += delta
	var threat_score: float = run_time + float(total_kills) * 0.35
	if threat_score < 25.0:
		defcon_level = 5
	elif threat_score < 60.0:
		defcon_level = 4
	elif threat_score < 110.0:
		defcon_level = 3
	elif threat_score < 180.0:
		defcon_level = 2
	else:
		defcon_level = 1

func _spawn_wave(player_pos: Vector3) -> void:
	var batch_count: int = 7 - defcon_level
	for _s in range(batch_count):
		var roll: float = randf()
		var e_type: int = ENEMY_TANK
		var hp: float = 20.0
		if defcon_level <= 3 and roll < 0.22:
			e_type = ENEMY_MECH
			hp = 55.0
		elif defcon_level <= 4 and roll < 0.48:
			e_type = ENEMY_HELI
			hp = 25.0
		
		# Ground units retry a few times so they do not spawn inside a building.
		for _attempt in range(4):
			var angle: float = randf() * TAU
			var dist: float = randf_range(26.0, 38.0)
			var s_pos := Vector3(player_pos.x + cos(angle) * dist, 0.0, player_pos.z + sin(angle) * dist)
			if e_type != ENEMY_HELI and is_instance_valid(city_ref) and city_ref.has_method("is_cell_blocked") and city_ref.is_cell_blocked(s_pos):
				continue
			spawn_enemy(s_pos, e_type, hp)
			break

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return
	var hide_xform := Transform3D(Basis(), OFF_SCREEN_REST)
	if player_ref.get("is_dead") == true:
		# Horde and bullets freeze on death; debris keeps falling so the death burst is visible.
		_update_debris(delta, hide_xform)
		return
		
	frame_counter += 1
	_update_defcon_escalation(delta)
	var player_pos: Vector3 = player_ref.global_position
	
	# 1. DEFCON-Scaled Multi-Bucket Spawning
	spawn_timer += delta
	var spawn_interval: float = 0.05 + float(defcon_level) * 0.015
	if spawn_timer >= spawn_interval and active_enemy_count < MAX_ENEMIES - 10:
		spawn_timer = 0.0
		_spawn_wave(player_pos)

	# 2. Update Enemies across Tank, Mech, and Heli MultiMesh Buckets
	spatial_hash.clear()
	var tick_group: int = frame_counter & 15
	var contact_damage_this_frame: float = 0.0
	
	for i in range(MAX_ENEMIES):
		if enemy_active[i] == 0:
			continue
		var e_pos: Vector3 = enemy_pos[i]
		var e_type: int = enemy_type[i]
		var to_player_x: float = player_pos.x - e_pos.x
		var to_player_z: float = player_pos.z - e_pos.z
		var player_dist_sq: float = to_player_x * to_player_x + to_player_z * to_player_z
		
		# Flying VTOL Gunships ignore street navmesh; ground units query navmesh on their tick group
		if e_type == ENEMY_HELI:
			enemy_waypoint[i] = player_pos
		elif (i & 15) == tick_group:
			enemy_waypoint[i] = _query_next_waypoint(e_pos, player_pos)
			
		var wp: Vector3 = enemy_waypoint[i]
		var dx: float = wp.x - e_pos.x
		var dz: float = wp.z - e_pos.z
		var wp_dist_sq: float = dx * dx + dz * dz
		if wp_dist_sq < 0.25:
			dx = to_player_x
			dz = to_player_z
			wp_dist_sq = player_dist_sq

		var speed: float = 6.2 if e_type == ENEMY_HELI else (3.3 if e_type == ENEMY_MECH else 4.4)
		
		if player_dist_sq > 784.0:
			if (i & 15) == tick_group and wp_dist_sq > 0.01:
				var inv_d: float = 1.0 / sqrt(wp_dist_sq)
				e_pos.x += dx * inv_d * speed * (delta * 16.0)
				e_pos.z += dz * inv_d * speed * (delta * 16.0)
				enemy_pos[i] = e_pos
				_set_enemy_slot_transform(i, e_type, Transform3D(Basis(), e_pos))
		else:
			if player_dist_sq < 2.5:
				var dps: float = 22.0 if e_type == ENEMY_MECH else 12.0
				contact_damage_this_frame += dps * delta
				if player_dist_sq > 0.001:
					var push_inv: float = 1.0 / sqrt(player_dist_sq)
					e_pos.x -= to_player_x * push_inv * 2.5 * delta
					e_pos.z -= to_player_z * push_inv * 2.5 * delta
			elif wp_dist_sq > 0.01:
				var inv_d: float = 1.0 / sqrt(wp_dist_sq)
				e_pos.x += dx * inv_d * speed * delta
				e_pos.z += dz * inv_d * speed * delta
				
			enemy_pos[i] = e_pos
			var look_dir := Vector3(dx, 0.0, dz)
			var basis := Basis.looking_at(look_dir.normalized(), Vector3.UP) if look_dir.length_squared() > 0.001 else Basis()
			_set_enemy_slot_transform(i, e_type, Transform3D(basis, e_pos))
			spatial_hash.insert_entity(i, e_pos)

	if contact_damage_this_frame > 0.0 and player_ref.has_method("take_damage"):
		player_ref.take_damage(contact_damage_this_frame)

	# 3. Update Bullets & Piercing Broadphase Collisions
	var bullet_mm: MultiMesh = bullet_mmi.multimesh
	var hit_radius_sq: float = 1.2 * 1.2
	
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
		
		var candidates: PackedInt32Array = spatial_hash.query_radius(b_pos, 1.25)
		var depleted: bool = false
		
		for c_idx in range(candidates.size()):
			var e_id: int = candidates[c_idx]
			if enemy_active[e_id] == 1 and e_id != bullet_last_hit[i]:
				var e_pos: Vector3 = enemy_pos[e_id]
				var edx: float = b_pos.x - e_pos.x
				var edz: float = b_pos.z - e_pos.z
				if (edx * edx + edz * edz) <= hit_radius_sq:
					bullet_last_hit[i] = e_id
					_damage_enemy(e_id, bullet_damage[i])
					if bullet_pierce[i] > 0:
						bullet_pierce[i] -= 1
					else:
						depleted = true
					break
					
		if depleted:
			bullet_active[i] = 0
			bullet_mm.set_instance_transform(i, hide_xform)
		else:
			var b_basis := Basis.looking_at(b_vel.normalized(), Vector3.UP)
			bullet_mm.set_instance_transform(i, Transform3D(b_basis, b_pos))

	# 4. Update G-Cell XP Pickups & Magnetic Collection
	var pickup_mm: MultiMesh = pickup_mmi.multimesh
	var mag_r: float = float(player_ref.get("pickup_radius"))
	var mag_r_sq: float = mag_r * mag_r
	var spin_basis := Basis(Vector3.UP, run_time * 3.5)
	
	for i in range(MAX_PICKUPS):
		if pickup_active[i] == 0:
			continue
		var p_pos: Vector3 = pickup_pos[i]
		var pdx: float = player_pos.x - p_pos.x
		var pdz: float = player_pos.z - p_pos.z
		var p_dist_sq: float = pdx * pdx + pdz * pdz
		
		if p_dist_sq <= 1.2:
			pickup_active[i] = 0
			pickup_mm.set_instance_transform(i, hide_xform)
			_collect_pickup(i)
			if is_instance_valid(audio_bank):
				audio_bank.play_sfx("pickup_xp", 0.04)
		elif p_dist_sq <= mag_r_sq and p_dist_sq > 0.001:
			var inv_d: float = 1.0 / sqrt(p_dist_sq)
			p_pos.x += pdx * inv_d * 18.0 * delta
			p_pos.z += pdz * inv_d * 18.0 * delta
			pickup_pos[i] = p_pos
			pickup_mm.set_instance_transform(i, Transform3D(spin_basis, p_pos))
		else:
			pickup_mm.set_instance_transform(i, Transform3D(spin_basis, p_pos))

	# 5. Update Destruction Debris Particles
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
