extends SceneTree
var failed := false
func check(ok: bool, reason: String) -> void:
	if not ok:
		failed = true
		printerr("GENETICS TEST FAILED: " + reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	check(GeneRegistry.validate().is_empty(), "source/runtime validation")
	var g := GenomeState.new()
	check(g.total() == 0 and g.identity()["kind"] == "unformed", "neutral newborn")
	for f in GeneRegistry.FORMS: check(g.percentages()[f] == 0, "zero percentage")
	var options := MutationDraft.create(g, 79123, 0)
	check(options == MutationDraft.create(g, 79123, 0) and options.size() == 3, "deterministic draft")
	check(options[0] != options[1] and options[1] != options[2], "unique choices")
	var behaved := GenomeState.new()
	check(behaved.credit_behaviour("bird","prey_a") and not behaved.credit_behaviour("bird","prey_a"),"event replay rejected")
	check(behaved.credit_behaviour("bird","prey_b") and not behaved.credit_behaviour("bird","prey_c"),"behaviour capped per interval")
	check(behaved.select_gene("gene_022","interval") and behaved.credit_behaviour("bird","prey_c"),"legitimate selection resets interval")
	check(GenomeState.from_record(behaved.record())!=null,"behaviour save validation")
	for f in GeneRegistry.FORMS:
		var pure := GenomeState.new()
		var key: String = GeneRegistry.seed_key(f)
		for i in range(5): check(pure.select_gene(key, "test_%d" % i), "family path")
		check(pure.identity()["kind"] == "consolidated" and pure.identity()["families"][0] == f, "pure " + f)
		check(not pure.select_gene(key, "test_4"), "duplicate transaction")
		var restored := GenomeState.from_record(pure.record())
		check(restored != null and restored.record() == pure.record(), "round trip " + f)
	for pair in [["reptile","bird"],["ape","crab"],["worm","mole"]]:
		var hybrid := GenomeState.new()
		for i in range(3):
			for f in pair: check(hybrid.select_gene(GeneRegistry.seed_key(f), "%s_%d" % [f,i]), "hybrid gene")
		check(hybrid.identity()["kind"] == "hybrid", "expressed " + str(pair))
	var candidate := GenomeState.new()
	candidate.raw["bird"] = 12
	candidate.raw["reptile"] = 12
	check(candidate.identity()["kind"] == "candidate", "scores alone cannot express hybrid")
	var support := GenomeState.new()
	support.select_gene(GeneRegistry.seed_key("worm"), "w")
	check(not support.legal(GeneRegistry.seed_key("ape")), "unsupported heavy arms")
	support.select_gene(GeneRegistry.seed_key("biomass"), "bridge")
	check(support.legal(GeneRegistry.seed_key("ape")), "visible matrix support bridge")
	var invalid := g.record()
	invalid["raw"]["unknown"] = 5
	check(GenomeState.from_record(invalid) == null, "unknown family rejected")
	invalid = g.record()
	invalid["ranks"]["unsupported_flight"] = 1
	check(GenomeState.from_record(invalid) == null, "unsupported gene rejected")
	if not failed: print("GENETICS CORE TEST PASSED: catalogue, neutral scores, deterministic legal drafts, nine pure paths, three hybrids, support bridge, idempotence, save validation")
	quit(1 if failed else 0)
