extends SceneTree
## Growth is intentionally distinct from each level's chosen mutation.
## Covers early rapid levelling (L6 in ~2.5 min), six planned milestones,
## continuous post-34 growth, and the visual-only posture transition.

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("GROWTH TEST FAILED: " + message)
	paused = false
	quit(1)

func _run() -> void:
	var p: Array[int] = [5, 10, 16, 22, 28, 34, 40, 46]
	for level in range(0, 47):
		var expected_stage := 0
		for threshold in p:
			if level >= threshold:
				expected_stage += 1
		if GrowthProgression.stage_for(level) != expected_stage:
			_fail("Unexpected growth stage at level %d" % level)
			return
		if GrowthProgression.is_growth_step(level) != p.has(level):
			_fail("Growth fired between milestones at level %d" % level)
			return
		if GrowthProgression.next_growth_level(level) <= level:
			_fail("Next growth milestone should be in the future")
			return
	if GrowthProgression.target_scale(4) != 1.0:
		_fail("Hatchling should not grow before level 5")
		return
	if absf(GrowthProgression.target_scale(6) - 1.20) > 0.001:
		_fail("At level six creature should have only one modest growth")
		return
	if GrowthProgression.upright_for(21) or not GrowthProgression.upright_for(22):
		_fail("Upright transition must happen at level 22, not before")
		return
	var packed: PackedScene = load("res://scenes/BeachDemo.tscn")
	if packed == null:
		_fail("Beach demo scene missing")
		return
	var demo: Variant = packed.instantiate()
	root.add_child(demo)
	# This scenario exercises authored assets after explicitly requesting their chunks.
	for authored_index in range(demo.world.authored_count): demo._prepare_authored(authored_index)
	await physics_frame
	var original_camera_offset: Vector3 = demo._camera_offset()
	demo._apply_growth_milestone(3)
	if demo.growth_scale != 1.0 or demo.growth_stage != 0:
		_fail("Level three should not grow any more")
		return
	demo._apply_growth_milestone(5)
	demo.beast_visual.scale = Vector3.ONE * demo.growth_scale
	if demo.growth_stage != 1 or absf(demo.growth_scale - 1.20) > 0.001:
		_fail("First increase is wrong")
		return
	demo._apply_growth_milestone(6)
	if absf(demo.growth_scale - 1.20) > 0.001:
		_fail("Evolution six incorrectly grew the creature")
		return
	demo._apply_growth_milestone(10)
	demo._apply_growth_milestone(16)
	demo.beast_visual.scale = Vector3.ONE * demo.growth_scale
	if demo.growth_stage != 3 or demo.upright_form:
		_fail("Evolution sixteen must be a large quadruped")
		return
	if demo._camera_offset().length() <= original_camera_offset.length():
		_fail("Camera must back away as physical size increases")
		return
	demo._apply_growth_milestone(22)
	demo.beast_visual.scale = Vector3.ONE * demo.growth_scale
	demo._update_creature_animation(0.6, false)
	if not demo.upright_form or demo.growth_stage != 4:
		_fail("Dramatic form milestone did not activate")
		return
	if demo.torso_pivot.rotation.x < 0.7:
		_fail("Torso does not visibly stand upright")
		return
	if demo.head_collision_node.position.y < 2.5:
		_fail("Upright head collision did not follow raised head")
		return
	if demo.leg_pivots[1].get_parent() != demo.beast_visual:
		_fail("Grounded rear legs must remain attached to body root")
		return
	if demo.leg_pivots[0].get_parent() != demo.body_art_anchor:
		_fail("Front limbs must articulate with raised chest")
		return
	var size_at_22: float = demo.growth_scale
	demo._apply_growth_milestone(28)
	demo._apply_growth_milestone(34)
	demo._apply_growth_milestone(40)
	if demo.growth_scale <= size_at_22 or demo.growth_stage != 7:
		_fail("Large upright form must continue growing after level 22")
		return
	# Validate historical stages without applying any new gameplay changes.
	demo.evolutions = 4
	demo._record_evolution("armour")
	if not bool(demo.evolution_history[0]["size_changed"]) or int(demo.evolution_history[0]["growth_milestone"]) != 1:
		_fail("Evolution history omitted the level-five transformation")
		return
	demo.evolutions = 5
	demo._record_evolution("speed")
	if bool(demo.evolution_history[1]["size_changed"]):
		_fail("Normal mutation should not be marked as growth")
		return
	print("GROWTH TEST PASSED: milestones 5, 10, 16, 22, 28, 34, later every six; upright transform and collision")
	quit(0)
