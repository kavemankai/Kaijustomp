class_name CreatureMorphology
extends Node3D
## Bounded low-poly ground proofs. Meshes build only when the gene recipe changes.
const COLORS := [Color("368f86"),Color("af677d"),Color("a44736"),Color("ca9a45"),Color("bc653c"),Color("46455f"),Color("795845"),Color("bd7e83"),Color("766054")]
const CREAM := Color("edd8b0")
const INK := Color("202936")
static var cache: Dictionary = {}
var joints: Array[Node3D] = []
var axes: Array[Node3D] = []
var primary := ""
var recipe := ""
var build_count := 0

func configure(genome: GenomeState, generic_ranks: Dictionary = {}) -> void:
	var anatomy := AnatomyResolver.resolve(genome.ranks,genome.raw)
	var families: Array = anatomy["families"]
	primary = ""
	for f in genome.ordered_families():
		if f in families: primary = f; break
	var traits: Array = []
	for id in GeneEffects.EARLY:
		if genome.ranks.has("gene_%03d" % id): traits.append(id)
	var signature := primary + ":" + ",".join(families)+":"+str(traits)+":"+JSON.stringify(genome.ranks)+":"+JSON.stringify(generic_ranks)
	if recipe == signature: return
	recipe = signature
	for child in get_children(): child.free()
	joints.clear()
	axes.clear()
	visible = not primary.is_empty()
	if not visible: return
	build_count += 1
	var body := Node3D.new()
	body.name = "Core"
	add_child(body)
	if cache.has(signature):
		var renderer := MeshInstance3D.new()
		renderer.mesh = cache[signature]
		renderer.material_override = CoastalArt.palette
		body.add_child(renderer)
	else:
		_core(body, primary)
		for family in families:
			if genome.ranks.has(GeneRegistry.seed_key(family)): _signature(body,family,genome.ranks.has("gene_061"))
		for id in traits: _trait(MutationExpressionLibrary.trait_frame(body, primary, id),id)
		MutationExpressionLibrary.render(body,primary,generic_ranks)
		var merged := CoastalArt.merge(body,"GeneticCore")
		if cache.size() >= 24: cache.erase(cache.keys()[0])
		cache[signature] = merged.mesh
	# Articulated supports are independent nodes, reusing primitive meshes until next recipe.
	var color: Color = COLORS[GeneRegistry.FORMS.find(primary)]
	if primary in ["snake","worm"]:
		for i in range(6):
			var axis := Node3D.new()
			axis.position = Vector3(0,.48,.3+i*.38)
			add_child(axis)
			oval(axis,Vector3.ZERO,Vector3(.61-i*.055,.39-i*.035,.34),color.darkened(i*.035))
			axes.append(axis)
	else:
		var count := 8 if primary in ["spider","crab"] else (2 if primary == "bird" else 4)
		for i in range(count):
			var side := -1.0 if i < count/2 else 1.0
			var row := i % (count/2)
			var z := lerpf(-.9,1.0,float(row)/maxf(1.0,count/2.0-1.0))
			var joint := Node3D.new()
			joint.name = "Support_%d" % i
			joint.position = Vector3(side*.70,.65,z)
			add_child(joint)
			if primary in ["crab","spider"]:
				link(joint,Vector3.ZERO,Vector3(side*.85,.15,.28),.11,color)
				link(joint,Vector3(side*.85,.15,.28),Vector3(side*1.25,-.58,.48),.085,color.lightened(.15))
			else:
				link(joint,Vector3.ZERO,Vector3(side*.18,-.48,.05),.18,color)
				oval(joint,Vector3(side*.2,-.51,-.18),Vector3(.27,.14,.39),color.darkened(.2))
			joints.append(joint)
			CoastalArt.merge(joint,"Support")

static func oval(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	return CoastalArt.oval(parent,at,size,color)
static func link(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var limb := oval(parent,(a+b)*.5,Vector3(radius,a.distance_to(b)*.5,radius),color)
	if a.distance_to(b) > .001:
		limb.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
static func eye(parent: Node3D, at: Vector3, radius: float = .12) -> void:
	oval(parent,at,Vector3.ONE*radius,Color("f2cc62"))
	oval(parent,at+Vector3(0,0,-radius*.7),Vector3(radius*.40,radius*.70,radius*.5),INK)

func _core(body: Node3D, family: String) -> void:
	var color: Color = COLORS[GeneRegistry.FORMS.find(family)]
	match family:
		"snake":
			oval(body,Vector3(0,.70,-.65),Vector3(.52,.72,.65),color)
			oval(body,Vector3(0,1.35,-1.12),Vector3(.60,.42,.64),color)
			oval(body,Vector3(0,.73,-.99),Vector3(.34,.64,.19),CREAM)
		"worm":
			oval(body,Vector3(0,.55,-.68),Vector3(.73,.55,.75),color)
			var mouth := TorusMesh.new()
			mouth.inner_radius=.28; mouth.outer_radius=.65; mouth.rings=12; mouth.ring_segments=6
			var ring := MeshInstance3D.new(); ring.mesh=mouth; ring.rotation.x=PI*.5; ring.position=Vector3(0,.60,-1.35)
			var mat := StandardMaterial3D.new(); mat.albedo_color=CREAM; ring.material_override=mat; body.add_child(ring)
			oval(body,Vector3(0,.60,-1.31),Vector3(.35,.34,.09),INK)
		"bird":
			oval(body,Vector3(0,1.0,.1),Vector3(.62,.75,1.0),color)
			oval(body,Vector3(0,1.50,-.66),Vector3(.40,.66,.43),color)
			oval(body,Vector3(0,1.90,-1.0),Vector3(.47,.39,.48),color)
			link(body,Vector3(0,1.83,-1.14),Vector3(0,1.75,-1.92),.20,Color("e6bb67"))
			for i in range(3): oval(body,Vector3(0,1.3+i*.15,1.1+i*.20),Vector3(.15,.13,.7),color.darkened(.2))
		"crab","spider":
			oval(body,Vector3(0,.8,.15),Vector3(1.16,.50,1.18),color)
			if family == "spider": oval(body,Vector3(0,.75,1.0),Vector3(.88,.65,.95),color.lightened(.1))
			oval(body,Vector3(0,.85,-.88),Vector3(.60,.32,.5),color)
		"ape":
			oval(body,Vector3(0,1.20,0),Vector3(1.0,.88,.78),color)
			oval(body,Vector3(0,1.55,-.8),Vector3(.57,.57,.48),color)
			oval(body,Vector3(0,1.34,-1.10),Vector3(.40,.25,.22),CREAM)
			oval(body,Vector3(0,1.25,-.69),Vector3(.68,.58,.14),color.darkened(.25))
		"mole":
			oval(body,Vector3(0,.72,.12),Vector3(.86,.56,1.02),color)
			oval(body,Vector3(0,.72,-.9),Vector3(.56,.40,.57),color.lightened(.10))
			oval(body,Vector3(0,.66,-1.38),Vector3(.30,.23,.30),Color("c19386"))
			oval(body,Vector3(0,.49,1.10),Vector3(.18,.15,.32),color)
		_:
			oval(body,Vector3(0,.85,.2),Vector3(.82,.57,1.22),color)
			oval(body,Vector3(0,.95,-1.0),Vector3(.6,.44,.75),color)
			oval(body,Vector3(0,.68,-1.1),Vector3(.48,.19,.68),CREAM)
			for i in range(3): oval(body,Vector3(0,.73-i*.13,1.3+i*.48),Vector3(.47-i*.11,.30-i*.06,.55),color)
	if family != "worm":
		var eye_y := 1.98 if family == "bird" else (1.69 if family == "ape" else (1.51 if family == "snake" else 1.08))
		for s in [-1,1]: eye(body,Vector3(s*.40,eye_y,-1.32))

func _signature(body: Node3D, family: String, pincer_hands: bool = false) -> void:
	match family:
		"reptile":
			for i in range(6):
				var plate := CoastalArt.box(body,Vector3(0,1.40,.9-i*.40),Vector3(.36,.42,.26),Color("de8a49"))
				plate.rotation.z=PI*.25
		"biomass":
			for s in [-1,1]:
				for i in range(3):
					link(body,Vector3(s*.55,1.1,i*.4-.3),Vector3(s*(1.0+i*.10),1.6+i*.15,i*.4-.5),.095,Color("d58b9b"))
				oval(body,Vector3(s*.65,.95,.3),Vector3(.3,.4,.4),Color("733f65"))
		"snake":
			for s in [-1,1]: link(body,Vector3(s*.32,1.12,-1.49),Vector3(s*.26,.73,-1.92),.10,CREAM)
		"bird":
			for s in [-1,1]:
				for i in range(5):
					var feather := oval(body,Vector3(s*(.88+i*.24),1.1-i*.07,.1+i*.14),Vector3(.28,.10,.74-i*.04),Color("d6ad63") if i%2 else Color("5b7a85"))
					feather.rotation.y=s*(.3+i*.12)
		"crab":
			oval(body,Vector3(0,1.29,.25),Vector3(.98,.24,1.0),Color("d46b3d"))
			for s in [-1,1]:
				link(body,Vector3(s*.65,.9,-.6),Vector3(s*1.35,.6,-1.25),.22,Color("c96534"))
				for t in [-1,1]: link(body,Vector3(s*1.35,.6,-1.2),Vector3(s*1.35+t*.20,.59,-1.95),.15,Color("e19151"))
		"spider":
			for s in [-1,1]:
				for i in range(3): eye(body,Vector3(s*(.16+i*.18),1.20,-1.33),.09)
		"ape":
			oval(body,Vector3(0,1.15,-.05),Vector3(.96,.62,.70),Color("795744"))
			for s in [-1,1]:
				link(body,Vector3(s*.75,1.35,-.35),Vector3(s*1.35,.45,-1.0),.30,Color("795744"))
				if not pincer_hands: oval(body,Vector3(s*1.4,.4,-1.15),Vector3(.36,.3,.38),Color("a37b59"))
		"worm":
			for i in range(5): oval(body,Vector3(0,.30,-.6+i*.38),Vector3(.70,.13,.13),CREAM)
		"mole":
			for s in [-1,1]:
				oval(body,Vector3(s*.9,.45,-.8),Vector3(.4,.3,.47),Color("aa8a72"))
				for i in range(3): link(body,Vector3(s*(.65+i*.18),.45,-1.0),Vector3(s*(.65+i*.18),.20,-1.87),.09,CREAM)
			oval(body,Vector3(0,.72,-1.50),Vector3(.28,.22,.40),Color("d49e9d"))

func animate(phase: float, moving: bool) -> void:
	for i in range(joints.size()): joints[i].rotation.x = sin(phase+i*PI)*.3 if moving else 0.0
	for i in range(axes.size()): axes[i].position.x = sin(phase-i*.55)*.18 if moving else 0.0

func _trait(body: Node3D, id: int) -> void:
	# Distinct small anatomical cues, merged once into the recipe mesh.
	match id:
		1:
			for s in [-1,1]: link(body,Vector3(0,.75,-1.6),Vector3(s*.18,.69,-2.15),.045,Color("a85975"))
		2:
			for s in [-1,1]:
				for i in range(3): CoastalArt.box(body,Vector3(s*.74,1.0,.5-i*.4),Vector3(.08,.28,.30),CREAM)
		7:
			for s in [-1,1]: link(body,Vector3(s*.30,.68,-1.55),Vector3(s*.30,.28,-1.59),.055,Color("9bbd52"))
		9,72:
			for i in range(5): link(body,Vector3(0,1.3,-.5+i*.4),Vector3(0,1.9,-.3+i*.4),.13,CREAM if id==9 else Color("e3a578"))
		12:
			oval(body,Vector3(0,.63,-1.4),Vector3(.65,.19,.6),Color("c9a87e"))
		14,95:
			for s in [-1,1]:
				for i in range(3): oval(body,Vector3(s*(.25+i*.10),1.0,-1.6),Vector3.ONE*.07,Color("de864f") if id==14 else Color("71cecb"))
		19:
			oval(body,Vector3(0,.4,2.5),Vector3(.50,.38,.58),Color("c68b62"))
		20:
			for s in [-1,1]:
				for i in range(3): oval(body,Vector3(s*.76,.99,.6-i*.4),Vector3(.12,.23,.19),Color("52684a"))
		30,57:
			for s in [-1,1]: eye(body,Vector3(s*.49,1.22,-1.28),.19 if id==30 else .14)
		36:
			for s in [-1,1]: link(body,Vector3(s*.95,.6,-.7),Vector3(s*1.4,.7,-1.0),.12,CREAM)
		39:
			for s in [-1,1]: oval(body,Vector3(s*.75,1.1,-.25),Vector3(.29,.42,.53),Color("c7b284"))
		42:
			for i in range(10):
				var x := sin(i*2.4)*.72
				var z := cos(i*2.4)*.75
				link(body,Vector3(x,1.1,z),Vector3(x*1.1,1.7,z),.065,Color("b5946c"))
		43:
			for s in [-1,1]: link(body,Vector3(s*.30,.73,-1.3),Vector3(s*.40,1.24,-1.77),.12,CREAM)
		47:
			for s in [-1,1]: link(body,Vector3(s*.72,1.0,.4),Vector3(s*.72,1.50,-.4),.045,Color("db7b66"))
		49:
			oval(body,Vector3(0,.8,.0),Vector3(1.02,.59,1.1),Color("ba9c76"))
		58:
			oval(body,Vector3(0,1.25,.8),Vector3(.6,.35,.65),Color("876854"))
		73:
			for s in [-1,1]:
				for z in [-.8,.8]: oval(body,Vector3(s*.9,.60,z),Vector3.ONE*.23,Color("83bba8"))
		81:
			for s in [-1,1]: oval(body,Vector3(s*.76,.79,0),Vector3(.13,.24,.92),Color("87bba4"))
		85:
			oval(body,Vector3(0,1.20,.2),Vector3(.9,.72,1.05),Color("b69b76"))
		88:
			link(body,Vector3(0,1.1,-.5),Vector3(0,2.1,-1.0),.07,Color("89a98a"))
			oval(body,Vector3(0,2.1,-1.0),Vector3.ONE*.20,Color("eddb7c"))
		90:
			for s in [-1,1]:
				for i in range(3): oval(body,Vector3(s*.76,1.0,i*.3-.3),Vector3.ONE*.15,Color("d69a63"))
		99:
			for i in range(3): oval(body,Vector3(0,.25,1.0+i*.30),Vector3(.4,.12,.25),Color("a8bc66"))
		441:
			for s in [-1,1]: link(body,Vector3(s*.45,1.2,-.8),Vector3(s*.7,1.6,-.3),.09,Color("803c55"))
