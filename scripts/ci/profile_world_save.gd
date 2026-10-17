extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var rows := []
	for count in [0,100,1000,5000,10000]:
		var state := WorldState.new()
		state.path="user://world-save-profile-%d.json" % Time.get_ticks_usec()
		state.player={"biomass":1000,"position":[0,0,0]}
		for i in range(count): state.objects["g1:%d:-12:0" % i]={"destroyed":true,"hits":0,"hidden":0,"reward_claimed":true}
		var samples: Array[float] = []
		for iteration in range(10):
			var began := Time.get_ticks_usec()
			if not state.write_save():
				printerr("SAVE PROFILE FAILED")
				quit(1)
				return
			samples.append((Time.get_ticks_usec()-began)/1000.0)
		samples.sort()
		var bytes := FileAccess.get_file_as_bytes(state.path).size()
		var row := {"modified_objects":count,"bytes":bytes,"write_p50_ms":samples[5],"write_p95_ms":samples[9]}
		rows.append(row)
		print("SAVE PROFILE "+JSON.stringify(row))
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(state.path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(state.path+suffix))
	DirAccess.make_dir_recursive_absolute("res://build/world-profile")
	var file := FileAccess.open("res://build/world-profile/save.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rows,"\t"))
	quit()
