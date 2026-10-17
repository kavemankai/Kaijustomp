class_name ObjectiveHUD
extends Control
## Readable portrait tracker plus explicit selection; no navigation teleport or growth locks.
var model: WorldObjectives
var opened := false
var button: Button
var card: PanelContainer
var tracker_titles: Array[Label]=[]
var tracker_hints: Array[Label]=[]
var notice: Label
var panel: PanelContainer
var rows: VBoxContainer
var heading: Label
var sector_label: Label
var last_signature := ""
signal opened_changed

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    theme=CoastalHUD.theme()
    button=Button.new()
    button.text="OBJECTIVES"
    button.position=Vector2(318,74)
    button.size=Vector2(150,48)
    button.focus_mode=Control.FOCUS_NONE
    button.pressed.connect(func(): set_open(not opened))
    add_child(button)
    card=PanelContainer.new()
    card.position=Vector2(16,188)
    card.size=Vector2(286,174)
    card.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(card)
    var column := VBoxContainer.new()
    column.mouse_filter=Control.MOUSE_FILTER_IGNORE
    card.add_child(column)
    sector_label=Label.new()
    sector_label.text="SECTOR OBJECTIVES"
    sector_label.add_theme_font_size_override("font_size",11)
    sector_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    column.add_child(sector_label)
    for i in range(3):
        var title := Label.new()
        title.add_theme_font_size_override("font_size",13)
        title.mouse_filter=Control.MOUSE_FILTER_IGNORE
        title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
        column.add_child(title)
        tracker_titles.append(title)
        var hint := Label.new()
        hint.add_theme_font_size_override("font_size",11)
        hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
        hint.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
        column.add_child(hint)
        tracker_hints.append(hint)
    notice=Label.new()
    notice.position=Vector2(16,374)
    notice.size=Vector2(508,50)
    notice.add_theme_font_size_override("font_size",14)
    notice.add_theme_color_override("font_shadow_color",Color.BLACK)
    notice.add_theme_constant_override("shadow_offset_x",2)
    notice.add_theme_constant_override("shadow_offset_y",2)
    notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    notice.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(notice)
    panel=PanelContainer.new()
    panel.position=Vector2(16,188)
    panel.size=Vector2(508,480)
    panel.hide()
    add_child(panel)
    var contents := VBoxContainer.new()
    panel.add_child(contents)
    heading=Label.new()
    contents.add_child(heading)
    var explanation := Label.new()
    explanation.text="Pin up to 3 / other slots suggest relevant sector goals"
    explanation.add_theme_font_size_override("font_size",13)
    contents.add_child(explanation)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size=Vector2(475,355)
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    contents.add_child(scroll)
    rows=VBoxContainer.new()
    rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    scroll.add_child(rows)
    var close := Button.new()
    close.text="RETURN TO WORLD"
    close.custom_minimum_size=Vector2(0,44)
    close.pressed.connect(func(): set_open(false))
    contents.add_child(close)

func set_open(value: bool) -> void:
    opened=value
    panel.visible=value
    card.visible=not value
    notice.visible=not value
    button.text="CLOSE" if value else "OBJECTIVES"
    last_signature=""
    opened_changed.emit()

func refresh(at: Vector3,available: bool) -> void:
    if model==null or model.state==null: return
    button.disabled=not available
    card.visible=not opened and available
    if opened and not available: set_open(false)
    var goals := model.tracked_goals(at)
    sector_label.text=model.sector_name(at)+" / %d TRACKED" % goals.size()
    for i in range(3):
        tracker_titles[i].visible=i<goals.size()
        tracker_hints[i].visible=i<goals.size()
        if i>=goals.size(): continue
        var goal: Dictionary=goals[i]
        var pin := "* " if goal["id"] in model.record["pins"] else ""
        tracker_titles[i].text="%s%s  %d/%d" % [pin,goal["title"],mini(goal["goal"],model.value(goal)),goal["goal"]]
        tracker_hints[i].text=model.guidance(goal,at,true)
    if goals.is_empty():
        tracker_titles[0].visible=true
        tracker_titles[0].text="ALL OBJECTIVES COMPLETE"
    notice.text=model.notice if model.notice_time>0 else ""
    notice.visible=not opened and available
    heading.text="OBJECTIVES / %d OF 3 PINNED / RENOWN %d" % [model.record["pins"].size(),model.renown()]
    if not opened: return
    var signature := JSON.stringify(model.record)+str(Vector2i(at.x/50,at.z/50))
    if signature==last_signature: return
    last_signature=signature
    for row in rows.get_children():
        rows.remove_child(row)
        row.queue_free()
    for entry in WorldObjectives.GOALS:
        var row := Button.new()
        var done := model.complete(entry["id"])
        var mark := "DONE" if done else ("UNPIN" if entry["id"] in model.record["pins"] else "PIN")
        row.custom_minimum_size=Vector2(460,82)
        row.disabled=done or (model.record["pins"].size()>=3 and entry["id"] not in model.record["pins"])
        var content := VBoxContainer.new()
        content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        content.offset_left=12
        content.offset_right=-12
        content.offset_top=8
        content.offset_bottom=-8
        content.mouse_filter=Control.MOUSE_FILTER_IGNORE
        row.add_child(content)
        var row_title := Label.new()
        row_title.text="%s  %d/%d  [%s]" % [entry["title"],mini(entry["goal"],model.value(entry)),entry["goal"],mark]
        row_title.add_theme_font_size_override("font_size",14)
        row_title.mouse_filter=Control.MOUSE_FILTER_IGNORE
        content.add_child(row_title)
        var detail := Label.new()
        detail.text=model.guidance(entry,at)
        detail.add_theme_font_size_override("font_size",12)
        detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        detail.mouse_filter=Control.MOUSE_FILTER_IGNORE
        content.add_child(detail)
        row.pressed.connect(func(): model.track(entry["id"]); last_signature="")
        rows.add_child(row)
