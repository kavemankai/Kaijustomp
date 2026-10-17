class_name AnatomyResolver
extends RefCounted
## Ground-only proof parts occupy separate bounded accessory sockets.
## Heavy grasp arms need a matrix support frame on an axial trunk.
static func resolve(ranks: Dictionary, affinities: Dictionary = {}) -> Dictionary:
	var families: Array[String] = []
	var slots := {}
	for f in GeneRegistry.FORMS:
		var present := false
		for key in ranks:
			if GeneRegistry.definitions().has(key) and GeneRegistry.definitions()[key]["family"]==f: present=true
		if present:
			families.append(f)
			slots[f+"_signature"] = f
	var bridge := int(ranks.get("gene_100",0))>0
	if int(ranks.get("gene_044",0))>0:
		slots["forelimbs"]="ape_support_with_pincer_hands" if int(ranks.get("gene_061",0))>0 else "ape_grasp_arms"
	var legal := not (int(ranks.get("gene_044",0))>0 and ("worm" in families or "snake" in families) and not bridge)
	var plan := "ground"
	var scores := affinities.duplicate()
	if scores.is_empty():
		for f in GeneRegistry.FORMS: scores[f]=0
		for key in ranks:
			if not GeneRegistry.definitions().has(key): continue
			for f in GeneRegistry.definitions()[key]["affinity"]: scores[f]+=int(ranks[key])*int(GeneRegistry.definitions()[key]["affinity"][f])
	var primary := ""
	for f in GeneRegistry.FORMS:
		if f in families and (primary.is_empty() or int(scores[f])>int(scores[primary])): primary=f
	if primary=="worm": plan = "axial_crawler"
	elif primary=="snake": plan = "surface_slither"
	elif primary=="spider": plan = "eight_leg_ground"
	elif primary=="crab": plan = "lateral_ground"
	elif primary=="bird": plan = "light_ground"
	elif primary=="ape": plan = "knuckle_ground"
	return {"legal":legal,"families":families,"slots":slots,"body_plan":plan,
		"bridge":bridge,"cohesion":100 if legal else 88,
		"reason":"Heavy arms on an axial trunk require Chimeric Flesh Matrix." if not legal else "Ground controller; flight, wall climb and underground travel locked."}
