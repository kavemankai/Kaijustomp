extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(540,960)
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://build/world-captures")
	var scenes := [
		{"name":"starting_beach","at":Vector3(0,0,10),"level":0},
		{"name":"banksia","at":Vector3(0,0,-150),"level":0},
		{"name":"expanded_city","at":Vector3(3072,0,-3072),"level":34},
		{"name":"inland","at":Vector3(6144,0,-5120),"level":55},
		{"name":"giant_world","at":Vector3(4096,0,-3072),"level":120},
		{"name":"giant_boundary","at":Vector3(9600,0,-5700),"level":120}]
	for item in scenes:
		while demo.evolutions<item["level"]: demo._debug_evolve_batch(mini(60,item["level"]-demo.evolutions))
		demo.beast.position=item["at"]
		demo.world.ensure_region(demo.beast.position,maxf(190,demo.growth_scale*4+20))
		demo._resolve_growth_clearance()
		demo._update_camera(1)
		demo.world.refresh()
		for frame in range(300):
			demo.world.advance(.016)
			await process_frame
			if demo.world.queue.is_empty() and frame>45: break
		demo._update_hud()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/world-captures/%s.png" % item["name"])
		print("WORLD RENDER %s E%d scale=%.3f chunks=%d nodes=%d draw_calls=%d primitives=%d" % [item["name"],demo.evolutions,demo.growth_scale,demo.world.chunks.size(),get_node_count(),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	quit()
