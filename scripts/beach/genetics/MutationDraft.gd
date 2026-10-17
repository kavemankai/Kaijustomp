class_name MutationDraft
extends RefCounted
static func create(genome: GenomeState, seed_value: int, evolution: int, focus: String = "", context: Dictionary = {}) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + evolution * 104729
	var eligible: Array[String] = []
	for key in GeneRegistry.definitions():
		if genome.legal(key): eligible.append(key)
	var result: Array[String] = []
	var leader: String = genome.ordered_families()[0] if genome.total() > 0 else ""
	for lane in ["strengthen","explore","adapt"]:
		var pool: Array[String] = []
		for key in eligible:
			var family: String = GeneRegistry.definitions()[key]["family"]
			if (lane == "strengthen" and family == (focus if focus in GeneRegistry.FORMS else leader)) or (lane == "explore" and not family.is_empty() and family != leader) or (lane == "adapt" and family.is_empty()): pool.append(key)
		if pool.is_empty(): pool.assign(eligible)
		if pool.is_empty(): break
		var chosen := weighted(pool,genome,rng,context)
		# A matrix creates a second explore opportunity instead of a generic stat card.
		if lane == "adapt" and int(genome.ranks.get("gene_100",0)) > 0:
			var cross_pool: Array[String] = []
			for key in eligible:
				if not GeneRegistry.definitions()[key]["family"].is_empty(): cross_pool.append(key)
			if not cross_pool.is_empty(): chosen=weighted(cross_pool,genome,rng,context)
		result.append(chosen)
		eligible.erase(chosen)
	return result

static func weighted(pool: Array[String], genome: GenomeState, rng: RandomNumberGenerator, context: Dictionary) -> String:
	var weights: Array[float] = []
	var total := 0.0
	for key in pool:
		var gene: Dictionary = GeneRegistry.definitions()[key]
		var family: String = gene["family"]
		var weight := float(gene["weight"])
		if not family.is_empty():
			weight *= clampf(1.0+float(genome.raw[family])*.03+float(genome.interval_credit[family])*.1,1.0,2.0)
			if (context.get("terrain","")=="coast" and family in ["crab","worm"]) or (context.get("terrain","")=="inland" and family=="mole"): weight*=1.2
		weights.append(weight); total+=weight
	var roll := rng.randf()*total
	for i in range(pool.size()):
		roll-=weights[i]
		if roll<=0: return pool[i]
	return pool.back()
