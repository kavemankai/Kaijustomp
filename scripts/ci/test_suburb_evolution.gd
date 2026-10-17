extends SceneTree
## First inland neighbourhood and mutation survival/performance contract.

func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, reason: String) -> bool:
	if not ok:
		printerr("SUBURB EVOLUTION TEST FAILED: " + reason)
		paused = false
		quit(1)
	return ok


func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	# This scenario exercises authored assets after explicitly requesting their chunks.
	for authored_index in range(demo.world.authored_count): demo._prepare_authored(authored_index)
	demo.set_physics_process(false)
	await physics_frame
	if not _check(demo.world.authored_count == 114, "Expected original 80 buildings plus 34 outer-region targets"): return
	for i in range(36):
		if not _check(demo.buildings[i]["name"] != "Coastal home", "Existing beach building order changed"): return
	for i in range(36, 54):
		var home: Dictionary = demo.buildings[i]
		if not _check(home["name"] == "Coastal home" and home["collider"] is StaticBody3D, "Suburban house is not physical"): return
		if not _check(home["node"].get_node_or_null("Architecture") != null, "Suburban architecture not batched"): return
	if not _check(demo.get_node_or_null("CoastalNeighbourhood/NeighbourhoodRoads") != null, "Inland roads missing"): return
	if not _check(is_equal_approx(demo._evolution_duration(), 6.0) and demo._cocoon_break_limit() == 35.0, "Base evolution timing or vulnerability changed"): return
	# Both new choices should be included after the first successful adaptation,
	# and the portrait UI still offers at most seven visible choices.
	demo.biomass = 100
	demo._start_evolution()
	demo._finish_evolution()
	demo._choose_mutation("armour")
	demo.shedding.reveal_progress = 1.0
	demo.shedding._process(0.0)
	await process_frame
	demo.biomass = demo._cost() + 300
	demo._start_evolution()
	demo._finish_evolution()
	# Previous queued cards are freed at frame end, as in the portrait art test.
	await process_frame
	var choices := 0
	for button in demo.choice_column.get_children():
		if button is Button:
			choices += 1
	if not _check(choices == 7, "New options overflow portrait evolution cards"): return
	demo._choose_mutation("cocoon")
	if not _check(demo.cocoon_rank == 1 and demo.evolution_history[-1]["mutation_id"] == "cocoon", "Cocoon upgrade/history not stored"): return
	if not _check(demo.mutation_visual_counts["cocoon"] == 1 and MutationIcons.texture("cocoon", 1) != null, "Cocoon skin art/icon missing"): return
	demo.shedding.reveal_progress = 1.0
	demo.shedding._process(0.0)
	await process_frame
	demo.biomass = demo._cost() + 400
	demo._start_evolution()
	if not _check(demo._cocoon_break_limit() == 47.0 and is_equal_approx(demo.evolution_total, 9.0), "Cocoon must not change timing"): return
	var hp_before: float = demo.hp
	demo._take_damage(45.0)
	if not _check(demo.evolving and demo.hp > hp_before - 45.0 and demo.evolution_damage < demo._cocoon_break_limit(), "Cocoon fails to protect ongoing evolution"): return
	demo._finish_evolution()
	demo._choose_mutation("metamorphosis")
	demo.shedding.reveal_progress = 1.0
	demo.shedding._process(0.0)
	await process_frame
	if not _check(demo.metamorphosis_rank == 1 and demo.evolution_history[-1]["mutation_id"] == "metamorphosis", "Metamorphosis upgrade/history not stored"): return
	if not _check(demo.mutation_visual_counts["metamorphosis"] == 1 and MutationIcons.texture("metamorphosis", 1) != null, "Metamorphosis art/icon missing"): return
	if not _check(is_equal_approx(demo._evolution_duration(), 10.5 * 0.78), "Accelerated timer uses wrong evolution level"): return
	# An interrupted strong cocoon still loses biomass and preserves upgrades.
	demo.biomass = demo._cost() + 50
	demo._start_evolution()
	if not _check(is_equal_approx(demo.evolution_clock, 10.5 * 0.78), "Next transformation was not faster"): return
	demo._take_damage(80.0)
	if not _check(not demo.evolving and demo.biomass == 0 and demo.cocoon_rank == 1 and demo.metamorphosis_rank == 1, "Broken cocoon failed to interrupt evolution fairly"): return
	# A player can continue from promenade to inland houses without teleporting.
	demo.beast.global_position = Vector3(-90, 0, -92)
	await physics_frame
	var impact: KinematicCollision3D = demo.beast.move_and_collide(Vector3(0, 0, -30))
	if not _check(impact != null and demo._building_for_collider(impact.get_collider()) >= 36, "Suburban houses lack collision"): return
	demo.beast.global_position = Vector3(0, 0, -85)
	demo.touch_vector = Vector2(0, -1)
	demo._update_movement(0.2)
	if not _check(demo.beast.global_position.z < -85.0, "Walk from beach into neighbourhood is blocked"): return
	demo.touch_vector = Vector2.ZERO
	for npc in demo.civilians:
		npc["node"].queue_free()
	demo.civilians.clear()
	demo.beast.global_position = Vector3(0, 0, -167)
	for i in range(10):
		demo.population_clock = 0.0
		demo._maintain_population(0.0)
	if not _check(demo.civilians.size() == demo.ACTIVE_POPULATION_TARGET, "Neighbourhood cannot refill with prey"): return
	for npc in demo.civilians:
		var pos: Vector3 = npc["node"].global_position
		if not _check(pos.z < -88.0 and pos.z > demo.NEIGHBOURHOOD_FAR_Z and demo._blocking_building(pos) < 0, "New suburban prey outside neighbourhood or inside house"): return
	print("SUBURB EVOLUTION TEST PASSED: cocoon armour and interruption, accelerated metamorphosis, cards, suburban structures, inland path, local prey")
	quit(0)
