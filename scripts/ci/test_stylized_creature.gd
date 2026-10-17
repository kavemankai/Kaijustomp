extends SceneTree
## Imported artwork, bounded mutations and visual/gameplay adapter coverage.
func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> bool:
	if not ok:
		printerr("STYLIZED CREATURE TEST FAILED: " + message)
		quit(1)
	return ok

func visible_renderers(node: Node) -> int:
	var total := 0
	for renderer in CreatureVisual.renderers(node):
		if renderer.is_visible_in_tree(): total += 1
	return total

func triangle_count(node: Node) -> int:
	var count := 0
	for renderer in CreatureVisual.renderers(node):
		if not renderer.is_visible_in_tree(): continue
		for surface in range(renderer.mesh.get_surface_count()):
			var arrays := renderer.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			count += (indices.size() if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	return count

func run() -> void:
	# Open plates must face outwards under Godot's clockwise front-face rule.
	var plate_holder := Node3D.new()
	root.add_child(plate_holder)
	StylizedCreatureArt._plate(plate_holder,Vector3.ZERO,Vector3.ONE,Color.WHITE)
	var plate: MeshInstance3D = plate_holder.get_child(0)
	var normals: PackedVector3Array = plate.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for normal in normals:
		if not check(normal.y > 0,"Mutation plate is inside-out and invisible from above"): return
	plate_holder.free()
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	var visual: CreatureVisual = demo.creature_rig["visual"]
	if not check(visual.skeletons.size() == 2 and visual.forms[0].visible and not visual.forms[1].visible,"Two form assets and quadruped default required"): return
	for skeleton in visual.skeletons:
		if not check(skeleton.get_bone_count() == 19,"Unexpected rig contract"): return
	for form in visual.forms:
		var renderer := CreatureVisual.renderers(form)[0]
		if not check(renderer.skin != null and renderer.mesh.get_surface_count() == 1,"Hero must be skinned with one palette surface"): return
	if not check(demo.leg_pivots.size() == 4 and demo.tail_pivots.size() == 3,"Gameplay articulation changed"): return
	if not check(is_equal_approx(demo.beast_collision_shape.radius,1.85) and is_equal_approx(demo.head_collision_shape.radius,.82),"Hatchling collision changed"): return
	for id in ["armour","speed","stamina","jaw","strength","health","regen","cocoon","metamorphosis"]:
		for i in range(3): demo._apply_mutation_visual(id)
	var mature_count := visible_renderers(demo.beast_visual)
	var mature_triangles := triangle_count(demo.beast_visual)
	print("MATURE HERO BUDGET: triangles=%d renderers=%d"%[mature_triangles,mature_count])
	for id in ["armour","speed","stamina","jaw","strength","health","regen","cocoon","metamorphosis"]:
		for i in range(20): demo._apply_mutation_visual(id)
		if not check(demo.mutation_visual_counts[id] == 23,"Appearance cap must not discard purchase history"): return
	if not check(visible_renderers(demo.beast_visual) == mature_count and triangle_count(demo.beast_visual) == mature_triangles,"Mature mutation geometry grew without bound"): return
	if not check(mature_triangles < 13000,"Hero exceeded initial triangle budget"): return
	demo._apply_growth_milestone(22)
	if not check(visual.forms[1].visible and not visual.forms[0].visible,"Upright asset was not selected"): return
	var renderer := CreatureVisual.renderers(visual.forms[1])[0]
	var mesh := CreatureVisual.posed_mesh(renderer)
	if not check(mesh.get_aabb().size.y > 2.5,"Upright skin snapshot lost the raised pose"): return
	var head_bone := visual.skeletons[1].find_bone("Head")
	var pose := visual.skeletons[1].get_bone_global_pose(head_bone)
	var expected: Vector3 = visual.skeletons[1].to_local(demo.head_pivot.global_position)
	if not check(pose.origin.distance_to(expected) < .001,"Art head does not track gameplay head"): return
	var shell := CreatureVisual.snapshot(demo.beast_visual)
	root.add_child(shell)
	if not check(visible_renderers(shell) == mature_count,"Snapshot included hidden form or omitted mutations"): return
	for render in CreatureVisual.renderers(shell):
		if not check(render.skin == null,"Shed still depends on animated skeleton"): return
	shell.free()
	var resting_head_height: float = demo.head_pivot.global_position.y
	var resting_arm: float = demo.leg_pivots[0].rotation.x
	demo.bite_timer = demo.bite_duration * .5
	demo._update_creature_animation(.1,false)
	if not check(demo.head_pivot.global_position.y >= resting_head_height - .5 * demo.growth_scale,"Upright feeding still faceplants instead of lifting prey"): return
	if not check(demo.leg_pivots[0].rotation.x > resting_arm + .1 and demo.creature_rig["lower_limbs"][0].rotation.x < -.4, "Upright forelimb does not reach and bend to grab"): return
	var actual: Vector3 = demo.beast.to_local(demo.head_pivot.to_global(Vector3(0,-.16,-1.11)))
	if not check(actual.distance_to(demo.head_collision_node.position) < .001,"Bite collider trails visual pose"): return
	# During planted stance, world-space feet must cancel forward body motion.
	var walker = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(walker)
	walker.set_physics_process(false)
	var walk_visual: CreatureVisual = walker.creature_rig["visual"]
	var walk_skeleton: Skeleton3D = walk_visual.skeletons[0]
	walk_visual.update_pose(false,true,.2)
	var paw_index := walk_skeleton.find_bone("Paw0")
	var first := walk_skeleton.to_global(walk_skeleton.get_bone_global_pose(paw_index).origin)
	walker.beast.position.z -= .1
	walk_visual.update_pose(false,true,.2+.1*TAU/2.5)
	var second := walk_skeleton.to_global(walk_skeleton.get_bone_global_pose(paw_index).origin)
	if not check(first.distance_to(second) < .002,"Planted foot slides during straight travel"): return
	walker._apply_growth_milestone(46)
	walker.beast_visual.position.y = .1
	walker.beast_visual.rotation.z = .04
	walk_visual.update_pose(true,true,.2)
	walk_skeleton = walk_visual.skeletons[1]
	var hind := walk_skeleton.get_bone_global_pose(walk_skeleton.find_bone("Paw1"))
	var world_foot := walk_skeleton.to_global(hind.origin)
	if not check(absf(world_foot.y-.03*walker.growth_scale)<.002,"Large planted foot sinks during body bob"): return
	walker.free()
	print("STYLIZED CREATURE TEST PASSED: two imported rigs, bounded mutations, history, triangle budget, posed snapshots and head contract")
	quit()
