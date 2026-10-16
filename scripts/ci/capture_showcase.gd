extends SceneTree
## Scripted desktop showcase, not a natural progression or phone playtest.
var demo: Node3D
var frame := 0

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	root.size = Vector2i(540,960)
	demo.beast.position = Vector3(0,0,8)
	demo.follow_camera.position = demo.beast.position+demo._camera_offset()
	process_frame.connect(tick)

func tick() -> void:
	frame += 1
	if frame == 91:
		demo.touch_vector = Vector2.ZERO
		demo.biomass = 1000
		demo._start_evolution()
	if frame == 151:
		demo._finish_evolution()
	if frame == 181:
		demo._choose_mutation("armour")
	if frame == 271:
		demo.beast.position = Vector3(0,0,8)
		for id in ["armour","speed","stamina","jaw","strength","health","regen"]:
			for i in range(3):demo._apply_mutation_visual(id)
		demo._apply_growth_milestone(22)
		demo.evolutions = 22
		demo.follow_camera.position = demo.beast.position+demo._camera_offset()
	if frame < 91 or frame > 271:
		demo.touch_vector = Vector2(.6 if frame%90<45 else -.6,-.7)
	demo._physics_process(1.0/30.0)
	if frame >= 390:
		quit()
