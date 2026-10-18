extends SceneTree
## Launcher is an actual launch scene, save validation is read-only and menu remains touch-sized.
var failed:=false
func check(ok: bool,reason: String) -> void:
	if not ok:
		failed=true
		printerr("LAUNCH MENU TEST FAILED: "+reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(540,960)
	check(String(ProjectSettings.get_setting("application/run/main_scene"))=="res://scenes/LaunchMenu.tscn","launcher set as main scene")
	var title=load("res://scenes/LaunchMenu.tscn").instantiate()
	root.add_child(title)
	title.save_path="user://ci-title-world.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(title.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(title.save_path+".bak"))
	title._refresh_save()
	check(not title.existing_world and title.continue_button.disabled,"continue disabled without valid save")
	check(title.new_button.visible and title.settings_dialog!=null and title.credits_dialog!=null,"four functioning menu destinations")
	check(title.menu_card.size.x>=300 and title.menu_card.size.y>=300,"portrait action panel")
	check(not title.splash_finished and title.intro.visible,"animated splash precedes menu")
	title._finish_intro()
	check(title.splash_finished,"splash is skip-safe")
	var state=WorldState.new()
	state.path=title.save_path
	check(state.write_save(),"create isolated test save")
	title._refresh_save()
	check(title.existing_world and not title.continue_button.disabled,"valid persistent save enables continue")
	title._request_new()
	check(title.new_confirm.visible,"new world requires confirmation with save")
	title.new_confirm.hide()
	title.size=Vector2(960,540)
	title._layout()
	check(title.menu_card.position.x>480 and title.title_group.position.x<300,"landscape title and menu are separate")
	title.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ci-title-world.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ci-title-world.json.bak"))
	if not failed: print("LAUNCH MENU TEST PASSED: startup, splash, safe continue/new, settings, credits and mobile layout")
	quit(1 if failed else 0)
