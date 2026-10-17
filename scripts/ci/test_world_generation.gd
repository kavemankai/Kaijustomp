extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,reason: String) -> void:
	if not ok:
		failed = true
		printerr("WORLD GENERATION TEST FAILED: "+reason)
func run() -> void:
	var layout := WorldLayout.new()
	check(WorldLayout.coord(Vector3(-.01,0,-256.01))==Vector2i(-1,-2),"Negative-coordinate floor division")
	var first := {}
	var districts := {}
	var ids := {}
	var coords: Array[Vector2i] = []
	for x in range(-38,39,3):
		coords.append(Vector2i(x,-1))
		for z in range(-22,0,2): coords.append(Vector2i(x,z))
	for c in coords:
		var described := layout.describe(c)
		first[c] = var_to_str(described)
		for d in described:
			check(not ids.has(d["id"]),"Duplicate structure ID")
			ids[d["id"]] = true
			districts[d["district"]] = true
			var p: Vector3 = d["position"]
			check(not WorldLayout.authored(p),"Generated structure overwrites authored world")
			var half := Vector2(d["size"])*.5
			var dx := fposmod(p.x,256)
			var dz := fposmod(p.z,256)
			check(dx-half.x>8 and dx+half.x<248 and dz-half.y>8 and dz+half.y<248,"Parcel crosses a shared road or intersection")
	coords.reverse()
	for c in coords: check(var_to_str(layout.describe(c))==first[c],"Visitation order changes world")
	layout.seed_value += 1
	check(var_to_str(layout.describe(coords[0])) != first[coords[0]],"Seed has no effect")
	check(districts.size()==7,"Missing district families")
	check(ids.size()>1000,"World is an empty chunk demonstration")
	# Each shared street has exactly matching world endpoints at the next chunk.
	for c in [Vector2i(8,-10),Vector2i(-12,-18),Vector2i(20,-6)]:
		var roads := WorldLayout.road_segments(c)
		var next := WorldLayout.road_segments(c+Vector2i.RIGHT)
		var endpoint := Vector3((c.x+1)*256,0,c.y*256)
		check(roads.any(func(r): return r["b"]==endpoint),"Road fails to reach chunk edge")
		check(next.any(func(r): return r["a"]==endpoint),"Adjacent road edge disagrees")
	check(WorldLayout.HALF_WIDTH*2==20000 and WorldLayout.INLAND==-6000,"Wrong finite world dimensions")
	if not failed: print("WORLD GENERATION TEST PASSED: deterministic seeds/order, negative chunks, unique IDs, seven districts, road seams and >1000 occupied parcels")
	quit(1 if failed else 0)
