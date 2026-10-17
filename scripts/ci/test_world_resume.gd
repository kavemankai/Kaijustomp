extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,reason: String) -> void:
	if not ok:
		failed = true
		printerr("WORLD RESUME TEST FAILED: "+reason)
func run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	demo.world.state.path = "user://resume-regression-%d.json" % Time.get_ticks_usec()
	var path: String = demo.world.state.path
	demo._damage_car(4,1000)
	demo._debug_evolve_batch(34)
	demo.beast.position=Vector3(3072,0,-3072)
	demo.world.ensure_region(demo.beast.position,220)
	var indices: Array = demo.world.chunks[Vector2i(12,-12)]["indices"]
	check(indices.size()>1,"No expanded save targets")
	if indices.size()<2: quit(1); return
	var id: String = demo.buildings[indices[0]]["id"]
	var damaged_id: String = demo.buildings[indices[1]]["id"]
	demo._damage_building(indices[0],10000)
	demo._damage_building(indices[1],2)
	var hits: float = demo.buildings[indices[1]]["hits"]
	var biomass: int = demo.biomass
	demo.alert=90
	demo.heat_cooldown=25
	check(demo.world.save_now(),"Scene snapshot failed")
	var saved_position: Vector3 = demo.beast.position
	var evacuation_count: int = demo.evacuations.remaining()
	demo.queue_free()
	await process_frame
	var resumed = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(resumed)
	resumed.set_physics_process(false)
	for c in resumed.world.chunks.keys(): resumed.world._unload(c)
	var loaded := WorldState.new()
	loaded.path=path
	check(loaded.read_save(),"Saved snapshot unreadable")
	resumed.world.state=loaded
	for b in resumed.buildings:
		if not b.get("vacant",false): loaded.apply(b)
	resumed.world.restore_player()
	resumed.world.restore_vehicles()
	resumed.world.ensure_region(saved_position,220)
	await physics_frame
	check(resumed.beast.position.distance_to(saved_position)<.01,"Saved position changed on reload")
	check(resumed.evolutions==34 and resumed.upright_form and resumed.evolution_history.size()==34,"Evolution/history lost on restart")
	check(resumed.biomass==biomass and resumed.alert==90 and resumed.heat_cooldown==25,"Biomass or persistent DEFCON state lost")
	check(resumed.cars[4]["destroyed"],"Important destroyed vehicle respawned")
	check(resumed.evacuations.remaining()==evacuation_count,"Evacuations duplicated or lost on restart")
	var i: int = resumed._index_for_world_id(id)
	check(i>=0 and resumed.buildings[i]["destroyed"],"Destroyed generated building respawned after disk reload")
	i=resumed._index_for_world_id(damaged_id)
	check(i>=0 and is_equal_approx(resumed.buildings[i]["hits"],hits),"Damaged generated building reset after disk reload")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	if not failed: print("WORLD RESUME TEST PASSED: disk restart preserves player, mutations, position, DEFCON, destroyed car, evacuation ledger, building damage and rewards")
	quit(1 if failed else 0)
