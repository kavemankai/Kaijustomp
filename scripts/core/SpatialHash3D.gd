class_name SpatialHash3D
extends RefCounted

var cell_size: float
var inverse_cell_size: float
var grid: Dictionary = {}

func _init(p_cell_size: float = 3.0) -> void:
	cell_size = p_cell_size
	inverse_cell_size = 1.0 / p_cell_size

func clear() -> void:
	grid.clear()

func insert_entity(entity_id: int, pos: Vector3) -> void:
	var cx: int = int(floor(pos.x * inverse_cell_size))
	var cz: int = int(floor(pos.z * inverse_cell_size))
	var key: int = (cx * 73856093) ^ (cz * 19349663)
	if not grid.has(key):
		grid[key] = PackedInt32Array()
	grid[key].append(entity_id)

func query_radius(pos: Vector3, radius: float) -> PackedInt32Array:
	var results := PackedInt32Array()
	var min_cx: int = int(floor((pos.x - radius) * inverse_cell_size))
	var max_cx: int = int(floor((pos.x + radius) * inverse_cell_size))
	var min_cz: int = int(floor((pos.z - radius) * inverse_cell_size))
	var max_cz: int = int(floor((pos.z + radius) * inverse_cell_size))

	for cx in range(min_cx, max_cx + 1):
		for cz in range(min_cz, max_cz + 1):
			var key: int = (cx * 73856093) ^ (cz * 19349663)
			if grid.has(key):
				results.append_array(grid[key])
	return results
