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
var last_error := ""
func setup(game: Node3D) -> void:
	scene=game
	name="CreatureTraversal"
func can_use(kind: String) -> bool:
	if not scene.genetics.enabled: return false
	var g: Dictionary=scene.genetics.genome.ranks
	match kind:
		"flight": return int(g.get("gene_121",0))>0
		"glide": return int(g.get("gene_029",0))>0
		"burrow": return int(g.get("gene_052",0))>0 or int(g.get("gene_119",0))>0
		"climb": return int(g.get("gene_180",0))>0
	return kind=="ground"
func _safe_surface(p: Vector3) -> bool:
	if absf(p.x) > WorldLayout.HALF_WIDTH-10 or p.z<WorldLayout.INLAND+10 or p.z>WorldLayout.shore(p.x)-5: return false
	scene.world.ensure_region(Vector3(p.x,0,p.z),maxf(28,scene.growth_scale*5.0))
	return scene._blocking_building(Vector3(p.x,0,p.z),maxf(1.5,scene.beast_collision_shape.radius))<0
func _wall_probe() -> Dictionary:
	var ahead := -scene.beast.global_transform.basis.z
	var origin := scene.beast.global_position+Vector3(0,1.2,0)
	var ray:=PhysicsRayQueryParameters3D.create(origin,origin+ahead*maxf(4.5,scene.beast_collision_shape.radius+1.5))
	ray.collision_mask=1
	ray.exclude=[scene.beast.get_rid()]
	return scene.beast.get_world_3d().direct_space_state.intersect_ray(ray)
func activate(kind: String) -> bool:
	last_error=""
	if kind==mode: return true
	if scene.game_over or scene.evolving or scene.choice_open or scene.reveal_active: return false
	if kind!="ground" and not can_use(kind):
		last_error="Required movement genes are not equipped."
		return false
	if kind=="ground":
		if mode=="burrow" and not _safe_surface(scene.beast.global_position):
			last_error="Blocked emergence: move away from buried foundations."
			return false
		if mode=="flight" or mode=="glide":
			# Landing is gradual; do not snap through rooftops.
			height_target=0.0
			mode="landing"
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
		scene.beast.global_position.y=-underground_depth
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
func cycle() -> void:
	if mode!="ground":
		activate("ground")
		return
	var primary: String=scene.genetics.genome.ordered_families()[0]
	var preferences:=["flight","burrow","climb"]
	if primary in ["mole","worm"]: preferences=["burrow","climb","flight"]
	if primary=="spider": preferences=["climb","burrow","flight"]
	for kind in preferences:
		if can_use(kind) and activate(kind): return
func direction_input(move: Vector3, vertical: float, speed: float, delta: float) -> bool:
	var beast: CharacterBody3D=scene.beast
	if mode=="ground": return false
	if mode=="burrow":
		var surface:=Vector3(beast.global_position.x+move.x*speed*delta*.72,0,beast.global_position.z+move.z*speed*delta*.72)
		if _safe_surface(surface):
			beast.global_position=Vector3(surface.x,-underground_depth,surface.z)
		# Travel through actual intermediate samples; no teleport and no foundation crossing.
		beast.velocity=move*speed*.72
		return true
	if mode in ["flight","glide","landing"]:
		var altitude := beast.global_position.y
		if mode=="flight":
			height_target=clampf(height_target+vertical*delta*13.0,4.0,45.0)
		if mode=="glide":
			height_target=maxf(0.0,height_target-delta*1.45)
		if mode=="landing": height_target=0
		var lift:=clampf((height_target-altitude)*2.7,-9.0,9.0)
		var horizontal_speed := speed * (1.18 if mode=="flight" else .92)
		var planned := move*horizontal_speed*delta+Vector3(0,lift*delta,0)
		if is_instance_valid(scene.world): scene.world.ensure_region(beast.position+planned,maxf(35,scene.growth_scale*5.0))
		var hit:=beast.move_and_collide(planned)
		if hit!=null:
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
			# Do not float in midair when a wall is destroyed or unloaded.
			_end_mode()
			return true
		var normal:=Vector3(hit["normal"])
		if absf(normal.y)>.35:
			_end_mode()
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
	return false
func safe_restore(saved_mode: String) -> void:
	# Never reload in unsupported air/burrow/wall state; older worlds remain safe.
	if saved_mode=="ground" or not can_use(saved_mode):
		_end_mode()
		return
	if saved_mode=="flight":
		mode="flight";height_target=maxf(4.0,scene.beast.position.y)
	elif saved_mode=="burrow":
		mode="burrow";scene.beast.collision_layer=0;scene.beast.collision_mask=0
	else: _end_mode()
