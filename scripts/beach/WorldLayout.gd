class_name WorldLayout
extends RefCounted
## Pure world-space geography. Never consumes the gameplay random stream.
const GENERATOR_VERSION := 1
const CHUNK_SIZE := 256.0
const CONFIG = preload("res://config/world.tres")
static var HALF_WIDTH: float = maxf(2048,CONFIG.half_width)
static var INLAND: float = -maxf(2000,CONFIG.inland_depth)
static var SEED: int = CONFIG.world_seed
const DISTRICTS := ["Seabrook", "Banksia Plains", "Civic Centre", "Harbour Works", "Ironbark", "Highland Command", "Market Quarter"]
var seed_value := SEED

static func coord(at: Vector3) -> Vector2i:
	return Vector2i(floori(at.x / CHUNK_SIZE), floori(at.z / CHUNK_SIZE))

static func bounds(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c.x, c.y) * CHUNK_SIZE, Vector2.ONE * CHUNK_SIZE)

static func inside(at: Vector3, margin: float = 0.0) -> bool:
	return absf(at.x) <= HALF_WIDTH - margin and at.z >= INLAND + margin and at.z <= shore(at.x) - margin

static func shore(x: float) -> float:
	# Preserve the approved beach exactly; broad coves and terminal headlands elsewhere.
	var blend := clampf((absf(x) - 800.0) / 600.0, 0.0, 1.0)
	return 26.0 + blend * (38.0 * sin(x / 730.0) + 20.0 * sin(x / 291.0)) - pow(maxf(0.0, (absf(x) - (HALF_WIDTH-800)) / 800.0), 2.0) * 480.0

static func authored(at: Vector3) -> bool:
	return (absf(at.x) < 800.0 and at.z > -85.0) or (absf(at.x) < 430.0 and at.z > -1530.0)

func district(at: Vector3) -> int:
	var region := Vector2i(floori(at.x / 1024.0), floori(at.z / 768.0))
	var n := absi(hash("%d:%d:%d" % [seed_value, region.x, region.y]))
	# Regional anchors create connected cores, commercial rings and suburbs;
	# seeded parcels vary within that geography rather than assigning random objects.
	for port_x in [-3584.0,6656.0]:
		if Vector2((at.x-port_x)/850,(at.z+256)/620).length()<1: return 3
	if at.z > -220.0: return 0
	for base_x in [-6656.0,5632.0]:
		if Vector2((at.x-base_x)/900,(at.z+4800)/750).length()<1: return 5
	for center in [Vector2(-6144,-1792),Vector2(3072,-2816),Vector2(7168,-1536)]:
		var distance := Vector2((at.x-center.x),(at.z-center.y)*1.2).length()
		if distance<650: return 2
		if distance<1100: return 6
		if distance<1600: return 1
	if Vector2(at.x+2048,(at.z+3200)*1.2).length()<1000: return 3
	if at.z < -2300: return 4
	return 6 if n%7==0 else 1

func describe(c: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("world:%d:%d:%d:%d" % [GENERATOR_VERSION, seed_value, c.x, c.y])
	# Parcels sit between shared boundary streets. Larger facilities use one parcel.
	var center := Vector3((c.x + .5) * CHUNK_SIZE, 0, (c.y + .5) * CHUNK_SIZE)
	var kind := district(center)
	var large := kind in [3, 5]
	var count := 2 if large else (4 if kind == 4 else 9)
	for slot in range(count):
		var cols := 2 if count <= 4 else 3
		var rows := ceili(float(count) / cols)
		var at := Vector3(c.x * CHUNK_SIZE + 40 + (slot % cols + .5) * 176.0 / cols, 0,
			c.y * CHUNK_SIZE + 40 + (slot / cols + .5) * 176.0 / rows)
		at += Vector3(rng.randf_range(-7, 7), 0, rng.randf_range(-7, 7))
		if authored(at) or not inside(at, 95.0) or at.z < INLAND + 220.0: continue
		var title := "Coastal home"
		var size := Vector2(18, 17)
		var height := 5.0
		match kind:
			0: title = ["Cafe", "Hotel", "Beach shop"][slot % 3]; size = Vector2(21, 20); height = 6 + slot % 3 * 4
			1: height = 5 + slot % 3 * 2
			2: title = "Civic Tower" if slot % 3 == 0 else "Apartments"; size = Vector2(30, 27); height = 35 + rng.randf_range(0, 55)
			3: title = ["Factory", "Warehouse", "Power Station", "Container Yard", "Water Works", "Distribution Depot"][(absi(c.x+c.y)+slot)%6]; size = Vector2(62, 90); height = 18 + slot % 2 * 9
			4: title = "Farm Store"; size = Vector2(22, 27); height = 7
			5: title = "Military Hangar" if slot == 0 else "Command Centre"; size = Vector2(65, 82); height = 20
			6: title = ["Bakery", "Supermarket", "Coffee Bar"][slot % 3]; size = Vector2(32, 29); height = 8 + slot % 3 * 3
		var descriptor := {"id": "g%d:%d:%d:%d" % [GENERATOR_VERSION, c.x, c.y, slot], "position": at,
			"size": size, "height": height, "name": title, "district": kind,
			"colour": Color("c2d0bb"), "strength": 2 if height < 10 else 5,
			"hits": 6 if height < 10 else 18, "breakthrough": 5 if height < 10 else 8, "occupants": 5 if height < 10 else 8}
		WorldLandmarks.decorate(descriptor)
		result.append(descriptor)
	return result

static func road_point(at: Vector3) -> Vector3:
	if authored(at):
		return Vector3(0, 0, clampf(at.z, INLAND + 256, -27))
	var x := roundf(at.x / CHUNK_SIZE) * CHUNK_SIZE
	var z := minf(-256.0, roundf(at.z / CHUNK_SIZE) * CHUNK_SIZE)
	var candidate := Vector3(x, 0, at.z) if absf(at.x - x) < absf(at.z - z) else Vector3(at.x, 0, z)
	if at.z > -180: candidate = Vector3(at.x, 0, shore(at.x) - 53.0)
	return candidate

static func road_segments(c: Vector2i) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var x := c.x * CHUNK_SIZE
	var z := c.y * CHUNK_SIZE
	# Split at 16-unit intervals so roads stop at authored reservations and shorelines.
	for vertical in [false,true]:
		var run_start := Vector3.INF
		var run_end := Vector3.ZERO
		for i in range(16):
			var a := Vector3(x + (0.0 if vertical else i * 16.0), 0, z + (i * 16.0 if vertical else 0.0))
			var b := a + (Vector3(0, 0, 16) if vertical else Vector3(16, 0, 0))
			var mid := (a + b) * .5
			if inside(mid, 20) and mid.z <= shore(mid.x)-53 and not authored(mid):
				if not run_start.is_finite(): run_start=a
				run_end=b
			elif run_start.is_finite():
				segments.append({"a":run_start,"b":run_end})
				run_start=Vector3.INF
		if run_start.is_finite(): segments.append({"a":run_start,"b":run_end})
	return segments
