extends SceneTree
## Reproduce interactions absent from the original fourteen suites.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, reason: String) -> void:
	if not ok:
		failures.append(reason)
		printerr("STABILITY TEST FAILED: " + reason)

func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	# This scenario exercises authored assets after explicitly requesting their chunks.
	for authored_index in range(demo.world.authored_count): demo._prepare_authored(authored_index)
	demo.set_physics_process(false)
	await physics_frame
	for person in demo.civilians:
		person["node"].queue_free()
	demo.civilians.clear()
	demo.beast.position = Vector3(0, 0, 15)
	demo._spawn_response_enemy(Vector3(100, 0, 15), "helicopter")
	var heli: Node3D = demo.officers[0]["node"]
	var altitude := heli.position.y
	for frame in range(240):
		demo._update_police(1.0 / 60.0)
	check(is_equal_approx(heli.position.y, altitude), "Helicopter loses altitude pursuing a ground target")
	for foe in demo.officers:
		foe["node"].queue_free()
	demo.officers.clear()
	demo.beast.rotation = Vector3.ZERO
	demo._spawn_response_enemy(demo.beast.position + Vector3(0, 0, -2), "armoured")
	var biomass: int = demo.biomass
	demo._update_biting(0)
	check(demo.officers.size() == 1 and demo.biomass == biomass and demo.prey_in_mouth == null,
		"Hatchling swallows an armoured vehicle as human prey")
	# Shelter accumulation is legitimate: evacuating a full building must not
	# allocate an arbitrarily large crowd during one physics tick.
	demo.buildings[0]["hidden"] = 200
	demo._damage_building(0, 1000)
	check(demo.civilians.size() <= demo.MAX_ACTIVE_CIVILIANS, "Collapse bypasses the active civilian cap")
	check(demo.civilians.size() + demo.evacuations.remaining() == 200,
		"Civilian cap discards displaced occupants")
	var pending: int = demo.evacuations.remaining()
	for index in range(5):
		demo.civilians.pop_back()["node"].queue_free()
	demo.population_clock = 0
	demo._maintain_population(0)
	check(demo.evacuations.remaining() == pending - 5 and demo.civilians.size() == demo.MAX_ACTIVE_CIVILIANS,
		"Evacuees do not take available slots before ambient refill")
	for foe in demo.officers:
		foe["node"].queue_free()
	demo.officers.clear()
	demo._spawn_response_enemy(Vector3(360, 0, 15), "police")
	var arrival: Node3D = demo.officers[0]["node"]
	demo._update_police(1)
	check(demo.officers.size() == 1 and arrival.position.x < 360,
		"Distant offscreen reinforcements retire before approaching")
	# Once arrived, the same unit must still retire when left behind.
	arrival.position = demo.beast.position + Vector3(100, 0, 0)
	demo._update_police(0)
	arrival.position.x += 300
	demo._update_police(0)
	check(demo.officers.is_empty(), "Established responder never retires after player leaves")
	# Real touch events followed by the Android focus notification.
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(50, 500)
	touch.pressed = true
	demo.touch_input._gui_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(120, 500)
	demo.touch_input._gui_input(drag)
	check(demo.touch_vector.length() > 0.5, "Touch drag does not reach gameplay input")
	demo.sprint_requested = true
	demo.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(demo.touch_vector == Vector2.ZERO and not demo.sprint_requested and not demo.touch_input.joystick_active,
		"Focus loss leaves movement or sprint held")
	# Owned projectile records must freeze under choice/reveal, then expire.
	demo._spawn_projectile(Vector3(0, 90, 0), Vector3.RIGHT, true)
	var shot: Node3D = demo.projectiles[-1]["node"]
	var shot_position := shot.global_position
	demo.choice_open = true
	demo._physics_process(1)
	check(shot.global_position == shot_position, "Extracted projectiles advance during mutation choice")
	demo.choice_open = false
	demo._update_projectiles(4)
	check(demo.projectiles.is_empty(), "Expired projectile records leak")
	await process_frame
	check(not is_instance_valid(shot), "Expired projectile visual leaks")
	if failures.is_empty():
		print("STABILITY TEST PASSED: flight, diet, conserved capped evacuation, arrival retirement, touch focus and projectile pause/cleanup")
	quit(0 if failures.is_empty() else 1)
