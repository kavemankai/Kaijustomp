class_name ProgressionManager
extends Node

const SAVE_PATH: String = "user://kaiju_save.cfg"

var g_cells: int = 0
var best_kills: int = 0
var apex_pass_unlocked: bool = false

var lab_ranks: Dictionary = {
	"carapace": 0,  # +20 Max HP per rank
	"meltdown": 0,  # +15% Bullet Damage per rank
	"stride": 0,    # +8% Move Speed per rank
	"magnet": 0     # +1.5m Pickup Magnet Radius per rank
}

func _ready() -> void:
	load_data()

func _notification(what: int) -> void:
	# G-cells are banked in memory during a run; flush on app pause or close so a mobile OS kill loses nothing.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("economy", "g_cells", g_cells)
	cfg.set_value("economy", "best_kills", best_kills)
	cfg.set_value("economy", "apex_pass_unlocked", apex_pass_unlocked)
	for key in lab_ranks.keys():
		cfg.set_value("lab", key, lab_ranks[key])
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	g_cells = int(cfg.get_value("economy", "g_cells", 0))
	best_kills = int(cfg.get_value("economy", "best_kills", 0))
	apex_pass_unlocked = bool(cfg.get_value("economy", "apex_pass_unlocked", false))
	for key in lab_ranks.keys():
		lab_ranks[key] = int(cfg.get_value("lab", key, 0))

func add_g_cells(amount: int) -> void:
	var mult: int = 2 if apex_pass_unlocked else 1
	g_cells += amount * mult

func record_kills(kills: int) -> void:
	if kills > best_kills:
		best_kills = kills
	save_data()

func get_upgrade_cost(upgrade_key: String) -> int:
	var rank: int = lab_ranks.get(upgrade_key, 0)
	return 25 + rank * 35

func try_buy_upgrade(upgrade_key: String) -> bool:
	if not lab_ranks.has(upgrade_key):
		return false
	var cost: int = get_upgrade_cost(upgrade_key)
	if g_cells < cost:
		return false
	g_cells -= cost
	lab_ranks[upgrade_key] += 1
	save_data()
	return true

func get_max_hp_bonus() -> float:
	return float(lab_ranks["carapace"]) * 20.0

func get_damage_multiplier() -> float:
	return 1.0 + float(lab_ranks["meltdown"]) * 0.15

func get_speed_multiplier() -> float:
	return 1.0 + float(lab_ranks["stride"]) * 0.08

func get_magnet_bonus() -> float:
	return float(lab_ranks["magnet"]) * 1.5
