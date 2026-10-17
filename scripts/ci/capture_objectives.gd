extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(demo: Node,name: String) -> void:
    demo._update_camera(1)
    demo.world.refresh()
    for frame in range(300):
        demo.world.advance(.016)
        await process_frame
        if frame>45 and demo.world.queue.is_empty(): break
    demo.objectives.observe(demo,1)
    demo._update_hud()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/objective-captures/%s.png" % name)
func run() -> void:
    root.size=Vector2i(540,960)
    DirAccess.make_dir_recursive_absolute("res://build/objective-captures")
    var demo=load("res://scenes/BeachDemo.tscn").instantiate()
    root.add_child(demo)
    demo.set_physics_process(false)
    await capture(demo,"tracker")
    demo.objective_hud.set_open(true)
    await capture(demo,"missions")
    demo.objective_hud.set_open(false)
    demo._debug_evolve_batch(34)
    for site in demo.objectives.sites:
        if site["id"] not in ["harbour","command"]: continue
        demo.beast.position=site["at"]+Vector3(0,0,80)
        demo.world.ensure_region(demo.beast.position,230)
        var index: int=demo._index_for_world_id(site["object"])
        demo._activate_building(index,true)
        demo.objectives.track("port" if site["id"]=="harbour" else "command")
        await capture(demo,site["id"])
    print("OBJECTIVE CAPTURES COMPLETE: portrait tracker, selection and landmark identities")
    quit()
