class_name BeachGenetics
extends Node
## Owns active genetics only. Existing WorldStreaming remains the single save owner.
var scene: Node3D
var enabled := false
var genome := GenomeState.new()
var archive := LineageArchive.new()
var life_id := 1
var focus := ""
var morphology: CreatureMorphology
var hud: GeneticsHUD
var breach_cooldown := 0.0
var sensor: Node3D
var marked_target: Node3D
var last_marker_target := 0
var poison_tick := false
var error_message := ""
var effects: GeneEffects
var trail: AxialTrail
var traversal: CreatureTraversal
var dimensions: Dictionary = {}
var qa_preview := false
var neck_contact: CollisionShape3D
var wing_contact: CollisionShape3D

func setup(owner_scene: Node3D) -> void:
	scene = owner_scene
	effects = GeneEffects.new(self)
	effects.setup_trail()
	morphology = CreatureMorphology.new()
	morphology.name = "GeneticMorphology"
	scene.beast_visual.add_child(morphology)
	neck_contact=CollisionShape3D.new()
	neck_contact.name="AnatomicalNeckCollision"
	neck_contact.shape=CapsuleShape3D.new()
	neck_contact.disabled=true
	scene.beast.add_child(neck_contact)
	wing_contact=CollisionShape3D.new()
	wing_contact.name="FlightWingEnvelope"
	wing_contact.shape=BoxShape3D.new()
	wing_contact.disabled=true
	scene.beast.add_child(wing_contact)
	sensor = Node3D.new()
	sensor.name = "PreySensor"
	sensor.set_meta("exclude_shed",true)
	scene.add_child(sensor)
	var diamond := CoastalArt.box(sensor,Vector3.ZERO,Vector3(.28,.28,.28),Color("f5ca68"))
	diamond.rotation.z = PI*.25
	sensor.hide()
	trail=AxialTrail.new()
	scene.add_child(trail)
	trail.setup(scene)
	traversal=CreatureTraversal.new()
	add_child(traversal)
	traversal.setup(scene)
	hud = GeneticsHUD.new()
	hud.model = self
	scene.ui_layer.add_child(hud)

func rank(family: String) -> int:
	return int(genome.ranks.get(GeneRegistry.seed_key(family),0)) if enabled else 0
func restore(saved: Dictionary, events: Dictionary, test_mode: bool) -> void:
	archive = LineageArchive.from_record(events.get("lineage_archive",{}))
	if saved.has("genetics"):
		var data: Dictionary = saved["genetics"]
		genome = GenomeState.from_record(data["genome"])
		enabled = data["enabled"]
		life_id = int(data["life_id"])
		focus = data.get("focus","")
		qa_preview=bool(data.get("qa_preview",false))
		breach_cooldown = float(data.get("breach_cooldown",0))
		if data.has("effects"): effects.restore(data["effects"])
	else:
		enabled = saved.is_empty() and not test_mode
		genome.growth_policy = "chosen" if saved.is_empty() else "legacy"
		if saved.is_empty(): genome.draft_seed=int(scene.world.state.seed_value%2147483647)
		life_id = archive.next_id
	refresh()
	if saved.has("genetics"):
		trail.restore(saved["genetics"].get("trail",{}))
		traversal.safe_restore(String(saved["genetics"].get("mode","ground")))
	if enabled and scene.hp <= 0: finalize_death()

func record() -> Dictionary:
	return {"version":1,"enabled":enabled,"life_id":life_id,"focus":focus,"qa_preview":qa_preview,"genome":genome.record(),"effects":effects.record(),"breach_cooldown":breach_cooldown,"mode":traversal.mode,"trail":trail.record()}
static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.has("qa_preview") and not data["qa_preview"] is bool: return false
	var cooldown = data.get("breach_cooldown",0)
	if not WorldState._number(cooldown) or float(cooldown)<0 or float(cooldown)>4: return false
	return data.get("version")==1 and data.get("enabled") is bool and WorldState._number(data.get("life_id")) and int(data["life_id"])>=1 and data.get("focus","") in GeneRegistry.FORMS+[""] and GenomeState.from_record(data.get("genome")) != null and data.get("mode","ground") in ["ground","flight","glide","burrow","emerging","climb","roof","falling","landing"] and (not data.has("trail") or AxialTrail.valid(data["trail"])) and (not data.has("effects") or GeneEffects.valid(data["effects"]))

func refresh() -> void:
	if not is_instance_valid(morphology): return
	if enabled:
		var inherited: Dictionary={}
		for generic_id in GeneRegistry.LEGACY: inherited[generic_id]=int(genome.ranks.get(generic_id,0))
		morphology.configure(genome,inherited)
		if not qa_preview: archive.observe(genome)
	else: morphology.hide()
	var overridden := enabled and morphology.visible
	scene.creature_rig["visual"].set_meta("genetic_body",overridden)
	scene.creature_rig["visual"].update_pose(scene.upright_form)
	if enabled and genome.growth_policy == "chosen":
		var host:=morphology.primary if not morphology.primary.is_empty() else "reptile"
		dimensions=BodyDimensionsPolicy.measure(host,int(genome.ranks.get("physical_growth",0)))
		scene.growth_scale=float(dimensions["scale_metric"])
		scene.upright_form = false
		scene.beast_visual.scale = Vector3.ONE*scene.growth_scale
		scene.torso_pivot.rotation.x = 0
		morphology.scale=BodyDimensionsPolicy.visual_axes(dimensions,scene.growth_scale)
		scene.upright_form=false
	scene._sync_beast_collision()
	if overridden:
		if not dimensions.has("family"):
			dimensions=BodyDimensionsPolicy.measure(morphology.primary,int(genome.ranks.get("physical_growth",0)))
		var contact_radius:=maxf(1.0,BodyDimensionsPolicy.envelope(dimensions))
		# Hybrid support arrays may be wider than their primary host's core.
		for joint in morphology.joints:
			var mesh: MeshInstance3D=joint.get_child(0) as MeshInstance3D
			var box := mesh.get_aabb()
			for corner in range(8):
				var at: Vector3=scene.beast.to_local(joint.to_global(box.get_endpoint(corner)))
				contact_radius=maxf(contact_radius,absf(at.x)+.10)
		scene.beast_collision_shape.radius=contact_radius
		scene.beast_collision_shape.height=maxf(contact_radius*2.0,float(dimensions["height"]))
		scene.body_collision_node.position.y=contact_radius
		scene.head_collision_shape.radius=maxf(.28,float(dimensions["radius"])*.72 if dimensions["axial"] else float(dimensions["width"])*.19)
		scene.head_collision_node.position=mouth_local()
	neck_contact.disabled=not (overridden and dimensions.get("axial",false))
	if not neck_contact.disabled:
		var mouth := mouth_local()
		var neck_radius := float(dimensions["radius"])*.78
		neck_contact.shape.radius=neck_radius
		neck_contact.shape.height=maxf(neck_radius*2,absf(mouth.z)+neck_radius*2)
		neck_contact.rotation.x=PI*.5
		neck_contact.position=Vector3(0,maxf(neck_radius,mouth.y),mouth.z*.5)
	trail.configure(dimensions) if overridden else trail.hide()
	if overridden: fit_wings()
	if traversal.mode=="flight" and not traversal.can_use("flight"):
		traversal.mode="glide"
		traversal.height_target=scene.beast.position.y
		traversal.last_error="New wing load: gliding to land."
	for axis in morphology.axes: axis.visible=not trail.live
	if not overridden: trail.live=false
	scene.retry_button.text = "NEW ORGANISM" if enabled else "RESTART"
	if is_instance_valid(hud): hud.refresh()

func mouth_local() -> Vector3:
	if not enabled or morphology.primary.is_empty(): return scene.head_collision_node.position
	var mouth: Vector3=AnatomyManifest.signature(morphology.primary)["anchors"]["mouth"]
	return scene.beast.to_local(morphology.to_global(mouth))

func fit_wings() -> void:
	if morphology.wings.is_empty():
		wing_contact.disabled=true
		return
	var width := morphology.global_basis.x.length()
	var length := .58+morphology.wing_development*.35+morphology.seed_tier*.06
	var span := float(dimensions.get("wingspan",0))
	if span<=0: span=maxf(4.2,float(dimensions.get("width",2))*1.8)
	for wing in morphology.wings: wing.scale.x=maxf(.4,(span*.5/maxf(.01,width)-.43)/(1.0+length))
	wing_contact.shape.size=Vector3(span,maxf(.35,float(dimensions["height"])*.15),maxf(1.0,float(dimensions["length"])*.6))
	wing_contact.position=Vector3(0,float(dimensions["height"])*.6,0)

func prepare_draft() -> void:
	if genome.draft.is_empty(): genome.draft = MutationDraft.create(genome,genome.draft_seed,scene.evolutions,focus,{"terrain":"coast" if scene.beast.position.z>=WorldLayout.shore(scene.beast.position.x)-45 else "inland"})
	# Store frozen offers against the pre-evolution player state. A crash resumes
	# the same organism and frozen offers; the vulnerable stage can be retried.
	scene.world.checkpoint_genetics()

func choose(key: String) -> bool:
	if not enabled or key not in genome.draft: return false
	if not genome.select_gene(key,"life_%d_evo_%d" % [life_id,scene.evolutions+1]): return false
	refresh()
	scene._update_creature_animation(0,false)
	scene._resolve_growth_clearance()
	return true

func preview(key: String) -> String:
	var gene: Dictionary = GeneRegistry.definitions()[key]
	var forecast := GenomeState.from_record(genome.record())
	forecast.select_gene(key,"preview_%d" % scene.evolutions)
	var affinity := "No family affinity"
	if not gene["family"].is_empty(): affinity = "+4 " + String(gene["family"]).capitalize()
	var host: String=AnatomyResolver.resolve(forecast.ranks,forecast.raw)["primary"]
	if host.is_empty(): host="reptile"
	var spec := AnatomyManifest.expression(host,key,int(forecast.ranks.get(key,1)))
	var change := "%s %s · rank %d" % [String(spec["operation"]).capitalize(),String(spec["socket"]).replace("_"," "),spec["rank"]]
	if key=="physical_growth": change="Length + radius" if host in ["snake","worm"] else "Body dimensions + clearance"
	if key=="armour" and int(forecast.ranks.get(key,0))>=3 and not forecast.ranks.has("gene_122"): change+=" · heavy flight needs Soaring"
	return "%s\n%s | %s\n%s\n%s" % [gene["name"],affinity,change,gene["detail"],forecast.label()]

func speed_multiplier(at: Vector3) -> float:
	var value := (1.0+.12*rank("bird"))*maxf(.70,1.0-.06*rank("crab"))
	if rank("worm")>0 and at.z < WorldLayout.shore(at.x)-45: value *= .88
	return value * effects.movement()
func sprint_cost(at: Vector3) -> float:
	var value := 1.0+.05*int(genome.ranks.get("physical_growth",0)) if enabled else 1.0
	if rank("worm")>0 and at.z >= WorldLayout.shore(at.x)-45: value *= .75
	return value * (.80 if effects.has(39) else 1.0)
func damage_multiplier() -> float:
	return maxf(.25,pow(.82,rank("reptile"))*pow(.84,rank("crab")))*(1.0+.10*rank("bird"))
func reach_multiplier() -> float: return 1.0+.18*rank("ape")
func cone() -> float: return .25 if rank("ape")>0 or rank("spider")>0 or effects.has(30) else scene.BITE_CONE_DOT

func on_response_hit(index: int) -> void:
	if poison_tick or rank("snake")==0 or index<0 or index>=scene.officers.size(): return
	if not DefconDirector.is_vehicle(scene.officers[index]["kind"]):
		scene.officers[index]["venom_remaining"] = 3.0
		scene.officers[index]["venom_power"] = 6.0*rank("snake")

func advance(delta: float) -> void:
	if not enabled: return
	effects.advance(delta)
	morphology.movement_mode=traversal.mode
	morphology.bank=traversal.bank
	morphology.flight_clock=scene.creature_idle_clock
	morphology.bite=sin((1.0-clampf(scene.bite_timer/maxf(.05,scene.bite_duration),0,1))*PI) if scene.bite_timer>0 else 0.0
	var wall_offset := Vector3.ZERO
	if traversal.mode=="climb": wall_offset=scene.beast_visual.global_basis.inverse()*(-traversal.climb_normal*(scene.beast_collision_shape.radius-.12))
	morphology.position=morphology.position.lerp(wall_offset,minf(1,delta*12))
	morphology.animate(scene.run_phase,scene.beast.velocity.length()>0 or scene.touch_vector.length_squared()>.01)
	if morphology.visible: scene.head_collision_node.position=mouth_local()
	breach_cooldown = maxf(0,breach_cooldown-delta)
	for i in range(scene.officers.size()-1,-1,-1):
		var foe: Dictionary = scene.officers[i]
		var remaining := float(foe.get("venom_remaining",0))
		if remaining>0:
			foe["venom_remaining"] = maxf(0,remaining-delta)
			poison_tick = true
			scene._damage_response(i,float(foe.get("venom_power",0))*minf(delta,remaining))
			poison_tick = false
	update_sensor()

func update_sensor() -> void:
	marked_target = null
	if effects.sensor_range()>0:
		var distance := effects.sensor_range()
		for npc in scene.civilians:
			var node: Node3D = npc["node"]
			var d := node.global_position.distance_to(scene.beast.global_position)
			if d<distance: distance=d; marked_target=node
		if effects.has(95):
			for foe in scene.officers:
				var node: Node3D = foe["node"]
				var d := node.global_position.distance_to(scene.beast.global_position)
				if d<distance: distance=d; marked_target=node
			for car in scene.cars:
				if not car["destroyed"] and car.get("active",false):
					var node: Node3D = car["node"]
					var d := node.global_position.distance_to(scene.beast.global_position)
					if d<distance: distance=d; marked_target=node
	sensor.visible = is_instance_valid(marked_target)
	if sensor.visible: sensor.global_position = marked_target.global_position+Vector3(0,3.0,0)

func breach(index: int) -> void:
	if rank("mole")==0 or breach_cooldown>0 or index<0 or index>=scene.buildings.size(): return
	var b: Dictionary = scene.buildings[index]
	if b["destroyed"]: return
	# Surface soil clearing/breach adds bounded chip damage, never moves through cover.
	breach_cooldown = 4.0
	genome.credit_behaviour("mole","breached_"+String(b["id"]))
	scene._damage_building(index,.20*rank("mole"))
	scene._add_alert(2.0)
	scene.coastal_effects.burst(scene.beast.position+Vector3(0,.3,0),6,1.0,true)

func finalize_death() -> void:
	if not enabled: return
	traversal.vertical_input=0
	if qa_preview: return
	archive.finalize(life_id,genome,scene.beast.position,scene.evolutions,scene.alert)
	scene.world.state.events["lineage_archive"] = archive.record()

func new_organism_keep_world(reload_scene: bool = true) -> bool:
	if not enabled or not scene.game_over or not scene.world.state.writable: return false
	finalize_death()
	scene.world.save_writer.flush()
	if not scene.world.save_now(true):
		error_message = "Save failed. World retained; retry when storage is available."
		return false
	# Persist the fresh organism in the SAME atomic world document before reloading.
	# Keep objectives, pins, vehicles, pending evacuations, destruction and seed.
	var pending: Array = scene.world.state.player.get("evacuations",[]).duplicate(true)
	var fresh := GenomeState.new()
	fresh.draft_seed = int((scene.world.state.seed_value+archive.next_id*104729)%2147483647)
	scene.world.state.player = {"hp":scene.BASE_HP,"position":[0,0,18],"evacuations":pending,
		"genetics":{"version":1,"enabled":true,"life_id":archive.next_id,"focus":"","genome":fresh.record()}}
	if not scene.world.state.write_save():
		error_message = "Could not checkpoint new organism. The prior life remains recoverable."
		return false
	scene.get_tree().paused = false
	if reload_scene: scene.get_tree().reload_current_scene()
	return true

func fixture(families: Array, count: int = 1) -> void:
	traversal._end_mode()
	enabled = true
	genome = GenomeState.new()
	effects.reset()
	breach_cooldown=0
	for i in range(count):
		for family in families: genome.select_gene(GeneRegistry.seed_key(family),"fixture_%s_%d" % [family,i])
	if families.size()>1 and count<5: genome.select_gene(GeneRegistry.seed_key(families[0]),"fixture_primary")
	refresh()
	scene._resolve_growth_clearance()
	scene._update_camera(1)
