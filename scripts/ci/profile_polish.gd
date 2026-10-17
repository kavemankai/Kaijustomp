extends SceneTree
## Rendered desktop route. -- --seconds=900 requests a real 15-minute session.
var seconds := 90.0
func _initialize() -> void: call_deferred("run")
func percentile(values: Array[float],q: float) -> float:
	return values[clampi(int(values.size()*q),0,values.size()-1)] if not values.is_empty() else 0.0
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="): seconds=float(arg.trim_prefix("--seconds="))
	root.size=Vector2i(540,960)
	var demo=load("res://scenes/BeachDemo.tscn").instantiate();root.add_child(demo)
	demo.world.state.path="res://build/polish-evidence/profile-save.json"
	var begin := Time.get_ticks_usec();var previous := begin;var phase := -1
	var frames: Array[float]=[];var cpu: Array[float]=[]
	var draws := 0.0;var collisions := 0;var memory := 0;var nodes := 0
	var route: Array=[]
	while (Time.get_ticks_usec()-begin)/1000000.0<seconds:
		var elapsed := (Time.get_ticks_usec()-begin)/1000000.0
		var next_phase := mini(6,int(elapsed/(seconds/7)))
		if phase!=next_phase:
			phase=next_phase
			var family: String=["reptile","snake","bird","worm","spider","mole","ape"][phase]
			demo.genetics.fixture([family],3)
			for i in range(18 if phase==1 else 6): demo.genetics.genome.select_gene("physical_growth","profile_growth_%d"%i)
			for key in (["gene_029","gene_121","gene_122"] if phase==2 else (["gene_119"] if phase==3 else (["gene_052"] if phase==5 else []))): demo.genetics.genome.select_gene(key,key)
			demo.genetics.refresh();demo.beast.position=Vector3(0,0,-310)
			if demo.genetics.trail.live: demo.genetics.trail.reset(demo.beast.position,Vector3.BACK)
			if phase==2: demo.genetics.traversal.activate("flight");demo.genetics.traversal.vertical_input=1
			if phase in [3,5]: demo.genetics.traversal.activate("burrow")
			demo.hp=10000;demo.max_hp=10000
			route.append({"phase":phase,"family":family,"elapsed":elapsed})
		demo.touch_vector=Vector2(sin(elapsed*.3)*.35,-.65)
		demo.stamina=maxf(demo.stamina,30)
		await process_frame
		var now := Time.get_ticks_usec()
		if elapsed>3:
			frames.append((now-previous)/1000.0);cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		previous=now
		draws=maxf(draws,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		collisions=maxi(collisions,demo.genetics.trail.contact_areas.size() if demo.genetics.trail.live else 0)
		memory=maxi(memory,OS.get_static_memory_usage());nodes=maxi(nodes,get_node_count())
	frames.sort();cpu.sort()
	var report := {"platform":OS.get_name(),"renderer":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()["string"],"duration_seconds":seconds,"frame_count":frames.size(),"frame_ms":{"median":percentile(frames,.5),"p95":percentile(frames,.95),"p99":percentile(frames,.99)},"process_ms":{"median":percentile(cpu,.5),"p95":percentile(cpu,.95),"p99":percentile(cpu,.99)},"peak_static_bytes":memory,"peak_draw_calls":draws,"peak_axial_colliders":collisions,"peak_nodes":nodes,"route":route,"limitations":"Desktop wall-clock frames; not Android FPS. No RSS, battery or thermal measurements. Fixture changes are included. Spider phase is ground stress; wall climbing tested separately."}
	DirAccess.make_dir_recursive_absolute("res://build/polish-evidence")
	FileAccess.open("res://build/polish-evidence/profile.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("POLISH PROFILE ",JSON.stringify(report));quit()
