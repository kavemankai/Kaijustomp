extends SceneTree
## Behavioural coverage for bugs missed by the original anatomy/count tests.

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> bool:
	if not ok:
		printerr("GROWTH GAMEPLAY TEST FAILED: " + message)
		paused = false
		quit(1)
	return ok

func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	var expected := 1.0
	for level in range(1, 53):
		if level in [5, 10, 16, 22, 28, 34]:
			expected *= [1.20, 1.24, 1.28, 1.32, 1.24, 1.20][[5, 10, 16, 22, 28, 34].find(level)]
		elif level in [40, 46, 52]:
			expected *= 1.16
		if not _check(is_equal_approx(GrowthProgression.target_scale(level), expected), "Wrong relative size at %d" % level): return
	# Drive six actual mutation selections, including paused shedding/reveal.
	for id in ["armour", "speed", "stamina", "jaw", "strength", "health"]:
		demo.biomass = demo._cost() + 10
		demo._start_evolution()
		demo._finish_evolution()
		demo._choose_mutation(id)
		demo.shedding.reveal_progress = 1.0
		demo.shedding._process(0.0)
		await process_frame
	if not _check(demo.evolutions == 6 and demo.growth_stage == 1 and is_equal_approx(demo.growth_scale, 1.20), "L6 must have one growth after real choices"): return
	if not _check(demo.armour == 1 and demo.strength == 1 and demo.speed_bonus > 0 and demo.max_stamina == 135 and demo.max_hp == 125 and demo.bite_duration < 0.55, "Mutations did not accumulate"): return
	if not _check(demo.shedding.shed_remnants.size() == 5, "Shed budget exceeded"): return
	# Clear NPCs, then prove a larger creature can eat outside hatchling reach.
	for npc in demo.civilians:
		npc["node"].queue_free()
	demo.civilians.clear()
	demo._apply_growth_milestone(16)
	demo.bite_timer = 0.0
	demo.beast.rotation = Vector3.ZERO
	var food: Vector3 = demo.beast.global_position + Vector3(0, 0, -demo.BITE_RANGE * demo.growth_scale * 0.95)
	demo._spawn_civilian(food)
	var biomass_before: int = demo.biomass
	demo._update_biting(0.0)
	if not _check(demo.biomass == biomass_before + 12 and demo.civilians.is_empty(), "Large quadruped cannot feed at its scaled snout"): return
	# Real paused L22 reveal must already expose a usable upright pose.
	demo.evolutions = 21
	demo.bite_timer = 0.0
	demo.biomass = demo._cost()
	demo._start_evolution()
	demo._finish_evolution()
	demo._choose_mutation("jaw")
	if not _check(paused and demo.reveal_active and demo.torso_pivot.rotation.x > 1.0, "Upright pose not ready during paused reveal"): return
	for bite in [0.0, demo.bite_duration * 0.5, 0.0]:
		demo.bite_timer = bite
		demo._update_creature_animation(0.016, false)
		var actual: Vector3 = demo.beast.to_local(demo.head_pivot.to_global(Vector3(0, -0.16, -1.11)))
		if not _check(actual.distance_to(demo.head_collision_node.position) < 0.001, "Head collider trails current pose"): return
		var head_forward: Vector3 = -demo.head_pivot.global_basis.z.normalized()
		if not _check(head_forward.dot(Vector3.FORWARD) > 0.95, "Upright head points skyward"): return
	# Camera may ease during reveal but gameplay must remain frozen.
	var old_camera: Vector3 = demo.follow_camera.global_position
	var old_beast: Vector3 = demo.beast.global_position
	demo._physics_process(0.1)
	if not _check(demo.beast.global_position == old_beast and demo.follow_camera.global_position != old_camera, "Reveal camera or gameplay pause broken"): return
	demo.shedding.reveal_progress = 1.0
	demo.shedding._process(0.0)
	# Later non-growth mutations must preserve the raised form through shedding.
	demo.biomass = demo._cost()
	demo._start_evolution()
	demo._update_evolution_animation(0.1)
	if not _check((-demo.head_pivot.global_basis.z.normalized()).dot(Vector3.FORWARD) > 0.95, "Later evolution loses upright neck compensation"): return
	demo._finish_evolution()
	demo._choose_mutation("armour")
	if not _check((-demo.head_pivot.global_basis.z.normalized()).dot(Vector3.FORWARD) > 0.95, "Non-growth reveal points head skyward"): return
	demo.shedding.reveal_progress = 1.0
	demo.shedding._process(0.0)
	# Upright feeding still collects ground-level prey, without moving the player.
	demo.bite_timer = 0.0
	demo._spawn_civilian(demo.beast.global_position + Vector3(0, 0, -demo._bite_reach() * 0.95))
	biomass_before = demo.biomass
	demo._update_biting(0.0)
	if not _check(demo.biomass == biomass_before + 12, "Upright form cannot collect ground prey"): return
	# Grow against the cafe: expanded shapes must end outside the wall.
	demo.growth_scale = 1.0
	demo.upright_form = false
	demo.beast_visual.scale = Vector3.ONE
	demo.torso_pivot.rotation.x = 0.0
	demo._sync_beast_collision()
	demo.beast.global_position = Vector3(-21, 0, -30.9)
	await physics_frame
	if not _check(demo._growth_position_clear(demo.beast.global_position), "Wall fixture overlaps before growth"): return
	demo._apply_growth_milestone(16)
	await physics_frame
	if not _check(demo._growth_position_clear(demo.beast.global_position), "Growing creature stuck inside cafe"): return
	var impact: KinematicCollision3D = demo.beast.move_and_collide(Vector3(0, 0, -20))
	if not _check(impact != null and demo._building_for_collider(impact.get_collider()) >= 0, "Scaled creature tunnels through cafe"): return
	# Late-stage camera, both portrait ratios, and supporting hind feet.
	demo.beast.global_position = Vector3(0, 0, 18)
	demo._apply_growth_milestone(46)
	demo._update_creature_animation(1.0, false)
	for viewport_size in [Vector2i(540, 960), Vector2i(540, 1200)]:
		root.size = viewport_size
		demo._update_camera(1.0)
		var camera: Camera3D = demo.follow_camera
		if not _check(camera.is_position_in_frustum(demo.head_pivot.global_position) and camera.is_position_in_frustum(demo.beast.global_position), "Late creature clipped by camera"): return
		var view: Vector3 = (demo._camera_look_target() - camera.global_position).normalized()
		var approved_view: Vector3 = (Vector3(0, 0, -2.8) - demo.CAMERA_OFFSET * demo.PORTRAIT_CAMERA_DISTANCE).normalized()
		if not _check(view.dot(approved_view) > 0.99999, "Approved camera angle changed"): return
	for index in [1, 3]:
		var paw: Node3D = demo.creature_rig["paws"][index]
		if not _check(paw.global_basis.y.normalized().dot(Vector3.UP) > 0.99, "Upright hind paw not planted level"): return
	# Exhaustion requires a complete recharge, and restart creates clean state.
	demo.stamina = 0.01
	demo.sprint_requested = true
	demo.touch_vector = Vector2(0, -1)
	demo._update_movement(0.016)
	if not _check(demo.sprint_locked and not demo.sprint_requested, "Exhaustion lock lost"): return
	demo.stamina = demo.max_stamina - 1
	demo._toggle_sprint()
	if not _check(not demo.sprint_requested, "Sprint unlocked on partial recharge"): return
	demo.stamina = demo.max_stamina
	demo._update_movement(0.0)
	if not _check(not demo.sprint_locked, "Full recharge did not unlock sprint"): return
	demo.queue_free()
	await process_frame
	var fresh = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(fresh)
	if not _check(fresh.growth_scale == 1 and fresh.evolutions == 0 and not fresh.upright_form, "Scene restart retained previous evolution"): return
	print("GROWTH GAMEPLAY TEST PASSED: real choices to L6, cumulative stats, scaled feeding, paused L22, current head collider, wall clearance, late portrait camera, stance, sprint and restart")
	quit(0)
