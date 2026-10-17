extends SceneTree
## Regression for the expanded coast, sustainable food supply, and local police.

func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> bool:
	if not condition:
		printerr("LONG BEACH TEST FAILED: " + message)
		paused = false
		quit(1)
	return condition


func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	if not _check(demo.COAST_HALF_LENGTH >= 560.0 and demo.PLAYABLE_HALF_LENGTH >= 540.0, "Coast did not extend at least eightfold"): return
	if not _check(demo.buildings.size() == 114, "Expected original 80, 10 beach wings, 12 outer homes and 12 factories"): return
	if not _check(demo.buildings[0]["name"] == "Beach kiosk" and demo.buildings[1]["name"] == "Wooden shed" and demo.buildings[4]["name"] == "Apartments", "Original beach building order changed"): return
	var far_left := 0
	var far_right := 0
	for b in demo.buildings:
		var point: Vector3 = b["position"]
		if point.x < -350.0: far_left += 1
		if point.x > 350.0: far_right += 1
		if not _check(absf(point.x) < demo.PLAYABLE_HALF_LENGTH - 7.0, "Building outside playable area"): return
	if not _check(far_left >= 5 and far_right >= 5, "Both distant districts must contain buildings"): return
	if not _check(demo.get_node_or_null("CoastalHorizon") != null and demo.get_node_or_null("BeachCluster45") != null, "Coastal environment stops before extended world"): return
	if not _check(demo.civilians.size() >= 20 and demo.civilians.size() <= demo.MAX_ACTIVE_CIVILIANS, "Initial crowd is missing or unbounded"): return
	# The approved joystick and follow-camera direction must still move the player
	# outside the previous +/-70-unit wall.
	demo.beast.global_position = Vector3(290, 0, 18)
	demo.touch_vector = Vector2(1, 0)
	demo._update_movement(0.3)
	if not _check(demo.beast.global_position.x > 290.5, "Joystick cannot traverse extended beach"): return
	demo.beast.global_position = Vector3(547.0, 0, 18)
	demo._update_movement(0.5)
	if not _check(demo.beast.global_position.x <= demo.PLAYABLE_HALF_LENGTH + 0.01, "Creature escaped playable shoreline"): return
	demo.touch_vector = Vector2.ZERO
	# Simulate all available people having been eaten, then travel far from the
	# starting beach. Small batches must restore a local crowd.
	for npc in demo.civilians:
		var actor: Node3D = npc["node"]
		actor.queue_free()
	demo.civilians.clear()
	demo.beast.global_position = Vector3(425, 0, 18)
	for step in range(9):
		demo.population_clock = 0.0
		demo._maintain_population(0.0)
	if not _check(demo.civilians.size() == demo.ACTIVE_POPULATION_TARGET, "Beachgoers did not replenish after depletion"): return
	for npc in demo.civilians:
		var actor: Node3D = npc["node"]
		var dist := actor.global_position.distance_to(demo.beast.global_position)
		if not _check(dist > 37.0 and dist < 150.0, "New arrivals are visible at spawn or far from player"): return
		if not _check(demo._blocking_building(actor.global_position) < 0, "New arrival appeared inside a building"): return
		var shelter: int = npc["shelter"]
		if shelter >= 0:
			var refuge: Vector3 = demo.buildings[shelter]["position"]
			if not _check(refuge.distance_to(actor.global_position) < 59.0, "Beachgoer runs towards shelter in another district"): return
	# Continuous local police response, not officers stranded at the old centre.
	demo.alert = 25.0
	demo.response_clock = 19.0
	demo._update_police(0.016)
	if not _check(demo.officers.size() == 2, "Police did not respond in new district"): return
	for officer in demo.officers:
		var unit: Node3D = officer["node"]
		if not _check(unit.global_position.distance_to(demo.beast.global_position) < 75.0, "Police spawned back at the starting beach"): return
	# A depleted coast near the far boundary also needs to refill from inward.
	for npc in demo.civilians:
		var actor: Node3D = npc["node"]
		actor.queue_free()
	demo.civilians.clear()
	demo.beast.global_position = Vector3(543, 0, 18)
	for step in range(9):
		demo.population_clock = 0.0
		demo._maintain_population(0.0)
	if not _check(demo.civilians.size() == demo.ACTIVE_POPULATION_TARGET, "No new prey near far beach boundary"): return
	print("LONG BEACH TEST PASSED: 8x coast, 36 destructible buildings, preserved controls, refillable bounded crowds, local shelters and police")
	quit(0)
