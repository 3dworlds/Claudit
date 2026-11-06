class_name WeaponModels
## Modelos de armas hechos con primitivas, en el mismo estilo low-poly del juego.
## El cañón apunta hacia +Z. Se usan en primera persona (en la cámara) y en la mano del jugador.


static func build(wname: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Gun"
	var metal := _mat(Color(0.2, 0.22, 0.28))
	var dark := _mat(Color(0.1, 0.1, 0.12))
	var accent := _mat(_accent(wname))
	match wname:
		"Escopeta":
			_box(root, Vector3(0.08, 0.1, 0.5), Vector3(0, 0, 0), metal)
			_cyl(root, 0.03, 0.42, Vector3(-0.025, 0.03, 0.4), metal)
			_cyl(root, 0.03, 0.42, Vector3(0.025, 0.03, 0.4), metal)
			_box(root, Vector3(0.07, 0.14, 0.16), Vector3(0, -0.04, -0.3), dark)
		"Rifle", "Francotirador", "Ametralladora", "SMG":
			var long: float = 0.7 if wname == "Francotirador" else 0.55
			_box(root, Vector3(0.07, 0.1, long), Vector3(0, 0, 0), metal)
			_cyl(root, 0.02, 0.3, Vector3(0, 0.02, long * 0.5 + 0.15), dark)
			_box(root, Vector3(0.06, 0.12, 0.18), Vector3(0, -0.04, -long * 0.5 - 0.06), dark)
			_box(root, Vector3(0.05, 0.14, 0.06), Vector3(0, -0.12, -0.04), dark)
			_box(root, Vector3(0.04, 0.12, 0.04), Vector3(0, 0.09, 0.08), accent)
		"Lanzacohetes":
			_cyl(root, 0.08, 0.7, Vector3(0, 0.02, 0.05), metal)
			_cyl(root, 0.06, 0.05, Vector3(0, 0.02, 0.4), dark)
			_box(root, Vector3(0.05, 0.12, 0.14), Vector3(0, -0.1, -0.2), dark)
		"Granada":
			_sphere(root, 0.08, Vector3(0, 0, 0), accent)
			_box(root, Vector3(0.03, 0.03, 0.1), Vector3(0, 0.08, 0), dark)
		"Lanzallamas":
			_cyl(root, 0.07, 0.6, Vector3(0, -0.02, 0.1), metal)
			_cyl(root, 0.05, 0.25, Vector3(0, 0.0, 0.5), accent)
			_box(root, Vector3(0.06, 0.16, 0.14), Vector3(0, -0.12, -0.2), dark)
		_:
			# Pistola (y cualquier otra arma sin modelo propio)
			_box(root, Vector3(0.06, 0.08, 0.24), Vector3(0, 0, 0), metal)
			_box(root, Vector3(0.05, 0.14, 0.06), Vector3(0, -0.11, -0.05), dark)
			_box(root, Vector3(0.04, 0.03, 0.04), Vector3(0, 0.06, 0.1), accent)
	return root


static func _accent(wname: String) -> Color:
	match wname:
		"Escopeta", "Lanzallamas": return Color(1.0, 0.5, 0.15)
		"Rifle", "Granada": return Color(0.3, 0.9, 0.4)
		"Francotirador": return Color(0.3, 0.6, 1.0)
		"Lanzacohetes": return Color(1.0, 0.3, 0.3)
		"Ametralladora", "SMG": return Color(1.0, 0.9, 0.3)
	return Color(0.25, 0.85, 0.95)


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## Cilindro con el eje a lo largo de Z (hacia el cañón).
static func _cyl(parent: Node3D, r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = mat
	mi.rotation.x = PI * 0.5
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _sphere(parent: Node3D, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
