extends SceneTree
## Phone report: at E34 rooftops/cars could not be smashed and the upright
## predator still faceplanted to eat. Verify actual gameplay at growth scales.

func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, why: String) -> bool:
	if not ok:
		printerr("GIANT FEEDING TEST FAILED: " + why)
		paused = false
		quit(1)
	return ok


func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	if not _check(demo.evolutions == 0 and not demo.upright_form, "Changed hatchling state"): return
	if not _check(is_equal_approx(demo._bite_reach(), demo.BITE_RANGE), "Tongue gave hatchling extra reach"): return
	if not _check(demo._effective_demolition_strength() == 0, "Hatchling automatically stronger"): return
	# Preserve low-level strength gating and gradual cracks.
	var shop_index := 66
	var shop: Dictionary = demo.buildings[shop_index]
	if not _check(shop["name"] == "Bakery", "Test shop order changed"): return
	demo.beast.global_position = shop["position"] + Vector3(0, 7, 0)
	demo._giant_proximity_contact()
	if not _check(not demo.buildings[shop_index]["destroyed"], "Small creature demolished shop without collision"): return
	# E34: effective structural strength comes from physical size, even with
	# no purchased strength mutations. Body may be on top of a low roof.
	demo._apply_growth_milestone(34)
	if not _check(demo.upright_form and demo.growth_stage == 6 and demo._effective_demolition_strength() >= 4, "E34 giant lacks mass-driven strength"): return
	demo.strength = 0
	demo.sprint_active = true
	demo.beast.global_position = shop["position"] + Vector3(0, 11, 0)
	var before_shop_food: int = demo.biomass
	demo._giant_proximity_contact()
	if not _check(demo.buildings[shop_index]["destroyed"] and demo.debris.size() > 0, "E34 giant standing over shop could not crush it"): return
	if not _check(demo.biomass > before_shop_food, "E34 structure destruction does not provide food"): return
	# Car on the other side of the world should remain intact.
	var car_index := 4
	var car: Dictionary = demo.cars[car_index]
	if not _check(not car["destroyed"], "Cars already broken"): return
	demo.beast.global_position = car["node"].global_position + Vector3(0, 8.0, 0)
	var before_car_food: int = demo.biomass
	demo._giant_proximity_contact()
	if not _check(demo.cars[car_index]["destroyed"], "E34 giant on top of parked car did not squash it"): return
	if not _check(demo.biomass > before_car_food, "E34 car destruction gives no biomass"): return
	if not _check(demo._car_for_collider(car["collider"]) < 0, "Smashed car still active in collision mapping"): return
	# E34 is past the body-size cutoff: don't try to pinch a tiny human.
	demo.sprint_active = false
	demo.beast.global_position = Vector3(0, 0, 18)
	demo.beast.rotation = Vector3.ZERO
	demo._spawn_civilian(Vector3(0,0,13))
	var uneaten_person: Node3D = demo.civilians[-1]["node"]
	var before_people_food: int = demo.biomass
	demo.bite_timer = 0.0
	demo._update_biting(0.0)
	if not _check(is_instance_valid(uneaten_person) and demo.biomass == before_people_food, "E34 still swallows tiny people"): return
	# Test the actual arm and tongue animations just before they become
	# implausible, at E28 (upright but still small enough to grab people).
	demo.civilians.pop_back()
	uneaten_person.queue_free()
	demo._apply_growth_milestone(28)
	# The two arms raise prey; the head stays relatively still and doesn't
	# dive toward the road when upright.
	demo.bite_timer = 0.0
	demo._update_creature_animation(.3,false)
	var head_before: float = demo.head_pivot.global_position.y
	var arm_before: float = demo.leg_pivots[0].rotation.x
	demo.bite_timer = demo.bite_duration * .50
	demo._update_creature_animation(.12,false)
	if not _check(demo.head_pivot.global_position.y > head_before - demo.growth_scale * .35, "Upright still dives head toward ground"): return
	if not _check(demo.leg_pivots[0].rotation.x > arm_before + .25 and demo.leg_pivots[2].rotation.x > arm_before + .25, "Both front arms do not reach out"): return
	if not _check(demo.creature_rig["lower_limbs"][0].rotation.x < -.45 and demo.creature_rig["lower_limbs"][2].rotation.x < -.45, "Elbows do not bend into grip"): return
	# Distant prey triggers the tongue rather than silently jumping to mouth.
	demo.bite_timer = 0.0
	var normal_reach: float = demo._normal_grab_reach()
	if not _check(demo._bite_reach() > normal_reach * 1.44, "Upright tongue does not extend range"): return
	var target: Vector3 = demo.beast.global_position + Vector3(0, 0, -normal_reach * 1.25)
	demo._spawn_civilian(target)
	var previous_biomass: int = demo.biomass
	demo.beast.rotation.y = 0.0
	demo._update_biting(0.0)
	if not _check(demo.biomass == previous_biomass + 12 and demo.tongue_active and is_instance_valid(demo.prey_in_mouth), "Long-range tongue capture failed"): return
	demo.bite_timer = demo.bite_duration * .65
	demo._update_creature_animation(.1, false)
	if not _check(demo.tongue_root.visible and demo.tongue_length_mesh.scale.y > 0.2, "Tongue not visible while pulling distant prey"): return
	if not _check(demo.prey_in_mouth.global_position.distance_to(demo.prey_origin) > .1, "Tongue did not physically pull prey"): return
	demo.bite_timer = 0.0
	demo._update_creature_animation(.1, false)
	if not _check(not demo.tongue_root.visible and not demo.tongue_active, "Tongue remained visible after feeding"): return
	# Close prey must use arm grab without deploying the tongue.
	demo._spawn_civilian(demo.beast.global_position + Vector3(0,0,-normal_reach * .75))
	demo.bite_timer = 0.0
	demo._update_biting(0.0)
	if not _check(not demo.tongue_active and is_instance_valid(demo.prey_in_mouth), "Close prey incorrectly uses tongue instead of hands"): return
	print("GIANT FEEDING TEST PASSED: E34 shop/car crush and demolition nutrition, size-gated E28 arms/tongue pull, hatchling contract")
	quit(0)
