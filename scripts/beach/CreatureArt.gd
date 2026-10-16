class_name CreatureArt
extends RefCounted
## Mobile-first, procedural anatomical art for the BeachDemo creature.
## All geometry is rendered only: existing CharacterBody3D and bite/sprint logic
## remain authoritative. Direction of travel is local -Z.
## No external assets or editor-side modelling required.

const SKIN := Color(0.34, 0.39, 0.27)
const SKIN_DARK := Color(0.23, 0.29, 0.23)
const HIGHLIGHT := Color(0.44, 0.46, 0.32)
const BELLY := Color(0.55, 0.49, 0.35)
const CREASE := Color(0.14, 0.18, 0.14)
const BONE := Color(0.79, 0.74, 0.58)
const EYE := Color(0.76, 0.57, 0.19)

static func _mat(col: Color, rough: float = 0.88) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	mat.metallic = 0.0
	mat.vertex_color_use_as_albedo = true
	return mat

static func _ball(parent: Node3D, pos: Vector3, radius: Vector3, col: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 14
	mesh.rings = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = radius
	node.material_override = _mat(col)
	parent.add_child(node)
	return node

static func _spur(parent: Node3D, pos: Vector3, height: float, width: float, col: Color, tilt: float = 0.0) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = width
	mesh.height = height
	mesh.radial_segments = 7
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation.x = tilt
	node.material_override = _mat(col)
	parent.add_child(node)

static func _loft(parent: Node3D, points: Array[Vector3], widths: Array[Vector2], col: Color, segments: int = 14) -> MeshInstance3D:
	# Ring loft replaces rigid boxes with a continuous tapered reptilian silhouette.
	assert(points.size() == widths.size())
	assert(points.size() >= 2)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var vertex_colours := PackedColorArray()
	var indices := PackedInt32Array()
	for i in range(points.size()):
		var ringsize: Vector2 = widths[i]
		var z: float = float(i) / float(points.size() - 1)
		for j in range(segments + 1):
			var theta: float = TAU * float(j) / float(segments)
			var cx: float = cos(theta)
			var sy: float = sin(theta)
			vertices.append(points[i] + Vector3(cx * ringsize.x, sy * ringsize.y, 0))
			normals.append(Vector3(cx / maxf(0.05, ringsize.x), sy / maxf(0.05, ringsize.y), 0).normalized())
			uvs.append(Vector2(float(j) / float(segments), z))
			# Deterministic tonal variation, no per-frame procedural textures.
			var fleck: float = 0.91 + 0.065 * sin(float(j * 13 + i * 17)) + 0.045 * cos(float(j * 7 - i * 3))
			vertex_colours.append(Color(fleck, fleck, fleck, 1.0))
	for i in range(points.size() - 1):
		for j in range(segments):
			var a: int = i * (segments + 1) + j
			var b: int = a + 1
			var c: int = a + segments + 1
			var d: int = c + 1
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = vertex_colours
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var render := MeshInstance3D.new()
	render.mesh = mesh
	render.material_override = _mat(col)
	parent.add_child(render)
	return render

static func build(body: Node3D, head: Node3D, jaw: Node3D, legs: Array[Node3D], tails: Array[Node3D]) -> void:
	# Monitor-lizard shoulders and a crocodilian, low-slung hindquarter.
	_loft(body,
		[Vector3(0, 1.05, -1.62), Vector3(0, 1.09, -1.25),
		 Vector3(0, 1.12, -0.58), Vector3(0, 1.12, 0.18),
		 Vector3(0, 1.00, 0.92), Vector3(0, 0.94, 1.43)],
		[Vector2(0.27, 0.27), Vector2(0.65, 0.46),
		 Vector2(0.88, 0.58), Vector2(0.85, 0.55),
		 Vector2(0.57, 0.43), Vector2(0.19, 0.17)], SKIN)
	# Loose pale throat and underbelly form a contrasting anatomical plane.
	_loft(body,
		[Vector3(0, 0.91, -1.49), Vector3(0, 0.84, -1.10),
		 Vector3(0, 0.77, -0.40), Vector3(0, 0.74, 0.33),
		 Vector3(0, 0.77, 0.91)],
		[Vector2(0.18, 0.10), Vector2(0.42, 0.14),
		 Vector2(0.59, 0.16), Vector2(0.54, 0.13),
		 Vector2(0.22, 0.08)], BELLY)
	# Small, intermittent keratin scutes rather than oversized fantasy spikes.
	for i in range(9):
		var z: float = -1.11 + float(i) * 0.28
		var y: float = 1.65 - float(maxi(0, i - 5)) * 0.06
		_ball(body, Vector3(0, y, z), Vector3(0.20, 0.08, 0.17), SKIN_DARK)
		if i % 2 == 0:
			_spur(body, Vector3(0, y + 0.13, z + 0.04), 0.24, 0.10, HIGHLIGHT, 0.22)
	# Inset scale patches and flank stripes break the manufactured smoothness.
	for side in [-1.0, 1.0]:
		for i in range(7):
			var z: float = -1.13 + float(i) * 0.34
			var w: float = 0.71 if i < 5 else 0.58
			_ball(body, Vector3(side * w, 1.31, z),
				Vector3(0.095, 0.085, 0.16), SKIN_DARK if i % 2 == 0 else HIGHLIGHT)
	# Jointed limbs keep the exact working four-leg gait pivots.
	for i in range(legs.size()):
		var hip: Node3D = legs[i]
		var sign: float = -1.0 if i < 2 else 1.0
		_ball(hip, Vector3(sign * 0.05, -0.19, 0),
			Vector3(0.34, 0.43, 0.37), SKIN)
		_ball(hip, Vector3(sign * 0.12, -0.56, -0.02),
			Vector3(0.245, 0.39, 0.265), SKIN_DARK)
		_ball(hip, Vector3(sign * 0.17, -0.94, -0.14),
			Vector3(0.30, 0.13, 0.39), SKIN)
		for toe in range(3):
			var x: float = sign * 0.17 + float(toe - 1) * 0.17
			_loft(hip,
				[Vector3(x, -0.96, -0.39), Vector3(x, -0.98, -0.58),
				 Vector3(x, -1.01, -0.75)],
				[Vector2(0.08, 0.07), Vector2(0.060, 0.050),
				 Vector2(0.007, 0.006)], BONE, 7)
	# Wedge-shaped skull, brow, broad snout, separately articulated lower jaw.
	_loft(head,
		[Vector3(0, -0.03, 0.29), Vector3(0, -0.01, -0.06),
		 Vector3(0, 0.01, -0.55), Vector3(0, -0.13, -0.96),
		 Vector3(0, -0.24, -1.41), Vector3(0, -0.26, -1.72)],
		[Vector2(0.40, 0.26), Vector2(0.65, 0.39),
		 Vector2(0.63, 0.37), Vector2(0.54, 0.28),
		 Vector2(0.40, 0.18), Vector2(0.26, 0.13)], HIGHLIGHT)
	_loft(jaw,
		[Vector3(0, -0.04, 0.33), Vector3(0, -0.04, -0.16),
		 Vector3(0, -0.06, -0.61), Vector3(0, -0.035, -0.96)],
		[Vector2(0.34, 0.12), Vector2(0.47, 0.14),
		 Vector2(0.40, 0.13), Vector2(0.21, 0.08)], SKIN_DARK)
	_ball(jaw, Vector3(0, 0.080, -0.40), Vector3(0.34, 0.023, 0.49), CREASE)
	for side in [-1.0, 1.0]:
		# Eyes are inset into a bony ridge with a dark iris, not a glowing orb.
		_ball(head, Vector3(side * 0.55, 0.18, -0.45), Vector3(0.20, 0.17, 0.25), SKIN_DARK)
		_ball(head, Vector3(side * 0.69, 0.16, -0.47), Vector3(0.087, 0.105, 0.12), EYE)
		_ball(head, Vector3(side * 0.752, 0.15, -0.49), Vector3(0.032, 0.075, 0.050), CREASE)
		_ball(head, Vector3(side * 0.28, -0.15, -1.58), Vector3(0.07, 0.045, 0.075), CREASE)
		_ball(head, Vector3(side * 0.48, 0.27, -0.42), Vector3(0.29, 0.13, 0.33), SKIN)
		for t in range(5):
			var z: float = -0.47 - float(t) * 0.20
			_spur(head, Vector3(side * (0.41 - float(t) * 0.025), -0.41, z), 0.14, 0.046, BONE, PI)
			_spur(jaw, Vector3(side * (0.34 - float(t) * 0.018), 0.12, z + 0.20), 0.11, 0.034, BONE)
	# Tail narrows continuously across three existing animated pivots.
	for i in range(tails.size()):
		var seg: Node3D = tails[i]
		var taper: float = 1.0 - float(i) * 0.28
		_loft(seg,
			[Vector3(0, 0.0, -0.14), Vector3(0, -0.015, 0.12),
			 Vector3(0, -0.055, 0.51), Vector3(0, -0.10, 0.94)],
			[Vector2(0.45 * taper, 0.37 * taper),
			 Vector2(0.42 * taper, 0.32 * taper),
			 Vector2(0.31 * taper, 0.23 * taper),
			 Vector2(0.15 * taper, 0.12 * taper)], SKIN_DARK)
		for k in range(3):
			_ball(seg, Vector3(0, 0.31 * taper - float(k) * 0.045, 0.11 + 0.31 * float(k)),
				Vector3(0.15 * taper, 0.085 * taper, 0.15), SKIN)
	# A final tapered tail-tip prevents the stump-like silhouette.
	if not tails.is_empty():
		_loft(tails[tails.size() - 1],
			[Vector3(0, -0.10, 0.85), Vector3(0, -0.16, 1.24),
			 Vector3(0, -0.20, 1.63)],
			[Vector2(0.13, 0.09), Vector2(0.075, 0.05),
			 Vector2(0.004, 0.004)], SKIN_DARK, 10)

static func add_mutation(body: Node3D, head: Node3D, legs: Array[Node3D], id: String, stage: int) -> void:
	# Additive, compact, and stays parented to the correct animated joint.
	var slot: int = stage % 6
	var tier: int = stage / 6
	var height: float = minf(0.16, float(tier) * 0.045)
	var z: float = -1.02 + float(slot) * 0.40
	match id:
		"armour":
			for side in [-1.0, 1.0]:
				_ball(body, Vector3(side * 0.51, 1.60 + height, z),
					Vector3(0.22, 0.095 + height, 0.22), SKIN_DARK)
		"speed":
			for leg in legs:
				_ball(leg, Vector3(0, -0.28 - float(slot % 3) * 0.22, -0.26),
					Vector3(0.11, 0.08, 0.14), HIGHLIGHT)
		"stamina":
			for side in [-1.0, 1.0]:
				_ball(body, Vector3(side * 0.79, 1.14, z),
					Vector3(0.13 + height, 0.21, 0.14), SKIN)
		"jaw":
			for side in [-1.0, 1.0]:
				_ball(head, Vector3(side * 0.51, -0.24, -0.53 - float(slot) * 0.19),
					Vector3(0.11 + height, 0.15, 0.17), BONE)
		"strength":
			for idx in [0, 2]:
				for digit in range(3):
					var x: float = float(digit - 1) * 0.17
					_loft(legs[idx],
						[Vector3(x, -1.01, -0.47), Vector3(x, -1.03, -0.67 - height),
						 Vector3(x, -1.04, -0.86 - height)],
						[Vector2(0.075, 0.055), Vector2(0.05, 0.039),
						 Vector2(0.006, 0.005)], BONE, 7)
		"health":
			for side in [-1.0, 1.0]:
				_ball(body, Vector3(side * 0.82, 1.08, z),
					Vector3(0.14 + height, 0.23, 0.24), SKIN)
		"regen":
			for side in [-1.0, 1.0]:
				_ball(body, Vector3(side * 0.31, 1.69 + height, z),
					Vector3(0.09, 0.06, 0.16), HIGHLIGHT)
