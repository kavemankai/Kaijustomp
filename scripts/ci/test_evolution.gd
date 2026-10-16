extends SceneTree
## Headless regression test for the beach evolution contract.

func _initialize() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	printerr("EVOLUTION TEST FAILED: " + message)
	paused = false
	quit(1)


func _run_test() -> void:
	var packed: PackedScene = load("res://scenes/BeachDemo.tscn")
	if packed == null:
		_fail("Could not load the beach scene")
		return
	var demo: Variant = packed.instantiate()
	root.add_child(demo)
	await process_frame
	demo.biomass = 80
	demo._start_evolution()
	if not demo.evolving or demo.shedding.current_shell == null:
		_fail("Evolution did not generate an old-form skin snapshot")
		return
	demo.shedding.update_shed_progress(0.85)
	if demo.shedding.cracks.is_empty() or not demo.shedding.cracks[0].visible:
		_fail("Skin cracks did not become visible")
		return
	demo._finish_evolution()
	if not paused or not demo.choice_open:
		_fail("Mutation selection must pause the game")
		return
	demo._choose_mutation("armour")
	if not paused or not demo.reveal_active:
		_fail("Reveal must remain paused until the shell breaks")
		return
	if demo.armour != 1 or demo.evolution_history.size() != 1:
		_fail("Chosen mutation must update the creature and history")
		return
	if demo.biomass != 25 or demo.evolutions != 1:
		_fail("Evolution must consume only one threshold and carry excess")
		return
	for i in range(7):
		demo.shedding.accelerate_reveal()
	await process_frame
	await process_frame
	if paused or demo.reveal_active:
		_fail("Tap-assisted skin reveal did not finish and unpause")
		return
	if demo.shedding.shed_remnants.size() != 1:
		_fail("Completed evolution must leave behind one old skin")
		return
	demo.biomass = 90
	demo._start_evolution()
	if not demo.evolving:
		_fail("Second evolution could not start")
		return
	demo._take_damage(40.0)
	if demo.evolving or demo.biomass != 0 or demo.armour != 1:
		_fail("Failed evolution must lose all stored biomass, preserving mutations")
		return
	if demo.shedding.shed_remnants.size() != 1:
		_fail("Failed evolution must not add a permanent shed")
		return
	print("EVOLUTION TEST PASSED: old-form snapshot, choice pause, tap reveal, history, carryover, failed evolution")
	quit(0)
