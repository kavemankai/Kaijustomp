extends SceneTree
func _initialize() -> void: call_deferred("run")
func percentile(values: Array[float],fraction: float) -> float:
	values.sort()
	return values[mini(values.size()-1,int(values.size()*fraction))]
func run() -> void:
	var began := Time.get_ticks_usec()
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	var report := {"engine":Engine.get_version_info()["string"],"startup_ms":(Time.get_ticks_usec()-began)/1000.0,"startup_nodes":get_node_count(),"startup_static_mib":OS.get_static_memory_usage()/1048576.0,"samples":[]}
	for level in [0,34,55,80,120]:
		if demo.evolutions<level: demo._debug_evolve_batch(level-demo.evolutions)
		demo.beast.position=Vector3(3072,0,-3072)
		demo._update_camera(1)
		demo.world.generation_times.clear()
		demo.world.max_tick_ms=0
		var times: Array[float] = []
		var frames: Array[float] = []
		var last_frame := Time.get_ticks_usec()
		var peak_nodes := get_node_count()
		var peak_chunks := 0
		for frame in range(360):
			demo.beast.position.x+=5
			began=Time.get_ticks_usec()
			demo._physics_process(1.0/60)
			times.append((Time.get_ticks_usec()-began)/1000.0)
			peak_nodes=maxi(peak_nodes,get_node_count())
			peak_chunks=maxi(peak_chunks,demo.world.chunks.size())
			await process_frame
			var now := Time.get_ticks_usec()
			frames.append((now-last_frame)/1000.0)
			last_frame=now
		var item := {"evolution":level,"cpu_p50_ms":percentile(times,.5),"cpu_p95_ms":percentile(times,.95),"cpu_p99_ms":percentile(times,.99),"cpu_max_ms":times.max(),"frame_p95_ms":percentile(frames,.95),"peak_nodes":peak_nodes,"peak_chunks":peak_chunks,"registry_slots":demo.buildings.size(),"static_mib":OS.get_static_memory_usage()/1048576.0,"generation_p95_ms":percentile(demo.world.generation_times.duplicate(),.95),"generation_max_ms":demo.world.generation_times.max(),"stream_tick_max_ms":demo.world.max_tick_ms}
		report["samples"].append(item)
		print("STREAM PROFILE "+JSON.stringify(item))
	DirAccess.make_dir_recursive_absolute("res://build/world-profile")
	var mode := "headless" if DisplayServer.get_name()=="headless" else "rendered"
	var file := FileAccess.open("res://build/world-profile/%s.json" % mode,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	quit()
