class_name CivilianEvacuations
extends RefCounted
## Preserve displaced occupants without allocating an unlimited active crowd.
## One record per collapse; the scene drains available slots before ambient refill.
var pending: Array[Dictionary] = []

func enqueue(center: Vector3, half: Vector2, occupants: int) -> void:
	if occupants > 0:
		pending.append({"center": center, "half": half, "remaining": occupants, "released": 0})

func remaining() -> int:
	var count := 0
	for event in pending:
		count += int(event["remaining"])
	return count

func drain(slots: int, spawn: Callable) -> void:
	while slots > 0 and not pending.is_empty():
		var event: Dictionary = pending[0]
		var half: Vector2 = event["half"]
		var offset := Vector3.ZERO
		match int(event["released"]) % 4:
			0: offset = Vector3(half.x + 2.0, 0, randf_range(-half.y, half.y))
			1: offset = Vector3(-half.x - 2.0, 0, randf_range(-half.y, half.y))
			2: offset = Vector3(randf_range(-half.x, half.x), 0, half.y + 2.0)
			3: offset = Vector3(randf_range(-half.x, half.x), 0, -half.y - 2.0)
		spawn.call(Vector3(event["center"]) + offset)
		event["released"] += 1
		event["remaining"] -= 1
		slots -= 1
		if event["remaining"] <= 0:
			pending.pop_front()

func drain_near(slots: int, center: Vector3, radius: float, spawn: Callable) -> void:
	# Distant displacement stays compact until the player returns to its region.
	for event in pending.duplicate():
		if slots<=0: break
		if Vector3(event["center"]).distance_to(center)>radius: continue
		pending.erase(event)
		pending.push_front(event)
		var count := mini(slots,int(event["remaining"]))
		drain(count,spawn)
		slots-=count
