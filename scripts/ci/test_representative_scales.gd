extends SceneTree
## Exercise real scene growth, swept bodies, skin foot stance and framing.
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, reason: String) -> void:
	if not ok:
		failed = true
		printerr("REPRESENTATIVE SCALES TEST FAILED: " + reason)

func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	for level in [0, 5, 16, 22, 28, 34, 55, 80, 120]:
		if level > demo.evolutions:
			demo._debug_evolve_batch(level - demo.evolutions)
		check(demo.evolutions == level and is_equal_approx(demo.growth_scale, GrowthProgression.target_scale(level)), "Wrong size at E%d" % level)
		check(is_equal_approx(demo.beast_collision_shape.radius, 1.85 * demo.growth_scale), "Body collider scale mismatch at E%d" % level)
		demo.beast.position = Vector3(0, 0, 18)
		demo.beast.rotation = Vector3.ZERO
		demo._update_camera(1)
		var visual: CreatureVisual = demo.creature_rig["visual"]
		var skeleton: Skeleton3D = visual.skeletons[1 if demo.upright_form else 0]
		var paw := skeleton.find_bone("Paw1" if demo.upright_form else "Paw0")
		# Select a planted phase for each supporting foot.
		var phase := PI + 0.2 if demo.upright_form else 0.2
		demo.beast_visual.position.y = 0.1
		demo.beast_visual.rotation.z = 0.04
		visual.update_pose(demo.upright_form, true, phase)
		var first := skeleton.to_global(skeleton.get_bone_global_pose(paw).origin)
		check(absf(first.y - 0.03 * demo.growth_scale) < 0.003, "Planted foot leaves ground at E%d" % level)
		var travel: float = 0.1 * demo.growth_scale
		demo.beast.position.z -= travel
		visual.update_pose(demo.upright_form, true, phase + travel * TAU / (2.5 * demo.growth_scale))
		var second := skeleton.to_global(skeleton.get_bone_global_pose(paw).origin)
		check(first.distance_to(second) < 0.003, "Stance foot slides during scaled travel at E%d" % level)
		for dimensions in [Vector2i(540, 960), Vector2i(540, 1200)]:
			root.size = dimensions
			demo._update_camera(1)
			check(demo.follow_camera.is_position_in_frustum(demo.head_pivot.global_position), "Head outside portrait camera at E%d" % level)
		# Deliberately overlap an industrial target, then resolve physical shape
		# clearance. The old 16-unit search cannot escape this warehouse.
		demo.beast.position = demo.buildings[102]["position"]
		await physics_frame
		demo._resolve_growth_clearance()
		await physics_frame
		check(demo._growth_position_clear(demo.beast.position), "Industrial overlap unresolved at E%d" % level)
		check(absf(demo.beast.position.x) <= demo.PLAYABLE_HALF_LENGTH and demo.beast.position.z >= demo.NEIGHBOURHOOD_FAR_Z,
			"Growth clearance leaves world at E%d" % level)
	if not failed:
		print("REPRESENTATIVE SCALES TEST PASSED: E0/5/16/22/28/34/55/80/120 collision, skin stance, travel, portrait framing and industrial clearance")
	quit(1 if failed else 0)
