extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,why: String) -> void:
    if not ok:
        failed=true
        printerr("WORLD TRACKING TEST FAILED: "+why)
func run() -> void:
    var demo=load("res://scenes/BeachDemo.tscn").instantiate()
    root.add_child(demo)
    demo.set_physics_process(false)
    await physics_frame
    var model: WorldObjectives=demo.objectives
    var goals := model.tracked_goals(demo.beast.position)
    check(goals.size()==3,"Not three suggestions at launch")
    check(goals[0]["id"]=="banksia","Nearest starting mission not prioritised")
    model.track("port"); model.track("grid"); model.track("titan")
    check(model.record["pins"].size()==3,"Cannot pin three goals")
    model.track("command")
    check(model.record["pins"].size()==3 and "command" not in model.record["pins"],"Fourth pin exceeded cap")
    goals=model.tracked_goals(demo.beast.position)
    check(goals.size()==3 and goals[0]["id"]=="port" and goals[2]["id"]=="titan","Manual pins not retained in order")
    model.track("grid")
    goals=model.tracked_goals(demo.beast.position)
    check(model.record["pins"].size()==2 and goals.size()==3,"Unpin did not auto-fill slot")
    model.record["completed"]["port"]=true
    model.evaluate()
    check("port" not in model.record["pins"],"Completed goal kept a pin slot")
    model.track("titan") # Return to automatic suggestions.
    for site in model.sites:
        if site["id"]=="command": demo.beast.position=site["at"]+Vector3(0,0,80)
    demo.evolutions=34
    model.observe(demo,1)
    goals=model.tracked_goals(demo.beast.position)
    check(goals.size()==3 and goals[0]["id"]=="command","Sector landmark not prioritised inland")
    demo.defcon=2
    model.observe(demo,1)
    goals=model.tracked_goals(demo.beast.position)
    var ids: Array=[]
    for goal in goals:
        check(not model.complete(goal["id"]),"Completed goal auto-tracked")
        check(goal["id"] not in ids,"Duplicate tracked goal")
        ids.append(goal["id"])
    check("escape" in ids and "response" in ids,"Active threat not reflected in suggestions")
    demo._update_hud()
    check(demo.objective_hud.tracker_titles.size()==3,"HUD lacks three tracker rows")
    for label in demo.objective_hud.tracker_titles: check(label.visible and not label.text.is_empty(),"Empty tracker row")
    var saved: Dictionary=model.record.duplicate(true)
    model.track("grid"); model.track("titan"); model.track("command")
    demo.world.state.path="user://three-tracking-%d.json" % Time.get_ticks_usec()
    var path: String=demo.world.state.path
    check(demo.world.save_now(),"Three-pin checkpoint failed")
    var loaded := WorldState.new()
    loaded.path=path
    check(loaded.read_save(),"Three-pin save rejected")
    var resumed := WorldObjectives.new()
    resumed.setup(loaded,demo.world.layout)
    check(resumed.record["pins"]==model.record["pins"] and resumed.tracked_goals(demo.beast.position).size()==3,"Pin order lost on disk restart")
    var legacy := WorldState.new()
    saved.erase("pins"); saved["tracked"]="titan"
    legacy.events["objectives"]=saved
    check(WorldObjectives.valid(saved),"Legacy single-selection record rejected")
    var migrated := WorldObjectives.new()
    migrated.setup(legacy,demo.world.layout)
    check(migrated.record["pins"]==["titan"],"Old selection not migrated to pin")
    var invalid: Dictionary=model.record.duplicate(true)
    invalid["pins"]=["grid","grid"]
    check(not WorldObjectives.valid(invalid),"Duplicate saved pins accepted")
    invalid["pins"]=["grid","titan","command","response"]
    check(not WorldObjectives.valid(invalid),"Four saved pins accepted")
    invalid["pins"]=["unknown"]
    check(not WorldObjectives.valid(invalid),"Unknown saved pin accepted")
    for goal in WorldObjectives.GOALS: model.record["completed"][goal["id"]]=true
    model.evaluate()
    demo._update_hud()
    check(model.tracked_goals(demo.beast.position).is_empty(),"Finished game suggested completed goals")
    check(demo.objective_hud.tracker_titles[0].text=="ALL OBJECTIVES COMPLETE","Missing empty-state display")
    for suffix in ["",".bak",".tmp"]:
        if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    if not failed: print("WORLD TRACKING TEST PASSED: three relevant suggestions, pin cap/order, sector/threat changes, completed cleanup, disk migration and HUD")
    quit(1 if failed else 0)
