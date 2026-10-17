extends SceneTree
## One Android tap chooses multiple levels, applies growth + mutation history once.

func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, why: String) -> bool:
	if not ok:
		printerr("BATCH DEBUG TEST FAILED: " + why)
		paused = false
		quit(1)
	return ok


func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	if not _check(demo.evolutions == 0 and demo._cost() == 55, "Changed regular evolution baseline"): return
	if not OS.has_feature("debug"):
		demo._debug_evolve_batch(34)
		if not _check(demo.evolutions == 0, "Debug cheat active in non-debug environment"): return
		print("BATCH DEBUG TEST PASSED: non-debug build excludes batch evolution")
		quit(0)
		return
	if not _check(demo.debug_batch_dialog != null and demo.debug_batch_spin != null and demo.debug_evolve_button.visible, "Mobile batch selector not constructed"): return
	demo._debug_evolve()
	if not _check(demo.debug_batch_dialog.visible, "DEBUG EVO did not show the level chooser"): return
	if not _check(int(demo.debug_batch_spin.value) == 5, "Default batch not five levels"): return
	demo._debug_select_preset(34)
	if not _check(int(demo.debug_batch_spin.value) == 34 and demo.debug_batch_preview.text.contains("E34"), "Preset or projected evolution preview incorrect"): return
	# Cancel retains all existing state.
	demo.debug_batch_dialog.hide()
	if not _check(demo.evolutions == 0 and demo.evolution_history.is_empty(), "Closing batch dialog changed levels"): return
	# No feeding, no mutations menus, no 34 sequential reveals.
	demo.biomass = 0
	demo._debug_evolve_batch(34)
	if not _check(demo.evolutions == 34 and demo.evolution_history.size() == 34 and demo.biomass == 0, "Batch did not apply 34 free levels"): return
	if not _check(not demo.evolving and not demo.choice_open and not demo.reveal_active and not paused, "Batch left behind an evolution pause or reveal"): return
	if not _check(demo.growth_stage == 6 and demo.upright_form and is_equal_approx(demo.growth_scale, GrowthProgression.target_scale(34)), "Skipped growth milestones or upright transformation"): return
	if not _check(demo.beast_collision_shape.radius > 5.0 and is_equal_approx(demo.beast_collision_shape.radius, 1.85 * demo.growth_scale), "Body collision didn't scale with batch"): return
	if not _check(demo.hp == demo.max_hp and demo.stamina == demo.max_stamina and demo.max_hp > demo.BASE_HP and demo.strength > 0 and demo.cocoon_rank > 0, "Balanced auto-mutations didn't apply stats and health"): return
	if not _check(demo.mutation_visual_counts.size() == 9, "Batch omitted a mutation family visual"): return
	for id in demo.mutation_visual_counts:
		if not _check(int(demo.mutation_visual_counts[id]) >= 3, "Batch didn't record cosmetic tiers"): return
	for n in range(demo.evolution_history.size()):
		var item: Dictionary = demo.evolution_history[n]
		if not _check(int(item["step"]) == n + 1, "Evolution history lost step order"): return
		if not _check(bool(item["size_changed"]) == GrowthProgression.is_growth_step(n + 1), "Evolution history missed size milestone"): return
	# Selection is additive, and another confirm advances all requested levels.
	demo._debug_evolve()
	demo.debug_batch_spin.value = 6.0
	demo.debug_batch_dialog.hide()
	demo._debug_apply_selected_batch()
	if not _check(demo.evolutions == 40 and demo.evolution_history.size() == 40 and demo.growth_stage == 7, "Second selected batch didn't reach E40"): return
	if not _check(is_equal_approx(demo.growth_scale, GrowthProgression.target_scale(40)), "Later recurring growth increments not preserved"): return
	var old_level := demo.evolutions
	var old_visuals := demo.mutation_visual_counts.duplicate()
	demo._debug_evolve_batch(0)
	demo._debug_evolve_batch(61)
	if not _check(demo.evolutions == old_level and demo.mutation_visual_counts == old_visuals, "Out-of-range batch changed state"): return
	# Don't allow modal/pause exploits, and ensure normal evolution still works.
	demo.choice_open = true
	demo._debug_evolve_batch(5)
	if not _check(demo.evolutions == old_level, "Batch ran during mutation choice"): return
	demo.choice_open = false
	demo.reveal_active = true
	demo._debug_evolve_batch(5)
	if not _check(demo.evolutions == old_level, "Batch ran during skin reveal"): return
	demo.reveal_active = false
	demo.evolving = true
	demo._debug_evolve_batch(5)
	if not _check(demo.evolutions == old_level, "Batch ran during ordinary vulnerable evolution"): return
	demo.evolving = false
	demo.biomass = demo._cost()
	demo._start_evolution()
	if not _check(demo.evolving and demo.evolution_clock > 0.0, "Ordinary biomass evolution broke after batching"): return
	print("BATCH DEBUG TEST PASSED: selectable 34+6 levels, instant E40, correct growth/mutations/history, additive batches, guarded input and normal evolution")
	quit(0)
