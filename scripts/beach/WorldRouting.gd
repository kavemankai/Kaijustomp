class_name WorldRouting
extends RefCounted
## Local grid routing uses descriptors only: intervening chunks need no live physics.
static func route(start: Vector3, target: Vector3, world: WorldStreaming, clearance: float) -> PackedVector3Array:
	var grid := AStarGrid2D.new()
	grid.cell_size = Vector2(16,16)
	grid.offset = Vector2(8,8)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	var origin := Vector2i(floori(minf(start.x,target.x)/16)-8,floori(minf(start.z,target.z)/16)-8)
	var end := Vector2i(ceili(maxf(start.x,target.x)/16)+8,ceili(maxf(start.z,target.z)/16)+8)
	grid.region = Rect2i(origin,end-origin+Vector2i.ONE)
	grid.update()
	var rect := Rect2(Vector2(origin)*16,Vector2(grid.region.size)*16)
	for b in world.descriptors_in_rect(rect):
		if b.get("destroyed",false): continue
		var p: Vector3 = b["position"]
		var half: Vector2 = b["half"]
		var a := Vector2i(floori((p.x-half.x-clearance-8)/16),floori((p.z-half.y-clearance-8)/16))
		var z := Vector2i(ceili((p.x+half.x+clearance)/16),ceili((p.z+half.y+clearance)/16))
		for x in range(maxi(origin.x,a.x),mini(end.x,z.x)+1):
			for y in range(maxi(origin.y,a.y),mini(end.y,z.y)+1): grid.set_point_solid(Vector2i(x,y))
	for x in range(origin.x,end.x+1):
		for y in range(origin.y,end.y+1):
			if not WorldLayout.inside(Vector3(x*16+8,0,y*16+8),clearance): grid.set_point_solid(Vector2i(x,y))
	var from := Vector2i(floori(start.x/16),floori(start.z/16))
	var to := Vector2i(floori(target.x/16),floori(target.z/16))
	grid.set_point_solid(from,false)
	# Giants may straddle buildings: approach the nearest reachable perimeter.
	if grid.is_point_solid(to):
		var found := false
		for ring in range(1,9):
			for dx in range(-ring,ring+1):
				for dy in range(-ring,ring+1):
					var candidate := to+Vector2i(dx,dy)
					if grid.region.has_point(candidate) and not grid.is_point_solid(candidate):
						to = candidate
						found = true
						break
				if found: break
			if found: break
	var path := grid.get_point_path(from,to,true)
	var result := PackedVector3Array()
	for point in path: result.append(Vector3(point.x,0,point.y))
	return result
