extends SceneTree
## Connected long world, stable previous zones, and camera-frustum DEFCON
## reinforcements that never pop into the 3/4 Android viewport.

func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, reason: String) -> bool:
	if not ok:
		printerr("OUTER WORLD TEST FAILED: " + reason)
		paused = false
		quit(1)
	return ok


func _validate_spawn(demo: Node, kind: String, offset: float, need_spawn: bool) -> bool:
	var point: Vector3 = demo._find_offscreen_response_spawn(kind, offset)
	if not point.is_finite():
		return _check(not need_spawn, "No camera-safe reinforcement location in accessible world")
	if not _check(absf(point.x) < demo.PLAYABLE_HALF_LENGTH and point.z >= demo.NEIGHBOURHOOD_FAR_Z,
		"Responder placed beyond world boundary"): return false
	if not _check(not demo._response_is_visible(point, kind), "Reinforcement visibly appeared within portrait camera"): return false
	if not _check(point.distance_to(demo.beast.global_position) > 80.0, "Reinforcement materialised immediately beside giant"): return false
	if kind != "helicopter":
		if not _check(demo._blocking_building(point) < 0, "Ground response landed inside a physical building"): return false
	return true


func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	if not _check(demo.buildings.size() == 114, "Expected 80 original, 10 coast, 12 outer homes and 12 industrial"): return
	if not _check(demo.PLAYABLE_HALF_LENGTH > 760.0 and demo.NEIGHBOURHOOD_FAR_Z <= -1500.0, "Coast or outer district still restricted to old dimensions"): return
	if not _check(demo.get_node_or_null("OuterDistrict/OuterRoads") != null, "Connected outer ring roads not generated"): return
	if not _check(demo.follow_camera.far >= 1600.0, "Giant camera clips distant district"): return
	for i in range(80):
		if not _check(demo.buildings[i]["name"] not in ["Factory", "Water Works", "Power Station"], "Legacy shopping/world building order changed"): return
	var industry := 0
	var wings := 0
	for i in range(80, demo.buildings.size()):
		var b: Dictionary = demo.buildings[i]
		if absf(b["position"].x) > 540.0 and b["position"].z > -85.0:
			wings += 1
		if b["position"].z < -750.0:
			industry += 1
			if not _check(b["node"].get_node_or_null("IndustrialArchitecture") != null, "Industrial artwork not merged"): return
			if not _check(b["collider"] is StaticBody3D, "Large warehouse has no physical collision"): return
	if not _check(industry == 12 and wings == 10, "Large industrial cluster and both coast extensions missing"): return
	if not _check(DietProgression.structure_biomass(4.0, "Factory", Vector2(88,75)) > DietProgression.structure_biomass(4.0, "Bakery", Vector2(18,15)) * 2, "Large food targets don't reward giant growth"): return
	# From the old shopping street it must remain possible to walk into the
	# industrial zone, and both coastal ends must be traversable.
	demo.beast.global_position = Vector3(0,0,-520)
	demo.touch_vector = Vector2(0,-1)
	demo._update_movement(.25)
	if not _check(demo.beast.global_position.z < -520.3, "Road into outer district is obstructed"): return
	demo.touch_vector = Vector2.ZERO
	demo.beast.global_position = Vector3(0,0,-900)
	demo._update_camera(1.0)
	await physics_frame
	if not _validate_spawn(demo, "police", -24.0, true): return
	if not _validate_spawn(demo, "armoured", 24.0, true): return
	if not _validate_spawn(demo, "helicopter", 36.0, true): return
	# Actual deployment must use the same camera-safe locator.
	demo.officers.clear()
	demo._spawn_local_response(-32.0, "swat")
	if not _check(demo.officers.size() == 1, "DEFCON cannot reinforce new district"): return
	if not _check(not demo._response_is_visible(Vector3(demo.officers[0]["node"].global_position.x,0,demo.officers[0]["node"].global_position.z), "swat"), "Spawned DEFCON unit appears onscreen"): return
	# Rotating camera should change which coordinates count as offscreen.
	demo.follow_camera.global_position = demo.beast.global_position + Vector3(-42, 45, -42)
	demo.follow_camera.look_at(demo.beast.global_position, Vector3.UP)
	if not _validate_spawn(demo, "soldier", 22.0, true): return
	# E34 camera zoom must also keep reinforcements out of sight.
	demo._apply_growth_milestone(34)
	demo._update_camera(1.0)
	await physics_frame
	if not _validate_spawn(demo, "armoured", -25.0, true): return
	if not _validate_spawn(demo, "helicopter", 25.0, true): return
	# Extremely large debug bodies may see all nearby geometry. In that
	# case skipping a wave is preferable to enemies visibly popping in.
	if OS.has_feature("debug"):
		demo._debug_evolve_batch(60)
		demo._debug_evolve_batch(26)
		demo._update_camera(1.0)
		if not _validate_spawn(demo, "helicopter", 25.0, false): return
	print("OUTER WORLD TEST PASSED: 114 world buildings, coastal wings, connected industrial targets, world access and offscreen DEFCON deployment")
	quit(0)
