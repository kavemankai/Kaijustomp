class_name CoastalEffects
extends Node3D
## Fixed pool: impacts and footsteps never allocate per-frame physics bodies.
const LIMIT := 40
var particles: Array[Dictionary] = []
var clock := 0.0
var rng := RandomNumberGenerator.new()
var dust: StandardMaterial3D
var impact: StandardMaterial3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	rng.seed = 6181
	dust = StandardMaterial3D.new()
	dust.albedo_color = Color("d9caa7")
	dust.roughness = 1
	impact = StandardMaterial3D.new()
	impact.albedo_color = Color("f7d291")
	impact.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := SphereMesh.new()
	mesh.radial_segments = 6
	mesh.rings = 2
	for i in range(LIMIT):
		var render := MeshInstance3D.new()
		render.mesh = mesh
		render.material_override = dust
		render.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		render.hide()
		add_child(render)
		particles.append({"node":render,"life":0.0,"velocity":Vector3.ZERO,"size":1.0})

func burst(at: Vector3, amount: int = 6, scale_factor: float = 1.0, flash: bool = false) -> void:
	var left := amount
	for item in particles:
		if left <= 0: break
		if item["life"] > 0: continue
		var render: MeshInstance3D = item["node"]
		render.position = at
		render.material_override = impact if flash else dust
		item["size"] = rng.randf_range(.13,.30)*minf(2,scale_factor)
		item["life"] = .32 if flash else .55
		item["velocity"] = Vector3(rng.randf_range(-1,1),rng.randf_range(.5,1.5),rng.randf_range(-1,1))*scale_factor
		render.scale = Vector3.ONE*item["size"]
		render.show()
		left -= 1

func _process(delta: float) -> void:
	for item in particles:
		if item["life"] <= 0: continue
		item["life"] -= delta
		var render: MeshInstance3D = item["node"]
		render.position += item["velocity"]*delta
		render.scale = Vector3.ONE*item["size"]*clampf(item["life"]/.25,0,1)
		if item["life"] <= 0: render.hide()
