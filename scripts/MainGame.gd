extends Node3D

var sim_manager: SimulationManager
var city_manager: DynamicCityManager
var player: KaijuPlayer
var debug_label: Label

func _ready() -> void:
	Engine.max_fps = 60
	_setup_lighting()
	_setup_game_systems()
	_setup_post_processing_and_ui()

func _setup_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.45, 0.55)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)

func _setup_game_systems() -> void:
	sim_manager = SimulationManager.new()
	add_child(sim_manager)
	
	city_manager = DynamicCityManager.new()
	city_manager.sim_manager = sim_manager
	add_child(city_manager)
	
	player = KaijuPlayer.new()
	player.sim_manager = sim_manager
	player.city_manager = city_manager
	add_child(player)
	
	sim_manager.player_ref = player
	sim_manager.city_ref = city_manager

func _setup_post_processing_and_ui() -> void:
	var post_layer := CanvasLayer.new()
	post_layer.layer = 1
	add_child(post_layer)
	
	var dither_rect := ColorRect.new()
	dither_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dither_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var post_mat := ShaderMaterial.new()
	post_mat.shader = load("res://shaders/ps1_postprocess.gdshader") as Shader
	dither_rect.material = post_mat
	post_layer.add_child(dither_rect)
	
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 2
	add_child(ui_layer)
	
	var touch_ctrl := MobileTouchController.new()
	touch_ctrl.movement_vector_updated.connect(player.set_movement_vector)
	touch_ctrl.tap_action_triggered.connect(player.trigger_atomic_nova)
	ui_layer.add_child(touch_ctrl)
	
	debug_label = Label.new()
	debug_label.position = Vector2(20, 20)
	debug_label.add_theme_font_size_override("font_size", 18)
	ui_layer.add_child(debug_label)

func _process(_delta: float) -> void:
	if is_instance_valid(debug_label) and is_instance_valid(sim_manager):
		debug_label.text = "FPS: %d | Active Horde: %d | Left Drag: Move Kaiju | Right Tap: Atomic Nova" % [
			Engine.get_frames_per_second(),
			sim_manager.active_enemy_count
		]
