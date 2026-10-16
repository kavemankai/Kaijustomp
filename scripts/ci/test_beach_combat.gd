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
	await physics_frame
	if demo.buildings.size() < 6:
		_fail("Beach kiosk, shed and original buildings must all exist")
		return
	for b in demo.buildings:
		if int(b["base_occupants"]) < 1 or int(b["hidden"]) < 1:
			_fail("Every building must begin with civilians inside")
			return
		if not b["collider"] is StaticBody3D:
			_fail("Every intact building needs a StaticBody3D collider")
			return
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
	# First strength tier takes three hits to break a kiosk and releases occupants.
	var baseline: int = demo.civilians.size()
	var occupants: int = demo.buildings[0]["hidden"]
	for i in range(3):
		demo._damage_building(0, 1)
	if not demo.buildings[0]["destroyed"]:
		_fail("Three hits did not demolish the weak kiosk")
		return
	if demo.civilians.size() != baseline + occupants:
		_fail("Collapsing structure did not release all its occupants")
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
	print("DESTRUCTION TEST PASSED: swept collision, occupants, collapse, real tracers and cover")
	quit(0)
