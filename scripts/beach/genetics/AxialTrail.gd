class_name AxialTrail
extends Node3D
## Fixed-topology skinned tube. 97 arc-length rings, one draw, <=40 query proxies.
## History knots are distance-spaced rather than frame-spaced.
var owner_scene: Node3D
var family := "snake"
var total_length := 5.0
var radius := .55
var samples: Array[Vector3]=[]
var rendered: Array[Vector3]=[]
var contact_areas: Array[Area3D]=[]
var live := false
var source_origin := Vector3.ZERO
var source_heading := Vector3.BACK
var spacing := 1.5
var skin: MeshInstance3D
var material: ShaderMaterial
var mesh_build_count := 0
var sample_spacing := .5
var contact_cursor := 0
var contact_blocked := false
var last_positions := PackedVector3Array()
func setup(scene: Node3D) -> void:
	owner_scene=scene;name="AxialTrail";visible=false
	material=ShaderMaterial.new();material.shader=load("res://scripts/beach/genetics/axial_skin.gdshader")
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(97):
		for j in range(11):
			var a := TAU*j/10.0
			st.set_normal(Vector3(cos(a),sin(a),0));st.add_vertex(Vector3(cos(a),sin(a),float(i)))
	for i in range(96):
		for j in range(10):
			var n := i*11+j
			for k in [n,n+11,n+1,n+1,n+11,n+12]: st.add_index(k)
	skin=MeshInstance3D.new();skin.mesh=st.commit();skin.material_override=material
	skin.custom_aabb=AABB(Vector3(-15000,-100,-15000),Vector3(30000,300,30000))
	skin.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(skin);mesh_build_count+=1
func configure(profile: Dictionary) -> void:
	var next: String=profile["family"]
	var previous := family
	var was_live := live
	if next not in ["snake","worm"]:
		live=false;visible=false
		for a in contact_areas: a.collision_layer=0
		return
	live=true;visible=true;family=next
	total_length=float(profile["length"]);radius=float(profile["radius"])
	spacing=maxf(1.15,total_length/float(mini(40,int(profile["segments"]))))
	material.set_shader_parameter("skin",Color("a44736") if family=="snake" else Color("bd7e83"))
	material.set_shader_parameter("worm",family=="worm")
	material.set_shader_parameter("body_radius",radius)
	material.set_shader_parameter("armour",float(mini(3,int(owner_scene.genetics.genome.ranks.get("armour",0)))))
	if samples.is_empty() or not was_live or previous!=family: reset(owner_scene.beast.global_position,owner_scene.beast.global_transform.basis.z)
	_extend_history()
	_rebuild_segments();update_pose()
func reset(head: Vector3,rearward: Vector3) -> void:
	samples.clear();source_origin=head;source_heading=rearward.normalized()
	if source_heading.length_squared()<.01: source_heading=Vector3.BACK
	for i in range(220): samples.append(head+source_heading*float(i)*sample_spacing)
func _extend_history() -> void:
	if samples.size()<2: return
	var length := 0.0
	for i in range(1,samples.size()): length+=samples[i-1].distance_to(samples[i])
	var direction: Vector3= (samples.back()-samples[samples.size()-2]).normalized()
	if direction.length_squared()<.01: direction=source_heading
	while length<total_length+2 and samples.size()<220:
		samples.append(samples.back()+direction*sample_spacing);length+=sample_spacing
func advance(head: Vector3) -> void:
	if not live: return
	if samples.is_empty(): reset(head,owner_scene.beast.global_transform.basis.z)
	# Slot zero follows the exact head. Knots behind it commit every .5 world units.
	var origin := samples[0]
	var distance := origin.distance_to(head)
	var steps := maxi(1,ceili(distance/.4))
	for i in range(steps):
		var p := origin.lerp(head,float(i+1)/steps)
		if samples.size()>1 and samples[1].distance_to(p)>=sample_spacing:
			samples.push_front(p)
		else: samples[0]=p
		if samples.size()>220: samples.resize(220)
	_extend_history()
	update_pose()
func point_at(distance: float) -> Vector3:
	if samples.is_empty(): return owner_scene.beast.global_position
	var left := maxf(0,distance)
	for i in range(1,samples.size()):
		var length := samples[i-1].distance_to(samples[i])
		if left<=length and length>.00001: return samples[i-1].lerp(samples[i],left/length)
		left-=length
	return samples.back()
func _rebuild_segments() -> void:
	var count := clampi(ceili(total_length/spacing),3,40)
	if contact_areas.size()==count: return
	for a in contact_areas: a.free()
	contact_areas.clear()
	for i in range(count):
		var area := Area3D.new();area.name="BodySection_%02d"%i;area.collision_layer=4;area.collision_mask=0;area.monitoring=false
		var collider := CollisionShape3D.new();collider.shape=SphereShape3D.new();area.add_child(collider);add_child(area);contact_areas.append(area)
func update_pose() -> void:
	if not live: return
	rendered.clear();last_positions.clear()
	var cursor := 1
	var consumed := 0.0
	for i in range(97):
		var wanted := total_length*i/96.0
		while cursor<samples.size()-1 and consumed+samples[cursor-1].distance_to(samples[cursor])<wanted:
			consumed+=samples[cursor-1].distance_to(samples[cursor]);cursor+=1
		var length := maxf(.00001,samples[cursor-1].distance_to(samples[cursor]))
		var p := samples[cursor-1].lerp(samples[cursor],clampf((wanted-consumed)/length,0,1))
		rendered.append(p);last_positions.append(p)
	material.set_shader_parameter("path",last_positions)
	for i in range(contact_areas.size()):
		var f := (float(i)+.5)/contact_areas.size()
		var index := f*96
		var at := rendered[floori(index)].lerp(rendered[mini(96,ceili(index))],fmod(index,1.0))+Vector3.UP*radius*.7
		contact_areas[i].global_position=at
		contact_areas[i].collision_layer=4 if at.y+radius>0 else 0
		var shape: SphereShape3D=contact_areas[i].get_child(0).shape
		shape.radius=radius*lerpf(1,.035,pow(f,2.7))
	# Tight culling bounds follow the complete path, including offscreen tail.
	var bounds := AABB(last_positions[0],Vector3.ONE*.01)
	for p in last_positions: bounds=bounds.expand(p)
	skin.custom_aabb=bounds.grow(radius*2)
func constrain_head_motion() -> bool:
	# The head capsule is wider than the tube. Replaying its exact swept path is
	# the primary wall rule. Newly streamed/changed walls are checked in bounded
	# batches; stop head travel instead of silently dragging through solid cover.
	if not live or owner_scene.genetics.traversal.mode!="ground": return false
	contact_blocked=false
	for step in range(mini(4,contact_areas.size())):
		contact_cursor=(contact_cursor+1)%contact_areas.size()
		var a := contact_areas[contact_cursor]
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape=a.get_child(0).shape;query.transform=a.global_transform;query.collision_mask=1
		query.exclude=[owner_scene.beast.get_rid()]
		var hits := get_world_3d().direct_space_state.intersect_shape(query,4)
		for hit in hits:
			var collider: Node=hit["collider"]
			if collider is StaticBody3D:
				contact_blocked=true
				var index: int=owner_scene._building_for_collider(collider)
				if index>=0: owner_scene._attack_building(index,owner_scene.sprint_active)
	return contact_blocked
func record() -> Dictionary:
	if not live: return {}
	var points: Array=[]
	for p in samples: points.append([p.x,p.y,p.z])
	return {"version":1,"family":family,"points":points}
static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	if data.get("version")!=1 or data.get("family") not in ["snake","worm"]: return false
	if not data.get("points") is Array or data["points"].size()>220: return false
	for p in data["points"]:
		if not p is Array or p.size()!=3: return false
		for v in p:
			if not WorldState._number(v) or absf(float(v))>15000: return false
	return true
func restore(saved: Dictionary) -> void:
	if not live or not valid(saved) or saved.get("family","")!=family or saved.get("points",[]).is_empty(): return
	samples.clear()
	for p in saved["points"]: samples.append(Vector3(float(p[0]),float(p[1]),float(p[2])))
	_extend_history();update_pose()
