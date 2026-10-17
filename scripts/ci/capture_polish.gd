extends SceneTree
## Real engine captures. Run without --headless; -- baseline selects old recipe evidence.
var demo: Node3D
var out := "res://build/polish-captures"
func _initialize() -> void: call_deferred("run")
func snap(stem: String) -> void:
	for i in range(3): await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+stem+".png")
	print("CAPTURE ",stem)
func run() -> void:
	if "baseline" in OS.get_cmdline_user_args(): out="res://build/polish-baseline"
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(540,960)
	demo=load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	demo.world.state.path=out+"/capture-save.json"
	await physics_frame
	for f in GeneRegistry.FORMS:
		for growth in [0,6,12,18]:
			demo.genetics.fixture([f],3)
			for i in range(growth): demo.genetics.genome.select_gene("physical_growth","capture_growth_%d"%i)
			demo.genetics.refresh()
			demo.beast.position=Vector3(0,0,18)
			if demo.genetics.trail.live:
				demo.genetics.trail.reset(demo.beast.position,Vector3.BACK)
				demo.genetics.trail.update_pose()
			for angle in range(3):
				demo.beast.rotation.y=[-.5,1.2,2.6][angle]
				demo._update_creature_animation(0,false)
				demo._update_camera(1)
				await snap("%s_e%02d_a%d"%[f,growth,angle])
				# Inspection is the same live gameplay mesh, without the HUD.
				demo.ui_layer.hide()
				var d: Dictionary=demo.genetics.dimensions
				var focus: Vector3=demo.beast.position+Vector3(0,float(d["height"])*.4,0)
				var distance := maxf(float(d["width"])*1.5,float(d["height"])*1.4)
				if d["axial"]:
					focus=demo.genetics.trail.point_at(float(d["length"])*.45)
					distance=maxf(8,float(d["length"])*1.4)
				demo.follow_camera.position=focus+Vector3(.6,.85,1.0)*maxf(5,distance)
				demo.follow_camera.look_at(focus)
				await snap("inspect_%s_e%02d_a%d"%[f,growth,angle])
				demo.ui_layer.show()
	quit()
