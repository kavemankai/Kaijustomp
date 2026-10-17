extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var state := WorldState.new()
	state.path="user://async-regression-%d.json" % Time.get_ticks_usec()
	state.player={"biomass":0,"position":[0,0,0]}
	for i in range(1000): state.objects["g1:%d:-12:0" % i]={"destroyed":true,"hits":0,"hidden":0,"reward_claimed":true}
	var writer := WorldSaveWriter.new()
	var failed := false
	for value in range(25):
		state.player["biomass"]=value
		if not writer.request(state) or writer.queued_count()>2: failed=true
	# Mutating live state afterwards must not change an in-flight snapshot.
	state.player["biomass"]=999
	state.objects.clear()
	if not writer.flush(): failed=true
	var loaded := WorldState.new()
	loaded.path=state.path
	if not loaded.read_save() or loaded.player.get("biomass")!=24 or loaded.objects.size()!=1000: failed=true
	if writer.queued_count()!=0: failed=true
	# Flush/join also makes the previous worker harmless before a fresh run resets data.
	state.player={}
	state.events={}
	if not state.write_save(): failed=true
	loaded=WorldState.new()
	loaded.path=state.path
	if not loaded.read_save() or not loaded.player.is_empty() or not loaded.objects.is_empty(): failed=true
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(state.path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(state.path+suffix))
	if failed: printerr("WORLD ASYNC SAVE TEST FAILED: coalescing, snapshot isolation, flush or restart ownership")
	else: print("WORLD ASYNC SAVE TEST PASSED: bounded coalescing, detached player/object snapshots, atomic disk writes and flush-before-reset")
	quit(1 if failed else 0)
