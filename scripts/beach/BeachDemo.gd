extends Node3D
# Kaijustomp beach vertical slice: intentionally isolated from the old auto-shooter.
# Authored hero assets and a coastal art layer preserve the approved gameplay contract.

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
var head_collision_shape: SphereShape3D
var head_collision_node: CollisionShape3D
var body_collision_node: CollisionShape3D
var beast_visual: Node3D
var jaw: Node3D
var head_pivot: Node3D
var leg_pivots: Array[Node3D] = []
var tail_pivots: Array[Node3D] = []
var creature_rig: Dictionary = {}
var creature_idle_clock := 0.0
var growth_stage := 0
var upright_form := false
var torso_pivot: Node3D
var body_art_anchor: Node3D
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
var cocoon_rank := 0
var metamorphosis_rank := 0
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
const NEIGHBOURHOOD_FAR_Z := -512.0
const SHOPPING_DISTRICT_Z := -320.0
var evolution_history: Array[Dictionary] = []
var shedding: EvolutionShedding
var camera_celebration_clock := 0.0

var civilians: Array[Dictionary] = []
var officers: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var debris: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var cars: Array[Dictionary] = []
const MAX_CARS := 20
const MAX_PROJECTILES := 72
# Seven coastal districts give roughly eight times the original 140-unit beach.
const COAST_HALF_LENGTH := 560.0
const PLAYABLE_HALF_LENGTH := 548.0
const ACTIVE_POPULATION_TARGET := 34
const MAX_ACTIVE_CIVILIANS := 42
const POPULATION_REFRESH_SECONDS := 1.7
var population_clock := 0.0

var ui_layer: CanvasLayer
var stats_label: Label
var sprint_button: Button
var evolve_button: Button
var retry_button: Button
var debug_evolve_button: Button
var modal_shade: ColorRect
var modal: CenterContainer
var choice_column: VBoxContainer
var evolution_progress: ProgressBar
var reveal_input_layer: Control
var reveal_hint: Label
var coastal_hud: CoastalHUD
var sun_light: DirectionalLight3D
var ground_shadow: MeshInstance3D
var coastal_effects: CoastalEffects
var previous_step := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 60
	randomize()
	_build_lighting()
	_build_beach()
	_build_cars()
	_build_creature()
	shedding = EvolutionShedding.new()
	add_child(shedding)
	shedding.reveal_finished.connect(_on_reveal_finished)
	_build_camera()
	_build_population()
	_build_ui()
	coastal_effects = CoastalEffects.new()
	add_child(coastal_effects)

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
	env.background_color = Color("b2c9c6")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c7ddd8")
	env.ambient_light_energy = 0.65
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.0
	sun.light_color = Color("fff1d4")
	sun_light = sun
	sun.shadow_enabled = false # mobile-first; profile before enabling shadows
	add_child(sun)

func _build_beach() -> void:
	var beach_width := COAST_HALF_LENGTH * 2.0 + 40.0
	_box(self, Vector3(0, -0.3, -24), Vector3(beach_width, 0.5, 100), Color("d9c79e"))
	_box(self, Vector3(0, -0.06, -27), Vector3(beach_width, 0.10, 8), Color("687a7a"))
	_box(self, Vector3(0, 0.015, -18), Vector3(beach_width, 0.12, 4.5), Color("c8bea5"))
	_box(self, Vector3(0, -0.08, -51), Vector3(beach_width, 0.14, 39), Color("94a18a"))
	for x in range(-int(COAST_HALF_LENGTH / 11.0), int(COAST_HALF_LENGTH / 11.0) + 1):
		_box(self, Vector3(float(x) * 11.0, 0.02, -27), Vector3(4.2, 0.03, 0.20), Color(0.76, 0.70, 0.50))
	CoastalArt.scenery(self, COAST_HALF_LENGTH)
	CoastalArt.neighbourhood(self)
	# Weak beach structures are the first demolition targets; larger buildings
	# require more Strength evolutions. Every structure has baseline occupants.
	_add_building(Vector3(-6, 0, -35), Vector2(5, 5), 2.9, Color(0.71, 0.58, 0.34), "Beach kiosk", 1, 3, 3, 2)
	_add_building(Vector3(7, 0, -47), Vector2(6, 5), 3.1, Color(0.59, 0.51, 0.38), "Wooden shed", 1, 3, 3, 1)
	_add_building(Vector3(-21, 0, -40), Vector2(13, 11), 4.6, Color(0.76, 0.46, 0.34), "Cafe", 2, 5, 4, 5)
	_add_building(Vector3(22, 0, -37), Vector2(10, 9), 4.0, Color(0.55, 0.67, 0.70), "Beach shop", 2, 4, 4, 3)
	_add_building(Vector3(-45, 0, -54), Vector2(14, 12), 7.5, Color(0.65, 0.56, 0.62), "Apartments", 3, 7, 5, 10)
	_add_building(Vector3(45, 0, -54), Vector2(14, 12), 7.0, Color(0.64, 0.62, 0.49), "Hotel", 3, 7, 5, 12)
	# Keep the proven first six buildings intact. Six additional coastal districts
	# spread weak and strong structures along both directions of the beach.
	for district in [-3, -2, -1, 1, 2, 3]:
		var anchor := float(district) * 150.0
		var stagger := float(absi(district) % 2) * 4.0
		_add_building(Vector3(anchor - 35, 0, -35 - stagger), Vector2(5, 5), 2.9, Color(0.71, 0.58, 0.34), "Beach kiosk", 1, 3, 3, 2)
		_add_building(Vector3(anchor + 4, 0, -44), Vector2(6, 5), 3.1, Color(0.59, 0.51, 0.38), "Wooden shed", 1, 3, 3, 1)
		_add_building(Vector3(anchor - 9, 0, -58), Vector2(12, 10), 4.6, Color(0.76, 0.46, 0.34), "Cafe", 2, 5, 4, 5)
		_add_building(Vector3(anchor + 36, 0, -53), Vector2(11, 10), 4.0, Color(0.55, 0.67, 0.70), "Beach shop", 2, 4, 4, 3)
		_add_building(Vector3(anchor - 54, 0, -55), Vector2(14, 12), 7.5, Color(0.65, 0.56, 0.62), "Apartments", 3, 7, 5, 10)
	# First inland suburb: a connected road behind the promenade, not a new
	# game scene or teleport. Leave the original beach layout untouched.
	for row in range(3):
		for column in range(6):
			var at := Vector3(-90.0 + float(column) * 36.0, 0, -109.0 - float(row) * 44.0)
			var colour := Color("e4c8a6") if (column + row) % 3 == 0 else (Color("cfdfcd") if (column + row) % 3 == 1 else Color("d3d5df"))
			_add_building(at, Vector2(13, 12), 4.1 + float((column + row) % 2) * 0.6, colour,
				"Coastal home", 2 if row < 2 else 3, 5 if row < 2 else 6, 4 if row < 2 else 5, 4 + (column + row) % 3)
	# Expand further inland with two new residential streets. Keep the original
	# 54 structures and their indices untouched for gameplay/tests.
	for row in range(2):
		for column in range(6):
			var at := Vector3(-90.0 + float(column) * 36.0, 0, -243.0 - float(row) * 44.0)
			var colour := Color("e2d9bf") if (column + row) % 2 == 0 else Color("c0d6d1")
			_add_building(at, Vector2(13, 12), 4.3, colour, "Coastal home", 3, 6, 5, 5)
	# Connected main-street shopping: 12 small premises and two bigger stores.
	var businesses := ["Bakery", "Chemist", "Fish & Chips", "Bookshop", "Greengrocer", "Takeaway",
		"Coffee Bar", "Surf Outlet", "Florist", "Newsagent", "Corner Mart", "Pet Shop"]
	for row in range(2):
		for column in range(6):
			var at := Vector3(-105.0 + float(column) * 42.0, 0, -352.0 - float(row) * 52.0)
			var name: String = businesses[row * 6 + column]
			_add_building(at, Vector2(18, 15), 5.6, Color("d9c3a2"), name, 3, 7, 5, 5)
	for side in [-1.0, 1.0]:
		var at := Vector3(side * 75.0, 0, -468.0)
		_add_building(at, Vector2(31, 22), 7.5, Color("becbc3"),
			"Supermarket" if side < 0 else "Hardware Store", 4, 11, 6, 12)


# Vehicles are bounded, collidable world objects, not scenery you walk through.
# Four animate on local roads; the remaining twelve are parked at the shops.
func _build_cars() -> void:
	var colours := [Color("bf6555"), Color("e6d6b0"), Color("668d9b"), Color("a5b39b")]
	for index in range(4):
		var x := -3.25 if index % 2 == 0 else 3.25
		var z := [-127.0, -225.0, -337.0, -446.0][index]
		_add_car(Vector3(x, 0, z), true, -1 if index % 2 == 0 else 1, colours[index])
	for z in [-346.0, -401.0]:
		for x in [-9.0, 9.0]:
			_add_car(Vector3(x, 0, z), false, 0, colours[absi(int(x + z)) % colours.size()])
	for z in [-451.0, -482.0]:
		for x in [-47.0, -33.0, 33.0, 47.0]:
			_add_car(Vector3(x, 0, z), false, 0, colours[absi(int(x + z)) % colours.size()])


func _add_car(pos: Vector3, moving: bool, direction: int, colour: Color) -> void:
	assert(cars.size() < MAX_CARS)
	var root := Node3D.new()
	root.name = "MovingCar" if moving else "ParkedCar"
	root.position = pos
	root.rotation.y = PI if moving and direction > 0 else 0.0
	add_child(root)
	CoastalArt.car(root, colour)
	var solid := AnimatableBody3D.new()
	solid.collision_layer = 1
	solid.collision_mask = 1
	root.add_child(solid)
	var shape := CollisionShape3D.new()
	var body := BoxShape3D.new()
	body.size = Vector3(2.25, 1.65, 4.65)
	shape.shape = body
	shape.position.y = .825
	solid.add_child(shape)
	cars.append({"node":root, "collider":solid, "moving":moving, "direction":direction,
		"speed":6.0, "hits":3.0, "destroyed":false})


func _car_for_collider(collider: Object) -> int:
	for i in range(cars.size()):
		if not bool(cars[i]["destroyed"]) and cars[i]["collider"] == collider:
			return i
	return -1


func _attack_car(index: int, sprinting: bool) -> void:
	var car: Dictionary = cars[index]
	if car["destroyed"]:
		return
	if sprinting and strength >= 2:
		_damage_car(index, float(car["hits"]))
	elif strike_timer <= 0.0:
		_damage_car(index, 1.0 + float(strength) * 1.2)
		strike_timer = 0.55


func _damage_car(index: int, amount: float) -> void:
	var car: Dictionary = cars[index]
	if car["destroyed"]:
		return
	car["hits"] = float(car["hits"]) - amount
	if car["hits"] <= 0.0:
		car["destroyed"] = true
		var at: Vector3 = car["node"].global_position
		car["node"].queue_free()
		_make_debris(at, 8)
		alert += 7.0
		# The driver flees the wreck and becomes a normal edible pedestrian.
		_spawn_civilian(at + Vector3(3.7, 0, 2.7))
	cars[index] = car


func _update_cars(delta: float) -> void:
	for i in range(cars.size()):
		var car: Dictionary = cars[i]
		if car["destroyed"] or not car["moving"]:
			continue
		var node: Node3D = car["node"]
		if node.global_position.distance_to(beast.global_position) > 125.0:
			continue
		var direction := int(car["direction"])
		if node.position.z < -488.0:
			direction = 1
		elif node.position.z > -96.0:
			direction = -1
		car["direction"] = direction
		node.rotation.y = PI if direction > 0 else 0.0
		# Cars stop rather than intersecting a player on foot; the player can
		# damage them with the same walk/sprint contact controls as buildings.
		var candidate := node.position + Vector3(0, 0, float(direction) * float(car["speed"]) * delta)
		if candidate.distance_to(beast.global_position) > 5.0 + growth_scale and _blocking_building(candidate) < 0:
			node.position = candidate
		cars[i] = car


func _add_building(pos: Vector3, footprint: Vector2, height: float, col: Color, title: String, required_strength: int, hits: int, breakthrough_strength: int, occupants: int) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	if title == "Coastal home":
		CoastalArt.home(root, footprint, height, col)
	elif title in ["Bakery", "Chemist", "Fish & Chips", "Bookshop", "Greengrocer", "Takeaway",
		"Coffee Bar", "Surf Outlet", "Florist", "Newsagent", "Corner Mart", "Pet Shop",
		"Supermarket", "Hardware Store"]:
		CoastalArt.shop(root, footprint, height, title)
	else:
		CoastalArt.building(root, footprint, height, title)
	# A visible MeshInstance3D is not an obstacle. Physical collision must
	# remain active until the building actually collapses.
	var crack_layers := _build_building_cracks(root, footprint, height)
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
		"half": footprint * 0.5, "hits": float(hits), "max_hits": float(hits),
		"crack_layers": crack_layers, "crack_stage": 0, "destroyed": false,
		"hidden": occupants, "base_occupants": occupants, "name": title,
		"required_strength": required_strength, "breakthrough_strength": breakthrough_strength
	})


# Each crack stage is added only as the building is hit. Keep them slightly
# proud of the four wall surfaces so they remain visible without z-fighting.
func _build_building_cracks(root: Node3D, footprint: Vector2, height: float) -> Array[Node3D]:
	var stages: Array[Node3D] = []
	for stage in range(3):
		var layer := Node3D.new()
		layer.name = "CracksStage%d" % (stage + 1)
		layer.visible = false
		root.add_child(layer)
		for face in range(4):
			for fork in range(stage + 2):
				var u := (float(fork) - float(stage + 1) * 0.5) * 0.24
				var y := height * (0.72 - float(fork) * 0.105)
				var crack_len := minf(0.72, height * 0.19)
				for segment in range(2):
					var diagonal := 0.48 if (fork + segment + face) % 2 == 0 else -0.40
					var offset := float(segment) * crack_len * 0.23
					var ink := Color(0.17, 0.14, 0.13)
					if face < 2:
						var z := (footprint.y * 0.5 + 0.075) * (1.0 if face == 0 else -1.0)
						var x := u * footprint.x + offset * diagonal
						var line := _box(layer, Vector3(x, clampf(y - offset, 0.18, height - 0.14), z), Vector3(0.065, crack_len * 0.65, 0.045), ink)
						line.rotation.z = diagonal
					else:
						var x := (footprint.x * 0.5 + 0.075) * (1.0 if face == 2 else -1.0)
						var z := u * footprint.y + offset * diagonal
						var side_line := _box(layer, Vector3(x, clampf(y - offset, 0.18, height - 0.14), z), Vector3(0.045, crack_len * 0.65, 0.065), ink)
						side_line.rotation.x = diagonal
		CoastalArt.merge(layer, "Fractures")
		stages.append(layer)
	return stages


func _build_creature() -> void:
	beast = CharacterBody3D.new()
	beast.collision_layer = 1
	beast.collision_mask = 1
	beast.position = Vector3(0, 0, 18)
	add_child(beast)
	# Approved swept collision, body physics and snout extension untouched.
	beast_collision_shape = CapsuleShape3D.new()
	body_collision_node = CollisionShape3D.new()
	body_collision_node.shape = beast_collision_shape
	beast.add_child(body_collision_node)
	head_collision_shape = SphereShape3D.new()
	head_collision_node = CollisionShape3D.new()
	head_collision_node.shape = head_collision_shape
	beast.add_child(head_collision_node)
	_sync_beast_collision()

	beast_visual = Node3D.new()
	beast.add_child(beast_visual)
	leg_pivots.clear()
	for x in [-0.78, 0.78]:
		for z in [-0.87, 0.94]:
			var hip := Node3D.new()
			hip.position = Vector3(x, 1.0, z)
			beast_visual.add_child(hip)
			leg_pivots.append(hip)
	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0, 1.13, -1.22)
	beast_visual.add_child(head_pivot)
	jaw = Node3D.new()
	jaw.position = Vector3(0, -0.45, -0.95)
	head_pivot.add_child(jaw)
	tail_pivots.clear()
	var tail_parent: Node3D = beast_visual
	for i in range(3):
		var segment := Node3D.new()
		segment.position = Vector3(0, 0.98 if i == 0 else -0.13, 1.24 if i == 0 else 0.91)
		tail_parent.add_child(segment)
		tail_pivots.append(segment)
		tail_parent = segment
	# No new collision objects or extra gameplay behaviours: only hero artwork.
	creature_rig = StylizedCreatureArt.build(beast_visual, head_pivot, jaw, leg_pivots, tail_pivots)
	# An independent upper-body joint lets the major level-22 evolution raise
	# the shoulders, head and front limbs into an upright stance. At 0 degrees
	# it is exactly the established quadruped rig.
	torso_pivot = Node3D.new()
	torso_pivot.name = "MajorFormPosture"
	torso_pivot.position = Vector3(0, 0.95, 0.75)
	beast_visual.add_child(torso_pivot)
	body_art_anchor = Node3D.new()
	body_art_anchor.name = "BodyArtSpace"
	body_art_anchor.position = -torso_pivot.position
	torso_pivot.add_child(body_art_anchor)
	var chest: Node3D = creature_rig.get("breathing")
	if is_instance_valid(chest):
		chest.reparent(body_art_anchor, true)
	head_pivot.reparent(body_art_anchor, true)
	leg_pivots[0].reparent(body_art_anchor, true)
	leg_pivots[2].reparent(body_art_anchor, true)
	creature_rig["visual"].update_pose(false)
	ground_shadow = CoastalArt.shadow(beast, Vector2(3.1, 6.7), Vector3(0,0,.35))

func _sync_beast_collision() -> void:
	# Keep world-space collision sized to major growth milestones.
	beast_collision_shape.radius = 1.85 * growth_scale
	beast_collision_shape.height = 3.70 * growth_scale
	body_collision_node.position.y = 1.85 * growth_scale
	head_collision_shape.radius = 0.82 * growth_scale
	head_collision_node.position = Vector3(0, 0.94 * growth_scale, -2.20 * growth_scale)


func _build_camera() -> void:
	follow_camera = Camera3D.new()
	add_child(follow_camera)
	follow_camera.fov = 48.0
	follow_camera.near = 0.1
	follow_camera.far = 230.0
	follow_camera.current = true
	follow_camera.global_position = beast.global_position + _camera_offset()
	follow_camera.look_at(_camera_look_target(), Vector3.UP)

func _camera_offset() -> Vector3:
	# Keep the approved view angle. Pull back in portrait so targets remain
	# visible on the narrower screen without changing movement orientation.
	var viewport_size := get_viewport().get_visible_rect().size
	# Scale only the distance, not the established portrait chase angle.
	return CAMERA_OFFSET * (PORTRAIT_CAMERA_DISTANCE if viewport_size.y > viewport_size.x else 1.0) * maxf(1.0, growth_scale) + Vector3(0, _camera_height(), 0)

func _camera_height() -> float:
	return (growth_scale - 1.0) * 0.65 + (growth_scale * 0.75 if upright_form else 0.0)

func _camera_look_target() -> Vector3:
	# Bigger and upright forms remain framed with the exact original camera
	# angle and control mapping at hatchling size.
	return beast.global_position + Vector3(0, _camera_height(), -2.8 * maxf(1.0, growth_scale))


func _build_population() -> void:
	# Preserve the original busy starting beach; newcomers arrive in small
	# batches as the player explores rather than loading the whole coast's NPCs.
	for i in range(26):
		var pos := Vector3(randf_range(-48, 48), 0, randf_range(-14, 15))
		if _blocking_building(pos) < 0:
			_spawn_civilian(pos)
	_maintain_population(0.0)


func _maintain_population(delta: float) -> void:
	population_clock -= delta
	if population_clock > 0.0:
		return
	population_clock = POPULATION_REFRESH_SECONDS
	# Retire only people far beyond the local play space. Total active actors
	# stay bounded regardless of the length of the map or length of the session.
	var retirement_distance := maxf(150.0, growth_scale * 90.0)
	for i in range(civilians.size() - 1, -1, -1):
		var actor: Node3D = civilians[i]["node"]
		if actor.global_position.distance_to(beast.global_position) > retirement_distance:
			actor.queue_free()
			civilians.remove_at(i)
	var newcomers := mini(5, ACTIVE_POPULATION_TARGET - civilians.size())
	var attempts := 0
	while newcomers > 0 and attempts < 50 and civilians.size() < MAX_ACTIVE_CIVILIANS:
		attempts += 1
		var min_distance := maxf(42.0, growth_scale * 36.0)
		var side := -1.0 if randi_range(0, 1) == 0 else 1.0
		var spawn_z := clampf(beast.global_position.z + randf_range(-68.0, 68.0), NEIGHBOURHOOD_FAR_Z + 14.0, -91.0) if beast.global_position.z < -82.0 else randf_range(-13.0, 17.0)
		var pos := Vector3(beast.global_position.x + side * randf_range(min_distance, min_distance + 48.0), 0, spawn_z)
		if beast.global_position.z < -82.0:
			pos.x = beast.global_position.x + randf_range(-70.0, 70.0)
			if pos.distance_to(beast.global_position) < min_distance:
				continue
		if absf(pos.x) >= PLAYABLE_HALF_LENGTH - 6.0:
			continue
		if pos.distance_to(beast.global_position) < maxf(38.0, growth_scale * 28.0):
			continue
		if _blocking_building(pos) >= 0:
			continue
		_spawn_civilian(pos)
		newcomers -= 1

func _person(pos: Vector3, uniform: bool = false) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	add_child(node)
	CoastalArt.person(node, uniform, randi_range(0, 19))
	return node

func _spawn_civilian(pos: Vector3) -> void:
	var response := randi_range(0, 2) # flee at once, freeze, or react late
	# Use nearby shelters, never a fixed building index back at spawn.
	var shelter := -1
	if randi_range(0, 2) != 0:
		var best_distance := 58.0
		for i in range(buildings.size()):
			var building: Dictionary = buildings[i]
			if building["destroyed"]:
				continue
			var distance := pos.distance_to(building["position"])
			if distance < best_distance:
				best_distance = distance
				shelter = i
	civilians.append({"node": _person(pos), "speed": randf_range(3.4, 7.1), "response": response, "panic": false, "delay": 0.0, "shelter": shelter, "direction": Vector3.ZERO})

func _spawn_officer(pos: Vector3, swat: bool = false) -> void:
	var node := _person(pos, true)
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
	stats_label.hide()
	coastal_hud = CoastalHUD.new()
	ui_layer.add_child(coastal_hud)
	var quality := OptionButton.new()
	quality.position = Vector2(318, 24)
	quality.size = Vector2(120, 32)
	quality.add_item("Smooth")
	quality.add_item("Battery")
	quality.add_item("Rich")
	quality.theme = CoastalHUD.theme()
	quality.item_selected.connect(func(index: int) -> void:
		Engine.max_fps = 30 if index == 1 else 60
		sun_light.shadow_enabled = index == 2
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED if index == 1 else Viewport.MSAA_2X
	)
	ui_layer.add_child(quality)
	evolution_progress = ProgressBar.new()
	evolution_progress.position = Vector2(18, 166)
	evolution_progress.size = Vector2(238, 20)
	evolution_progress.show_percentage = false
	evolution_progress.min_value = 0
	evolution_progress.max_value = 100
	evolution_progress.visible = false
	ui_layer.add_child(evolution_progress)
	sprint_button = Button.new()
	sprint_button.text = "SPRINT"
	_place_right_button(sprint_button, -164, -83)
	# Mouse/keyboard clicks retain normal Button behavior; native touchscreen
	# presses also work while a second finger remains on the movement joystick.
	sprint_button.pressed.connect(_toggle_sprint)
	sprint_button.focus_mode = Control.FOCUS_NONE
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
	# Developer-only test shortcut. Shares the former restart slot while alive.
	debug_evolve_button = Button.new()
	debug_evolve_button.text = "DEBUG\nEVO"
	_place_right_button(debug_evolve_button, -342, -263)
	debug_evolve_button.visible = OS.has_feature("debug")
	debug_evolve_button.pressed.connect(_debug_evolve)
	debug_evolve_button.focus_mode = Control.FOCUS_NONE
	modal_shade = ColorRect.new()
	modal_shade.color = Color(.04,.10,.12,.58)
	modal_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_shade.hide()
	ui_layer.add_child(modal_shade)
	modal = CenterContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.visible = false
	ui_layer.add_child(modal)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 0)
	panel.theme = CoastalHUD.theme()
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
	btn.theme = CoastalHUD.theme()
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


func _debug_evolve() -> void:
	# Available only in test/debug builds. This starts a free evolution without
	# changing regular feeding costs, then skips the dangerous countdown so
	# testers can inspect growth/mutations rapidly. Choice and skin reveal stay
	# intact, with no queued double-evolution during pause.
	if not OS.has_feature("debug") or game_over or evolving or choice_open or reveal_active:
		return
	biomass = maxi(biomass, _cost())
	_start_evolution()
	if evolving:
		_finish_evolution()


func _physics_process(delta: float) -> void:
	# The root runs during pause for UI, but no enemies, damage or movement do.
	if reveal_active:
		_update_camera(delta)
		return
	if game_over or choice_open or reveal_active:
		return
	if evolving:
		evolution_clock -= delta
		_update_evolution_animation(delta)
	else:
		_update_movement(delta)
		_update_biting(delta)
		_update_civilians(delta)
		_update_cars(delta)
		_maintain_population(delta)
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
		next_pos.x = clampf(next_pos.x, -PLAYABLE_HALF_LENGTH, PLAYABLE_HALF_LENGTH)
		next_pos.z = clampf(next_pos.z, NEIGHBOURHOOD_FAR_Z, 26.0)
		# move_and_collide performs a swept physics test, including sprint frames.
		# Sliding preserves responsive movement along the face of an obstacle.
		var previous_position := beast.global_position
		var motion := next_pos - beast.global_position
		var contact := beast.move_and_collide(motion)
		if contact != null:
			var index := _building_for_collider(contact.get_collider())
			if index >= 0:
				_attack_building(index, sprint_active)
			else:
				var car_index := _car_for_collider(contact.get_collider())
				if car_index >= 0:
					_attack_car(car_index, sprint_active)
			var slide := contact.get_remainder().slide(contact.get_normal())
			if slide.length_squared() > 0.000001:
				beast.move_and_collide(slide)
		run_phase += beast.global_position.distance_to(previous_position) * TAU / (2.5 * maxf(1.0, growth_scale))
	strike_timer = maxf(0.0, strike_timer - delta)
	_update_creature_animation(delta, moving)
	bite_timer = maxf(0.0, bite_timer - delta)

func _update_creature_animation(delta: float, moving: bool) -> void:
	creature_idle_clock += delta
	# A discrete anatomical transition at level 22, not a continuous stretch.
	# Front limbs become elevated forelimbs; rear limbs keep ground contact.
	if is_instance_valid(torso_pivot):
		torso_pivot.rotation.x = lerpf(torso_pivot.rotation.x,
			1.05 if upright_form else 0.0, minf(1.0, 3.5 * delta))
	var gait_amplitude := (0.74 if sprint_active else 0.45) if moving else 0.0
	for i in range(leg_pivots.size()):
		var phase := run_phase + (0.0 if i == 0 or i == 3 else PI)
		var limb := leg_pivots[i]
		var is_front := i == 0 or i == 2
		var animation_swing := sin(phase) * gait_amplitude * (0.38 if upright_form and is_front else 1.0)
		# Independent shoulder compensation keeps arms hanging forward rather
		# than rotating them up with the chest. Hind knees support the new mass.
		var stance := -torso_pivot.rotation.x - 0.25 if upright_form and is_front else (0.20 if upright_form else 0.0)
		limb.rotation.x = lerpf(limb.rotation.x,
			animation_swing + stance,
			minf(1.0, 15.0 * delta))
		var knee: Node3D = creature_rig["lower_limbs"][i]
		var paw: Node3D = creature_rig["paws"][i]
		knee.rotation.x = -0.20 + maxf(0.0, -sin(phase)) * gait_amplitude * 0.65 if upright_form and not is_front else 0.0
		paw.rotation.x = -limb.rotation.x - knee.rotation.x if upright_form and not is_front else 0.0
		# A tiny plant/recovery sway adds weight without changing locomotion.
		limb.rotation.z = lerpf(limb.rotation.z,
			0.035 * sin(phase + 0.4) if moving else 0.0, minf(1.0, 9.0 * delta))
	var bob := absf(sin(run_phase)) * (0.11 if sprint_active else 0.065) if moving else 0.0
	beast_visual.position.y = lerpf(beast_visual.position.y, bob, minf(1.0, 14.0 * delta))
	beast_visual.rotation.z = lerpf(beast_visual.rotation.z,
		(0.042 * sin(run_phase * 0.5)) if moving else 0.0, minf(1.0, 8.0 * delta))
	# Breathing and head curiosity must remain visible when standing still.
	var chest: Node3D = creature_rig.get("breathing")
	if is_instance_valid(chest):
		chest.scale = Vector3(1.0 + 0.010 * sin(creature_idle_clock * 1.9),
			1.0 + 0.025 * sin(creature_idle_clock * 1.9),
			1.0 + 0.008 * sin(creature_idle_clock * 1.9))
	for i in range(tail_pivots.size()):
		var tail := tail_pivots[i]
		var sway := sin(run_phase * 0.58 - float(i) * 0.65) * (0.17 if sprint_active else 0.11) if moving else sin(creature_idle_clock * 0.75 - float(i) * 0.52) * 0.075
		tail.rotation.y = lerpf(tail.rotation.y, sway, minf(1.0, 8.0 * delta))
	var progress := 1.0 - clampf(bite_timer / maxf(0.05, bite_duration), 0.0, 1.0)
	var snap := sin(progress * PI) if bite_timer > 0.0 else 0.0
	if upright_form:
		# Reach down toward ground prey; convert the intended vertical reach
		# into the tilted torso space. Collision is sampled from this final pose.
		var reach := Basis(Vector3.RIGHT, -torso_pivot.rotation.x) * Vector3(0, -.95 * snap, -.67 * snap)
		head_pivot.position = Vector3(0, 1.13, -1.22) + reach
	else:
		head_pivot.position = Vector3(0, 1.13, -1.22 - .67 * snap)
	# Neck counter-rotation keeps eyes and jaws facing prey in the upright form.
	head_pivot.rotation.x = (-torso_pivot.rotation.x if upright_form else 0.0) - 0.13 * snap + (0.025 * sin(creature_idle_clock * 0.95) if not moving and bite_timer <= 0.0 else 0.0)
	head_pivot.rotation.y = 0.025 * sin(creature_idle_clock * 0.70) if not moving else 0.0
	jaw.rotation.x = -0.85 * maxf(0.0, sin(progress * PI)) if bite_timer > 0.0 else 0.0
	# Sample AFTER all transforms, never the previous frame's head pose.
	if upright_form:
		head_collision_node.position = beast.to_local(head_pivot.to_global(Vector3(0, -0.16, -1.11)))
	else:
		head_collision_node.position = Vector3(0, 0.94, -2.20 - 0.67 * snap) * growth_scale
	if is_instance_valid(prey_in_mouth):
		prey_in_mouth.position = prey_in_mouth.position.lerp(Vector3(0, -0.43, -1.16), minf(1.0, 18.0 * delta))
		prey_in_mouth.scale = Vector3.ONE * maxf(0.02, 1.0 - progress * 1.2)
		if bite_timer <= delta:
			prey_in_mouth.queue_free()
			prey_in_mouth = null

	creature_rig["visual"].update_pose(upright_form, moving, run_phase)
	var step := int(run_phase / PI)
	if moving and step != previous_step and is_instance_valid(coastal_effects):
		previous_step = step
		coastal_effects.burst(beast.global_position + Vector3(0, .12, 0), 2, growth_scale)
	if is_instance_valid(ground_shadow):
		ground_shadow.scale = Vector3(growth_scale, 1, growth_scale)

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

func _attack_building(index: int, running: bool) -> void:
	var b: Dictionary = buildings[index]
	if b["destroyed"]:
		return
	# Weak forms always chip away at even heavy buildings. High tier buildings
	# take many minutes at baseline strength, but the first hit shows a crack.
	if running and strength >= int(b["breakthrough_strength"]):
		_damage_building(index, float(b["hits"]))
	elif strike_timer <= 0.0:
		var strength_gap := int(b["required_strength"]) - strength
		var damage := 0.015 / pow(2.0, float(strength_gap - 1)) if strength_gap > 0 else float(1 + (-strength_gap) * 2)
		_damage_building(index, damage)
		strike_timer = 0.70


func _damage_building(index: int, hits: float) -> void:
	var b: Dictionary = buildings[index]
	if b["destroyed"]:
		return
	if is_instance_valid(coastal_effects):
		var center: Vector3 = b["position"]
		var half_size: Vector2 = b["half"]
		var at := Vector3(clampf(beast.position.x, center.x-half_size.x, center.x+half_size.x), 1, clampf(beast.position.z, center.z-half_size.y, center.z+half_size.y))
		coastal_effects.burst(at, 5, growth_scale, true)
	b["hits"] = float(b["hits"]) - hits
	if b["hits"] < float(b["max_hits"]):
		var damage_fraction := 1.0 - maxf(0.0, float(b["hits"])) / float(b["max_hits"])
		var stage := mini(3, maxi(1, ceili(damage_fraction * 3.0)))
		if stage > int(b["crack_stage"]):
			var layers: Array[Node3D] = b["crack_layers"]
			for i in range(stage):
				layers[i].visible = true
			b["crack_stage"] = stage
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
	coastal_effects.burst(at + Vector3(0,1,0), 10, 2.0)
	for i in range(mini(count, maxi(0,48-debris.size()))):
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
	var reach := _bite_reach()
	for i in range(civilians.size() - 1, -1, -1):
		var npc: Node3D = civilians[i]["node"]
		var toward := npc.global_position - beast.global_position
		toward.y = 0.0
		if toward.length_squared() <= reach * reach and facing.dot(toward.normalized()) >= BITE_CONE_DOT:
			civilians.remove_at(i)
			_capture_and_feed(npc, 12)
			return
	for i in range(officers.size() - 1, -1, -1):
		var cop: Node3D = officers[i]["node"]
		var toward := cop.global_position - beast.global_position
		toward.y = 0.0
		if toward.length_squared() <= reach * reach and facing.dot(toward.normalized()) >= BITE_CONE_DOT:
			officers.remove_at(i)
			_capture_and_feed(cop, 16)
			return

func _bite_reach() -> float:
	# Preserve hatchling reach/cone. Raised jaws must still collect ground prey.
	return maxf(BITE_RANGE * growth_scale, -head_collision_node.position.z + head_collision_shape.radius * 0.8) if upright_form else BITE_RANGE * growth_scale

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
				new_pos.x = clampf(new_pos.x, -PLAYABLE_HALF_LENGTH + 1.0, PLAYABLE_HALF_LENGTH - 1.0)
				new_pos.z = clampf(new_pos.z, NEIGHBOURHOOD_FAR_Z + 6.0, 23.0)
				if _blocking_building(new_pos) < 0:
					person.global_position = new_pos
				person.rotation.y = atan2(-travel.x, -travel.z)
		CoastalArt.animate_person(person, creature_idle_clock * 12.0 + float(i), bool(c["panic"]) and float(c["delay"]) <= 0.0)
		civilians[i] = c

func _spawn_local_officer(offset: float, swat: bool) -> void:
	var x := clampf(beast.global_position.x + offset, -PLAYABLE_HALF_LENGTH + 8.0, PLAYABLE_HALF_LENGTH - 8.0)
	var z := clampf(beast.global_position.z - 30.0, NEIGHBOURHOOD_FAR_Z + 7.0, 16.0)
	var point := Vector3(x, 0, z)
	if _blocking_building(point) >= 0:
		point.z = clampf(beast.global_position.z + 22.0, NEIGHBOURHOOD_FAR_Z + 8.0, 22.0)
	_spawn_officer(point, swat)


func _update_police(delta: float) -> void:
	# Do not leave the entire police response stranded in an earlier district.
	for i in range(officers.size() - 1, -1, -1):
		var officer: Node3D = officers[i]["node"]
		if officer.global_position.distance_to(beast.global_position) > maxf(155.0, growth_scale * 95.0):
			officer.queue_free()
			officers.remove_at(i)
	if alert > 0.0:
		response_clock += delta
	if response_clock > 18.0 and officers.is_empty():
		_spawn_local_officer(-12.0, false)
		_spawn_local_officer(12.0, false)
		response_clock = -8.0
	if alert > 65.0 and response_clock > 65.0 and officers.size() < 4:
		_spawn_local_officer(-32.0, true)
		_spawn_local_officer(32.0, true)
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
		CoastalArt.animate_person(unit, creature_idle_clock * 9.0 + float(i), distance > 12.0 and distance < 45.0)
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
	if evolving:
		# The cocoon protects health and resists transformation interruption.
		damage *= pow(0.82, cocoon_rank)
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
	elif evolving and evolution_damage >= _cocoon_break_limit():
		_reset_evolution_pose()
		shedding.abort_shed()
		evolving = false
		biomass = 0
		evolution_damage = 0.0

func _cocoon_break_limit() -> float:
	return 35.0 + 12.0 * float(cocoon_rank)


func _evolution_duration() -> float:
	# Speed upgrades shorten the dangerous stage, never the safe selection.
	return maxf(3.0, (6.0 + float(evolutions) * 1.5) * pow(0.78, metamorphosis_rank))


func _update_evolution_animation(delta: float) -> void:
	# Readable pulsing/shivering while the player is vulnerable. Temporary
	# pose changes cannot overwrite accumulated physical growth.
	evolution_visual_clock += delta
	var beat := sin(evolution_visual_clock * 11.0)
	beast_visual.position.y = -0.12 + 0.045 * beat
	beast_visual.rotation.z = beat * 0.025
	beast_visual.scale = Vector3.ONE * growth_scale * (1.0 + 0.018 * maxf(0.0, beat))
	head_pivot.rotation.x = (-torso_pivot.rotation.x if upright_form else 0.0) + 0.07 * sin(evolution_visual_clock * 8.0)
	shedding.update_shed_progress(1.0 - evolution_clock / maxf(0.01, evolution_total))

func _reset_evolution_pose() -> void:
	beast_visual.position = Vector3.ZERO
	beast_visual.rotation.z = 0.0
	beast_visual.scale = Vector3.ONE * growth_scale
	head_pivot.rotation.x = -torso_pivot.rotation.x if upright_form else 0.0
	creature_rig["visual"].update_pose(upright_form)

func _start_evolution() -> void:
	if game_over or evolving or choice_open or reveal_active or biomass < _cost():
		return
	evolving = true
	sprint_requested = false
	sprint_active = false
	evolution_damage = 0.0
	evolution_visual_clock = 0.0
	evolution_total = _evolution_duration()
	evolution_clock = evolution_total
	shedding.begin_shed(beast_visual)

func _finish_evolution() -> void:
	evolving = false
	_reset_evolution_pose()
	choice_open = true
	get_tree().paused = true
	modal.visible = true
	modal_shade.show()
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
		{"id": "strength", "name": "Brutal Strength", "detail": "Damage buildings much faster"},
		{"id": "health", "name": "Dense Flesh", "detail": "Increase maximum health"}
	]
	if evolutions >= 1:
		pool.append({"id": "cocoon", "name": "Reinforced Cocoon", "detail": "Protect yourself during evolution"})
		pool.append({"id": "metamorphosis", "name": "Rapid Metamorphosis", "detail": "Shorten vulnerable evolution time"})
	if evolutions >= 2:
		pool.append({"id": "regen", "name": "Regeneration", "detail": "Recover health over time"})
	pool.shuffle()
	var extra := maxi(0, int((biomass - _cost()) / 30.0))
	# Nine possible families, but never crowd the approved portrait choice UI.
	var number_of_choices := mini(7, mini(pool.size(), 3 + extra))
	for i in range(number_of_choices):
		var mutation: Dictionary = pool[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(350, 76)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_constant_override("icon_max_width", 42)
		var region: String = {"armour":"BACK PLATES", "speed":"LIMBS", "stamina":"RIB GILLS", "jaw":"JAWS", "strength":"FORECLAWS", "health":"CHEST", "regen":"FLANKS", "cocoon":"SHELL", "metamorphosis":"DORSAL CREST"}[mutation["id"]]
		var rank := int(mutation_visual_counts.get(mutation["id"],0)) + 1
		button.icon = MutationIcons.texture(String(mutation["id"]), rank)
		button.text = "%s  /  %d\n%s\n%s" % [mutation["name"], rank, region, mutation["detail"]]
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
		"cocoon": cocoon_rank += 1
		"metamorphosis": metamorphosis_rank += 1
	_apply_mutation_visual(id)
	_record_evolution(id)
	biomass = maxi(0, biomass - _cost())
	evolutions += 1
	hp = max_hp
	stamina = max_stamina
	sprint_locked = false
	sprint_requested = false
	_apply_growth_milestone(evolutions)
	beast_visual.scale = Vector3.ONE * growth_scale
	choice_open = false
	modal.visible = false
	modal_shade.hide()
	reveal_active = true
	reveal_input_layer.visible = true
	shedding.start_reveal()
	# Remain paused until the new form is fully revealed.
	touch_input.reset_input()

func _apply_growth_milestone(level: int) -> void:
	# Mutations are continuous. Size only changes at 5/10/16/22/28/34,
	# then every six later evolutions. Keep progression deterministic.
	if not GrowthProgression.is_growth_step(level):
		return
	growth_stage = GrowthProgression.stage_for(level)
	growth_scale = GrowthProgression.target_scale(level)
	upright_form = GrowthProgression.upright_for(level)
	beast_visual.scale = Vector3.ONE * growth_scale
	# The reveal runs while gameplay is paused: pose must be ready beforehand.
	torso_pivot.rotation.x = 1.05 if upright_form else 0.0
	_update_creature_animation(1.0, false)
	_sync_beast_collision()
	_update_creature_animation(0.0, false)
	_resolve_growth_clearance()

func _resolve_growth_clearance() -> void:
	# Shape expansion is not swept by move_and_collide. Resolve only the new
	# overlap at an evolution milestone, without damage or per-frame searches.
	var origin := beast.global_position
	if _growth_position_clear(origin):
		return
	for ring in range(1, 33):
		for direction in range(16):
			var angle := TAU * float(direction) / 16.0
			var candidate := origin + Vector3(cos(angle), 0, sin(angle)) * float(ring) * 0.5
			if absf(candidate.x) > PLAYABLE_HALF_LENGTH or candidate.z < NEIGHBOURHOOD_FAR_Z or candidate.z > 26.0:
				continue
			if _growth_position_clear(candidate):
				beast.global_position = candidate
				return
	push_warning("No local growth clearance; beach has outgrown its supported scale")

func _growth_position_clear(position: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = beast.collision_mask
	query.exclude = [beast.get_rid()]
	query.margin = 0.04
	for collider in [body_collision_node, head_collision_node]:
		query.shape = collider.shape
		query.transform = beast.global_transform * collider.transform
		query.transform.origin += position - beast.global_position
		if not beast.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return false
	return true


func _evolution_label(id: String) -> String:
	match id:
		"armour": return "Hardened Scales"
		"speed": return "Fleet Limbs"
		"stamina": return "Endurance"
		"jaw": return "Rapid Feeding"
		"strength": return "Brutal Strength"
		"health": return "Dense Flesh"
		"regen": return "Regeneration"
		"cocoon": return "Reinforced Cocoon"
		"metamorphosis": return "Rapid Metamorphosis"
	return id


func _record_evolution(id: String) -> void:
	# Ordered entries deliberately retain the mutation ID and size milestone:
	# these will form the nodes/edges of the future evolution tree or web.
	evolution_history.append({
		"step": evolutions + 1,
		"mutation_id": id,
		"label": _evolution_label(id),
		"growth_milestone": GrowthProgression.stage_for(evolutions + 1),
		"size_changed": GrowthProgression.is_growth_step(evolutions + 1),
		"form": GrowthProgression.form_name(evolutions + 1)
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
	# Colour-consistent cumulative enhancements retain the approved mutation IDs.
	var stage := int(mutation_visual_counts.get(id, 0))
	mutation_visual_counts[id] = stage + 1
	StylizedCreatureArt.add_mutation(body_art_anchor, head_pivot, leg_pivots, id, stage)
	creature_rig["visual"].update_pose(upright_form)

func _update_camera(delta: float) -> void:
	var goal := beast.global_position + _camera_offset()
	follow_camera.far = maxf(230.0, 230.0 * growth_scale)
	if camera_celebration_clock > 0.0:
		camera_celebration_clock = maxf(0.0, camera_celebration_clock - delta)
		goal.x += sin(camera_celebration_clock * 90.0) * camera_celebration_clock * 0.50
		goal.z += cos(camera_celebration_clock * 75.0) * camera_celebration_clock * 0.35
	follow_camera.global_position = follow_camera.global_position.lerp(goal, minf(1.0, 6.0 * delta))
	follow_camera.look_at(_camera_look_target(), Vector3.UP)

func _update_hud() -> void:
	var status := "EVOLVING %.1fs  |  DAMAGE %.0f/%.0f" % [evolution_clock, evolution_damage, _cocoon_break_limit()] if evolving else ("GAME OVER" if game_over else "Hunt / feed / escape / evolve")
	stats_label.text = "HP %d/%d    BIOMASS %d/%d\nSTAMINA %d%%    EVOLUTIONS %d\n%s" % [
		int(ceil(hp)), int(max_hp), biomass, _cost(), int(100.0 * stamina / max_stamina), evolutions, status
	]
	var district_name := "SHOPPING DISTRICT" if beast.global_position.z < SHOPPING_DISTRICT_Z else ("COASTAL NEIGHBOURHOOD" if beast.global_position.z < -82.0 else ("COASTAL KAIJU" if upright_form else "COASTAL HATCHLING"))
	coastal_hud.update_state(hp, max_hp, stamina, max_stamina, biomass, _cost(), evolutions, status if evolving or game_over else district_name)
	if is_instance_valid(debug_evolve_button):
		debug_evolve_button.visible = OS.has_feature("debug") and not game_over
		debug_evolve_button.disabled = evolving or choice_open or reveal_active
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

func _input(event: InputEvent) -> void:
	# Button.pressed is unreliable with simultaneous screen touches on some
	# phones. Handle only the on-screen Sprint rectangle on touch-down; prevent
	# that touch from also generating a release/click toggle.
	if event is InputEventScreenTouch and event.pressed and is_instance_valid(sprint_button):
		if sprint_button.get_global_rect().has_point(event.position):
			_toggle_sprint()
			get_viewport().set_input_as_handled()
		elif is_instance_valid(debug_evolve_button) and debug_evolve_button.visible and debug_evolve_button.get_global_rect().has_point(event.position):
			_debug_evolve()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and reveal_active:
			shedding.accelerate_reveal()
		elif event.keycode == KEY_E:
			_start_evolution()
		elif event.keycode == KEY_F6:
			_debug_evolve()
		elif event.keycode == KEY_SHIFT:
			_toggle_sprint()
		elif event.keycode == KEY_R and game_over:
			get_tree().reload_current_scene()
