extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,why: String) -> void:
    if not ok:
        failed=true
        printerr("WORLD OBJECTIVES TEST FAILED: "+why)
func run() -> void:
    var demo=load("res://scenes/BeachDemo.tscn").instantiate()
    root.add_child(demo)
    demo.set_physics_process(false)
    await physics_frame
    var model: WorldObjectives=demo.objectives
    check(model.sites.size()==6,"Missing landmark parcel")
    check(model.renown()==0,"Goals completed at launch")
    var original_food: int=demo.biomass
    demo.beast.position=Vector3(0,0,-150)
    model.observe(demo,1)
    check(model.complete("banksia"),"Banksia discovery not recorded")
    check(demo.biomass==original_food,"Discovery inflated biomass")
    var renown := model.renown()
    model.observe(demo,1)
    check(model.renown()==renown,"Repeated discovery duplicated reward")
    demo.beast.position=Vector3(2600,0,-2300)
    model.observe(demo,1)
    check(model.complete("coast") and model.complete("inland"),"Travel objectives failed")
    # Landmarks add identity without moving/replacing baseline generator parcels.
    for site in model.sites:
        if site["object"].is_empty(): continue
        var at: Vector3=site["at"]
        demo.beast.position=at+Vector3(0,0,80)
        demo.world.ensure_region(at,150)
        model.observe(demo,1)
        var index: int=demo._index_for_world_id(site["object"])
        check(index>=114,"Landmark overwrote authored region or missing")
        if index<0: continue
        demo._activate_building(index,true)
        check(demo.buildings[index]["landmark"]==site["id"],"Metadata lost in registration")
        check(demo.buildings[index]["node"].has_node("LandmarkIdentity"),"No distinctive landmark geometry")
        if site["id"] in ["harbour","power","command"]:
            demo._damage_building(index,100000)
            var earned := model.renown()
            var count: int=model.record["counters"]["demolished"]
            demo._damage_building(index,100000)
            check(model.record["counters"]["demolished"]==count and model.renown()==earned,"Destroyed landmark double counted")
            var chunk := WorldLayout.coord(at)
            demo.world._unload(chunk)
            demo.world.ensure_region(at,150)
            check(demo.buildings[demo._index_for_world_id(site["object"])]["destroyed"],"Landmark respawned after unloading")
    check(model.complete("sites") and model.complete("port") and model.complete("grid") and model.complete("command"),"Landmark objectives incomplete")
    # Retiring/unloading enemies is distinct from combat victories.
    var before: int=model.record["counters"].get("responders",0)
    demo._spawn_response_enemy(demo.beast.position+Vector3(70,0,0),"police")
    demo._damage_response(demo.officers.size()-1,10000)
    check(model.record["counters"]["responders"]==before+1,"Combat victory not counted")
    for i in range(4):
        demo._spawn_response_enemy(demo.beast.position+Vector3(80+i*3,0,0),"soldier")
        demo._damage_response(demo.officers.size()-1,10000)
    check(model.complete("response"),"Response objective failed")
    demo.defcon=2; model.observe(demo,1)
    demo.hp=0; demo.defcon=5; model.observe(demo,1)
    check(not model.complete("escape"),"Death counted as escaping")
    demo.hp=100; model.observe(demo,1)
    check(model.complete("escape"),"Alive de-escalation failed")
    demo._debug_evolve_batch(34)
    model.observe(demo,1)
    check(model.complete("upright") and model.complete("giant") and not model.complete("titan"),"Existing evolution milestones not observed")
    # Objective view pauses actors/projectiles without replacing existing controls.
    demo.objective_hud.button.pressed.emit()
    var position_before: Vector3=demo.beast.position
    demo.touch_vector=Vector2(1,0)
    demo._physics_process(.1)
    check(demo.beast.position==position_before,"Objective panel allowed player movement")
    check(demo.objective_hud.panel.visible and demo.objective_hud.rows.get_child_count()==WorldObjectives.GOALS.size(),"Objective list missing rows")
    check(not demo.sprint_button.visible and not demo.debug_evolve_button.visible,"Gameplay controls overlap objective panel")
    demo.objective_hud.rows.get_child(6).pressed.emit()
    check(model.record["tracked"]=="titan","Objective selection button captured wrong goal")
    demo.objective_hud.set_open(false)
    check(demo.touch_vector==Vector2.ZERO,"Panel close retained held movement")
    model.track("titan")
    demo.world.state.path="user://objectives-%d.json" % Time.get_ticks_usec()
    var path: String=demo.world.state.path
    check(demo.world.save_now(),"Objective checkpoint failed")
    var loaded := WorldState.new()
    loaded.path=path
    check(loaded.read_save(),"Objective save failed validation")
    var resumed := WorldObjectives.new()
    resumed.setup(loaded,demo.world.layout)
    check(resumed.renown()==model.renown() and resumed.record["tracked"]=="titan","Reward/track state lost on disk restart")
    resumed.evaluate()
    check(resumed.renown()==model.renown(),"Reload reissued objective rewards")
    var bad: Dictionary=model.record.duplicate(true)
    bad["counters"]["responders"]="broken"
    check(not WorldObjectives.valid(bad),"Malformed objective counter accepted")
    bad=model.record.duplicate(true); bad["completed"]["fake"]=true
    check(not WorldObjectives.valid(bad),"Unknown reward injected")
    var future: Dictionary=loaded.document().duplicate(true)
    future["events"]["objectives"]["version"]=2
    var future_file := FileAccess.open(path,FileAccess.WRITE)
    future_file.store_string(JSON.stringify(future)); future_file.close()
    var protected := WorldState.new()
    protected.path=path
    check(not protected.read_save() and not protected.writable and protected.recovery=="unsupported","Future objective format overwritten or fell back to backup")
    var legacy := WorldState.new()
    legacy.objects["authored:000"]={"destroyed":true}
    var migrated := WorldObjectives.new()
    migrated.setup(legacy,demo.world.layout)
    check(migrated.record["counters"]["demolished"]==1,"Legacy world lost demolition credit")
    for suffix in ["",".bak",".tmp"]:
        if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    if not failed: print("WORLD OBJECTIVES TEST PASSED: landmarks, exploration, combat, one-time awards, pause UI, save/reload, legacy credit and validation")
    quit(1 if failed else 0)
