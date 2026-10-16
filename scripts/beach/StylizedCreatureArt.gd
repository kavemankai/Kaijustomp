class_name StylizedCreatureArt
extends RefCounted
## Kaijustomp's intentional, coloured-shape hero. This is *art*, not physics:
## never adjust BeachDemo's CharacterBody3D, collider sizes, controls or camera.
## Local -Z is forward. All adornments are parented to animated pivots.

const DEEP := Color("#173E48")
const SHADOW := Color("#17666B")
const BODY := Color("#238B83")
const LIGHT := Color("#59BEA5")
const BELLY := Color("#F2D69D")
const RIDGE := Color("#ED8457")
const RIDGE_LIGHT := Color("#FFB16F")
const MOUTH := Color("#472B49")
const TONGUE := Color("#E66B83")
const EYE_GOLD := Color("#FFCD65")
const WHITE := Color("#FFF7D8")
static var _materials: Dictionary = {}
static var mutation_palette: StandardMaterial3D

static func _mat(tint: Color, sheen: float = 0.72) -> StandardMaterial3D:
	var key := "%s/%.3f" % [tint.to_html(), sheen]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = sheen
	material.metallic = 0.0
	_materials[key] = material
	return material

static func _oval(parent: Node3D, name: String, pos: Vector3, radii: Vector3, tint: Color, facets: int = 16) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = facets
	mesh.rings = 8
	var part := MeshInstance3D.new()
	part.name = name
	part.mesh = mesh
	part.position = pos
	part.scale = radii
	part.material_override = _mat(tint)
	parent.add_child(part)
	return part

static func _cone(parent: Node3D, name: String, pos: Vector3, height: float, width: float, tint: Color, tilt: float = 0.0, sides: int = 5) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.bottom_radius = width
	mesh.top_radius = 0.0
	mesh.radial_segments = sides
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.position = pos
	node.rotation.x = tilt
	node.material_override = _mat(tint)
	parent.add_child(node)
	return node

static func _collar(parent: Node3D, name: String, pos: Vector3, radius_top: float, radius_bottom: float, length: float, tint: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.height = length
	mesh.top_radius = radius_top
	mesh.bottom_radius = radius_bottom
	mesh.radial_segments = 10
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	node.position = pos
	node.rotation.x = PI * 0.5
	node.material_override = _mat(tint)
	parent.add_child(node)
	return node

static func build(body: Node3D, head: Node3D, jaw: Node3D, legs: Array[Node3D], tails: Array[Node3D]) -> Dictionary:
	var chest := Node3D.new()
	chest.name = "BreathingTorso"
	body.add_child(chest)
	var knees: Array[Node3D] = []
	var paws: Array[Node3D] = []
	for i in range(legs.size()):
		var side := -1.0 if i < 2 else 1.0
		var knee := Node3D.new()
		knee.name = "Knee"
		legs[i].add_child(knee)
		knee.position = Vector3(side * 0.10, -0.55, 0)
		var paw := Node3D.new()
		paw.name = "Ankle"
		knee.add_child(paw)
		paw.position = Vector3(side * 0.07, -0.42, -0.19)
		knees.append(knee)
		paws.append(paw)
	var visual := CreatureVisual.new()
	visual.name = "CreatureVisual"
	body.add_child(visual)
	visual.configure(body, chest, head, jaw, legs, knees, paws, tails)
	return {"breathing": chest, "lower_limbs": knees, "paws": paws, "visual": visual}

static func _family(parent: Node3D, id: String) -> Node3D:
	var key := "Mutation_" + id
	var old := parent.get_node_or_null(key)
	if old != null:
		parent.remove_child(old)
		old.queue_free()
	var group := Node3D.new()
	group.name = key
	parent.add_child(group)
	return group

static func _plate(parent: Node3D, pos: Vector3, size: Vector3, tint: Color) -> void:
	# A bevelled shield wedge, not a spherical bump. Shared palette material.
	var points := PackedVector3Array([
		Vector3(-.5,0,-.35), Vector3(.5,0,-.35), Vector3(.42,0,.28),
		Vector3(0,0,.65), Vector3(-.42,0,.28), Vector3(0,.34,-.03)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(5):
		for index in [i, (i + 1) % 5, 5]:
			surface.add_vertex(points[index] * size)
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	node.material_override = _mat(tint)
	node.position = pos
	parent.add_child(node)

static func add_mutation(body: Node3D, head: Node3D, legs: Array[Node3D], id: String, stage: int) -> void:
	# stage is zero-based purchase history. Appearance saturates; stats do not.
	if stage >= 3:
		return
	var tier := stage + 1
	var bulk := 1.0 + 0.16 * float(stage)
	var group := _family(head if id == "jaw" else body, id)
	group.set_meta("tier", tier)
	match id:
		"armour":
			for side in [-1.0, 1.0]:
				for i in range(3):
					_plate(group, Vector3(side * .52, 1.51, -.72 + i * .57), Vector3(.43 * bulk, .34 * bulk, .57), SHADOW.lightened(.10))
		"speed":
			for limb in legs:
				var marks := _family(limb, id)
				_plate(marks, Vector3(0, -.24, -.25), Vector3(.24, .32 * bulk, .42), RIDGE_LIGHT)
				_batch_family(marks)
		"stamina":
			for side in [-1.0, 1.0]:
				for i in range(tier + 1):
					var mark := _oval(group, "Gill", Vector3(side * .80, 1.04, -.20 + i * .21), Vector3(.055, .20, .065), DEEP, 8)
					mark.rotation.x = -.35
		"jaw":
			for side in [-1.0, 1.0]:
				_plate(group, Vector3(side * .64, -.02, -.55), Vector3(.32 * bulk, .48, .70 * bulk), RIDGE_LIGHT)
		"strength":
			for index in [0, 2]:
				var marks := _family(legs[index].get_node("Knee/Ankle"), id)
				for claw in range(3):
					_cone(marks, "Talons", Vector3(float(claw - 1) * .19, .04, -.41), .32 * bulk, .07, BELLY, -PI / 2, 6)
				_batch_family(marks)
		"health":
			for side in [-1.0, 1.0]:
				_oval(group, "ChestContour", Vector3(side * .65, 1.05, -.68), Vector3(.17 * bulk, .28, .44), BODY, 12)
		"regen":
			for side in [-1.0, 1.0]:
				for i in range(tier):
					_plate(group, Vector3(side * .70, 1.30, .55 + i * .19), Vector3(.18, .40, .24), LIGHT)
		"cocoon":
			# Overlapping back shields communicate stronger shedding protection.
			for side in [-1.0, 1.0]:
				for i in range(2 + tier):
					_plate(group, Vector3(side * .39, 1.76, -.88 + float(i) * .43), Vector3(.49 * bulk, .28, .46), BELLY)
		"metamorphosis":
			# Secondary ridge fins signal an accelerated transformation cycle.
			for side in [-1.0, 1.0]:
				for i in range(tier + 1):
					_plate(group, Vector3(side * .28, 1.90, -.95 + float(i) * .47), Vector3(.27 * bulk, .40, .34), RIDGE_LIGHT)
	if group.get_child_count() > 0:
		_batch_family(group)

static func _batch_family(group: Node3D) -> void:
	if mutation_palette == null:
		mutation_palette = StandardMaterial3D.new()
		mutation_palette.vertex_color_use_as_albedo = true
		mutation_palette.roughness = .72
	var render := CoastalArt.merge(group,"MutationSurface")
	render.material_override = mutation_palette
