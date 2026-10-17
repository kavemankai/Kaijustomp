class_name WorldEnvironmentArt
extends RefCounted
## Additions to the approved kit: readable towers, farm sheds and restricted sites.

static func tower(root: Node3D, size: Vector2, height: float, title: String) -> void:
	CoastalArt.box(root,Vector3(0,height*.5,0),Vector3(size.x,height,size.y),Color("a9bdbd"))
	CoastalArt.box(root,Vector3(0,2,0),Vector3(size.x+3,4,size.y+3),Color("d4cbb6"))
	for floor_index in range(1,int(height/4)):
		var y := floor_index*4.0+1
		for side in [-1,1]:
			CoastalArt.box(root,Vector3(0,y,side*(size.y*.5+.06)),Vector3(size.x*.88,1.6,.12),Color("5f8793"))
			CoastalArt.box(root,Vector3(side*(size.x*.5+.06),y,0),Vector3(.12,1.6,size.y*.88),Color("5f8793"))
	CoastalArt.box(root,Vector3(0,height+1,0),Vector3(size.x*.7,2,size.y*.65),CoastalArt.ROOF)
	if title=="Civic Tower": CoastalArt.box(root,Vector3(0,height+6,0),Vector3(.5,10,.5),CoastalArt.INK)
	CoastalArt.merge(root,"Architecture")
	CoastalArt.shadow(root,size+Vector2(3,3))

static func restricted(root: Node3D,size: Vector2,height: float,title: String) -> void:
	CoastalArt.industrial_building(root,size,height,title)
	var fittings := Node3D.new()
	root.add_child(fittings)
	for side in [-1,1]:
		CoastalArt.box(fittings,Vector3(side*size.x*.43,height+2,size.y*.35),Vector3(5,4,5),Color("728775"))
		CoastalArt.box(fittings,Vector3(side*size.x*.43,height+4.5,size.y*.35),Vector3(6,1,6),CoastalArt.INK)
	CoastalArt.oval(fittings,Vector3(0,height+3,0),Vector3(4,1.5,4),Color("b3c0ad"))
	CoastalArt.merge(fittings,"MilitaryFittings")

static func landscape(root: Node3D,c: Vector2i,kind: int) -> void:
	if kind==4:
		for row in range(6):
			CoastalArt.box(root,Vector3(c.x*256+25,-.14,c.y*256+45+row*30),Vector3(13,.2,22),Color("abb17d"))
		for i in range(7):
			var at := Vector3(c.x*256+128,0,c.y*256+28+i*32)
			CoastalArt.box(root,at+Vector3(0,3,0),Vector3(.8,6,.8),Color("8d816b"))
			CoastalArt.oval(root,at+Vector3(0,7,0),Vector3(5,5,4),Color("648373"))
	elif kind==3:
		# Utility infrastructure is scenery; warehouses remain the destructible targets.
		for i in range(4):
			CoastalArt.box(root,Vector3(c.x*256+32,1.4,c.y*256+38+i*42),Vector3(8,2.8,22),Color("748f89") if i%2==0 else Color("b49b80"))
	elif kind==5:
		CoastalArt.box(root,Vector3(c.x*256+128,-.1,c.y*256+128),Vector3(20,.12,256),Color("52676b"))
		for i in range(8):
			CoastalArt.box(root,Vector3(c.x*256+128,-.025,c.y*256+i*32+12),Vector3(1,.02,12),CoastalArt.CREAM)
