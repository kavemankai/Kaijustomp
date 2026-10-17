class_name DefconDirector
extends RefCounted
## Public emergency response: DEFCON 5 is calm; DEFCON 1 is the full
## military response. Alert is earned by actions, and decays after quiet time.
const ALERT_BANDS := [0.0, 25.0, 65.0, 130.0, 220.0]
const MAX_RESPONDERS := 9
const COOLDOWN_DELAY := 18.0
const PASSIVE_DECAY := 0.75

static func tier_for(alert: float) -> int:
	if alert >= ALERT_BANDS[4]: return 1
	if alert >= ALERT_BANDS[3]: return 2
	if alert >= ALERT_BANDS[2]: return 3
	if alert >= ALERT_BANDS[1]: return 4
	return 5

static func name_for(tier: int) -> String:
	match tier:
		5: return "LOCAL POLICE"
		4: return "TACTICAL RESPONSE"
		3: return "NATIONAL GUARD"
		2: return "ARMOURED SUPPORT"
		_: return "AIR SUPPORT"

static func interval_for(tier: int) -> float:
	match tier:
		5: return 18.0
		4: return 16.0
		3: return 13.0
		2: return 11.0
		_: return 9.0

static func cap_for(tier: int) -> int:
	match tier:
		5: return 2
		4: return 4
		3: return 6
		2: return 7
		_: return MAX_RESPONDERS

static func wave_for(tier: int) -> Array[String]:
	match tier:
		5: return ["police", "police"]
		4: return ["police", "swat"]
		3: return ["swat", "soldier", "soldier"]
		2: return ["soldier", "armoured", "soldier"]
		_: return ["soldier", "armoured", "helicopter"]

static func stats_for(kind: String) -> Dictionary:
	match kind:
		"police": return {"health": 24.0, "damage": 10.0, "rate": 2.0, "range": 21.0, "speed": 3.0}
		"swat": return {"health": 55.0, "damage": 16.0, "rate": 1.3, "range": 29.0, "speed": 3.8}
		"soldier": return {"health": 85.0, "damage": 21.0, "rate": 1.1, "range": 42.0, "speed": 3.3}
		"armoured": return {"health": 280.0, "damage": 35.0, "rate": 3.0, "range": 65.0, "speed": 2.0}
		"helicopter": return {"health": 180.0, "damage": 27.0, "rate": 1.6, "range": 95.0, "speed": 5.2}
	return stats_for("police")

static func is_vehicle(kind: String) -> bool:
	return kind in ["armoured", "helicopter"]
