class_name Humanoid
extends RefCounted
## Cuerpo humano armado con partes de pocos polígonos (1,8 m de alto).
## Devuelve {"root": Node3D con todo el cuerpo, "torso": MeshInstance3D que se puede pintar}.

const SKIN := Color(0.93, 0.76, 0.62)
const HAIR := Color(0.18, 0.12, 0.08)
const PANTS := Color(0.16, 0.18, 0.28)
const SHOE := Color(0.1, 0.09, 0.09)


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _sphere(parent: Node3D, r: float, pos: Vector3, mat: Material, squash: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	mi.scale = squash
	parent.add_child(mi)
	return mi


## Hueso de la pierna o brazo: cilindro de 6 lados entre dos puntos.
static func _limb(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = a.distance_to(b)
	cm.radial_segments = 6
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	var dir: Vector3 = (b - a).normalized()
	mi.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), (a + b) * 0.5)
	parent.add_child(mi)


static func build(parent: Node3D, shirt: Color, pants: Color = PANTS, mono: Color = Color(-1, 0, 0, 0)) -> Dictionary:
	var root := Node3D.new()
	root.name = "Model"
	root.rotation.y = PI
	parent.add_child(root)
	var skin := _mat(mono if mono.a > 0.0 else SKIN)
	var hair := _mat(mono if mono.a > 0.0 else HAIR)
	var cloth := _mat(mono if mono.a > 0.0 else shirt)
	var legs := _mat(mono if mono.a > 0.0 else pants)
	var shoes := _mat(mono if mono.a > 0.0 else SHOE)
	var eyes := _mat(Color(0.05, 0.05, 0.07))

	# Pelvis y piernas
	_box(root, Vector3(0.36, 0.2, 0.22), Vector3(0, 0.9, 0), legs)
	var hips: Array = []
	var knees: Array = []
	for sd in [-1.0, 1.0]:
		var hipv := Vector3(sd * 0.1, 0.88, 0.0)
		var kneev := Vector3(sd * 0.11, 0.48, 0.0)
		var anklev := Vector3(sd * 0.11, 0.08, 0.0)
		var hp := Node3D.new()
		hp.position = hipv
		root.add_child(hp)
		_limb(hp, Vector3.ZERO, kneev - hipv, 0.085, legs)
		_sphere(hp, 0.09, kneev - hipv, legs)
		var kp := Node3D.new()
		kp.position = kneev - hipv
		hp.add_child(kp)
		_limb(kp, Vector3.ZERO, anklev - kneev, 0.075, legs)
		_box(kp, Vector3(0.14, 0.08, 0.28), Vector3(sd * 0.11, 0.04, 0.05) - kneev, shoes)
		hips.append(hp)
		knees.append(kp)

	# Torso (es la parte que se pinta con el color de la camisa)
	var torso := _box(root, Vector3(0.4, 0.58, 0.24), Vector3(0, 1.2, 0), cloth)
	# Cuello
	_limb(root, Vector3(0, 1.48, 0), Vector3(0, 1.54, 0), 0.06, skin)

	# Brazos: pivote en el hombro (para balanceo y pose de sentado)
	var arms: Array = []
	for sd in [-1.0, 1.0]:
		var shv := Vector3(sd * 0.25, 1.45, 0.0)
		var ap := Node3D.new()
		ap.position = shv
		root.add_child(ap)
		var elv := Vector3(sd * 0.29, 1.14, 0.0) - shv
		var wrv := Vector3(sd * 0.31, 0.88, 0.0) - shv
		_sphere(ap, 0.075, Vector3.ZERO, cloth)
		_limb(ap, Vector3.ZERO, elv, 0.065, cloth)
		_sphere(ap, 0.06, elv, cloth)
		_limb(ap, elv, wrv, 0.055, skin)
		_sphere(ap, 0.06, wrv + Vector3(0, -0.04, 0), skin, Vector3(0.9, 1.3, 0.6))
		arms.append(ap)

	# Cabeza, pelo, ojos y nariz
	var head := _sphere(root, 0.15, Vector3(0, 1.66, 0), skin, Vector3(0.92, 1.05, 0.98))
	_sphere(root, 0.158, Vector3(0, 1.7, -0.02), hair, Vector3(0.95, 0.72, 1.0))
	for sd in [-1.0, 1.0]:
		_box(root, Vector3(0.035, 0.03, 0.02), Vector3(sd * 0.055, 1.67, 0.14), eyes)
	_box(root, Vector3(0.03, 0.05, 0.03), Vector3(0, 1.63, 0.15), skin)

	root.set_meta("hips", hips)
	root.set_meta("knees", knees)
	root.set_meta("arms", arms)
	return {"root": root, "torso": torso, "head": head}


## Animación procedural: respiración, caminar, saltar, sentarse y aturdido.
## Mueve los pivotes de caderas, rodillas y hombros. Cada valor se interpola hacia el objetivo
## para que el movimiento sea suave.
static func animate(root: Node3D, t: float, speed: float, airborne: bool, stunned: bool, seated: bool, delta: float = 0.016, takeoff: float = 0.0) -> void:
	var k: float = clampf(delta * 12.0, 0.0, 1.0)
	root.rotation.y = PI
	var walk: float = clampf(speed / 6.0, 0.0, 1.0)
	var ph: float = t * 8.0
	var y: float = sin(t * 2.2) * 0.012
	var tilt_x: float = 0.0
	var tilt_z: float = 0.0
	var hip_a: float = 0.0
	var knee_a: float = 0.0
	var arm_a: float = 0.0
	if walk > 0.01 and not airborne:
		y += absf(sin(ph)) * 0.05 * walk
		tilt_z = sin(ph) * 0.04 * walk
		tilt_x = 0.04 * walk
		hip_a = sin(ph) * 0.5 * walk
		knee_a = absf(sin(ph)) * 0.4 * walk
		arm_a = -sin(ph) * 0.5 * walk
	if airborne:
		tilt_x = -0.12
		hip_a = -0.4
		knee_a = 0.6
		arm_a = -1.1
	# Despegue: agachado y brazos atrás antes de subir (takeoff va de 0.2 a 0)
	if takeoff > 0.0:
		var k2: float = clampf(takeoff / 0.2, 0.0, 1.0)
		hip_a = lerpf(hip_a, 0.7, k2)
		knee_a = lerpf(knee_a, 1.1, k2)
		arm_a = lerpf(arm_a, 1.2, k2)
	var sw: float = 1.0 if seated else 0.0
	tilt_x = lerpf(tilt_x, 0.1, sw)
	var sit_hip: float = -PI * 0.5
	var sit_knee: float = PI * 0.5
	var sit_arm: float = -0.35

	var hips: Array = root.get_meta("hips", [])
	var knees: Array = root.get_meta("knees", [])
	var arms: Array = root.get_meta("arms", [])
	for i in range(hips.size()):
		var sg: float = 1.0 if i == 0 else -1.0
		var hp := hips[i] as Node3D
		hp.rotation.x = lerpf(hp.rotation.x, lerpf(hip_a * sg, sit_hip, sw), k)
		var kp := knees[i] as Node3D
		kp.rotation.x = lerpf(kp.rotation.x, lerpf(knee_a * sg, sit_knee, sw), k)
	for i in range(arms.size()):
		var sg2: float = 1.0 if i == 0 else -1.0
		var ap := arms[i] as Node3D
		ap.rotation.x = lerpf(ap.rotation.x, lerpf(arm_a * sg2, sit_arm, sw), k)

	if stunned:
		tilt_z = sin(t * 60.0) * 0.12
		tilt_x = sin(t * 47.0) * 0.06
		y += sin(t * 80.0) * 0.02
	root.position.y = lerpf(root.position.y, y, k)
	root.rotation.x = lerpf(root.rotation.x, tilt_x, k)
	root.rotation.z = lerpf(root.rotation.z, tilt_z, k)


## Aplica una textura procedural (tela, metal, carbono...) a todas las piezas del modelo.
## variant: clave propia de cada personaje, así cada uno tiene un dibujo distinto.
static func skin_texture(root: Node, tname: String, variant: String) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			var mat := (child as MeshInstance3D).material_override as StandardMaterial3D
			if mat != null:
				mat.albedo_texture = Textures.get_tex(tname, variant)
				mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
		skin_texture(child, tname, variant)

