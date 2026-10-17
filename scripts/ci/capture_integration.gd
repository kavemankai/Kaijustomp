extends SceneTree
## Desktop Compatibility captures and rendering counters, never phone metrics.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/integration-captures")
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	root.size = Vector2i(540, 960)
	for level in [0, 5, 16, 22, 28, 34, 55, 80, 120]:
		if level > demo.evolutions:
			demo._debug_evolve_batch(level - demo.evolutions)
		demo.beast.position = Vector3(0, 0, -900)
		demo.beast.rotation = Vector3.ZERO
		demo.run_phase = PI + 0.2
		demo._update_creature_animation(1.0, true)
		demo._update_camera(1.0)
		demo._update_hud()
		for frame in range(5):
			await process_frame
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/integration-captures/e%d.png" % level)
		print("DESKTOP RENDER E%d calls=%d primitives=%d static_mib=%.2f" % [level,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			OS.get_static_memory_usage() / 1048576.0])
	quit()
