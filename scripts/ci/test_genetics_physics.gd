extends SceneTree
var failed := false
func check(ok: bool, reason: String) -> void:
	if not ok: failed=true; printerr("GENETICS PHYSICS TEST FAILED: "+reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var demo=load("res://scenes/BeachDemo.tscn").instantiate(); root.add_child(demo); demo.set_physics_process(false)
	await physics_frame
	demo.world.state.path="user://genetics-physics-test.json"
	demo._prepare_authored(102)
	var building: Dictionary=demo.buildings[102]
	var center: Vector3=building["position"]
	var half: Vector2=building["half"]
	var recipes: Array=[]
	for f in GeneRegistry.FORMS: recipes.append([f])
	recipes.append_array([["reptile","bird"],["ape","crab"],["worm","mole"]])
	for families in recipes:
		for growth in [0,6]:
			demo.beast.position=Vector3(0,0,18)
			demo.genetics.fixture(families,3 if families.size()==2 else 1)
			for n in range(growth): demo.genetics.genome.select_gene("physical_growth","g_%d" % n)
			demo.genetics.refresh()
			demo.beast.position=center+Vector3(half.x+demo.growth_scale*4+5,0,0)
			demo._update_creature_animation(0,false)
			demo._resolve_growth_clearance()
			demo._update_camera(1)
			await physics_frame
			var right: Vector3=demo.follow_camera.basis.x; right.y=0; right=right.normalized()
			var forward: Vector3=-demo.follow_camera.basis.z; forward.y=0; forward=forward.normalized()
			demo.touch_vector=Vector2(Vector3.LEFT.dot(right),-Vector3.LEFT.dot(forward))
			for n in range(8): demo._update_movement(.2)
			# Godot's contact solver permits millimetre-scale floating-point overlap;
			# assert the complete body stays outside the known wall within 1cm/scale.
			var gap: float=demo.beast.position.x-center.x-half.x
			check(gap>=demo.beast_collision_shape.radius-.01*demo.growth_scale,"swept structure clearance "+str(families)+" scale "+str(growth))
			check(not demo.upright_form,"genetics body never forced upright")
	# Radical crossover requires and visibly carries the support matrix.
	demo.genetics.fixture(["worm"],3)
	check(not demo.genetics.genome.select_gene("gene_044","unsupported"),"heavy arms require bridge")
	check(demo.genetics.genome.select_gene("gene_100","support"),"bridge selected")
	for n in range(3): check(demo.genetics.genome.select_gene("gene_044","arms_%d" % n),"supported heavy arms")
	demo.genetics.refresh()
	check(demo.genetics.genome.identity()["kind"]=="hybrid" and demo.genetics.genome.identity()["anatomy"]["bridge"],"supported worm/ape hybrid")
	# Large chosen growth must resolve overlap without demolishing the obstacle.
	demo.genetics.fixture(["worm","mole"],3)
	for n in range(18): demo.genetics.genome.select_gene("physical_growth","large_%d" % n)
	demo.genetics.refresh(); demo.beast.position=center; demo._update_creature_animation(0,false)
	demo._resolve_growth_clearance()
	check(demo._growth_position_clear(demo.beast.position),"maximum chosen growth overlap resolution")
	check(not demo.buildings[102]["destroyed"],"clearance never demolishes a warehouse")
	check(not demo.genetics.genome.legal("physical_growth"),"growth cap")
	# Debug batches use legal genetics, retain E120 cap and never force growth.
	demo.genetics.fixture([]); demo.evolutions=0; demo.evolution_history.clear(); demo.beast.position=Vector3(0,0,18)
	demo._debug_evolve_batch(60); demo._debug_evolve_batch(60)
	check(demo.evolutions==120 and demo.evolution_history.size()==120,"genetic E120 debug semantics")
	check(GenomeState.from_record(demo.genetics.genome.record())!=null,"E120 genome reload")
	check(demo.genetics.morphology.get_child_count()<20 and demo.genetics.effects.trail.size()==6,"bounded anatomy and effects")
	demo.queue_free(); await process_frame
	if not failed: print("GENETICS PHYSICS TEST PASSED: nine forms/three hybrids swept at two sizes, explicit support crossover, maximum growth clearance, bounded E120 debug/reload")
	quit(1 if failed else 0)
