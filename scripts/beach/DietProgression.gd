class_name DietProgression
extends RefCounted
## Diet depends on visual/body scale, not a fixed evolution number. Humans are
## the same physical height while the creature continues to grow. The cutoff
## is a tuning value: inspect upright grab at E28 vs E34 on a real phone.
const HUMAN_GRAB_SCALE_LIMIT := 3.35
const CAR_FEED_SCALE_START := 2.45

static func can_grab_people(scale: float) -> bool:
	return scale <= HUMAN_GRAB_SCALE_LIMIT

static func can_feed_on_cars(scale: float) -> bool:
	return scale >= CAR_FEED_SCALE_START

static func can_feed_on_structures(scale: float) -> bool:
	return scale > HUMAN_GRAB_SCALE_LIMIT

static func car_biomass(scale: float) -> int:
	if not can_feed_on_cars(scale):
		return 0
	# A crushed car provides meaningful fuel in the first upright phase.
	return 75

static func structure_biomass(scale: float, name: String, footprint: Vector2) -> int:
	if not can_feed_on_structures(scale):
		return 0
	# Bigger premises carry more resources. Small kiosks remain worthwhile
	# to destroy, but do not feed a city-sized creature efficiently.
	var floor_area := footprint.x * footprint.y
	var value := maxi(25, roundi(floor_area * .85))
	if name in ["Supermarket", "Hardware Store", "Hotel", "Apartments"]:
		value = roundi(float(value) * 1.45)
	return mini(value, 900)

static func diet_label(scale: float) -> String:
	if can_feed_on_structures(scale):
		return "BUILDINGS + CARS"
	if can_feed_on_cars(scale):
		return "PEOPLE + CARS"
	return "PEOPLE"
