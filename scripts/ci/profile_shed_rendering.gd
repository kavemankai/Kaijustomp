extends SceneTree
## Manual desktop rendering probe, never evidence of Android performance.
## godot --path . --script res://scripts/ci/profile_shed_rendering.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	root.size = Vector2i(540, 960)
	await process_frame
	for shed_count in [0, 5]:
		if shed_count == 5:
			for i in range(5):
				demo.shedding.begin_shed(demo.beast_visual)
				demo.shedding.start_reveal()
				demo.shedding.reveal_progress = 1.0
				demo.shedding._process(0.0)
		for i in range(60):
			await process_frame
			await RenderingServer.frame_post_draw
		print("SHED RENDER PROBE: sheds=%d draw_calls=%d primitives=%d static_memory_mib=%.2f" % [shed_count, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), OS.get_static_memory_usage() / 1048576.0])
	quit()
