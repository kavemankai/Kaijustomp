class_name KaijuPlayer
extends Node3D

signal player_died()

@export var move_speed: float = 8.5
@export var max_hp: float = 100.0

var hp: float = 100.0
var is_dead: bool = false
var damage_flash_timer: float = 0.0

var move_input: Vector2 = Vector2.ZERO
var sim_manager: SimulationManager
var city_manager: DynamicCityManager

var fire_timer: float = 0.0
var spiral_angle: float = 0.0
var step_timer: float = 0.0
var visual_root: Node3D
var kaiju_material: ShaderMaterial

func _ready() -> void:
	hp = max_hp
	_build_kaiju_mesh()
	_setup_diorama_camera()

func _build_kaiju_mesh() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var ps1_shader := load("res://shaders/ps1_retro_model.gdshader") as Shader
	kaiju_material = ShaderMaterial.new()
	kaiju_material.shader = ps1_shader
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

func take_damage(amount: float) -> void:
	if is_dead:
		return
	hp = max(0.0, hp - amount)
	damage_flash_timer = 0.12
	kaiju_material.set_shader_parameter("base_color", Color(1.0, 0.25, 0.25))
	
	if hp <= 0.0:
		is_dead = true
		visual_root.visible = false
		if is_instance_valid(sim_manager):
			sim_manager.spawn_debris_burst(global_position + Vector3(0.0, 1.5, 0.0), 35)
		Input.vibrate_handheld(300)
		player_died.emit()

func reset_player() -> void:
	hp = max_hp
	is_dead = false
	global_position = Vector3.ZERO
	visual_root.visible = true
	kaiju_material.set_shader_parameter("base_color", Color.WHITE)

func _physics_process(delta: float) -> void:
	if damage_flash_timer > 0.0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0.0:
			kaiju_material.set_shader_parameter("base_color", Color.WHITE)
			
	if is_dead:
		return
		
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
		if is_instance_valid(city_manager):
			city_manager.crush_buildings_near(global_position, 2.8)

	fire_timer += delta
	if fire_timer >= 0.06 and is_instance_valid(sim_manager):
		fire_timer = 0.0
		spiral_angle += 0.38
		var origin := global_position + Vector3(0.0, 1.4, 0.0)
		
		for arm in range(4):
			var a: float = spiral_angle + arm * (PI * 0.5)
			var dir := Vector3(cos(a), 0.0, sin(a))
			sim_manager.spawn_bullet(origin, dir * 22.0, 2.2)

func trigger_atomic_nova() -> void:
	if is_dead or not is_instance_valid(sim_manager):
		return
	Input.vibrate_handheld(80)
	var origin := global_position + Vector3(0.0, 1.4, 0.0)
	for i in range(48):
		var a: float = (float(i) / 48.0) * TAU
		sim_manager.spawn_bullet(origin, Vector3(cos(a), 0.0, sin(a)) * 28.0, 2.5)
