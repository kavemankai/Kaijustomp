extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,reason: String) -> void:
	if not ok:
		failed = true
		printerr("WORLD RESPONSE TEST FAILED: "+reason)
func run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	for at in [Vector3(0,0,-1000),Vector3(4096,0,-3072),Vector3(-6144,0,-5120)]:
		for foe in demo.officers: foe["node"].queue_free()
		demo.officers.clear()
		demo.beast.position=at
		demo._update_camera(1)
		demo.world.ensure_region(at,200)
		demo._spawn_local_response(24,"armoured")
		demo._spawn_local_response(-24,"helicopter")
		check(demo.officers.size()==2,"No viable offscreen response in district")
		var initial := {}
		for foe in demo.officers:
			var node: Node3D = foe["node"]
			initial[foe["kind"]]=node.global_position.distance_to(at)
			check(not demo._response_is_visible(Vector3(node.position.x,0,node.position.z),foe["kind"]),"Physical arrival materialises in camera")
			if foe["kind"]=="armoured": check(demo._blocking_building(node.position,3.5)<0,"APC arrives in building")
		for frame in range(400):
			demo._update_police(.1)
			demo._update_projectiles(.1)
			if frame%20==0:
				demo.world.advance(.1)
				await physics_frame
		for foe in demo.officers:
			var node: Node3D = foe["node"]
			check(node.position.distance_to(at)<float(initial[foe["kind"]])-20,"Arrival permanently occupies cap without approaching")
			if foe["kind"]=="helicopter": check(is_equal_approx(node.position.y,22 if WorldLayout.authored(at) else 120),"Aircraft altitude lost or city towers not cleared")
		check(demo.officers.size()<=9 and demo.projectiles.size()<=72,"Response/projectile caps exceeded")
		check(demo.world.chunks.size()<100,"Entire approach corridor stays fully resident")
	# Far population retires and evacuation overflow remains compact near its source.
	demo.beast.position=Vector3(8192,0,-4096)
	demo.population_clock=0
	demo._maintain_population(0)
	for person in demo.civilians:
		check(person["node"].position.distance_to(demo.beast.position)<151,"Distant civilian remains simulated")
	demo._update_cars(1)
	for car in demo.cars:
		if car.get("active",false) and not car["destroyed"]:
			check(car["node"].position.distance_to(demo.beast.position)<321,"Distant traffic retains active physics")
	check(demo.civilians.size()<=42 and demo.cars.size()<=20,"Population caps changed")
	if not failed: print("WORLD RESPONSE TEST PASSED: multi-district offscreen APC/air approaches, reachable routing, cap recovery, collision coverage and local actor cleanup")
	quit(1 if failed else 0)
