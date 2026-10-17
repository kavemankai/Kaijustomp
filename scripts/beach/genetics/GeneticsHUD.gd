class_name GeneticsHUD
extends Control
var model: BeachGenetics
var button: Button
var summary: Label
var dialog: AcceptDialog
var reset_dialog: ConfirmationDialog
var details: RichTextLabel
var search: LineEdit
var entries: ItemList
var focus_picker: OptionButton
var enable_button: Button
var stance_button: Button
var traverse_button: Button
var ascend_button: Button
var descend_button: Button
var qa_dialog: AcceptDialog
var qa_primary: OptionButton
var qa_secondary: OptionButton
var qa_size: SpinBox
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = CoastalHUD.theme()
	button = Button.new()
	button.text = "LINEAGE"
	button.position = Vector2(318,132)
	button.size = Vector2(150,44)
	button.pressed.connect(open)
	add_child(button)
	summary = Label.new()
	summary.position = Vector2(18,430)
	summary.add_theme_font_size_override("font_size",13)
	summary.add_theme_color_override("font_shadow_color",Color.BLACK)
	summary.add_theme_constant_override("shadow_offset_x",2)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(summary)
	stance_button=Button.new()
	stance_button.position=Vector2(318,530)
	stance_button.size=Vector2(150,64)
	stance_button.text="REST / GUARD"
	stance_button.pressed.connect(func():
		if not (model.scene.game_over or model.scene.evolving or model.scene.choice_open or model.scene.reveal_active): model.effects.toggle_stance()
	)
	add_child(stance_button)
	traverse_button=Button.new()
	traverse_button.position=Vector2(334,610)
	traverse_button.size=Vector2(132,52)
	traverse_button.text="TRAVERSE"
	traverse_button.pressed.connect(func(): model.traversal.cycle(); refresh())
	add_child(traverse_button)
	ascend_button=Button.new()
	ascend_button.text="UP"
	ascend_button.position=Vector2(334,668)
	ascend_button.size=Vector2(62,50)
	ascend_button.button_down.connect(func(): model.traversal.vertical_input=1.0)
	ascend_button.button_up.connect(func(): model.traversal.vertical_input=0.0)
	add_child(ascend_button)
	descend_button=Button.new()
	descend_button.text="DOWN"
	descend_button.position=Vector2(402,668)
	descend_button.size=Vector2(64,50)
	descend_button.button_down.connect(func(): model.traversal.vertical_input=-1.0)
	descend_button.button_up.connect(func(): model.traversal.vertical_input=0.0)
	add_child(descend_button)
	dialog = AcceptDialog.new()
	dialog.title = "LINEAGE / GENE INDEX"
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.get_ok_button().text = "RETURN TO WORLD"
	dialog.close_requested.connect(close)
	dialog.confirmed.connect(close)
	add_child(dialog)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	dialog.add_child(column)
	details = RichTextLabel.new()
	details.custom_minimum_size = Vector2(435,220)
	details.scroll_active = true
	column.add_child(details)
	var focus_label := Label.new()
	focus_label.text = "Draft direction (applies to the next unfrozen draft)"
	focus_label.add_theme_font_size_override("font_size",13)
	column.add_child(focus_label)
	focus_picker = OptionButton.new()
	focus_picker.add_item("No preference")
	for f in GeneRegistry.FORMS: focus_picker.add_item(String(f).capitalize())
	focus_picker.item_selected.connect(func(index: int): model.focus = GeneRegistry.FORMS[index-1] if index>0 else "")
	column.add_child(focus_picker)
	enable_button = Button.new()
	enable_button.text = "ENABLE GENETICS (KEEP LEGACY GROWTH)"
	enable_button.pressed.connect(func(): model.enabled=true; model.refresh(); refresh_details())
	column.add_child(enable_button)
	if OS.has_feature("debug"):
		_build_qa_panel(column)
	search = LineEdit.new()
	search.placeholder_text = "Search 500 source genes by ID or name"
	search.text_changed.connect(func(_text: String): populate())
	column.add_child(search)
	entries = ItemList.new()
	entries.custom_minimum_size = Vector2(435,200)
	entries.add_theme_font_size_override("font_size",13)
	column.add_child(entries)
	var reset := Button.new()
	reset.text = "NEW WORLD / FULL RESET..."
	reset.pressed.connect(func(): reset_dialog.popup_centered(Vector2i(420,180)))
	column.add_child(reset)
	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = "CONFIRM FULL RESET"
	reset_dialog.dialog_text = "Erase this world, organism and lineage archive?\nA recovery copy is kept before resetting."
	reset_dialog.get_ok_button().text = "ERASE / NEW WORLD"
	reset_dialog.confirmed.connect(_reset_world)
	add_child(reset_dialog)
	refresh()

func refresh() -> void:
	if not is_instance_valid(button): return
	button.disabled = model.scene.evolving or model.scene.choice_open or model.scene.reveal_active or model.scene.objective_hud.opened
	stance_button.visible = model.enabled and (model.effects.has(58) or model.effects.has(85)) and not button.disabled and not dialog.visible and not model.scene.game_over
	stance_button.text = ("STANCE ON" if model.effects.stance else "REST / GUARD")+("\nMOVE TO CANCEL" if model.effects.has(58) else "\nSPRINT TO CANCEL")
	var ready: bool=model.enabled and not button.disabled and not dialog.visible and not model.scene.game_over
	traverse_button.visible=ready and (model.traversal.can_use("flight") or model.traversal.can_use("glide") or model.traversal.can_use("burrow") or model.traversal.can_use("climb"))
	traverse_button.text="LAND / EXIT" if model.traversal.mode!="ground" else "TRAVERSE"
	ascend_button.visible=ready and model.traversal.mode in ["flight","climb"]
	descend_button.visible=ascend_button.visible
	if not ascend_button.visible: model.traversal.vertical_input=0
	summary.text = "%s\nSize %.2fx | %s" % [model.genome.label(),model.scene.growth_scale,model.genome.growth_policy+" growth | "+model.traversal.mode] if model.enabled else ""
	summary.visible = model.enabled and not dialog.visible and not model.scene.objective_hud.opened and not (model.scene.choice_open or model.scene.reveal_active or model.scene.evolving)

func open() -> void:
	if button.disabled or model.scene.choice_open or model.scene.reveal_active or model.scene.evolving or model.scene.objective_hud.opened: return
	model.scene.touch_input.reset_input()
	model.scene.touch_vector = Vector2.ZERO
	model.scene.sprint_requested = false
	model.scene.sprint_active = false
	get_tree().paused = true
	refresh_details()
	populate()
	dialog.popup_centered(Vector2i(470,740))

func close() -> void:
	dialog.hide()
	get_tree().paused = false
	if not model.scene.world.test_mode: model.scene.world.save_now()

func refresh_details() -> void:
	enable_button.visible = not model.enabled
	focus_picker.select(GeneRegistry.FORMS.find(model.focus)+1)
	var text := "%s\nOrganism %d | %d archived lives\nGrowth: %s | Ground compatibility controller\n" % [model.genome.label(),model.life_id,model.archive.lives.size(),model.genome.growth_policy]
	var shares := model.genome.percentages()
	for f in GeneRegistry.FORMS: text += "%s: %d (%.0f%%) | mastery %d\n" % [String(f).capitalize(),model.genome.raw[f],shares[f],model.archive.mastery[f]]
	text += "Hybrid discoveries: " + (", ".join(model.archive.hybrids) if not model.archive.hybrids.is_empty() else "none")
	text += "\nTraversal: "+model.traversal.mode+"; abilities require equipped genes.\n"+model.traversal.last_error+"\n"+model.error_message
	details.text = text

func populate() -> void:
	entries.clear()
	var query := search.text.to_lower()
	for id in range(1,501):
		var source: Dictionary = GeneRegistry.catalogue()[id]
		var text := "%03d %s" % [id,source["name"]]
		if not query.is_empty() and query not in text.to_lower(): continue
		var status := "PLAYABLE" if id in GeneRegistry.SEEDS or id in GeneEffects.EARLY else "concept / locked"
		entries.add_item(text+" — "+status)
		var key := "gene_%03d" % id
		var detail: String = GeneRegistry.definitions()[key]["detail"] if GeneRegistry.definitions().has(key) else source["source_effect"]
		entries.set_item_tooltip(entries.item_count-1,detail+"\n"+status)

func _build_qa_panel(column: VBoxContainer) -> void:
	var launch:=Button.new()
	launch.text="QA PREVIEW: FORMS, HYBRIDS, FLIGHT / BURROW / CLIMB"
	launch.pressed.connect(func(): qa_dialog.popup_centered(Vector2i(460,540)))
	column.add_child(launch)
	qa_dialog=AcceptDialog.new()
	qa_dialog.title="QA MORPHOLOGY / TRAVERSAL"
	qa_dialog.process_mode=Node.PROCESS_MODE_ALWAYS
	qa_dialog.get_ok_button().text="GENERATE TEST CREATURE"
	qa_dialog.confirmed.connect(_apply_qa_form)
	add_child(qa_dialog)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",9)
	qa_dialog.add_child(content)
	var note:=Label.new()
	note.text="DEBUG PREVIEW ONLY - replaces the active creature.\nExisting world destruction and missions are retained."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	qa_primary=OptionButton.new()
	for fam in GeneRegistry.FORMS: qa_primary.add_item(fam.capitalize())
	qa_primary.select(0)
	content.add_child(qa_primary)
	qa_secondary=OptionButton.new()
	qa_secondary.add_item("No second lineage")
	for fam in GeneRegistry.FORMS: qa_secondary.add_item("+ "+fam.capitalize())
	content.add_child(qa_secondary)
	var growth_label:=Label.new()
	growth_label.text="Chosen physical growth ranks (0-18)"
	content.add_child(growth_label)
	qa_size=SpinBox.new()
	qa_size.min_value=0;qa_size.max_value=18;qa_size.step=1
	qa_size.value=6
	content.add_child(qa_size)
	var instructions:=Label.new()
	instructions.text="Bird: wings and FLIGHT | Mole/Worm: BURROW\nSpider: wall hooks | Snake/Worm: long body\nTap TRAVERSE to move, UP/DOWN for altitude or wall."
	instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(instructions)

func _apply_qa_form() -> void:
	if model.scene.game_over or model.scene.evolving or model.scene.choice_open or model.scene.reveal_active: return
	# Testing alters only the isolated preview's current organism, not any
	# approved release or shared Android application data.
	model.traversal._end_mode()
	var first: String=GeneRegistry.FORMS[qa_primary.selected]
	var families: Array=[first]
	if qa_secondary.selected>0:
		var second: String=GeneRegistry.FORMS[qa_secondary.selected-1]
		if second!=first: families.append(second)
	model.enabled=true
	model.genome=GenomeState.new()
	model.effects.reset()
	model.breach_cooldown=0.0
	# The axial-heavy-arms pairing requires a visible biomass support bridge.
	if "ape" in families and ("snake" in families or "worm" in families):
		model.genome.select_gene("gene_100","qa_bridge")
	for family in families:
		for tier in range(3):
			model.genome.select_gene(GeneRegistry.seed_key(family),"qa_seed_%s_%d"%[family,tier])
	for family in families:
		match family:
			"bird":
				model.genome.select_gene("gene_029","qa_glide")
				model.genome.select_gene("gene_121","qa_flight")
				model.genome.select_gene("gene_122","qa_soar")
			"spider": model.genome.select_gene("gene_180","qa_climb")
			"worm": model.genome.select_gene("gene_119","qa_burrow_worm")
			"mole": model.genome.select_gene("gene_052","qa_burrow_mole")
	for rank in range(int(qa_size.value)):
		model.genome.select_gene("physical_growth","qa_size_%d"%rank)
	model.refresh()
	model.scene.hp=model.scene.max_hp
	model.scene._resolve_growth_clearance()
	model.scene._update_camera(1.0)
	qa_dialog.hide()
	close()
	refresh()
	if not model.scene.world.test_mode: model.scene.world.save_now(true)

func _reset_world() -> void:
	var world: WorldStreaming = model.scene.world
	world.save_writer.flush()
	if not world.state.writable:
		model.error_message = "Save is protected; reset cancelled."
		refresh_details()
		return
	if FileAccess.file_exists(world.state.path):
		var path := ProjectSettings.globalize_path(world.state.path)
		var backup := path+".before-reset-"+str(Time.get_unix_time_from_system())+".json"
		if DirAccess.copy_absolute(path,backup) != OK:
			model.error_message = "Recovery copy failed; reset cancelled."
			refresh_details()
			return
	get_tree().paused = false
	model.scene._restart_run()
