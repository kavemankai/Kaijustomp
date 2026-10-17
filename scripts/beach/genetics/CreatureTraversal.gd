class_name CreatureTraversal
extends Node
## One position authority for air, underground and vertical wall modes.
## No flight/underground claim is made for a merely decorative organ.
var scene: Node3D
var mode := "ground"
var height_target := 0.0
var climb_normal := Vector3.ZERO
var underground_depth := 3.5
var toggled := false
var vertical_input := 0.0
var last_error := ""
var ground_marker: MeshInstance3D
var seismic_distance := 0.0
var bank := 0.0
func setup(game: Node3D) -> void:
	scene=game
	name="CreatureTraversal"
	ground_marker=CoastalArt.oval(scene,Vector3.ZERO,Vector3(.9,.13,1.15),Color("bca47c"))
	ground_marker.name="UndergroundSeismicTrace"
	ground_marker.visible=false
func can_use(kind: String) -> bool:
	if not scene.genetics.enabled: return false
	var g: Dictionary=scene.genetics.genome.ranks
	match kind:
		"flight":
			if scene.genetics.dimensions.get("axial",false) and float(scene.genetics.dimensions.get("length",0))>24: return false
			return int(g.get("gene_121",0))>0 and (not (scene.genetics.morphology.primary in ["ape","crab","worm"] or int(g.get("armour",0))>=3) or int(g.get("gene_122",0))>0)
		"glide": return int(g.get("gene_029",0))>0
		"burrow": return int(g.get("gene_052",0))>0 or int(g.get("gene_119",0))>0
		"climb": return int(g.get("gene_180",0))>0
	return kind=="ground"
func _safe_surface(p: Vector3) -> bool:
	if absf(p.x) > WorldLayout.HALF_WIDTH-10 or p.z<WorldLayout.INLAND+10 or p.z>WorldLayout.shore(p.x)-5: return false
	scene.world.ensure_region(Vector3(p.x,0,p.z),maxf(28,scene.growth_scale*5.0))
	return scene._blocking_building(Vector3(p.x,0,p.z),maxf(1.5,scene.beast_collision_shape.radius))<0
func _wall_probe() -> Dictionary:
	var ahead: Vector3 = -scene.beast.global_transform.basis.z
	var origin: Vector3 = scene.beast.global_position+Vector3(0,1.2,0)
	var ray:=PhysicsRayQueryParameters3D.create(origin,origin+ahead*maxf(4.5,scene.beast_collision_shape.radius+1.5))
	ray.collision_mask=1
	ray.exclude=[scene.beast.get_rid()]
	return scene.beast.get_world_3d().direct_space_state.intersect_ray(ray)
func _roof_probe(at: Vector3) -> Dictionary:
	# Probe inward across the wall's top face; do not invent a roof when
	# the corresponding solid collider has been destroyed.
	var inside: Vector3=at-climb_normal*(scene.beast_collision_shape.radius+2.0)
	var query:=PhysicsRayQueryParameters3D.create(inside+Vector3.UP*5.0,inside-Vector3.UP*6.0)
	query.exclude=[scene.beast.get_rid()]
	query.collision_mask=1
	var result: Dictionary=scene.beast.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty() or Vector3(result["normal"]).y<.75: return {}
	return result

func _roof_support(at: Vector3) -> Dictionary:
	var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*3.5,at-Vector3.UP*5)
	ray.exclude=[scene.beast.get_rid()]
	ray.collision_mask=1
	var roof: Dictionary=scene.beast.get_world_3d().direct_space_state.intersect_ray(ray)
	if roof.is_empty() or Vector3(roof["normal"]).y<.75: return {}
	return roof

func activate(kind: String) -> bool:
	last_error=""
	if kind==mode: return true
	if scene.game_over or scene.evolving or scene.choice_open or scene.reveal_active: return false
	if kind!="ground" and not can_use(kind):
		last_error="Movement needs its support genes. Heavy lift needs soaring; long axial bodies can only glide."
		return false
	if kind=="ground":
		if mode=="emerging": return true
		if mode=="burrow" and not _safe_surface(scene.beast.global_position):
			last_error="Blocked emergence: move away from buried foundations."
			return false
		if mode=="roof":
			last_error="Walk off the roof edge to descend; walls remain solid."
			return false
		if mode in ["climb","falling"]:
			mode="falling"
			return true
		if mode=="flight" or mode=="glide":
			# Landing is gradual; do not snap through rooftops.
			height_target=0.0
			mode="landing"
			return true
		if mode=="burrow":
			mode="emerging"
			return true
		_end_mode()
		return true
	if kind=="burrow":
		if mode!="ground" or not _safe_surface(scene.beast.global_position):
			last_error="Diggable, foundation-free ground is required."
			return false
		mode="burrow"
		scene.beast.collision_layer=0
		scene.beast.collision_mask=0
		underground_depth=maxf(3.5,float(scene.genetics.dimensions.get("radius",.7))*2.5)
		scene.beast.global_position.y=-.08
		seismic_distance=0
		ground_marker.visible=true
		return true
	if kind=="flight" or kind=="glide":
		if mode!="ground": return false
		if not _safe_surface(scene.beast.global_position): return false
		mode=kind
		height_target=8.0 if kind=="flight" else 5.0
		return true
	if kind=="climb":
		if mode!="ground": return false
		var wall:=_wall_probe()
		if wall.is_empty() or absf(Vector3(wall["normal"]).y)>.25:
			last_error="Approach a solid wall before climbing."
			return false
		climb_normal=Vector3(wall["normal"])
		var contact: Vector3=wall["position"]+climb_normal*(scene.beast_collision_shape.radius+.03)
		contact.y=scene.beast.position.y
		scene.beast.move_and_collide(contact-scene.beast.position)
		mode="climb"
		return true
	return false
func _end_mode() -> void:
	mode="ground"
	height_target=0
	climb_normal=Vector3.ZERO
	scene.beast.global_position.y=0
	scene.beast.collision_layer=1
	scene.beast.collision_mask=1
	ground_marker.visible=false
	vertical_input=0
	bank=0
	scene.genetics.wing_contact.disabled=true
func cycle() -> void:
	if mode!="ground":
		activate("ground")
		return
	var primary: String=scene.genetics.genome.ordered_families()[0]
	var preferences:=["flight","glide","burrow","climb"]
	if primary in ["mole","worm"]: preferences=["burrow","climb","flight","glide"]
	if primary=="spider": preferences=["climb","burrow","flight","glide"]
	for kind in preferences:
		if can_use(kind) and activate(kind): return
func direction_input(move: Vector3, vertical: float, speed: float, delta: float) -> bool:
	var beast: CharacterBody3D=scene.beast
	scene.genetics.wing_contact.disabled=mode not in ["flight","glide","landing"]
	scene.genetics.wing_contact.rotation.z=bank
	if mode=="ground": return false
	# All modes share finite world bounds; swept collision still owns air travel.
	var next := beast.position+move*speed*delta
	if absf(next.x)>WorldLayout.HALF_WIDTH-10 or next.z<WorldLayout.INLAND+10 or next.z>WorldLayout.shore(next.x)-3:
		move=Vector3.ZERO
	if mode=="emerging":
		if not _safe_surface(beast.position):
			mode="burrow";last_error="Emergence blocked by a foundation."
			return true
		beast.position.y=move_toward(beast.position.y,0,delta*3.5)
		beast.velocity=Vector3.ZERO
		if beast.position.y>=-.001: _end_mode()
		return true
	if mode=="burrow":
		var initial := beast.position
		var wanted: Vector3=move*speed*delta*.72
		var pieces:=maxi(1,ceili(wanted.length()/1.5))
		for i in range(pieces):
			var surface:=Vector3(beast.global_position.x+wanted.x/float(pieces),0,beast.global_position.z+wanted.z/float(pieces))
			if not _safe_surface(surface): break
			beast.global_position=Vector3(surface.x,move_toward(beast.position.y,-underground_depth,delta*2.5/float(pieces)),surface.z)
		ground_marker.visible=true
		ground_marker.global_position=Vector3(beast.position.x,.08,beast.position.z)
		ground_marker.scale=Vector3.ONE*maxf(1.0,scene.growth_scale*.40)
		# Travel through actual intermediate samples; no teleport and no foundation crossing.
		beast.velocity=(beast.position-initial)/maxf(delta,.001)
		seismic_distance+=Vector2(beast.position.x-initial.x,beast.position.z-initial.z).length()
		if seismic_distance>=12:
			seismic_distance=0
			scene._add_alert(.6)
		return true
	if mode in ["flight","glide","landing"]:
		if mode=="flight":
			var mass := 1.0+.08*int(scene.genetics.genome.ranks.get("physical_growth",0))+.12*int(scene.genetics.genome.ranks.get("armour",0))
			scene.stamina=maxf(0,scene.stamina-delta*9.0*mass)
			if scene.stamina<=0:
				mode="glide";height_target=beast.position.y;last_error="Lift exhausted: gliding to land."
		var facing: Vector3=-beast.global_basis.z
		bank=lerpf(bank,clampf(facing.cross(move).y*.55,-.45,.45),minf(1,delta*5))
		var altitude := beast.global_position.y
		if mode=="flight":
			height_target=clampf(height_target+vertical*delta*13.0,4.0,70.0 if scene.genetics.genome.ranks.has("gene_122") else 45.0)
		if mode=="glide":
			height_target=maxf(0.0,height_target-delta*1.45)
		if mode=="landing": height_target=0
		var lift:=clampf((height_target-altitude)*2.7,-9.0,9.0)
		var horizontal_speed := speed * (1.29 if scene.genetics.genome.ranks.has("gene_122") and mode=="flight" else (1.18 if mode=="flight" else .92))
		var planned := move*horizontal_speed*delta+Vector3(0,lift*delta,0)
		if is_instance_valid(scene.world): scene.world.ensure_region(beast.position+planned,maxf(35,scene.growth_scale*5.0))
		var hit:=beast.move_and_collide(planned)
		if hit!=null:
			if mode in ["landing","glide"] and hit.get_normal().y>.75 and beast.position.y>1.0:
				mode="roof"
			var slide:=hit.get_remainder().slide(hit.get_normal())
			if slide.length_squared()>.001: beast.move_and_collide(slide)
		beast.velocity=planned/maxf(delta,.001)
		if mode=="landing" and beast.global_position.y<=.35:
			beast.global_position.y=0
			_end_mode()
		if mode=="glide" and beast.global_position.y<=.35:
			beast.global_position.y=0
			_end_mode()
		return true
	if mode=="climb":
		var hit:=_wall_probe()
		if hit.is_empty():
			var top: Dictionary=_roof_probe(beast.global_position)
			if not top.is_empty():
				var point: Vector3=top["position"]
				beast.global_position=Vector3(point.x,point.y,point.z)
				mode="roof"
			else:
				mode="falling"
			return true
		var normal:=Vector3(hit["normal"])
		if absf(normal.y)>.35:
			mode="falling"
			return true
		climb_normal=normal
		var sideways:=Vector3.UP.cross(normal).normalized()
		var rise:=clampf(vertical,-1.0,1.0)
		var side:=clampf(move.dot(sideways),-1.0,1.0)
		var motion: Vector3=(Vector3.UP*rise+sideways*side)*speed*.52*delta
		var collision:=beast.move_and_collide(motion)
		if collision!=null:
			var remainder:=collision.get_remainder().slide(collision.get_normal())
			if remainder.length_squared()>.001: beast.move_and_collide(remainder)
		beast.global_position.y=maxf(.0,beast.global_position.y)
		beast.velocity=motion/maxf(.001,delta)
		if beast.global_position.y<=.01 and rise<0: _end_mode()
		return true
	if mode=="roof":
		var proposed: Vector3=beast.global_position+move*speed*delta*.70
		var support: Dictionary=_roof_support(proposed)
		if support.is_empty() or float(Vector3(support["position"]).y)<1.0:
			mode="falling"
		else:
			var motion: Vector3=Vector3(proposed.x-beast.position.x,0,proposed.z-beast.position.z)
			beast.move_and_collide(motion)
			beast.global_position.y=float(Vector3(support["position"]).y)
		beast.velocity=move*speed*.70
		return true
	if mode=="falling":
		var motion: Vector3=move*speed*delta*.35+Vector3.DOWN*9.5*delta
		var hit := beast.move_and_collide(motion)
		if hit!=null and hit.get_normal().y>.75:
			mode="roof" if beast.position.y>1 else "ground"
		beast.velocity=motion/maxf(.001,delta)
		if beast.global_position.y<=.10: _end_mode()
		return true
	return false
func safe_restore(saved_mode: String) -> void:
	# Never reload in unsupported air/burrow/wall state; older worlds remain safe.
	if saved_mode=="ground" or not can_use(saved_mode):
		_end_mode()
		return
	if saved_mode in ["flight","glide"]:
		mode=saved_mode;height_target=maxf(4.0,scene.beast.position.y)
	elif saved_mode=="burrow":
		if not _safe_surface(scene.beast.position):
			_end_mode();return
		underground_depth=maxf(3.5,float(scene.genetics.dimensions.get("radius",.7))*2.5)
		mode="burrow";scene.beast.collision_layer=0;scene.beast.collision_mask=0
		ground_marker.visible=true
	else: _end_mode()
