extends SceneTree
var failed := false
func check(ok: bool, reason: String) -> void:
	if not ok: failed=true; printerr("GENETICS GAMEPLAY TEST FAILED: "+reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	demo.world.state.path = "user://test-genetics-gameplay.json"
	var system: BeachGenetics = demo.genetics
	var recipes := {}
	for f in GeneRegistry.FORMS:
		system.fixture([f])
		check(system.morphology.visible and system.morphology.get_child_count()>0,"visible "+f)
		check(not demo.creature_rig["visual"].forms[0].visible,"legacy body hidden "+f)
		check(demo.growth_scale == 1.0 and not demo.upright_form,"identity does not force growth "+f)
		recipes[f] = system.morphology.recipe
		var builds := system.morphology.build_count
		for i in range(30): system.refresh(); system.advance(.016)
		check(system.morphology.build_count==builds,"no per-frame rebuild "+f)
		demo.beast.position=Vector3(0,0,17)
		demo.touch_vector=Vector2(1,0)
		var old: Vector3 = demo.beast.position
		demo._update_movement(.1)
		check(demo.beast.position.distance_to(old)>.1,"ground movement "+f)
		check(is_finite(demo.beast.position.x),"finite transform")
	check(recipes.size()==9,"nine distinct recipes")
	system.fixture(["reptile"])
	demo.hp=100.0; demo._take_damage(10)
	check(is_equal_approx(demo.hp,91.8),"osteoderm actual mitigation")
	system.fixture(["bird"])
	check(system.speed_multiplier(Vector3.ZERO)>1.0 and system.damage_multiplier()>1.0,"bird benefit and cost")
	system.fixture(["crab"])
	check(system.speed_multiplier(Vector3.ZERO)<1.0 and system.damage_multiplier()<1.0,"crab shell tradeoff")
	system.fixture(["biomass","worm"])
	check(system.genome.legal(GeneRegistry.seed_key("ape")),"matrix support effect")
	system.fixture(["ape"])
	check(demo._bite_reach()>demo.BITE_RANGE and system.cone()<demo.BITE_CONE_DOT,"ape working reach/cone")
	system.fixture(["worm"])
	check(system.sprint_cost(Vector3(0,0,18))<system.sprint_cost(Vector3(0,0,-500)),"worm coastal terrain stamina")
	system.fixture(["spider"])
	var prey := Node3D.new(); demo.add_child(prey); prey.position=demo.beast.position+Vector3(0,0,5)
	demo.civilians.append({"node":prey})
	system.update_sensor()
	check(is_instance_valid(system.marked_target) and system.sensor.visible,"spider actual prey sensor")
	demo.civilians.pop_back(); prey.queue_free()
	system.fixture(["snake"])
	demo._spawn_response_enemy(Vector3(0,0,-10),"soldier")
	var index: int = demo.officers.size()-1
	demo._damage_response(index,1.0)
	var health: float = demo.officers[index]["health"]
	system.advance(1.0)
	check(demo.officers[index]["health"]<health,"venom damages living responder")
	system.fixture(["mole"])
	demo._prepare_authored(0)
	var hits: float = demo.buildings[0]["hits"]
	system.breach(0)
	check(demo.buildings[0]["hits"]<hits,"surface breach actual structure damage")
	var next: float = demo.buildings[0]["hits"]
	system.breach(0)
	check(demo.buildings[0]["hits"]==next,"breach cooldown")
	for pair in [["reptile","bird"],["ape","crab"],["worm","mole"]]:
		system.fixture(pair,3)
		check(system.genome.identity()["kind"]=="hybrid","functional hybrid "+str(pair))
		check(AnatomyResolver.resolve(system.genome.ranks)["families"].size()==2,"dual sockets")
		demo.shedding.begin_shed(demo.beast_visual)
		check(is_instance_valid(demo.shedding.current_shell),"hybrid shed snapshot")
		demo.shedding.abort_shed()
	# Real paid choice and pause/reveal transaction.
	system.fixture([])
	demo.biomass=200
	demo._start_evolution(); demo._finish_evolution()
	check(paused and demo.choice_open and system.genome.draft.size()==3,"three legal paused cards")
	var offers := system.genome.draft.duplicate()
	demo._choose_mutation("unsupported_flight")
	check(demo.choice_open and demo.evolutions==0,"unsupported choice rejected")
	demo._choose_mutation(offers[0])
	var count := system.genome.transactions.size()
	demo._choose_mutation(offers[0])
	check(system.genome.transactions.size()==count and demo.reveal_active and paused,"one selection and paused reveal")
	for i in range(7): demo.shedding.accelerate_reveal()
	await process_frame
	await process_frame
	check(not paused and not demo.reveal_active,"reveal resumes")
	# Mutation alone cannot escalate response; explicit chosen growth only.
	demo.alert=0; demo.heat_cooldown=0; demo.response_clock=0
	system.fixture(["bird"],5)
	for i in range(20): demo._update_police(1.0)
	check(demo.defcon==5,"no mutation-triggered SWAT")
	for level in range(1,121): demo._apply_growth_milestone(level)
	check(demo.growth_scale==1.0 and not demo.upright_form,"E120 optional growth")
	check(system.genome.select_gene("physical_growth","growth"),"growth offered")
	system.refresh()
	check(is_equal_approx(demo.growth_scale,float(BodyDimensionsPolicy.measure("reptile",1)["scale_metric"])),"chosen physical scale metric")
	root.size=Vector2i(540,960)
	system.hud.refresh()
	system.hud.open()
	check(paused and system.hud.entries.item_count==500,"searchable 500 source index")
	system.hud.search.text="Hollow Bone"
	system.hud.populate()
	check(system.hud.entries.item_count==1,"catalogue search")
	system.hud.close()
	if not failed: print("GENETICS GAMEPLAY TEST PASSED: nine live effects/recipes, movement, three hybrids, shed, legal cards, pause/reveal, growth, sensor, status, DEFCON, source index")
	demo.queue_free(); await process_frame
	for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test-genetics-gameplay.json"+suffix))
	quit(1 if failed else 0)
