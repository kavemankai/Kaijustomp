class_name AnatomyPortrait
extends RefCounted
## Deterministic live-geometry anterior preview. Exists only while the card does.
static func attach(card: Button, genome: GenomeState) -> void:
	var view := SubViewport.new()
	view.name="AnatomyForecast"
	view.size=Vector2i(128,144)
	view.own_world_3d=true
	view.transparent_bg=true
	view.render_target_update_mode=SubViewport.UPDATE_ONCE
	view.process_mode=Node.PROCESS_MODE_ALWAYS
	card.add_child(view)
	var stage := Node3D.new();view.add_child(stage)
	var model := CreatureMorphology.new();stage.add_child(model)
	var generic := {}
	for key in GeneRegistry.LEGACY: generic[key]=int(genome.ranks.get(key,0))
	model.configure(genome,generic)
	model.animate(0,false)
	var environment := WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("cbdde0")
	environment.environment.ambient_light_energy=.7
	stage.add_child(environment)
	var light := DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-35,0);stage.add_child(light)
	var camera := Camera3D.new();camera.position=Vector3(3.8,3.5,-5.3);stage.add_child(camera);camera.basis=Basis.looking_at((Vector3(0,1,0)-camera.position).normalized());camera.fov=40
	card.icon=view.get_texture()
	card.expand_icon=true
	card.add_theme_constant_override("icon_max_width",84)

