class_name CoastalHUD
extends Control
## Compact vector HUD; physical touch targets remain owned by BeachDemo.
var health := 1.0
var stamina := 1.0
var biomass := 0.0
var level := 0
var hp_text := "100 / 100"
var biomass_text := "0 / 55"
var status := "COASTAL HATCHLING"
var defcon := 5
var response_name := "LOCAL POLICE"

func update_defcon(tier: int, detail: String) -> void:
	defcon = tier
	response_name = detail
	queue_redraw()

static func panel(fill: Color, border: Color = Color("446465")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 17
	result.set_stylebox("panel", "PanelContainer", panel(Color("203b43")))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var fill := Color("294a50")
		if state == "pressed": fill = Color("417f79")
		if state == "hover": fill = Color("365f63")
		if state == "disabled": fill = Color("39494b")
		result.set_stylebox(state,"Button",panel(fill,Color("6e9e94")))
	result.set_color("font_color","Button",Color("f1e5c8"))
	result.set_color("font_color","Label",Color("f1e5c8"))
	return result

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(16,20)
	size = Vector2(286,159)

func update_state(hp: float, maximum_hp: float, energy: float, maximum_energy: float,
		food: int, cost: int, evolution: int, message: String) -> void:
	health = clampf(hp/maximum_hp,0,1)
	stamina = clampf(energy/maximum_energy,0,1)
	biomass = clampf(float(food)/cost,0,1)
	level = evolution
	hp_text = "%d / %d" % [ceili(hp),int(maximum_hp)]
	biomass_text = "%d / %d" % [food,cost]
	status = message
	queue_redraw()

func _draw() -> void:
	draw_style_box(panel(Color(.09,.19,.22,.94)),Rect2(Vector2.ZERO,size))
	var font := ThemeDB.fallback_font
	var cream := Color("f1e5c8")
	draw_string(font,Vector2(14,24),"KAIJUSTOMP",HORIZONTAL_ALIGNMENT_LEFT,-1,17,cream)
	draw_string(font,Vector2(220,24),"E%02d"%level,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("efb778"))
	var values := [health,stamina,biomass]
	var colors: Array[Color] = [Color("e69679"),Color("78c4ad"),Color("efc66c")]
	var labels := [hp_text,"%d%%"%int(stamina*100),biomass_text]
	for i in range(3):
		var y := 45.0+i*26
		var points := PackedVector2Array()
		if i == 0:
			points = PackedVector2Array([Vector2(-7,-3),Vector2(-4,-7),Vector2(0,-4),Vector2(4,-7),Vector2(7,-3),Vector2(0,6)])
		elif i == 1:
			points = PackedVector2Array([Vector2(1,-8),Vector2(-6,1),Vector2(-1,1),Vector2(-2,8),Vector2(6,-2),Vector2(1,-2)])
		else:
			points = PackedVector2Array([Vector2(0,-7),Vector2(7,0),Vector2(0,7),Vector2(-7,0)])
		for p in range(points.size()): points[p] += Vector2(22,y)
		draw_colored_polygon(points,colors[i])
		draw_style_box(panel(Color("142e35"),Color("142e35")),Rect2(40,y-5,133,9))
		if values[i] > 0:
			draw_style_box(panel(colors[i],colors[i]),Rect2(40,y-5,133*values[i],9))
		draw_string(font,Vector2(184,y+5),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,cream)
	var threat_color := Color("e8ae8a") if defcon <= 2 else (Color("efc66c") if defcon == 3 else Color("92c4b1"))
	draw_string(font,Vector2(14,127),"DEFCON %d  /  %s"%[defcon,response_name],HORIZONTAL_ALIGNMENT_LEFT,266,12,threat_color)
	draw_string(font,Vector2(14,147),status,HORIZONTAL_ALIGNMENT_LEFT,266,12,Color("b4cbc1"))
