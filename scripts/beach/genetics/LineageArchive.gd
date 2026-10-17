class_name LineageArchive
extends RefCounted
const VERSION := 1
var next_id := 1
var lives: Array = []
var discoveries: Array[String] = []
var hybrids: Array[String] = []
var mastery: Dictionary = {}
var strategic_pressure := 0.0
func _init() -> void:
	for f in GeneRegistry.FORMS: mastery[f] = 0
func observe(genome: GenomeState) -> void:
	for key in genome.ranks:
		if key not in discoveries: discoveries.append(key)
	for f in GeneRegistry.FORMS: mastery[f] = maxi(int(mastery[f]),int(genome.raw[f]))
	var identity := genome.identity()
	if identity["kind"] == "hybrid":
		var pair: Array = identity["families"].duplicate()
		pair.sort()
		var key := "+".join(pair)
		if key not in hybrids: hybrids.append(key)
func finalize(life_id: int, genome: GenomeState, position: Vector3, evolution: int, pressure: float) -> bool:
	if life_id<next_id: return false
	for life in lives:
		if int(life["id"]) == life_id: return false
	observe(genome)
	strategic_pressure = maxf(strategic_pressure,pressure)
	lives.append({"id":life_id,"identity":genome.label(),"genes":genome.ranks.duplicate(),"evolution":evolution,"position":[position.x,position.y,position.z]})
	if lives.size()>128: lives.pop_front()
	next_id = maxi(next_id,life_id+1)
	return true
func record() -> Dictionary:
	return {"version":VERSION,"next_id":next_id,"lives":lives.duplicate(true),"discoveries":discoveries.duplicate(),"hybrids":hybrids.duplicate(),"mastery":mastery.duplicate(),"strategic_pressure":strategic_pressure}
static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != VERSION: return false
	if not WorldState._number(data.get("next_id")) or int(data["next_id"])<1: return false
	if not WorldState._number(data.get("strategic_pressure")) or float(data["strategic_pressure"])<0: return false
	if not data.get("lives") is Array or data["lives"].size()>128: return false
	if not data.get("discoveries") is Array or not data.get("hybrids") is Array or not data.get("mastery") is Dictionary: return false
	if data["discoveries"].size()>GeneRegistry.definitions().size() or data["hybrids"].size()>36 or data["mastery"].size()!=9: return false
	var ids := {}
	for life in data["lives"]:
		if not life is Dictionary or not WorldState._number(life.get("id")) or not life.get("identity") is String or not life.get("genes") is Dictionary: return false
		if int(life["id"])<1 or int(life["id"])>=int(data["next_id"]) or ids.has(int(life["id"])): return false
		ids[int(life["id"])] = true
		if not WorldState._number(life.get("evolution")) or not life.get("position") is Array or life["position"].size()!=3: return false
		for n in life["position"]:
			if not WorldState._number(n): return false
		for key in life["genes"]:
			if not GeneRegistry.definitions().has(key) or not WorldState._number(life["genes"][key]): return false
	for key in data["discoveries"]:
		if not key is String or not GeneRegistry.definitions().has(key): return false
	for key in data["hybrids"]:
		if not key is String: return false
		var pair: PackedStringArray = key.split("+")
		if pair.size()!=2 or pair[0] not in GeneRegistry.FORMS or pair[1] not in GeneRegistry.FORMS or pair[0]==pair[1]: return false
	for f in GeneRegistry.FORMS:
		if not WorldState._number(data["mastery"].get(f)) or float(data["mastery"][f])<0: return false
	return true
static func from_record(data: Dictionary) -> LineageArchive:
	var result := LineageArchive.new()
	if not valid(data): return result
	result.next_id = int(data["next_id"])
	result.lives = data["lives"].duplicate(true)
	result.discoveries.assign(data["discoveries"])
	result.hybrids.assign(data["hybrids"])
	result.mastery = data["mastery"].duplicate()
	result.strategic_pressure = float(data["strategic_pressure"])
	return result
