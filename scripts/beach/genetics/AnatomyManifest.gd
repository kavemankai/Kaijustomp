class_name AnatomyManifest
extends RefCounted
## Body-relative anchors, not universal reptile-space coordinates.
const SOCKETS := ["head","mouth","neck","shoulder","forelimbs","hindlimbs","dorsal","abdomen","flanks","tail","wing","shell","segment_anterior","segment_mid","segment_rear"]
static func signature(family: String) -> Dictionary:
	var plan := "quadruped"
	var support := 4
	var anchor := {
		"head":Vector3(0,1.05,-1.3),"mouth":Vector3(0,.78,-1.65),
		"neck":Vector3(0,1.15,-.9),"shoulder":Vector3(0,1.15,-.5),
		"forelimbs":Vector3(0,.70,-.85),"hindlimbs":Vector3(0,.7,.85),
		"dorsal":Vector3(0,1.45,.2),"abdomen":Vector3(0,.8,.5),
		"flanks":Vector3(0,.90,.2),"tail":Vector3(0,.6,1.55),
		"wing":Vector3(0,1.25,-.1),"shell":Vector3(0,1.32,.2),
		"segment_anterior":Vector3(0,.6,-.6),"segment_mid":Vector3(0,.6,.6),"segment_rear":Vector3(0,.55,1.55)}
	match family:
		"biomass":
			plan="tissue_crawler";support=4
			anchor["head"]=Vector3(0,.78,-.9);anchor["mouth"]=Vector3(0,.61,-1.45)
			anchor["dorsal"]=Vector3(-.10,1.40,.05)
		"snake":
			plan = "surface_slither"; support=0
			anchor["head"]=Vector3(0,1.45,-1.2);anchor["mouth"]=Vector3(0,1.35,-1.8)
			anchor["dorsal"]=Vector3(0,.8,.65);anchor["flanks"]=Vector3(0,.45,.6)
			anchor["neck"]=Vector3(0,1.12,-.75);anchor["shoulder"]=Vector3(0,.85,-.35)
			anchor["wing"]=Vector3(0,.9,-.3);anchor["forelimbs"]=Vector3(0,.55,-.55)
		"worm":
			plan = "axial_crawler";support=0
			anchor["head"]=Vector3(0,.65,-1.25);anchor["mouth"]=Vector3(0,.6,-1.5)
			anchor["dorsal"]=Vector3(0,.85,.6)
			anchor["neck"]=Vector3(0,.6,-.65);anchor["shoulder"]=Vector3(0,.6,-.35)
			anchor["flanks"]=Vector3(0,.55,0);anchor["wing"]=Vector3(0,.7,-.2)
			anchor["forelimbs"]=Vector3(0,.45,-.65)
		"bird":
			plan = "avian_ground";support=2
			anchor["head"]=Vector3(0,1.88,-1.0);anchor["mouth"]=Vector3(0,1.75,-1.65)
			anchor["wing"]=Vector3(0,1.3,.05);anchor["dorsal"]=Vector3(0,1.55,.4)
		"crab":
			plan="lateral_ground";support=8;anchor["shell"]=Vector3(0,1.1,.2)
			anchor["head"]=Vector3(0,.95,-.85);anchor["mouth"]=Vector3(0,.65,-1.15)
			anchor["dorsal"]=Vector3(0,1.15,.2);anchor["forelimbs"]=Vector3(0,.65,-.75)
		"spider":
			plan="arachnid_ground";support=8;anchor["abdomen"]=Vector3(0,.8,1.05)
			anchor["head"]=Vector3(0,.82,-.95);anchor["mouth"]=Vector3(0,.55,-1.25)
			anchor["dorsal"]=Vector3(0,1.15,.8);anchor["forelimbs"]=Vector3(0,.65,-.6)
		"ape":
			plan="knuckle_ground";support=4;anchor["shoulder"]=Vector3(0,1.45,-.4)
			anchor["head"]=Vector3(0,1.6,-.8)
			anchor["mouth"]=Vector3(0,1.35,-1.15);anchor["forelimbs"]=Vector3(0,1.3,-.35)
		"mole":
			plan="dig_ground";support=4;anchor["forelimbs"]=Vector3(0,.5,-.95)
			anchor["head"]=Vector3(0,.78,-.9);anchor["mouth"]=Vector3(0,.55,-1.45)
			anchor["dorsal"]=Vector3(0,1.15,.25)
	return {"family":family,"plan":plan,"supports":support,"anchors":anchor}
static func socket_for_gene(gene_id: int) -> String:
	if gene_id in [1,7,11,12,14,30,43,57,95]: return "head"
	if gene_id in [2,6,9,20,72,85,90]: return "dorsal"
	if gene_id in [19,88,441]: return "tail"
	if gene_id in [29,36,39,121,122]: return "wing"
	if gene_id in [15,44,52,61,62,73,119,180]: return "forelimbs"
	if gene_id in [42,47,49,58,81,99,100]: return "flanks"
	return "abdomen"

class OrganSocket extends RefCounted:
	var owner_family: String
	var semantic: String
	var pose: Transform3D
	var bounds: Vector3
	var segment_fraction := -1.0
	var support: String
	var operations := ["add","alter","replace","remove","overlay"]
	func _init(host: String, key: String, at: Vector3, extent: Vector3, kind: String) -> void:
		owner_family=host;semantic=key;pose=Transform3D(Basis.IDENTITY,at);bounds=extent;support=kind

static func sockets(host: String) -> Dictionary:
	var result := {}
	var manifest := signature(host)
	for key in manifest["anchors"]:
		var extent := Vector3(.7,.4,.8)
		if key in ["head","mouth"]: extent=Vector3(.5,.3,.4)
		if key=="wing": extent=Vector3(2.4,.4,1.4)
		var socket := OrganSocket.new(host,key,manifest["anchors"][key],extent,String(manifest["plan"]))
		if host in ["snake","worm"] and key.begins_with("segment_"):
			socket.segment_fraction={"segment_anterior":.12,"segment_mid":.5,"segment_rear":.82}[key]
		result[key]=socket
	return result

static func generic_socket(key: String, host: String) -> String:
	if key=="jaw": return "mouth"
	if key in ["armour","cocoon","metamorphosis"]: return "dorsal"
	if key in ["strength","speed"]: return "segment_anterior" if host in ["snake","worm"] else "forelimbs"
	return "flanks"

static func expression(host: String, key: String, rank: int) -> Dictionary:
	var source := int(GeneRegistry.definitions()[key]["source_id"])
	var socket := generic_socket(key,host) if source==0 else socket_for_gene(source)
	var operation := "alter"
	if key in ["armour","cocoon","regen","metamorphosis"]: operation="overlay"
	if source>0: operation="add"
	if source in [6,11,15,22,44,61,62,84,100]: operation="alter"
	return {"owner":host,"gene":key,"source_id":source,"rank":rank,"tier":clampi(rank,1,3),
		"socket":socket,"operation":operation,"organ":host+"_"+key,"support":signature(host)["plan"]}
