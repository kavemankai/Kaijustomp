class_name LaunchBackdrop
extends Control
## Procedural portrait title illustration. No external texture download required.
## All geometry is CanvasItem-batched, resolution-independent and deterministic.
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _poly(points: Array[Vector2], tint: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), tint)

func _draw() -> void:
	if size.x <= 0 or size.y <= 0: return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / 540.0, size.y / 960.0))
	var sky_top := Color("071a28")
	var sky_middle := Color("164653")
	var sky_bottom := Color("d97c51")
	for i in range(48):
		var y := float(i) * 20.0
		var progress := y / 960.0
		var shade := sky_top.lerp(sky_middle, clampf(progress / .53, 0.0, 1.0)) if progress < .53 else sky_middle.lerp(sky_bottom, clampf((progress - .53) / .47, 0.0, 1.0))
		draw_rect(Rect2(0.0, y, 540.0, 21.0), shade)
	# Faint illuminated sky and the distant coastline.
	var shimmer := .04 * sin(elapsed * .55)
	draw_circle(Vector2(415, 334), 105, Color(1.0,.63,.35,.08 + shimmer))
	draw_circle(Vector2(415, 334), 67, Color("f3b77e"))
	_poly([Vector2(0,500),Vector2(150,458),Vector2(279,492),Vector2(366,451),Vector2(540,496),Vector2(540,656),Vector2(0,656)],Color("214653"))
	_poly([Vector2(0,589),Vector2(170,566),Vector2(330,593),Vector2(540,569),Vector2(540,750),Vector2(0,750)],Color("133d49"))
	# One deliberately long kaiju silhouette behind the coastal town.
	var spine := PackedVector2Array([Vector2(-25,567),Vector2(55,519),Vector2(137,540),Vector2(200,516),Vector2(265,453),Vector2(315,422),Vector2(358,430)])
	draw_polyline(spine,Color("061a24"),63,true)
	draw_polyline(spine,Color("1f5b5d"),36,true)
	_poly([Vector2(321,397),Vector2(368,385),Vector2(413,413),Vector2(398,438),Vector2(359,449),Vector2(317,430)],Color("0a232b"))
	_poly([Vector2(391,416),Vector2(414,420),Vector2(401,431)],Color("daa35b"))
	draw_circle(Vector2(377,410),5.3,Color("e9a657"))
	for i in range(5):
		var px := 75.0 + i * 55.0
		var py := 518.0 - (i % 3) * 13.0
		_poly([Vector2(px-12,py),Vector2(px,py-28),Vector2(px+16,py+3)],Color("102b32"))
	# The shoreline village: angular roofs, windows and roads.
	for i in range(14):
		var px := float(i) * 43.0 - 14.0
		var base := 679.0 + float(i % 3) * 13.0
		var height := 49.0 + float((i * 5) % 4) * 18.0
		var facade := Color("183e49") if i % 2 == 0 else Color("265561")
		draw_rect(Rect2(px, base-height, 38, height),facade)
		_poly([Vector2(px-5,base-height),Vector2(px+19,base-height-24),Vector2(px+43,base-height)],Color("102f39"))
		draw_rect(Rect2(px+10,base-height+13,10,13),Color("d9ab70"))
		draw_rect(Rect2(px+24,base-height+13,7,13),Color("96bbc0"))
	draw_rect(Rect2(0,693,540,267),Color("0a2733"))
	_poly([Vector2(0,713),Vector2(175,690),Vector2(540,735),Vector2(540,960),Vector2(0,960)],Color("123c45"))
	for i in range(10):
		var base := 741.0 + float(i) * 28.0
		draw_line(Vector2(0,base),Vector2(540,base+40),Color(1,.74,.45,.065),2.0,true)
	draw_rect(Rect2(0,825,540,135),Color(0.018,0.075,0.11,.60))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
