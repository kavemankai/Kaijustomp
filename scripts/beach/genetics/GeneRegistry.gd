class_name GeneRegistry
extends RefCounted
## Source catalogue stays immutable; only these authored hooks enter live drafts.
const FORMS := ["reptile","biomass","snake","bird","crab","spider","ape","worm","mole"]
const SEEDS := [6,100,11,22,61,62,44,84,15]
const CURATED := [1,2,6,7,9,12,14,19,20,22,30,36,39,42,43,47,49,57,58,61,72,73,81,85,88,90,95,99,100,441]
const LEGACY := ["armour","strength","speed","stamina","health","jaw","regen","cocoon","metamorphosis"]
const GENERIC := {
	"armour":["Hardened Scales","22% less remaining incoming damage per rank; cap 8."],
	"strength":["Brutal Strength","+1 demolition strength per rank; cap 8."],
	"speed":["Fleet Limbs","+1.6 ground speed per rank; cap 8."],
	"stamina":["Endurance","+35 maximum stamina per rank; cap 8."],
	"health":["Dense Flesh","+25 maximum health per rank; cap 8."],
	"jaw":["Rapid Feeding","22% shorter feeding slowdown per rank, floor 0.23 seconds."],
	"regen":["Regeneration","Recover 0.6 HP/s per rank; cap 8."],
	"cocoon":["Reinforced Cocoon","18% less evolution damage and +12 interruption tolerance per rank; cap 3."],
	"metamorphosis":["Rapid Metamorphosis","22% shorter vulnerable evolution per rank, floor 3 seconds; cap 3."]
}
const DESCRIPTIONS := [
	"Dorsal osteoderms: 18% less damage per rank (capped).",
	"Patchwork tendrils: support incompatible heavy arms; wider explore offers.",
	"Venom fangs: contact envenoms responders for 3 seconds; no effect on vehicles.",
	"Feathered winglets: +12% ground speed per rank; +10% incoming damage. Flight locked.",
	"Segmented shell and pincers: 16% damage reduction per rank; 6% slower per rank.",
	"Ocelli and eight-leg frame: mark nearest prey within 38 units, wider feeding cone.",
	"Long grasping arms: +18% feeding reach per rank and wider capture cone.",
	"Segmented ventral crawler: 25% cheaper sprint on coastal sand; 12% slower inland.",
	"Digging spades: surface breach every 4 seconds chips nearby structures; no tunnelling."
]
static var _entries: Dictionary = {}
static var _catalog: Dictionary = {}

static func catalogue() -> Dictionary:
	if _catalog.is_empty():
		var doc = JSON.parse_string(FileAccess.get_file_as_string("res://data/evolution/kaijustomp_mutation_catalog_500.json"))
		if doc is Dictionary:
			for entry in doc.get("entries", []): _catalog[int(entry["id"])] = entry
	return _catalog

static func seed_key(family: String) -> String:
	var i := FORMS.find(family)
	return "gene_%03d" % SEEDS[i] if i >= 0 else ""

static func definitions() -> Dictionary:
	if not _entries.is_empty(): return _entries
	var catalog := catalogue()
	for i in range(FORMS.size()):
		var key := seed_key(FORMS[i])
		_entries[key] = {"key":key,"source_id":SEEDS[i],"name":catalog[SEEDS[i]]["name"],
			"family":FORMS[i],"affinity":{FORMS[i]:4},"cap":5,"lane":"explore",
			"socket":FORMS[i]+"_signature","part":FORMS[i],"operation":"add",
			"effect":FORMS[i],"detail":DESCRIPTIONS[i],"readiness":"playable","weight":1.0}
	for id in LEGACY:
		_entries[id] = {"key":id,"source_id":0,"name":GENERIC[id][0],"family":"",
			"affinity":{},"cap":3 if id in ["cocoon","metamorphosis"] else 8,"lane":"adapt","socket":"legacy","part":"",
			"operation":"modify","effect":id,"detail":GENERIC[id][1],"readiness":"playable","weight":0.6}
	for id in GeneEffects.EARLY:
		var authored: Array = GeneEffects.EARLY[id]
		var key := "gene_%03d" % id
		_entries[key] = {"key":key,"source_id":id,"name":catalog[id]["name"],"family":authored[0],
			"affinity":{authored[0]:4},"cap":1,"lane":"adapt","socket":"trait_%d" % id,
			"part":authored[2],"operation":"add","effect":"source_%d" % id,"detail":authored[1],"readiness":"playable","weight":1.0}
	_entries["physical_growth"] = {"key":"physical_growth","source_id":0,"name":"Chosen physical growth","family":"",
		"affinity":{},"cap":18,"lane":"adapt","socket":"core","part":"growth","operation":"modify",
		"effect":"physical_growth","detail":"Grow host dimensions; axial forms gain length and girth. +5% sprint cost per rank, cap 18; diet and clearance change.","readiness":"playable","weight":0.8}
	return _entries

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var catalog := catalogue()
	if catalog.size() != 500: errors.append("Expected 500 sources")
	var keys := {}
	for id in range(1,501):
		if not catalog.has(id):
			errors.append("Missing source %d" % id)
			continue
		var entry: Dictionary = catalog[id]
		if keys.has(entry["key"]) or String(entry["name"]).is_empty() or String(entry["source_effect"]).is_empty(): errors.append("Invalid source %d" % id)
		keys[entry["key"]] = true
	for gene in definitions().values():
		if gene["source_id"] != 0 and not catalog.has(gene["source_id"]): errors.append("Unknown source")
		for family in gene["affinity"]:
			if family not in FORMS or int(gene["affinity"][family]) < 0: errors.append("Invalid affinity")
	return errors
