class_name GenomeState
extends RefCounted
const VERSION := 1
var raw: Dictionary = {}
var ranks: Dictionary = {}
var transactions: Array[String] = []
var draft: Array[String] = []
var draft_seed := 79123
var growth_policy := "chosen"
var behaviour: Dictionary = {}
var interval_credit: Dictionary = {}
var behaviour_events: Array[String] = []
func _init() -> void:
	for f in GeneRegistry.FORMS: raw[f] = 0; behaviour[f]=0; interval_credit[f]=0
func credit_behaviour(family: String, verified_event: String) -> bool:
	if family not in GeneRegistry.FORMS or verified_event.is_empty() or verified_event in behaviour_events or int(interval_credit[family])>=2: return false
	if behaviour_events.size()>=18: return false
	behaviour_events.append(verified_event)
	interval_credit[family]+=1
	behaviour[family]+=1
	raw[family]+=1
	return true
func total() -> int:
	var sum := 0
	for n in raw.values(): sum += int(n)
	return sum
func percentages() -> Dictionary:
	var result := {}
	for f in GeneRegistry.FORMS: result[f] = 100.0 * int(raw[f]) / total() if total() > 0 else 0.0
	return result
func ordered_families() -> Array:
	var result := GeneRegistry.FORMS.duplicate()
	result.sort_custom(func(a,b): return int(raw[a]) > int(raw[b]) if raw[a] != raw[b] else GeneRegistry.FORMS.find(a) < GeneRegistry.FORMS.find(b))
	return result
func identity() -> Dictionary:
	var anatomy := AnatomyResolver.resolve(ranks,raw)
	var order := ordered_families()
	var shares := percentages()
	var kind := "unformed"
	var families := [order[0]] if total() >= 12 else []
	if total() >= 20 and shares[order[0]] >= 25 and shares[order[1]] >= 25 and shares[order[0]]+shares[order[1]] >= 65:
		families = [order[0],order[1]]
		kind = "hybrid" if anatomy["legal"] and order[0] in anatomy["families"] and order[1] in anatomy["families"] else "candidate"
	elif total() >= 20 and shares[order[0]] >= 50 and order[0] in anatomy["families"]: kind = "consolidated"
	elif total() >= 12 and shares[order[0]] >= 35: kind = "emerging"
	return {"kind":kind,"families":families,"anatomy":anatomy}
func label() -> String:
	var state := identity()
	return "Unformed hatchling" if state["kind"] == "unformed" else "%s %s" % [String(state["kind"]).capitalize(), "+".join(state["families"])]
func legal(key: String) -> bool:
	var defs := GeneRegistry.definitions()
	if not defs.has(key) or defs[key]["readiness"] != "playable": return false
	if int(ranks.get(key,0)) >= int(defs[key]["cap"]): return false
	if key == "physical_growth" and growth_policy == "legacy": return false
	var proposed := ranks.duplicate()
	proposed[key] = int(proposed.get(key,0))+1
	return AnatomyResolver.resolve(proposed)["legal"]
func select_gene(key: String, transaction: String) -> bool:
	if transaction.is_empty() or transaction in transactions or transactions.size() >= 120 or not legal(key): return false
	ranks[key] = int(ranks.get(key,0))+1
	for f in GeneRegistry.definitions()[key]["affinity"]: raw[f] += int(GeneRegistry.definitions()[key]["affinity"][f])
	transactions.append(transaction)
	for f in GeneRegistry.FORMS: interval_credit[f]=0
	behaviour_events.clear()
	draft.clear()
	return true
func record() -> Dictionary:
	return {"version":VERSION,"raw":raw.duplicate(),"ranks":ranks.duplicate(),"transactions":transactions.duplicate(),"draft":draft.duplicate(),"seed":draft_seed,"growth_policy":growth_policy,"behaviour":behaviour.duplicate(),"interval_credit":interval_credit.duplicate(),"behaviour_events":behaviour_events.duplicate()}
static func from_record(data: Variant) -> GenomeState:
	if not data is Dictionary or data.get("version") != VERSION: return null
	if not data.get("raw") is Dictionary or not data.get("ranks") is Dictionary: return null
	if data["raw"].size() != 9 or data.get("growth_policy") not in ["chosen","legacy"]: return null
	if not WorldState._number(data.get("seed")) or absf(float(data["seed"])) > 2147483647: return null
	var result := GenomeState.new()
	result.growth_policy = data["growth_policy"]
	result.draft_seed = int(data["seed"])
	var count := 0
	for key in data["ranks"]:
		var value = data["ranks"][key]
		if not WorldState._number(value) or float(value) != floorf(float(value)): return null
		if not GeneRegistry.definitions().has(key) or int(value)<1 or int(value)>int(GeneRegistry.definitions()[key]["cap"]): return null
		result.ranks[key] = int(value)
		count += int(value)
		for f in GeneRegistry.definitions()[key]["affinity"]: result.raw[f] += int(value)*int(GeneRegistry.definitions()[key]["affinity"][f])
	if data.has("behaviour"):
		if not data["behaviour"] is Dictionary or data["behaviour"].size()!=9 or not data.get("interval_credit") is Dictionary or data["interval_credit"].size()!=9: return null
		for f in GeneRegistry.FORMS:
			var value = data["behaviour"].get(f)
			var credit = data["interval_credit"].get(f)
			if not WorldState._number(value) or float(value)!=floorf(float(value)) or float(value)<0 or float(value)>2*(count+1): return null
			if not WorldState._number(credit) or float(credit)!=floorf(float(credit)) or int(credit)<0 or int(credit)>2 or float(credit)>float(value): return null
			result.behaviour[f]=int(value); result.interval_credit[f]=int(credit); result.raw[f]+=int(value)
		if not data.get("behaviour_events") is Array or data["behaviour_events"].size()>18: return null
		for event in data["behaviour_events"]:
			if not event is String or event.is_empty() or event.length()>96 or event in result.behaviour_events: return null
			result.behaviour_events.append(event)
	for f in GeneRegistry.FORMS:
		if not data["raw"].has(f) or not WorldState._number(data["raw"][f]) or float(data["raw"][f]) != float(result.raw[f]): return null
	if not AnatomyResolver.resolve(result.ranks)["legal"]: return null
	if not data.get("transactions") is Array or data["transactions"].size() != count or count > 120: return null
	for transaction in data["transactions"]:
		if not transaction is String or transaction.is_empty() or transaction.length()>96 or transaction in result.transactions: return null
		result.transactions.append(transaction)
	if not data.get("draft") is Array or data["draft"].size()>3: return null
	for key in data["draft"]:
		if not key is String or not result.legal(key) or key in result.draft: return null
		result.draft.append(key)
	return result
