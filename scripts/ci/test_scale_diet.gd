extends SceneTree
## Visual-size-driven diet: stop human hand-grabs only when too large;
## give one-time biomass from larger targets without fake eating poses.

func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, why: String) -> bool:
	if not ok:
		printerr("SCALE DIET TEST FAILED: " + why)
		paused = false
		quit(1)
	return ok


func _clear_people(demo: Node) -> void:
	for record in demo.civilians:
		record["node"].queue_free()
	demo.civilians.clear()


func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	if not _check(DietProgression.can_grab_people(GrowthProgression.target_scale(28)), "Human grab closed too early"): return
	if not _check(not DietProgression.can_grab_people(GrowthProgression.target_scale(34)), "Human grab still possible when scaled hands dwarf person"): return
	if not _check(DietProgression.can_feed_on_cars(GrowthProgression.target_scale(22)) and not DietProgression.can_feed_on_cars(GrowthProgression.target_scale(16)), "Car-food phase starts at wrong size"): return
	if not _check(DietProgression.can_feed_on_structures(GrowthProgression.target_scale(34)) and not DietProgression.can_feed_on_structures(GrowthProgression.target_scale(28)), "Structure food phase not tied to body scale"): return
	if not _check(DietProgression.can_grab_people(3.34) and not DietProgression.can_grab_people(3.36), "Threshold based on hardcoded level instead of physical size"): return
	if not _check(DietProgression.car_biomass(1.0) == 0 and DietProgression.structure_biomass(1.0,"Bakery",Vector2(18,15)) == 0, "Hatchling is earning demolition food"): return
	# Destroying cars before sufficient growth still works as a weapon, but
	# earns no food and preserves a fleeing driver.
	var original_people: int = demo.civilians.size()
	demo._damage_car(4, 9.0)
	if not _check(demo.cars[4]["destroyed"] and demo.biomass == 0 and demo.civilians.size() == original_people + 1, "Early car destruction changed combat or granted biomass"): return
	# E22: upright can still grab people, and cars add a second food source.
	_clear_people(demo)
	demo.beast.global_position = Vector3(0,0,18)
	demo._apply_growth_milestone(22)
	demo._damage_car(5, 9.0)
	if not _check(demo.biomass == 75, "E22 car biomass missing or incorrect"): return
	if not _check(demo.bite_timer == 0.0, "Car demolition triggers tiny-person mouth animation"): return
	var car_reward: int = demo.biomass
	demo._damage_car(5, 9.0)
	if not _check(demo.biomass == car_reward, "Same vehicle awarded biomass twice"): return
	# E28 is still small enough for the previously approved arm/tongue grab.
	_clear_people(demo)
	demo._apply_growth_milestone(28)
	demo.bite_timer = 0.0
	demo._spawn_civilian(demo.beast.global_position + Vector3(0,0,-demo._normal_grab_reach()*.7))
	var human_reward_before: int = demo.biomass
	demo._update_biting(0.0)
	if not _check(demo.biomass == human_reward_before + 12 and demo.bite_timer > 0.0, "E28 no longer feeds on people"): return
	# E34: humans remain living world actors; no bite/arms/tongue capture.
	_clear_people(demo)
	if is_instance_valid(demo.prey_in_mouth):
		demo.prey_in_mouth.queue_free()
		demo.prey_in_mouth = null
	demo.bite_timer = 0.0
	demo._apply_growth_milestone(34)
	demo._spawn_civilian(demo.beast.global_position + Vector3(0,0,-4))
	var pedestrian: Node3D = demo.civilians[-1]["node"]
	var before_people: int = demo.biomass
	demo._update_biting(0.0)
	if not _check(demo.biomass == before_people and demo.civilians.size() == 1 and is_instance_valid(pedestrian) and demo.bite_timer == 0, "Giant grabbed tiny human despite diet transition"): return
	if not _check(not demo.tongue_root.visible, "Giant tongue remains visible after cutoff"): return
	# Original commercial structures award once only after collapse. Bigger
	# footprints yield more; failed/chip hits do not hand out resources.
	var bakery: int = 66
	var first_biomass: int = demo.biomass
	demo._damage_building(bakery, 0.1)
	if not _check(demo.biomass == first_biom and not demo.buildings[bakery]["destroyed"], "Chip damage grants structure food early"): return
	demo._damage_building(bakery, 50.0)
	var bakery_reward: int = demo.biomass - first_biom
	if not _check(bakery_reward > 50 and demo.buildings[bakery]["destroyed"], "E34 shop collapse lacks meaningful biomass"): return
	demo._damage_building(bakery, 99.0)
	if not _check(demo.biomass == first_biom + bakery_reward, "Already demolished structure paid twice"): return
	var store: int = 78
	var shop_name: String = demo.buildings[store]["name"]
	if not _check(shop_name == "Supermarket", "Store index changed"): return
	var before_store: int = demo.biomass
	demo._damage_building(store, 99.0)
	if not _check(demo.biomass - before_store > bakery_reward, "Big store pays no more biomass than a small shop"): return
	if not _check(DietProgression.diet_label(demo.growth_scale) == "BUILDINGS + CARS", "HUD food source doesn't follow physical size"): return
	# Debug E120 should still be able to crash through structures, but no
	# human feed even with auto-selected arm/tongue mutation history.
	if OS.has_feature("debug"):
		_clear_people(demo)
		demo._debug_evolve_batch(60)
		demo._debug_evolve_batch(60)
		if not _check(demo.evolutions == 120 and not DietProgression.can_grab_people(demo.growth_scale), "E120 debug batch restored human feeding"): return
		if not _check(demo.biomass > 0, "Debug batch destroyed earned building food"): return
	print("SCALE DIET TEST PASSED: arm-size cutoff, E22 cars, E28 humans, E34 buildings, one-time destruction rewards, E120 debug compatibility")
	quit(0)
