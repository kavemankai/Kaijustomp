extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,why: String) -> void:
	if not ok: failed=true;printerr("POLISH LIFECYCLE TEST FAILED: "+why)
func run() -> void:
	for form in ["bird","mole","spider"]:
		var demo=load("res://scenes/BeachDemo.tscn").instantiate();root.add_child(demo);demo.set_physics_process(false)
		await physics_frame
		var path: String="user://polish-life-"+form+".json";demo.world.state.path=path
		demo.genetics.fixture([form],3)
		for key in (["gene_029","gene_121"] if form=="bird" else (["gene_052"] if form=="mole" else ["gene_180"])): demo.genetics.genome.select_gene(key,key)
		demo.genetics.refresh();demo.beast.position=Vector3(520,0,-170)
		if form=="spider":
			var wall := StaticBody3D.new();var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size=Vector3(2,18,14);shape.shape=box;wall.add_child(shape);demo.add_child(wall);wall.position=Vector3(310,9,-180);demo.beast.position=Vector3(306,0,-180);demo.beast.rotation.y=-PI*.5
			await physics_frame
		var mode := "flight" if form=="bird" else ("burrow" if form=="mole" else "climb")
		check(demo.genetics.traversal.activate(mode),"enter mode "+mode)
		for i in range(12): demo.genetics.traversal.direction_input(Vector3.ZERO,1,6,.1)
		demo.genetics.traversal.vertical_input=1;demo.touch_vector=Vector2.ONE;demo.sprint_requested=true
		demo._notification(NOTIFICATION_APPLICATION_PAUSED)
		check(demo.genetics.traversal.vertical_input==0 and demo.touch_vector==Vector2.ZERO and not demo.sprint_requested,"Android pause clears input "+mode)
		check(demo.world.save_now(),"active-mode checkpoint "+mode)
		var saved := WorldState.new();saved.path=path;check(saved.read_save(),"active-mode save valid "+mode)
		check(BeachGenetics.valid(saved.player["genetics"]),"genome + path + mode validation")
		# Each phenotype's live mouth collider follows the same canonical transform.
		demo._update_creature_animation(0,false)
		check(demo.head_collision_node.position.is_equal_approx(demo.genetics.mouth_local()),"anatomical mouth collision "+form)
		# Real button rectangles must not overlap in common portrait layouts.
		for size in [Vector2i(540,960),Vector2i(540,1200),Vector2i(768,1024)]:
			root.size=size;await process_frame;demo.genetics.hud.refresh()
			var h: GeneticsHUD=demo.genetics.hud
			check(not h.traverse_button.get_global_rect().intersects(demo.debug_evolve_button.get_global_rect()),"traverse/debug nonoverlap")
			check(not h.ascend_button.get_global_rect().intersects(h.descend_button.get_global_rect()),"altitude nonoverlap")
			check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(h.traverse_button.get_global_rect()),"portrait mode control fits")
		root.size=Vector2i(540,960)
		demo._prepare_authored(0);demo._damage_building(0,10000)
		var id: String=demo.buildings[0]["id"]
		demo._take_damage(1000000)
		check(demo.game_over and demo.genetics.traversal.vertical_input==0,"death clears altitude "+mode)
		check(demo.genetics.new_organism_keep_world(false),"new life while traversing "+mode)
		var newborn := WorldState.new();newborn.path=path;check(newborn.read_save(),"new life checkpoint")
		check(newborn.objects[id]["destroyed"] and GenomeState.from_record(newborn.player["genetics"]["genome"]).total()==0,"world preserved, genome replaced")
		demo.queue_free();await process_frame
		for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	if not failed: print("POLISH LIFECYCLE TEST PASSED: flight/burrow/climb pause/checkpoint/death/new life, mouth transforms and 3 portrait control layouts")
	quit(1 if failed else 0)
