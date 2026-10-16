class_name KaijuPlayer
extends Node3D

@export var move_speed: float = 8.5
var move_input: Vector2 = Vector2.ZERO
var sim_manager: SimulationManager
var city_manager: DynamicCityManager

var fire_timer: float = 0.0
var spiral_angle: float = 0.0
var step_timer: float = 0.0
var visual_root: Node3D

func _ready() -> void:
	_build_kaiju_mesh()
	_setup_diorama_camera()

func _build_kaiju_mesh() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	var ps1_shader := load("res://shaders/ps1_retro_model.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = ps1_shader
	mat.set_shader_parameter("base_color", Color(0.18, 0.75, 0.32))
	
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.8, 3.2, 1.8)
	body_mesh.material = mat
	body.mesh = body_mesh
	body.position = Vector3(0.0, 1.6, 0.0)
	visual_root.add_child(body)
	
	var spine_mat := ShaderMaterial.new()
	spine_mat.shader = ps1_shader
	spine_mat.set_shader_parameter("base_color", Color(0.2, 1.0, 0.95))
	var spine := MeshInstance3D.new()
	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(0.4, 2.2, 0.6)
	spine_mesh.material = spine_mat
	spine.mesh = spine_mesh
	spine.position = Vector3(0.0, 1.8, 0.9)
	visual_root.add_child(spine)

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

func _physics_process(delta: float) -> void:
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
	if not is_instance_valid(sim_manager):
		return
	Input.vibrate_handheld(80)
	var origin := global_position + Vector3(0.0, 1.4, 0.0)
	for i in range(48):
		var a: float = (float(i) / 48.0) * TAU
		sim_manager.spawn_bullet(origin, Vector3(cos(a), 0.0, sin(a)) * 28.0, 2.5)
