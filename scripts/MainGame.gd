extends Node3D

var progression: ProgressionManager
var audio_bank: RetroAudioBank
var sim_manager: SimulationManager
var city_manager: DynamicCityManager
var player: KaijuPlayer
var touch_ctrl: MobileTouchController
var debug_label: Label
var modal_ui: MutationAndLabUI

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
	progression = ProgressionManager.new()
	add_child(progression)
	
	audio_bank = RetroAudioBank.new()
	add_child(audio_bank)
	
	sim_manager = SimulationManager.new()
	sim_manager.audio_bank = audio_bank
	sim_manager.progression = progression
	add_child(sim_manager)
	
	city_manager = DynamicCityManager.new()
	city_manager.sim_manager = sim_manager
	city_manager.audio_bank = audio_bank
	add_child(city_manager)
	
	player = KaijuPlayer.new()
	player.sim_manager = sim_manager
	player.city_manager = city_manager
	player.audio_bank = audio_bank
	player.progression = progression
	player.player_died.connect(_on_player_died)
	player.level_up_ready.connect(_on_player_level_up)
	add_child(player)
	
	sim_manager.player_ref = player
	sim_manager.city_ref = city_manager
	sim_manager.nav_map_rid = city_manager.get_nav_map_rid()

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
	
	touch_ctrl = MobileTouchController.new()
	touch_ctrl.movement_vector_updated.connect(player.set_movement_vector)
	touch_ctrl.tap_action_triggered.connect(player.trigger_atomic_nova)
	ui_layer.add_child(touch_ctrl)
	
	debug_label = Label.new()
	debug_label.position = Vector2(20, 16)
	debug_label.add_theme_font_size_override("font_size", 17)
	ui_layer.add_child(debug_label)
	
	modal_ui = MutationAndLabUI.new()
	modal_ui.progression = progression
	modal_ui.player_ref = player
	modal_ui.sim_ref = sim_manager
	modal_ui.mutation_selected.connect(_on_mutation_selected)
	modal_ui.revive_requested.connect(_on_revive_requested)
	modal_ui.restart_requested.connect(_restart_game)
	ui_layer.add_child(modal_ui)

func _on_player_level_up(new_level: int) -> void:
	modal_ui.show_level_up(new_level)

func _on_mutation_selected(mutation_id: String) -> void:
	player.apply_mutation(mutation_id)
	# The touch controller is paused during the draft and misses the finger-up, so clear its stale joystick.
	touch_ctrl.reset_input()

func _on_player_died() -> void:
	touch_ctrl.reset_input()
	modal_ui.show_game_over_lab()

func _on_revive_requested() -> void:
	player.revive_with_defibrillator()

func _restart_game() -> void:
	sim_manager.reset_simulation()
	city_manager.reset_city()
	player.reset_player()

func _process(_delta: float) -> void:
	if is_instance_valid(debug_label) and is_instance_valid(sim_manager) and is_instance_valid(player):
		var nova_text: String = "READY" if player.nova_timer <= 0.0 else "%.1fs" % player.nova_timer
		debug_label.text = "HP: %d/%d | Lv.%d (XP %d/%d) | DEFCON %d | Kills: %d | G-Cells: %d | Nova: %s | FPS: %d" % [
			int(ceil(player.hp)),
			int(player.max_hp),
			player.level,
			player.xp,
			player.xp_to_next,
			sim_manager.defcon_level,
			sim_manager.total_kills,
			progression.g_cells,
			nova_text,
			Engine.get_frames_per_second()
		]
