class_name WorldStreaming
extends Node3D
## Scene-owned streamer, explicitly advanced by BeachDemo's pause gate.
const BUDGET_USEC := 2000
const STRUCTURE_OVERHANG := 64.0 # Largest authored/generated half footprint is45 units.
const PLAYER_FIELDS := ["hp", "max_hp", "biomass", "evolutions", "armour", "strength", "speed_bonus", "bite_duration", "regeneration", "cocoon_rank", "metamorphosis_rank", "stamina", "max_stamina", "alert", "heat_cooldown", "response_clock", "response_wave"]
var scene: Node3D
var layout := WorldLayout.new()
var state := WorldState.new()
var chunks: Dictionary = {}
var authored: Dictionary = {}
var authored_count := 114
var free_slots: Array[int] = []
var desired: Dictionary = {}
var queue: Array[Vector2i] = []
var last_center := Vector2i(99999,99999)
var last_scale := -1.0
var refresh_clock := 0.0
var save_clock := 0.0
var generation_times: Array[float] = []
var max_tick_ms := 0.0
var test_mode := false
var initialized := false

func setup(owner_scene: Node3D) -> void:
	scene = owner_scene
	name = "WorldStreaming"
	# Script suites deliberately use clean in-memory worlds; live builds persist.
	for argument in OS.get_cmdline_args():
		if argument.begins_with("res://scripts/ci/"): test_mode = true
	for i in range(authored_count):
		var b: Dictionary = scene.buildings[i]
		var c := WorldLayout.coord(b["position"])
		if not authored.has(c): authored[c] = []
		authored[c].append(i)
	if not test_mode: state.read_save()
	layout.seed_value = state.seed_value
	for b in scene.buildings: state.apply(b)
	_make_backdrop()
	initialized = true
	restore_player()
	restore_vehicles()
	ensure_region(scene.beast.position, 190.0)
	scene._resolve_growth_clearance()
	scene._update_camera(1)
	for i in range(6):
		if Vector3(scene.buildings[i]["position"]).distance_to(scene.beast.position)<150: scene._activate_building(i,true)
	refresh()
	scene._update_hud()

func _make_backdrop() -> void:
	# A handful of finite terrain surfaces, never a full-detail map at startup.
	var terrain := SurfaceTool.new()
	terrain.begin(Mesh.PRIMITIVE_TRIANGLES)
	var span := ceili(WorldLayout.HALF_WIDTH/128)*128
	for x in range(-span,span,128):
		var a := Vector3(x,-.38,WorldLayout.shore(x))
		var b := Vector3(x+128,-.38,WorldLayout.shore(x+128))
		# Background terrain continues behind the impassable ridge at giant zoom.
		var inland_a := Vector3(x,-.38,WorldLayout.INLAND-6000)
		var inland_b := Vector3(x+128,-.38,WorldLayout.INLAND-6000)
		# Godot's visible faces use clockwise winding; normals point up explicitly.
		for v in [a,inland_a,b,b,inland_a,inland_b]:
			terrain.set_normal(Vector3.UP)
			terrain.add_vertex(v)
	var ground := MeshInstance3D.new()
	ground.mesh = terrain.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("98a589")
	ground.material_override = material
	add_child(ground)
	CoastalArt.box(self, Vector3(0,-2.2,0),Vector3(WorldLayout.HALF_WIDTH*4+8000,.4,50000),Color("4f9da7"))
	var ridge := Node3D.new()
	add_child(ridge)
	var groups := {}
	for x in range(-span-500,span+501,400):
		_add_boundary_hill(ridge,groups,"Inland_%d" % floori(x/1024.0),Vector3(x,-2,WorldLayout.INLAND-250),Vector3(12,27+6*sin(x*.013),9))
	for z in range(int(WorldLayout.INLAND)-300,301,350):
		for side in [-1,1]:
			_add_boundary_hill(ridge,groups,"Side_%d_%d" % [side,floori(z/1024.0)],Vector3(side*(WorldLayout.HALF_WIDTH+200),-2,z),Vector3(10,23+5*cos(z*.011),8))
	for group in groups.values(): CoastalArt.merge(group,"BoundaryRidges")

func _add_boundary_hill(parent: Node3D,groups: Dictionary,key: String,at: Vector3,size: Vector3) -> void:
	if not groups.has(key):
		var group := Node3D.new()
		group.name=key
		parent.add_child(group)
		groups[key]=group
	var group: Node3D = groups[key]
	CoastalArt._headland(group,Vector3.ZERO)
	var hill: MeshInstance3D = group.get_child(group.get_child_count()-1)
	hill.position=at
	hill.scale=size

func ensure_region(at: Vector3, radius: float) -> void:
	if not initialized: return
	# Collider ownership follows the centre, so include owners beyond the query edge.
	radius+=STRUCTURE_OVERHANG
	var first := WorldLayout.coord(at - Vector3(radius,0,radius))
	var last := WorldLayout.coord(at + Vector3(radius,0,radius))
	for x in range(first.x,last.x+1):
		for z in range(first.y,last.y+1):
			var c := Vector2i(x,z)
			if _valid(c): _load(c, true)

func _valid(c: Vector2i) -> bool:
	return c.x >= floori(-WorldLayout.HALF_WIDTH/256) and c.x <= floori(WorldLayout.HALF_WIDTH/256) and c.y >= floori(WorldLayout.INLAND/256) and c.y <= 0

func ensure_segment(start: Vector3, end: Vector3) -> void:
	var distance := start.distance_to(end)
	for step in range(ceili(distance/100)+1):
		ensure_region(start.lerp(end,minf(1,float(step)*100/maxf(1,distance))),12)
	ensure_region(end,12)

func refresh() -> void:
	desired.clear()
	queue.clear()
	var center: Vector3 = scene.beast.position
	var safety := maxf(190.0, scene.growth_scale * 7.0 + 100.0)
	# Far geometry follows projected terrain coverage; no actor/collider cost there.
	var view_radius := maxf(520.0, scene._camera_offset().length() * 2.0 + 300.0)
	var first := WorldLayout.coord(center - Vector3(view_radius,0,view_radius))
	var last := WorldLayout.coord(center + Vector3(view_radius,0,view_radius))
	for x in range(first.x,last.x+1):
		for z in range(first.y,last.y+1):
			var c := Vector2i(x,z)
			if not _valid(c): continue
			var at := Vector3((x+.5)*256,0,(z+.5)*256)
			var near := at.distance_to(center) < safety + 182
			if near or _visible(c): desired[c] = near
	# Pin local moving actors and the complete remaining projectile corridor.
	for foe in scene.officers:
		_pin_region(foe["node"].global_position, 100)
	for shot in scene.projectiles:
		var at: Vector3 = shot["node"].global_position
		_pin_region(at, 160)
	for c in chunks:
		if not desired.has(c): queue.append(c)
	for c in queue: _unload(c)
	queue.clear()
	for c in desired:
		if not chunks.has(c) or bool(chunks[c]["collision"]) != bool(desired[c]): queue.append(c)
	queue.sort_custom(func(a: Vector2i,b: Vector2i): return Vector2(a-WorldLayout.coord(center)).length_squared() < Vector2(b-WorldLayout.coord(center)).length_squared())
	last_center = WorldLayout.coord(center)
	last_scale = scene.growth_scale

func _pin_region(at: Vector3, radius: float) -> void:
	var a := WorldLayout.coord(at-Vector3(radius,0,radius))
	var b := WorldLayout.coord(at+Vector3(radius,0,radius))
	for x in range(a.x,b.x+1):
		for z in range(a.y,b.y+1):
			var c := Vector2i(x,z)
			if _valid(c): desired[c] = true

func _visible(c: Vector2i) -> bool:
	var camera: Camera3D = scene.follow_camera
	var rect := Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).grow(120)
	for dx in [0.0,128.0,256.0]:
		for dz in [0.0,128.0,256.0]:
			for h in [0.0,100.0]:
				var point := Vector3(c.x*256+dx,h,c.y*256+dz)
				if camera.is_position_in_frustum(point): return true
				# Prefetch beyond screen edges before travel or a growth-camera transition.
				if not camera.is_position_behind(point) and rect.has_point(camera.unproject_position(point)) and point.distance_to(camera.global_position)<camera.far+256: return true
	return false

func advance(delta: float) -> void:
	var started := Time.get_ticks_usec()
	refresh_clock -= delta
	if WorldLayout.coord(scene.beast.position) != last_center or not is_equal_approx(last_scale,scene.growth_scale) or refresh_clock <= 0:
		refresh_clock = .3
		refresh()
	while not queue.is_empty() and Time.get_ticks_usec()-started < BUDGET_USEC:
		var c: Vector2i = queue.pop_front()
		if desired.has(c): _load(c,desired[c])
	# Promote/demote authored detail with distance, retaining simple physical cover.
	for c in chunks:
		if not chunks[c]["collision"]: continue
		for i in chunks[c]["indices"]:
			var b: Dictionary = scene.buildings[i]
			var distance: float = Vector3(b["position"]).distance_to(scene.beast.position)
			var full := distance < maxf(130.0,scene.growth_scale*4+80)
			if bool(b.get("full",false)) != full and not b["destroyed"]:
				# One expensive art promotion per frame.
				if Time.get_ticks_usec()-started < BUDGET_USEC: scene._activate_building(i,full)
	max_tick_ms = maxf(max_tick_ms,(Time.get_ticks_usec()-started)/1000.0)
	save_clock += delta
	if save_clock >= 10:
		save_clock = 0
		if not test_mode: save_now()

func _load(c: Vector2i, collision: bool) -> void:
	if chunks.has(c):
		if chunks[c]["collision"] == collision: return
		_unload(c)
	var started := Time.get_ticks_usec()
	var root := Node3D.new()
	root.name = "Chunk_%d_%d" % [c.x,c.y]
	add_child(root)
	var indices: Array[int] = []
	if collision:
		for i in authored.get(c,[]):
			indices.append(i)
			var b: Dictionary = scene.buildings[i]
			scene._activate_building(i,false)
	for d in layout.describe(c):
		var b: Dictionary = d.duplicate()
		b["destroyed"] = false
		b["reward_claimed"] = false
		state.apply(b)
		if collision:
			var i: int = scene._register_generated(d,free_slots.pop_back() if not free_slots.is_empty() else -1)
			state.apply(scene.buildings[i])
			indices.append(i)
			scene._activate_building(i,false)
		elif not b["destroyed"]:
			_silhouette(root,d)
	if not collision:
		for i in authored.get(c,[]):
			var b: Dictionary = scene.buildings[i]
			if not b["destroyed"]:
				_silhouette(root,{"position":b["position"],"size":Vector2(b["half"])*2,"height":b["height"],"colour":b["colour"]})
	_draw_roads(root,c)
	var center := Vector3((c.x+.5)*256,0,(c.y+.5)*256)
	if not WorldLayout.authored(center) and WorldLayout.inside(center,180): WorldEnvironmentArt.landscape(root,c,layout.district(center))
	if root.get_child_count()>0: CoastalArt.merge(root,"TerrainAndSkyline")
	chunks[c] = {"node":root,"indices":indices,"collision":collision}
	generation_times.append((Time.get_ticks_usec()-started)/1000.0)
	if generation_times.size()>4096: generation_times.pop_front()

func _silhouette(root: Node3D,d: Dictionary) -> void:
	var p: Vector3 = d["position"]
	var size: Vector2 = d["size"]
	var height: float = d["height"]
	CoastalArt.box(root,p+Vector3(0,height*.5,0),Vector3(size.x,height,size.y),d["colour"])
	CoastalArt.box(root,p+Vector3(0,height+.25,0),Vector3(size.x+1,.5,size.y+1),CoastalArt.ROOF)

func _draw_roads(root: Node3D,c: Vector2i) -> void:
	for road in WorldLayout.road_segments(c):
		var a: Vector3 = road["a"]
		var b: Vector3 = road["b"]
		var size := Vector3(14,.08,b.z-a.z) if a.x==b.x else Vector3(b.x-a.x,.08,14)
		CoastalArt.box(root,(a+b)*.5+Vector3(0,-.05,0),size,Color("64757a"))
	# Continuous coastal arterial and surf follow the same sampled shoreline.
	if c.y in [-2,-1,0]:
		for i in range(16):
			var x := c.x*256+i*16+8.0
			var shore := WorldLayout.shore(x)
			if absi(c.x)>2 and shore>=c.y*256 and shore<(c.y+1)*256:
				CoastalArt.box(root,Vector3(x,-.29,shore-24),Vector3(16,.3,100),Color("d9c79e"))
				CoastalArt.box(root,Vector3(x,-.05,shore-53),Vector3(16,.08,12),Color("687a7a"))
				CoastalArt.box(root,Vector3(x,-.02,shore+5),Vector3(16,.04,10),Color("8ab9b4"))
	# Extend the authored main road and cross-street exits into the generated graph.
	if c.x in [-2,-1,0,1] and c.y in range(-6,0):
		for z in [-27.,-131.,-175.,-263.,-307.,-377.,-431.,-493.,-548.,-612.,-714.,-905.,-1032.,-1165.,-1298.,-1450.]:
			if z>=c.y*256 and z<(c.y+1)*256:
				var edge := 342.5 if z < -500 else (118.0 if z < -80 else 0.0)
				for side in [-1,1]:
					var a := maxf(edge, c.x*256.0) if side>0 else maxf(edge,-(c.x+1)*256.0)
					var b := minf(512, (c.x+1)*256.0) if side>0 else minf(512,-c.x*256.0)
					if b>a: CoastalArt.box(root,Vector3(side*(a+b)*.5,-.05,z),Vector3(b-a,.08,12),Color("64757a"))
	if c.x==0 and c.y<=-6:
		CoastalArt.box(root,Vector3(0,-.05,c.y*256+128),Vector3(20,.08,256),Color("64757a"))

func _unload(c: Vector2i) -> void:
	if not chunks.has(c): return
	for i in chunks[c]["indices"]:
		var b: Dictionary = scene.buildings[i]
		state.remember(b)
		scene._deactivate_building(i)
		if i>=authored_count:
			scene.buildings[i] = {"destroyed":true,"vacant":true}
			free_slots.append(i)
	chunks[c]["node"].queue_free()
	chunks.erase(c)

func remember_all() -> void:
	for b in scene.buildings:
		if not b.get("vacant",false): state.remember(b)

func descriptors_in_rect(rect: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(authored_count):
		var b: Dictionary = scene.buildings[i]
		var p: Vector3 = b["position"]
		if rect.grow(100).has_point(Vector2(p.x,p.z)): result.append(b)
	var a := WorldLayout.coord(Vector3(rect.position.x,0,rect.position.y))
	var b := WorldLayout.coord(Vector3(rect.end.x,0,rect.end.y))
	for x in range(a.x,b.x+1):
		for z in range(a.y,b.y+1):
			for d in layout.describe(Vector2i(x,z)):
				d["half"] = Vector2(d["size"])*.5
				state.apply(d)
				result.append(d)
	return result

func save_now() -> bool:
	if scene.evolving or scene.choice_open or scene.reveal_active: return false
	remember_all()
	var snapshot := {}
	for field in PLAYER_FIELDS: snapshot[field] = scene.get(field)
	snapshot["position"] = [scene.beast.position.x,scene.beast.position.y,scene.beast.position.z]
	snapshot["history"] = scene.evolution_history
	snapshot["mutations"] = scene.mutation_visual_counts
	var pending := []
	for event in scene.evacuations.pending:
		pending.append({"center":[event["center"].x,event["center"].z],"half":[event["half"].x,event["half"].y],"remaining":event["remaining"],"released":event["released"]})
	snapshot["evacuations"] = pending
	var vehicles := {}
	for car in scene.cars:
		if car.get("persistent",false):
			vehicles[car["id"]] = {"destroyed":car["destroyed"],"hits":car["hits"]}
	state.events["vehicles"] = vehicles
	state.player = snapshot
	return state.write_save()

func restore_player() -> void:
	var p := state.player
	if p.is_empty(): return
	for field in PLAYER_FIELDS:
		if p.has(field): scene.set(field,p[field])
	if scene.hp<=0:
		scene.game_over=true
		scene.retry_button.show()
	scene.evolution_history.assign(p.get("history",[]))
	for id in p.get("mutations",{}):
		for n in range(int(p["mutations"][id])): scene._apply_mutation_visual(id)
	var level: int = scene.evolutions
	while level>0 and not GrowthProgression.is_growth_step(level): level-=1
	if level>0: scene._apply_growth_milestone(level)
	var pos: Array = p.get("position",[0,0,0])
	var at := Vector3(float(pos[0]),0,float(pos[2]))
	if WorldLayout.inside(at): scene.beast.position = at
	for event in p.get("evacuations",[]):
		scene.evacuations.pending.append({"center":Vector3(event["center"][0],0,event["center"][1]),"half":Vector2(event["half"][0],event["half"][1]),"remaining":int(event["remaining"]),"released":int(event["released"])})
	scene._update_camera(1)

func restore_vehicles() -> void:
	var vehicles: Dictionary = state.events.get("vehicles",{})
	for i in range(scene.cars.size()):
		var car: Dictionary = scene.cars[i]
		var saved: Dictionary = vehicles.get(car.get("id",""),{})
		for key in saved: car[key] = saved[key]
		if car["destroyed"] and is_instance_valid(car["node"]):
			car["node"].queue_free()
			car["node"] = null
			car["collider"] = null
