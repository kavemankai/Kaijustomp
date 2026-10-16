class_name EvolutionShedding
extends Node3D
## Lightweight skin shedding, reveal and world remnants for the beach demo.
## The old form is snapshotted BEFORE applying a mutation. No gameplay aggro,
## damage rules or stamina changes are performed here.

signal reveal_finished

const MAX_SHEDS := 5
const SHED_LIFETIME := 40.0
const SHED_FADE_SECONDS := 7.0
const REVEAL_SECONDS := 3.0
const PALE_SKIN := Color(0.85, 0.84, 0.74)

var current_shell: Node3D
var original_visual: Node3D
var shell_materials: Array[StandardMaterial3D] = []
var original_colours: Array[Color] = []
var cracks: Array[MeshInstance3D] = []
var active_shards: Array[Dictionary] = []
var shed_remnants: Array[Dictionary] = []
var reveal_progress := 0.0
var revealing := false
var shards_spawned := false
var aborting := false
var abort_clock := 0.0
var base_shell_scale := Vector3.ONE


func _ready() -> void:
	# Reveal can progress while gameplay is paused for the mutation choice.
	process_mode = Node.PROCESS_MODE_ALWAYS


func begin_shed(source: Node3D) -> void:
	if is_instance_valid(current_shell):
		current_shell.queue_free()
	current_shell = null
	original_visual = source
	revealing = false
	aborting = false
	reveal_progress = 0.0
	shards_spawned = false
	active_shards.clear()
	shell_materials.clear()
	original_colours.clear()
	cracks.clear()

	# duplicate() retains the complete prior geometry and mutation details.
	# Materials are overridden on the copy only, so the live creature stays intact.
	current_shell = source.duplicate() as Node3D
	add_child(current_shell)
	current_shell.global_transform = source.global_transform
	base_shell_scale = current_shell.scale
	var renderers: Array[MeshInstance3D] = []
	_collect_renderers(current_shell, renderers)
	for renderer in renderers:
		var old_colour := Color(0.25, 0.40, 0.24)
		var source_mat := renderer.get_active_material(0)
		if source_mat is BaseMaterial3D:
			old_colour = source_mat.albedo_color
		var shell_mat := StandardMaterial3D.new()
		shell_mat.albedo_color = old_colour
		shell_mat.roughness = 1.0
		shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shell_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		renderer.material_override = shell_mat
		shell_materials.append(shell_mat)
		original_colours.append(old_colour)
	_add_cracks()
	original_visual.visible = false


func _collect_renderers(node: Node, renderers: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		renderers.append(node)
	for child in node.get_children():
		_collect_renderers(child, renderers)


func _add_cracks() -> void:
	# Cheap visible fracture marks along the old back and flanks.
	for i in range(11):
		var mark := MeshInstance3D.new()
		var chip := BoxMesh.new()
		chip.size = Vector3(0.045, 0.05, 0.25 + float(i % 3) * 0.07)
		var ink := StandardMaterial3D.new()
		ink.albedo_color = Color(0.33, 0.29, 0.24)
		chip.material = ink
		mark.mesh = chip
		if i < 7:
			mark.position = Vector3(-0.63 + float(i % 3) * 0.63, 1.70, -1.02 + float(i / 3) * 0.58)
		else:
			mark.position = Vector3(0.86 if i % 2 == 0 else -0.86, 1.14, -0.90 + float(i - 7) * 0.57)
		mark.rotation.y = float(i % 4) * 0.54
		mark.visible = false
		current_shell.add_child(mark)
		cracks.append(mark)


func update_shed_progress(progress: float) -> void:
	if not is_instance_valid(current_shell) or revealing:
		return
	var portion := clampf(progress, 0.0, 1.0)
	for i in range(shell_materials.size()):
		shell_materials[i].albedo_color = original_colours[i].lerp(PALE_SKIN, portion * 0.94)
	var count := int(floorf(maxf(0.0, portion - 0.25) / 0.75 * float(cracks.size())))
	for i in range(cracks.size()):
		cracks[i].visible = i < count
	current_shell.rotation.z = sin(portion * 55.0) * 0.013 * portion
	current_shell.position.y = -0.10 * portion


func abort_shed() -> void:
	# Short darkening/collapse effect marks a failed evolution. No shed is
	# retained, and existing mutations/size are unaffected.
	revealing = false
	aborting = is_instance_valid(current_shell)
	abort_clock = 0.42
	if is_instance_valid(original_visual):
		original_visual.visible = true
	for mark in cracks:
		mark.visible = false


func start_reveal() -> void:
	if not is_instance_valid(current_shell) or not is_instance_valid(original_visual):
		return
	revealing = true
	reveal_progress = 0.0
	shards_spawned = false
	for mark in cracks:
		mark.visible = true
	original_visual.visible = false


func accelerate_reveal() -> void:
	if revealing:
		reveal_progress = minf(1.0, reveal_progress + 0.16)


func _process(delta: float) -> void:
	if revealing:
		reveal_progress = minf(1.0, reveal_progress + delta / REVEAL_SECONDS)
		_animate_reveal(delta)
		if reveal_progress >= 1.0:
			_complete_reveal()
	elif aborting:
		abort_clock = maxf(0.0, abort_clock - delta)
		var fade := abort_clock / 0.42
		if is_instance_valid(current_shell):
			current_shell.scale = base_shell_scale * Vector3(1.0, fade, 1.0)
			for material in shell_materials:
				var colour := PALE_SKIN.darkened(0.63)
				colour.a = fade * 0.85
				material.albedo_color = colour
		if abort_clock <= 0.0:
			aborting = false
			if is_instance_valid(current_shell):
				current_shell.queue_free()
			current_shell = null
			shell_materials.clear()
			original_colours.clear()
			cracks.clear()
			active_shards.clear()
	if not get_tree().paused:
		_age_remnants(delta)


func _animate_reveal(delta: float) -> void:
	if not shards_spawned and reveal_progress >= 0.12:
		shards_spawned = true
		_spawn_shards()
		original_visual.visible = true
	var p := reveal_progress
	for i in range(shell_materials.size()):
		var new_col := original_colours[i].lerp(PALE_SKIN, 0.96)
		new_col.a = maxf(0.62, 1.0 - p * 0.38)
		shell_materials[i].albedo_color = new_col
	if is_instance_valid(current_shell):
		current_shell.scale = base_shell_scale * Vector3(1.0 + p * 0.08, 1.0 - p * 0.68, 1.0 + p * 0.06)
		current_shell.position.y = -0.10 - p * 0.09
		current_shell.rotation.z = sin(p * 38.0) * (1.0 - p) * 0.06
	for i in range(active_shards.size()):
		var shard_data: Dictionary = active_shards[i]
		var node: Node3D = shard_data["node"]
		var velocity: Vector3 = shard_data["velocity"]
		velocity.y -= 11.0 * delta
		node.position += velocity * delta
		node.position.y = maxf(0.10, node.position.y)
		node.rotate_y(delta * float(i % 3 + 1) * 1.5)
		shard_data["velocity"] = velocity
		active_shards[i] = shard_data


func _spawn_shards() -> void:
	# Fragments are parented to the shell and stay with that shed. No rigid
	# bodies or collision shapes; only a handful of simple meshes are needed.
	for i in range(12):
		var chunk := Node3D.new()
		current_shell.add_child(chunk)
		var row := float(i / 4)
		var side := float(i % 4) - 1.5
		chunk.position = Vector3(side * 0.45, 1.25 + row * 0.16, -0.96 + row * 0.90)
		var render := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.18 + float(i % 2) * 0.13, 0.07, 0.40)
		var pale := StandardMaterial3D.new()
		pale.albedo_color = PALE_SKIN
		mesh.material = pale
		render.mesh = mesh
		chunk.add_child(render)
		active_shards.append({
			"node": chunk,
			"velocity": Vector3(side * 1.4, 1.8 + float(i % 4) * 0.35, (row - 1.0) * 1.2)
		})


func _complete_reveal() -> void:
	revealing = false
	if is_instance_valid(original_visual):
		original_visual.visible = true
	if is_instance_valid(current_shell):
		current_shell.rotation.z = 0.0
		var remnant_materials := _bake_remnant()
		shed_remnants.append({
			"node": current_shell,
			"materials": remnant_materials,
			"age": 0.0
		})
		while shed_remnants.size() > MAX_SHEDS:
			_remove_oldest_shed()
	current_shell = null
	shell_materials.clear()
	original_colours.clear()
	cracks.clear()
	active_shards.clear()
	reveal_finished.emit()


func _bake_remnant() -> Array[StandardMaterial3D]:
	# Once the reveal finishes the skin never articulates again. Keep its full
	# old silhouette/mutations, but bake the many coloured parts into one pale
	# surface. Five retained skins must not cost five complete creature rigs
	# worth of draw calls. Cracks and flying fragments remain separate.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var renderers: Array[MeshInstance3D] = []
	_collect_renderers(current_shell, renderers)
	var shell_inverse := current_shell.global_transform.affine_inverse()
	for renderer in renderers:
		if not shell_materials.has(renderer.material_override):
			continue
		for index in range(renderer.mesh.get_surface_count()):
			surface.append_from(renderer.mesh, index, shell_inverse * renderer.global_transform)
		renderer.queue_free()
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color(PALE_SKIN, 0.62)
	pale.roughness = 1.0
	pale.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pale.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	var baked := MeshInstance3D.new()
	baked.name = "BakedSkin"
	baked.mesh = surface.commit()
	baked.material_override = pale
	current_shell.add_child(baked)
	return [pale]


func _remove_oldest_shed() -> void:
	var old: Dictionary = shed_remnants.pop_front()
	var root: Node3D = old["node"]
	if is_instance_valid(root):
		root.queue_free()


func _age_remnants(delta: float) -> void:
	for i in range(shed_remnants.size() - 1, -1, -1):
		var record: Dictionary = shed_remnants[i]
		record["age"] = float(record["age"]) + delta
		var age: float = record["age"]
		var fade := clampf((SHED_LIFETIME - age) / SHED_FADE_SECONDS, 0.0, 1.0)
		if age >= SHED_LIFETIME:
			var body: Node3D = record["node"]
			if is_instance_valid(body):
				body.queue_free()
			shed_remnants.remove_at(i)
			continue
		if fade < 1.0:
			for material in record["materials"]:
				var mat: StandardMaterial3D = material
				var colour := mat.albedo_color
				colour.a = minf(colour.a, fade * 0.62)
				mat.albedo_color = colour
		shed_remnants[i] = record
