class_name GeneEffects
extends RefCounted
## Bounded adaptations of the curated source concepts to the current ground game.
## No catalogue prose is executed as an ability.
const EARLY := {
	1:["reptile","Forked tongue marks nearby prey (28 units).","tongue"],
	2:["reptile","Loose scutes give 22% damage resistance for 3 seconds every 12 seconds.","peel"],
	7:["reptile","Acid saliva corrodes contacted structures and cars for 3 seconds; maximum 8 targets.","drool"],
	9:["reptile","Ridge spines add 6 damage to close responder impacts.","spines"],
	12:["reptile","Scavenger jaw grants 25% more biomass from eligible food; diet gates remain.","jaw"],
	14:["snake","Thermal pits mark prey through cover within 40 units.","pits"],
	19:["reptile","Tail club strikes a nearby rear responder for 10 damage and slows it for 2 seconds; 4s cooldown.","club"],
	20:["reptile","Still camouflage adds 2 units of enemy aim spread after 2 seconds without movement.","pigment"],
	30:["bird","Raptor eyes mark prey out to 52 units and widen the feeding cone.","eyes"],
	36:["bird","Wing spurs add 14 responder contact damage while sprinting.","spurs"],
	39:["bird","Air sacs reduce sprint drain by 20%.","sacs"],
	42:["ape","Guard hair reduces small-arms damage (raw <=10) by 12%.","hair"],
	43:["ape","Tusks add 8 penetrating damage on responder contact.","tusks"],
	47:["ape","Adrenal veins give 25% more speed below 35% health.","veins"],
	49:["ape","Fat layer reduces heavy hits by 20%; 8% slower movement.","fat"],
	57:["ape","Eyeshine marks nearby prey within 34 units; perception proof, no day/night system.","eyeshine"],
	58:["ape","REST stance heals 2 HP/s while still, but incoming damage rises 20%. Move to cancel.","torpor"],
	72:["crab","Shell spikes deflect every fourth small-arms hit. Heavy rounds remain effective.","shellspikes"],
	73:["spider","Hydraulic joints give 20% speed during the first 2 seconds of a sprint.","joints"],
	81:["biomass","Mucus reduces feeding slowdown: retain 75% speed instead of 53%.","slime"],
	85:["worm","GUARD stance halves movement and reduces damage 40%. Sprint cancels the stance.","mantle"],
	88:["worm","Lure stalk draws quiet prey within 12 units while still; stops above alert 35.","lure"],
	90:["biomass","Toxin skin pulses 4 damage against responders within 3 units after a hit; 2s cooldown.","glands"],
	95:["mole","Electroreception marks nearby vehicles/responders within 32 units, including behind cover.","pores"],
	99:["biomass","Acid slime chips one nearby structure/car each second within 4 units; six pooled trail marks.","trail"],
	441:["snake","After 3 seconds motionless, next responder contact gains 20 damage; rearm by waiting.","prowl"]
}
var owner: BeachGenetics
var clock := 0.0
var still := 0.0
var sprint_time := 0.0
var stance := false
var hit_count := 0
var tail_cooldown := 0.0
var toxin_cooldown := 0.0
var slime_clock := 0.0
var ambush_ready := false
var corrosion: Array[Dictionary] = []
var trail: Array[Node3D] = []
var trail_expiry: Array[float] = []
var trail_index := 0
func _init(model: BeachGenetics) -> void: owner=model
func has(id: int) -> bool: return owner.enabled and int(owner.genome.ranks.get("gene_%03d" % id,0))>0
func setup_trail() -> void:
	for i in range(6):
		var node := Node3D.new()
		owner.scene.add_child(node)
		node.set_meta("exclude_shed",true)
		CoastalArt.oval(node,Vector3.ZERO,Vector3(1.3,.035,1.1),Color("88ac54"))
		node.hide()
		trail.append(node); trail_expiry.append(0.0)
func toggle_stance() -> void:
	if not owner.enabled or not (has(58) or has(85)): return
	stance=not stance
func record() -> Dictionary:
	return {"version":1,"clock":clock,"still":still,"sprint_time":sprint_time,"stance":stance,"hit_count":hit_count,"tail_cooldown":tail_cooldown,"toxin_cooldown":toxin_cooldown,"slime_clock":slime_clock,"ambush_ready":ambush_ready,"corrosion":corrosion.duplicate(true)}
static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version")!=1: return false
	for key in ["clock","still","sprint_time","hit_count","tail_cooldown","toxin_cooldown","slime_clock"]:
		if not WorldState._number(data.get(key)) or float(data[key])<0 or float(data[key])>1.0e12: return false
	for key in ["stance","ambush_ready"]:
		if not data.get(key) is bool: return false
	if not data.get("corrosion") is Array or data["corrosion"].size()>8: return false
	for target in data["corrosion"]:
		if not target is Dictionary or target.get("kind") not in ["building","car"] or not target.get("id") is String: return false
		if not WorldState._number(target.get("remaining")) or float(target["remaining"])<0 or float(target["remaining"])>3: return false
	return true
func restore(data: Dictionary) -> void:
	if not valid(data): return
	for key in ["clock","still","sprint_time","stance","hit_count","tail_cooldown","toxin_cooldown","slime_clock","ambush_ready"]: set(key,data[key])
	corrosion.assign(data["corrosion"].duplicate(true))
func reset() -> void:
	clock=0; still=0; sprint_time=0; stance=false; hit_count=0; tail_cooldown=0; toxin_cooldown=0; slime_clock=0; ambush_ready=false
	corrosion.clear()
	for i in range(trail.size()): trail[i].hide(); trail_expiry[i]=0
func movement() -> float:
	var value := 1.0
	if has(47) and owner.scene.hp<owner.scene.max_hp*.35: value*=1.25
	if has(49): value*=.92
	if has(73) and owner.scene.sprint_active and sprint_time<2.0: value*=1.20
	if has(85) and stance: value*=.5
	return value
func feeding_slowdown() -> float: return .75 if has(81) else .53
func concealed() -> bool: return has(20) and still>=2.0
func incoming(raw: float) -> float:
	var value := 1.0
	if has(2) and fmod(clock,12.0)<3.0: value*=.78
	if has(42) and raw<=10.0: value*=.88
	if has(49) and raw>10.0: value*=.80
	if has(58) and stance and still>.1: value*=1.20
	if has(85) and stance: value*=.60
	if has(72) and raw<=10.0:
		hit_count+=1
		if hit_count%4==0: value=0
	return value
func feed_multiplier() -> float: return 1.25 if has(12) else 1.0
func sensor_range() -> float:
	var value := 38.0 if owner.rank("spider")>0 else 0.0
	for id in [1,14,30,57,95]:
		if has(id): value=maxf(value,{1:28.0,14:40.0,30:52.0,57:34.0,95:32.0}[id])
	return value
func contact_bonus(index: int) -> float:
	if owner.poison_tick or index<0 or index>=owner.scene.officers.size(): return 0.0
	var value := 0.0
	if has(9): value+=6.0
	if has(36) and owner.scene.sprint_active: value+=14.0
	if has(43): value+=8.0
	if has(441) and ambush_ready: value+=20.0; ambush_ready=false; still=0.0
	return value
func retaliate() -> void:
	if not has(90) or toxin_cooldown>0: return
	toxin_cooldown=2.0
	owner.poison_tick=true
	for i in range(owner.scene.officers.size()-1,-1,-1):
		if owner.scene.officers[i]["node"].global_position.distance_to(owner.scene.beast.position)<3.0*owner.scene.growth_scale: owner.scene._damage_response(i,4.0)
	owner.poison_tick=false
func corrode(kind: String, id: String) -> void:
	if not has(7): return
	for target in corrosion:
		if target["kind"]==kind and target["id"]==id: target["remaining"]=3.0; return
	if corrosion.size()<8: corrosion.append({"kind":kind,"id":id,"remaining":3.0})
func lure_direction(at: Vector3, original: Vector3) -> Vector3:
	if has(88) and still>1.0 and owner.scene.alert<35 and at.distance_to(owner.scene.beast.position)<12.0:
		var toward: Vector3 = owner.scene.beast.position-at
		toward.y=0
		return toward.normalized()
	return original
func _corrosion_tick(delta: float) -> void:
	for i in range(corrosion.size()-1,-1,-1):
		var target: Dictionary = corrosion[i]
		var step := minf(float(target["remaining"]),delta)
		if target["kind"]=="building":
			var index: int = owner.scene._index_for_world_id(target["id"])
			if index>=0 and not owner.scene.buildings[index].get("destroyed",true): owner.scene._damage_building(index,.08*step)
		else:
			for car_index in range(owner.scene.cars.size()):
				var car: Dictionary = owner.scene.cars[car_index]
				if car.get("id","")==target["id"] and not car["destroyed"] and car.get("active",false): owner.scene._damage_car(car_index,.25*step); break
		target["remaining"]=float(target["remaining"])-delta
		if float(target["remaining"])<=0: corrosion.remove_at(i)
func _slime_pulse() -> void:
	var at: Vector3 = owner.scene.beast.position
	trail[trail_index].position=Vector3(at.x,.03,at.z)
	trail[trail_index].show(); trail_expiry[trail_index]=clock+6.0
	trail_index=(trail_index+1)%6
	for index in range(owner.scene.buildings.size()):
		var b: Dictionary = owner.scene.buildings[index]
		if b.get("destroyed",true) or not b.get("active",false): continue
		var center: Vector3 = b["position"]
		var half: Vector2 = b["half"]
		if absf(at.x-center.x)<half.x+4 and absf(at.z-center.z)<half.y+4:
			owner.scene._damage_building(index,.06)
			return
	for index in range(owner.scene.cars.size()):
		var car: Dictionary = owner.scene.cars[index]
		if not car["destroyed"] and car.get("active",false) and car["node"].position.distance_to(at)<6:
			owner.scene._damage_car(index,.15)
			return
func advance(delta: float) -> void:
	clock+=delta
	var moving: bool = owner.scene.beast.velocity.length()>.1
	still=0.0 if moving else still+delta
	sprint_time=sprint_time+delta if owner.scene.sprint_active else 0.0
	if moving and has(58): stance=false
	if owner.scene.sprint_active: stance=false
	if has(441) and still>=3.0: ambush_ready=true
	if has(58) and stance and not moving: owner.scene.hp=minf(owner.scene.max_hp,owner.scene.hp+2.0*delta)
	tail_cooldown=maxf(0,tail_cooldown-delta)
	toxin_cooldown=maxf(0,toxin_cooldown-delta)
	_corrosion_tick(delta)
	for foe in owner.scene.officers: foe["gene_slow"]=maxf(0,float(foe.get("gene_slow",0))-delta)
	if has(19) and tail_cooldown<=0:
		for i in range(owner.scene.officers.size()-1,-1,-1):
			var toward: Vector3 = owner.scene.officers[i]["node"].position-owner.scene.beast.position
			if toward.length()<4.0*owner.scene.growth_scale and toward.dot(owner.scene.beast.basis.z)>0:
				tail_cooldown=4.0
				owner.scene.officers[i]["gene_slow"]=2.0
				owner.poison_tick=true; owner.scene._damage_response(i,10.0); owner.poison_tick=false
				break
	if has(99):
		slime_clock+=delta
		if slime_clock>=1.0: slime_clock=0.0; _slime_pulse()
	for i in range(trail.size()): trail[i].visible=has(99) and trail_expiry[i]>clock
