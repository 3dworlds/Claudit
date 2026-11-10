class_name Builder
extends Node
## Construcción estilo "Build a Boat for Treasure".
## Una estructura es UN RigidBody3D con muchos bloques (cada bloque = MeshInstance3D + CollisionShape3D).
## El host es autoritativo; los clientes replican estructuras y bloques por RPC.
## Mientras construís, las estructuras están congeladas. Con "Probar" (L) se sueltan y los bloques con función andan.

const OP_SCALE_UP := 0
const OP_SCALE_DOWN := 1
const OP_ROT_CW := 2
const OP_ROT_CCW := 3
const OP_PAINT := 4
const OP_COPY := 5
const OP_DELETE := 6

const WATER_DENSITY := 10.0
const MAX_BLOCKS := 160
const WHEEL_FORCE := 160.0
const PROP_FORCE := 140.0
const JET_FORCE := 260.0
const BALLOON_LIFT := 95.0
const STEER_TORQUE := 70.0
const MAX_SPEED := 45.0
const CANNON_COOLDOWN := 1.2
const AIRPROP_FORCE := 220.0
const WING_LIFT := 14.0
const PITCH_TORQUE := 40.0

var world: Node = null
var defs: Dictionary = Content.blocks()
var sel_block: String = "Madera"
var sel_color: Color = Color(0.71, 0.51, 0.29)
var launched: bool = false
var next_bid: int = 1
var drives: Dictionary = {}     # sid -> Vector2(giro, avance)
var cannon_cd: Dictionary = {}  # "sid:bid" -> segundos restantes
var undo: Dictionary = {}       # peer -> [[sid, bid], ...]
var build_xf: Dictionary = {}   # sid -> Transform3D al empezar la prueba
var spin: float = 0.0
var tex_override: String = ""
var shock_cd: Dictionary = {}


# ================================================================ Utilidades

static func half_extent(basis: Basis, dims: Vector3, axis: Vector3) -> float:
	return 0.5 * (absf(basis.x.dot(axis)) * dims.x + absf(basis.y.dot(axis)) * dims.y + absf(basis.z.dot(axis)) * dims.z)


func get_struct(sid: int) -> RigidBody3D:
	var v: Variant = world.props.get(sid, null)
	if v == null or not is_instance_valid(v):
		return null
	var b := v as RigidBody3D
	if b == null or not b.has_meta("structure"):
		return null
	return b


func block_data(sid: int, bid: int) -> Dictionary:
	var body: RigidBody3D = get_struct(sid)
	if body == null:
		return {}
	var blocks: Dictionary = body.get_meta("blocks")
	if not blocks.has(bid):
		return {}
	return blocks[bid]


## Devuelve [sid, bid] del bloque golpeado por un raycast, o [-1, -1].
func block_from_hit(hit: Dictionary) -> Array:
	if hit.is_empty():
		return [-1, -1]
	var body := hit.get("collider") as RigidBody3D
	if body == null or not body.has_meta("structure"):
		return [-1, -1]
	var oid: int = body.shape_find_owner(int(hit.get("shape", 0)))
	var node := body.shape_owner_get_owner(oid) as Node
	if node == null:
		return [-1, -1]
	return [int(body.get_meta("pid")), int(node.get_meta("bid", -1))]


## Dimensiones del bloque en su propio marco (ya incluye la rotación interna del eje).
func block_dims(data: Dictionary) -> Vector3:
	var def: Dictionary = defs[data["kind"]]
	var shape: String = str(def["shape"])
	var s: Vector3 = def["size"]
	if shape == "box":
		var size: Vector3 = data["size"]
		return size
	var dims: Vector3
	if shape == "sphere":
		dims = Vector3(s.x * 2.0, s.x * 2.0, s.x * 2.0)
	else:
		dims = Vector3(s.x * 2.0, s.y, s.x * 2.0)
		var axis: String = str(def.get("axis", "y"))
		if axis == "x":
			dims = Vector3(s.y, s.x * 2.0, s.x * 2.0)
		elif axis == "z":
			dims = Vector3(s.x * 2.0, s.x * 2.0, s.y)
	return dims


func block_volume(data: Dictionary) -> float:
	var def: Dictionary = defs[data["kind"]]
	var s: Vector3 = def["size"]
	match str(def["shape"]):
		"box":
			var size: Vector3 = data["size"]
			return size.x * size.y * size.z
		"sphere":
			return 4.0 / 3.0 * PI * s.x * s.x * s.x
		_:
			return PI * s.x * s.x * s.y


func block_mass(data: Dictionary) -> float:
	var def: Dictionary = defs[data["kind"]]
	return maxf(0.05, block_volume(data) * float(def["density"]) * 10.0)


func update_mass(body: RigidBody3D) -> void:
	var blocks: Dictionary = body.get_meta("blocks")
	var total: float = 0.0
	for bid in blocks:
		var data: Dictionary = blocks[bid]
		total += block_mass(data)
	body.mass = maxf(0.1, total)


# ================================================================ Nodos de bloques

func _shape_pair(data: Dictionary) -> Array:
	var def: Dictionary = defs[data["kind"]]
	var s: Vector3 = def["size"]
	var mesh: Mesh
	var shape: Shape3D
	var inner: Basis = Basis.IDENTITY
	match str(def["shape"]):
		"box":
			var size: Vector3 = data["size"]
			var bm := BoxMesh.new()
			bm.size = size
			mesh = bm
			var bs := BoxShape3D.new()
			bs.size = size
			shape = bs
		"sphere":
			var sm := SphereMesh.new()
			sm.radial_segments = 8
			sm.rings = 4
			sm.radius = s.x
			sm.height = s.x * 2.0
			mesh = sm
			var ss := SphereShape3D.new()
			ss.radius = s.x
			shape = ss
		_:
			var cm := CylinderMesh.new()
			cm.radial_segments = 6
			cm.rings = 1
			cm.top_radius = s.x
			cm.bottom_radius = s.x
			cm.height = s.y
			mesh = cm
			var cs := CylinderShape3D.new()
			cs.radius = s.x
			cs.height = s.y
			shape = cs
	var axis: String = str(def.get("axis", "y"))
	if axis == "x":
		inner = Basis(Vector3(0, 0, 1), PI / 2.0)
	elif axis == "z":
		inner = Basis(Vector3(1, 0, 0), PI / 2.0)
	return [mesh, shape, inner]


func free_block_nodes(body: Node, bid: int) -> void:
	for n in ["M%d" % bid, "C%d" % bid, "L%d" % bid]:
		var node: Node = body.get_node_or_null(n)
		if node != null:
			body.remove_child(node)
			node.queue_free()


func build_block_nodes(body: RigidBody3D, bid: int, data: Dictionary) -> void:
	free_block_nodes(body, bid)
	var pair: Array = _shape_pair(data)
	var inner: Basis = pair[2]
	var xf: Transform3D = data["xf"]
	var node_xf := Transform3D(xf.basis * inner, xf.origin)
	var def: Dictionary = defs[data["kind"]]
	var color: Color = data["color"]
	var special: String = str(def.get("special", ""))

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	var btex: String = str(def.get("tex", ""))
	if btex == "":
		btex = tex_override
	Textures.apply(mat, Textures.pick(btex, str(def["shape"]), color.to_html()), 0.5, color.to_html())
	if def.has("alpha"):
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = float(def["alpha"])
	if special == "light":
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0

	var mi := MeshInstance3D.new()
	mi.name = "M%d" % bid
	mi.mesh = pair[0] as Mesh
	mi.material_override = mat
	mi.transform = node_xf
	body.add_child(mi)

	var cs := CollisionShape3D.new()
	cs.name = "C%d" % bid
	cs.shape = pair[1] as Shape3D
	cs.transform = node_xf
	cs.set_meta("bid", bid)
	body.add_child(cs)

	if special == "light":
		var l := OmniLight3D.new()
		l.name = "L%d" % bid
		l.position = xf.origin
		l.light_color = color
		l.omni_range = 9.0
		l.light_energy = 1.5
		body.add_child(l)


func _init_struct_body(body: RigidBody3D, sid: int) -> void:
	body.name = "S%d" % sid
	body.set_meta("pid", sid)
	body.set_meta("kind", "Estructura")
	body.set_meta("structure", true)
	body.set_meta("blocks", {})
	body.add_to_group("props")
	body.can_sleep = false


func _new_structure(origin: Vector3, live: bool = false) -> RigidBody3D:
	var sid: int = world.next_pid
	world.next_pid += 1
	var body := RigidBody3D.new()
	_init_struct_body(body, sid)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.2
	body.physics_material_override = pm
	body.freeze = not live
	if live:
		body.set_meta("live", true)
	body.gravity_scale = 1.0 if world.gravity_on else 0.0
	world.add_child(body)
	body.global_position = origin
	world.props[sid] = body
	if multiplayer.get_peers().size() > 0:
		_c_struct.rpc(sid, body.global_transform, live)
	return body


## Agrega un bloque a una estructura que ya existe en los clientes. Devuelve el bid.
func _add_block(body: RigidBody3D, peer: int, kind: String, size: Vector3, color: Color, local_xf: Transform3D) -> int:
	var blocks: Dictionary = body.get_meta("blocks")
	if blocks.size() >= MAX_BLOCKS:
		return -1
	var bid: int = next_bid
	next_bid += 1
	var data := {"kind": kind, "size": size, "color": color, "xf": local_xf}
	blocks[bid] = data
	build_block_nodes(body, bid, data)
	update_mass(body)
	var sid: int = int(body.get_meta("pid"))
	if peer >= 0:
		_push_undo(peer, sid, bid)
	if multiplayer.get_peers().size() > 0:
		_c_block.rpc(sid, bid, kind, size, color, local_xf)
	return bid


func _delete_block(body: RigidBody3D, bid: int) -> void:
	var blocks: Dictionary = body.get_meta("blocks")
	blocks.erase(bid)
	free_block_nodes(body, bid)
	var sid: int = int(body.get_meta("pid"))
	if multiplayer.get_peers().size() > 0:
		_c_block_remove.rpc(sid, bid)
	if blocks.is_empty():
		world.remove_prop(body)
	else:
		update_mass(body)


func _resend_block(body: RigidBody3D, bid: int) -> void:
	var blocks: Dictionary = body.get_meta("blocks")
	var data: Dictionary = blocks[bid]
	build_block_nodes(body, bid, data)
	update_mass(body)
	if multiplayer.get_peers().size() > 0:
		_c_block.rpc(int(body.get_meta("pid")), bid, str(data["kind"]), data["size"], data["color"], data["xf"])


# ================================================================ Colocar

func request_place(kind: String, xf: Transform3D, size: Vector3, color: Color, sid: int) -> void:
	if multiplayer.is_server():
		server_place(1, kind, xf, size, color, sid)
	else:
		_req_place.rpc_id(1, kind, xf, size, color, sid)


@rpc("any_peer", "reliable")
func _req_place(kind: String, xf: Transform3D, size: Vector3, color: Color, sid: int) -> void:
	server_place(multiplayer.get_remote_sender_id(), kind, xf, size, color, sid)


func server_place(peer: int, kind: String, xf: Transform3D, size: Vector3, color: Color, sid: int) -> void:
	if not defs.has(kind):
		return
	var def: Dictionary = defs[kind]
	var bsize: Vector3 = def["size"]
	if str(def["shape"]) == "box":
		bsize = Vector3(clampf(size.x, 0.25, 8.0), clampf(size.y, 0.25, 8.0), clampf(size.z, 0.25, 8.0))
	var basis: Basis = xf.basis.orthonormalized()

	var body: RigidBody3D = null
	var local_xf: Transform3D
	if sid >= 0:
		body = get_struct(sid)
		if body == null or not body.freeze:
			return
		local_xf = body.global_transform.affine_inverse() * Transform3D(basis, xf.origin)
	else:
		body = _new_structure(xf.origin)
		local_xf = Transform3D(basis, Vector3.ZERO)

	var bid: int = _add_block(body, peer, kind, bsize, color, local_xf)
	if bid < 0:
		world.toast("Esa estructura llegó al máximo de bloques")
		return
	world.burst(xf.origin, color, 6)


# ================================================================ Editar (escalar, rotar, pintar, copiar, borrar)

func request_op(op: int, sid: int, bid: int, normal: Vector3, pos: Vector3, color: Color) -> void:
	if multiplayer.is_server():
		server_op(1, op, sid, bid, normal, pos, color)
	else:
		_req_op.rpc_id(1, op, sid, bid, normal, pos, color)


@rpc("any_peer", "reliable")
func _req_op(op: int, sid: int, bid: int, normal: Vector3, pos: Vector3, color: Color) -> void:
	server_op(multiplayer.get_remote_sender_id(), op, sid, bid, normal, pos, color)


func server_op(peer: int, op: int, sid: int, bid: int, normal: Vector3, _pos: Vector3, color: Color) -> void:
	var body: RigidBody3D = get_struct(sid)
	if body == null:
		# No es una estructura: puede ser un objeto suelto que se quiere pintar
		if op == OP_PAINT:
			world.paint_prop_color(sid, color)
		return
	if not body.freeze:
		return
	var blocks: Dictionary = body.get_meta("blocks")
	if not blocks.has(bid):
		return
	var data: Dictionary = blocks[bid]
	var def: Dictionary = defs[data["kind"]]
	var xf: Transform3D = data["xf"]

	# Eje del bloque más alineado con la normal de la cara tocada
	var nl: Vector3 = body.global_transform.basis.inverse() * normal
	var cols: Array = [xf.basis.x, xf.basis.y, xf.basis.z]
	var ai: int = 0
	var best: float = -1.0
	for i in 3:
		var cv: Vector3 = cols[i]
		var dv: float = absf(cv.dot(nl))
		if dv > best:
			best = dv
			ai = i
	var axis: Vector3 = cols[ai]
	var sgn: float = 1.0 if axis.dot(nl) >= 0.0 else -1.0
	var changed: bool = false

	match op:
		OP_PAINT:
			data["color"] = color
			changed = true
		OP_ROT_CW, OP_ROT_CCW:
			var ang: float = PI / 2.0 if op == OP_ROT_CW else -PI / 2.0
			xf.basis = (Basis(axis.normalized(), ang) * xf.basis).orthonormalized()
			data["xf"] = xf
			changed = true
		OP_SCALE_UP, OP_SCALE_DOWN:
			if str(def["shape"]) == "box":
				var size: Vector3 = data["size"]
				var step: float = 0.5 if op == OP_SCALE_UP else -0.5
				var old: float = size[ai]
				var nv: float = clampf(old + step, 0.25, 8.0)
				var delta: float = nv - old
				if absf(delta) > 0.001:
					size[ai] = nv
					data["size"] = size
					xf.origin += axis * sgn * delta * 0.5
					data["xf"] = xf
					changed = true
		OP_COPY:
			var dims: Vector3 = block_dims(data)
			var extent: float = maxf(dims.x, maxf(dims.y, dims.z))
			if str(def["shape"]) == "box":
				extent = dims[ai]
			var nxf := Transform3D(xf.basis, xf.origin + axis * sgn * extent)
			_add_block(body, peer, str(data["kind"]), data["size"], data["color"], nxf)
			return
		OP_DELETE:
			_delete_block(body, bid)
			return

	if changed:
		_resend_block(body, bid)


# ================================================================ Mover y rotar estructuras

func request_move(sid: int, pos: Vector3) -> void:
	if multiplayer.is_server():
		server_move(sid, pos)
	else:
		_req_move.rpc_id(1, sid, pos)


@rpc("any_peer", "unreliable")
func _req_move(sid: int, pos: Vector3) -> void:
	server_move(sid, pos)


func server_move(sid: int, pos: Vector3) -> void:
	var body: RigidBody3D = get_struct(sid)
	if body == null or not body.freeze:
		return
	body.global_position = pos
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO


func request_rotate_struct(sid: int) -> void:
	if multiplayer.is_server():
		server_rotate_struct(sid)
	else:
		_req_rotate_struct.rpc_id(1, sid)


@rpc("any_peer", "reliable")
func _req_rotate_struct(sid: int) -> void:
	server_rotate_struct(sid)


func server_rotate_struct(sid: int) -> void:
	var body: RigidBody3D = get_struct(sid)
	if body == null or not body.freeze:
		return
	var t: Transform3D = body.global_transform
	t.basis = (Basis(Vector3.UP, PI / 2.0) * t.basis).orthonormalized()
	body.global_transform = t


# ================================================================ Deshacer y borrar todo

func _push_undo(peer: int, sid: int, bid: int) -> void:
	var arr: Array = undo.get(peer, [])
	arr.append([sid, bid])
	if arr.size() > 60:
		arr.pop_front()
	undo[peer] = arr


func request_undo() -> void:
	if multiplayer.is_server():
		server_undo(1)
	else:
		_req_undo.rpc_id(1)


@rpc("any_peer", "reliable")
func _req_undo() -> void:
	server_undo(multiplayer.get_remote_sender_id())


func server_undo(peer: int) -> void:
	if launched:
		return
	var arr: Array = undo.get(peer, [])
	while not arr.is_empty():
		var e: Array = arr.pop_back()
		var body: RigidBody3D = get_struct(int(e[0]))
		if body == null:
			continue
		var blocks: Dictionary = body.get_meta("blocks")
		if blocks.has(int(e[1])):
			_delete_block(body, int(e[1]))
			break
	undo[peer] = arr


func request_clear_structs() -> void:
	if multiplayer.is_server():
		server_clear_structs()
	else:
		_req_clear_structs.rpc_id(1)


@rpc("any_peer", "reliable")
func _req_clear_structs() -> void:
	server_clear_structs()


func server_clear_structs() -> void:
	for pid in world.props.keys():
		var body: RigidBody3D = get_struct(int(pid))
		if body != null:
			world.remove_prop(body)
	launched = false
	drives.clear()
	undo.clear()
	build_xf.clear()
	if multiplayer.get_peers().size() > 0:
		_c_launched.rpc(false)
	world.toast("Construcciones borradas")


func on_cleared() -> void:
	launched = false
	drives.clear()
	undo.clear()
	build_xf.clear()
	cannon_cd.clear()


# ================================================================ Probar (launch)

func request_launch() -> void:
	if multiplayer.is_server():
		server_launch()
	else:
		_req_launch.rpc_id(1)


@rpc("any_peer", "reliable")
func _req_launch() -> void:
	server_launch()


func server_launch() -> void:
	launched = not launched
	for pid in world.props.keys():
		var body: RigidBody3D = get_struct(int(pid))
		if body == null or body.has_meta("live"):
			continue
		var sid: int = int(body.get_meta("pid"))
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		if launched:
			build_xf[sid] = body.global_transform
			body.freeze = false
		else:
			body.freeze = true
			if build_xf.has(sid):
				body.global_transform = build_xf[sid]
	drives.clear()
	if not launched:
		build_xf.clear()
	_show_launched(launched)
	if multiplayer.get_peers().size() > 0:
		_c_launched.rpc(launched)


func _show_launched(v: bool) -> void:
	launched = v
	world.toast("▶ Prueba iniciada: sentate (E) y conducí" if v else "■ Prueba detenida: volvés a construir")


# ================================================================ Conducir y disparar cañones

func request_drive(sid: int, forward: float, steer: float, vert: float) -> void:
	if multiplayer.is_server():
		drives[sid] = Vector3(steer, forward, vert)
	else:
		_req_drive.rpc_id(1, sid, forward, steer, vert)


@rpc("any_peer", "unreliable")
func _req_drive(sid: int, forward: float, steer: float, vert: float) -> void:
	drives[sid] = Vector3(steer, forward, vert)


func request_fire(sid: int) -> void:
	if multiplayer.is_server():
		server_fire(sid)
	else:
		_req_fire.rpc_id(1, sid)


@rpc("any_peer", "reliable")
func _req_fire(sid: int) -> void:
	server_fire(sid)


func _weapon_index(wname: String) -> int:
	var list: Array = world.WEAPONS
	for i in list.size():
		var w: Dictionary = list[i]
		if str(w["name"]) == wname:
			return i
	return 0


func server_fire(sid: int) -> void:
	var body: RigidBody3D = get_struct(sid)
	if body == null or body.freeze:
		return
	var blocks: Dictionary = body.get_meta("blocks")
	var rocket: int = _weapon_index("Lanzacohetes")
	for bid in blocks:
		var data: Dictionary = blocks[bid]
		var def: Dictionary = defs[data["kind"]]
		if str(def.get("special", "")) != "cannon":
			continue
		var key: String = "%d:%d" % [sid, int(bid)]
		if float(cannon_cd.get(key, 0.0)) > 0.0:
			continue
		cannon_cd[key] = CANNON_COOLDOWN
		var xf: Transform3D = data["xf"]
		var gx: Transform3D = body.global_transform * xf
		var fwd: Vector3 = -gx.basis.z.normalized()
		world.server_shoot(1, gx.origin + fwd * 1.1, fwd, rocket)
		body.apply_impulse(-fwd * body.mass * 0.6, gx.origin - body.global_position)


# ================================================================ Física de bloques con función

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_shock_check(delta)
	for key in cannon_cd.keys():
		cannon_cd[key] = maxf(0.0, float(cannon_cd[key]) - delta)
	for pid in world.props.keys():
		var body: RigidBody3D = get_struct(int(pid))
		if body == null or body.freeze:
			continue
		_water_forces(body)
		_apply_drive(body)


func _water_forces(body: RigidBody3D) -> void:
	var wl: float = world.water_level
	if wl < -1000.0:
		return
	var blocks: Dictionary = body.get_meta("blocks")
	var sub_total: float = 0.0
	for bid in blocks:
		var data: Dictionary = blocks[bid]
		var xf: Transform3D = data["xf"]
		var wp: Vector3 = body.global_transform * xf.origin
		var vol: float = block_volume(data)
		var half: float = pow(maxf(vol, 0.001), 1.0 / 3.0) * 0.5
		var ratio: float = clampf((wl - (wp.y - half)) / (half * 2.0), 0.0, 1.0)
		if ratio > 0.0:
			body.apply_force(Vector3.UP * vol * WATER_DENSITY * 9.8 * ratio, wp - body.global_position)
			sub_total += ratio
	var s: float = sub_total / float(maxi(1, blocks.size()))
	body.linear_damp = 0.1 + 1.5 * s
	body.angular_damp = 0.5 + 3.0 * s


func _apply_drive(body: RigidBody3D) -> void:
	var sid: int = int(body.get_meta("pid"))
	var d: Vector3 = drives.get(sid, Vector3.ZERO)   # x = giro, y = avance, z = vertical
	var blocks: Dictionary = body.get_meta("blocks")
	var wl: float = world.water_level
	var vel: Vector3 = body.linear_velocity
	var speed: float = vel.length()
	var bas: Basis = body.global_transform.basis
	var vf: float = -bas.z.normalized().dot(vel)
	var n_wheels: int = 0
	for bid in blocks:
		var data0: Dictionary = blocks[bid]
		var def0: Dictionary = defs[data0["kind"]]
		if str(def0.get("special", "")) == "wheel":
			n_wheels += 1
	var traction: bool = false
	var wings: int = 0

	for bid in blocks:
		var data: Dictionary = blocks[bid]
		var def: Dictionary = defs[data["kind"]]
		var sp: String = str(def.get("special", ""))
		if sp == "":
			continue
		var power: float = float(def.get("power", 1.0))
		var xf: Transform3D = data["xf"]
		var gx: Transform3D = body.global_transform * xf
		var rel: Vector3 = gx.origin - body.global_position
		match sp:
			"balloon":
				body.apply_force(Vector3.UP * BALLOON_LIFT, rel)
			"wheel":
				var dsz: Vector3 = def["size"]
				var q := PhysicsRayQueryParameters3D.create(gx.origin, gx.origin + Vector3.DOWN * (dsz.x + 0.3))
				q.exclude = [body.get_rid()]
				var res: Dictionary = body.get_world_3d().direct_space_state.intersect_ray(q)
				if not res.is_empty():
					traction = true
					var ax: Vector3 = gx.basis.x.normalized()
					var fwd: Vector3 = Vector3.UP.cross(ax).normalized()
					var k: float = 0.12 if d.y != 0.0 else 0.6
					var engine: float = d.y * WHEEL_FORCE * power if speed < MAX_SPEED else 0.0
					var share: float = float(maxi(1, n_wheels))
					body.apply_force(fwd * (engine - fwd.dot(vel) * body.mass * k / share), rel)
					body.apply_force(-ax * ax.dot(vel) * body.mass * 3.0 / share, rel)
			"prop":
				var wet: bool = wl > -1000.0 and gx.origin.y < wl
				if wet:
					traction = true
					if d.y != 0.0 and speed < MAX_SPEED:
						body.apply_force(-gx.basis.z.normalized() * d.y * PROP_FORCE * power, rel)
			"airprop":
				if d.y != 0.0 and speed < MAX_SPEED:
					body.apply_force(-gx.basis.z.normalized() * d.y * AIRPROP_FORCE * power, rel)
			"jet":
				if d.y != 0.0 and speed < MAX_SPEED:
					body.apply_force(-gx.basis.z.normalized() * d.y * JET_FORCE * power, rel)
			"rotor":
				body.apply_force(gx.basis.y.normalized() * body.mass * 9.8 * clampf(0.95 + d.y * 0.35 + d.z * 0.5, 0.0, 1.6), rel)
			"wing":
				var wsz: Vector3 = data["size"]
				var area: float = wsz.x * wsz.z / 4.0
				# La sustentación depende de la velocidad total (no solo del avance), así no se cae al girar o subir
				var lift: float = maxf(maxf(vf, speed * 0.6), 0.0) * WING_LIFT * area
				body.apply_force(gx.basis.y.normalized() * lift, rel)
				wings += 1

	if d.x != 0.0 and (traction or speed > 1.0):
		body.apply_torque(Vector3.UP * -d.x * STEER_TORQUE * sqrt(body.mass))
		if wings > 0:
			body.apply_torque(-bas.z.normalized() * d.x * STEER_TORQUE * sqrt(body.mass) * 0.6)
	if d.z != 0.0 and wings > 0 and vf > 3.0:
		body.apply_torque(bas.x.normalized() * d.z * PITCH_TORQUE * sqrt(body.mass))
	# Estabilizador de cabeceo: si la nariz sube demasiado, el avión la vuelve a bajar (evita que se haga la cola para adelante)
	if wings > 0 and speed > 2.0:
		var fwd_y: float = clampf(-bas.z.normalized().y, -1.0, 1.0)
		var pitch_angle: float = asin(fwd_y)
		var ax_pitch: Vector3 = bas.x.normalized()
		body.apply_torque(ax_pitch * (-pitch_angle * 40.0 - body.angular_velocity.dot(ax_pitch) * 6.0) * sqrt(body.mass))
	# Ayuda de vuelo: con alas, la gravedad pesa menos en el aire (no se cae sin motivo)
	if wings > 0 and speed > 4.0:
		body.apply_central_force(Vector3.UP * body.mass * 9.8 * 0.25)
	if wings > 0 and wl < -1000.0:
		body.angular_damp = 2.0
		body.linear_damp = 0.05


## Las hélices giran en todos los peers mientras dura la prueba.
func _process(delta: float) -> void:
	spin += delta * 18.0
	for pid in world.props.keys():
		var body: RigidBody3D = get_struct(int(pid))
		if body == null:
			continue
		if not (launched or body.has_meta("live")):
			continue
		var blocks: Dictionary = body.get_meta("blocks")
		for bid in blocks:
			var data: Dictionary = blocks[bid]
			var def: Dictionary = defs[data["kind"]]
			var spc: String = str(def.get("special", ""))
			if spc != "prop" and spc != "airprop" and spc != "rotor":
				continue
			var mi := body.get_node_or_null("M%d" % int(bid)) as MeshInstance3D
			if mi == null:
				continue
			var xf: Transform3D = data["xf"]
			var ax: Vector3 = Vector3.UP if spc == "rotor" else xf.basis.z.normalized()
			mi.transform = Transform3D(Basis(ax, spin) * xf.basis, xf.origin)


# ================================================================ Replicación (host -> clientes)

@rpc("authority", "reliable")
func _c_struct(sid: int, xf: Transform3D, live: bool = false) -> void:
	if world.props.has(sid):
		return
	var body := RigidBody3D.new()
	_init_struct_body(body, sid)
	if live:
		body.set_meta("live", true)
	body.transform = xf
	body.freeze = true
	body.gravity_scale = 0.0
	world.add_child(body)
	world.props[sid] = body


@rpc("authority", "reliable")
func _c_block(sid: int, bid: int, kind: String, size: Vector3, color: Color, xf: Transform3D) -> void:
	var body: RigidBody3D = get_struct(sid)
	if body == null or not defs.has(kind):
		return
	var blocks: Dictionary = body.get_meta("blocks")
	var data := {"kind": kind, "size": size, "color": color, "xf": xf}
	blocks[bid] = data
	build_block_nodes(body, bid, data)
	next_bid = maxi(next_bid, bid + 1)


@rpc("authority", "reliable")
func _c_block_remove(sid: int, bid: int) -> void:
	var body: RigidBody3D = get_struct(sid)
	if body == null:
		return
	var blocks: Dictionary = body.get_meta("blocks")
	blocks.erase(bid)
	free_block_nodes(body, bid)


@rpc("authority", "reliable")
func _c_launched(v: bool) -> void:
	_show_launched(v)


func send_state(peer: int) -> void:
	for pid in world.props.keys():
		var body: RigidBody3D = get_struct(int(pid))
		if body == null:
			continue
		var sid: int = int(body.get_meta("pid"))
		_c_struct.rpc_id(peer, sid, body.global_transform, body.has_meta("live"))
		var blocks: Dictionary = body.get_meta("blocks")
		for bid in blocks:
			var data: Dictionary = blocks[bid]
			_c_block.rpc_id(peer, sid, int(bid), str(data["kind"]), data["size"], data["color"], data["xf"])
	_c_launched.rpc_id(peer, launched)


# ================================================================ Guardado

func _xf_arr(t: Transform3D) -> Array:
	return [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z,
		t.basis.z.x, t.basis.z.y, t.basis.z.z, t.origin.x, t.origin.y, t.origin.z]


func _arr_xf(a: Array) -> Transform3D:
	return Transform3D(
		Basis(Vector3(a[0], a[1], a[2]), Vector3(a[3], a[4], a[5]), Vector3(a[6], a[7], a[8])),
		Vector3(a[9], a[10], a[11]))


func serialize() -> Array:
	var out: Array = []
	for pid in world.props.keys():
		var body: RigidBody3D = get_struct(int(pid))
		if body == null or body.has_meta("live"):
			continue
		var sid: int = int(body.get_meta("pid"))
		var base: Transform3D = body.global_transform
		if launched and build_xf.has(sid):
			base = build_xf[sid]
		var list: Array = []
		var blocks: Dictionary = body.get_meta("blocks")
		for bid in blocks:
			var data: Dictionary = blocks[bid]
			var size: Vector3 = data["size"]
			var color: Color = data["color"]
			var bxf: Transform3D = data["xf"]
			list.append({"kind": str(data["kind"]), "size": [size.x, size.y, size.z], "color": color.to_html(false), "xf": _xf_arr(bxf)})
		out.append({"xf": _xf_arr(base), "blocks": list})
	return out


func deserialize(arr: Array) -> void:
	if not multiplayer.is_server():
		return
	for item in arr:
		var s: Dictionary = item
		var xf_a: Array = s["xf"]
		var base: Transform3D = _arr_xf(xf_a)
		var body: RigidBody3D = _new_structure(base.origin)
		body.global_transform = base
		for b in s["blocks"]:
			var bd: Dictionary = b
			if not defs.has(str(bd["kind"])):
				continue
			var sz: Array = bd["size"]
			var bx: Array = bd["xf"]
			_add_block(body, -1, str(bd["kind"]), Vector3(sz[0], sz[1], sz[2]), Color.html("#" + str(bd["color"])), _arr_xf(bx))
		if (body.get_meta("blocks") as Dictionary).is_empty():
			world.remove_prop(body)


# ================================================================ Vehículos prearmados

func request_prefab(pname: String, xf: Transform3D) -> void:
	if multiplayer.is_server():
		server_prefab(pname, xf)
	else:
		_req_prefab.rpc_id(1, pname, xf)


@rpc("any_peer", "reliable")
func _req_prefab(pname: String, xf: Transform3D) -> void:
	server_prefab(pname, xf)


func server_prefab(pname: String, xf: Transform3D) -> void:
	var all: Dictionary = Content.prefabs().merged(ContentExtra.prefabs())
	if not all.has(pname):
		return
	var body: RigidBody3D = _new_structure(xf.origin, true)
	body.global_transform = Transform3D(xf.basis.orthonormalized(), xf.origin)
	var pre: Dictionary = all[pname]
	var list: Array = pre["blocks"]
	for item in list:
		var e: Dictionary = item
		var k: String = str(e["k"])
		if not defs.has(k):
			continue
		var def: Dictionary = defs[k]
		var size: Vector3 = def["size"]
		var sv: Vector3 = e["s"]
		if sv != Vector3.ZERO:
			size = sv
		var cs: String = str(e["c"])
		var color: Color = Color.html("#" + (cs if cs != "" else str(def["color"])))
		var rv: Vector3 = e["r"]
		var bas := Basis.from_euler(Vector3(deg_to_rad(rv.x), deg_to_rad(rv.y), deg_to_rad(rv.z)))
		var pos: Vector3 = e["p"]
		_add_block(body, -1, k, size, color, Transform3D(bas, pos))
	world.burst(xf.origin, Color(0.9, 0.9, 0.9), 16)


## Primer asiento de una estructura (o -1). Sirve para sentarse apuntando a cualquier parte del vehículo.
func find_seat(sid: int) -> int:
	var body: RigidBody3D = get_struct(sid)
	if body == null:
		return -1
	var blocks: Dictionary = body.get_meta("blocks")
	for bid in blocks:
		var data: Dictionary = blocks[bid]
		var def: Dictionary = defs[data["kind"]]
		if str(def.get("special", "")) == "seat":
			return int(bid)
	return -1


## Bloques "shock" (bobinas): electrocutan a jugadores y NPCs que estén cerca.
func _shock_check(delta: float) -> void:
	for key in shock_cd.keys():
		shock_cd[key] = maxf(0.0, float(shock_cd[key]) - delta)
	for pid in world.props.keys():
		var body: RigidBody3D = get_struct(int(pid))
		if body == null:
			continue
		var blocks: Dictionary = body.get_meta("blocks")
		for bid in blocks:
			var data: Dictionary = blocks[bid]
			var def: Dictionary = defs[data["kind"]]
			if str(def.get("special", "")) != "shock":
				continue
			var key2: String = "%d:%d" % [int(pid), int(bid)]
			if float(shock_cd.get(key2, 0.0)) > 0.0:
				continue
			var xf: Transform3D = data["xf"]
			var wp: Vector3 = body.global_transform * xf.origin
			var hit: bool = false
			# Radio amplio y medido desde el pecho (los pies están cerca del piso, la bobina también)
			for pl_v in world.players.values():
				var pl := pl_v as Player
				if pl != null and pl.shock_immune <= 0.0 and (pl.global_position + Vector3.UP * 0.9).distance_to(wp) < 2.4:
					world._stun_player(pl, 0.8)
					hit = true
			for n_v in world.npcs.npcs.values():
				var nn := n_v as NPC
				if nn != null and is_instance_valid(nn) and (nn.global_position + Vector3.UP * 0.9).distance_to(wp) < 2.4:
					nn.stun(2.0)
					hit = true
			if hit:
				shock_cd[key2] = 1.0
