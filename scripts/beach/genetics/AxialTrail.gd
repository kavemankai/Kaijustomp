class_name AxialTrail
extends Node3D
## Nokia-Snake readable continuous trail: the head owns movement.
## Path history is arc-length sampled and bounded; rear segments never teleport to head.
var owner_scene: Node3D
var family := "snake"
var total_length := 5.0
var radius := .55
var samples: Array[Vector3] = []
var rendered: Array[MeshInstance3D] = []
var live := false
var source_origin := Vector3.ZERO
var source_heading := Vector3(0,0,1)
var spacing := 1.5
var segment_mesh: SphereMesh
var shared_material: StandardMaterial3D
func setup(scene: Node3D) -> void:
	owner_scene = scene
	name = "AxialTrail"
	segment_mesh = SphereMesh.new()
	segment_mesh.radius = 1.0
	segment_mesh.height = 2.0
	segment_mesh.radial_segments = 10
	segment_mesh.rings = 6
	shared_material = StandardMaterial3D.new()
	shared_material.roughness = .88
	shared_material.albedo_color = Color("a44736")
	visible = false
func configure(profile: Dictionary) -> void:
	var new_family := String(profile["family"])
	if new_family not in ["snake","worm"]:
		live=false;visible=false
		return
	live = true
	visible = true
	family = new_family
	total_length = float(profile["length"])
	radius = float(profile["radius"])
	spacing = maxf(1.15,total_length/float(mini(40,int(profile["segments"]))))
	var tint := Color("a44736") if family == "snake" else Color("bd7e83")
	shared_material.albedo_color = tint
	if samples.is_empty():
		reset(owner_scene.beast.global_position,owner_scene.beast.global_transform.basis.z)
	_rebuild_segments()
	update_pose()
func reset(head: Vector3, rearward: Vector3) -> void:
	samples.clear()
	var toward_tail := rearward.normalized()
	if toward_tail.length_squared()<.01: toward_tail=Vector3(0,0,1)
	for i in range(90):
		samples.append(head + toward_tail*float(i)*1.0)
	source_origin=head
	source_heading=toward_tail
func advance(head: Vector3) -> void:
	if not live: return
	if samples.is_empty(): reset(head,owner_scene.beast.global_transform.basis.z)
	var delta := samples[0].distance_to(head)
	if delta > 0.0001:
		samples.push_front(head)
	# Trim by actual distance, preserving one interpolating endpoint.
	var travelled := 0.0
	for i in range(1,samples.size()):
		travelled += samples[i-1].distance_to(samples[i])
		if travelled > total_length+spacing*2:
			samples.resize(i+1)
			break
	if samples.size()>220: samples.resize(220)
	update_pose()
func point_at(distance: float) -> Vector3:
	if samples.is_empty(): return owner_scene.beast.global_position
	var remaining := distance
	for i in range(1,samples.size()):
		var section := samples[i-1].distance_to(samples[i])
		if remaining <= section and section > .0001: return samples[i-1].lerp(samples[i],remaining/section)
		remaining -= section
	return samples.back()
func _rebuild_segments() -> void:
	var count := clampi(ceili(total_length/spacing),3,40)
	if rendered.size()==count: return
	for old in rendered: old.queue_free()
	rendered.clear()
	for i in range(count):
		var part := MeshInstance3D.new()
		part.mesh=segment_mesh
		part.material_override=shared_material
		part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(part)
		rendered.append(part)
func update_pose() -> void:
	if not live: return
	for i in range(rendered.size()):
		var fraction := (float(i)+.5)/float(rendered.size())
		var at := point_at(fraction*total_length)
		var adjacent := point_at(minf(total_length,(fraction+.025)*total_length))
		var along := adjacent-at
		var part := rendered[i]
		part.global_position=at+Vector3(0,radius*.70,0)
		var thickness := radius*(.65+.35*sin(fraction*PI))
		part.scale=Vector3(thickness,thickness,spacing*.72)
		if along.length_squared()>.001:
			part.global_transform.basis=Basis.looking_at(-along.normalized(),Vector3.UP)*Basis.from_scale(part.scale)
