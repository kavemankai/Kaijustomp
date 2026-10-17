extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,reason: String) -> void:
	if not ok:
		failed = true
		printerr("WORLD STREAMING TEST FAILED: "+reason)
func settle(demo: Node) -> void:
	demo._update_camera(1)
	demo.world.refresh()
	for i in range(50):
		demo.world.advance(.016)
		if demo.world.queue.is_empty(): break
	await physics_frame
func run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	var initial_active := 0
	for b in demo.buildings:
		if b.get("active",false): initial_active+=1
	check(initial_active<114,"Whole authored world still instantiated at launch")
	check(not demo.buildings[102]["active"],"Distant industry is permanently resident")
	# Real swept movement follows continuous coastal and inland routes.
	demo.beast.position = Vector3(0,0,17)
	var peak_chunks := 0
	for goal in [Vector3(-8500,0,0),Vector3(8500,0,0),Vector3(8500,0,-5500)]:
		var coastal: bool = goal.z==0
		var steps := 0
		while absf(demo.beast.position.x-goal.x)>20 or (not coastal and absf(demo.beast.position.z-goal.z)>20):
			steps+=1
			if steps>1800:
				check(false,"Travel stalled before reaching "+str(goal))
				break
			var direction := Vector3(signf(goal.x-demo.beast.position.x),0,0) if absf(goal.x-demo.beast.position.x)>20 else Vector3(0,0,-1)
			if coastal:
				var target_z := WorldLayout.shore(demo.beast.position.x+direction.x*22)-8
				direction.z = (target_z-demo.beast.position.z)/22
				direction = direction.normalized()
			else:
				# This highway is a global chunk edge, clear from coast to inland ridge.
				demo.beast.position.x = 8448
				goal.x = 8448
				direction = Vector3(0,0,-1)
			demo._update_camera(1)
			var right: Vector3 = demo.follow_camera.global_basis.x
			var forward: Vector3 = -demo.follow_camera.global_basis.z
			right.y=0; forward.y=0
			right=right.normalized(); forward=forward.normalized()
			demo.touch_vector = Vector2(direction.dot(right),-direction.dot(forward))
			var before: Vector3 = demo.beast.position
			demo._update_movement(2)
			check(demo.beast.position.distance_to(before)>1,"Swept travel hit an unexplained chunk seam")
			demo.world.advance(2)
			peak_chunks = maxi(peak_chunks,demo.world.chunks.size())
			await physics_frame
	check(peak_chunks<100,"Hatchling retains unrelated chunks")
	check(demo.buildings.size()<1000,"Generated object registry grows with distance travelled")
	# Generated destruction, partial damage and reward survive real unload/reload.
	demo.beast.position = Vector3(3072,0,-3072)
	await settle(demo)
	var candidates: Array = demo.world.chunks[Vector2i(12,-12)]["indices"]
	check(candidates.size()>1,"Expanded district has no functional structures")
	if candidates.size()<2: quit(1); return
	var target_index: int = candidates[0]
	var damage_index: int = candidates[1]
	var id: String = demo.buildings[target_index]["id"]
	var damaged_id: String = demo.buildings[damage_index]["id"]
	var b: Dictionary = demo.buildings[damage_index]
	var center: Vector3 = b["position"]
	var half: Vector2 = b["half"]
	var collider: StaticBody3D = b["collider"]
	for full in [true,false,true]:
		demo._activate_building(damage_index,full)
		var query := PhysicsRayQueryParameters3D.create(center+Vector3(0,1,half.y+5),center+Vector3(0,1,-half.y-5),1)
		query.exclude=[demo.beast.get_rid()]
		var hit: Dictionary = demo.beast.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and hit["collider"]==collider,"LOD transition temporarily removes projectile cover")
	demo.growth_scale=4
	demo._damage_building(damage_index,1)
	var remaining: float = demo.buildings[damage_index]["hits"]
	demo._damage_building(target_index,10000)
	var biomass: int = demo.biomass
	demo.world._unload(Vector2i(12,-12))
	await physics_frame
	demo.world.ensure_region(Vector3(3200,0,-2944),1)
	target_index=demo._index_for_world_id(id)
	damage_index=demo._index_for_world_id(damaged_id)
	check(target_index>=0 and demo.buildings[target_index]["destroyed"],"Destroyed structure reappears after reload")
	check(damage_index>=0 and is_equal_approx(demo.buildings[damage_index]["hits"],remaining),"Partial damage resets")
	demo._damage_building(target_index,10000)
	check(demo.biomass==biomass,"Reload permits duplicate biomass")
	# Descriptor-only responder routing navigates around the original warehouses.
	var path := WorldRouting.route(Vector3(-380,0,-830),Vector3(0,0,-830),demo.world,3.5)
	check(path.size()>3,"Industrial responder route unavailable")
	for p in path:
		check(demo._blocking_building(p,3.5)<0,"Responder path intersects warehouse hull")
	# At extreme sizes, colliders on both sides of a seam remain available.
	for level in [34,55,80,120]:
		var milestone: int = level
		while not GrowthProgression.is_growth_step(milestone): milestone-=1
		demo._apply_growth_milestone(milestone)
		demo.beast.position=Vector3(4096,0,-3072)
		demo._update_camera(1)
		demo.world.ensure_region(demo.beast.position,demo.growth_scale*4+20)
		await settle(demo)
		check(demo.world.chunks[Vector2i(15,-13)]["collision"] and demo.world.chunks[Vector2i(16,-12)]["collision"],"Giant seam lacks collision on both sides")
		for kind in ["armoured","helicopter"]:
			var at: Vector3 = demo._find_offscreen_response_spawn(kind,24)
			check(not at.is_finite() or not demo._response_is_visible(at,kind),"Giant arrival appears onscreen")
	check(demo.civilians.size()<=42 and demo.officers.size()<=9 and demo.projectiles.size()<=72,"Existing entity caps changed")
	# Static streaming can finish during a paused reveal, without advancing actors/shots.
	demo.beast.position=Vector3(-4096,0,-3072)
	demo._update_camera(1)
	demo.world.refresh()
	var pending: int = demo.world.queue.size()
	var saved_position: Vector3 = demo.beast.position
	demo._spawn_projectile(saved_position+Vector3(0,200,0),Vector3.UP,false)
	var shot: Node3D = demo.projectiles[-1]["node"]
	var shot_position := shot.position
	demo.reveal_active=true
	for frame in range(20): demo._physics_process(.016)
	check(demo.world.queue.size()<pending,"Paused reveal leaves the enlarged camera world unloaded")
	check(demo.beast.position==saved_position and shot.position==shot_position,"Streaming bypasses gameplay pause")
	if not failed: print("WORLD STREAMING TEST PASSED: 25km swept coastal travel, 5.5km inland, bounded chunks/records, damage/reward persistence, warehouse routes and giant collision/arrivals")
	quit(1 if failed else 0)
