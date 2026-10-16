class_name CoastalArt
extends RefCounted
## Decorative coastal kit. No physics bodies or gameplay state in this layer.

const INK := Color("263f49")
const CREAM := Color("f0e4c7")
const SAGE := Color("829582")
const ROOF := Color("648384")
static var palette: StandardMaterial3D
static var shadow_material: ShaderMaterial

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var render := MeshInstance3D.new()
	render.mesh = mesh
	render.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	render.material_override = material
	parent.add_child(render)
	return render

static func oval(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 4
	mesh.radius = 1
	mesh.height = 2
	var render := box(parent, pos, Vector3.ONE, color)
	render.mesh = mesh
	render.scale = size
	return render

static func merge(root: Node3D, name: String = "CoastalMesh") -> MeshInstance3D:
	# One vertex-coloured surface per spatial chunk/building, not per board/window.
	if palette == null:
		palette = StandardMaterial3D.new()
		palette.vertex_color_use_as_albedo = true
		palette.roughness = .88
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for child in root.get_children():
		if not child is MeshInstance3D:
			continue
		var color: Color = child.get_active_material(0).albedo_color
		var source := SurfaceTool.new()
		source.create_from(child.mesh, 0)
		source.deindex()
		var arrays := source.commit_to_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in range(vertices.size()):
			st.set_color(color)
			st.set_normal((child.basis.inverse().transposed() * normals[i]).normalized())
			st.add_vertex(child.transform * vertices[i])
		root.remove_child(child)
		child.free()
	st.index()
	var render := MeshInstance3D.new()
	render.name = name
	render.mesh = st.commit()
	render.material_override = palette
	root.add_child(render)
	return render

static func shadow(parent: Node3D, size: Vector2, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	if shadow_material == null:
		var shader := Shader.new()
		shader.code = "shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; void fragment(){float r=length((UV-vec2(0.5))*2.0); ALBEDO=vec3(0.12,0.20,0.20); ALPHA=(1.0-smoothstep(0.35,1.0,r))*0.24;}"
		shadow_material = ShaderMaterial.new()
		shadow_material.shader = shader
	var render := MeshInstance3D.new()
	render.name = "ContactShadow"
	var plane := PlaneMesh.new()
	plane.size = size
	render.mesh = plane
	render.material_override = shadow_material
	render.position = position + Vector3(0, .025, 0)
	render.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	render.set_meta("exclude_shed", true)
	parent.add_child(render)
	return render

static func building(root: Node3D, footprint: Vector2, height: float, title: String) -> void:
	var w := footprint.x
	var d := footprint.y
	var cafe := title == "Cafe"
	var small := height < 5
	var wall := Color("d7b99b") if cafe else (Color("dce0ca") if small else Color("cfccc0"))
	box(root, Vector3(0,height/2,0), Vector3(w,height,d), wall)
	box(root, Vector3(0,.20,0), Vector3(w+.05,.40,d+.05), Color("9d9e8b"))
	box(root, Vector3(0,height-.12,0), Vector3(w+.12,.24,d+.12), CREAM)
	# Roof ridges stay above the physical footprint, without false wall volumes.
	if small:
		for side in [-1.0,1.0]:
			var roof := box(root, Vector3(side*w*.25,height+.35,0), Vector3(w*.52,.18,d+.30), ROOF if not cafe else Color("b6775a"))
			roof.rotation.z = side * -.16
		for z in range(int(d/1.3)):
			box(root,Vector3(0,height+.52,-d/2+z*1.3),Vector3(w,.045,.10),ROOF.lightened(.15) if not cafe else Color("ca9671"))
	else:
		box(root,Vector3(0,height+.1,0),Vector3(w,.2,d),ROOF)
		box(root,Vector3(-w*.22,height+.48,-d*.15),Vector3(w*.32,.76,d*.30),CREAM)
	# Windows inset visually with strong dark recesses and cream frames.
	for side in [-1.0,1.0]:
		for floor_index in range(1 if small else 2):
			var y := 1.35+floor_index*2.75
			for index in range(maxi(2,int(w/3))):
				var x := -w*.36+index*w*.72/float(maxi(1,int(w/3)-1))
				box(root,Vector3(x,y,side*(d/2+.035)),Vector3(1.35,1.55,.08),CREAM)
				box(root,Vector3(x,y,side*(d/2+.085)),Vector3(1.10,1.28,.035),INK)
				box(root,Vector3(x-.20,y+.12,side*(d/2+.11)),Vector3(.45,1.00,.02),Color("739598"))
	# Side windows make the usual three-quarter camera informative.
	for side in [-1.0,1.0]:
		for z in [-d*.26,d*.26]:
			box(root,Vector3(side*(w/2+.025),height*.52,z),Vector3(.06,1.5,1.4),CREAM)
			box(root,Vector3(side*(w/2+.065),height*.52,z),Vector3(.025,1.25,1.12),INK)
	box(root,Vector3(0,1.05,d/2+.1),Vector3(1.05,2.10,.08),INK)
	box(root,Vector3(.32,1.0,d/2+.155),Vector3(.07,.19,.04),CREAM)
	if small:
		for i in range(int(height/.40)):
			box(root,Vector3(0,.46+i*.40,d/2+.015),Vector3(w,.025,.025),wall.darkened(.10))
		box(root,Vector3(0,height*.78,d/2+.16),Vector3(w*.72,.40,.16),INK)
		# Compact awning, with posts flush to the collision boundary.
		var awning := box(root,Vector3(0,height*.68,d/2+.22),Vector3(w*.84,.14,.55),CREAM)
		awning.rotation.x = .10
		for side in [-1.0,1.0]:
			box(root,Vector3(side*w*.39,height*.32,d/2+.12),Vector3(.12,height*.64,.12),CREAM)
	merge(root,"Architecture")
	shadow(root,Vector2(w+2,d+2),Vector3(.45,.005,.5))
	var sign := Label3D.new()
	sign.text = {"Cafe":"SALT & SUN", "Beach kiosk":"SURF KIOSK", "Wooden shed":"SURF RESCUE", "Beach shop":"COAST SUPPLY", "Apartments":"BANKSIA", "Hotel":"THE HEADLAND"}.get(title,title)
	sign.font_size = 48
	sign.pixel_size = .007 if small else .012
	sign.position = Vector3(0,height*.78,d/2+.255)
	sign.modulate = CREAM
	sign.outline_size = 0
	root.add_child(sign)

static func scenery(parent: Node3D) -> void:
	# Fixed seed: art placement never consumes gameplay random choices.
	var rng := RandomNumberGenerator.new()
	rng.seed = 79123
	var land := Node3D.new()
	land.name = "CoastalHorizon"
	parent.add_child(land)
	box(land,Vector3(0,-.50,-120),Vector3(700,.40,200),Color("94a18a"))
	box(land,Vector3(0,-.36,170),Vector3(900,.42,300),Color("4f9da7"))
	box(land,Vector3(-190,-.3,-24),Vector3(220,.5,100),Color("d9c79e"))
	box(land,Vector3(190,-.3,-24),Vector3(220,.5,100),Color("d9c79e"))
	# Shoreline bands and broad wet sand; no dense noisy ground texture.
	box(land,Vector3(0,-.035,26),Vector3(600,.025,9),Color("c2bc9c"))
	box(land,Vector3(0,-.03,32),Vector3(600,.025,5),Color("8ab9b4"))
	for i in range(4):
		box(land,Vector3(0,-.015,33+i*6),Vector3(600,.02,.18),Color("d0e5d5"))
	for x in [-94.0,100.0]:
		_headland(land,Vector3(x,-.05,-45))
	merge(land)
	for chunk_index in range(6):
		var chunk := Node3D.new()
		chunk.name = "BeachCluster%d" % chunk_index
		parent.add_child(chunk)
		var x := -59.0+chunk_index*23.0
		# Dune clusters and access fences outside the central hunt area.
		for j in range(7):
			var at := Vector3(x+rng.randf_range(-5,5),.10,20+rng.randf_range(-1,3))
			for stem in range(3):
				var grass := box(chunk,at+Vector3(stem*.12,.25,0),Vector3(.065,.55,.12),SAGE)
				grass.rotation.z = -.35+stem*.3
		for j in range(5):
			box(chunk,Vector3(x+j*.7,.45,-15),Vector3(.09,.9,.09),Color("b5ab89"))
		box(chunk,Vector3(x+1.4,.65,-15),Vector3(2.9,.09,.07),CREAM)
		# Promenade bench and litter bin are small enough to remain decorative.
		box(chunk,Vector3(x,.53,-18),Vector3(1.8,.12,.55),Color("a68965"))
		box(chunk,Vector3(x,.92,-18.23),Vector3(1.8,.55,.09),Color("a68965"))
		for side in [-.65,.65]:box(chunk,Vector3(x+side,.26,-18),Vector3(.09,.5,.36),INK)
		box(chunk,Vector3(x+2.6,.47,-18),Vector3(.55,.94,.55),ROOF)
		if chunk_index % 2 == 0:
			# Beach umbrella with alternating broad panels.
			box(chunk,Vector3(x,1.15,9),Vector3(.08,2.3,.08),CREAM)
			for side in [-1.0,1.0]:
				var canopy := box(chunk,Vector3(x+side*.65,2.25,9),Vector3(1.4,.09,2.4),CREAM if side<0 else Color("c17d62"))
				canopy.rotation.z = side * -.2
			box(chunk,Vector3(x,.015,10.8),Vector3(1.5,.03,2.3),Color("c17d62"))
		merge(chunk)
	# Swimming flags identify this coast without a tropical-palm shorthand.
	for x in [-17.0,19.0]:
		var flag := Node3D.new()
		parent.add_child(flag)
		box(flag,Vector3(x,1.7,24),Vector3(.07,3.4,.07),CREAM)
		box(flag,Vector3(x+.48,3.0,24),Vector3(.96,.45,.035),Color("d3674e"))
		box(flag,Vector3(x+.48,2.55,24),Vector3(.96,.45,.035),Color("efc66c"))
		merge(flag)
	for x in [-62.0,-33.0,34.0,63.0]:
		var tree := Node3D.new()
		parent.add_child(tree)
		box(tree,Vector3(x,3.6,-61),Vector3(.40,7.2,.40),Color("9b8970"))
		for tier in range(5):
			var mesh := CylinderMesh.new()
			mesh.top_radius = .10
			mesh.bottom_radius = 2.2-tier*.35
			mesh.height = 2.2
			mesh.radial_segments = 7
			var crown := box(tree,Vector3(x,3.1+tier*1.05,-61),Vector3.ONE,Color("668777").lightened(tier*.025))
			crown.mesh = mesh
		merge(tree)

static func _headland(parent: Node3D, origin: Vector3) -> void:
	var points := PackedVector3Array()
	for z in range(15):
		for x in range(11):
			var u := (x-5.0)/5.0
			var v := (z-7.0)/7.0
			var rim := maxf(0,1-u*u-v*v)
			var height := pow(rim,1.25)*(5.0+1.4*sin(u*5+v*4))
			points.append(origin+Vector3(u*23,height,v*35))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(14):
		for x in range(10):
			var i := z*11+x
			for index in [i,i+1,i+11,i+1,i+12,i+11]:
				surface.add_vertex(points[index])
	surface.generate_normals()
	var render := box(parent,Vector3.ZERO,Vector3.ONE,Color("8c9c83"))
	render.mesh = surface.commit()

static func person(root: Node3D, uniform: bool, variant: int) -> void:
	var clothing: Array[Color] = [Color("e6c478"),Color("b97e69"),Color("749e9b"),Color("e6d8bd"),Color("9292a0")]
	var skin: Array[Color] = [Color("c99a75"),Color("986e53"),Color("e1b68f"),Color("76533f")]
	var shirt := Color("3c5774") if uniform else clothing[posmod(variant,clothing.size())]
	oval(root,Vector3(0,1.12,0),Vector3(.27,.40,.19),shirt)
	oval(root,Vector3(0,1.64,0),Vector3(.22,.25,.21),skin[posmod(variant,skin.size())])
	oval(root,Vector3(0,1.82,.02),Vector3(.23,.09,.21),INK if uniform else Color("685444"))
	for side in [-1.0,1.0]:
		var arm := oval(root,Vector3(side*.32,1.03,-.03),Vector3(.10,.32,.11),shirt)
		arm.rotation.z = side*.18
	if uniform:
		box(root,Vector3(0,1.85,-.18),Vector3(.43,.07,.24),INK)
		box(root,Vector3(-.10,1.26,-.19),Vector3(.085,.11,.02),Color("efc66c"))
		box(root,Vector3(0,.84,0),Vector3(.49,.10,.36),INK)
	merge(root,"PersonBody")
	for side in [-1.0,1.0]:
		var pivot := Node3D.new()
		pivot.name = "StrideLeft" if side<0 else "StrideRight"
		pivot.position = Vector3(side*.14,.74,0)
		root.add_child(pivot)
		oval(pivot,Vector3(0,-.30,0),Vector3(.105,.34,.12),INK if uniform else shirt.darkened(.2))
		oval(pivot,Vector3(0,-.65,-.06),Vector3(.12,.075,.19),INK)
		merge(pivot)
	shadow(root,Vector2(.95,.7))

static func animate_person(root: Node3D, clock: float, moving: bool) -> void:
	for key in ["StrideLeft","StrideRight"]:
		var limb := root.get_node_or_null(key) as Node3D
		if limb != null:
			limb.rotation.x = sin(clock + (PI if key == "StrideRight" else 0.0)) * .60 if moving else 0.0
