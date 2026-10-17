extends SceneTree
## Headless regression test for the beach evolution contract.

func _initialize() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	printerr("EVOLUTION TEST FAILED: " + message)
	paused = false
	quit(1)

func _vertices(node: Node) -> int:
	var total := 0
	if node is MeshInstance3D and node.is_visible_in_tree() and not node.get_meta("exclude_shed", false):
		for surface in range(node.mesh.get_surface_count()):
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			total += indices.size() if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()
	for child in node.get_children():
		total += _vertices(child)
	return total


func _run_test() -> void:
	var packed: PackedScene = load("res://scenes/BeachDemo.tscn")
	if packed == null:
		_fail("Could not load the beach scene")
		return
	var demo: Variant = packed.instantiate()
	root.add_child(demo)
	# This scenario exercises authored assets after explicitly requesting their chunks.
	for authored_index in range(demo.world.authored_count): demo._prepare_authored(authored_index)
	await process_frame
	var old_vertices := _vertices(demo.beast_visual)
	var body: MeshInstance3D = CreatureVisual.renderers(demo.creature_rig["visual"].forms[0])[0]
	var body_colour: Color = body.get_active_material(0).albedo_color
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
	var remnant: Node3D = demo.shedding.shed_remnants[0]["node"]
	var baked: MeshInstance3D = remnant.get_node_or_null("BakedSkin")
	if baked == null or _vertices(baked) != old_vertices:
		_fail("Static remnant bake lost prior creature geometry")
		return
	if body.get_active_material(0).albedo_color != body_colour:
		_fail("Shared live palette changed while shedding")
		return
	demo.biomass = 90
	demo._start_evolution()
	if not demo.evolving:
		_fail("Second evolution could not start")
		return
	demo._take_damage(50.0)
	if demo.evolving or demo.biomass != 0 or demo.armour != 1:
		_fail("Failed evolution must lose all stored biomass, preserving mutations")
		return
	if demo.shedding.shed_remnants.size() != 1:
		_fail("Failed evolution must not add a permanent shed")
		return
	demo.shedding.shed_remnants[0]["age"] = 37.0
	demo.shedding._age_remnants(0.0)
	if baked.material_override.albedo_color.a >= 0.62:
		_fail("Baked remnant did not fade")
		return
	demo.shedding._age_remnants(4.0)
	if not demo.shedding.shed_remnants.is_empty():
		_fail("Baked remnant exceeded its lifetime")
		return
	print("EVOLUTION TEST PASSED: old-form snapshot, choice pause, tap reveal, history, carryover, failed evolution, full-geometry bake and fade")
	quit(0)
