class_name MutationAndLabUI
extends Control

signal mutation_selected(mutation_id: String)
signal revive_requested()
signal restart_requested()

const MUTATION_POOL: Array[Dictionary] = [
	{"id": "dorsal_overcharge", "title": "Dorsal Overcharge", "desc": "+1 Atomic Spine Stream & +10% Fire Rate"},
	{"id": "isotope_core", "title": "Isotope Core", "desc": "+25% Bullet Damage & +1 Enemy Pierce"},
	{"id": "regenerative_cells", "title": "Regenerative G-Cells", "desc": "Heal 50 HP & +30 Max HP"},
	{"id": "seismic_stomp", "title": "Seismic Shockwave", "desc": "Periodic AoE Ground Quake crushes tanks & buildings"},
	{"id": "bio_magnet", "title": "Bio-Magnetic Pulse", "desc": "+3m G-Cell Magnet Radius & +12% Move Speed"}
]

var progression: ProgressionManager
var player_ref: KaijuPlayer
var sim_ref: SimulationManager

var level_panel: PanelContainer
var level_title: Label
var card_buttons: Array[Button] = []
var current_choices: Array[String] = []
var pending_level_ups: Array[int] = []

var lab_panel: PanelContainer
var lab_summary_label: Label
var revive_btn: Button
var lab_buttons: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_level_up_modal()
	_build_lab_game_over_modal()

func _build_level_up_modal() -> void:
	level_panel = PanelContainer.new()
	level_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	level_panel.custom_minimum_size = Vector2(460, 290)
	level_panel.position -= Vector2(230, 145)
	level_panel.visible = false
	add_child(level_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	level_panel.add_child(vbox)
	
	level_title = Label.new()
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(level_title)
	
	for i in range(3):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(420, 62)
		var slot_idx: int = i
		btn.pressed.connect(func() -> void: _pick_card(slot_idx))
		vbox.add_child(btn)
		card_buttons.append(btn)

func _build_lab_game_over_modal() -> void:
	lab_panel = PanelContainer.new()
	lab_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	lab_panel.custom_minimum_size = Vector2(500, 420)
	lab_panel.position -= Vector2(250, 210)
	lab_panel.visible = false
	add_child(lab_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	lab_panel.add_child(vbox)
	
	lab_summary_label = Label.new()
	lab_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab_summary_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lab_summary_label)
	
	var upgrades: Array[Dictionary] = [
		{"key": "carapace", "name": "Carapace Plating (+20 Max HP)"},
		{"key": "meltdown", "name": "Meltdown Output (+15% Damage)"},
		{"key": "stride", "name": "Seismic Stride (+8% Speed)"},
		{"key": "magnet", "name": "Bio-Magnetism (+1.5m Magnet)"}
	]
	for u in upgrades:
		var u_key: String = u["key"]
		var u_name: String = u["name"]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(460, 42)
		btn.pressed.connect(func() -> void: _on_buy_lab_upgrade(u_key))
		vbox.add_child(btn)
		lab_buttons[u_key] = {"btn": btn, "label": u_name}
		
	revive_btn = Button.new()
	revive_btn.custom_minimum_size = Vector2(460, 46)
	revive_btn.text = "[ ATOMIC DEFIBRILLATOR: FREE 1x REVIVE (65% HP + NOVA) ]"
	revive_btn.pressed.connect(_on_revive_pressed)
	vbox.add_child(revive_btn)
	
	var restart_btn := Button.new()
	restart_btn.custom_minimum_size = Vector2(460, 48)
	restart_btn.text = "[ DEPLOY NEXT KAIJU (ENTER / SPACE) ]"
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)

func show_level_up(new_level: int) -> void:
	# Two level-ups can land in the same frame; queue the later one instead of overwriting the open draft.
	if level_panel.visible:
		pending_level_ups.append(new_level)
		return
	get_tree().paused = true
	level_title.text = "MUTATION LEVEL %d: CHOOSE EVOLUTION" % new_level
	
	var shuffled: Array[Dictionary] = MUTATION_POOL.duplicate()
	shuffled.shuffle()
	current_choices.clear()
	
	for i in range(3):
		var m: Dictionary = shuffled[i]
		current_choices.append(m["id"])
		card_buttons[i].text = "[%d] %s\n%s" % [i + 1, m["title"], m["desc"]]
		
	level_panel.visible = true

func _pick_card(slot: int) -> void:
	if not level_panel.visible or slot >= current_choices.size():
		return
	level_panel.visible = false
	mutation_selected.emit(current_choices[slot])
	if not pending_level_ups.is_empty():
		show_level_up(pending_level_ups.pop_front())
	else:
		get_tree().paused = false

func show_game_over_lab() -> void:
	# Never leave a draft open (and the tree paused) underneath the lab.
	level_panel.visible = false
	pending_level_ups.clear()
	get_tree().paused = false
	revive_btn.visible = is_instance_valid(player_ref) and not player_ref.revive_used
	_refresh_lab_ui()
	lab_panel.visible = true

func _refresh_lab_ui() -> void:
	if not is_instance_valid(progression) or not is_instance_valid(sim_ref):
		return
	lab_summary_label.text = "KAIJU DEFEATED AT DEFCON %d\nKills: %d (Best: %d) | Banked G-Cells: %d" % [
		sim_ref.defcon_level,
		sim_ref.total_kills,
		progression.best_kills,
		progression.g_cells
	]
	for u_key in lab_buttons.keys():
		var info: Dictionary = lab_buttons[u_key]
		var btn: Button = info["btn"]
		var rank: int = progression.lab_ranks[u_key]
		var cost: int = progression.get_upgrade_cost(u_key)
		btn.text = "%s [Rank %d]: Cost %d G-Cells" % [info["label"], rank, cost]
		btn.disabled = (progression.g_cells < cost)

func _on_buy_lab_upgrade(u_key: String) -> void:
	if is_instance_valid(progression) and progression.try_buy_upgrade(u_key):
		_refresh_lab_ui()

func _on_revive_pressed() -> void:
	lab_panel.visible = false
	revive_requested.emit()

func _on_restart_pressed() -> void:
	lab_panel.visible = false
	pending_level_ups.clear()
	restart_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if level_panel.visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_pick_card(0)
		elif event.keycode == KEY_2:
			_pick_card(1)
		elif event.keycode == KEY_3:
			_pick_card(2)
	elif lab_panel.visible and event.is_action_pressed("ui_accept"):
		_on_restart_pressed()
