class_name CreatureMorphology
extends Node3D
## Connected, cached tissue cores and articulated, exclusive support organs.
const COLORS := [Color("368f86"),Color("af677d"),Color("a44736"),Color("ca9a45"),Color("bc653c"),Color("46455f"),Color("795845"),Color("bd7e83"),Color("766054")]
const CREAM := Color("edd8b0")
const INK := Color("202936")
static var cache: Dictionary={}
var joints: Array[Node3D]=[]
var axes: Array[Node3D]=[]
var wings: Array[Node3D]=[]
var wrists: Array[Node3D]=[]
var tendrils: Array[Node3D]=[]
var primary := ""
var recipe := ""
var build_count := 0
var movement_mode := "ground"
var expressions: Array[Dictionary]=[]
var wing_development := 0
var bank := 0.0
var bite := 0.0
var flight_clock := 0.0
var face: Node3D
var forelimb_kind := ""
var seed_tier := 1
var wall_hooks := false
var grasp_tier := 0
var tail_club: Node3D

func configure(genome: GenomeState,generic_ranks: Dictionary={}) -> void:
	var anatomy := AnatomyResolver.resolve(genome.ranks,genome.raw)
	var families: Array=anatomy["families"]
	primary=""
	for f in genome.ordered_families():
		if f in families: primary=f;break
	var signature := primary+":"+JSON.stringify(genome.ranks)+":"+JSON.stringify(generic_ranks)
	if recipe==signature: return
	recipe=signature
	for child in get_children(): child.free()
	tail_club=null
	joints.clear();axes.clear();wings.clear();wrists.clear();tendrils.clear();expressions.clear()
	visible=not primary.is_empty()
	if not visible: return
	build_count+=1
	var active: Array=[primary]
	for f in genome.ordered_families():
		if f!=primary and f in families and genome.ranks.has(GeneRegistry.seed_key(f)):
			active.append(f);break
	# A matrix is a support system, not a replacement for the grasp organ it unlocks.
	if primary in ["snake","worm"] and genome.ranks.has("gene_044"):
		if active.size()==1: active.append("ape")
		else: active[1]="ape"
	forelimb_kind="pincer" if "crab" in active else ("spade" if "mole" in active else ("knuckle" if primary=="ape" else "paw"))
	seed_tier=clampi(int(genome.ranks.get(GeneRegistry.seed_key(primary),1)),1,3)
	wall_hooks=genome.ranks.has("gene_180")
	grasp_tier=mini(3,int(genome.ranks.get("gene_044",0)))
	wing_development=3 if genome.ranks.has("gene_122") else (2 if genome.ranks.has("gene_121") else (1 if genome.ranks.has("gene_029") else 0))
	var core := Node3D.new();core.name="Core";add_child(core)
	for key in genome.ranks:
		if key!="physical_growth": expressions.append(AnatomyManifest.expression(primary,key,int(genome.ranks[key])))
	# Growth changes outer transforms; keep a bounded cache of real mesh recipes.
	var mesh_key := signature
	if cache.has(mesh_key):
		var mesh := MeshInstance3D.new();mesh.mesh=cache[mesh_key];mesh.material_override=CoastalArt.palette;core.add_child(mesh)
	else:
		_core(core,primary)
		for part in core.get_children():
			part.transform=Transform3D(Basis.from_scale(Vector3(1.0+seed_tier*.025,1.0+seed_tier*.02,1.0+seed_tier*.015)),Vector3.ZERO)*part.transform
		for f in active: _signature(core,f,clampi(int(genome.ranks.get(GeneRegistry.seed_key(f),1)),1,3))
		for f in GeneRegistry.FORMS:
			if f not in active and genome.ranks.has(GeneRegistry.seed_key(f)): _integrated_support(core,f)
		for id in GeneEffects.EARLY:
			if genome.ranks.has("gene_%03d"%id): MutationExpressionLibrary.render_source(core,primary,id,int(genome.ranks["gene_%03d"%id]))
		MutationExpressionLibrary.render(core,primary,generic_ranks)
		var merged := OrganicGeometry.bake(core,"GeneticCore")
		if cache.size()>=24: cache.erase(cache.keys()[0])
		cache[mesh_key]=merged.mesh
	_build_face()
	if "bird" in active or genome.ranks.has("gene_029"): _build_wings()
	_build_supports(active,generic_ranks)
	if primary=="crab": _build_pincers(generic_ranks)
	if genome.ranks.has("gene_100"): _build_tendrils()
	if primary in ["snake","worm"] and genome.ranks.has("gene_019"):
		tail_club=Node3D.new();tail_club.name="FractionalTailClub";tail_club.position=Vector3(0,.6,2.5);add_child(tail_club)
		OrganicGeometry.loft(tail_club,[Vector3(0,0,-.5),Vector3.ZERO,Vector3(0,0,.5)],[Vector2(.18,.16),Vector2(.50,.38),Vector2(.15,.13)],Color("c68b62"))
		CoastalArt.merge(tail_club,"TailClubSkin")

static func oval(parent: Node3D, at: Vector3,size: Vector3,c: Color) -> MeshInstance3D:
	return CoastalArt.oval(parent,at,size,c)
static func link(parent: Node3D,a: Vector3,b: Vector3,r: float,c: Color) -> void:
	OrganicGeometry.tapered(parent,a,b,r,r*.65,c)
static func eye(parent: Node3D,at: Vector3,r: float=.10) -> void:
	oval(parent,at,Vector3.ONE*r,Color("f2cc62"))
	oval(parent,at+Vector3(0,0,-r*.75),Vector3(r*.40,r*.65,r*.35),INK)
func _core(p: Node3D,f: String) -> void:
	var c: Color=COLORS[GeneRegistry.FORMS.find(f)]
	match f:
		"snake":
			OrganicGeometry.loft(p,[Vector3(0,.45,.7),Vector3(0,.62,-.3),Vector3(0,1.04,-.75),Vector3(0,1.38,-1.08),Vector3(0,1.30,-1.61)],[Vector2(.50,.40),Vector2(.53,.48),Vector2(.37,.47),Vector2(.55,.31),Vector2(.36,.16)],c)
			OrganicGeometry.loft(p,[Vector3(0,.37,.4),Vector3(0,.60,-.68),Vector3(0,1.14,-1.17),Vector3(0,1.15,-1.65)],[Vector2(.31,.06),Vector2(.24,.08),Vector2(.40,.07),Vector2(.27,.05)],CREAM)
		"worm":
			OrganicGeometry.loft(p,[Vector3(0,.55,.7),Vector3(0,.59,-.45),Vector3(0,.60,-1.15),Vector3(0,.60,-1.42)],[Vector2(.68,.53),Vector2(.72,.54),Vector2(.64,.50),Vector2(.55,.45)],c)
			oval(p,Vector3(0,.60,-1.425),Vector3(.43,.37,.045),INK)
			for i in range(12):
				var a := TAU*i/12.0
				OrganicGeometry.tapered(p,Vector3(cos(a)*.52,.6+sin(a)*.43,-1.46),Vector3(cos(a)*.36,.6+sin(a)*.28,-1.53),.09,.015,CREAM)
		"bird":
			OrganicGeometry.loft(p,[Vector3(0,.95,1.05),Vector3(0,1.1,.30),Vector3(0,1.18,-.35),Vector3(0,1.65,-.65),Vector3(0,1.90,-.98)],[Vector2(.17,.20),Vector2(.63,.62),Vector2(.52,.56),Vector2(.25,.36),Vector2(.39,.31)],c)
			OrganicGeometry.loft(p,[Vector3(0,1.85,-1.07),Vector3(0,1.79,-1.50),Vector3(0,1.72,-1.88)],[Vector2(.30,.20),Vector2(.27,.15),Vector2(.025,.045)],CREAM)
			for i in range(5):
				OrganicGeometry.tapered(p,Vector3((i-2)*.10,1.12,.72),Vector3((i-2)*.24,1.44,1.76),.17,.025,c.darkened(.25))
			for i in range(3): OrganicGeometry.tapered(p,Vector3(0,2.05,-.75+i*.13),Vector3(0,2.48-i*.10,-.62+i*.13),.13,.025,Color("d57449"))
		"crab":
			OrganicGeometry.loft(p,[Vector3(0,.70,-1.05),Vector3(0,.80,-.30),Vector3(0,.82,.5),Vector3(0,.70,1.22)],[Vector2(.56,.23),Vector2(1.12,.43),Vector2(1.20,.41),Vector2(.65,.20)],c)
			oval(p,Vector3(0,.52,-.92),Vector3(.36,.18,.38),CREAM)
		"spider":
			oval(p,Vector3(0,.80,.87),Vector3(.80,.60,1.05),c)
			OrganicGeometry.loft(p,[Vector3(0,.70,.45),Vector3(0,.75,-.40),Vector3(0,.69,-1.18)],[Vector2(.47,.31),Vector2(.62,.38),Vector2(.35,.23)],c.lightened(.12))
			for s in [-1,1]: OrganicGeometry.tapered(p,Vector3(s*.24,.54,-1.1),Vector3(s*.16,.20,-1.50),.12,.025,CREAM)
		"ape":
			OrganicGeometry.loft(p,[Vector3(0,.72,.65),Vector3(0,1.0,.20),Vector3(0,1.38,-.32),Vector3(0,1.59,-.65)],[Vector2(.62,.47),Vector2(.76,.66),Vector2(.98,.64),Vector2(.50,.42)],c)
			oval(p,Vector3(0,1.59,-.84),Vector3(.47,.48,.44),c)
			oval(p,Vector3(0,1.40,-1.12),Vector3(.37,.23,.20),CREAM.darkened(.15))
			oval(p,Vector3(0,1.10,-.54),Vector3(.67,.49,.13),c.darkened(.18))
		"mole":
			OrganicGeometry.loft(p,[Vector3(0,.63,1.10),Vector3(0,.72,.35),Vector3(0,.78,-.40),Vector3(0,.64,-1.13),Vector3(0,.58,-1.58)],[Vector2(.36,.29),Vector2(.83,.54),Vector2(.85,.56),Vector2(.47,.32),Vector2(.17,.13)],c)
			oval(p,Vector3(0,.58,-1.57),Vector3(.20,.15,.19),Color("c19386"))
		"biomass":
			OrganicGeometry.loft(p,[Vector3(0,.58,1.26),Vector3(.12,.79,.65),Vector3(-.10,.91,-.10),Vector3(.05,.82,-.85),Vector3(0,.70,-1.5)],[Vector2(.20,.19),Vector2(.72,.53),Vector2(.86,.64),Vector2(.54,.36),Vector2(.27,.17)],c)
			oval(p,Vector3(.52,.85,.35),Vector3(.39,.45,.63),c.lightened(.16))
		_:
			OrganicGeometry.loft(p,[Vector3(0,.26,2.65),Vector3(0,.48,1.70),Vector3(0,.78,.65),Vector3(0,.85,-.35),Vector3(0,.98,-1.1),Vector3(0,.90,-1.75)],[Vector2(.025,.025),Vector2(.29,.23),Vector2(.74,.53),Vector2(.80,.57),Vector2(.52,.35),Vector2(.34,.20)],c)
			OrganicGeometry.loft(p,[Vector3(0,.47,.85),Vector3(0,.44,-.45),Vector3(0,.67,-1.62)],[Vector2(.43,.07),Vector2(.51,.11),Vector2(.31,.10)],CREAM)
func _signature(p: Node3D,f: String,tier: int) -> void:
	var t := float(tier)
	var dorsal: Vector3=AnatomyManifest.signature(primary)["anchors"]["dorsal"]
	match f:
		"reptile":
			for i in range(5):
				var a := dorsal+Vector3(0,-.10,i*.30-.6)
				OrganicGeometry.loft(p,[a,a+Vector3(0,.19+.06*t,.03),a+Vector3(0,.27+.10*t,.12)],[Vector2(.15,.12),Vector2(.15,.13),Vector2(.015,.02)],Color("de8a49"))
		"crab":
			OrganicGeometry.loft(p,[dorsal+Vector3(0,-.14,-.65),dorsal+Vector3(0,.04,0),dorsal+Vector3(0,-.08,.72)],[Vector2(.48,.10),Vector2(.79+.06*t,.15+.025*t),Vector2(.48,.07)],Color("cc754d"))
		"snake":
			var mouth: Vector3=AnatomyManifest.signature(primary)["anchors"]["mouth"]
			for s in [-1,1]: OrganicGeometry.tapered(p,mouth+Vector3(s*.28,0,.12),mouth+Vector3(s*.23,-.28,-.06-.04*t),.08+.015*t,.015,CREAM)
		"worm":
			for i in range(4): oval(p,Vector3(0,.24,i*.26-.5),Vector3(.63,.09,.12),CREAM)
		"spider":
			if primary!="spider":
				oval(p,dorsal+Vector3(0,-.10,.32),Vector3(.49,.31,.60),COLORS[5])
		"ape":
			if primary!="ape":
				for s in [-1,1]: oval(p,Vector3(s*.61,.95,-.36),Vector3(.36,.40,.46),COLORS[6])
		"mole":
			if primary!="mole":
				OrganicGeometry.loft(p,[Vector3(0,.55,-.20),Vector3(0,.75,-.80),Vector3(0,.62,-1.40)],[Vector2(.56,.21),Vector2(.59,.34),Vector2(.32,.15)],COLORS[8])
func _build_face() -> void:
	face=Node3D.new();face.name="Face";add_child(face)
	var h: Vector3=AnatomyManifest.signature(primary)["anchors"]["head"]
	if primary=="worm": return
	if primary=="crab":
		for s in [-1,1]:
			link(face,Vector3(s*.37,1.02,-.65),Vector3(s*.48,1.38,-.87),.065,COLORS[4])
			eye(face,Vector3(s*.48,1.38,-.89),.11)
	elif primary=="spider":
		for s in [-1,1]:
			for i in range(3): eye(face,h+Vector3(s*(.12+i*.13),.13-absf(i-1)*.03,-.22),.085)
	else:
		var width := .36 if primary!="mole" else .35
		for s in [-1,1]:
			eye(face,h+Vector3(s*width,.13,-.17),.065 if primary=="mole" else .10)
			oval(face,h+Vector3(s*width,.24,-.15),Vector3(.16,.07,.20),COLORS[GeneRegistry.FORMS.find(primary)].darkened(.20))
	CoastalArt.merge(face,"EyesAndBrows")
func _integrated_support(p: Node3D,f: String) -> void:
	# Further family seeds retain a fitted support expression; no third full rig.
	if f in ["reptile","snake","crab","worm"]:
		_signature(p,f,1)
		return
	var anchor: Vector3=AnatomyManifest.signature(primary)["anchors"]["flanks"]
	var tint: Color=COLORS[GeneRegistry.FORMS.find(f)]
	for side in [-1,1]:
		OrganicGeometry.loft(p,[anchor+Vector3(side*.55,-.16,-.3),anchor+Vector3(side*.65,0,.08),anchor+Vector3(side*.55,-.12,.46)],[Vector2(.05,.08),Vector2(.09,.23),Vector2(.04,.06)],tint)
func _build_wings() -> void:
	var anchor: Vector3=AnatomyManifest.signature(primary)["anchors"]["wing"]
	var length := .58+wing_development*.35+seed_tier*.06
	for s in [-1.0,1.0]:
		var wing := Node3D.new();wing.name="WingShoulder";wing.position=anchor+Vector3(s*.43,0,0);add_child(wing)
		OrganicGeometry.loft(wing,[Vector3.ZERO,Vector3(s*.60,.04,.16),Vector3(s*1.15,0,.26)],[Vector2(.19,.17),Vector2(.23,.16),Vector2(.12,.10)],COLORS[3])
		CoastalArt.merge(wing,"WingArm")
		var wrist := Node3D.new();wrist.name="WingWrist";wrist.position=Vector3(s*1.0,0,.21);wing.add_child(wrist)
		for i in range(7):
			var spread := float(i)/6.0
			var a := Vector3(s*.10*spread,0,spread*.34)
			var b := Vector3(s*(length*(1.0-.35*spread)), -.03,.25+spread*.72)
			OrganicGeometry.loft(wrist,[a,a.lerp(b,.45),b],[Vector2(.16,.055),Vector2(.18,.045),Vector2(.025,.018)],Color("e0bb79") if i%2 else Color("517784"),6)
		CoastalArt.merge(wrist,"FlightFeathers")
		wings.append(wing);wrists.append(wrist)
func _build_supports(active: Array,generic: Dictionary) -> void:
	var radial := primary in ["crab","spider"]
	var count := 8 if radial else (2 if primary=="bird" else (0 if primary in ["snake","worm"] else 4))
	if count==0 and ("mole" in active or "ape" in active or "crab" in active): count=2
	if "spider" in active and not radial: count=8;radial=true
	for i in range(count):
		var s := -1.0 if i<count/2 else 1.0
		var row := i%(count/2)
		var front := row==0 and primary!="bird"
		# Avian shoulders replace front supports on four-limbed hosts.
		if "bird" in active and primary!="bird" and not radial and front: continue
		var joint := Node3D.new();joint.name="Support_%d"%i
		joint.position=Vector3(s*(.55 if not radial else .60),.65,lerpf(-.65,.85,float(row)/maxf(1,count/2.0-1)))
		if primary=="bird" and not radial: joint.position=Vector3(s*.36,.62,.25)
		if primary=="ape" and front: joint.position=Vector3(s*.70,1.30,-.35)
		if primary in ["snake","worm"] and "ape" in active and front: joint.position.y=.95
		add_child(joint)
		var c: Color=COLORS[GeneRegistry.FORMS.find(primary)]
		var muscle := .17+.022*mini(3,int(generic.get("strength",0)))
		if (radial and not (primary=="ape" and front)) or (count==8 and not front):
			var spread := lerpf(-.65,.75,float(row)/3.0)
			link(joint,Vector3.ZERO,Vector3(s*.88,.40,spread*.45),.12,c)
			link(joint,Vector3(s*.88,.40,spread*.45),Vector3(s*1.40,-.55,spread*.70),.085,c.lightened(.13))
			if wall_hooks:
				var toe := Vector3(s*1.40,-.55,spread*.70)
				OrganicGeometry.loft(joint,[toe,toe+Vector3(s*.09,-.06,-.11),toe+Vector3(0,-.08,-.22)],[Vector2(.085,.07),Vector2(.06,.045),Vector2(.018,.02)],CREAM)
		else:
			var end := Vector3(s*.18,-.53,-.12-(grasp_tier*.11 if front else 0.0))
			if primary=="ape" and front: end=Vector3(s*.56,-.94,-.66)
			elif primary in ["snake","worm"] and "ape" in active and front: end=Vector3(s*.56,-.70,-.66)
			link(joint,Vector3.ZERO,end,muscle*(1.65 if primary=="ape" and front else 1.0),c)
			if front and forelimb_kind=="pincer":
				oval(joint,end,Vector3(.33,.25,.39),COLORS[4])
				for k in [-1,1]:
					OrganicGeometry.loft(joint,[end+Vector3(k*.13,0,-.20),end+Vector3(k*.26,0,-.48),end+Vector3(k*.08,0,-.76)],[Vector2(.16,.15),Vector2(.12,.13),Vector2(.025,.03)],Color("e19161"))
			elif front and forelimb_kind=="spade":
				oval(joint,end,Vector3(.39,.18,.38),c.lightened(.20))
				for k in range(4): OrganicGeometry.tapered(joint,end+Vector3((k-1.5)*.17,0,-.22),end+Vector3((k-1.5)*.20,-.08,-.77),.095,.025,CREAM)
			elif primary=="bird":
				link(joint,end+Vector3(0,.23,.06),end,.09,CREAM)
				for k in [-1,0,1]: OrganicGeometry.tapered(joint,end, end+Vector3(k*.12,-.04,-.40-grasp_tier*.10),.06+grasp_tier*.01,.018,INK)
			else: oval(joint,end,Vector3(.36 if primary=="ape" and front else .27,.27 if primary=="ape" and front else .15,.33),c.lightened(.13))
		CoastalArt.merge(joint,"WorkingSupport")
		joints.append(joint)
func _build_tendrils() -> void:
	for i in range(4):
		var p := Node3D.new();p.position=Vector3(-.55 if i%2==0 else .55,.9,float(i/2)*.6-.05);add_child(p)
		var s := -1.0 if i%2==0 else 1.0
		OrganicGeometry.loft(p,[Vector3.ZERO,Vector3(s*.27,.38,.08),Vector3(s*.53,.55,-.12),Vector3(s*.58,.43,-.42)],[Vector2(.20,.18),Vector2(.14,.12),Vector2(.07,.06),Vector2(.015,.02)],Color("d58b9b"))
		CoastalArt.merge(p,"LivingTendril");tendrils.append(p)
func _build_pincers(generic: Dictionary) -> void:
	for s in [-1.0,1.0]:
		var arm := Node3D.new();arm.name="Cheliped";arm.position=Vector3(s*.72,.72,-.60);add_child(arm)
		var end := Vector3(s*.75,-.06,-.80)
		var strength := mini(3,int(generic.get("strength",0)))
		link(arm,Vector3.ZERO,Vector3(s*.50,.02,-.28),.25,COLORS[4])
		link(arm,Vector3(s*.50,.02,-.28),end,.26+strength*.035,COLORS[4])
		oval(arm,end,Vector3(.33+strength*.035,.24,.37),Color("d98251"))
		for k in [-1,1]:
			OrganicGeometry.loft(arm,[end+Vector3(k*.14,0,-.18),end+Vector3(k*.27,0,-.52),end+Vector3(k*.07,0,-.85)],[Vector2(.15,.16),Vector2(.12,.12),Vector2(.02,.025)],CREAM)
		CoastalArt.merge(arm,"PincerHand");joints.append(arm)
func animate(phase: float,moving: bool) -> void:
	for i in range(joints.size()):
		var stagger: float= float(i%4)*PI*.5+(PI if i>=joints.size()/2 else 0)
		joints[i].rotation.x=sin(phase+stagger)*(.20 if primary in ["spider","crab"] else .30) if moving else 0.0
		joints[i].rotation.z=sin(phase+stagger)*.12 if moving and primary in ["spider","crab"] else 0.0
		if movement_mode=="burrow" and primary=="mole": joints[i].rotation.x=sin(phase*2+i*PI)*.6
	for i in range(wings.size()):
		var airborne := movement_mode in ["flight","glide","landing","falling"]
		var flap := sin(flight_clock*7.0)*.32 if movement_mode=="flight" else .03*sin(flight_clock)
		var s := 1.0 if i==0 else -1.0
		wings[i].rotation.z=s*(flap if airborne else .95)+bank*.12
		wings[i].rotation.y=s*(.06 if airborne else -.48)
		wrists[i].rotation.y=s*(.08 if airborne else -.85)
	for i in range(tendrils.size()): tendrils[i].rotation.z=sin(phase*.7+i)*.14
	rotation.z=lerpf(rotation.z,bank if movement_mode in ["flight","glide"] else 0.0,.18)
	rotation.x=lerpf(rotation.x,PI*.46 if movement_mode=="climb" else 0.0,.18)
	if is_instance_valid(face): face.position.z=-.09*bite
