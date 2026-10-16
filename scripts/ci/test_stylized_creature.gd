extends SceneTree
## Validate the mobile creature's composition while preserving the approved
## gameplay, bite/head collider, locomotion and cumulative mutation visual path.

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	printerr("STYLIZED CREATURE TEST FAILED: " + reason)
	paused = false
	quit(1)

func _count_renderers(node: Node) -> int:
	var total := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		total += _count_renderers(child)
	return total

func _count_boxes(node: Node) -> int:
	var total := 0
	if node is MeshInstance3D and node.mesh is BoxMesh:
		total += 1
	for child in node.get_children():
		total += _count_boxes(child)
	return total

func _name_present(node: Node, target: String) -> bool:
	if node.name == target:
		return true
	for child in node.get_children():
		if _name_present(child, target):
			return true
	return false

func _run() -> void:
	var packed: PackedScene = load("res://scenes/BeachDemo.tscn")
	if packed == null:
		_fail("Failed to load BeachDemo")
		return
	var demo: Variant = packed.instantiate()
	root.add_child(demo)
	await physics_frame
	if demo.leg_pivots.size() != 4 or demo.tail_pivots.size() != 3:
		_fail("Original animation joints have changed")
		return
	if demo.beast_collision_shape.radius < 1.8 or demo.head_collision_shape.radius < 0.8:
		_fail("Approved collision shapes were modified")
		return
	if _count_boxes(demo.beast_visual) != 0:
		_fail("Old raw box placeholder shapes remain on creature")
		return
	if _count_renderers(demo.beast_visual) < 65:
		_fail("The complete stylised creature was not assembled")
		return
	for name in ["MainTealBody", "GoldenUnderbelly", "CoralDorsal0",
		"EyeSocket", "AmberEye", "IvoryClaw0", "CreamJaw", "InsideMouth", "TaperedTailTip"]:
		if not _name_present(demo.beast_visual, name):
			_fail("Expected readable feature missing: " + name)
			return
	var chest: Node3D = demo.creature_rig.get("breathing")
	if not is_instance_valid(chest):
		_fail("Torso idle breathing rig not configured")
		return
	var before: int = _count_renderers(demo.beast_visual)
	for mutation in ["armour", "speed", "stamina", "jaw", "strength", "health", "regen"]:
		demo._apply_mutation_visual(mutation)
	if _count_renderers(demo.beast_visual) <= before + 10:
		_fail("Mutation meshes did not accumulate")
		return
	if demo.mutation_visual_counts.size() != 7:
		_fail("Mutation history visual records not retained")
		return
	# Animations must leave the verified bite hitbox in front of the snout.
	demo.bite_timer = demo.bite_duration * 0.5
	demo._update_creature_animation(0.016, true)
	if demo.head_collision_node.position.z - demo.head_collision_shape.radius > -3.45:
		_fail("Snout collision no longer tracks the bite lunge")
		return
	demo.bite_timer = 0.0
	demo._update_creature_animation(0.016, false)
	if chest.scale.y < 0.95 or chest.scale.y > 1.05:
		_fail("Breathing rig produces extreme scaling")
		return
	print("STYLIZED CREATURE TEST PASSED: silhouette, colour parts, 4 legs, tail, jaw, mutation accumulation and collider")
	quit(0)
