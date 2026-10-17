extends SceneTree
var failed := false
func check(ok: bool, reason: String) -> void:
	if not ok: failed=true; printerr("GENETICS LIVES TEST FAILED: "+reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var packed = load("res://scenes/BeachDemo.tscn")
	var demo = packed.instantiate()
	root.add_child(demo); demo.set_physics_process(false)
	await physics_frame
	var path := "user://genetics-lives-%d.json" % Time.get_ticks_usec()
	demo.world.state.path = path
	demo.genetics.fixture(["ape","crab"],3)
	demo.evolutions=6
	demo.biomass=800
	demo._damage_car(4,1000)
	demo._prepare_authored(0)
	demo._damage_building(0,1000)
	var id: String = demo.buildings[0]["id"]
	var remaining: int = demo.evacuations.remaining()
	demo.objectives.observe(demo,1)
	var objective_record: Dictionary = demo.world.state.events.get("objectives",{}).duplicate(true)
	check(demo.world.save_now(),"save mid-life")
	var loaded := WorldState.new(); loaded.path=path
	check(loaded.read_save(),"read mid-life")
	check(BeachGenetics.valid(loaded.player["genetics"]),"versioned genome validation")
	check(GenomeState.from_record(loaded.player["genetics"]["genome"]).identity()["kind"]=="hybrid","hybrid resumes")
	# Freeze an actual paused draft and reload it without rerolling.
	demo._start_evolution(); demo._finish_evolution()
	var frozen: Array = demo.genetics.genome.draft.duplicate()
	var frozen_state := WorldState.new(); frozen_state.path=path
	check(frozen_state.read_save(),"paused choice checkpoint")
	check(frozen_state.player["genetics"]["genome"]["draft"]==frozen,"actual offers persisted")
	paused=false; demo.choice_open=false; demo.modal.hide(); demo.modal_shade.hide(); demo.shedding.abort_shed()
	demo.genetics.genome.draft.clear()
	demo._take_damage(1000000)
	check(demo.game_over and demo.genetics.archive.lives.size()==1,"lethal damage finalizes once")
	demo.genetics.finalize_death()
	check(demo.genetics.archive.lives.size()==1,"death idempotent")
	check(demo.genetics.new_organism_keep_world(false),"atomic new-organism transition")
	var newborn := WorldState.new(); newborn.path=path
	check(newborn.read_save(),"new life survives disk restart")
	check(newborn.objects.has(id) and newborn.objects[id]["destroyed"],"structural tombstone survives death")
	check(newborn.events["vehicles"]["vehicle:004"]["destroyed"],"vehicle tombstone survives")
	check(newborn.events["objectives"]==JSON.parse_string(JSON.stringify(objective_record)),"objective pins/renown/progress retained")
	check(newborn.events["lineage_archive"]["lives"].size()==1,"one archived record on reload")
	check(newborn.player.get("alert",0)==0 and newborn.player.get("response_wave",0)==0,"contact cleared")
	var fresh := GenomeState.from_record(newborn.player["genetics"]["genome"])
	check(fresh != null and fresh.total()==0 and fresh.ranks.is_empty(),"genuinely fresh neutral genome")
	check(newborn.player["evacuations"].size()>0 or remaining==0,"evacuations preserved")
	check(newborn.seed_value==demo.world.state.seed_value,"world seed retained")
	check(newborn.player["genetics"]["life_id"]==2,"distinct organism ID")
	# Existing pre-genetics saves retain automatic milestones and stats.
	var old = packed.instantiate(); root.add_child(old); old.set_physics_process(false)
	old.world.state.player={"hp":75,"evolutions":22,"max_hp":150,"biomass":81}
	old.world.restore_player()
	check(not old.genetics.enabled and old.upright_form and is_equal_approx(old.growth_scale,GrowthProgression.target_scale(22)),"legacy growth migration")
	check(old.hp==75 and old.max_hp==150 and old.biomass==81,"old stats retained")
	# Future genome/archive schema cannot overwrite a newer user's save.
	var future: Dictionary = newborn.document().duplicate(true)
	future["player"]["genetics"]["genome"]["version"]=999
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(future)); file.close()
	var unsupported := WorldState.new(); unsupported.path=path
	check(not unsupported.read_save() and not unsupported.writable and unsupported.recovery=="unsupported","future genome preserved")
	# Malformed known version restores the previous-good backup.
	future["player"]["genetics"]["genome"]["version"]=1
	future["player"]["genetics"]["genome"]["raw"]["bird"]=-4
	file=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(future)); file.close()
	var recovery := WorldState.new(); recovery.path=path
	check(recovery.read_save() and recovery.recovery=="backup","malformed genome uses backup")
	demo.queue_free(); old.queue_free(); await process_frame
	for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	if not failed: print("GENETICS LIVES TEST PASSED: mid-life/draft checkpoint, death idempotence, neutral next life, retained world/objectives/vehicle/evacuations/seed, legacy migration, future protection and backup")
	quit(1 if failed else 0)
