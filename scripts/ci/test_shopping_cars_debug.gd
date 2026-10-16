extends SceneTree
## Shopping precinct, car impacts/traffic, and debug-only free growth regressions.

func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> bool:
	if not ok:
		printerr("SHOPPING CARS DEBUG TEST FAILED: " + message)
		paused = false
		quit(1)
	return ok


func _complete_reveal(demo: Node) -> void:
	demo.shedding.reveal_progress = 1.0
	demo.shedding._process(0.0)


func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	if not _check(demo.buildings.size() == 80, "Missing 54 original buildings, 12 homes or 14 shops"): return
	for i in range(54):
		if not _check(demo.buildings[i]["name"] != "Supermarket" and demo.buildings[i]["name"] != "Hardware Store", "Approved buildings reordered"): return
	var houses := 0
	var shopping := 0
	for i in range(54, demo.buildings.size()):
		var b: Dictionary = demo.buildings[i]
		if b["name"] == "Coastal home":
			houses += 1
		else:
			shopping += 1
			if not _check(b["node"].get_node_or_null("ShopSign") != null, "Shop signs missing"): return
		if not _check(b["node"].get_node_or_null("Architecture") != null, "Shopping art not batched"): return
		if not _check(b["collider"] is StaticBody3D, "Extended building lost physics"): return
	if not _check(houses == 12 and shopping == 14, "Wrong houses/shop split"): return
	if not _check(demo.NEIGHBOURHOOD_FAR_Z <= -500.0 and demo.get_node_or_null("CoastalNeighbourhood/NeighbourhoodRoads") != null, "Inland streets not extended"): return
	# The central access route reaches the shops; storefronts block physical impact.
	demo.beast.global_position = Vector3(0, 0, -325)
	demo.touch_vector = Vector2(0, -1)
	demo._update_movement(0.25)
	if not _check(demo.beast.global_position.z < -325.1, "Creature cannot reach shopping street from neighbourhood"): return
	demo.touch_vector = Vector2.ZERO
	demo.beast.global_position = Vector3(-105, 0, -334)
	await physics_frame
	var shop_impact: KinematicCollision3D = demo.beast.move_and_collide(Vector3(0, 0, -25))
	if not _check(shop_impact != null and demo._building_for_collider(shop_impact.get_collider()) >= 66, "Shopping storefronts do not block creature physically"): return
	# All cars remain physical, bounded and independently destructible.
	if not _check(demo.cars.size() == 16 and demo.cars.size() <= demo.MAX_CARS, "Vehicle count exceeded cap"): return
	var moving := 0
	for i in range(demo.cars.size()):
		var car: Dictionary = demo.cars[i]
		if bool(car["moving"]): moving += 1
		if not _check(car["collider"] is AnimatableBody3D and demo._car_for_collider(car["collider"]) == i, "Car collision ownership missing"): return
		if not _check(car["node"].get_node_or_null("CarBody") != null, "Car art missing"): return
		if not _check(demo._blocking_building(car["node"].global_position) < 0, "Parked or moving car intersects a building"): return
	if not _check(moving == 4, "No moving traffic on inland roads"): return
	demo.beast.global_position = Vector3(15, 0, -127)
	var moving_car: Dictionary = demo.cars[0]
	var before_z: float = moving_car["node"].position.z
	demo._update_cars(0.8)
	if not _check(demo.cars[0]["node"].position.z < before_z - 3.0, "Car does not drive along road"): return
	# Strength/sprint must matter, and impact must open a visible gap.
	var parked := 4
	var parked_car: Dictionary = demo.cars[parked]
	var pre_people: int = demo.civilians.size()
	demo.strength = 0
	for n in range(3):
		demo.strike_timer = 0.0
		demo._attack_car(parked, false)
	if not _check(demo.cars[parked]["destroyed"] and demo._car_for_collider(parked_car["collider"]) == -1, "Three baseline car strikes did not destroy vehicle"): return
	if not _check(demo.civilians.size() == pre_people + 1 and demo.debris.size() > 0, "Smash did not produce debris and fleeing driver"): return
	demo.strength = 2
	demo._attack_car(5, true)
	if not _check(demo.cars[5]["destroyed"], "Upgraded sprint did not smash car"): return
	# People and police must follow the player into the shopping region.
	for person in demo.civilians:
		person["node"].queue_free()
	demo.civilians.clear()
	demo.beast.global_position = Vector3(0,0,-397)
	for step in range(10):
		demo.population_clock = 0.0
		demo._maintain_population(0.0)
	if not _check(demo.civilians.size() == demo.ACTIVE_POPULATION_TARGET, "Shops cannot sustain nearby prey"): return
	for person in demo.civilians:
		var pos: Vector3 = person["node"].global_position
		if not _check(pos.distance_to(demo.beast.global_position) < 155 and demo._blocking_building(pos) < 0, "Shop crowd outside area or inside wall"): return
	demo.alert = 25.0
	demo.response_clock = 19.0
	demo._update_police(0.016)
	if not _check(demo.officers.size() == 2, "Police did not respond beyond the first suburb"): return
	for cop in demo.officers:
		if not _check(cop["node"].global_position.distance_to(demo.beast.global_position) < 75.0, "Police dispatched back to beach"): return
	# Free evolution must not alter the live progression cost or growth cadence.
	if not _check(demo._cost() == 55 and demo.evolutions == 0, "Pre-debug progression changed"): return
	if OS.has_feature("debug"):
		if not _check(demo.debug_evolve_button.visible, "Visible developer button missing from debug build"): return
		for n in range(5):
			demo.biomass = 0
			demo._debug_evolve()
			if not _check(demo.choice_open and paused and not demo.evolving and demo.evolutions == n, "Free evolution did not open safe mutation choice"): return
			demo._debug_evolve()
			if not _check(demo.evolutions == n, "Overlapping debug request bypassed safe paused modal"): return
			demo._choose_mutation("speed")
			_complete_reveal(demo)
			await process_frame
			if not _check(not paused and demo.evolutions == n+1 and demo.biomass == 0, "Debug failed to complete cost-free evolution"): return
		if not _check(demo.growth_stage == 1 and is_equal_approx(demo.growth_scale, 1.20), "Free debug choices broke growth level 5"): return
	else:
		demo.biomass = 0
		demo._debug_evolve()
		if not _check(not demo.evolving and demo.evolutions == 0, "Free cheat active outside debug builds"): return
	print("SHOPPING CARS DEBUG TEST PASSED: 80 buildings, 14 shops, solid moving and smashable vehicles, shopping crowds, local police, free debug evolutions and level-5 growth")
	quit(0)
