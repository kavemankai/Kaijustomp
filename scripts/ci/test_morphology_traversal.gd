extends SceneTree
## Actual scene + physics probes for morphology, axial body and mode transitions.
var failed := false
func check(ok: bool, reason: String) -> void:
	if not ok:
		failed=true
		printerr("MORPHOLOGY TRAVERSAL TEST FAILED: "+reason)
func _initialize() -> void: call_deferred("run")
func open_ground(demo: Node3D) -> Vector3:
	for x in [520.0,750.0,1100.0,-650.0,-1200.0]:
		for z in [-170.0,-300.0,-480.0]:
			var point := Vector3(x,0,z)
			if demo.genetics.traversal._safe_surface(point): return point
	return Vector3(0,0,18)
func run() -> void:
	var demo=load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	demo.world.state.path="user://morphology-traversal-ci.json"
	for family in GeneRegistry.FORMS:
		demo.genetics.fixture([family])
		var profile=demo.genetics.dimensions
		check(demo.genetics.morphology.primary==family,"recognisable primary "+family)
		check(String(profile["family"])==family,"per-host dimensions "+family)
		check(demo.genetics.morphology.get_child_count()>0,"rendered "+family)
		if family in ["snake","worm"]:
			check(profile["axial"] and demo.genetics.trail.live,"axial body "+family)
			var first: float=profile["length"]
			for i in range(6): demo.genetics.genome.select_gene("physical_growth","growth_%s_%d" % [family,i])
			demo.genetics.refresh()
			check(float(demo.genetics.dimensions["length"])>first*2.5,"length-dominant growth "+family)
			check(not demo.upright_form,"axial never upright "+family)
			check(demo.genetics.trail.rendered.size()>=8,"actual path-following segments "+family)
			demo.beast.global_position=Vector3(0,0,18)
			demo.genetics.trail.reset(demo.beast.position,Vector3.BACK)
			for i in range(35):
				demo.beast.global_position.x=float(i+1)*.45
				demo.genetics.trail.advance(demo.beast.global_position)
			var tail: Vector3=demo.genetics.trail.point_at(float(demo.genetics.dimensions["length"])*.82)
			check(tail.distance_to(demo.beast.position)>5.0,"world-spanning trailing tail "+family)
	# A universal generic stat must affect the ACTUAL host mesh.
	for family in GeneRegistry.FORMS:
		demo.genetics.fixture([family])
		var before: String=demo.genetics.morphology.recipe
		for tier in range(3):
			check(demo.genetics.genome.select_gene("strength","fit_%s_%d" % [family,tier]),"select body strength "+family)
			demo.genetics.refresh()
			check(demo.genetics.morphology.recipe!=before,"strength changes visual recipe "+family+" tier "+str(tier))
			before=demo.genetics.morphology.recipe
	# Unlocked traversal must be controlled by actual organ prerequisites.
	demo.genetics.fixture(["bird"])
	var g: GenomeState=demo.genetics.genome
	check(not g.legal("gene_121"),"powered wings require proto wing")
	check(g.select_gene("gene_029","glide"),"glide gene")
	check(g.select_gene("gene_121","flight"),"powered wing gene")
	demo.genetics.refresh()
	check(demo.genetics.traversal.can_use("flight"),"flight motor unlocked")
	var safe: Vector3=open_ground(demo)
	check(demo.genetics.traversal._safe_surface(safe),"open test ground located")
	demo.beast.global_position=safe
	check(demo.genetics.traversal.activate("flight"),"takeoff from clear terrain")
	for i in range(22):
		demo.genetics.traversal.direction_input(Vector3(0,0,-1),1,8.0,.10)
	check(demo.beast.global_position.y>3.0,"actual powered altitude gain")
	check(demo.genetics.traversal.mode=="flight","flight remains active in air")
	demo.genetics.traversal.activate("ground")
	for i in range(75):
		demo.genetics.traversal.direction_input(Vector3.ZERO,-1,0,.1)
	check(demo.genetics.traversal.mode=="ground","actual gradual landing")
	# Burrowing physically changes position while checking building footprints.
	demo.genetics.fixture(["mole"])
	g=demo.genetics.genome
	check(g.select_gene("gene_052","dig"),"dig adaptation gene")
	demo.genetics.refresh()
	demo.beast.global_position=safe
	check(demo.genetics.traversal.activate("burrow"),"underground entry")
	check(demo.beast.global_position.y<0 and demo.beast.collision_mask==0,"real buried position")
	var start: Vector3=demo.beast.global_position
	demo.genetics.traversal.direction_input(Vector3(0,0,-1),0,8.0,.5)
	check(demo.beast.global_position.z<start.z,"underground contiguous movement")
	check(demo.genetics.traversal.activate("ground"),"safe controlled emergence")
	check(demo.beast.global_position.y==0 and demo.beast.collision_mask==1,"surface collision restored")
	# Spider adhesion probes a physical wall; horizontal movement is not flight.
	demo.genetics.fixture(["spider"])
	g=demo.genetics.genome
	check(g.select_gene("gene_180","hooks"),"wall hooks equip")
	demo.genetics.refresh()
	var wall:=StaticBody3D.new()
	wall.collision_layer=1
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new(); box.size=Vector3(2,22,14)
	shape.shape=box
	wall.add_child(shape)
	demo.add_child(wall)
	wall.global_position=Vector3(310,10,-180)
	demo.beast.global_position=Vector3(306,0,-180)
	demo.beast.rotation.y=-PI*.5
	await physics_frame
	check(demo.genetics.traversal.activate("climb"),"wall attachment requires genuine collider")
	var old_y: float=demo.beast.position.y
	for i in range(10): demo.genetics.traversal.direction_input(Vector3.ZERO,1,7.0,.10)
	check(demo.beast.position.y>old_y+1,"climbs a physical vertical facade")
	for i in range(80): demo.genetics.traversal.direction_input(Vector3.ZERO,1,7.0,.10)
	check(demo.genetics.traversal.mode=="roof","real wall-to-roof transition")
	demo.genetics.traversal.activate("ground")
	demo.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://morphology-traversal-ci.json"+suffix))
	if not failed: print("MORPHOLOGY TRAVERSAL TEST PASSED: 9 hosts, evolving anatomy, axial world trail, powered flight/landing, underground travel, wall adhesion")
	quit(1 if failed else 0)
