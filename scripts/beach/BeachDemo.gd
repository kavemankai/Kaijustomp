extends Node3D
# Kaijustomp beach vertical slice: intentionally isolated from the old auto-shooter.
# All art is generated as simple low-poly geometry so the game feel can be tested first.

const BASE_HP := 100.0
const BASE_WALK := 11.0
const BASE_STAMINA := 100.0
const SPRINT_MULTIPLIER := 2.35
const SPRINT_BURN_RATE := 35.0
const SPRINT_RECHARGE_RATE := 19.0
const TURN_RESPONSE := 24.0
const BITE_RANGE := 2.85
const BITE_CONE_DOT := 0.53
const BITE_SECONDS := 0.55
const CAMERA_OFFSET := Vector3(14.0, 25.0, 22.0)
const PORTRAIT_CAMERA_DISTANCE := 1.48

var beast: CharacterBody3D
var beast_collision_shape: CapsuleShape3D
var beast_visual: Node3D
var jaw: Node3D
var head_pivot: Node3D
var leg_pivots: Array[Node3D] = []
var tail_pivots: Array[Node3D] = []
var prey_in_mouth: Node3D
var growth_scale := 1.0
var evolution_visual_clock := 0.0
var mutation_visual_counts: Dictionary = {}
var follow_camera: Camera3D
var touch_input: MobileTouchController
var touch_vector := Vector2.ZERO
var sprint_requested := false
var sprint_locked := false
var sprint_active := false
var stamina := BASE_STAMINA
var max_stamina := BASE_STAMINA
var hp := BASE_HP
var max_hp := BASE_HP
var biomass := 0
var evolutions := 0
var armour := 0
var strength := 0
var speed_bonus := 0.0
var bite_duration := BITE_SECONDS
var regeneration := 0
var bite_timer := 0.0
var strike_timer := 0.0
var run_phase := 0.0
var alert := 0.0
var response_clock := 0.0
var game_over := false
var evolving := false
var evolution_clock := 0.0
var evolution_damage := 0.0
var choice_open := false
var reveal_active := false
var evolution_total := 6.0
var evolution_history: Array[Dictionary] = []
var shedding: EvolutionShedding
var camera_celebration_clock := 0.0

var civilians: Array[Dictionary] = []
var officers: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var debris: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
const MAX_PROJECTILES := 72

var ui_layer: CanvasLayer
var stats_label: Label
var sprint_button: Button
var evolve_button: Button
var retry_button: Button
var modal: CenterContainer
var choice_column: VBoxContainer
var evolution_progress: ProgressBar
var reveal_input_layer: Control
var reveal_hint: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 60
	randomize()
	_build_lighting()
	_build_beach()
	_build_creature()
	shedding = EvolutionShedding.new()
	add_child(shedding)
	shedding.reveal_finished.connect(_on_reveal_finished)
	_build_camera()
	_build_population()
	_build_ui()

func _material(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0
	return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, col: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(col)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi

func _sphere(parent: Node3D, pos: Vector3, radius: float, col: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = _material(col)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi

func _build_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.59, 0.76, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.76, 0.76, 0.73)
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false # mobile-first; profile before enabling shadows
	add_child(sun)

func _build_beach() -> void:
	_box(self, Vector3(0, -0.3, -12), Vector3(160, 0.5, 125), Color(0.82, 0.71, 0.48))
	_box(self, Vector3(0, -0.36, 60), Vector3(180, 0.42, 78), Color(0.12, 0.39, 0.59))
	_box(self, Vector3(0, -0.06, -27), Vector3(150, 0.10, 8), Color(0.31, 0.35, 0.37))
	_box(self, Vector3(0, 0.015, -18), Vector3(150, 0.12, 4.5), Color(0.51, 0.42, 0.31))
	_box(self, Vector3(0, -0.08, -51), Vector3(150, 0.14, 39), Color(0.43, 0.48, 0.40))
	for x in range(-6, 7):
		_box(self, Vector3(float(x) * 11.0, 0.02, -27), Vector3(4.2, 0.03, 0.20), Color(0.76, 0.70, 0.50))
	for i in range(16):
		var x := randf_range(-58.0, 58.0)
		var z := randf_range(-8.0, 15.0)
		_box(self, Vector3(x, 0.16, z), Vector3(0.5, 0.32, 0.5), Color(0.52, 0.50, 0.36))
	for p in [Vector3(-32, 0, 7), Vector3(28, 0, 9), Vector3(51, 0, -11)]:
		_sphere(self, p + Vector3(0, 0.85, 0), 1.2, Color(0.39, 0.38, 0.34))
	# Weak beach structures are the first demolition targets; larger buildings
	# require more Strength evolutions. Every structure has baseline occupants.
	_add_building(Vector3(-6, 0, -35), Vector2(5, 5), 2.9, Color(0.71, 0.58, 0.34), "Beach kiosk", 1, 3, 3, 2)
	_add_building(Vector3(7, 0, -47), Vector2(6, 5), 3.1, Color(0.59, 0.51, 0.38), "Wooden shed", 1, 3, 3, 1)
	_add_building(Vector3(-21, 0, -40), Vector2(13, 11), 4.6, Color(0.76, 0.46, 0.34), "Cafe", 2, 5, 4, 5)
	_add_building(Vector3(22, 0, -37), Vector2(10, 9), 4.0, Color(0.55, 0.67, 0.70), "Beach shop", 2, 4, 4, 3)
	_add_building(Vector3(-45, 0, -54), Vector2(14, 12), 7.5, Color(0.65, 0.56, 0.62), "Apartments", 3, 7, 5, 10)
	_add_building(Vector3(45, 0, -54), Vector2(14, 12), 7.0, Color(0.64, 0.62, 0.49), "Hotel", 3, 7, 5, 12)

func _add_building(pos: Vector3, footprint: Vector2, height: float, col: Color, title: String, required_strength: int, hits: int, breakthrough_strength: int, occupants: int) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	_box(root, Vector3(0, height * 0.5, 0), Vector3(footprint.x, height, footprint.y), col)
	_box(root, Vector3(0, height + 0.18, 0), Vector3(footprint.x + 0.5, 0.35, footprint.y + 0.5), col.darkened(0.24))
	for x in [-1.0, 1.0]:
		_box(root, Vector3(x * footprint.x * 0.25, height * 0.60, footprint.y * 0.51), Vector3(1.6, 1.8, 0.14), Color(0.23, 0.37, 0.45))
	# A visible MeshInstance3D is not an obstacle. Physical collision must
	# remain active until the building actually collapses.
	var solid := StaticBody3D.new()
	solid.collision_layer = 1
	solid.collision_mask = 1
	root.add_child(solid)
	var blocker := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(footprint.x, height, footprint.y)
	blocker.shape = shape
	blocker.position.y = height * 0.5
	solid.add_child(blocker)
	buildings.append({
		"node": root, "collider": solid, "position": pos,
		"half": footprint * 0.5, "hits": hits, "destroyed": false,
		"hidden": occupants, "base_occupants": occupants, "name": title,
		"required_strength": required_strength, "breakthrough_strength": breakthrough_strength
	})


func _build_creature() -> void:
	beast = CharacterBody3D.new()
	beast.collision_layer = 1
	beast.collision_mask = 1
	beast.position = Vector3(0, 0, 18)
	add_child(beast)
	# Upright capsule provides swept, orientation-independent wall collision.
	# Its broad footprint protects the head and torso, including while sprinting.
	beast_collision_shape = CapsuleShape3D.new()
	var body_collision := CollisionShape3D.new()
	body_collision.shape = beast_collision_shape
	beast.add_child(body_collision)
	_sync_beast_collision()
	beast_visual = Node3D.new()
	beast.add_child(beast_visual)
	var green := Color(0.22, 0.42, 0.19)
	_box(beast_visual, Vector3(0, 1.02, 0), Vector3(1.75, 1.18, 3.0), green)
	# Four pivoted legs make direction changes read as a scurry, not a sliding tank.
	leg_pivots.clear()
	for x in [-0.78, 0.78]:
		for z in [-0.87, 0.94]:
			var hip := Node3D.new()
			hip.position = Vector3(x, 1.0, z)
			beast_visual.add_child(hip)
			_box(hip, Vector3(0, -0.46, 0), Vector3(0.50, 1.05, 0.58), green.darkened(0.17))
			_box(hip, Vector3(0, -0.96, -0.13), Vector3(0.58, 0.16, 0.65), green.darkened(0.24))
			leg_pivots.append(hip)

	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0, 1.13, -1.22)
	beast_visual.add_child(head_pivot)
	_box(head_pivot, Vector3(0, -0.04, -0.45), Vector3(1.36, 0.74, 1.46), green.lightened(0.10))
	_box(head_pivot, Vector3(0, -0.24, -1.18), Vector3(1.03, 0.31, 0.93), green)
	for x in [-0.48, 0.48]:
		_sphere(head_pivot, Vector3(x, 0.23, -0.85), 0.17, Color(0.96, 0.73, 0.16))
		_sphere(head_pivot, Vector3(x * 0.48, -0.09, -1.61), 0.072, Color(0.10, 0.15, 0.10))
	jaw = Node3D.new()
	jaw.position = Vector3(0, -0.45, -0.95)
	head_pivot.add_child(jaw)
	_box(jaw, Vector3(0, -0.05, -0.25), Vector3(1.04, 0.20, 1.13), Color(0.48, 0.52, 0.28))
	_box(jaw, Vector3(0, 0.06, -0.36), Vector3(0.78, 0.04, 0.76), Color(0.57, 0.18, 0.22))

	# Jointed tail swings opposite the hips at speed.
	tail_pivots.clear()
	var tail_parent: Node3D = beast_visual
	for i in range(3):
		var segment := Node3D.new()
		segment.position = Vector3(0, 0.98 if i == 0 else -0.13, 1.24 if i == 0 else 0.91)
		tail_parent.add_child(segment)
		var taper := 1.0 - float(i) * 0.27
		_box(segment, Vector3(0, 0, 0.39), Vector3(0.86 * taper, 0.62 * taper, 1.06), green.darkened(0.08 + float(i) * 0.06))
		tail_pivots.append(segment)
		tail_parent = segment
	for z in [-0.9, -0.25, 0.42]:
		_box(beast_visual, Vector3(0, 1.67, z), Vector3(0.18, 0.40, 0.25), Color(0.33, 0.51, 0.29))

func _sync_beast_collision() -> void:
	# Keep world-space collision sized to major growth milestones.
	beast_collision_shape.radius = 1.85 * growth_scale
	beast_collision_shape.height = 3.70 * growth_scale
	var shape_node: CollisionShape3D = beast.get_child(0)
	shape_node.position.y = 1.85 * growth_scale


func _build_camera() -> void:
	follow_camera = Camera3D.new()
	add_child(follow_camera)
	follow_camera.fov = 48.0
	follow_camera.near = 0.1
	follow_camera.far = 230.0
	follow_camera.current = true
	follow_camera.global_position = beast.global_position + _camera_offset()
	follow_camera.look_at(beast.global_position + Vector3(0, 0, -2.8), Vector3.UP)

func _camera_offset() -> Vector3:
	# Keep the approved view angle. Pull back in portrait so targets remain
	# visible on the narrower screen without changing movement orientation.
	var viewport_size := get_viewport().get_visible_rect().size
	return CAMERA_OFFSET * (PORTRAIT_CAMERA_DISTANCE if viewport_size.y > viewport_size.x else 1.0)

func _build_population() -> void:
	for i in range(22):
		var pos := Vector3(randf_range(-48, 48), 0, randf_range(-14, 15))
		_spawn_civilian(pos)

func _person(pos: Vector3, uniform: bool = false) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	add_child(node)
	var colour := Color(0.17, 0.28, 0.54) if uniform else Color.from_hsv(randf(), 0.45, 0.82)
	_box(node, Vector3(0, 1.08, 0), Vector3(0.45, 0.83, 0.32), colour)
	_sphere(node, Vector3(0, 1.66, 0), 0.23, Color(0.67, 0.48, 0.35))
	for x in [-0.14, 0.14]:
		_box(node, Vector3(x, 0.36, 0), Vector3(0.15, 0.70, 0.16), colour.darkened(0.25))
	return node

func _spawn_civilian(pos: Vector3) -> void:
	var response := randi_range(0, 2) # flee at once, freeze, or react late
	civilians.append({"node": _person(pos), "speed": randf_range(3.4, 7.1), "response": response, "panic": false, "delay": 0.0, "shelter": randi_range(-1, 1), "direction": Vector3.ZERO})

func _spawn_officer(pos: Vector3, swat: bool = false) -> void:
	var node := _person(pos, true)
	_box(node, Vector3(0, 1.9, 0), Vector3(0.44, 0.18, 0.44), Color(0.12, 0.15, 0.23))
	officers.append({"node": node, "cooldown": randf_range(0.3, 1.4), "swat": swat})

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 2
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)
	touch_input = MobileTouchController.new()
	touch_input.movement_vector_updated.connect(_touch_moved)
	ui_layer.add_child(touch_input)
	stats_label = Label.new()
	stats_label.position = Vector2(18, 30)
	stats_label.add_theme_font_size_override("font_size", 17)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	stats_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stats_label.add_theme_constant_override("shadow_offset_x", 2)
	stats_label.add_theme_constant_override("shadow_offset_y", 2)
	ui_layer.add_child(stats_label)
	evolution_progress = ProgressBar.new()
	evolution_progress.position = Vector2(18, 128)
	evolution_progress.size = Vector2(238, 20)
	evolution_progress.show_percentage = false
	evolution_progress.min_value = 0
	evolution_progress.max_value = 100
	evolution_progress.visible = false
	ui_layer.add_child(evolution_progress)
	sprint_button = Button.new()
	sprint_button.text = "SPRINT"
	_place_right_button(sprint_button, -164, -83)
	sprint_button.pressed.connect(_toggle_sprint)
	sprint_button.add_theme_color_override("font_disabled_color", Color(0.69, 0.68, 0.65))
	evolve_button = Button.new()
	evolve_button.text = "EVOLVE"
	_place_right_button(evolve_button, -253, -174)
	evolve_button.pressed.connect(_start_evolution)
	retry_button = Button.new()
	retry_button.text = "RESTART"
	_place_right_button(retry_button, -342, -263)
	retry_button.visible = false
	retry_button.pressed.connect(func() -> void: get_tree().reload_current_scene())
	modal = CenterContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.visible = false
	ui_layer.add_child(modal)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 0)
	modal.add_child(panel)
	choice_column = VBoxContainer.new()
	choice_column.add_theme_constant_override("separation", 9)
	panel.add_child(choice_column)

	# Full-screen interaction is present only during the safe, paused reveal.
	reveal_input_layer = Control.new()
	reveal_input_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reveal_input_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	reveal_input_layer.visible = false
	reveal_input_layer.gui_input.connect(_on_reveal_input)
	ui_layer.add_child(reveal_input_layer)
	reveal_hint = Label.new()
	reveal_hint.text = "TAP TO BREAK FREE\nOR WATCH THE SKIN SHED"
	reveal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reveal_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	reveal_hint.offset_top = 150
	reveal_hint.offset_bottom = 224
	reveal_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_hint.add_theme_font_size_override("font_size", 23)
	reveal_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	reveal_hint.add_theme_constant_override("shadow_offset_x", 2)
	reveal_hint.add_theme_constant_override("shadow_offset_y", 2)
	reveal_input_layer.add_child(reveal_hint)

func _place_right_button(btn: Button, upper: int, lower: int) -> void:
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left = -150
	btn.offset_right = -18
	btn.offset_top = upper
	btn.offset_bottom = lower
	btn.add_theme_font_size_override("font_size", 19)
	ui_layer.add_child(btn)

func _touch_moved(vector: Vector2) -> void:
	touch_vector = vector

func _toggle_sprint() -> void:
	if game_over or evolving or choice_open or sprint_locked:
		return
	sprint_requested = not sprint_requested

func _cost() -> int:
	return 55 + evolutions * 25

func _physics_process(delta: float) -> void:
	# The root runs during pause for UI, but no enemies, damage or movement do.
	if game_over or choice_open or reveal_active:
		return
	if evolving:
		evolution_clock -= delta
		_update_evolution_animation(delta)
	else:
		_update_movement(delta)
		_update_biting(delta)
		_update_civilians(delta)
		if regeneration > 0:
			hp = minf(max_hp, hp + float(regeneration) * 0.6 * delta)
	_update_police(delta)
	_update_projectiles(delta)
	_update_debris(delta)
	if evolving and evolution_clock <= 0.0 and not game_over:
		_finish_evolution()
	_update_camera(delta)
	_update_hud()

func _update_movement(delta: float) -> void:
	var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var stick := touch_vector if touch_vector.length_squared() > 0.001 else keys
	var right := follow_camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var forward := -follow_camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var direction := right * stick.x - forward * stick.y
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	var moving := direction.length_squared() > 0.003
	if sprint_locked and stamina >= max_stamina - 0.01:
		sprint_locked = false
	sprint_active = sprint_requested and not sprint_locked and moving and stamina > 0.0
	if sprint_active:
		stamina = maxf(0.0, stamina - delta * SPRINT_BURN_RATE)
		if stamina <= 0.0:
			sprint_active = false
			sprint_requested = false
			sprint_locked = true
	else:
		stamina = minf(max_stamina, stamina + delta * SPRINT_RECHARGE_RATE)
	# Input dictates travel instantly. The body turns rapidly to match travel,
	# rather than requiring tank-like rotation before moving.
	var speed := (BASE_WALK + speed_bonus) * (SPRINT_MULTIPLIER if sprint_active else 1.0)
	if bite_timer > 0.0:
		speed *= 0.53
	if moving:
		beast.rotation.y = lerp_angle(beast.rotation.y, atan2(-direction.x, -direction.z), minf(1.0, TURN_RESPONSE * delta))
		var next_pos := beast.global_position + direction * speed * delta
		next_pos.x = clampf(next_pos.x, -70.0, 70.0)
		next_pos.z = clampf(next_pos.z, -67.0, 26.0)
		# move_and_collide performs a swept physics test, including sprint frames.
		# Sliding preserves responsive movement along the face of an obstacle.
		var motion := next_pos - beast.global_position
		var contact := beast.move_and_collide(motion)
		if contact != null:
			var index := _building_for_collider(contact.get_collider())
			if index >= 0:
				var building: Dictionary = buildings[index]
				if strength >= int(building["required_strength"]):
					strike_timer -= delta
					if sprint_active and strength >= int(building["breakthrough_strength"]):
						_damage_building(index, int(building["hits"]))
					elif strike_timer <= 0.0:
						_damage_building(index, 1)
						strike_timer = 0.70
			var slide := contact.get_remainder().slide(contact.get_normal())
			if slide.length_squared() > 0.000001:
				beast.move_and_collide(slide)
		run_phase += delta * (18.0 if sprint_active else 11.0) * maxf(0.4, stick.length())
	strike_timer = maxf(0.0, strike_timer - delta)
	_update_creature_animation(delta, moving)
	bite_timer = maxf(0.0, bite_timer - delta)

func _update_creature_animation(delta: float, moving: bool) -> void:
	var gait_amplitude := (0.74 if sprint_active else 0.45) if moving else 0.0
	for i in range(leg_pivots.size()):
		var phase := run_phase + (0.0 if i == 0 or i == 3 else PI)
		var limb := leg_pivots[i]
		limb.rotation.x = lerpf(limb.rotation.x, sin(phase) * gait_amplitude, minf(1.0, 15.0 * delta))
	var bob := absf(sin(run_phase)) * (0.11 if sprint_active else 0.065) if moving else 0.0
	beast_visual.position.y = lerpf(beast_visual.position.y, bob, minf(1.0, 14.0 * delta))
	beast_visual.rotation.z = lerpf(beast_visual.rotation.z, (0.035 * sin(run_phase * 0.5)) if moving else 0.0, minf(1.0, 8.0 * delta))
	for i in range(tail_pivots.size()):
		var tail := tail_pivots[i]
		tail.rotation.y = lerpf(tail.rotation.y, sin(run_phase * 0.58 - float(i) * 0.65) * (0.15 if sprint_active else 0.09) if moving else 0.0, minf(1.0, 8.0 * delta))

	# Bite cycle: snap forward -> jaws open -> grab -> retract and swallow.
	var progress := 1.0 - clampf(bite_timer / maxf(0.05, bite_duration), 0.0, 1.0)
	var snap := sin(progress * PI) if bite_timer > 0.0 else 0.0
	head_pivot.position.z = -1.22 - 0.67 * snap
	head_pivot.rotation.x = -0.13 * snap
	jaw.rotation.x = -0.85 * maxf(0.0, sin(progress * PI)) if bite_timer > 0.0 else 0.0
	if is_instance_valid(prey_in_mouth):
		prey_in_mouth.position = prey_in_mouth.position.lerp(Vector3(0, -0.43, -1.16), minf(1.0, 18.0 * delta))
		prey_in_mouth.scale = Vector3.ONE * maxf(0.02, 1.0 - progress * 1.2)
		if bite_timer <= delta:
			prey_in_mouth.queue_free()
			prey_in_mouth = null

func _building_for_collider(collider: Object) -> int:
	for i in range(buildings.size()):
		if not buildings[i]["destroyed"] and buildings[i]["collider"] == collider:
			return i
	return -1


func _blocking_building(pos: Vector3) -> int:
	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		if b["destroyed"]:
			continue
		var center: Vector3 = b["position"]
		var half: Vector2 = b["half"]
		if absf(pos.x - center.x) < half.x + 0.70 and absf(pos.z - center.z) < half.y + 0.70:
			return i
	return -1

func _damage_building(index: int, hits: int) -> void:
	var b: Dictionary = buildings[index]
	if b["destroyed"]:
		return
	b["hits"] = int(b["hits"]) - hits
	if b["hits"] <= 0:
		b["destroyed"] = true
		var source: Vector3 = b["position"]
		var root: Node3D = b["node"]
		root.queue_free()
		_make_debris(source, 12)
		alert += 17.0
		# Everyone already inside, plus people who sheltered during the run,
		# is released on collapse. Spawn outside the original footprint.
		var half: Vector2 = b["half"]
		for j in range(int(b["hidden"])):
			var side := j % 4
			var spawn_offset := Vector3.ZERO
			match side:
				0: spawn_offset = Vector3(half.x + 2.0, 0, randf_range(-half.y, half.y))
				1: spawn_offset = Vector3(-half.x - 2.0, 0, randf_range(-half.y, half.y))
				2: spawn_offset = Vector3(randf_range(-half.x, half.x), 0, half.y + 2.0)
				3: spawn_offset = Vector3(randf_range(-half.x, half.x), 0, -half.y - 2.0)
			_spawn_civilian(source + spawn_offset)
		b["hidden"] = 0
		Input.vibrate_handheld(65)
	buildings[index] = b

func _make_debris(at: Vector3, count: int) -> void:
	for i in range(count):
		var root := Node3D.new()
		root.position = at + Vector3(randf_range(-3.0, 3.0), randf_range(0.5, 3.0), randf_range(-3.0, 3.0))
		add_child(root)
		_box(root, Vector3.ZERO, Vector3(0.5, 0.5, 0.5), Color(0.49, 0.42, 0.37))
		debris.append({"node": root, "time": randf_range(0.7, 1.4), "velocity": Vector3(randf_range(-3, 3), randf_range(1, 5), randf_range(-3, 3))})

func _update_debris(delta: float) -> void:
	for i in range(debris.size() - 1, -1, -1):
		var d: Dictionary = debris[i]
		d["time"] = float(d["time"]) - delta
		var root: Node3D = d["node"]
		if d["time"] <= 0:
			root.queue_free()
			debris.remove_at(i)
			continue
		var velocity: Vector3 = d["velocity"]
		velocity.y -= 14.0 * delta
		root.position += velocity * delta
		root.position.y = maxf(0.22, root.position.y)
		d["velocity"] = velocity
		debris[i] = d

func _update_biting(_delta: float) -> void:
	if bite_timer > 0.0:
		return
	var facing := -beast.global_transform.basis.z
	for i in range(civilians.size() - 1, -1, -1):
		var npc: Node3D = civilians[i]["node"]
		var toward := npc.global_position - beast.global_position
		toward.y = 0.0
		if toward.length_squared() <= BITE_RANGE * BITE_RANGE and facing.dot(toward.normalized()) >= BITE_CONE_DOT:
			civilians.remove_at(i)
			_capture_and_feed(npc, 12)
			return
	for i in range(officers.size() - 1, -1, -1):
		var cop: Node3D = officers[i]["node"]
		var toward := cop.global_position - beast.global_position
		toward.y = 0.0
		if toward.length_squared() <= BITE_RANGE * BITE_RANGE and facing.dot(toward.normalized()) >= BITE_CONE_DOT:
			officers.remove_at(i)
			_capture_and_feed(cop, 16)
			return

func _capture_and_feed(prey: Node3D, amount: int) -> void:
	# Remove the target from AI updates immediately, but keep its mesh for
	# the brief jaw-grab/swallow visual instead of making it vanish at contact.
	if is_instance_valid(prey_in_mouth):
		prey_in_mouth.queue_free()
	prey_in_mouth = prey
	prey.reparent(head_pivot, true)
	_feed(amount)

func _feed(amount: int) -> void:
	biomass += amount
	hp = minf(max_hp, hp + 15.0)
	alert += 5.0
	bite_timer = bite_duration
	Input.vibrate_handheld(28)

func _update_civilians(delta: float) -> void:
	for i in range(civilians.size() - 1, -1, -1):
		var c: Dictionary = civilians[i]
		var person: Node3D = c["node"]
		var dist := person.global_position.distance_to(beast.global_position)
		if not c["panic"] and (dist < 13.5 or (alert > 18.0 and dist < 24.0)):
			c["panic"] = true
			c["delay"] = 0.0 if c["response"] == 0 else (0.7 if c["response"] == 1 else 2.5)
		if c["panic"]:
			c["delay"] = maxf(0.0, float(c["delay"]) - delta)
			if c["delay"] <= 0.0:
				var away := person.global_position - beast.global_position
				away.y = 0.0
				away = away.normalized() if away.length_squared() > 0.01 else Vector3(-1, 0, 0)
				var travel := away
				var shelter_index := int(c["shelter"])
				if shelter_index >= 0 and shelter_index < buildings.size() and not buildings[shelter_index]["destroyed"]:
					var target: Vector3 = buildings[shelter_index]["position"]
					travel = (target - person.global_position).normalized()
					if person.global_position.distance_to(target) < 9.0:
						var b: Dictionary = buildings[shelter_index]
						b["hidden"] = int(b["hidden"]) + 1
						buildings[shelter_index] = b
						person.queue_free()
						civilians.remove_at(i)
						continue
				var new_pos := person.global_position + travel * float(c["speed"]) * delta
				new_pos.x = clampf(new_pos.x, -69.0, 69.0)
				new_pos.z = clampf(new_pos.z, -62.0, 23.0)
				if _blocking_building(new_pos) < 0:
					person.global_position = new_pos
				person.rotation.y = atan2(-travel.x, -travel.z)
		civilians[i] = c

func _update_police(delta: float) -> void:
	if alert > 0.0:
		response_clock += delta
	if response_clock > 18.0 and officers.is_empty():
		_spawn_officer(Vector3(-12, 0, -30))
		_spawn_officer(Vector3(12, 0, -30))
		response_clock = -8.0
	if alert > 65.0 and response_clock > 65.0 and officers.size() < 4:
		_spawn_officer(Vector3(-32, 0, -29), true)
		_spawn_officer(Vector3(32, 0, -29), true)
		response_clock = 0.0
	for i in range(officers.size()):
		var cop: Dictionary = officers[i]
		var unit: Node3D = cop["node"]
		var delta_pos := beast.global_position - unit.global_position
		var distance := delta_pos.length()
		if distance > 12.0 and distance < 45.0:
			var step := delta_pos.normalized() * delta * (3.8 if cop["swat"] else 3.0)
			if _blocking_building(unit.global_position + step) < 0:
				unit.global_position += step
		if distance > 0.2:
			unit.rotation.y = atan2(-delta_pos.x, -delta_pos.z)
		if distance < 21.0:
			cop["cooldown"] = float(cop["cooldown"]) - delta
			if cop["cooldown"] <= 0.0:
				# Every shot creates a real moving projectile. Aim error only
				# changes its trajectory; damage happens on physical impact.
				var origin := unit.global_position + Vector3(0, 1.55, 0)
				var aim := beast.global_position + Vector3(0, 1.75 * growth_scale, 0)
				var move_aim := sprint_active or touch_vector.length_squared() > 0.05 or Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").length_squared() > 0.05
				var spread := 2.15 if sprint_active else (1.1 if move_aim else 0.24)
				aim += Vector3(randf_range(-spread, spread), randf_range(-spread * 0.45, spread * 0.45), randf_range(-spread, spread))
				_spawn_projectile(origin, (aim - origin).normalized(), bool(cop["swat"]))
				cop["cooldown"] = 1.3 if cop["swat"] else 2.0
		officers[i] = cop

func _spawn_projectile(origin: Vector3, direction: Vector3, heavy: bool) -> void:
	# A bright tracer is part of the actual projectile, not a cosmetic hitscan.
	# A strict cap prevents gunfire from overloading a low-end Android device.
	if projectiles.size() >= MAX_PROJECTILES:
		var expired: Dictionary = projectiles.pop_front()
		var old_visual: Node3D = expired["node"]
		old_visual.queue_free()
	var tint := Color(1.0, 0.30, 0.12) if heavy else Color(1.0, 0.90, 0.25)
	var travel := direction.normalized()
	var root := Node3D.new()
	root.position = origin
	add_child(root)
	root.look_at(origin + travel, Vector3.UP)
	var streak := BoxMesh.new()
	streak.size = Vector3(0.18, 0.18, 1.0) if heavy else Vector3(0.12, 0.12, 0.75)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	streak.material = mat
	var visual := MeshInstance3D.new()
	visual.mesh = streak
	visual.position.z = 0.40
	root.add_child(visual)
	projectiles.append({
		"node": root, "velocity": travel * (43.0 if heavy else 36.0),
		"damage": 16.0 if heavy else 10.0, "lifetime": 1.8
	})


func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var shot: Dictionary = projectiles[i]
		var visual: Node3D = shot["node"]
		var start: Vector3 = visual.global_position
		var destination: Vector3 = start + Vector3(shot["velocity"]) * delta
		var query := PhysicsRayQueryParameters3D.create(start, destination, 1)
		var result := get_world_3d().direct_space_state.intersect_ray(query)
		shot["lifetime"] = float(shot["lifetime"]) - delta
		if not result.is_empty():
			visual.global_position = result["position"]
			if result["collider"] == beast:
				_take_damage(float(shot["damage"]))
			# Any intact building intercepts shots; no damage passes through.
			visual.queue_free()
			projectiles.remove_at(i)
		elif shot["lifetime"] <= 0.0:
			visual.queue_free()
			projectiles.remove_at(i)
		else:
			visual.global_position = destination
			projectiles[i] = shot


func _take_damage(raw: float) -> void:
	if game_over:
		return
	var damage := raw * pow(0.78, armour)
	hp = maxf(0.0, hp - damage)
	Input.vibrate_handheld(35)
	if evolving:
		evolution_damage += damage
	if hp <= 0.0:
		game_over = true
		if evolving:
			_reset_evolution_pose()
			shedding.abort_shed()
		evolving = false
		retry_button.visible = true
	elif evolving and evolution_damage >= 35.0:
		_reset_evolution_pose()
		shedding.abort_shed()
		evolving = false
		biomass = 0
		evolution_damage = 0.0

func _update_evolution_animation(delta: float) -> void:
	# Readable pulsing/shivering while the player is vulnerable. Temporary
	# pose changes cannot overwrite accumulated physical growth.
	evolution_visual_clock += delta
	var beat := sin(evolution_visual_clock * 11.0)
	beast_visual.position.y = -0.12 + 0.045 * beat
	beast_visual.rotation.z = beat * 0.025
	beast_visual.scale = Vector3.ONE * growth_scale * (1.0 + 0.018 * maxf(0.0, beat))
	head_pivot.rotation.x = 0.07 * sin(evolution_visual_clock * 8.0)
	shedding.update_shed_progress(1.0 - evolution_clock / maxf(0.01, evolution_total))

func _reset_evolution_pose() -> void:
	beast_visual.position = Vector3.ZERO
	beast_visual.rotation.z = 0.0
	beast_visual.scale = Vector3.ONE * growth_scale
	head_pivot.rotation.x = 0.0

func _start_evolution() -> void:
	if game_over or evolving or choice_open or reveal_active or biomass < _cost():
		return
	evolving = true
	sprint_requested = false
	sprint_active = false
	evolution_damage = 0.0
	evolution_visual_clock = 0.0
	evolution_total = 6.0 + float(evolutions) * 1.5
	evolution_clock = evolution_total
	shedding.begin_shed(beast_visual)

func _finish_evolution() -> void:
	evolving = false
	_reset_evolution_pose()
	choice_open = true
	get_tree().paused = true
	modal.visible = true
	for child in choice_column.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = "SKIN READY TO SHED\nChoose ONE mutation"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_column.add_child(header)
	var history_label := Label.new()
	history_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history_label.add_theme_font_size_override("font_size", 14)
	history_label.text = _evolution_history_summary()
	choice_column.add_child(history_label)
	var pool: Array[Dictionary] = [
		{"id": "armour", "name": "Hardened Scales", "detail": "Reduce incoming damage"},
		{"id": "speed", "name": "Fleet Limbs", "detail": "Run faster"},
		{"id": "stamina", "name": "Endurance", "detail": "Larger sprint reserve"},
		{"id": "jaw", "name": "Rapid Feeding", "detail": "Shorter feeding slowdown"},
		{"id": "strength", "name": "Brutal Strength", "detail": "Start damaging building walls"},
		{"id": "health", "name": "Dense Flesh", "detail": "Increase maximum health"}
	]
	if evolutions >= 2:
		pool.append({"id": "regen", "name": "Regeneration", "detail": "Recover health over time"})
	pool.shuffle()
	var extra := maxi(0, int((biomass - _cost()) / 30.0))
	var number_of_choices := mini(pool.size(), 3 + extra)
	for i in range(number_of_choices):
		var mutation: Dictionary = pool[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(300, 48)
		button.text = "%s\n%s" % [mutation["name"], mutation["detail"]]
		button.pressed.connect(_choose_mutation.bind(String(mutation["id"])))
		choice_column.add_child(button)

func _choose_mutation(id: String) -> void:
	if not choice_open:
		return
	match id:
		"armour": armour += 1
		"speed": speed_bonus += 1.6
		"stamina": max_stamina += 35.0
		"jaw": bite_duration = maxf(0.23, bite_duration * 0.78)
		"strength": strength += 1
		"health": max_hp += 25.0
		"regen": regeneration += 1
	_apply_mutation_visual(id)
	_record_evolution(id)
	biomass = maxi(0, biomass - _cost())
	evolutions += 1
	hp = max_hp
	stamina = max_stamina
	sprint_locked = false
	sprint_requested = false
	if evolutions % 3 == 0:
		growth_scale *= 1.25
		_sync_beast_collision()
	beast_visual.scale = Vector3.ONE * growth_scale
	choice_open = false
	modal.visible = false
	reveal_active = true
	reveal_input_layer.visible = true
	shedding.start_reveal()
	# Remain paused until the new form is fully revealed.
	touch_input.reset_input()

func _evolution_label(id: String) -> String:
	match id:
		"armour": return "Hardened Scales"
		"speed": return "Fleet Limbs"
		"stamina": return "Endurance"
		"jaw": return "Rapid Feeding"
		"strength": return "Brutal Strength"
		"health": return "Dense Flesh"
		"regen": return "Regeneration"
	return id


func _record_evolution(id: String) -> void:
	# Ordered entries deliberately retain the mutation ID and size milestone:
	# these will form the nodes/edges of the future evolution tree or web.
	evolution_history.append({
		"step": evolutions + 1,
		"mutation_id": id,
		"label": _evolution_label(id),
		"growth_milestone": int((evolutions + 1) / 3)
	})


func _evolution_history_summary() -> String:
	if evolution_history.is_empty():
		return "YOUR EVOLUTION PATH\nFirst adaptation"
	var summary := "YOUR EVOLUTION PATH"
	var start := maxi(0, evolution_history.size() - 4)
	for i in range(start, evolution_history.size()):
		var item: Dictionary = evolution_history[i]
		summary += "\n%d  %s" % [int(item["step"]), String(item["label"])]
	return summary


func _on_reveal_input(event: InputEvent) -> void:
	if not reveal_active:
		return
	if event is InputEventScreenTouch and event.pressed:
		shedding.accelerate_reveal()
		reveal_input_layer.accept_event()
	elif event is InputEventMouseButton and event.pressed:
		shedding.accelerate_reveal()
		reveal_input_layer.accept_event()


func _on_reveal_finished() -> void:
	reveal_active = false
	reveal_input_layer.visible = false
	reveal_hint.text = "TAP TO BREAK FREE\nOR WATCH THE SKIN SHED"
	camera_celebration_clock = 0.22
	Input.vibrate_handheld(85)
	get_tree().paused = false
	touch_input.reset_input()


func _apply_mutation_visual(id: String) -> void:
	# Each chosen mutation adds a *small* persistent physical detail.
	# Repeating one mutation adds further details instead of replacing
	# the creature or changing its overall size.
	var stage := int(mutation_visual_counts.get(id, 0))
	mutation_visual_counts[id] = stage + 1
	var slot := stage % 5
	var tier := floori(float(stage) / 5.0)
	var lift := minf(0.20, float(tier) * 0.065)
	match id:
		"armour":
			for side in [-1.0, 1.0]:
				_box(beast_visual,
					Vector3(side * 0.54, 1.64 + lift, -0.96 + float(slot) * 0.48),
					Vector3(0.42, 0.13, 0.32),
					Color(0.33, 0.48, 0.29).darkened(minf(0.28, float(tier) * 0.08)))
		"speed":
			# New tendon markings along the outer edge of each moving leg.
			for hip in leg_pivots:
				_box(hip,
					Vector3(0, -0.23 - float(slot % 3) * 0.22, -0.31 - lift),
					Vector3(0.37, 0.10, 0.12),
					Color(0.60, 0.68, 0.26))
		"stamina":
			for side in [-1.0, 1.0]:
				_box(beast_visual,
					Vector3(side * (0.90 + lift), 1.15, -0.96 + float(slot) * 0.46),
					Vector3(0.10, 0.26, 0.23),
					Color(0.47, 0.65, 0.24))
		"jaw":
			for side in [-1.0, 1.0]:
				_box(head_pivot,
					Vector3(side * 0.53, -0.24, -0.54 - float(slot) * 0.23),
					Vector3(0.16, 0.20 + lift, 0.17),
					Color(0.74, 0.72, 0.53))
		"strength":
			for index in [0, 2]:
				var foreleg := leg_pivots[index]
				for claw in [-1.0, 0.0, 1.0]:
					_box(foreleg,
						Vector3(claw * 0.17, -1.02, -0.34 - float(slot) * 0.075),
						Vector3(0.10, 0.13 + lift, 0.23),
						Color(0.72, 0.68, 0.46))
		"health":
			for side in [-1.0, 1.0]:
				_sphere(beast_visual,
					Vector3(side * 0.83, 1.10, -0.94 + float(slot) * 0.47),
					0.17 + lift * 0.14,
					Color(0.28, 0.46, 0.22))
		"regen":
			for side in [-1.0, 1.0]:
				_sphere(beast_visual,
					Vector3(side * 0.32, 1.68 + lift, -1.00 + float(slot) * 0.47),
					0.13,
					Color(0.55, 0.86, 0.43))

func _update_camera(delta: float) -> void:
	var goal := beast.global_position + _camera_offset()
	if camera_celebration_clock > 0.0:
		camera_celebration_clock = maxf(0.0, camera_celebration_clock - delta)
		goal.x += sin(camera_celebration_clock * 90.0) * camera_celebration_clock * 0.50
		goal.z += cos(camera_celebration_clock * 75.0) * camera_celebration_clock * 0.35
	follow_camera.global_position = follow_camera.global_position.lerp(goal, minf(1.0, 6.0 * delta))
	follow_camera.look_at(beast.global_position + Vector3(0, 0, -2.8), Vector3.UP)

func _update_hud() -> void:
	var status := "EVOLVING %.1fs  |  DAMAGE %.0f/35" % [evolution_clock, evolution_damage] if evolving else ("GAME OVER" if game_over else "Hunt / feed / escape / evolve")
	stats_label.text = "HP %d/%d    BIOMASS %d/%d\nSTAMINA %d%%    EVOLUTIONS %d\n%s" % [
		int(ceil(hp)), int(max_hp), biomass, _cost(), int(100.0 * stamina / max_stamina), evolutions, status
	]
	evolve_button.visible = not evolving and not game_over and biomass >= _cost()
	evolution_progress.visible = evolving
	if evolving:
		evolution_progress.value = 100.0 * (1.0 - evolution_clock / maxf(0.01, evolution_total))
	sprint_button.disabled = evolving or game_over or sprint_locked
	if sprint_locked:
		sprint_button.text = "RECHARGING\n%d%%" % int(100.0 * stamina / max_stamina)
		sprint_button.modulate = Color(0.48, 0.48, 0.48)
	elif sprint_requested:
		sprint_button.text = "SPRINT ON"
		sprint_button.modulate = Color(0.30, 0.98, 0.74)
	else:
		sprint_button.text = "SPRINT"
		sprint_button.modulate = Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and reveal_active:
			shedding.accelerate_reveal()
		elif event.keycode == KEY_E:
			_start_evolution()
		elif event.keycode == KEY_SHIFT:
			_toggle_sprint()
		elif event.keycode == KEY_R and game_over:
			get_tree().reload_current_scene()
