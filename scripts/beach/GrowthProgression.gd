class_name GrowthProgression
extends RefCounted
## Deliberately sparse body-size milestones. Ordinary evolution is still fast
## and provides one mutation; size and posture only change at these steps.
## Levels 0-4 remain the starting small quadruped.
const MILESTONES := [5, 10, 16, 22, 28, 34]
const SCALE_FACTORS := [1.20, 1.24, 1.28, 1.32, 1.24, 1.20]
const REPEAT_EVERY := 6
const REPEAT_FACTOR := 1.16
const UPRIGHT_LEVEL := 22

static func stage_for(level: int) -> int:
	if level <= 0:
		return 0
	var stage := 0
	for milestone in MILESTONES:
		if level >= int(milestone):
			stage += 1
	if level > MILESTONES[MILESTONES.size() - 1]:
		stage += int((level - MILESTONES[MILESTONES.size() - 1]) / REPEAT_EVERY)
	return stage

static func is_growth_step(level: int) -> bool:
	return level > 0 and stage_for(level) > stage_for(level - 1)

static func factor_for(level: int) -> float:
	if not is_growth_step(level):
		return 1.0
	var stage := stage_for(level)
	if stage <= SCALE_FACTORS.size():
		return float(SCALE_FACTORS[stage - 1])
	return REPEAT_FACTOR

static func target_scale(level: int) -> float:
	var size := 1.0
	for step in range(1, level + 1):
		size *= factor_for(step)
	return size

static func upright_for(level: int) -> bool:
	return level >= UPRIGHT_LEVEL

static func form_name(level: int) -> String:
	if level >= UPRIGHT_LEVEL:
		return "Upright kaiju"
	if level >= 16:
		return "Heavy quadruped"
	if level >= 10:
		return "Large quadruped"
	if level >= 5:
		return "Growing quadruped"
	return "Coastal hatchling"

static func next_growth_level(level: int) -> int:
	for m in MILESTONES:
		if int(m) > level:
			return int(m)
	var final_level: int = MILESTONES[MILESTONES.size() - 1]
	return final_level + (int((maxi(0, level - final_level) / REPEAT_EVERY)) + 1) * REPEAT_EVERY
