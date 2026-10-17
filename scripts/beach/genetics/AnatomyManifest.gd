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
		"snake":
			plan = "surface_slither"; support=0
			anchor["head"]=Vector3(0,1.45,-1.2);anchor["mouth"]=Vector3(0,1.35,-1.8)
			anchor["dorsal"]=Vector3(0,.8,.65);anchor["flanks"]=Vector3(0,.45,.6)
		"worm":
			plan = "axial_crawler";support=0
			anchor["head"]=Vector3(0,.65,-1.25);anchor["mouth"]=Vector3(0,.6,-1.5)
			anchor["dorsal"]=Vector3(0,.85,.6)
		"bird":
			plan = "avian_ground";support=2
			anchor["head"]=Vector3(0,1.88,-1.0);anchor["mouth"]=Vector3(0,1.75,-1.65)
			anchor["wing"]=Vector3(0,1.3,.05);anchor["dorsal"]=Vector3(0,1.55,.4)
		"crab":
			plan="lateral_ground";support=8;anchor["shell"]=Vector3(0,1.1,.2)
		"spider":
			plan="arachnid_ground";support=8;anchor["abdomen"]=Vector3(0,.8,1.05)
		"ape":
			plan="knuckle_ground";support=4;anchor["shoulder"]=Vector3(0,1.45,-.4)
			anchor["head"]=Vector3(0,1.6,-.8)
		"mole":
			plan="dig_ground";support=4;anchor["forelimbs"]=Vector3(0,.5,-.95)
	return {"family":family,"plan":plan,"supports":support,"anchors":anchor}
static func socket_for_gene(gene_id: int) -> String:
	if gene_id in [1,7,11,12,14,30,43,57,95]: return "head"
	if gene_id in [2,6,9,20,72,85,90]: return "dorsal"
	if gene_id in [19,88,441]: return "tail"
	if gene_id in [29,36,39,121,122]: return "wing"
	if gene_id in [15,44,52,61,62,73,119,180]: return "forelimbs"
	if gene_id in [42,47,49,58,81,99,100]: return "flanks"
	return "abdomen"
