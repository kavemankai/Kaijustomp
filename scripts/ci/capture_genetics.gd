extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/genetics-captures")
	root.size = Vector2i(540,960)
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.world.state.path="res://build/genetics-captures/capture-save.json"
	demo.set_physics_process(false)
	var label := Label.new()
	label.position=Vector2(18,375)
	label.add_theme_font_size_override("font_size",22)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",2)
	demo.ui_layer.add_child(label)
	var recipes: Array = []
	for f in GeneRegistry.FORMS: recipes.append([f])
	recipes.append_array([["reptile","bird"],["ape","crab"],["worm","mole"]])
	for families in recipes:
		demo.genetics.fixture(families,3 if families.size()==2 else 1)
		demo.beast.position=Vector3(0,0,17)
		demo.beast.rotation=Vector3(0,-.35,0)
		demo._update_creature_animation(1.0,false)
		demo._update_camera(1.0)
		demo._update_hud()
		label.text = "+".join(families).to_upper()
		demo.genetics.hud.summary.hide()
		for i in range(4): await process_frame; await RenderingServer.frame_post_draw
		var path := "res://build/genetics-captures/"+"_".join(families)+".png"
		root.get_texture().get_image().save_png(path)
		print("CAPTURE ",path," calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," memory_mib=",OS.get_static_memory_usage()/1048576.0)
	# Actual portrait draft and index layouts, with the live HUD in place.
	for id in GeneRegistry.CURATED+[11,62,44,84,15]:
		demo.genetics.fixture([])
		demo.genetics.genome.select_gene("gene_%03d" % id,"capture")
		demo.genetics.refresh()
		demo.beast.position=Vector3(0,0,17)
		demo._update_creature_animation(0,false); demo._update_camera(1)
		label.text="SOURCE %03d" % id
		demo.genetics.hud.summary.hide()
		for i in range(2): await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/genetics-captures/source_%03d.png" % id)
	label.hide()
	demo.genetics.fixture([])
	demo.biomass=100
	demo._start_evolution(); demo._finish_evolution()
	for i in range(4): await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/genetics-captures/draft.png")
	paused=false; demo.choice_open=false; demo.modal.hide(); demo.modal_shade.hide(); demo.shedding.abort_shed()
	demo.genetics.hud.refresh(); demo.genetics.hud.open()
	for i in range(4): await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/genetics-captures/lineage.png")
	quit()
