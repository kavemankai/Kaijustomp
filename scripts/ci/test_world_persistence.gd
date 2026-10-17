extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,reason: String) -> void:
	if not ok:
		failed = true
		printerr("WORLD PERSISTENCE TEST FAILED: "+reason)
func run() -> void:
	var state := WorldState.new()
	state.path = "user://world-regression-%d.json" % Time.get_ticks_usec()
	state.player = {"biomass":30,"position":[2500,0,-3000]}
	state.remember({"id":"fixture","destroyed":true,"hits":0.,"max_hits":5.,"hidden":0,"reward_claimed":true})
	check(state.write_save(),"Initial save failed")
	state.player["biomass"] = 40
	check(state.write_save(),"Atomic replacement failed")
	var loaded := WorldState.new()
	loaded.path = state.path
	check(loaded.read_save() and loaded.player["biomass"]==40,"Player state did not round trip")
	check(loaded.objects["fixture"]["reward_claimed"],"Reward ledger lost")
	var file := FileAccess.open(state.path,FileAccess.WRITE)
	file.store_string("interrupted write")
	file.close()
	var recovered := WorldState.new()
	recovered.path = state.path
	check(recovered.read_save() and recovered.recovery=="backup" and recovered.player["biomass"]==30,"Corrupt save did not recover previous-good backup")
	var migrated := state.document()
	migrated["version"] = 0
	migrated.erase("events")
	file = FileAccess.open(state.path,FileAccess.WRITE)
	file.store_string(JSON.stringify(migrated))
	file.close()
	loaded = WorldState.new()
	loaded.path = state.path
	check(loaded.read_save() and loaded.recovery=="migrated" and loaded.write_save(),"v0 migration failed")
	for malformed in [{"events":{"vehicles":[]}}, {"player":{"history":["invalid entry"]}}]:
		var invalid := state.document()
		for key in malformed: invalid[key]=malformed[key]
		file=FileAccess.open(state.path,FileAccess.WRITE)
		file.store_string(JSON.stringify(invalid))
		file.close()
		loaded=WorldState.new()
		loaded.path=state.path
		check(loaded.read_save() and loaded.recovery=="backup","Malformed nested save bypasses recovery")
	migrated["version"] = 999
	file = FileAccess.open(state.path,FileAccess.WRITE)
	file.store_string(JSON.stringify(migrated))
	file.close()
	loaded = WorldState.new()
	loaded.path = state.path
	check(not loaded.read_save() and not loaded.writable and not loaded.write_save(),"Future save was overwritten")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(state.path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(state.path+suffix))
	if not failed: print("WORLD PERSISTENCE TEST PASSED: player/reward deltas, atomic replacement, corrupt recovery, migration and future-format protection")
	quit(1 if failed else 0)
