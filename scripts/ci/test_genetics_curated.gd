extends SceneTree
var failed := false
var demo: Node3D
func check(ok: bool, reason: String) -> void:
	if not ok: failed=true; printerr("CURATED GENES TEST FAILED: "+reason)
func _initialize() -> void: call_deferred("run")
func equip(id: int) -> GeneEffects:
	demo.genetics.fixture([])
	var key := "gene_%03d" % id
	check(demo.genetics.genome.select_gene(key,"source_%d" % id),"equip %d" % id)
	demo.genetics.refresh()
	return demo.genetics.effects
func run() -> void:
	demo=load("res://scenes/BeachDemo.tscn").instantiate(); root.add_child(demo); demo.set_physics_process(false)
	await physics_frame
	demo.world.state.path="user://curated-gene-tests.json"
	var sources := {}
	for gene in GeneRegistry.definitions().values():
		if gene["source_id"]>0: sources[gene["source_id"]]=true
	check(sources.size()==35,"exact curated 30 + five seeds")
	for id in GeneRegistry.CURATED: check(sources.has(id),"curated source preserved")
	for id in sources:
		equip(id)
		check(GenomeState.from_record(demo.genetics.genome.record())!=null,"source save roundtrip %d" % id)
		check(demo.genetics.morphology.visible and demo.genetics.morphology.get_child_count()>0,"source visual %d" % id)
		check(not demo.genetics.genome.legal("gene_%03d" % id) or id in GeneRegistry.SEEDS,"rank cap")
	check(equip(1).sensor_range()==28,"chemical tracking")
	var e:=equip(2); e.clock=1; check(e.incoming(10)<1,"shedding window"); e.clock=5; check(e.incoming(10)==1,"shedding expiry")
	e=equip(7); demo._prepare_authored(0); var h: float=demo.buildings[0]["hits"]
	e.corrode("building",demo.buildings[0]["id"]); e.advance(1); check(demo.buildings[0]["hits"]<h,"live corrosion")
	demo._spawn_response_enemy(Vector3(0,0,-20),"soldier")
	var i: int=demo.officers.size()-1
	check(equip(9).contact_bonus(i)==6,"ridge impact")
	e=equip(12); var food: int=demo.biomass; demo._feed(12); check(demo.biomass-food==15,"scavenger food")
	check(equip(14).sensor_range()==40,"thermal sensor")
	e=equip(19); demo.officers[i]["node"].position=demo.beast.position+demo.beast.basis.z*2
	h=demo.officers[i]["health"]; e.advance(.1); check(demo.officers[i]["health"]<h and demo.officers[i]["gene_slow"]>0,"tail strike and slow")
	e=equip(20); e.still=2; check(e.concealed(),"camouflage"); e.still=0; check(not e.concealed(),"movement breaks camouflage")
	check(equip(30).sensor_range()==52 and demo.genetics.cone()<demo.BITE_CONE_DOT,"raptor acquisition")
	e=equip(36); demo.sprint_active=true; check(e.contact_bonus(i)==14,"dash spurs"); demo.sprint_active=false; check(e.contact_bonus(i)==0,"spurs conditional")
	equip(39); check(demo.genetics.sprint_cost(Vector3.ZERO)==.8,"pneumatic endurance")
	e=equip(42); check(e.incoming(10)==.88 and e.incoming(20)==1,"guard hair damage category")
	check(equip(43).contact_bonus(i)==8,"tusk penetration")
	e=equip(47); demo.hp=20; check(e.movement()==1.25,"low-health adrenaline"); demo.hp=100; check(e.movement()==1,"adrenaline expiry")
	e=equip(49); check(e.incoming(20)==.8 and e.movement()==.92,"fat armour/cost")
	check(equip(57).sensor_range()==34,"eyes shine perception")
	e=equip(58); demo.hp=50; demo.beast.velocity=Vector3.ZERO; e.stance=true; e.advance(1); check(demo.hp==52 and e.incoming(10)>1,"torpor heal and vulnerability")
	e=equip(72); e.hit_count=0; for n in range(3): check(e.incoming(10)==1,"shell deflection charge")
	check(e.incoming(10)==0 and e.incoming(20)==1,"fourth small hit deflects, heavy doesn't")
	e=equip(73); demo.sprint_active=true; e.sprint_time=0; check(e.movement()==1.2,"hydraulic burst"); e.sprint_time=3; check(e.movement()==1,"burst expiry"); demo.sprint_active=false
	check(equip(81).feeding_slowdown()==.75,"mucus slowdown resistance")
	e=equip(85); e.stance=true; check(e.movement()==.5 and e.incoming(10)==.6,"mantle guard and cost")
	e=equip(88); e.still=2; demo.alert=0; check(e.lure_direction(demo.beast.position+Vector3(5,0,0),Vector3.ZERO).x<0,"lure actual movement vector")
	e=equip(90); demo.officers[i]["node"].position=demo.beast.position+Vector3(2,0,0); h=demo.officers[i]["health"]; e.toxin_cooldown=0; e.retaliate(); check(demo.officers[i]["health"]<h,"contact toxin")
	check(equip(95).sensor_range()==32,"electroreception")
	e=equip(99); demo._prepare_authored(0); demo.beast.position=demo.buildings[0]["position"]+Vector3(demo.buildings[0]["half"].x+2,0,0); h=demo.buildings[0]["hits"]; e.advance(1); check(demo.buildings[0]["hits"]<h and e.trail.size()==6,"bounded acid trail")
	e=equip(441); e.ambush_ready=true; check(e.contact_bonus(i)==20 and e.contact_bonus(i)==0,"one ambush strike")
	if not failed: print("CURATED GENES TEST PASSED: all 35 source IDs equip, save and visualize; 26 additive effects, conditions, cooldowns, tradeoffs and caps verified")
	demo.queue_free(); await process_frame
	for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path("user://curated-gene-tests.json"+suffix))
	quit(1 if failed else 0)
