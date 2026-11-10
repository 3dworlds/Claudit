class_name WeaponModels
## Modelos de armas con primitivas (low-poly). Cada arma tiene su propia forma y color.
## El cañón apunta hacia +Z. Se usan en primera persona (cámara) y en la mano del personaje.

## Formas disponibles. Cada arma usa una distinta cuando se puede.
const SHAPES := ["pistol", "smg", "drum", "shotgun", "rifle", "sniper", "rocket", "grenade",
	"flame", "bow", "orb", "launcher", "nuke", "pulse"]

const BY_NAME := {
	"Pistola": "pistol", "SMG": "smg", "Ametralladora": "drum", "Escopeta": "shotgun",
	"Rifle": "rifle", "Francotirador": "sniper", "Lanzacohetes": "rocket", "Granada": "grenade",
	"Lanzallamas": "flame", "Arco": "bow", "Ballesta": "bow", "Bobina Tesla": "orb",
	"Rayo": "orb", "Cañón de energía": "orb", "Cañón de pulso": "pulse", "Cañón repulsor": "pulse",
	"Escopeta de combate": "shotgun", "Escopeta explosiva": "shotgun", "Lanzagranadas": "launcher",
	"Mini cohetes": "rocket", "Mini nuke": "nuke", "Dardo tranquilizante": "smg",
	"Taser": "pistol",
	"Physgun": "physgun",
}


static func build(wname: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Gun"
	var metal := _mat(Color(0.22, 0.24, 0.3))
	var steel := _mat(Color(0.5, 0.52, 0.56))
	var dark := _mat(Color(0.1, 0.1, 0.12))
	var polymer := _mat(Color(0.16, 0.16, 0.18))
	var wood := _mat(Color(0.42, 0.26, 0.14))
	var accent_c: Color = _accent(wname)
	var accent := _mat(accent_c)
	var glow := _glow(accent_c)
	var shape: String = _shape_for(wname)
	match shape:
		"pistol":
			_box(root, Vector3(0.06, 0.07, 0.24), Vector3(0, 0.02, 0.0), metal)
			_box(root, Vector3(0.055, 0.05, 0.2), Vector3(0, 0.07, 0.0), steel)
			_cyl(root, 0.018, 0.1, Vector3(0, 0.04, 0.2), steel)
			_box(root, Vector3(0.05, 0.13, 0.07), Vector3(0, -0.07, -0.06), polymer)
			_box(root, Vector3(0.05, 0.03, 0.06), Vector3(0, -0.01, 0.03), dark)
			_box(root, Vector3(0.02, 0.02, 0.02), Vector3(0, 0.11, -0.04), accent)
		"smg":
			_box(root, Vector3(0.07, 0.09, 0.34), Vector3(0, 0, 0), metal)
			_box(root, Vector3(0.065, 0.06, 0.26), Vector3(0, 0.07, -0.02), steel)
			_cyl(root, 0.02, 0.14, Vector3(0, 0.02, 0.26), dark)
			_box(root, Vector3(0.05, 0.18, 0.07), Vector3(0, -0.13, 0.02), polymer)
			_box(root, Vector3(0.05, 0.14, 0.05), Vector3(0, -0.1, -0.16), polymer)
			_box(root, Vector3(0.03, 0.04, 0.03), Vector3(0, 0.1, 0.1), accent)
		"drum":
			_box(root, Vector3(0.08, 0.1, 0.5), Vector3(0, 0, 0), metal)
			_cyl_y(root, 0.11, 0.1, Vector3(0, 0.1, 0.02), accent)
			_cyl_y(root, 0.11, 0.02, Vector3(0, 0.15, 0.02), dark)
			_cyl(root, 0.025, 0.3, Vector3(0, 0.02, 0.4), dark)
			_box(root, Vector3(0.06, 0.16, 0.08), Vector3(0, -0.13, -0.06), polymer)
			_box(root, Vector3(0.05, 0.1, 0.12), Vector3(0, -0.04, -0.3), wood)
			_box(root, Vector3(0.04, 0.05, 0.03), Vector3(0, 0.07, -0.18), dark)
		"shotgun":
			_box(root, Vector3(0.08, 0.1, 0.5), Vector3(0, 0, 0), wood)
			_cyl(root, 0.03, 0.42, Vector3(-0.025, 0.04, 0.4), metal)
			_cyl(root, 0.03, 0.42, Vector3(0.025, 0.04, 0.4), metal)
			_box(root, Vector3(0.07, 0.14, 0.16), Vector3(0, -0.04, -0.3), wood)
			_box(root, Vector3(0.09, 0.05, 0.16), Vector3(0, -0.06, 0.18), accent)
			_box(root, Vector3(0.05, 0.12, 0.05), Vector3(0, -0.1, 0.02), dark)
			_box(root, Vector3(0.03, 0.03, 0.03), Vector3(0, 0.08, 0.36), steel)
		"rifle":
			_box(root, Vector3(0.07, 0.1, 0.6), Vector3(0, 0, 0), wood)
			_box(root, Vector3(0.055, 0.06, 0.4), Vector3(0, 0.06, 0.1), metal)
			_cyl(root, 0.02, 0.3, Vector3(0, 0.03, 0.45), steel)
			_box(root, Vector3(0.06, 0.12, 0.2), Vector3(0, -0.04, -0.4), wood)
			_box(root, Vector3(0.05, 0.16, 0.06), Vector3(0, -0.13, 0.05), dark)
			_box(root, Vector3(0.05, 0.2, 0.08), Vector3(0, -0.12, 0.2), polymer)
			_box(root, Vector3(0.04, 0.05, 0.04), Vector3(0, 0.1, 0.1), accent)
		"sniper":
			_box(root, Vector3(0.06, 0.09, 0.8), Vector3(0, 0, 0), dark)
			_cyl(root, 0.025, 0.25, Vector3(0, 0.03, 0.55), steel)
			_cyl(root, 0.045, 0.22, Vector3(0, 0.11, 0.1), accent)
			_cyl(root, 0.05, 0.02, Vector3(0, 0.11, -0.01), dark)
			_box(root, Vector3(0.07, 0.14, 0.2), Vector3(0, -0.04, -0.4), wood)
			_box(root, Vector3(0.04, 0.2, 0.04), Vector3(0, -0.13, 0.28), metal)
			_box(root, Vector3(0.05, 0.14, 0.06), Vector3(0, -0.11, 0.0), polymer)
		"rocket":
			_cyl(root, 0.08, 0.7, Vector3(0, 0.02, 0.05), metal)
			_cyl(root, 0.06, 0.05, Vector3(0, 0.02, 0.4), dark)
			_cyl(root, 0.09, 0.04, Vector3(0, 0.02, -0.3), dark)
			_box(root, Vector3(0.05, 0.12, 0.14), Vector3(0, -0.1, -0.2), polymer)
			_box(root, Vector3(0.1, 0.03, 0.1), Vector3(0, 0.1, -0.1), accent)
			_box(root, Vector3(0.04, 0.04, 0.04), Vector3(0, 0.1, 0.25), dark)
		"grenade":
			_sphere(root, 0.09, Vector3(0, 0, 0), accent)
			_box(root, Vector3(0.03, 0.03, 0.12), Vector3(0, 0.1, 0), dark)
			_box(root, Vector3(0.05, 0.1, 0.05), Vector3(0, -0.12, 0), metal)
			_cyl_y(root, 0.02, 0.05, Vector3(0, 0.12, 0), steel)
		"flame":
			_cyl_y(root, 0.1, 0.5, Vector3(-0.09, 0.0, -0.2), metal)
			_cyl_y(root, 0.02, 0.06, Vector3(-0.09, 0.28, -0.2), steel)
			_cyl(root, 0.06, 0.6, Vector3(0.02, -0.02, 0.1), metal)
			_cyl(root, 0.05, 0.22, Vector3(0.02, -0.02, 0.5), accent)
			_cyl(root, 0.03, 0.16, Vector3(0.02, -0.02, 0.62), dark)
			_box(root, Vector3(0.06, 0.14, 0.12), Vector3(0, -0.12, -0.12), dark)
			_box(root, Vector3(0.05, 0.05, 0.1), Vector3(0, -0.02, -0.2), polymer)
		"bow":
			_box(root, Vector3(0.05, 0.06, 0.4), Vector3(0, 0, 0), wood)
			_box(root, Vector3(0.02, 0.6, 0.02), Vector3(0, 0, 0.12), accent)
			_box(root, Vector3(0.015, 0.4, 0.015), Vector3(0, 0, 0.14), steel)
			_box(root, Vector3(0.06, 0.1, 0.1), Vector3(0, -0.06, -0.18), dark)
		"orb":
			_box(root, Vector3(0.08, 0.1, 0.22), Vector3(0, 0, 0), metal)
			_sphere(root, 0.12, Vector3(0, 0.02, 0.2), glow)
			_cyl_y(root, 0.05, 0.1, Vector3(0, 0.1, -0.02), dark)
			_box(root, Vector3(0.05, 0.14, 0.06), Vector3(0, -0.12, -0.05), dark)
		"pulse":
			_cyl(root, 0.07, 0.6, Vector3(0, 0, 0.1), metal)
			_cyl(root, 0.1, 0.06, Vector3(0, 0, 0.42), glow)
			_cyl(root, 0.045, 0.1, Vector3(0, 0, -0.22), dark)
			_box(root, Vector3(0.1, 0.14, 0.12), Vector3(0, -0.1, -0.15), dark)
		"launcher":
			_cyl(root, 0.1, 0.55, Vector3(0, 0.02, 0.05), accent)
			_cyl(root, 0.07, 0.05, Vector3(0, 0.02, 0.35), dark)
			_cyl(root, 0.1, 0.03, Vector3(0, 0.02, -0.25), dark)
			_box(root, Vector3(0.06, 0.14, 0.12), Vector3(0, -0.12, -0.2), dark)
		"nuke":
			_cyl(root, 0.13, 0.8, Vector3(0, 0, 0.05), metal)
			_sphere(root, 0.13, Vector3(0, 0, 0.46), glow)
			_box(root, Vector3(0.08, 0.16, 0.14), Vector3(0, -0.14, -0.2), dark)
			_cyl(root, 0.04, 0.3, Vector3(0, 0.15, 0.1), dark)
		"physgun":
			_box(root, Vector3(0.08, 0.12, 0.26), Vector3(0, 0, 0), metal)
			_box(root, Vector3(0.05, 0.14, 0.06), Vector3(0, -0.12, -0.04), dark)
			_cyl(root, 0.05, 0.12, Vector3(0, 0.02, 0.2), dark)
			_sphere(root, 0.06, Vector3(0, 0.02, 0.28), glow)
			_box(root, Vector3(0.1, 0.03, 0.04), Vector3(0, 0.08, -0.05), accent)
		_:
			_box(root, Vector3(0.06, 0.08, 0.24), Vector3(0, 0, 0), metal)
			_box(root, Vector3(0.05, 0.14, 0.06), Vector3(0, -0.11, -0.05), dark)
	return root


## Elige la forma según el nombre (por palabras clave). Si no coincide, usa una forma según el nombre.
static func _shape_for(wname: String) -> String:
	if BY_NAME.has(wname):
		return str(BY_NAME[wname])
	var n: String = wname.to_lower()
	var keys: Array = [
		["minigun", "drum"], ["ametralla", "drum"], ["smg", "smg"], ["subfusil", "smg"],
		["escopeta", "shotgun"], ["rifle", "rifle"], ["francotirador", "sniper"],
		["bazuca", "rocket"], ["cohete", "rocket"], ["mortero", "launcher"], ["lanzagranadas", "launcher"],
		["granada", "grenade"], ["lanzallamas", "flame"], ["arco", "bow"], ["ballesta", "bow"],
		["látigo", "bow"], ["lanza", "orb"], ["rayo", "orb"], ["tesla", "orb"], ["taser", "pistol"],
		["arco eléctrico", "orb"], ["cañón", "pulse"], ["pulso", "pulse"], ["nuke", "nuke"],
		["pistola", "pistol"], ["physgun", "physgun"],
	]
	for pair in keys:
		if n.contains(str(pair[0])):
			return str(pair[1])
	return SHAPES[absi(wname.hash()) % SHAPES.size()]


static func _accent(wname: String) -> Color:
	# Color propio por arma (estable para cada nombre)
	var h: float = float(absi(wname.hash()) % 360) / 360.0
	return Color.from_hsv(h, 0.6, 0.95)


static func _glow(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 2.5
	return m


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
	var mi := _cyl_y(parent, r, h, pos, mat)
	mi.rotation.x = PI * 0.5
	return mi


## Cilindro vertical (eje Y).
static func _cyl_y(parent: Node3D, r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = mat
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
