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
	# Shape language: one uninterrupted heavy torso, broad smiling snout,
	# four purposeful legs, coral ridges, graphic markings and a flowing tail.
	# Strong silhouette is favoured over fine detail at portrait-phone scale.
	var breathing := Node3D.new()
	breathing.name = "BreathingTorso"
	body.add_child(breathing)
	_oval(breathing, "MainTealBody", Vector3(0, 1.09, -0.02), Vector3(0.86, 0.55, 1.51), BODY)
	_oval(breathing, "StrongShoulders", Vector3(0, 1.10, -0.88), Vector3(0.79, 0.48, 0.59), BODY)
	_oval(breathing, "TaperedHips", Vector3(0, 1.02, 1.09), Vector3(0.64, 0.44, 0.61), SHADOW)
	_oval(breathing, "GoldenUnderbelly", Vector3(0, 0.72, -0.12), Vector3(0.60, 0.24, 1.23), BELLY)
	_oval(breathing, "SignatureDorsalStripe", Vector3(0, 1.59, -0.10), Vector3(0.33, 0.065, 1.26), DEEP)

	# Coral crest and repeating sea-glass flank bars — readable, not noisy.
	for i in range(7):
		var z := -1.13 + float(i) * 0.36
		var arch := 1.62 if i < 5 else 1.53
		_cone(breathing, "CoralDorsal%d" % i, Vector3(0, arch + 0.15, z),
			0.39 if i < 5 else 0.27, 0.17 if i < 5 else 0.13,
			RIDGE if i % 2 == 0 else RIDGE_LIGHT, 0.09, 5)
	for side in [-1.0, 1.0]:
		for i in range(4):
			var z := -0.97 + float(i) * 0.61
			var scale := 1.0 if i < 3 else 0.84
			_oval(breathing, "GraphicFlankMark", Vector3(side * 0.73 * scale, 1.23, z),
				Vector3(0.13, 0.16, 0.29), LIGHT)
		_oval(breathing, "ShoulderAccent", Vector3(side * 0.70, 1.31, -0.88),
			Vector3(0.16, 0.18, 0.29), RIDGE)

	var lower_limbs: Array[Node3D] = []
	var paws: Array[Node3D] = []
	for i in range(legs.size()):
		var joint: Node3D = legs[i]
		joint.name = "FrontLeg%d" % i if i % 2 == 0 else "BackLeg%d" % i
		var outer := -1.0 if i < 2 else 1.0
		_oval(joint, "MuscularUpperLeg", Vector3(outer * 0.06, -0.30, 0.02),
			Vector3(0.37, 0.45, 0.38), BODY)
		_oval(joint, "Forearm", Vector3(outer * 0.12, -0.67, -0.06),
			Vector3(0.27, 0.36, 0.29), SHADOW)
		_oval(joint, "StrongPaw", Vector3(outer * 0.17, -0.97, -0.19),
			Vector3(0.36, 0.13, 0.39), DEEP)
		_oval(joint, "LegColourBlocking", Vector3(outer * 0.08, -0.35, -0.27),
			Vector3(0.19, 0.22, 0.10), LIGHT)
		for claw in range(3):
			var x := outer * 0.17 + float(claw - 1) * 0.22
			_cone(joint, "IvoryClaw%d" % claw, Vector3(x, -0.98, -0.55),
				0.28, 0.079, WHITE, -PI * 0.5, 6)
		# Articulated knee and ankle, with identical quadruped rest geometry.
		var knee := Node3D.new()
		knee.name = "Knee"
		joint.add_child(knee)
		knee.position = Vector3(outer * 0.10, -0.55, 0.0)
		var ankle := Node3D.new()
		ankle.name = "Ankle"
		knee.add_child(ankle)
		ankle.position = Vector3(outer * 0.07, -0.42, -0.19)
		for child in joint.get_children():
			if child.name == "Forearm":
				child.reparent(knee, true)
			elif child.name == "StrongPaw" or String(child.name).begins_with("IvoryClaw"):
				child.reparent(ankle, true)
		lower_limbs.append(knee)
		paws.append(ankle)

	# Bony brows, large expressive eyes and an intentionally graphic jawline.
	_oval(head, "BroadSkull", Vector3(0, 0.01, -0.30), Vector3(0.71, 0.42, 0.70), BODY)
	_oval(head, "ProudMuzzle", Vector3(0, -0.18, -1.06), Vector3(0.57, 0.30, 0.70), LIGHT)
	_oval(head, "SnoutNose", Vector3(0, -0.20, -1.53), Vector3(0.51, 0.22, 0.25), BODY)
	_oval(head, "DarkSmileLine", Vector3(0, -0.42, -1.09), Vector3(0.52, 0.056, 0.67), DEEP)
	_oval(head, "ForeheadAccent", Vector3(0, 0.38, -0.43), Vector3(0.32, 0.09, 0.40), LIGHT)
	for side in [-1.0, 1.0]:
		_oval(head, "EyeSocket", Vector3(side * 0.56, 0.24, -0.49),
			Vector3(0.24, 0.24, 0.28), DEEP)
		_oval(head, "AmberEye", Vector3(side * 0.72, 0.29, -0.54),
			Vector3(0.105, 0.15, 0.16), EYE_GOLD)
		_oval(head, "NarrowPupil", Vector3(side * 0.810, 0.29, -0.56),
			Vector3(0.034, 0.100, 0.065), DEEP)
		_oval(head, "EyeGlint", Vector3(side * 0.829, 0.35, -0.61),
			Vector3(0.018, 0.031, 0.037), WHITE)
		_oval(head, "EyeBrow", Vector3(side * 0.57, 0.46, -0.50),
			Vector3(0.24, 0.12, 0.26), BODY)
		_oval(head, "Nostril", Vector3(side * 0.31, -0.08, -1.70),
			Vector3(0.085, 0.038, 0.064), DEEP)

	# Actual animated jaw retains BeachDemo's existing parent and bite trigger.
	_oval(jaw, "CreamJaw", Vector3(0, -0.06, -0.24),
		Vector3(0.51, 0.18, 0.63), BELLY)
	_oval(jaw, "InsideMouth", Vector3(0, 0.080, -0.28),
		Vector3(0.40, 0.030, 0.52), MOUTH)
	_oval(jaw, "Tongue", Vector3(0, 0.111, -0.51),
		Vector3(0.20, 0.018, 0.27), TONGUE)
	for side in [-1.0, 1.0]:
		for i in range(3):
			_cone(head, "Tooth", Vector3(side * 0.43, -0.45, -0.90 - 0.22 * float(i)),
				0.15, 0.043, WHITE, PI, 5)

	# A segmented animated tail: light at the root, dark at the tip.
	for i in range(tails.size()):
		var section: Node3D = tails[i]
		section.name = "TailSection%d" % i
		var taper := 1.0 - float(i) * 0.24
		_oval(section, "TaperedTailVolume", Vector3(0, -0.04, 0.41),
			Vector3(0.47 * taper, 0.34 * taper, 0.72), SHADOW if i != 1 else BODY, 14)
		_oval(section, "TailColourBand", Vector3(0, 0.04, 0.50),
			Vector3(0.30 * taper, 0.31 * taper, 0.20), LIGHT, 14)
		_cone(section, "TailScute", Vector3(0, 0.38 * taper, 0.30),
			0.22 * taper, 0.12 * taper, RIDGE, 0.0, 5)
		if i == tails.size() - 1:
			_cone(section, "TaperedTailTip", Vector3(0, -0.13, 1.21),
				0.80, 0.19, DEEP, PI * 0.5, 9)

	return {"breathing": breathing, "lower_limbs": lower_limbs, "paws": paws}

static func add_mutation(body: Node3D, head: Node3D, legs: Array[Node3D], id: String, stage: int) -> void:
	# Every enhancement is an authored palette-consistent extension to the
	# existing character, never a replacement mesh or raw placeholder box.
	var slot := stage % 5
	var tier := stage / 5
	var z := -1.02 + float(slot) * 0.48
	var lift := minf(0.20, float(tier) * 0.05)
	match id:
		"armour":
			for side in [-1.0, 1.0]:
				_oval(body, "ArmouredCoralPlate", Vector3(side * 0.55, 1.61 + lift, z),
					Vector3(0.25, 0.12, 0.24), RIDGE)
				_oval(body, "PlateHighlight", Vector3(side * 0.54, 1.72 + lift, z),
					Vector3(0.17, 0.045, 0.17), RIDGE_LIGHT)
		"speed":
			for limb in legs:
				_oval(limb, "SpeedFlash", Vector3(0, -0.34 - float(slot % 3) * 0.18, -0.32),
					Vector3(0.16, 0.11, 0.14), RIDGE_LIGHT)
		"stamina":
			for side in [-1.0, 1.0]:
				_oval(body, "EnduranceGill", Vector3(side * 0.87, 1.12, z),
					Vector3(0.12, 0.21, 0.19), LIGHT)
		"jaw":
			for side in [-1.0, 1.0]:
				_cone(head, "JawHorn", Vector3(side * 0.55, -0.25, -0.65 - float(slot) * 0.19),
					0.20 + lift, 0.12, RIDGE_LIGHT, PI * 0.5, 5)
		"strength":
			for index in [0, 2]:
				var foreleg: Node3D = legs[index]
				var talons := Node3D.new()
				foreleg.add_child(talons)
				for claw in range(3):
					_cone(talons, "GrowingTalons", Vector3(float(claw - 1) * 0.22, -0.99, -0.69 - lift),
						0.23 + lift, 0.07, BELLY, -PI * 0.5, 5)
				talons.reparent(foreleg.get_node("Knee/Ankle"), true)
		"health":
			for side in [-1.0, 1.0]:
				_oval(body, "MusclePlate", Vector3(side * 0.78, 1.11, z),
					Vector3(0.16 + lift, 0.26, 0.25), BODY)
		"regen":
			for side in [-1.0, 1.0]:
				_oval(body, "RegrowthBud", Vector3(side * 0.28, 1.75 + lift, z),
					Vector3(0.14, 0.09, 0.16), LIGHT)
