class_name KaijuPlayer
extends Node3D

signal player_died()
signal level_up_ready(new_level: int)

const NOVA_COOLDOWN: float = 5.0

@export var base_move_speed: float = 8.5
@export var base_max_hp: float = 100.0

var max_hp: float = 100.0
var hp: float = 100.0
var move_speed: float = 8.5
var pickup_radius: float = 6.5

var level: int = 1
var xp: int = 0
var xp_to_next: int = 8
var revive_used: bool = false

# In-Run Mutation Upgrades
var spiral_arms: int = 4
var bullet_damage: float = 12.0
var bullet_pierce: int = 0
var fire_interval: float = 0.07
var shockwave_level: int = 0

var is_dead: bool = false
var damage_flash_timer: float = 0.0
var nova_timer: float = 0.0

var move_input: Vector2 = Vector2.ZERO
var sim_manager: SimulationManager
var city_manager: DynamicCityManager
var audio_bank: RetroAudioBank
var progression: ProgressionManager

var fire_timer: float = 0.0
var shockwave_timer: float = 0.0
var spiral_angle: float = 0.0
var step_timer: float = 0.0
var visual_root: Node3D
var kaiju_material: ShaderMaterial

func _ready() -> void:
	_build_kaiju_mesh()
	_setup_diorama_camera()
	reset_player()

func _build_kaiju_mesh() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var ps1_shader := load("res://shaders/ps1_retro_model.gdshader") as Shader
	kaiju_material = ShaderMaterial.new()
	kaiju_material.shader = ps1_shader
	kaiju_material.set_shader_parameter("albedo_tex", RetroTextureAtlas.get_atlas_texture())
	kaiju_material.set_shader_parameter("base_color", Color.WHITE)
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = RetroMeshFactory.create_kaiju_mesh(kaiju_material)
	visual_root.add_child(mesh_inst)

func _setup_diorama_camera() -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 10.0
	cam.near = 10.0
	cam.far = 350.0
	add_child(cam)
	cam.position = Vector3(0.0, 145.0, 115.0)
	cam.look_at(global_position, Vector3.UP)

func set_movement_vector(vec: Vector2) -> void:
	move_input = vec

func add_xp(amount: int) -> void:
	if is_dead:
		return
	xp += amount
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(float(xp_to_next) * 1.35) + 4
		if is_instance_valid(audio_bank):
			audio_bank.play_sfx("level_up", 0.05)
		level_up_ready.emit(level)

func apply_mutation(mutation_id: String) -> void:
	match mutation_id:
		"dorsal_overcharge":
			spiral_arms = mini(spiral_arms + 1, 10)
			fire_interval = maxf(0.035, fire_interval * 0.90)
		"isotope_core":
			bullet_damage *= 1.25
			bullet_pierce += 1
		"regenerative_cells":
			max_hp += 30.0
			hp = minf(max_hp, hp + 50.0)
		"seismic_stomp":
			shockwave_level += 1
		"bio_magnet":
			pickup_radius += 3.0
			move_speed *= 1.12

func take_damage(amount: float) -> void:
	if is_dead:
		return
	hp = maxf(0.0, hp - amount)
	damage_flash_timer = 0.12
	kaiju_material.set_shader_parameter("base_color", Color(1.0, 0.25, 0.25))
	if is_instance_valid(audio_bank):
		audio_bank.play_sfx("player_hurt", 0.18)
	
	if hp <= 0.0:
		is_dead = true
		visual_root.visible = false
		if is_instance_valid(sim_manager):
			sim_manager.spawn_debris_burst(global_position + Vector3(0.0, 1.5, 0.0), 35)
		if is_instance_valid(progression) and is_instance_valid(sim_manager):
			progression.record_kills(sim_manager.total_kills)
		Input.vibrate_handheld(300)
		player_died.emit()

func revive_with_defibrillator() -> void:
	if not is_dead or revive_used:
		return
	revive_used = true
	is_dead = false
	hp = max_hp * 0.65
	visual_root.visible = true
	kaiju_material.set_shader_parameter("base_color", Color.WHITE)
	_fire_nova()
	if is_instance_valid(sim_manager):
		sim_manager.trigger_seismic_shockwave(global_position, 14.0, 200.0)

func reset_player() -> void:
	var hp_bonus: float = progression.get_max_hp_bonus() if is_instance_valid(progression) else 0.0
	var dmg_mult: float = progression.get_damage_multiplier() if is_instance_valid(progression) else 1.0
	var spd_mult: float = progression.get_speed_multiplier() if is_instance_valid(progression) else 1.0
	var mag_bonus: float = progression.get_magnet_bonus() if is_instance_valid(progression) else 0.0
	
	max_hp = base_max_hp + hp_bonus
	hp = max_hp
	move_speed = base_move_speed * spd_mult
	pickup_radius = 6.5 + mag_bonus
	
	level = 1
	xp = 0
	xp_to_next = 8
	revive_used = false
	
	spiral_arms = 4
	bullet_damage = 12.0 * dmg_mult
	bullet_pierce = 0
	fire_interval = 0.07
	shockwave_level = 0
	nova_timer = 0.0
	move_input = Vector2.ZERO
	
	is_dead = false
	global_position = Vector3.ZERO
	visual_root.visible = true
	kaiju_material.set_shader_parameter("base_color", Color.WHITE)
	if is_instance_valid(audio_bank):
		audio_bank.play_sfx("roar", 0.1)

func _physics_process(delta: float) -> void:
	if damage_flash_timer > 0.0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0.0:
			kaiju_material.set_shader_parameter("base_color", Color.WHITE)
			
	if is_dead:
		return
	
	nova_timer = maxf(0.0, nova_timer - delta)
		
	var kb_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var active_dir: Vector2 = move_input if move_input.length_squared() > 0.001 else kb_input
	
	if active_dir.length_squared() > 0.001:
		var move_vec := Vector3(active_dir.x, 0.0, active_dir.y) * move_speed * delta
		global_position += move_vec
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(-active_dir.x, -active_dir.y), 10.0 * delta)
		
		step_timer += delta
		if step_timer >= 0.4:
			step_timer = 0.0
			Input.vibrate_handheld(20)
			if is_instance_valid(audio_bank):
				audio_bank.play_sfx("footstep", 0.15)
		if is_instance_valid(city_manager):
			city_manager.crush_buildings_near(global_position, 2.8)

	# Auto-Shooter Atomic Spine Spiral
	fire_timer += delta
	if fire_timer >= fire_interval and is_instance_valid(sim_manager):
		fire_timer = 0.0
		spiral_angle += 0.36
		var origin := global_position + Vector3(0.0, 1.4, 0.0)
		var step_a: float = TAU / float(spiral_arms)
		
		for arm in range(spiral_arms):
			var a: float = spiral_angle + float(arm) * step_a
			var dir := Vector3(cos(a), 0.0, sin(a))
			sim_manager.spawn_bullet(origin, dir * 22.0, 2.2, bullet_damage, bullet_pierce)
		if is_instance_valid(audio_bank):
			audio_bank.play_sfx("shoot", 0.12)

	# Periodic Seismic Stomp Mutation
	if shockwave_level > 0 and is_instance_valid(sim_manager):
		shockwave_timer += delta
		if shockwave_timer >= maxf(1.2, 3.0 - float(shockwave_level) * 0.35):
			shockwave_timer = 0.0
			var r: float = 5.5 + float(shockwave_level) * 1.5
			sim_manager.trigger_seismic_shockwave(global_position, r, bullet_damage * 2.5)
			if is_instance_valid(city_manager):
				city_manager.crush_buildings_near(global_position, r * 0.8)
			if is_instance_valid(audio_bank):
				audio_bank.play_sfx("building_crush", 0.1)

func trigger_atomic_nova() -> void:
	if is_dead or nova_timer > 0.0:
		return
	_fire_nova()

func _fire_nova() -> void:
	if not is_instance_valid(sim_manager):
		return
	nova_timer = NOVA_COOLDOWN
	Input.vibrate_handheld(80)
	if is_instance_valid(audio_bank):
		audio_bank.play_sfx("roar", 0.2)
	var origin := global_position + Vector3(0.0, 1.4, 0.0)
	for i in range(48):
		var a: float = (float(i) / 48.0) * TAU
		sim_manager.spawn_bullet(origin, Vector3(cos(a), 0.0, sin(a)) * 28.0, 2.5, bullet_damage * 1.5, bullet_pierce + 1)
