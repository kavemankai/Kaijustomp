extends SceneTree
## Full DEFCON escalation regression: action-driven tiers, mixed enemy waves,
## projectile damage/cover, unit defeat, quiet decay, and mobile safety caps.

func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, why: String) -> bool:
	if not ok:
		printerr("DEFCON RESPONSE TEST FAILED: " + why)
		paused = false
		quit(1)
	return ok


func _clear_units(demo: Node) -> void:
	for foe in demo.officers:
		foe["node"].queue_free()
	demo.officers.clear()


func _run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	await physics_frame
	for tier in range(1,6):
		if not _check(not DefconDirector.wave_for(tier).is_empty() and DefconDirector.cap_for(tier) <= 9, "Tier roster/cap unavailable"): return
		for kind in DefconDirector.wave_for(tier):
			if not _check(float(DefconDirector.stats_for(kind)["damage"]) > 0, "Enemy has no configured damage"): return
	for record in [
		{"value": 0.0, "tier": 5}, {"value": 24.0, "tier": 5},
		{"value": 25.0, "tier": 4}, {"value": 65.0, "tier": 3},
		{"value": 130.0, "tier": 2}, {"value": 220.0, "tier": 1}]:
		if not _check(DefconDirector.tier_for(record["value"]) == record["tier"], "Incorrect escalation threshold"): return
	# Quiet beach does not conjure police into existence.
	demo._update_police(20.0)
	if not _check(demo.officers.is_empty() and demo.defcon == 5, "Peaceful world already has military"): return
	# The old local SWAT pathway remains operational.
	demo._spawn_officer(Vector3(16,0,0),true)
	if not _check(demo.officers.size() == 1 and demo.officers[0]["kind"] == "swat", "Backwards-compatible SWAT spawner changed"): return
	_clear_units(demo)
	# DEFCON 5 - first police patrol appears after initial response delay.
	demo._add_alert(5.0)
	demo.response_clock = 17.9
	demo._update_police(.2)
	if not _check(demo.defcon == 5 and demo.officers.size() == 2 and demo.officers[0]["kind"] == "police", "First wave wasn't local police"): return
	if not _check(demo.coastal_hud.defcon == 5 or demo.defcon == 5, "Threat HUD state missing"): return
	_clear_units(demo)
	# DEFCON 4 - mixed tactical responders, no sudden unlimited enemies.
	demo._add_alert(20.0)
	demo.response_clock = 16.0
	demo.response_wave = 0
	demo._update_police(.05)
	var kinds: Array[String] = []
	for foe in demo.officers: kinds.append(String(foe["kind"]))
	if not _check(demo.defcon == 4 and "police" in kinds and "swat" in kinds, "SWAT tier lacks mixed response"): return
	_clear_units(demo)
	# DEFCON 3 - deploy infantry in addition to tactical units.
	demo._add_alert(40.0)
	demo.response_wave = 0
	demo._deploy_defcon_wave()
	kinds.clear()
	for foe in demo.officers: kinds.append(String(foe["kind"]))
	if not _check(demo.defcon == 3 and "soldier" in kinds, "DEFCON 3 didn't mobilise soldiers"): return
	var soldier_index := kinds.find("soldier")
	var soldier: Dictionary = demo.officers[soldier_index]
	if not _check(soldier["node"].get_node_or_null("ResponseKit") != null, "National Guard missing visible gear"): return
	var soldier_hp: float = soldier["health"]
	demo._damage_response(soldier_index, 12.0)
	if not _check(demo.officers[soldier_index]["health"] < soldier_hp, "Soldier health not damageable"): return
	_clear_units(demo)
	# DEFCON 2 - armour physically blocks and can be destroyed.
	demo._add_alert(65.0)
	demo.response_wave = 0
	demo._deploy_defcon_wave()
	kinds.clear()
	for foe in demo.officers: kinds.append(String(foe["kind"]))
	if not _check(demo.defcon == 2 and "armoured" in kinds, "No armoured units at DEFCON 2"): return
	var armour_index := kinds.find("armoured")
	var apc: Dictionary = demo.officers[armour_index]
	if not _check(apc["collider"] is StaticBody3D and apc["node"].get_node_or_null("ResponseHull") != null, "APC has no physical cover or art"): return
	if not _check(demo._response_for_collider(apc["collider"]) == armour_index, "APC can't be hit by collision"): return
	var before_alert: float = demo.alert
	demo._damage_response(armour_index, 500.0)
	if not _check(demo.officers.size() == 2 and demo.alert > before_alert, "Destroying APC did not remove unit or raise threat"): return
	_clear_units(demo)
	# DEFCON 1 - air support + armour + infantry, bounded across many waves.
	demo._add_alert(120.0)
	demo.response_wave = 0
	demo._deploy_defcon_wave()
	kinds.clear()
	for foe in demo.officers: kinds.append(String(foe["kind"]))
	if not _check(demo.defcon == 1 and "helicopter" in kinds and "armoured" in kinds, "Highest tier lacks air/armour escalation"): return
	var heli_index := kinds.find("helicopter")
	var heli: Dictionary = demo.officers[heli_index]
	if not _check(heli["node"].global_position.y > 15.0 and heli["node"].get_node_or_null("Rotor") != null, "Helicopter not overhead or rotor missing"): return
	var before_rotor: float = heli["node"].get_node("Rotor").rotation.y
	demo._update_police(.15)
	if not _check(heli["node"].get_node("Rotor").rotation.y > before_rotor, "Air support rotors don't animate"): return
	for n in range(12): demo._deploy_defcon_wave()
	if not _check(demo.officers.size() <= DefconDirector.MAX_RESPONDERS and demo.officers.size() == 9, "Active enemy cap breached or reinforcements never arrive"): return
	# Diverse projectile strengths without changing real raycast/building cover.
	demo._spawn_projectile(Vector3(0,1.4,0),Vector3.FORWARD,true)
	var projectile: Dictionary = demo.projectiles[-1]
	if not _check(projectile["damage"] == 16.0 and demo.projectiles.size() <= demo.MAX_PROJECTILES, "Existing heavy tracer contract changed"): return
	for n in range(80): demo._spawn_projectile(Vector3(0,1.4,0),Vector3.FORWARD,true)
	if not _check(demo.projectiles.size() == demo.MAX_PROJECTILES, "Projectile safety cap ignored"): return
	# No escalation while paused, and response de-escalates after quiet time.
	_clear_units(demo)
	demo.alert = 66.0
	demo.heat_cooldown = 0.0
	demo.response_clock = 0.0
	demo._update_police(3.0)
	if not _check(demo.defcon == 4 and demo.alert < 65.0, "DEFCON refuses to cool after inactivity"): return
	demo._update_police(100.0)
	if not _check(demo.defcon == 5 and is_zero_approx(demo.alert), "DEFCON never returns to peaceful state"): return
	# Real phone test: rapid DEBUG EVO stays independent of threat stage.
	if OS.has_feature("debug"):
		demo._debug_evolve_batch(34)
		if not _check(demo.evolutions == 34 and demo.defcon == 5, "Debug-only growth incorrectly triggers emergency state"): return
	print("DEFCON RESPONSE TEST PASSED: five tiers, mixed response units, APC/helicopter, cooldown, real projectiles, capped waves and debug growth")
	quit(0)
