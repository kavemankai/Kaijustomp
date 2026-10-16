extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> bool:
	if not ok:
		printerr("COASTAL ART TEST FAILED: " + message)
		paused = false
		quit(1)
	return ok

func run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await process_frame
	if not check(demo.buildings.size() == 6,"Art changed the playable building set"): return
	for building in demo.buildings:
		var node: Node3D = building["node"]
		if not check(node.get_node_or_null("Architecture") != null,"Building missing combined artwork"): return
		if not check(is_instance_valid(building["collider"]),"Building art lost physical cover"): return
		for layer in building["crack_layers"]:
			if not check(layer.get_child_count() == 1,"Crack layer was not batched"): return
	var effects: CoastalEffects = demo.coastal_effects
	for i in range(100): effects.burst(Vector3.ZERO,20,2)
	if not check(effects.get_child_count() == 40,"Effect pool exceeded cap"): return
	effects._process(1)
	for item in effects.particles:
		if not check(not item["node"].visible,"Expired effect stayed visible"): return
	effects.burst(Vector3.ZERO,40)
	if not check(effects.get_child_count() == 40,"Effect reuse allocated more nodes"): return
	demo.evolutions = 3
	demo.biomass = 1000
	demo._start_evolution()
	demo._finish_evolution()
	for dimensions in [Vector2i(540,960),Vector2i(540,1200)]:
		root.size = dimensions
		await process_frame
		await process_frame
		var bounds := Rect2(Vector2.ZERO,root.get_visible_rect().size)
		if not check(bounds.encloses(demo.coastal_hud.get_global_rect()),"HUD clipped in portrait"): return
		var cards := 0
		for child in demo.choice_column.get_children():
			if child is Button:
				cards += 1
				if not check(child.icon != null and bounds.encloses(child.get_global_rect()),"Mutation preview missing or card clipped"): return
		if not check(cards == 7,"Seven-choice stress case was not exercised"): return
	paused = false
	print("COASTAL ART TEST PASSED: original buildings, batched cracks, bounded reusable effects, anatomical cards, 9:16 and 20:9 layout")
	quit()
