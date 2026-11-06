class_name NpcManager
extends Node
## Crea, sincroniza y elimina NPCs. El host decide; los clientes solo reflejan.

const MAX_NPCS := 40

var world: Node = null
var npcs: Dictionary = {}   # nid -> NPC
var next_nid: int = 1
var sync_clock: float = 0.0


func nearest_player(pos: Vector3, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d: float = max_dist
	for pid in world.players:
		var p: Node3D = world.players[pid]
		if not is_instance_valid(p):
			continue
		var d: float = p.global_position.distance_to(pos)
		if d < best_d:
			best = p
			best_d = d
	return best


func _make(nid: int, kind: String, pos: Vector3, puppet: bool) -> NPC:
	var n := NPC.new()
	n.name = "N%d" % nid
	n.nid = nid
	n.kind = kind
	n.puppet = puppet
	n.world = world
	n.position = pos
	world.add_child(n)
	npcs[nid] = n
	return n


# ---------------------------------------------------------------- Crear

func request_spawn(kind: String, pos: Vector3) -> void:
	if multiplayer.is_server():
		server_spawn(kind, pos)
	else:
		_req_spawn.rpc_id(1, kind, pos)


@rpc("any_peer", "reliable")
func _req_spawn(kind: String, pos: Vector3) -> void:
	server_spawn(kind, pos)


func server_spawn(kind: String, pos: Vector3) -> void:
	if not NPC.KINDS.has(kind) or npcs.size() >= MAX_NPCS:
		return
	var nid: int = next_nid
	next_nid += 1
	_make(nid, kind, pos, false)
	if multiplayer.get_peers().size() > 0:
		_c_spawn.rpc(nid, kind, pos)


@rpc("authority", "reliable")
func _c_spawn(nid: int, kind: String, pos: Vector3) -> void:
	if npcs.has(nid):
		return
	_make(nid, kind, pos, true)


func send_state(peer: int) -> void:
	for nid in npcs:
		var n: NPC = npcs[nid]
		if is_instance_valid(n):
			_c_spawn.rpc_id(peer, int(nid), n.kind, n.global_position)


# ---------------------------------------------------------------- Eliminar

func kill(nid: int) -> void:
	var n: NPC = npcs.get(nid, null)
	if n == null:
		return
	world.burst(n.global_position + Vector3.UP, Color(0.8, 0.1, 0.1), 24)
	npcs.erase(nid)
	n.queue_free()
	if multiplayer.get_peers().size() > 0:
		_c_remove.rpc(nid)


@rpc("authority", "reliable")
func _c_remove(nid: int) -> void:
	var n: NPC = npcs.get(nid, null)
	npcs.erase(nid)
	if n != null and is_instance_valid(n):
		n.queue_free()


func request_clear() -> void:
	if multiplayer.is_server():
		clear_all()
	else:
		_req_clear.rpc_id(1)


@rpc("any_peer", "reliable")
func _req_clear() -> void:
	clear_all()


func clear_all() -> void:
	for nid in npcs.keys():
		var n: NPC = npcs[nid]
		if is_instance_valid(n):
			n.queue_free()
		if multiplayer.get_peers().size() > 0:
			_c_remove.rpc(int(nid))
	npcs.clear()


## Libera los nodos localmente (sin RPC). Se usa al volver al menú.
func clear_local() -> void:
	for nid in npcs.keys():
		var n: NPC = npcs[nid]
		if is_instance_valid(n):
			n.queue_free()
	npcs.clear()


# ---------------------------------------------------------------- Daño, gancho y explosiones

func explosion_damage(pos: Vector3, radius: float, power: float) -> void:
	for nid in npcs.keys():
		var n: NPC = npcs.get(nid, null)
		if n == null or not is_instance_valid(n):
			continue
		var off: Vector3 = n.global_position + Vector3.UP - pos
		var d: float = off.length()
		if d > radius:
			continue
		var f: float = 1.0 - d / radius
		n.take_damage(power * f * 1.5, (off + Vector3.UP * 0.3).normalized() * power * f * 0.25)


## Gancho tipo whiplash: tira del NPC hacia una posición.
func request_pull(nid: int, to_pos: Vector3) -> void:
	if multiplayer.is_server():
		server_pull(nid, to_pos)
	else:
		_req_pull.rpc_id(1, nid, to_pos)


@rpc("any_peer", "reliable")
func _req_pull(nid: int, to_pos: Vector3) -> void:
	server_pull(nid, to_pos)


func server_pull(nid: int, to_pos: Vector3) -> void:
	var n: NPC = npcs.get(nid, null)
	if n == null or not is_instance_valid(n):
		return
	var dir: Vector3 = (to_pos - n.global_position).normalized()
	n.velocity = dir * 28.0 + Vector3.UP * 4.0
	n.take_damage(5.0, Vector3.ZERO)


# ---------------------------------------------------------------- Sincronización

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	sync_clock += delta
	if sync_clock < 0.05:
		return
	sync_clock = 0.0
	if multiplayer.get_peers().size() == 0:
		return
	var ids := PackedInt32Array()
	var pos := PackedVector3Array()
	var yaws := PackedFloat32Array()
	var hps := PackedFloat32Array()
	for nid in npcs:
		var n: NPC = npcs[nid]
		if is_instance_valid(n):
			ids.append(int(nid))
			pos.append(n.global_position)
			yaws.append(n.rotation.y)
			hps.append(n.hp)
	_c_sync.rpc(ids, pos, yaws, hps)


@rpc("authority", "unreliable")
func _c_sync(ids: PackedInt32Array, pos: PackedVector3Array, yaws: PackedFloat32Array, hps: PackedFloat32Array) -> void:
	for i in ids.size():
		var n: NPC = npcs.get(ids[i], null)
		if n != null and is_instance_valid(n):
			n.net_pos = pos[i]
			n.net_yaw = yaws[i]
			n.net_hp = hps[i]
