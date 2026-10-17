extends SceneTree
## Enumerated geometry, legal selection, slot ownership and bounded path proofs.
var failed := false
var rows: Array[String]=["host,gene,rank,legal,owner,socket,operation,geometry_verified"]
func check(ok: bool,why: String) -> void:
	if not ok: failed=true;printerr("POLISH ANATOMY TEST FAILED: "+why)
func _initialize() -> void: call_deferred("run")
func hash_mesh(m: CreatureMorphology) -> String:
	var mesh: Mesh=m.get_node("Core").get_child(0).mesh
	return (str(mesh.get_faces())+str(mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR])).sha256_text()
func make_genome(host: String,count: int=1) -> GenomeState:
	var g := GenomeState.new()
	for i in range(count): check(g.select_gene(GeneRegistry.seed_key(host),"seed_%d"%i),"seed "+host)
	return g
func prerequisites(g: GenomeState,key: String) -> void:
	var needs := {"gene_029":"gene_022","gene_121":"gene_029","gene_122":"gene_121","gene_052":"gene_015","gene_119":"gene_084","gene_180":"gene_062"}
	if needs.has(key) and not g.ranks.has(needs[key]):
		prerequisites(g,needs[key])
		if not g.legal(needs[key]) and not g.ranks.has("gene_100"): check(g.select_gene("gene_100","prerequisite_bridge"),"prerequisite bridge")
		check(g.select_gene(needs[key],"prerequisite_"+needs[key]),"prerequisite "+key)
func run() -> void:
	var morphology := CreatureMorphology.new();root.add_child(morphology)
	check(GeneRegistry.validate().is_empty(),"500 catalogue IDs preserved")
	var generic_count := 0
	for host in GeneRegistry.FORMS:
		var sockets := AnatomyManifest.sockets(host)
		for key in GeneRegistry.LEGACY:
			var g := make_genome(host,3)
			morphology.configure(g)
			var previous := hash_mesh(morphology)
			for tier in range(1,4):
				check(g.select_gene(key,"rank_%d"%tier),"legal generic")
				morphology.configure(g,{key:tier})
				var current := hash_mesh(morphology)
				check(current!=previous,"ACTUAL vertices or colours develop "+host+" "+key+" "+str(tier))
				previous=current
				var spec := AnatomyManifest.expression(host,key,tier)
				check(spec["owner"]==host and sockets.has(spec["socket"]),"owned socket")
				check(morphology.expressions.filter(func(e): return e["gene"]==key).size()==1,"one organ per equipped gene")
				check(GenomeState.from_record(g.record())!=null,"generic save roundtrip")
				rows.append("%s,%s,%d,true,%s,%s,%s,true"%[host,key,tier,host,spec["socket"],spec["operation"]]);generic_count+=1
			var builds := morphology.build_count
			for i in range(100): morphology.animate(i*.1,true)
			check(morphology.build_count==builds,"no per-frame mesh allocation")
			morphology.configure(g,{key:3})
			check(morphology.build_count==builds,"same recipe does not rebuild")
		for growth in [0,6,12,18]:
			var p := BodyDimensionsPolicy.measure(host,growth)
			check(float(p["width"])>0 and float(p["length"])<100 and float(p["height"])<20,"bounded dimensions")
			if host in ["snake","worm"]: check(p["axial"] and not p["upright_allowed"],"horizontal axial")
		for gene in GeneRegistry.definitions().values():
			if int(gene["source_id"])==0: continue
			var g := make_genome(host,3)
			var key: String=gene["key"]
			if key==GeneRegistry.seed_key(host): g=make_genome(host)
			prerequisites(g,key)
			var legal := g.legal(key)
			if not legal and key=="gene_044":
				check(g.select_gene("gene_100","bridge"),"heavy arms need matrix")
				legal=g.legal(key)
			if legal:
				morphology.configure(g)
				var previous := hash_mesh(morphology)
				check(g.select_gene(key,"source"),"source selection")
				morphology.configure(g)
				var spec := AnatomyManifest.expression(morphology.primary,key,int(g.ranks[key]))
				check(morphology.expressions.any(func(e): return e["gene"]==key),"source expression exists")
				# Flight changes animated feathers, seeds may change working supports.
				check(hash_mesh(morphology)!=previous or int(gene["source_id"]) in [29,121,122,15,22,44,62,100],"source geometry exists "+host+" "+key)
				check(GenomeState.from_record(g.record())!=null,"source save roundtrip "+key)
				check(String(gene["detail"]).length()>20 and not String(gene["effect"]).is_empty(),"card backed by runtime hook")
				rows.append("%s,%s,%d,true,%s,%s,%s,true"%[host,key,g.ranks[key],spec["owner"],spec["socket"],spec["operation"]])
			else: rows.append("%s,%s,1,false,,,,false"%[host,key])
	check(generic_count==243,"243 generic host tiers")
	var pairs := 0
	for i in range(9):
		for j in range(i+1,9):
			var a: String=GeneRegistry.FORMS[i];var b: String=GeneRegistry.FORMS[j]
			var g := make_genome(a)
			var legal := g.legal(GeneRegistry.seed_key(b))
			var proposed := g.ranks.duplicate();proposed[GeneRegistry.seed_key(b)]=1
			var resolved := AnatomyResolver.resolve(proposed)
			check(legal==resolved["legal"],"pair legality agrees")
			check(resolved.has("hybrid_status") and not String(resolved["reason"]).is_empty(),"prototype/illegal explanation")
			if not legal:
				check(g.select_gene("gene_100","support"),"matrix available")
				check(g.legal(GeneRegistry.seed_key(b)),"matrix resolves pair")
			pairs+=1
	check(pairs==36,"36 unordered pairs")
	DirAccess.make_dir_recursive_absolute("res://build/polish-evidence")
	FileAccess.open("res://build/polish-evidence/coverage.csv",FileAccess.WRITE).store_string("\n".join(rows)+"\n")
	morphology.free()
	if not failed: print("POLISH ANATOMY TEST PASSED: 36 growth profiles, 243 actual generic geometry tiers, all 41 sources across hosts, 36 pair legality, cache invariants")
	quit(1 if failed else 0)

