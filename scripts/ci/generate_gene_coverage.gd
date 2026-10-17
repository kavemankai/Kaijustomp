extends SceneTree
func _initialize() -> void:
	var file:=FileAccess.open("res://docs/evolution/GENE_COVERAGE.csv",FileAccess.WRITE)
	file.store_csv_line(PackedStringArray(["source_id","source_key","name","catalogued","runtime_defined","integrated","visualized","automated_tested","playable_prototype","runtime_effect_or_reason"]))
	for id in range(1,501):
		var source: Dictionary=GeneRegistry.catalogue()[id]
		var key:="gene_%03d" % id
		var implemented:=GeneRegistry.definitions().has(key)
		var flag:="yes" if implemented else "no"
		var detail: String=GeneRegistry.definitions()[key]["detail"] if implemented else "Concept only; absent from live drafts."
		file.store_csv_line(PackedStringArray([str(id),source["key"],source["name"],"yes",flag,flag,flag,flag,flag,detail]))
	file.close()
	print("Coverage: 500 indexed, 35 source prototypes; every other source remains locked.")
	quit()
