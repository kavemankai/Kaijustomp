class_name MutationExpressionLibrary
extends RefCounted
## Render semantic organs at host sockets; the same stat upgrade must not
## produce reptile paws or back plates on every biological body.
const COLORS := [Color("eccd95"),Color("dc8151"),Color("7dbcb2"),Color("b76f86")]
static func _oval(parent: Node3D, at: Vector3, axes: Vector3, tint: Color) -> void:
	CoastalArt.oval(parent,at,axes,tint)
static func _bone(parent: Node3D, a: Vector3,b: Vector3,thick: float,tint: Color) -> void:
	var n := CoastalArt.oval(parent,(a+b)*.5,Vector3(thick,a.distance_to(b)*.5,thick),tint)
	n.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
static func _rank(generic_ranks: Dictionary, k: String) -> int:
	return mini(3,int(generic_ranks.get(k,0)))
static func render(root: Node3D, host: String, generic: Dictionary) -> void:
	var template := AnatomyManifest.signature(host)
	var anchors: Dictionary = template["anchors"]
	var dorsal: Vector3 = anchors["dorsal"]
	var head: Vector3 = anchors["head"]
	var shoulder: Vector3 = anchors["shoulder"]
	var flanks: Vector3 = anchors["flanks"]
	var tail: Vector3 = anchors["tail"]
	var limbs: Vector3 = anchors["forelimbs"]
	var armour := _rank(generic,"armour")
	var strength := _rank(generic,"strength")
	var speed := _rank(generic,"speed")
	var stamina := _rank(generic,"stamina")
	var health := _rank(generic,"health")
	var jaw := _rank(generic,"jaw")
	var regen := _rank(generic,"regen")
	var cocoon := _rank(generic,"cocoon")
	var meta := _rank(generic,"metamorphosis")
	if armour>0:
		var root_pos := anchors["shell"] if host in ["crab","spider"] else dorsal
		if host in ["snake","worm"]:
			for i in range(1+armour*2):
				_oval(root,root_pos+Vector3(0,.16,float(i)*.39),Vector3(.41+armour*.07,.14,.13),COLORS[1])
		elif host=="bird":
			for side in [-1,1]:
				for i in range(armour+1):
					_oval(root,root_pos+Vector3(side*(.35+i*.16),.08,.1+i*.17),Vector3(.20,.08,.31),COLORS[0])
		elif host=="ape":
			for side in [-1,1]:
				_oval(root,shoulder+Vector3(side*.75,.14,0),Vector3(.37+armour*.11,.33+armour*.07,.39),COLORS[1])
		else:
			for i in range(2+armour):
				_oval(root,root_pos+Vector3(0,.13,float(i)*.36),Vector3(.40+armour*.12,.13,.23),COLORS[1])
	if strength>0:
		if host in ["snake","worm"]:
			for side in [-1,1]:
				_oval(root,flanks+Vector3(side*.45,0,.20),Vector3(.22+strength*.11,.18+strength*.07,1.0),COLORS[3])
		elif host=="crab":
			for side in [-1,1]:
				_oval(root,limbs+Vector3(side*1.42,.12,-.62),Vector3(.32+strength*.16,.26+strength*.10,.47+strength*.10),COLORS[1])
		elif host=="bird":
			for side in [-1,1]:
				_bone(root,limbs+Vector3(side*.54,0,-.48),limbs+Vector3(side*.54,-.7,-.96),.12+strength*.07,COLORS[0])
		else:
			for side in [-1,1]:
				_oval(root,limbs+Vector3(side*.65,-.1,0),Vector3(.20+strength*.13,.36+strength*.14,.42),COLORS[1])
	if speed>0:
		if host in ["snake","worm"]:
			for i in range(speed*2):
				_oval(root,tail+Vector3(0,.15,float(i)*.22),Vector3(.32,.09,.14),COLORS[2])
		elif host in ["bird","spider","crab"]:
			for side in [-1,1]:
				_bone(root,limbs+Vector3(side*.55,.1,.5),limbs+Vector3(side*(.95+speed*.16),.1,.82),.07+speed*.025,COLORS[2])
		else:
			for side in [-1,1]:
				_oval(root,limbs+Vector3(side*.68,-.35,0),Vector3(.15+speed*.04,.25,.40),COLORS[2])
	if stamina>0:
		for side in [-1,1]:
			for i in range(stamina):
				_oval(root,flanks+Vector3(side*.57,.14,float(i)*.25),Vector3(.11+stamina*.025,.23,.20),COLORS[2])
	if health>0:
		var target: Vector3 = anchors["abdomen"]
		if host=="bird": target=anchors["shoulder"]
		_oval(root,target,Vector3(.30+health*.18,.24+health*.09,.38+health*.15),COLORS[3])
	if jaw>0:
		_oval(root,head+Vector3(0,-.32,-.44),Vector3(.32+jaw*.07,.11,.28+jaw*.08),COLORS[0])
	if regen>0:
		for side in [-1,1]:
			for i in range(regen):
				_oval(root,flanks+Vector3(side*.52,.10+i*.19,.4),Vector3(.11,.12,.18),COLORS[2])
	if cocoon>0:
		for i in range(cocoon+2):
			_oval(root,dorsal+Vector3(0,.28,float(i)*.35),Vector3(.33+cocoon*.07,.07,.13),COLORS[0])
	if meta>0:
		for side in [-1,1]:
			for i in range(meta+1):
				_bone(root,dorsal+Vector3(side*.16,0,float(i)*.31),dorsal+Vector3(side*.25,.30+meta*.09,float(i)*.31),.06,COLORS[2])
static func trait_frame(root: Node3D, host: String, gene_id: int) -> Node3D:
	var socket := AnatomyManifest.socket_for_gene(gene_id)
	var manifest := AnatomyManifest.signature(host)
	var anchors: Dictionary = manifest["anchors"]
	# Historical trait meshes used these reptilian reference positions.
	var reference: Dictionary = {
		"head":Vector3(0,1.08,-1.25),"mouth":Vector3(0,.75,-1.55),
		"dorsal":Vector3(0,1.3,.15),"flanks":Vector3(0,.90,.1),
		"forelimbs":Vector3(0,.7,-.7),"tail":Vector3(0,.6,1.55),
		"wing":Vector3(0,1.1,0),"abdomen":Vector3(0,.8,.5)}
	var frame := Node3D.new()
	frame.name="Trait_%03d" % gene_id
	frame.position=Vector3(anchors.get(socket,Vector3.ZERO))-Vector3(reference.get(socket,Vector3.ZERO))
	if host in ["snake","worm"]:
		frame.scale=Vector3(.65,.78,.70)
	if host=="bird" and socket=="wing":
		frame.scale=Vector3(.76,.74,.78)
	root.add_child(frame)
	return frame
