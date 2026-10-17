class_name WorldState
extends RefCounted
## Compact deltas only. JSON never contains generated geometry or live node references.
const VERSION := 1
var objects: Dictionary = {}
var events: Dictionary = {}
var player: Dictionary = {}
var seed_value := WorldLayout.SEED
var writable := true
var recovery := "new"
var path := "user://persistent-world-v1.json"

func remember(b: Dictionary) -> void:
	if String(b.get("id", "")).is_empty(): return
	if bool(b.get("destroyed", false)) or float(b.get("hits", 0)) != float(b.get("max_hits", 0)) or int(b.get("hidden", 0)) != int(b.get("base_occupants", 0)):
		var delta := {"destroyed": b.get("destroyed", false), "hits": b.get("hits", 0),
			"hidden": b.get("hidden", 0), "reward_claimed": b.get("reward_claimed", false)}
		delta.make_read_only()
		objects[b["id"]]=delta

func apply(b: Dictionary) -> void:
	var delta: Dictionary = objects.get(b["id"], {})
	for key in delta: b[key] = delta[key]

func document() -> Dictionary:
	return {"version": VERSION, "generator": WorldLayout.GENERATOR_VERSION, "seed": seed_value,
		"objects": objects, "events": events, "player": player}

func snapshot() -> Dictionary:
	# Delta records are immutable and replaced as a unit. Share their read-only
	# values across workers, copying only the index and small player/event records.
	var result := document()
	var index := objects.duplicate()
	for record in index.values():
		if not record.is_read_only(): record.make_read_only()
	result["objects"]=index
	result["events"]=events.duplicate(true)
	result["player"]=player.duplicate(true)
	return result

func read_save() -> bool:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate)) != OK: continue
		var parsed = parser.data
		if not parsed is Dictionary: continue
		var version := int(parsed.get("version", -1))
		if version > VERSION or int(parsed.get("generator", -1)) > WorldLayout.GENERATOR_VERSION:
			writable = false
			recovery = "unsupported"
			return false
		# v0 prototype used the same delta representation without an events field.
		if version not in [0, VERSION] or not _valid_document(parsed): continue
		if not parsed.get("events", {}) is Dictionary: continue
		objects = parsed["objects"]
		for record in objects.values(): record.make_read_only()
		player = parsed["player"]
		events = parsed.get("events", {})
		seed_value = int(parsed.get("seed", WorldLayout.SEED))
		recovery = "backup" if candidate.ends_with(".bak") else ("migrated" if version == 0 else "loaded")
		return true
	if FileAccess.file_exists(path):
		# Preserve damaged user data rather than replacing it with a fresh run.
		writable = false
		recovery = "corrupt"
	return false

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _valid_document(data: Dictionary) -> bool:
	if not data.get("objects") is Dictionary or not data.get("player") is Dictionary: return false
	if not _number(data.get("seed",WorldLayout.SEED)): return false
	for id in data["objects"]:
		var delta = data["objects"][id]
		if not id is String or not delta is Dictionary: return false
		for key in delta:
			if key in ["hits","hidden"]:
				if not _number(delta[key]): return false
			elif key in ["destroyed","reward_claimed"]:
				if not delta[key] is bool: return false
			else: return false
	var p: Dictionary = data["player"]
	if p.has("position"):
		if not p["position"] is Array or p["position"].size()!=3: return false
		for n in p["position"]:
			if not _number(n): return false
	if p.has("mutations"):
		if not p["mutations"] is Dictionary: return false
		for id in p["mutations"]:
			if id not in ["armour","strength","speed","stamina","health","jaw","regen","cocoon","metamorphosis"]: return false
			if not _number(p["mutations"][id]) or float(p["mutations"][id])<0 or float(p["mutations"][id])>10000: return false
	if p.has("history"):
		if not p["history"] is Array: return false
		for entry in p["history"]:
			if not entry is Dictionary: return false
			for key in ["step","growth_milestone"]:
				if not _number(entry.get(key)): return false
			for key in ["mutation_id","label","form"]:
				if not entry.get(key) is String: return false
			if not entry.get("size_changed") is bool: return false
	for key in p:
		if key not in ["position","mutations","history","evacuations"] and not _number(p[key]): return false
	if p.has("evacuations"):
		if not p["evacuations"] is Array: return false
		for event in p["evacuations"]:
			if not event is Dictionary: return false
			for key in ["center","half"]:
				if not event.get(key) is Array or event[key].size()!=2: return false
				for n in event[key]:
					if not _number(n): return false
			for key in ["remaining","released"]:
				if not _number(event.get(key)) or float(event[key])<0: return false
	var events = data.get("events",{})
	if not events is Dictionary: return false
	var vehicles = events.get("vehicles",{})
	if not vehicles is Dictionary: return false
	for id in vehicles:
		var car = vehicles[id]
		if not car is Dictionary or not car.get("destroyed") is bool or not _number(car.get("hits")): return false
	return true

func write_save() -> bool:
	if not writable: return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(document()))
	file.flush()
	file.close()
	if not JSON.parse_string(FileAccess.get_file_as_string(temp)) is Dictionary: return false
	var absolute := ProjectSettings.globalize_path(path)
	# Never replace the known-good backup with the corrupt file we recovered from.
	if FileAccess.file_exists(path) and recovery != "backup":
		if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK: return false
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), absolute)
	if err == OK: recovery = "loaded"
	return err == OK
