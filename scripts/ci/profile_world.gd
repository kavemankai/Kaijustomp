extends SceneTree
## CPU/scene probe. Rendering and static memory values are desktop-only.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var start := Time.get_ticks_usec()
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	print("WORLD PROFILE startup_ms=%.3f nodes=%d static_mib=%.2f" % [
		(Time.get_ticks_usec() - start) / 1000.0, root.get_tree().get_node_count(), OS.get_static_memory_usage() / 1048576.0])
	for level in [0, 5, 16, 22, 28, 34, 55, 80, 120]:
		if level > 0:
			demo._debug_evolve_batch(level - demo.evolutions)
		demo.beast.global_position = Vector3(0, 0, 18)
		demo.touch_vector = Vector2.ZERO
		await physics_frame
		var timings: Array[float] = []
		for frame in range(120):
			start = Time.get_ticks_usec()
			demo._physics_process(1.0 / 60.0)
			timings.append((Time.get_ticks_usec() - start) / 1000.0)
			await process_frame
		timings.sort()
		print("WORLD PROFILE E%d scale=%.3f cpu_update_median_ms=%.3f p95_ms=%.3f nodes=%d" % [
			level, demo.growth_scale, timings[60], timings[114], get_node_count()])
	quit(0)
