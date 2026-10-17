class_name MutationExpressionLibrary
extends RefCounted
## Socket-local tissue expressions. Every tier develops one organ, not copies.
const CREAM := Color("edd8b0")
const TEAL := Color("76b8a2")
const CORAL := Color("da865c")
static func oval(p: Node3D, at: Vector3, size: Vector3, tint: Color) -> void:
	CoastalArt.oval(p,at,size,tint)
static func bone(p: Node3D,a: Vector3,b: Vector3,r: float,c: Color) -> void:
	OrganicGeometry.tapered(p,a,b,r,r*.18,c)
static func frame(root: Node3D, host: String, key: String, tier: int) -> Node3D:
	var spec := AnatomyManifest.expression(host,key,tier)
	var socket: AnatomyManifest.OrganSocket=AnatomyManifest.sockets(host)[spec["socket"]]
	var n := Node3D.new()
	n.name=spec["organ"]
	n.transform=socket.pose
	n.set_meta("expression",spec)
	root.add_child(n)
	return n
static func render(root: Node3D, host: String, generic: Dictionary) -> void:
	for key in GeneRegistry.LEGACY:
		var rank := clampi(int(generic.get(key,0)),0,3)
		if rank==0: continue
		var p := frame(root,host,key,rank)
		var t := float(rank)
		var axial := host in ["snake","worm"]
		var hard := host in ["crab","spider"]
		var skin: Color=CreatureMorphology.COLORS[GeneRegistry.FORMS.find(host)]
		match key:
			"armour","cocoon":
				var c: Color= CORAL if key=="armour" else CREAM
				if host=="biomass": c=skin.lightened(.22)
				for i in range(4):
					var z := float(i)*.32-.55
					# Embedded overlapping scutes follow the dorsal curvature.
					var w := (.44+.065*t)*(1.0 if not hard else 1.6)
					OrganicGeometry.loft(p,[Vector3(0,-.14,z-.2),Vector3(0,.06+t*.035,z),Vector3(0,-.05,z+.23)], [Vector2(w*.7,.05),Vector2(w,.07+t*.02),Vector2(w*.65,.04)],c)
			"jaw":
				if host=="worm":
					for i in range(10):
						var a := TAU*i/10.0
						bone(p,Vector3(cos(a)*.54,sin(a)*.50,0),Vector3(cos(a)*(.38-.04*t),sin(a)*(.36-.03*t),-.12-.09*t),.065+.02*t,CREAM)
				elif host=="bird":
					OrganicGeometry.loft(p,[Vector3(0,0,.1),Vector3(0,0,-.3),Vector3(0,-.08,-.55-.09*t)],[Vector2(.23,.16),Vector2(.25+.025*t,.13),Vector2(.015,.03)],CREAM)
				else:
					OrganicGeometry.loft(p,[Vector3(0,0,.25),Vector3(0,-.05,-.10),Vector3(0,-.03,-.38-.06*t)],[Vector2(.34,.12),Vector2(.39+.025*t,.11+.02*t),Vector2(.20,.06)],CREAM)
			"strength","speed":
				if axial:
					for s in [-1,1]:
						var x := .65 if host=="worm" else .48
						OrganicGeometry.loft(p,[Vector3(s*.40,-.08,-.45),Vector3(s*x,0,.15),Vector3(s*.34,-.05,.7)],[Vector2(.08,.10),Vector2(.14+.05*t,.18+.03*t),Vector2(.06,.07)],skin.lightened(.12) if key=="strength" else TEAL)
				elif host in ["crab","spider"]:
					# Joint sheaths integrated with the radial leg roots, no extra legs.
					for s in [-1,1]:
						for i in range(4):
							oval(p,Vector3(s*.78,-.02,float(i)*.44-.2),Vector3(.23+.025*t,.13+.02*t,.18),skin.lightened(.20))
				elif host=="bird":
					for s in [-1,1]:
						bone(p,Vector3(s*.38,.13,.8),Vector3(s*.42,-.34,.7),.12+.035*t,skin.lightened(.20))
				else:
					for s in [-1,1]:
						oval(p,Vector3(s*.65,-.08,0),Vector3(.23+.055*t,.27+.04*t,.35),skin.lightened(.12))
			"metamorphosis":
				var lift: float={"crab":.20,"bird":.18,"spider":.22,"mole":.10,"biomass":.10}.get(host,0.0)
				for side in [-1,1]:
					for i in range(3):
						var a := Vector3(side*.20,lift,float(i)*.30-.35)
						OrganicGeometry.loft(p,[a+Vector3(0,-.12,-.16),a+Vector3(0,.10+.06*t,0),a+Vector3(0,-.08,.20)],[Vector2(.10,.035),Vector2(.12+.025*t,.05+.02*t),Vector2(.07,.025)],TEAL)
			"stamina","health","regen":
				var c: Color= skin.lightened(.12) if key=="health" else TEAL
				if host=="biomass": c=Color("d989a0")
				for s in [-1,1]:
					# Broad flush tissue panels, air-sac rib feathers or shell seams.
					for i in range(3):
						var z := float(i)*.28-.2
						var x := .68 if host=="worm" else (.48 if host=="snake" else (.56 if host=="bird" else (1.16 if host=="crab" else (.84 if host=="biomass" else .70))))
						var n := CoastalArt.oval(p,Vector3(s*x,-.03,z),Vector3(.09+.035*t,.14+.035*t,.22),c)
						if host=="bird": n.rotation.x=-.4

static func render_source(root: Node3D,host: String,id: int,rank: int) -> void:
	# Seed organs are built by the host and hybrid composer.
	if id in GeneRegistry.SEEDS: return
	if id==19 and host in ["snake","worm"]: return # Moving fractional organ, not an anterior decoration.
	# Flight organs are attached to moving wing pivots, never baked twice.
	if id in [29,121,122,180]: return
	var p := frame(root,host,"gene_%03d"%id,rank)
	var skin: Color=CreatureMorphology.COLORS[GeneRegistry.FORMS.find(host)]
	match id:
		1:
			p.position=AnatomyManifest.signature(host)["anchors"]["mouth"]
			for s in [-1,1]: bone(p,Vector3(0,0,0),Vector3(s*.13,-.08,-.57),.035,Color("a85975"))
		2,20,81,90,99:
			for s in [-1,1]:
				for i in range(3):
					var c: Color= {2:CREAM,20:Color("52775c"),81:TEAL,90:CORAL,99:Color("adc06d")}[id]
					oval(p,Vector3(s*.60,-.13,i*.25-.35),Vector3(.09,.15,.26),c)
		7,12,43:
			p.position=AnatomyManifest.signature(host)["anchors"]["mouth"]
			for s in [-1,1]:
				if id==7: oval(p,Vector3(s*.27,.03,.03),Vector3(.13,.15,.20),Color("9bbd52"))
				else: bone(p,Vector3(s*.27,.02,0),Vector3(s*.24,-.25,-.24),.10,CREAM)
		9,72:
			for i in range(4): bone(p,Vector3(0,-.12,i*.35-.45),Vector3(0,.34,i*.35-.32),.13,CREAM if id==9 else CORAL)
		14,30,57,95:
			for s in [-1,1]:
				for i in range(2): oval(p,Vector3(s*(.28+i*.09),.08,-.31),Vector3(.065,.08,.04),Color("f3c76d") if id in [30,57] else TEAL)
		19:
			oval(p,Vector3(0,0,0),Vector3(.42,.25,.49),CORAL)
		36:
			for s in [-1,1]: bone(p,Vector3(s*.60,-.06,0),Vector3(s*.94,.02,-.25),.12,CREAM)
		39,47,49,58:
			for s in [-1,1]: oval(p,Vector3(s*.60,-.05,.1),Vector3(.12,.26,.38),skin.lightened(.20) if id!=47 else CORAL)
		42:
			for s in [-1,1]:
				for i in range(5): bone(p,Vector3(s*.55,-.08,i*.23-.35),Vector3(s*.66,.18,i*.23-.2),.055,CREAM)
		73:
			for s in [-1,1]: oval(p,Vector3(s*.74,-.10,0),Vector3(.18,.14,.21),TEAL)
		85:
			OrganicGeometry.loft(p,[Vector3(0,-.12,-.5),Vector3(0,.28,0),Vector3(0,-.12,.7)],[Vector2(.5,.13),Vector2(.8,.35),Vector2(.35,.10)],Color("b69b76"))
		88:
			p.position=AnatomyManifest.signature(host)["anchors"]["neck"]
			bone(p,Vector3(0,0,0),Vector3(0,.72,-.3),.055,TEAL)
			oval(p,Vector3(0,.72,-.3),Vector3(.13,.14,.13),Color("eddb7c"))
		441:
			for s in [-1,1]: bone(p,Vector3(s*.38,.12,0),Vector3(s*.53,.20,-.2),.08,skin.darkened(.25))
		52,119:
			# Ventral digging keels; Mole's working fore-spades are articulated.
			for s in [-1,1]:
				OrganicGeometry.loft(p,[Vector3(s*.35,-.1,.15),Vector3(s*.55,-.17,-.25),Vector3(s*.50,-.28,-.65)],[Vector2(.18,.14),Vector2(.29,.12),Vector2(.25,.02)],CREAM)
		180:
			for s in [-1,1]:
				for i in range(4): bone(p,Vector3(s*.78,-.18,i*.46-.2),Vector3(s*.91,-.38,i*.46-.30),.055,CREAM)
