extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,why: String) -> void:
	if not ok: failed=true;printerr("POLISH TRAVERSAL TEST FAILED: "+why)
func run() -> void:
	var demo=load("res://scenes/BeachDemo.tscn").instantiate();root.add_child(demo);demo.set_physics_process(false)
	await physics_frame
	demo.world.state.path="user://polish-traversal-ci.json"
	var safe := Vector3(520,0,-170)
	for f in ["snake","worm"]:
		demo.genetics.fixture([f])
		for i in range(18): demo.genetics.genome.select_gene("physical_growth","size_%d"%i)
		demo.genetics.refresh()
		var trail: AxialTrail=demo.genetics.trail
		demo.beast.position=safe;trail.reset(safe,Vector3.BACK)
		# Very slow movement used to exhaust 220 per-frame points and erase the tail.
		for i in range(1000): trail.advance(safe+Vector3(i*.005,0,0))
		check(trail.samples.size()<=220,"bounded slow history")
		check(trail.point_at(trail.total_length).distance_to(trail.samples[0])>trail.total_length*.7,"slow motion retains full length "+f)
		var previous: Vector3=trail.point_at(trail.total_length*.85)
		# S/90/U turns, including a 4-unit movement spike.
		for i in range(120):
			var a := i*.038
			var p := safe+Vector3(5+sin(a)*18,0,cos(a)*18-18)
			trail.advance(p)
			var tail: Vector3=trail.point_at(trail.total_length*.85)
			check(tail.distance_to(previous)<2,"continuous tail during turn")
			previous=tail
		trail.advance(trail.samples[0]+Vector3(4,0,0))
		check(trail.point_at(trail.total_length*.85).distance_to(previous)<5,"delta spike bounded tail travel")
		var at: Vector3=trail.point_at(32)
		var record := trail.record();trail.restore(record)
		check(at.is_equal_approx(trail.point_at(32)),"path save/reload continuity")
		check(trail.contact_areas.size()<=40 and trail.mesh_build_count==1,"one mesh and bounded colliders")
		# A new obstruction across an occupied body section is physically detected.
		var wall := StaticBody3D.new();var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size=Vector3(3,5,3);shape.shape=box;wall.add_child(shape);demo.add_child(wall)
		wall.position=trail.contact_areas[2].position+Vector3.UP
		await physics_frame
		var contact := false
		for i in range(12): contact=trail.constrain_head_motion() or contact
		check(contact,"physical trailing obstruction "+f)
		wall.free();await physics_frame
		# Rear mutations and their damage origin must follow the long body.
		demo.beast.position=trail.samples[0]
		for tier in range(2): demo.genetics.genome.select_gene(GeneRegistry.seed_key(f),"tail_host_%d"%tier)
		check(demo.genetics.genome.select_gene("gene_019","tail_club"),"axial tail club selection")
		demo.genetics.refresh()
		var club: Node3D=demo.genetics.morphology.tail_club
		var club_at := trail.point_at(trail.total_length*.92)+Vector3.UP*trail.radius*.7
		check(is_instance_valid(club) and club.global_position.distance_to(club_at)<.01,"fractional rear organ follows curve")
		check(club_at.distance_to(demo.beast.position)>20,"rear organ not glued to anterior")
		demo._spawn_response_enemy(Vector3(club_at.x,0,club_at.z),"police")
		var foe: Dictionary=demo.officers.back()
		var health: float=foe["health"]
		demo.genetics.effects.advance(.1)
		check(float(foe["health"])<health,"tail contact uses real rear organ origin")
		for officer in demo.officers: officer["node"].free()
		demo.officers.clear()
	# Touch route drives flight through the same movement function as gameplay.
	demo.genetics.fixture(["bird"])
	for key in ["gene_029","gene_121"]: check(demo.genetics.genome.select_gene(key,key),"flight prerequisite")
	demo.genetics.refresh();demo.beast.position=safe
	check(demo.genetics.traversal.activate("flight"),"takeoff")
	demo.genetics.traversal.vertical_input=1;demo.touch_vector=Vector2(.3,-1)
	for i in range(35): demo._update_movement(.05)
	check(demo.beast.position.y>3 and demo.stamina<demo.max_stamina,"touch altitude and finite lift")
	demo.genetics.hud.open()
	check(demo.genetics.traversal.vertical_input==0 and demo.touch_vector==Vector2.ZERO,"opening UI resets held inputs")
	demo.genetics.hud.close();paused=false
	demo.stamina=.01;demo.genetics.traversal.direction_input(Vector3.ZERO,1,0,.1)
	check(demo.genetics.traversal.mode=="glide","exhaustion has recoverable glide")
	demo.genetics.traversal._end_mode();demo.beast.position=safe
	for i in range(3): demo.genetics.genome.select_gene("armour","armour_%d"%i)
	demo.genetics.refresh()
	check(not demo.genetics.traversal.can_use("flight") and demo.genetics.traversal.can_use("glide"),"heavy wing load needs soaring")
	check(demo.genetics.genome.select_gene("gene_122","soaring"),"soaring support")
	demo.genetics.refresh();check(demo.genetics.traversal.can_use("flight"),"soaring restores heavy lift")
	for f in ["worm","mole"]:
		demo.genetics.fixture([f]);demo.genetics.genome.select_gene("gene_119" if f=="worm" else "gene_052","dig");demo.genetics.refresh();demo.beast.position=safe
		var t: CreatureTraversal=demo.genetics.traversal
		check(t.activate("burrow"),"soil entry "+f)
		check(demo.beast.position.y>-.2,"entry has no depth teleport")
		for i in range(25): t.direction_input(Vector3.RIGHT,0,5,.1);demo.genetics.trail.advance(demo.beast.position)
		check(demo.beast.position.y<-2,"progressive depth "+f)
		check(t.activate("ground") and t.mode=="emerging","controlled emerge "+f)
		for i in range(30): t.direction_input(Vector3.ZERO,0,0,.1)
		check(t.mode=="ground" and demo.beast.collision_mask==1,"safe emergence collision "+f)
		demo.beast.position.z=WorldLayout.shore(demo.beast.position.x)+5
		check(not t.activate("burrow"),"shore refuses excavation")
	# Destroyed-wall support cannot leave a spider hovering.
	demo.genetics.fixture(["spider"]);demo.genetics.genome.select_gene("gene_180","hooks");demo.genetics.refresh()
	var facade := StaticBody3D.new();var collider := CollisionShape3D.new();var box := BoxShape3D.new();box.size=Vector3(2,12,16);collider.shape=box;facade.add_child(collider);demo.add_child(facade)
	facade.position=Vector3(310,6,-180);demo.beast.position=Vector3(306,0,-180);demo.beast.rotation.y=-PI*.5
	await physics_frame
	check(demo.genetics.traversal.activate("climb"),"real wall attach")
	for i in range(8): demo.genetics.traversal.direction_input(Vector3(0,0,1),1,6,.1)
	check(demo.beast.position.y>1,"wall lateral/vertical route")
	facade.free();await physics_frame
	demo.genetics.traversal.direction_input(Vector3.ZERO,1,6,.1)
	check(demo.genetics.traversal.mode=="falling","destroyed support safe fall")
	for i in range(60): demo.genetics.traversal.direction_input(Vector3.ZERO,0,0,.1)
	check(demo.genetics.traversal.mode=="ground","fall recovers")
	demo.queue_free();await process_frame
	for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path("user://polish-traversal-ci.json"+suffix))
	if not failed: print("POLISH TRAVERSAL TEST PASSED: slow giant paths, S/U/delta turns, save continuity, wall body contact, touch flight exhaustion, soil/borders/emergence, destroyed climbing support")
	quit(1 if failed else 0)
