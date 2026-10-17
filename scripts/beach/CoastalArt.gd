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

# A walkable inland neighbourhood immediately beyond the beach promenade.
# Geometry is visual-only; the 18 houses use real StaticBody3D wall collision.
static func neighbourhood(parent: Node3D) -> void:
	var town := Node3D.new()
	town.name = "CoastalNeighbourhood"
	parent.add_child(town)
	box(town,Vector3(0,-.34,-290),Vector3(280,.50,452),Color("a6ad86"))
	# Long access road from beach into the neighbourhood, then cross streets.
	box(town,Vector3(0,-.057,-290),Vector3(13,.09,420),Color("626f71"))
	for crossing in [-131.0, -175.0, -263.0, -307.0, -377.0, -431.0, -493.0]:
		box(town,Vector3(0,-.05,crossing),Vector3(236,.08,12),Color("626f71"))
	# Shopping lots and short access aprons give the next zone a broader shape.
	for x in [-71.0, 71.0]:
		for z in [-354.0, -406.0, -464.0]:
			box(town,Vector3(x,-.022,z),Vector3(38,.04,19),Color("c7c4b5"))
	# Restrained paths and regularly spaced road markings.
	for x in [-8.0,8.0]:
		box(town,Vector3(x,.005,-289),Vector3(2.0,.05,415),Color("d7d1be"))
	for z in range(-498,-77,14):
		box(town,Vector3(0,.011,float(z)),Vector3(.30,.018,5),Color("e8dfbd"))
	for crossing in [-131.0, -175.0, -263.0, -307.0, -377.0, -431.0, -493.0]:
		for x in range(-108,109,16):
			box(town,Vector3(float(x),.009,crossing),Vector3(5,.018,.26),Color("e8dfbd"))
	merge(town,"NeighbourhoodRoads")
	var marker := Label3D.new()
	marker.name = "NeighbourhoodSign"
	marker.text = "BANKSIA HEIGHTS"
	marker.font_size = 52
	marker.pixel_size = .012
	marker.modulate = Color("faf0d4")
	marker.outline_size = 0
	marker.position = Vector3(12.0, 2.45, -82.0)
	town.add_child(marker)


static func home(root: Node3D, footprint: Vector2, height: float, colour: Color) -> void:
	# Batched authored-shape residential kit, not a beach commercial box.
	var w := footprint.x
	var d := footprint.y
	box(root,Vector3(0,height * .5,0),Vector3(w,height,d),colour)
	box(root,Vector3(0,height+.20,0),Vector3(w+.4,.24,d+.4),Color("648384"))
	# Two large pitched roof planes with overhangs.
	for side in [-1.0,1.0]:
		var roof := box(root,Vector3(side*w*.24,height+.68,0),Vector3(w*.56,.22,d+.65),Color("718480"))
		roof.rotation.z = side * -.21
	# Front facing coast: porch and readable doors/windows within wall footprint.
	box(root,Vector3(0,1.15,d*.5+.07),Vector3(1.25,2.3,.13),INK)
	box(root,Vector3(.34,1.0,d*.5+.15),Vector3(.10,.12,.04),CREAM)
	for side in [-1.0,1.0]:
		box(root,Vector3(side*w*.29,2.05,d*.5+.07),Vector3(1.62,1.42,.11),CREAM)
		box(root,Vector3(side*w*.29,2.05,d*.5+.14),Vector3(1.34,1.14,.055),Color("678f99"))
		box(root,Vector3(side*w*.29,2.05,d*.5+.18),Vector3(.06,1.20,.07),CREAM)
		box(root,Vector3(side*w*.29,2.05,-d*.5-.055),Vector3(1.45,1.25,.11),Color("678f99"))
	box(root,Vector3(0,.16,d*.5-.20),Vector3(3.8,.24,2.3),Color("c8bdab"))
	merge(root,"Architecture")
	shadow(root,Vector2(w+1.6,d+1.6),Vector3(.15,.005,.25))

# The same compact geometry/palette grammar as the coast, but commercial
# frontages have readable signage, glazing and striped awnings.
static func shop(root: Node3D, footprint: Vector2, height: float, title: String) -> void:
	var w := footprint.x
	var d := footprint.y
	var wall := Color("e5cfb0") if title in ["Bakery","Fish & Chips","Coffee Bar"] else Color("c4d3cd")
	box(root,Vector3(0,height*.5,0),Vector3(w,height,d),wall)
	box(root,Vector3(0,height+.14,0),Vector3(w+.35,.28,d+.35),Color("648384"))
	box(root,Vector3(0,height-.7,d*.5+.05),Vector3(w*.95,1.24,.15),INK)
	for i in range(3):
		var x := (float(i)-1.0)*w*.28
		box(root,Vector3(x,2.0,d*.5+.12),Vector3(w*.225,2.65,.12),CREAM)
		box(root,Vector3(x,2.0,d*.5+.19),Vector3(w*.205,2.40,.06),Color("6c9ca7"))
	box(root,Vector3(0,1.13,d*.5+.25),Vector3(1.5,2.24,.08),INK)
	var awning := box(root,Vector3(0,height*.70,d*.5+.5),Vector3(w*.88,.15,1.3),Color("cc886c"))
	awning.rotation.x = -.10
	for n in range(7):
		box(root,Vector3((float(n)-3.0)*w*.11,height*.7+.07,d*.5+1.0),Vector3(w*.055,.025,.15),CREAM)
	merge(root,"Architecture")
	shadow(root,Vector2(w+1.4,d+1.4),Vector3(0,.005,0))
	var sign := Label3D.new()
	sign.name = "ShopSign"
	sign.text = title.to_upper()
	sign.font_size = 52
	sign.pixel_size = .01 if w <= 20.0 else .014
	sign.position = Vector3(0,height-.68,d*.5+.18)
	sign.modulate = CREAM
	sign.outline_size = 0
	root.add_child(sign)


static func car(root: Node3D, paint: Color) -> void:
	# Four wheels, a strong low silhouette, windscreen and paired lights.
	# All opaque parts are collapsed to one vertex-coloured renderer.
	box(root,Vector3(0,.73,0),Vector3(2.12,.74,4.45),paint)
	box(root,Vector3(0,1.32,.35),Vector3(1.78,.68,2.55),paint.lightened(.10))
	box(root,Vector3(0,1.40,-.62),Vector3(1.68,.48,.12),Color("6b97a3"))
	box(root,Vector3(0,1.40,1.43),Vector3(1.68,.40,.12),Color("6b97a3"))
	for side in [-1.0,1.0]:
		for z in [-1.45,1.45]:
			box(root,Vector3(side*1.05,.43,z),Vector3(.35,.67,.86),INK)
		for z in [-.55,.68]:
			box(root,Vector3(side*.93,1.34,z),Vector3(.055,.42,.80),Color("6b97a3"))
		box(root,Vector3(side*.71,.79,-2.24),Vector3(.42,.22,.09),Color("f8e8c1"))
		box(root,Vector3(side*.71,.79,2.24),Vector3(.42,.22,.09),Color("c76d5f"))
	merge(root,"CarBody")
	shadow(root,Vector2(2.9,5.3),Vector3(0,.005,0))


# Second connected land zone: broad outer-suburban streets feed an
# industrial avenue. Batched ground/road meshes keep the Android draw count
# bounded independently of the longer inland walking limits.
static func outer_district(parent: Node3D) -> void:
	var region := Node3D.new()
	region.name = "OuterDistrict"
	parent.add_child(region)
	box(region, Vector3(0, -.35, -1005), Vector3(840,.50,1010), Color("a9b197"))
	# Main road overlaps the end of Banksia Heights by 15 units.
	box(region, Vector3(0, -.057, -1005), Vector3(20,.09,1020), Color("596b70"))
	for x in [-199.0,199.0]:
		box(region, Vector3(x,-.048,-1120), Vector3(14,.08,740), Color("596b70"))
	for z in [-548.0,-612.0,-714.0,-905.0,-1032.0,-1165.0,-1298.0,-1450.0]:
		box(region,Vector3(0,-.05,z),Vector3(685,.08,14),Color("64757a"))
	for z in range(-1500,-503,22):
		box(region,Vector3(0,.014,float(z)),Vector3(.34,.022,7),CREAM)
	for z in [-548.0,-612.0,-714.0,-905.0,-1032.0,-1165.0,-1298.0,-1450.0]:
		for x in range(-330,331,22):
			box(region,Vector3(float(x),.013,z),Vector3(7,.02,.27),CREAM)
	# Hardstands and freight aprons behind the roadside factories.
	for x in [-286.0,-103.0,103.0,286.0]:
		for z in [-830.0,-1095.0,-1360.0]:
			box(region,Vector3(x,-.025,z),Vector3(113,.05,99),Color("b1b2a9"))
	merge(region,"OuterRoads")
	var sign := Label3D.new()
	sign.name = "IndustrialZoneSign"
	sign.text = "OUTER DISTRICT  /  INDUSTRIAL ESTATE"
	sign.font_size = 55
	sign.pixel_size = .014
	sign.modulate = CREAM
	sign.outline_size = 0
	sign.position = Vector3(15,3.1,-760)
	region.add_child(sign)


static func industrial_building(root: Node3D, footprint: Vector2, height: float, title: String) -> void:
	var w := footprint.x
	var d := footprint.y
	var factory := title in ["Factory","Power Station","Water Works"]
	var wall := Color("a2b8b5") if factory else Color("c3b8a9")
	box(root,Vector3(0,height*.50,0),Vector3(w,height,d),wall)
	box(root,Vector3(0,height+.28,0),Vector3(w+1.6,.55,d+1.6),Color("6a8184"))
	# Bay doors are visible from the road at giant-camera zoom.
	for i in range(3):
		var x := (float(i)-1.0)*w*.285
		box(root,Vector3(x,height*.34,d*.5+.08),Vector3(w*.235,height*.66,.15),Color("435964"))
		for stripe in range(3):
			box(root,Vector3(x,height*.18+float(stripe)*height*.16,d*.5+.19),Vector3(w*.21,.11,.075),Color("92a7a4"))
	for x in [-w*.37,w*.37]:
		box(root,Vector3(x,height*.75,d*.5+.12),Vector3(w*.12,height*.16,.11),Color("e6d6b8"))
	if factory:
		for side in [-1.0,1.0]:
			var x: float = float(side) * w * .29
			box(root,Vector3(x,height+5.4,-d*.23),Vector3(4.4,10.8,4.4),Color("8f9f9e"))
			box(root,Vector3(x,height+10.7,-d*.23),Vector3(5.2,.4,5.2),INK)
	else:
		# Stacked shipping/warehouse containers, read as giant food targets.
		for i in range(3):
			box(root,Vector3((-1.0+float(i))*w*.23,height+.8,-d*.18),
				Vector3(w*.18,1.55,d*.38),Color("748f89") if i%2==0 else Color("b49b80"))
	merge(root,"IndustrialArchitecture")
	shadow(root,Vector2(w+4,d+4),Vector3(0,.005,0))
	var sign := Label3D.new()
	sign.name = "IndustrialSign"
	sign.text = title.to_upper()
	sign.font_size = 64
	sign.pixel_size = .018
	sign.position = Vector3(0,height*.84,d*.5+.26)
	sign.modulate = CREAM
	sign.outline_size = 0
	root.add_child(sign)


static func scenery(parent: Node3D, coast_half_length: float = 70.0) -> void:
	# Fixed seed: art placement never consumes gameplay random choices.
	var rng := RandomNumberGenerator.new()
	rng.seed = 79123
	var land := Node3D.new()
	land.name = "CoastalHorizon"
	parent.add_child(land)
	var shoreline_width := coast_half_length * 2.0 + 300.0
	box(land,Vector3(0,-.50,-120),Vector3(shoreline_width + 400.0,.40,200),Color("94a18a"))
	box(land,Vector3(0,-.36,170),Vector3(shoreline_width + 400.0,.42,300),Color("4f9da7"))
	box(land,Vector3(-coast_half_length-120.0,-.3,-24),Vector3(260,.5,100),Color("d9c79e"))
	box(land,Vector3(coast_half_length+120.0,-.3,-24),Vector3(260,.5,100),Color("d9c79e"))
	# One continuous shore and surf line along every coastal district.
	box(land,Vector3(0,-.035,26),Vector3(shoreline_width,.025,9),Color("c2bc9c"))
	box(land,Vector3(0,-.03,32),Vector3(shoreline_width,.025,5),Color("8ab9b4"))
	for i in range(4):
		box(land,Vector3(0,-.015,33+i*6),Vector3(shoreline_width,.02,.18),Color("d0e5d5"))
	for x in [-coast_half_length - 35.0, coast_half_length + 35.0]:
		_headland(land,Vector3(x,-.05,-45))
	merge(land)
	for chunk_index in range(ceili(coast_half_length * 2.0 / 23.0)):
		var chunk := Node3D.new()
		chunk.name = "BeachCluster%d" % chunk_index
		parent.add_child(chunk)
		var x := -coast_half_length + 12.0 + chunk_index * 23.0
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
	for district in range(-5, 6):
		for local_x in [-17.0, 19.0]:
			var x: float = float(district) * 150.0 + float(local_x)
			var flag := Node3D.new()
			parent.add_child(flag)
			box(flag,Vector3(x,1.7,24),Vector3(.07,3.4,.07),CREAM)
			box(flag,Vector3(x+.48,3.0,24),Vector3(.96,.45,.035),Color("d3674e"))
			box(flag,Vector3(x+.48,2.55,24),Vector3(.96,.45,.035),Color("efc66c"))
			merge(flag)
		for local_x in [-62.0,-33.0,34.0,63.0]:
			var x: float = float(district) * 150.0 + float(local_x)
			if absf(x) >= coast_half_length - 3.0:
				continue
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

# Lightweight distinguishable responder equipment, independent from civilian
# animation pivots. All extra armour is merged to one renderer per soldier.
static func response_uniform(root: Node3D, kind: String) -> void:
	var kit := Node3D.new()
	kit.name = "ResponseKit"
	root.add_child(kit)
	var body_color := Color("314451") if kind == "swat" else Color("697658")
	box(kit, Vector3(0,1.24,-.05), Vector3(.61,.52,.38), body_color)
	box(kit, Vector3(0,1.78,0), Vector3(.51,.16,.49), body_color.darkened(.18))
	box(kit, Vector3(0,1.50,-.24), Vector3(.42,.14,.11), Color("303f39"))
	box(kit, Vector3(-.29,1.37,-.15), Vector3(.08,.25,.13), Color("b1b99c"))
	merge(kit, "ArmourKit")


static func response_vehicle(root: Node3D, kind: String) -> void:
	var air := kind == "helicopter"
	var paint := Color("697c60") if not air else Color("4a6871")
	var hull := Node3D.new()
	hull.name = "VisualHull"
	root.add_child(hull)
	if air:
		oval(hull,Vector3(0,0,0),Vector3(1.45,1.0,3.45),paint)
		box(hull,Vector3(0,-.14,-.92),Vector3(2.0,.82,1.20),Color("6e99a3"))
		box(hull,Vector3(0,.0,3.0),Vector3(.35,.29,4.50),paint)
		box(hull,Vector3(0,.15,5.2),Vector3(2.25,.15,.37),paint)
		for side in [-1.0,1.0]:
			box(hull,Vector3(side*1.18,-.90,.5),Vector3(.11,.11,3.2),INK)
			box(hull,Vector3(side*1.08,-.6,-.1),Vector3(.09,.60,.11),INK)
	else:
		box(hull,Vector3(0,1.18,0),Vector3(3.2,1.8,5.8),paint)
		box(hull,Vector3(0,2.27,-.75),Vector3(2.25,.60,2.75),paint.lightened(.16))
		box(hull,Vector3(0,2.38,-2.4),Vector3(.48,.47,2.6),INK)
		for side in [-1.0,1.0]:
			for z in [-1.75, 1.75]:
				box(hull,Vector3(side*1.62,.63,z),Vector3(.38,.88,1.25),INK)
			box(hull,Vector3(side*1.05,1.25,-2.94),Vector3(.53,.22,.09),CREAM)
	merge(hull,"ResponseHull")
	if air:
		var rotor := Node3D.new()
		rotor.name = "Rotor"
		rotor.position = Vector3(0,1.22,0)
		root.add_child(rotor)
		box(rotor,Vector3.ZERO,Vector3(9.0,.06,.28),INK)
		box(rotor,Vector3.ZERO,Vector3(.28,.06,8.7),INK)
		merge(rotor,"Rotors")
	else:
		shadow(root,Vector2(4.5,7.1),Vector3(0,.01,0))


static func animate_person(root: Node3D, clock: float, moving: bool) -> void:
	for key in ["StrideLeft","StrideRight"]:
		var limb := root.get_node_or_null(key) as Node3D
		if limb != null:
			limb.rotation.x = sin(clock + (PI if key == "StrideRight" else 0.0)) * .60 if moving else 0.0
