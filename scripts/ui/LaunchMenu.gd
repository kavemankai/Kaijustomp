class_name LaunchMenu
extends Control
## First-run title scene. BeachDemo is created only after a deliberate player action.
const GAME_SCENE := "res://scenes/BeachDemo.tscn"
const SAVE_PATH := "user://persistent-world-v1.json"
const SETTINGS_PATH := "user://launch_settings.cfg"

var save_path := SAVE_PATH
var background: LaunchBackdrop
var title_group: VBoxContainer
var menu_card: PanelContainer
var menu_stack: VBoxContainer
var continue_button: Button
var new_button: Button
var status_label: Label
var intro: Control
var settings_dialog: AcceptDialog
var credits_dialog: AcceptDialog
var new_confirm: ConfirmationDialog
var problem_dialog: AcceptDialog
var sound_slider: HSlider
var splash_finished := false
var navigating := false
var existing_world := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	background = LaunchBackdrop.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_build_logo()
	_build_actions()
	_build_dialogs()
	_build_intro()
	size_changed.connect(_layout)
	_layout()
	_refresh_save()
	_begin_intro.call_deferred()

func _new_label(value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color",color)
	result.add_theme_color_override("font_shadow_color",Color("061822"))
	result.add_theme_constant_override("shadow_offset_x",2)
	result.add_theme_constant_override("shadow_offset_y",3)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _build_logo() -> void:
	title_group = VBoxContainer.new()
	title_group.alignment = BoxContainer.ALIGNMENT_CENTER
	title_group.add_theme_constant_override("separation",-10)
	title_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_group)
	title_group.add_child(_new_label("K A I J U", 52, Color("e9ece1")))
	title_group.add_child(_new_label("S T O M P", 62, Color("ffc377")))
	title_group.add_child(_new_label("EVOLVE  /  DEVOUR  /  ENDURE", 15, Color("c9ded8")))

func _button(title: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(0,52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size",19 if primary else 17)
	button.add_theme_color_override("font_color",Color("0c2831") if primary else Color("e5ecdf"))
	button.add_theme_color_override("font_hover_color",Color("0b252f") if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color",Color("849ba1"))
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color("efb46e") if primary else Color("194451")
	flat.border_color=Color("ffde9c") if primary else Color("4e7f84")
	flat.set_border_width_all(2)
	flat.set_corner_radius_all(10)
	flat.content_margin_left=14
	flat.content_margin_right=14
	var hovered := flat.duplicate() as StyleBoxFlat
	hovered.bg_color = Color("ffd18b") if primary else Color("2b6671")
	var pressed := flat.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("dc9e5e") if primary else Color("153642")
	button.add_theme_stylebox_override("normal",flat)
	button.add_theme_stylebox_override("hover",hovered)
	button.add_theme_stylebox_override("pressed",pressed)
	button.add_theme_stylebox_override("focus",hovered)
	button.add_theme_stylebox_override("disabled",pressed)
	return button

func _build_actions() -> void:
	menu_card = PanelContainer.new()
	add_child(menu_card)
	var panel := StyleBoxFlat.new()
	panel.bg_color=Color(0.025,0.10,0.15,.88)
	panel.border_color=Color(0.35,.56,.55,.62)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(17)
	panel.shadow_color=Color(0,0,0,.35)
	panel.shadow_size=12
	menu_card.add_theme_stylebox_override("panel",panel)
	var inset:=MarginContainer.new()
	for key in ["margin_left","margin_right"]:
		inset.add_theme_constant_override(key,19)
	for key in ["margin_top","margin_bottom"]:
		inset.add_theme_constant_override(key,18)
	menu_card.add_child(inset)
	menu_stack=VBoxContainer.new()
	menu_stack.add_theme_constant_override("separation",9)
	inset.add_child(menu_stack)
	continue_button = _button("CONTINUE",true)
	continue_button.pressed.connect(_continue_game)
	menu_stack.add_child(continue_button)
	new_button = _button("NEW WORLD")
	new_button.pressed.connect(_request_new)
	menu_stack.add_child(new_button)
	var settings_button := _button("SETTINGS")
	settings_button.pressed.connect(func() -> void: settings_dialog.popup_centered(Vector2i(390,240)))
	menu_stack.add_child(settings_button)
	var credits_button := _button("CREDITS")
	credits_button.pressed.connect(func() -> void: credits_dialog.popup_centered(Vector2i(420,260)))
	menu_stack.add_child(credits_button)
	var exit_button := _button("EXIT")
	exit_button.pressed.connect(func() -> void: get_tree().quit())
	exit_button.visible=not OS.has_feature("mobile")
	menu_stack.add_child(exit_button)
	status_label=_new_label("CHECKING SAVE...",12,Color("a6c3bc"))
	status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	menu_stack.add_child(status_label)

func _build_dialogs() -> void:
	new_confirm=ConfirmationDialog.new()
	new_confirm.title="START A NEW WORLD?"
	new_confirm.dialog_text="This will start a new coastal world. Your previous save and recovery copy will be archived before replacement. Continue?"
	new_confirm.get_ok_button().text="ARCHIVE AND START"
	new_confirm.confirmed.connect(_start_new)
	add_child(new_confirm)
	settings_dialog=AcceptDialog.new()
	settings_dialog.title="SETTINGS"
	settings_dialog.dialog_text="MASTER SOUND\n\n\nVolume changes apply to gameplay and are saved on this device."
	settings_dialog.min_size=Vector2i(390,245)
	settings_dialog.get_ok_button().text="DONE"
	add_child(settings_dialog)
	sound_slider=HSlider.new()
	sound_slider.position=Vector2(28,85)
	sound_slider.size=Vector2(320,32)
	sound_slider.min_value=0.0
	sound_slider.max_value=100.0
	sound_slider.step=5.0
	sound_slider.value_changed.connect(_volume_changed)
	settings_dialog.add_child(sound_slider)
	var prefs := ConfigFile.new()
	if prefs.load(SETTINGS_PATH)==OK:
		sound_slider.set_value_no_signal(clampf(float(prefs.get_value("audio","master",85.0)),0.0,100.0))
	_apply_volume(sound_slider.value)
	credits_dialog=AcceptDialog.new()
	credits_dialog.title="CREDITS"
	credits_dialog.dialog_text="KAIJUSTOMP\n\nA retro low-poly creature evolution game.\n\nBuilt with Godot 4.5.\n\nA changing organism. A persistent coastal world."
	credits_dialog.min_size=Vector2i(380,230)
	add_child(credits_dialog)
	problem_dialog=AcceptDialog.new()
	problem_dialog.title="CANNOT START"
	add_child(problem_dialog)

func _build_intro() -> void:
	intro=Control.new()
	intro.mouse_filter=Control.MOUSE_FILTER_STOP
	intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(intro)
	var shade:=ColorRect.new()
	shade.color=Color("081c29")
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.add_child(shade)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter=Control.MOUSE_FILTER_IGNORE
	intro.add_child(center)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",12)
	center.add_child(stack)
	stack.add_child(_new_label("K A I J U S T O M P",36,Color("ffca85")))
	stack.add_child(_new_label("THE COAST WILL REMEMBER",14,Color("acced0")))
	stack.add_child(_new_label("TAP TO CONTINUE",11,Color("789a9f")))
	intro.gui_input.connect(_skip_intro)
	menu_card.modulate.a=0.0
	title_group.modulate.a=0.0

func _layout() -> void:
	if not is_instance_valid(menu_card): return
	var w:=size.x
	var h:=size.y
	if w<=0 or h<=0: return
	var landscape := w > h * 1.2
	if landscape:
		title_group.position=Vector2(w*.06,h*.22)
		title_group.size=Vector2(w*.42,h*.47)
		menu_card.position=Vector2(w*.53,maxf(12.0,(h-385.0)*.5))
		menu_card.size=Vector2(minf(w*.42,365.0),385)
	else:
		var logo_y := maxf(42.0,h*.13)
		title_group.position=Vector2(14,logo_y)
		title_group.size=Vector2(w-28,minf(200,h*.23))
		var card_height:=minf(380.0,h*.50)
		var card_w:=minf(382.0,w-32.0)
		menu_card.position=Vector2((w-card_w)*.5,minf(h-card_height-20,h*.52))
		menu_card.size=Vector2(card_w,card_height)

func _begin_intro() -> void:
	await get_tree().create_timer(1.55).timeout
	if is_inside_tree(): _finish_intro()

func _skip_intro(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_finish_intro()

func _finish_intro() -> void:
	if splash_finished: return
	splash_finished=true
	continue_button.grab_focus() if existing_world else new_button.grab_focus()
	var fade := create_tween().set_parallel(true)
	fade.tween_property(intro,"modulate:a",0.0,.42)
	fade.tween_property(menu_card,"modulate:a",1.0,.42)
	fade.tween_property(title_group,"modulate:a",1.0,.42)
	fade.finished.connect(func() -> void: if is_instance_valid(intro): intro.hide())

func _refresh_save() -> void:
	var state := WorldState.new()
	state.path=save_path
	existing_world=state.read_save()
	continue_button.disabled=not existing_world
	if existing_world:
		status_label.text="WORLD READY TO RESUME" if state.recovery!="backup" else "RECOVERY SAVE READY"
	elif state.recovery in ["corrupt","unsupported"]:
		status_label.text="SAVE REQUIRES RECOVERY  ·  ORIGINAL PRESERVED"
	else:
		status_label.text="NO SAVED WORLD  ·  START A NEW ONE"

func _continue_game() -> void:
	if navigating or not existing_world: return
	_go_game()

func _request_new() -> void:
	if navigating: return
	if FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak"):
		new_confirm.popup_centered(Vector2i(430,230))
	else:
		_start_new()

func _start_new() -> void:
	if navigating: return
	var stamp := str(int(Time.get_unix_time_from_system()))
	# Preserve BOTH primary and backup before touching either file.
	for extension in ["",".bak"]:
		var existing:=save_path+extension
		if not FileAccess.file_exists(existing): continue
		var archive:=save_path+".archive-"+stamp+extension
		var outcome:=DirAccess.copy_absolute(ProjectSettings.globalize_path(existing),ProjectSettings.globalize_path(archive))
		if outcome!=OK:
			_problem("Could not safely archive the existing world. No saves were deleted.")
			return
	for extension in ["",".bak"]:
		var existing:=save_path+extension
		if FileAccess.file_exists(existing):
			if DirAccess.remove_absolute(ProjectSettings.globalize_path(existing))!=OK:
				_problem("World was archived but the old save could not be cleared. Retry after checking device storage.")
				_refresh_save()
				return
	_go_game()

func _go_game() -> void:
	navigating=true
	get_tree().paused=false
	var err:=get_tree().change_scene_to_file(GAME_SCENE)
	if err!=OK:
		navigating=false
		_problem("The game scene could not be loaded. Error code: "+str(err))

func _problem(message: String) -> void:
	problem_dialog.dialog_text=message
	problem_dialog.popup_centered(Vector2i(430,180))

func _apply_volume(percent: float) -> void:
	var master:=AudioServer.get_bus_index("Master")
	if master>=0:
		AudioServer.set_bus_volume_db(master,linear_to_db(maxf(.0001,percent/100.0)))
		AudioServer.set_bus_mute(master,percent<.01)

func _volume_changed(percent: float) -> void:
	_apply_volume(percent)
	var prefs:=ConfigFile.new()
	prefs.set_value("audio","master",percent)
	prefs.save(SETTINGS_PATH)

func _unhandled_input(event: InputEvent) -> void:
	if not splash_finished and event is InputEventKey and event.pressed:
		_finish_intro()
	elif splash_finished and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and not navigating:
		_request_new() if not existing_world else continue_button.grab_focus()
