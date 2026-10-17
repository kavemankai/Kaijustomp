extends SceneTree
## Headless regression for real collision, guaranteed occupants and tracer rounds.

func _initialize() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	printerr("DESTRUCTION TEST FAILED: " + message)
	paused = false
	quit(1)


func _run_test() -> void:
	var packed: PackedScene = load("res://scenes/BeachDemo.tscn")
	if packed == null:
		_fail("Cannot load beach scene")
		return
	var demo: Variant = packed.instantiate()
	root.add_child(demo)
	# This scenario exercises authored assets after explicitly requesting their chunks.
	for authored_index in range(demo.world.authored_count): demo._prepare_authored(authored_index)
	await physics_frame
	if demo.buildings.size() < 6:
		_fail("Beach kiosk, shed and original buildings must all exist")
		return
	for b in demo.buildings.slice(0, demo.world.authored_count):
		if int(b["base_occupants"]) < 1 or int(b["hidden"]) < 1:
			_fail("Every building must begin with civilians inside")
			return
		if not (b["collider"] is StaticBody3D):
			_fail("Every intact building needs a StaticBody3D collider")
			return
	# Native mobile touches should activate sprint even while the stick is held.
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = demo.sprint_button.get_global_rect().get_center()
	demo._input(tap)
	if not demo.sprint_requested:
		_fail("Touching SPRINT did not enable the sprint state")
		return
	demo.touch_vector = Vector2(0, -1)
	var start: Vector3 = demo.beast.global_position
	var stamina_before: float = demo.stamina
	demo._update_movement(0.12)
	var sprint_distance: float = demo.beast.global_position.distance_to(start)
	if not demo.sprint_active or demo.stamina >= stamina_before:
		_fail("Sprint input did not activate and consume stamina")
		return
	demo._input(tap)
	if demo.sprint_requested:
		_fail("Tapping SPRINT again did not turn it off")
		return
	demo.beast.global_position = start
	demo._update_movement(0.12)
	var walk_distance: float = demo.beast.global_position.distance_to(start)
	if walk_distance < 0.01 or sprint_distance <= walk_distance * 1.9:
		_fail("Touch sprint movement must be substantially faster than walking")
		return
	demo.touch_vector = Vector2.ZERO
	# The head collision must cover the idle snout and extended bite pose.
	if not (demo.head_collision_node is CollisionShape3D):
		_fail("Snout collider is missing")
		return
	if demo.head_collision_node.position.z - demo.head_collision_shape.radius > -2.86:
		_fail("Head collision still allows the idle snout to overlap walls")
		return
	demo.bite_timer = demo.bite_duration * 0.5
	demo._update_creature_animation(0.016, false)
	if demo.head_collision_node.position.z - demo.head_collision_shape.radius > -3.45:
		_fail("Biting head collider does not extend with the snout")
		return
	demo.bite_timer = 0.0
	demo._update_creature_animation(0.016, false)
	# A long swept move simulates a sprint frame; it cannot tunnel through the cafe.
	demo.beast.global_position = Vector3(-21, 0, -23)
	await physics_frame
	var impact: KinematicCollision3D = demo.beast.move_and_collide(Vector3(0, 0, -28))
	if impact == null or demo._building_for_collider(impact.get_collider()) < 0:
		_fail("Swept movement did not collide with a solid building")
		return
	if demo.beast.global_position.z < -33.5:
		_fail("Monster entered the cafe footprint")
		return
	# Every building takes chip damage from a baseline creature; the first
	# hit must show a crack, and Strength still accelerates destruction.
	var baseline: int = demo.civilians.size()
	var occupants: int = demo.buildings[0]["hidden"]
	demo.strength = 0
	demo.strike_timer = 0.0
	demo._attack_building(0, false)
	if float(demo.buildings[0]["hits"]) >= 3.0 or int(demo.buildings[0]["crack_stage"]) < 1:
		_fail("Level-zero hit should chip a kiosk and reveal its first crack")
		return
	var heavy_before: float = demo.buildings[4]["hits"]
	demo.strike_timer = 0.0
	demo._attack_building(4, false)
	if float(demo.buildings[4]["hits"]) >= heavy_before or int(demo.buildings[4]["crack_stage"]) < 1:
		_fail("Even an apartment must be damageable at base Strength")
		return
	demo.strength = 1
	for i in range(3):
		demo.strike_timer = 0.0
		demo._attack_building(0, false)
	if not demo.buildings[0]["destroyed"]:
		_fail("Three hits did not demolish the weak kiosk")
		return
	if demo.civilians.size() != baseline + occupants:
		_fail("Collapsing structure did not release all its occupants")
		return
	demo.strength = 2
	demo.strike_timer = 0.0
	demo._attack_building(1, false)
	if not demo.buildings[1]["destroyed"]:
		_fail("A stronger monster must break a wooden shed in one attack")
		return
	# A bullet is simulated over its travel path, and only a real hit damages.
	demo.beast.global_position = Vector3(0, 0, 18)
	await physics_frame
	var hp_before: float = demo.hp
	demo._spawn_projectile(Vector3(0, 1.7, 7), Vector3(0, 0, 1), false)
	if demo.projectiles.size() != 1:
		_fail("Police shot did not create a projectile")
		return
	demo._update_projectiles(0.45)
	if demo.hp >= hp_before or demo.projectiles.size() != 0:
		_fail("Police projectile must deal damage only after physical impact")
		return
	# A shot through an intact cafe must hit the building, not the player.
	demo.beast.global_position = Vector3(-21, 0, -54)
	await physics_frame
	hp_before = demo.hp
	demo._spawn_projectile(Vector3(-21, 1.7, -22), Vector3(0, 0, -1), true)
	demo._update_projectiles(0.8)
	if demo.hp != hp_before or not demo.projectiles.is_empty():
		_fail("An intact building did not absorb the heavy shot")
		return
	print("DESTRUCTION TEST PASSED: touch sprint, head collision, progressive cracks, chip damage, collapse, occupants and cover")
	quit(0)
