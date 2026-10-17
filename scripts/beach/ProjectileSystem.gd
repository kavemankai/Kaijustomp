class_name ProjectileSystem
extends Node3D
## Owns tracer visuals, capped lifetime records and swept collision queries.
## BeachDemo explicitly ticks this system under the gameplay pause gate.
signal target_hit(damage: float)
const LIMIT := 72
var shots: Array[Dictionary] = []
var target: CollisionObject3D
var tracer_meshes: Array[BoxMesh] = []

func _ready() -> void:
	# Geometry/material are identical for every shot of each type.
	for heavy in [false, true]:
		var streak := BoxMesh.new()
		streak.size = Vector3(0.18, 0.18, 1.0) if heavy else Vector3(0.12, 0.12, 0.75)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.30, 0.12) if heavy else Color(1.0, 0.90, 0.25)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		streak.material = mat
		tracer_meshes.append(streak)

func spawn(origin: Vector3, direction: Vector3, heavy: bool) -> void:
	if shots.size() >= LIMIT:
		var expired: Dictionary = shots.pop_front()
		expired["node"].queue_free()
	var travel := direction.normalized()
	var tracer := Node3D.new()
	add_child(tracer)
	tracer.global_position = origin
	tracer.look_at(origin + travel, Vector3.UP)
	var visual := MeshInstance3D.new()
	visual.mesh = tracer_meshes[int(heavy)]
	visual.position.z = 0.40
	tracer.add_child(visual)
	shots.append({"node": tracer, "velocity": travel * (43.0 if heavy else 36.0),
		"damage": 16.0 if heavy else 10.0, "lifetime": 1.8})

func advance(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		var visual: Node3D = shot["node"]
		var start := visual.global_position
		var destination := start + Vector3(shot["velocity"]) * delta
		var query := PhysicsRayQueryParameters3D.create(start, destination, 1)
		var result := get_world_3d().direct_space_state.intersect_ray(query)
		shot["lifetime"] = float(shot["lifetime"]) - delta
		if not result.is_empty():
			visual.global_position = result["position"]
			if result["collider"] == target:
				target_hit.emit(float(shot["damage"]))
			visual.queue_free()
			shots.remove_at(i)
		elif shot["lifetime"] <= 0.0:
			visual.queue_free()
			shots.remove_at(i)
		else:
			visual.global_position = destination
			shots[i] = shot
