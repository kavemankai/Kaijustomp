extends SceneTree
## Reproducible actual-engine captures. Gameplay views retain the approved camera.
## Turntables intentionally use a separate inspection camera; never shipped gameplay.
var output: String
var demo: Node3D

func _initialize() -> void:
	call_deferred("run")

func save_frame(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(filename + ".png"))

func fresh() -> void:
	if is_instance_valid(demo):
		demo.free()
	demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	seed(713)

func studio() -> void:
	demo.ui_layer.hide()
	for child in demo.get_children():
		if child is Node3D and child != demo.beast and child != demo.follow_camera and not child is Light3D and not child is WorldEnvironment:
			child.hide()
	demo.beast.position = Vector3.ZERO
	var ground := Node3D.new()
	demo.add_child(ground)
	CoastalArt.box(ground,Vector3(0,-.10,0),Vector3(80,.12,80),Color("c9d0bd"))
	CoastalArt.merge(ground)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	output = args[0] if not args.is_empty() else "user://art-captures"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(540,960)
	fresh()
	for level in [0,6,16,22,46]:
		while demo.evolutions < level:
			demo.biomass = demo._cost()+10
			demo._start_evolution()
			demo._finish_evolution()
			demo._choose_mutation(["armour","speed","stamina","jaw","strength","health","regen"][demo.evolutions%7])
			demo.shedding.reveal_progress = 1.0
			demo.shedding._process(0.0)
			await process_frame
		demo._update_creature_animation(1.0,false)
		demo._update_camera(1.0)
		demo._update_hud()
		await save_frame("gameplay-%02d"%level)
	fresh()
	demo.evolutions = 3
	demo.biomass = 1000
	demo._start_evolution()
	demo._finish_evolution()
	await save_frame("evolution-cards")
	paused = false
	root.size = Vector2i(720,720)
	for form in [0,22]:
		fresh()
		studio()
		demo._apply_growth_milestone(form)
		# Present both meshes at one design scale for silhouette comparison.
		demo.beast_visual.scale = Vector3.ONE
		demo.ground_shadow.scale = Vector3.ONE
		demo._update_creature_animation(1,false)
		demo.ground_shadow.scale = Vector3.ONE
		for view in ["front","side","back","game"]:
			var offsets := {"front":Vector3(6,4,-10),"side":Vector3(11,3,0),"back":Vector3(6,5,10),"game":Vector3(7,12.5,11)}
			demo.follow_camera.position = offsets[view]
			demo.follow_camera.look_at(Vector3(0,1.0,0))
			await save_frame("form-%02d-%s"%[form,view])
	for id in ["armour","speed","stamina","jaw","strength","health","regen"]:
		fresh()
		studio()
		demo.follow_camera.position = Vector3(7,7,-9)
		demo.follow_camera.look_at(Vector3(0,1,0))
		for tier in range(1,4):
			demo._apply_mutation_visual(id)
			demo._update_creature_animation(0,false)
			await save_frame("mutation-%s-%d"%[id,tier])
	root.size = Vector2i(540,1200)
	fresh()
	demo._apply_growth_milestone(46)
	demo._update_camera(1)
	demo._update_hud()
	await save_frame("portrait-20-9")
	print("ART CAPTURES COMPLETE: ",output)
	quit()
