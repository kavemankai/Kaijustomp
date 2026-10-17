class_name OrganicGeometry
extends RefCounted
## Authored cross-section lofts: connected low-poly tissue, tapered tips.
## Meshes are constructed only when a recipe changes, never during posing.
static func loft(parent: Node3D, centers: Array, radii: Array, tint: Color, sides: int = 8) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array=[]
	for i in range(centers.size()):
		var tangent: Vector3=centers[mini(i+1,centers.size()-1)]-centers[maxi(0,i-1)]
		if tangent.length_squared()<.001: tangent=Vector3.BACK
		var axis := tangent.normalized()
		var cross_axis := Vector3.UP if absf(axis.y)<.92 else Vector3.FORWARD
		var right := cross_axis.cross(axis).normalized()
		var up := axis.cross(right).normalized()
		var ring: Array[Vector3]=[]
		for j in range(sides):
			var a := TAU*float(j)/sides
			var r: Vector2=radii[i]
			ring.append(centers[i]+right*cos(a)*r.x+up*sin(a)*r.y)
		rings.append(ring)
	for i in range(centers.size()-1):
		for j in range(sides):
			var k := (j+1)%sides
			for v in [rings[i][j],rings[i+1][j],rings[i][k],rings[i][k],rings[i+1][j],rings[i+1][k]]:
				st.add_vertex(v)
	for end in [0,centers.size()-1]:
		for j in range(sides):
			var k := (j+1)%sides
			for v in ([centers[end],rings[end][k],rings[end][j]] if end==0 else [centers[end],rings[end][j],rings[end][k]]): st.add_vertex(v)
	st.generate_normals()
	st.index()
	var mesh := MeshInstance3D.new()
	mesh.mesh=st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color=tint
	mat.roughness=.86
	mesh.material_override=mat
	parent.add_child(mesh)
	return mesh

static func tapered(parent: Node3D, a: Vector3, b: Vector3, width: float, tip: float, tint: Color) -> void:
	loft(parent,[a,a.lerp(b,.48),b],[Vector2.ONE*width,Vector2.ONE*width*.72,Vector2.ONE*tip],tint)

static func bake(root: Node3D, title: String) -> MeshInstance3D:
	# Flatten semantic organ frames with their actual transforms before merging.
	for child in root.get_children():
		if child is Node3D and not child is MeshInstance3D:
			var baked := bake(child,title+"Part")
			var pose: Transform3D=child.transform*baked.transform
			child.remove_child(baked)
			root.add_child(baked)
			baked.transform=pose
			child.free()
	return CoastalArt.merge(root,title)
