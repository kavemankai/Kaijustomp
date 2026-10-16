extends SceneTree
## Headless creature art regression: new anatomical parts must be visible,
## original four-leg animation and hit shapes must still work.

func _count_renderers(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_renderers(child)
	return count

func _count_boxes(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.mesh is BoxMesh:
		count += 1
	for child in node.get_children():
		count += _count_boxes(child)
	return count

func _fail(message: String) -> void:
	printerr("CREATURE TEST FAILED: " + message)
	paused = false
	quit(1)

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var scene: PackedScene = load("res://scenes/BeachDemo.tscn")
	if scene == null:
		_fail("Scene missing")
		return
	var demo: Variant = scene.instantiate()
	root.add_child(demo)
	await physics_frame
	if demo.leg_pivots.size() != 4 or demo.tail_pivots.size() != 3:
		_fail("Creature joints are no longer compatible with tested locomotion")
		return
	if _count_renderers(demo.beast_visual) < 45:
		_fail("Expected articulated anatomical geometry was not constructed")
		return
	if _count_boxes(demo.beast_visual) != 0:
		_fail("Creature still contains placeholder box meshes")
		return
	if not (demo.head_collision_node is CollisionShape3D):
		_fail("Creature collision must remain independent of render meshes")
		return
	if not (demo.creature_audio is CreatureAudio):
		_fail("Creature Foley node is missing")
		return
	if demo.creature_audio.players.size() != 3 or demo.creature_audio.sounds.size() != 4:
		_fail("Foley synthesis or playback pool was not initialized")
		return
	var old_parts := _count_renderers(demo.beast_visual)
	demo._apply_mutation_visual("armour")
	demo._apply_mutation_visual("jaw")
	demo._apply_mutation_visual("strength")
	if _count_renderers(demo.beast_visual) <= old_parts:
		_fail("Visual mutations must add to the existing anatomy")
		return
	demo._update_creature_animation(0.016, true)
	if demo.head_collision_shape.radius <= 0.0 or demo.beast_collision_shape.radius <= 0.0:
		_fail("Creature collider sizes must remain valid")
		return
	print("CREATURE TEST PASSED: anatomical art, limb pivots, growth geometry, collision and audio")
	quit(0)
