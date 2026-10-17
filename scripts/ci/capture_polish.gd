extends SceneTree
## Real engine frames from the gameplay scene; no generated artwork.
var demo: Node3D
var out := "res://build/polish-captures"
var baseline := false
var captured: Array[String]=[]
var view_angle := 0.0
const HYBRIDS := [["reptile","bird"],["ape","crab"],["worm","mole"],["bird","spider"],["snake","biomass"],["ape","spider"],["reptile","crab"],["worm","biomass"]]
func _initialize() -> void: call_deferred("run")
func snap(stem: String) -> void:
	demo.genetics.hud.refresh()
	for i in range(3): await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+stem+".png")
	captured.append(stem)
	print("CAPTURE ",stem)
func finish() -> void:
	FileAccess.open(out+"/capture-index.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info()["string"],"source_sha":OS.get_environment("GITHUB_SHA"),"frames":captured},"\t"))
	quit()
func inspect(head_only: bool=false) -> void:
	demo.ui_layer.hide()
	var d: Dictionary=demo.genetics.dimensions
	var focus: Vector3=demo.beast.position+Vector3(0,float(d["height"])*.4,0)
	var distance := maxf(float(d["width"])*1.5,float(d["height"])*1.4)
	distance=maxf(distance,demo.beast_collision_shape.radius*4.0)
	if head_only and d["axial"]:
		focus=demo.beast.to_global(demo.genetics.mouth_local()).lerp(focus,.35)
		distance=maxf(distance,float(d["radius"])*5.0)
	if d["axial"] and not head_only:
		focus=demo.genetics.trail.point_at(float(d["length"])*.40)
		distance=maxf(8,float(d["length"])*1.4)
	demo.follow_camera.position=focus+Vector3(.6,.85,-1.0).rotated(Vector3.UP,view_angle)*maxf(5,distance)
	demo.follow_camera.look_at(focus)
func pose() -> void:
	view_angle=0
	demo.beast.position=Vector3(0,0,18);demo.beast.rotation=Vector3(0,-.5,0)
	if demo.genetics.trail.live:
		demo.genetics.trail.reset(demo.beast.position,demo.beast.global_basis.z);demo.genetics.trail.update_pose()
	demo._update_creature_animation(0,false);demo.genetics.morphology.animate(0,false);demo._update_camera(1);demo._update_hud()
func grow(n: int) -> void:
	for i in range(n): demo.genetics.genome.select_gene("physical_growth","capture_growth_%d"%i)
	demo.genetics.refresh()
func prerequisite(key: String) -> void:
	var required := {"gene_029":"gene_022","gene_121":"gene_029","gene_122":"gene_121","gene_052":"gene_015","gene_119":"gene_084","gene_180":"gene_062"}
	if required.has(key) and not demo.genetics.genome.ranks.has(required[key]):
		prerequisite(required[key]);demo.genetics.genome.select_gene(required[key],"capture_prereq_"+key)
func run() -> void:
	baseline="baseline" in OS.get_cmdline_user_args()
	if baseline: out="res://build/polish-baseline"
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(540,960)
	demo=load("res://scenes/BeachDemo.tscn").instantiate();root.add_child(demo)
	demo.set_physics_process(false);demo.world.state.path=out+"/capture-save.json"
	await physics_frame
	for f in GeneRegistry.FORMS:
		for growth in [0,6,12,18]:
			demo.genetics.fixture([f],3);grow(growth);pose()
			for angle in range(3):
				demo.ui_layer.show();view_angle=[0.0,TAU/3,TAU*2/3][angle];demo._update_camera(1)
				var target: Vector3=demo._camera_look_target()
				demo.follow_camera.position=target+(demo.follow_camera.position-target).rotated(Vector3.UP,view_angle)
				demo.follow_camera.look_at(target)
				await snap("%s_e%02d_a%d"%[f,growth,angle])
				inspect();await snap("inspect_%s_e%02d_a%d"%[f,growth,angle])
	if baseline: finish();return
	for host in GeneRegistry.FORMS:
		for key in GeneRegistry.LEGACY:
			demo.genetics.fixture([host],3)
			for tier in range(1,4):
				demo.genetics.genome.select_gene(key,"generic_%d"%tier);demo.genetics.refresh();pose();inspect(true)
				await snap("upgrade_%s_%s_%d"%[host,key,tier])
	for pair in HYBRIDS:
		for stage in range(3):
			demo.genetics.fixture(pair,stage+1);grow(stage*6);pose();demo.ui_layer.show();await snap("hybrid_%s_%d"%["_".join(pair),stage])
			inspect(true);await snap("inspect_hybrid_%s_%d"%["_".join(pair),stage])
	for gene in GeneRegistry.definitions().values():
		if int(gene["source_id"])<=0: continue
		demo.genetics.fixture([gene["family"]],2)
		prerequisite(gene["key"])
		if demo.genetics.genome.legal(gene["key"]): demo.genetics.genome.select_gene(gene["key"],"capture_source")
		demo.genetics.refresh();pose();inspect(true);await snap("source_%03d"%gene["source_id"])
	# Aerial proof beside a solid multi-storey gameplay structure.
	demo.genetics.fixture(["bird"],3)
	for key in ["gene_029","gene_121","gene_122"]: demo.genetics.genome.select_gene(key,key)
	demo.genetics.refresh();demo.beast.position=Vector3(0,0,-45)
	demo.genetics.traversal._end_mode();demo.beast.position=Vector3(0,0,-45)
	if demo.genetics.traversal.activate("flight"):
		for i in range(45): demo.genetics.traversal.direction_input(Vector3(0,0,-1),1,4,.1);demo._update_creature_animation(.1,true);demo.genetics.advance(.1)
		demo._update_camera(1);demo.ui_layer.show();await snap("action_flight")
		inspect(true);await snap("inspect_action_flight")
	# A long head-driven S path. The tube is sampled from the same saved history.
	demo.genetics.fixture(["snake"],3);grow(18);pose();demo.beast.position=Vector3(0,0,-310)
	demo.genetics.trail.reset(demo.beast.position,Vector3.BACK)
	for direction in [Vector3.FORWARD,Vector3.RIGHT,Vector3.BACK,Vector3.RIGHT,Vector3.FORWARD]:
		for i in range(70):
			var right: Vector3=demo.follow_camera.global_basis.x;right.y=0;right=right.normalized()
			var forward: Vector3=-demo.follow_camera.global_basis.z;forward.y=0;forward=forward.normalized()
			demo.touch_vector=Vector2(direction.dot(right),-direction.dot(forward));demo._update_movement(.05)
			demo.genetics.advance(.05)
	demo.touch_vector=Vector2.ZERO
	demo._update_camera(1);demo.ui_layer.show();await snap("action_snake_curve");inspect();await snap("inspect_action_snake_curve")
	for host in ["worm","mole"]:
		demo.genetics.fixture([host],3);grow(6);pose()
		demo.genetics.genome.select_gene("gene_119" if host=="worm" else "gene_052","dig");demo.genetics.refresh()
		demo.beast.position=Vector3(520,0,-170)
		if demo.genetics.trail.live: demo.genetics.trail.reset(demo.beast.position,Vector3.BACK)
		demo.genetics.traversal.activate("burrow")
		for stage in range(3):
			for i in range(4): demo.genetics.traversal.direction_input(Vector3(0,0,-1),0,5,.1);demo.genetics.trail.advance(demo.beast.position)
			demo._update_camera(1);demo.ui_layer.show();await snap("action_%s_dig_%d"%[host,stage])
		demo.genetics.traversal.activate("ground")
		for i in range(30): demo.genetics.traversal.direction_input(Vector3.ZERO,0,0,.1);demo.genetics.trail.advance(demo.beast.position)
		demo._update_camera(1);await snap("action_%s_emerge"%host)
	# A deliberately visible solid facade for the wall/roof interaction proof.
	demo.genetics.fixture(["spider"],3);demo.genetics.genome.select_gene("gene_180","hooks");demo.genetics.refresh()
	var wall := StaticBody3D.new();var collider := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size=Vector3(2,12,14);collider.shape=shape;wall.add_child(collider);demo.add_child(wall)
	wall.position=Vector3(310,6,-180);CoastalArt.box(wall,Vector3.ZERO,shape.size,Color("c2c8b3"))
	demo.beast.position=Vector3(306,0,-180);demo.beast.rotation.y=-PI*.5
	await physics_frame
	demo.genetics.traversal.activate("climb")
	for i in range(14): demo.genetics.traversal.direction_input(Vector3.ZERO,1,6,.1);demo.genetics.advance(.1)
	demo._update_camera(1);await snap("action_spider_wall");inspect(true);await snap("inspect_action_spider_wall")
	for i in range(60): demo.genetics.traversal.direction_input(Vector3.ZERO,1,6,.1)
	demo.genetics.morphology.movement_mode=demo.genetics.traversal.mode;demo.genetics.morphology.animate(0,false);demo._update_camera(1);demo.ui_layer.show();await snap("action_spider_roof")
	# Real portrait card UI at 20:9. Live geometry forecast thumbnails.
	demo.genetics.fixture(["bird"],2);demo.genetics.traversal._end_mode();pose();root.size=Vector2i(540,1200)
	demo.biomass=1000;demo._start_evolution();demo._finish_evolution()
	demo.ui_layer.show();await snap("ui_draft_20_9")
	paused=false;demo.choice_open=false;demo.modal.hide();demo.modal_shade.hide();demo.shedding.abort_shed()
	demo.genetics.hud.open();await snap("ui_lineage_20_9")
	finish()
