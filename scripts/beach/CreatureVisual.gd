class_name CreatureVisual
extends Node3D
## Visual adapter. Gameplay owns the pivots, timings, scale and collision.
## Both authored forms share a 19-bone contract; no root motion is applied.

var forms: Array[Node3D] = []
var skeletons: Array[Skeleton3D] = []
var targets: Dictionary = {}
var visual_root: Node3D
var upright := false

func configure(root: Node3D, chest: Node3D, head: Node3D, jaw: Node3D,
		legs: Array[Node3D], knees: Array[Node3D], paws: Array[Node3D], tails: Array[Node3D]) -> void:
	visual_root = root
	targets = {"Root": root, "Torso": chest, "Head": head, "Jaw": jaw}
	for i in range(4):
		targets["Leg%d" % i] = legs[i]
		targets["Knee%d" % i] = knees[i]
		targets["Paw%d" % i] = paws[i]
	for i in range(3):
		targets["Tail%d" % i] = tails[i]
	for path in ["res://assets/creature/quadruped.glb", "res://assets/creature/upright.glb"]:
		var form: Node3D = load(path).instantiate()
		add_child(form)
		forms.append(form)
		var skeleton := _find_skeleton(form)
		assert(skeleton != null, "Authored creature requires a Skeleton3D")
		skeletons.append(skeleton)
		# StandardMaterial vertex colours are the shared, texture-free palette.
		for render in renderers(form):
			render.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	update_pose(false)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null

func update_pose(is_upright: bool, moving: bool = false, phase: float = 0.0) -> void:
	upright = is_upright
	for i in range(forms.size()):
		forms[i].visible = (i == 1) == upright
		if not forms[i].visible:
			continue
		var skeleton := skeletons[i]
		var inverse := skeleton.global_transform.affine_inverse()
		for bone in range(skeleton.get_bone_count()):
			var key := skeleton.get_bone_name(bone)
			if not targets.has(key):
				continue
			var pivot: Node3D = targets[key]
			var rest := skeleton.get_bone_global_rest(bone)
			var pose := inverse * pivot.global_transform
			pose.basis *= rest.basis
			skeleton.set_bone_global_pose_override(bone, pose, 1.0, true)
		if moving:
			_plant_feet(skeleton, phase)
		skeleton.force_update_all_bone_transforms()
		# Limb upgrades follow the solved skin, not the unsolved gameplay pivots.
		for limb in range(4):
			for family in ["speed","strength"]:
				var key := ("Leg%d" if family == "speed" else "Paw%d") % limb
				var parent: Node3D = targets[key]
				var marks := parent.get_node_or_null("Mutation_"+family) as Node3D
				if marks == null: continue
				var bone := skeleton.find_bone(key)
				var pose := skeleton.get_bone_global_pose(bone)
				pose.basis *= skeleton.get_bone_global_rest(bone).basis.inverse()
				marks.global_transform = skeleton.global_transform * pose

func _plant_feet(skeleton: Skeleton3D, phase: float) -> void:
	# A 2.5 m cycle with 60% planted stance: the foot travels 1.5 m backwards
	# relative to the body, cancelling forward motion. Swing clears the sand.
	for i in range(4):
		if upright and i % 2 == 0:
			continue
		var t := fposmod(phase + (0.0 if i == 0 or i == 3 else PI), TAU) / TAU
		var z := lerpf(-.75,.75,t/.6) if t < .6 else lerpf(.75,-.75,(t-.6)/.4)
		var lift := 0.0 if t < .6 else sin((t-.6)/.4*PI)*.24
		var side := -1.0 if i < 2 else 1.0
		var hip := Vector3(side*.78,1.0,-.87 if i%2 == 0 else .94)
		var ground_target := Vector3(side*.95,.03+lift,hip.z-.19+z) * visual_root.scale.x
		var foot := visual_root.transform.affine_inverse() * ground_target
		var knee := hip.lerp(foot,.54) + Vector3(0,.03,.10)
		for key in ["Leg","Knee","Paw"]:
			var bone := skeleton.find_bone("%s%d"%[key,i])
			var rest := skeleton.get_bone_global_rest(bone)
			var origin := hip if key == "Leg" else (knee if key == "Knee" else foot)
			var endpoint := knee if key == "Leg" else foot
			var angle := atan2(origin.z-endpoint.z,origin.y-endpoint.y) if key != "Paw" else 0.0
			var pose := Transform3D(Basis(Vector3.RIGHT,angle)*rest.basis,origin)
			if key == "Paw":
				pose.basis = visual_root.basis.orthonormalized().inverse()*rest.basis
			skeleton.set_bone_global_pose_override(bone,pose,1.0,true)

func mouth_transform() -> Transform3D:
	return targets["Jaw"].global_transform

static func renderers(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(renderers(child))
	return result

static func posed_mesh(renderer: MeshInstance3D) -> Mesh:
	# CPU snapshot avoids the GPU readback stall of bake_mesh_from_current_skeleton_pose.
	# Also works in headless regression tests. No blend shapes in the asset contract.
	if renderer.skin == null:
		return renderer.mesh
	var skeleton := renderer.get_node_or_null(renderer.skeleton) as Skeleton3D
	if skeleton == null:
		return renderer.mesh
	skeleton.force_update_all_bone_transforms()
	var skin := renderer.skin
	var transforms: Array[Transform3D] = []
	var to_mesh := renderer.global_transform.affine_inverse() * skeleton.global_transform
	for bind in range(skin.get_bind_count()):
		var bone := skin.get_bind_bone(bind)
		if not skin.get_bind_name(bind).is_empty():
			bone = skeleton.find_bone(skin.get_bind_name(bind))
		assert(bone >= 0, "Missing skin bone")
		transforms.append(to_mesh * skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(bind))
	var baked := ArrayMesh.new()
	for surface in range(renderer.mesh.get_surface_count()):
		var arrays := renderer.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var influences := bones.size() / vertices.size()
		for vertex in range(vertices.size()):
			var position := Vector3.ZERO
			var normal := Vector3.ZERO
			for influence in range(influences):
				var index := vertex * influences + influence
				var weight := weights[index]
				if weight <= 0.0:
					continue
				var transform := transforms[bones[index]]
				position += (transform * vertices[vertex]) * weight
				normal += (transform.basis.inverse().transposed() * normals[vertex]) * weight
			vertices[vertex] = position
			normals[vertex] = normal.normalized()
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_BONES] = null
		arrays[Mesh.ARRAY_WEIGHTS] = null
		arrays[Mesh.ARRAY_TANGENT] = null
		baked.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		baked.surface_set_material(surface, renderer.get_active_material(surface))
	return baked

static func snapshot(source: Node3D) -> Node3D:
	var shell := Node3D.new()
	shell.name = "OldFormSnapshot"
	var inverse := source.global_transform.affine_inverse()
	for renderer in renderers(source):
		if not renderer.is_visible_in_tree() or renderer.get_meta("exclude_shed", false):
			continue
		var copy := MeshInstance3D.new()
		copy.name = renderer.name
		copy.mesh = posed_mesh(renderer)
		copy.material_override = renderer.material_override
		shell.add_child(copy)
		copy.transform = inverse * renderer.global_transform
	return shell
