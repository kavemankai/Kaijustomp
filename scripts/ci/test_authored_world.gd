extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var demo = load("res://scenes/BeachDemo.tscn").instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/ci/fixtures/authored_world.json"))
	var failed := false
	for i in range(114):
		var b: Dictionary = demo.buildings[i]
		var expected: Dictionary = fixture["buildings"][i]
		var actual := {"position":[b["position"].x,b["position"].z],"half":[b["half"].x,b["half"].y],"height":b["height"],"name":b["name"],"hits":b["max_hits"],"required_strength":b["required_strength"],"breakthrough_strength":b["breakthrough_strength"],"occupants":b["base_occupants"]}
		for key in actual:
			var equal: bool = is_equal_approx(float(actual[key]),float(expected[key])) if key in ["height","hits","required_strength","breakthrough_strength","occupants"] else actual[key]==expected[key]
			if not equal:
				failed=true
				printerr("AUTHORED WORLD TEST FAILED: original building %d changed %s: %s != %s" % [i,key,actual[key],expected[key]])
	if not failed: print("AUTHORED WORLD TEST PASSED: all 114 original positions, footprints, heights, titles, occupants, strength thresholds and rewards preserved from APK217 source")
	quit(1 if failed else 0)
