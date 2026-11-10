class_name Player
extends CharacterBody3D
## Jugador: movimiento, barra de ítems (herramientas y armas por separado), construcción estilo
## Build a Boat for Treasure, gancho whiplash (R), vehículos (E) y sincronización multijugador.

signal tool_changed(slot: int)
signal hotbar_changed
signal notify(msg: String)

const SPEED := 6.0
const SPRINT_SPEED := 10.0
const JUMP_VELOCITY := 5.5
const NOCLIP_SPEED := 14.0
const MOUSE_SENS := 0.003
const TOUCH_LOOK_SENS := 0.006
const MAX_HP := 100.0
const SLOTS := 12
const WHIP_RANGE := 70.0
const WHIP_PULL_SPEED := 40.0

## Herramientas "utilidad" -> id que entiende main.server_act
const UTIL_IDS := {"push": 2, "explode": 3, "magnet": 10, "blower": 11, "teleport": 12, "levitate": 13, "mass": 8, "freeze": 9}
const NEEDS_BODY_UTIL := ["push", "levitate", "mass", "freeze"]

var world: Node = null
var builder: Builder = null
var camera: Camera3D
var body_mesh: MeshInstance3D
var beam_main: MeshInstance3D
var beam_glow: MeshInstance3D
var rope: MeshInstance3D
var ghost: MeshInstance3D
var name_tag: Label3D

var display_name: String = ""
var hotbar: Array = []
var slot: int = 0
var weapons: Array = Content.weapons()
var noclip: bool = false
var gravity_scale: float = 1.0
var water_level: float = -100000.0
var shake: float = 0.0
var hp: float = MAX_HP
var stun_time: float = 0.0
var touch_mode: bool = false
var input_enabled: bool = true
var touch_move: Vector2 = Vector2.ZERO
var touch_jump: bool = false
var hooked: bool = false
var hook_point: Vector3 = Vector3.ZERO

var held_pid: int = -1
var held_kind: String = "prop"
var hold_distance: float = 4.0
var move_sid: int = -1
var move_dist: float = 6.0
var move_off: Vector3 = Vector3.ZERO
var seat_sid: int = -1
var seat_bid: int = -1

var ghost_basis: Basis = Basis.IDENTITY
var ghost_xf: Transform3D = Transform3D.IDENTITY
var ghost_valid: bool = false
var ghost_sid: int = -1

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _layer: int = 1
var _mask: int = 1
var _shoot_cd: float = 0.0
var _whip_cd: float = 0.0
var _whip_flash: float = 0.0
var _whip_end: Vector3 = Vector3.ZERO
var _firing: bool = false
var freecam: bool = false
var touch_crouch: bool = false
var touch_slam: bool = false
var _bhop_buffer: float = 0.0
var _bhop_landed: bool = false
var _zap_until: int = 0
var _ignore_stun: bool = false
var armor: float = 100.0
var _armor_delay: float = 0.0
var _gun_name: String = ""
var _gun_view: Node3D = null
var _gun_body: Node3D = null
var _slam_active: bool = false
var _slam_cd: float = 0.0
var _mg_next_ms: int = 0
var _fall_v: float = 0.0
var _prev_air: bool = false
var _jump_t: float = 0.0
var _was_floor: bool = true
var _crush_cd: float = 0.0
var _slam_hit: bool = false
var _pull: Vector3 = Vector3.ZERO
var _recoil: float = 0.0
var _anim_last: Vector3 = Vector3.ZERO
var _anim_speed: float = 0.0
var shock_immune: float = 0.0
var _free_pos: Vector3 = Vector3.ZERO
var _ghost_shape: BoxShape3D = BoxShape3D.new()
var _last_name: String = ""
var _bones: Node3D = null
var _model_root: Node3D = null
var body_color: Color = Color(0, 0, 0, 0)
var auto_fire: bool = false


func _ready() -> void:
	var mine: bool = is_multiplayer_authority()
	_net_target = global_position
	_net_yaw = rotation.y
	builder = world.builder
	hotbar = Content.default_hotbar()

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	var shirt_col: Color = body_color if body_color.a > 0.0 else Color.from_hsv(fposmod(float(name.to_int()) * 0.17, 1.0), 0.7, 0.9)
	var model: Dictionary = Humanoid.build(self, shirt_col)
	body_mesh = model["torso"] as MeshInstance3D
	(model["root"] as Node3D).visible = not mine
	_model_root = model["root"] as Node3D
	Humanoid.skin_texture(_model_root, "cloth", str(get_multiplayer_authority()))

	name_tag = Label3D.new()
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.pixel_size = 0.007
	name_tag.font_size = 48
	name_tag.outline_size = 12
	name_tag.no_depth_test = true
	name_tag.position.y = 2.25
	name_tag.visible = not mine
	add_child(name_tag)

	camera = Camera3D.new()
	camera.position.y = 1.6
	add_child(camera)
	if mine:
		camera.make_current()

	beam_main = _make_beam(Color(0.4, 0.9, 1.0))
	beam_glow = _make_beam(Color(1.0, 1.0, 1.0))
	rope = _make_beam(Color(0.95, 0.85, 0.4))

	# Fantasma de construcción (solo se usa con la herramienta Construir)
	ghost = MeshInstance3D.new()
	ghost.mesh = BoxMesh.new()
	ghost.top_level = true
	ghost.visible = false
	var gmat := StandardMaterial3D.new()
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.albedo_color = Color(0.3, 1.0, 0.4, 0.45)
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.material_override = gmat
	add_child(ghost)

	# Sincronización: posición, giro, vida, gancho y nombre
	var sync := MultiplayerSynchronizer.new()
	sync.root_path = NodePath("..")
	var cfg := SceneReplicationConfig.new()
	for p in [":hooked", ":hook_point", ":display_name", ":seat_sid"]:
		cfg.add_property(NodePath(p))
	sync.replication_config = cfg
	sync.name = "Sync"  # nombre fijo: igual en todos los PCs
	add_child(sync)

	_layer = collision_layer
	_mask = collision_mask


func _make_beam(color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = ImmediateMesh.new()
	mi.top_level = true
	mi.visible = false
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mi.material_override = mat
	add_child(mi)
	return mi


## Dibuja un rayo con zigzag (jitter 0 = línea recta).
static func build_bolt(im: ImmediateMesh, a: Vector3, b: Vector3, jitter: float, color: Color) -> void:
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	im.surface_set_color(color)
	var segs: int = 16
	for i in segs + 1:
		var t: float = float(i) / float(segs)
		var p: Vector3 = a.lerp(b, t)
		if i > 0 and i < segs:
			p += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * jitter
		im.surface_add_vertex(p)
	im.surface_end()


# ================================================================ Barra de ítems

func item_id() -> String:
	return str(hotbar[slot])


func item_name() -> String:
	return Content.item_label(item_id())


func is_weapon() -> bool:
	return item_id().begins_with("w:")


func _weapon_index(wname: String) -> int:
	for i in weapons.size():
		var w: Dictionary = weapons[i]
		if str(w["name"]) == wname:
			return i
	return 0


func set_slot_item(i: int, id: String) -> void:
	if i < 0 or i >= SLOTS:
		return
	hotbar[i] = id
	hotbar_changed.emit()
	if i == slot:
		select_slot(i)


func select_slot(i: int) -> void:
	_reset_actions()
	slot = wrapi(i, 0, SLOTS)
	tool_changed.emit(slot)


func cycle_slot(dir: int) -> void:
	select_slot(slot + dir)


## Cambia al siguiente arma del hotbar (botón "Ver armas").
func cycle_weapon(dir: int) -> void:
	for k in range(1, SLOTS + 1):
		var i: int = wrapi(slot + dir * k, 0, SLOTS)
		if str(hotbar[i]).begins_with("w:"):
			select_slot(i)
			return
	notify.emit("No tenés armas en el hotbar")


func _reset_actions() -> void:
	_firing = false
	move_sid = -1
	release()
	ghost.visible = false
	ghost_valid = false


# ================================================================ Efectos y daño

var _net_target: Vector3 = Vector3.ZERO
var _net_yaw: float = 0.0
var _net_t: float = 0.0
var _net_hp: float = 100.0
var _net_spd: float = 0.0
var _net_air: bool = false
var _net_stun: bool = false
var _net_seat: bool = false


## Posición y giro enviados por el dueño del personaje a todos (sin depender de MultiplayerSynchronizer).
@rpc("authority", "unreliable")
func _net_state(pos: Vector3, yaw: float, hp_v: float, spd: float, air: bool, stun: bool, seat: bool) -> void:
	_net_target = pos
	_net_yaw = yaw
	_net_hp = hp_v
	_net_spd = spd
	_net_air = air
	_net_stun = stun
	_net_seat = seat


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		_net_t -= delta
		if _net_t <= 0.0 and multiplayer.multiplayer_peer != null and multiplayer.get_peers().size() > 0:
			_net_t = 0.05
			_net_state.rpc(global_position, rotation.y, hp, _anim_speed, not is_on_floor(), stun_time > 0.0, seat_sid >= 0)
	else:
		global_position = global_position.lerp(_net_target, minf(1.0, 14.0 * delta))
		rotation.y = lerp_angle(rotation.y, _net_yaw, minf(1.0, 12.0 * delta))
		hp = _net_hp
		_anim_speed = _net_spd
	_sync_gun()
	_animate_gun(delta)
	_anim_speed = (global_position - _anim_last).length() / maxf(delta, 0.001)
	_anim_last = global_position
	var air_now: bool = (not is_on_floor()) if is_multiplayer_authority() else _net_air
	if air_now and not _prev_air:
		_jump_t = 0.2
	_prev_air = air_now
	_jump_t = maxf(0.0, _jump_t - delta)
	if _model_root != null:
		var air: bool = air_now
		var stn: bool = (stun_time > 0.0) if is_multiplayer_authority() else _net_stun
		var seated: bool = (seat_sid >= 0) if is_multiplayer_authority() else _net_seat
		Humanoid.animate(_model_root, Time.get_ticks_msec() / 1000.0, _anim_speed, air, stn, seated, delta, _jump_t)
	if shake > 0.0:
		camera.h_offset = randf_range(-1.0, 1.0) * shake * 0.1
		camera.v_offset = randf_range(-1.0, 1.0) * shake * 0.1
		shake = maxf(0.0, shake - delta * 2.0)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
	if display_name != _last_name:
		_last_name = display_name
		name_tag.text = display_name
	_whip_flash = maxf(0.0, _whip_flash - delta)
	# el esqueleto se ve en los demás (a vos no te lo mostramos en primera persona)
	# Los demás ven la descarga por la señal de red (_net_stun); el dueño la ve por su propio stun
	var stunned_now: bool = (stun_time > 0.0) if is_multiplayer_authority() else _net_stun
	if stunned_now:
		_zap_until = Time.get_ticks_msec() + 250
	var show_bones: bool = Time.get_ticks_msec() < _zap_until
	if show_bones and _bones == null:
		_bones = Player.make_zap_rig(1.8)
		add_child(_bones)
	if _bones != null:
		_bones.visible = show_bones
	if _bones != null and show_bones:
		Player.update_zap(_bones)
	if _model_root != null:
		_model_root.visible = (not show_bones) and ((not is_multiplayer_authority()) or freecam or (seat_sid >= 0 and stun_time > 0.0))
	_update_rope()


func add_shake(amount: float) -> void:
	shake = minf(shake + amount, 2.0)


func knockback(v: Vector3) -> void:
	if not noclip and seat_sid < 0:
		velocity += v


@rpc("any_peer", "reliable")
func receive_knock(v: Vector3) -> void:
	knockback(v)


@rpc("any_peer", "reliable")
func receive_stun(sec: float) -> void:
	stun_time = maxf(stun_time, sec)


## Lo llama el servidor cuando te pegan. Corre en tu peer (dueño del jugador).
@rpc("any_peer", "reliable")
func receive_hit(dmg: float) -> void:
	Sfx.play("hurt")
	# La armadura absorbe hasta el 60% del daño mientras tenga puntos
	var blocked: float = minf(armor, dmg * 0.6)
	armor -= blocked
	_armor_delay = 5.0
	hp = maxf(0.0, hp - (dmg - blocked))
	if hp <= 0.0:
		# Al morir la vida y la armadura vuelven al máximo (no queda daño acumulado)
		hp = MAX_HP
		armor = 100.0
		_armor_delay = 0.0
		_stand_up()
		_release_hook()
		velocity = Vector3.ZERO
		var sp: Vector3 = world._spawn_point()
		global_position = sp
		notify.emit("Te eliminaron. Reapareciste")


# ================================================================ Entrada

func _is_active() -> bool:
	if not input_enabled or (stun_time > 0.0 and not _ignore_stun):
		return false
	return touch_mode or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func _key(k: Key) -> bool:
	return _is_active() and Input.is_physical_key_pressed(k)


func _move_axes(arrows: bool = false) -> Vector3:
	var kf: int = KEY_UP if arrows else Controls.k(0)
	var kb: int = KEY_DOWN if arrows else Controls.k(1)
	var kl: int = KEY_LEFT if arrows else Controls.k(2)
	var kr: int = KEY_RIGHT if arrows else Controls.k(3)
	var d := Vector3.ZERO
	if _key(kf): d.z -= 1.0
	if _key(kb): d.z += 1.0
	if _key(kl): d.x -= 1.0
	if _key(kr): d.x += 1.0
	d.x += touch_move.x
	d.z += touch_move.y
	return d.limit_length(1.0)


func _look(rel: Vector2, sens: float) -> void:
	if freecam:
		camera.rotation.y -= rel.x * sens
		camera.rotation.x = clampf(camera.rotation.x - rel.y * sens, -1.5, 1.5)
		return
	rotate_y(-rel.x * sens)
	camera.rotation.x = clampf(camera.rotation.x - rel.y * sens, -1.5, 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == Controls.k(9) and seat_sid >= 0 and is_multiplayer_authority():
		_stand_up()
		return
	if not is_multiplayer_authority() or not _is_active():
		return

	if event is InputEventMouseMotion and not touch_mode:
		var m := event as InputEventMouseMotion
		_look(m.relative, MOUSE_SENS * Settings.sensitivity_pct / 100.0)

	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_look(d.relative, TOUCH_LOOK_SENS)

	elif event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_LEFT and not touch_mode:
			if b.pressed:
				tool_press()
			else:
				tool_release()
		elif b.button_index == MOUSE_BUTTON_RIGHT and b.pressed:
			tool_secondary()
		elif b.pressed and (b.button_index == MOUSE_BUTTON_WHEEL_UP or b.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var up: bool = b.button_index == MOUSE_BUTTON_WHEEL_UP
			if held_pid >= 0:
				hold_distance = clampf(hold_distance + (0.5 if up else -0.5), 1.5, 30.0)
			elif move_sid >= 0:
				move_dist = clampf(move_dist + (0.5 if up else -0.5), 2.0, 60.0)
			else:
				cycle_slot(-1 if up else 1)

	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == Controls.k(7):
				_toggle_noclip()
			elif k.keycode == Controls.k(8):
				toggle_hook()
			elif k.keycode == Controls.k(9):
				toggle_seat()
			elif k.keycode == Controls.k(10):
				toggle_freecam()
			match k.keycode:
				KEY_Z:
					if not k.ctrl_pressed:
						rotate_ghost(k.shift_pressed)
				KEY_1: select_slot(0)
				KEY_2: select_slot(1)
				KEY_3: select_slot(2)
				KEY_4: select_slot(3)
				KEY_5: select_slot(4)
				KEY_6: select_slot(5)
				KEY_7: select_slot(6)
				KEY_8: select_slot(7)
				KEY_9: select_slot(8)
				KEY_0: select_slot(9)
				KEY_MINUS: select_slot(10)
				KEY_EQUAL: select_slot(11)


# ================================================================ Usar ítems

func tool_press() -> void:
	if freecam and seat_sid < 0:
		return
	if seat_sid >= 0:
		builder.request_fire(seat_sid)
		return
	var id: String = item_id()
	if id.begins_with("w:"):
		_firing = true
		_shoot_once()
		return
	match id:
		"build": _build_click()
		"move": _move_start()
		"scale", "rotate", "delete", "paint", "copy": _edit_click(id, false)
		"spawn": _spawn_click()
		"physgun": _start_hold()
		_: _use_util(id)


func tool_release() -> void:
	_firing = false
	move_sid = -1
	var pid: int = held_pid
	release()
	if pid >= 0 and world.snap_enabled:
		world.request_snap(pid)


func tool_secondary() -> void:
	if seat_sid >= 0:
		return
	match item_id():
		"physgun": _freeze_held()
		"move": _rotate_struct()
		"scale", "rotate", "paint": _edit_click(item_id(), true)


func _raycast(dist: float = 100.0) -> Dictionary:
	var from: Vector3 = camera.global_position
	var to: Vector3 = from - camera.global_transform.basis.z * dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	query.collision_mask = 0xFFFFFFFF
	return get_world_3d().direct_space_state.intersect_ray(query)


func _hit_prop(hit: Dictionary) -> RigidBody3D:
	if hit.is_empty():
		return null
	return hit.get("collider") as RigidBody3D


func _aim_point(dist: float) -> Vector3:
	return camera.global_position - camera.global_transform.basis.z * dist


# ---------------------------------------------------------------- Physgun

func _start_hold() -> void:
	var hit: Dictionary = _raycast()
	var col: Object = hit.get("collider") if not hit.is_empty() else null
	if col is NPC:
		held_pid = (col as NPC).nid
		held_kind = "npc"
	elif col is Player and col != self:
		held_pid = (col as Player).get_multiplayer_authority()
		held_kind = "player"
	else:
		var body: RigidBody3D = _hit_prop(hit)
		if body == null:
			notify.emit("Physgun: no hay nada para agarrar ahí")
			return
		var pid: int = int(body.get_meta("pid", -1))
		if pid < 0:
			return
		held_pid = pid
		held_kind = "prop"
	var p: Vector3 = hit["position"]
	hold_distance = camera.global_position.distance_to(p)


func _update_held() -> void:
	if held_pid < 0:
		return
	world.request_hold(held_pid, _aim_point(hold_distance), held_kind)


func _freeze_held() -> void:
	if held_pid >= 0:
		world.request_freeze(held_pid)
	release()


func release() -> void:
	if held_pid >= 0 and world != null:
		world.request_hold(-1, Vector3.ZERO, held_kind)
	held_pid = -1


# ---------------------------------------------------------------- Construir (fantasma + colocar)

func rotate_ghost(pitch: bool) -> void:
	if item_id() != "build":
		return
	var axis: Vector3 = Vector3.RIGHT if pitch else Vector3.UP
	ghost_basis = (Basis(axis, PI / 2.0) * ghost_basis).orthonormalized()
	notify.emit("Bloque rotado")


func _axis_snap(v: Vector3) -> Vector3:
	var ax: float = absf(v.x)
	var ay: float = absf(v.y)
	var az: float = absf(v.z)
	if ax >= ay and ax >= az:
		return Vector3(signf(v.x), 0.0, 0.0)
	if ay >= az:
		return Vector3(0.0, signf(v.y), 0.0)
	return Vector3(0.0, 0.0, signf(v.z))


func _update_ghost() -> void:
	if item_id() == "spawn" and _is_active() and seat_sid < 0:
		_update_spawn_ghost()
		return
	if item_id() != "build" or not _is_active() or seat_sid >= 0:
		ghost.visible = false
		ghost_valid = false
		return
	var hit: Dictionary = _raycast(45.0)
	if hit.is_empty():
		ghost.visible = false
		ghost_valid = false
		return

	var kind: String = builder.sel_block
	var def: Dictionary = builder.defs[kind]
	var dsize: Vector3 = def["size"]
	var dims: Vector3 = builder.block_dims({"kind": kind, "size": dsize})
	var n: Vector3 = hit["normal"]
	var p: Vector3 = hit["position"]
	var col: RigidBody3D = _hit_prop(hit)

	var frame: Transform3D = Transform3D.IDENTITY
	var live_hit: bool = false
	ghost_sid = -1
	if col != null and col.has_meta("structure"):
		if col.freeze:
			ghost_sid = int(col.get_meta("pid"))
			frame = col.global_transform
		else:
			live_hit = true

	var lp: Vector3 = frame.affine_inverse() * p
	var ln: Vector3 = _axis_snap(frame.basis.inverse() * n)
	var half: float = Builder.half_extent(ghost_basis, dims, ln)
	var lc: Vector3 = lp if world.center_mode else lp + ln * half
	for i in 3:
		if absf(ln[i]) < 0.5 and (ghost_sid >= 0 or world.snap_enabled):
			var d: float = maxf(dims[i], 0.25)
			lc[i] = snappedf(lp[i], d)
	ghost_xf = frame * Transform3D(ghost_basis, lc)

	_ghost_shape.size = dims * 0.8
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _ghost_shape
	q.transform = ghost_xf
	q.exclude = [get_rid()]
	var overlaps: Array = get_world_3d().direct_space_state.intersect_shape(q, 8)
	var blocked: bool = false
	for o in overlaps:
		var oc: Object = (o as Dictionary).get("collider")
		if oc is StaticBody3D:
			continue
		blocked = true
	ghost_valid = not blocked and not live_hit

	(ghost.mesh as BoxMesh).size = dims
	ghost.global_transform = ghost_xf
	var gm := ghost.material_override as StandardMaterial3D
	gm.albedo_color = Color(0.3, 1.0, 0.4, 0.45) if ghost_valid else Color(1.0, 0.3, 0.3, 0.45)
	ghost.visible = true


func _build_click() -> void:
	if not ghost_valid:
		return
	var kind: String = builder.sel_block
	var def: Dictionary = builder.defs[kind]
	var dsize: Vector3 = def["size"]
	builder.request_place(kind, ghost_xf, dsize, builder.sel_color, ghost_sid)


# ---------------------------------------------------------------- Mover estructuras

func _move_start() -> void:
	var hit: Dictionary = _raycast(80.0)
	var body: RigidBody3D = _hit_prop(hit)
	if body == null or not body.has_meta("structure") or not body.freeze:
		return
	move_sid = int(body.get_meta("pid"))
	var p: Vector3 = hit["position"]
	move_dist = camera.global_position.distance_to(p)
	move_off = body.global_position - _aim_point(move_dist)


func _update_move() -> void:
	if move_sid < 0:
		return
	var t: Vector3 = _aim_point(move_dist) + move_off
	t = Vector3(snappedf(t.x, 0.5), snappedf(t.y, 0.5), snappedf(t.z, 0.5))
	builder.request_move(move_sid, t)


func _rotate_struct() -> void:
	var sid: int = move_sid
	if sid < 0:
		var hit: Dictionary = _raycast(80.0)
		var body: RigidBody3D = _hit_prop(hit)
		if body == null or not body.has_meta("structure"):
			return
		sid = int(body.get_meta("pid"))
	builder.request_rotate_struct(sid)


# ---------------------------------------------------------------- Editar bloques (escalar, rotar, pintar, copiar, borrar)

func _edit_click(id: String, secondary: bool) -> void:
	var hit0: Dictionary = _raycast(120.0)
	var col0: Object = hit0.get("collider") if not hit0.is_empty() else null
	if col0 is NPC and id == "delete":
		world.request_act(12, (col0 as NPC).nid, hit0["position"], -camera.global_transform.basis.z)
		return
	var hit: Dictionary = _raycast(120.0)
	var body: RigidBody3D = _hit_prop(hit)
	if body == null:
		return
	var pid: int = int(body.get_meta("pid", -1))
	if pid < 0:
		return
	var pos: Vector3 = hit["position"]
	var nrm: Vector3 = hit["normal"]
	var dir: Vector3 = -camera.global_transform.basis.z

	if body.has_meta("structure"):
		if not body.freeze:
			notify.emit("Frená la estructura para editarla (Physgun, click derecho)")
			return
		var ids: Array = builder.block_from_hit(hit)
		var bid: int = int(ids[1])
		if bid < 0:
			return
		var data: Dictionary = builder.block_data(pid, bid)
		if data.is_empty():
			return
		var op: int = -1
		match id:
			"scale":
				var def: Dictionary = builder.defs[data["kind"]]
				if str(def["shape"]) != "box":
					notify.emit("Solo los bloques cuadrados se pueden escalar")
					return
				op = Builder.OP_SCALE_DOWN if secondary else Builder.OP_SCALE_UP
			"rotate":
				op = Builder.OP_ROT_CCW if secondary else Builder.OP_ROT_CW
			"paint":
				if secondary:
					builder.sel_color = data["color"]
					notify.emit("Color copiado del bloque")
					return
				op = Builder.OP_PAINT
			"copy":
				op = Builder.OP_COPY
			"delete":
				op = Builder.OP_DELETE
		if op >= 0:
			builder.request_op(op, pid, bid, nrm, pos, builder.sel_color)
	else:
		# Objeto suelto
		match id:
			"delete": world.request_act(1, pid, pos, dir)
			"copy": world.request_act(4, pid, pos, dir)
			"rotate": world.request_act(7, pid, pos, dir)
			"paint": builder.request_op(Builder.OP_PAINT, pid, -1, nrm, pos, builder.sel_color)
			"scale": notify.emit("Escalar funciona con bloques de construcción")


# ---------------------------------------------------------------- Spawn (lo que elegís en el menú de objetos)

func _update_spawn_ghost() -> void:
	var hit: Dictionary = _raycast(80.0)
	if hit.is_empty():
		ghost.visible = false
		ghost_valid = false
		return
	var dims: Vector3 = world.spawn_dims()
	var n: Vector3 = hit["normal"]
	var p: Vector3 = hit["position"]
	var half: float = Builder.half_extent(Basis.IDENTITY, dims, n)
	var c: Vector3 = p if world.center_mode else p + n * half
	if world.ground_snap and n.y > 0.5:
		c.y = maxf(c.y, p.y + half)
	ghost_xf = Transform3D(Basis(Vector3.UP, rotation.y), c)
	(ghost.mesh as BoxMesh).size = dims
	ghost.global_transform = ghost_xf
	var gm := ghost.material_override as StandardMaterial3D
	gm.albedo_color = Color(0.3, 0.6, 1.0, 0.45)
	ghost_valid = true
	ghost.visible = true


func _spawn_click() -> void:
	if not ghost_valid:
		return
	world.spawn_at_ghost(ghost_xf)


# ---------------------------------------------------------------- Utilidades

func _use_util(id: String) -> void:
	if not UTIL_IDS.has(id):
		return
	var code: int = int(UTIL_IDS[id])
	var hit: Dictionary = _raycast()
	var has_hit: bool = not hit.is_empty()
	var pos: Vector3 = _aim_point(30.0)
	if has_hit:
		pos = hit["position"]

	if id == "teleport":
		if has_hit:
			var n: Vector3 = hit["normal"]
			global_position = pos + n * 1.2
			velocity = Vector3.ZERO
		return

	var body: RigidBody3D = _hit_prop(hit)
	var pid: int = int(body.get_meta("pid", -1)) if body != null else -1
	if pid < 0 and NEEDS_BODY_UTIL.has(id):
		return
	world.request_act(code, pid, pos, -camera.global_transform.basis.z)


# ---------------------------------------------------------------- Armas (cada arma es su propio ítem)

## El servidor mueve al jugador agarrado con la physgun (lo aplica el dueño y se sincroniza).
@rpc("any_peer", "unreliable")
func receive_pull_pos(p: Vector3) -> void:
	global_position = p
	velocity = Vector3.ZERO


func receive_pull(v: Vector3) -> void:
	_pull = v


func _shoot_once() -> void:
	if _shoot_cd > 0.0 or not is_weapon():
		return
	var wn: String = item_id().substr(2)
	_muzzle_flash(Color(0.5, 0.85, 1.0) if wn == "Taser" else Color(1.0, 0.8, 0.35))
	if wn == "Taser":
		# El Taser suena en bucle mientras dura la descarga (3 segundos)
		Sfx.loop_for("taser", 3.0)
	elif wn == "Ametralladora":
		# La ametralladora repite el disparo a un ritmo medio (cada 0.12 s)
		var now: int = Time.get_ticks_msec()
		if now >= _mg_next_ms:
			Sfx.play("disparo")
			_mg_next_ms = now + 120
	else:
		Sfx.play("disparo")
	var idx: int = _weapon_index(item_id().substr(2))
	var w: Dictionary = weapons[idx]
	_shoot_cd = float(w.get("cd", 0.25))
	add_shake(0.08)
	world.request_shoot(camera.global_position, -camera.global_transform.basis.z, idx)


func _update_beam() -> void:
	var body: RigidBody3D = null
	if held_pid >= 0 and world != null:
		body = world.get_prop(held_pid)
	if body == null or not is_instance_valid(body):
		beam_main.visible = false
		beam_glow.visible = false
		return
	beam_main.visible = true
	beam_glow.visible = true
	var from: Vector3 = camera.global_position + camera.global_transform.basis * Vector3(0.3, -0.2, -0.5)
	var to: Vector3 = body.global_position
	build_bolt(beam_main.mesh as ImmediateMesh, from, to, 0.12, Color(0.4, 0.9, 1.0))
	build_bolt(beam_glow.mesh as ImmediateMesh, from, to, 0.04, Color(1.0, 1.0, 1.0))


# ================================================================ Gancho whiplash (R), como en Ultrakill

## Objetos livianos y NPCs: los tira hacia vos. Superficies, estructuras y objetos pesados: te tira a vos hacia ellos.
func toggle_hook() -> void:
	if seat_sid >= 0 or noclip:
		return
	if hooked:
		_release_hook()
		return
	if _whip_cd > 0.0:
		return
	var hit: Dictionary = _raycast(WHIP_RANGE)
	if hit.is_empty():
		notify.emit("Gancho: no hay nada al alcance")
		return
	_whip_cd = 0.35
	var pos: Vector3 = hit["position"]
	var col: Object = hit.get("collider")
	var npc := col as NPC
	var rb := col as RigidBody3D
	var to_me: Vector3 = global_position + Vector3.UP * 1.2

	if npc != null:
		world.npcs.request_pull(npc.nid, to_me)
		_flash_rope(pos)
	elif rb != null and not rb.has_meta("structure") and rb.mass <= 60.0:
		world.request_act(14, int(rb.get_meta("pid", -1)), to_me, Vector3.ZERO)
		_flash_rope(pos)
	else:
		hooked = true
		hook_point = pos


func _flash_rope(end: Vector3) -> void:
	_whip_flash = 0.45
	_whip_end = end


func _release_hook() -> void:
	if hooked:
		hooked = false
		velocity.y += 3.0


func _hand_pos() -> Vector3:
	if is_multiplayer_authority():
		return camera.global_position + camera.global_transform.basis * Vector3(0.3, -0.3, -0.5)
	return global_position + Vector3.UP * 1.3


func _update_rope() -> void:
	var end: Vector3 = Vector3.ZERO
	var show_rope: bool = false
	if hooked:
		end = hook_point
		show_rope = true
	elif _whip_flash > 0.0:
		end = _whip_end
		show_rope = true
	rope.visible = show_rope
	if show_rope:
		build_bolt(rope.mesh as ImmediateMesh, _hand_pos(), end, 0.0, Color(0.95, 0.85, 0.4))


# ================================================================ Vehículos (asientos)

func toggle_seat() -> void:
	if seat_sid >= 0:
		_stand_up()
		return
	var hit: Dictionary = _raycast(6.0)
	var body: RigidBody3D = _hit_prop(hit)
	if body == null or not body.has_meta("structure"):
		return
	var sid: int = int(body.get_meta("pid"))
	var bid: int = builder.find_seat(sid)
	if bid < 0:
		notify.emit("Esta estructura no tiene asiento")
		return
	seat_sid = sid
	seat_bid = bid
	_release_hook()
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	notify.emit("Conduciendo: WASD, Espacio/C inclinan, click dispara cañones, E baja")


func _stand_up() -> void:
	if seat_sid < 0:
		return
	builder.request_drive(seat_sid, 0.0, 0.0, 0.0)
	seat_sid = -1
	seat_bid = -1
	collision_layer = _layer
	collision_mask = _mask
	global_position += Vector3.UP * 1.4 - transform.basis.z * 1.2
	shock_immune = 3.0
	velocity = Vector3.ZERO


func _seated_tick(arrows: bool = false) -> void:
	var kf: int = KEY_UP if arrows else Controls.k(0)
	var kb: int = KEY_DOWN if arrows else Controls.k(1)
	var kl: int = KEY_LEFT if arrows else Controls.k(2)
	var kr: int = KEY_RIGHT if arrows else Controls.k(3)
	var body: RigidBody3D = builder.get_struct(seat_sid)
	var data: Dictionary = builder.block_data(seat_sid, seat_bid)
	if body == null or data.is_empty():
		_stand_up()
		return
	var xf: Transform3D = data["xf"]
	global_position = body.global_transform * xf.origin + Vector3.UP * 0.35
	velocity = Vector3.ZERO
	var f: float = 0.0
	var s: float = 0.0
	var v: float = 0.0
	if _key(kf): f += 1.0
	if _key(kb): f -= 1.0
	if _key(kr): s += 1.0
	if _key(kl): s -= 1.0
	if _key(Controls.k(4)): v += 1.0
	if _key(Controls.k(5)): v -= 1.0
	# Mouse: apuntar arriba sube el avión, apuntar abajo lo baja
	if not freecam:
		var aim: float = camera.rotation.x
		if absf(aim) > 0.12:
			v += clampf((aim - signf(aim) * 0.12) * 0.5, -0.4, 0.4)
	f -= touch_move.y
	s += touch_move.x
	if touch_jump:
		v += 1.0
	builder.request_drive(seat_sid, clampf(f, -1.0, 1.0), clampf(s, -1.0, 1.0), clampf(v, -1.0, 1.0))


# ================================================================ Movimiento

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_ignore_stun = freecam or seat_sid >= 0
	if freecam:
		_freecam_move(delta)
		if seat_sid >= 0:
			_seated_tick(true)
		else:
			_walk(delta, true)
		return
	# Caída al vacío: no morís, volvés al punto de inicio
	if global_position.y < -30.0:
		_release_hook()
		if seat_sid >= 0:
			_stand_up()
		velocity = Vector3.ZERO
		global_position = world._spawn_point() + Vector3.UP * 2.0
		notify.emit("Te caíste al vacío: volviste al inicio")
	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	shock_immune = maxf(0.0, shock_immune - delta)
	_armor_delay = maxf(0.0, _armor_delay - delta)
	if _armor_delay <= 0.0:
		armor = minf(100.0, armor + 8.0 * delta)
	_whip_cd = maxf(0.0, _whip_cd - delta)
	if stun_time > 0.0:
		stun_time = maxf(0.0, stun_time - delta)

	# Ground slam: en el aire, agacharse (o bajar) te tira al piso con una onda expansiva
	_slam_cd = maxf(0.0, _slam_cd - delta)
	if seat_sid < 0 and not noclip and not is_on_floor() and not _slam_active and _slam_cd <= 0.0 and (_key(Controls.k(5)) or touch_crouch or touch_slam):
		_slam_active = true
		_slam_hit = true
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y = -35.0
	if _slam_active:
		if is_on_floor():
			_slam_active = false
			_slam_cd = 0.6
			world.explode(global_position, 5.0, 28.0, self)
			notify.emit("¡Ground slam!")
		else:
			velocity.y = minf(velocity.y, -35.0)
	if seat_sid >= 0:
		_seated_tick()
	elif noclip:
		_fly(delta)
	else:
		_walk(delta)

	_update_held()
	_update_move()
	_update_ghost()
	if _firing and is_weapon():
		var idx: int = _weapon_index(item_id().substr(2))
		if bool((weapons[idx] as Dictionary).get("auto", false)) or auto_fire:
			_shoot_once()
	_update_beam()


func _push_props() -> void:
	for i in get_slide_collision_count():
		var c: KinematicCollision3D = get_slide_collision(i)
		var col := c.get_collider() as RigidBody3D
		if col != null:
			col.apply_central_impulse(-c.get_normal() * 2.0)


func _walk(delta: float, arrows: bool = false) -> void:
	var in_water: bool = global_position.y + 0.8 < water_level
	var axes: Vector3 = _move_axes(arrows)
	var wish: Vector3 = (transform.basis * Vector3(axes.x, 0.0, axes.z)).normalized()
	var speed: float = SPRINT_SPEED if _key(Controls.k(6)) else SPEED
	if touch_crouch:
		speed *= 0.5
	var jump: bool = _key(Controls.k(4)) or touch_jump
	if jump:
		_bhop_buffer = 0.15
	_bhop_buffer = maxf(0.0, _bhop_buffer - delta)

	# Gancho: te tira hacia el punto
	if hooked:
		var to: Vector3 = hook_point - (global_position + Vector3.UP)
		var dist: float = to.length()
		if dist < 2.5 or (jump and not is_on_floor()):
			_release_hook()
		else:
			velocity = velocity.lerp(to / dist * WHIP_PULL_SPEED, minf(1.0, 8.0 * delta))
			velocity += wish * 8.0 * delta
			move_and_slide()
			_push_props()
			return

	if in_water:
		speed *= 0.65
		var rise: float = -0.8
		if jump:
			rise = 3.5
		elif _key(Controls.k(5)):
			rise = -3.0
		velocity.y = move_toward(velocity.y, rise, 10.0 * delta)
	else:
		if not is_on_floor():
			velocity.y -= _gravity * gravity_scale * delta
		if _bhop_buffer > 0.0 and is_on_floor():
			velocity.y = JUMP_VELOCITY
			_bhop_buffer = 0.0
			_bhop_landed = true

	var hl: float = Vector2(velocity.x, velocity.z).length()
	if is_on_floor():
		var bhop_go: bool = (_bhop_buffer > 0.0 or _bhop_landed) and wish.length() > 0.1
		_bhop_landed = false
		if bhop_go:
			# Bunny hop: al aterrizar no frenás, y cada salto suma un poco más de velocidad (con tope)
			var goal: float = maxf(hl, minf(maxf(hl, speed) * 1.03 + 0.4, speed * 1.8))
			velocity.x = wish.x * goal
			velocity.z = wish.z * goal
		else:
			velocity.x = move_toward(velocity.x, wish.x * speed, speed * 10.0 * delta)
			velocity.z = move_toward(velocity.z, wish.z * speed, speed * 10.0 * delta)
	elif hl < speed:
		# En el aire no frenás la velocidad que traés; sólo tenés control suave
		velocity.x = move_toward(velocity.x, wish.x * speed, speed * 2.0 * delta)
		velocity.z = move_toward(velocity.z, wish.z * speed, speed * 2.0 * delta)
	var pre_vy: float = velocity.y
	move_and_slide()
	_push_props()
	_after_move(delta, pre_vy)


func _toggle_noclip() -> void:
	if seat_sid >= 0:
		return
	noclip = not noclip
	if noclip:
		_release_hook()
		collision_layer = 0
		collision_mask = 0
		velocity = Vector3.ZERO
		notify.emit("Noclip activado")
	else:
		collision_layer = _layer
		collision_mask = _mask
		notify.emit("Noclip desactivado")


func set_noclip(v: bool) -> void:
	if noclip != v:
		_toggle_noclip()


func _fly(delta: float) -> void:
	var d: Vector3 = _move_axes()
	if _key(Controls.k(4)) or touch_jump:
		d.y += 1.0
	if _key(Controls.k(5)):
		d.y -= 1.0
	if touch_crouch:
		d.y -= 1.0
	var dir: Vector3 = (camera.global_transform.basis * d).normalized()
	var speed: float = NOCLIP_SPEED * (2.0 if _key(Controls.k(6)) else 1.0)
	global_position += dir * speed * delta

## Esqueleto de caricatura al electrocutarse: huesos blancos gruesos que tiemblan
## y rayos azules en zigzag alrededor del cuerpo. Se usa para jugadores y NPCs.
static func make_zap_rig(h: float) -> Node3D:
	var root := Node3D.new()
	var s: float = h / 1.8
	# Silueta: el mismo cuerpo humano, todo negro y un poco más grande
	var sil_model: Dictionary = Humanoid.build(root, Color(0.03, 0.03, 0.06), Color(0.03, 0.03, 0.06), Color(0.03, 0.03, 0.06))
	var sil: Node3D = sil_model["root"] as Node3D
	sil.scale = Vector3.ONE * s
	# La silueta es semitransparente: los huesos (opacos) se ven completos debajo, y siguen ocultos por las paredes
	var sil_mat := StandardMaterial3D.new()
	sil_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sil_mat.albedo_color = Color(0.03, 0.03, 0.06, 0.3)
	sil_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sil_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	sil_mat.render_priority = 1
	Player._paint_meshes(sil, sil_mat)
	sil.name = "sil"
	# Esqueleto anatómico detallado (estilo láminas de anatomía)
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color(0.97, 0.97, 1.0)
	white.no_depth_test = false
	white.render_priority = 2
	var dark := StandardMaterial3D.new()
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.albedo_color = Color(0.02, 0.02, 0.03)
	dark.no_depth_test = false
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color(0.03, 0.03, 0.06)
	black.no_depth_test = false
	var J := func(pos: Vector3, r: float) -> void:
		for layer in [[r * 1.4, white]]:
			var sj := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = float(layer[0]) * s
			sph.height = float(layer[0]) * 2.0 * s
			sph.radial_segments = 6
			sph.rings = 3
			sj.mesh = sph
			sj.material_override = layer[1]
			sj.position = Vector3(-pos.x, pos.y, -pos.z) * s
			root.add_child(sj)
	var L := func(pa: Vector3, pb: Vector3, r: float) -> void:
		var fa := Vector3(-pa.x, pa.y, -pa.z) * s
		var fb := Vector3(-pb.x, pb.y, -pb.z) * s
		root.add_child(Player._seg(fa, fb, r * s * 1.5, white))
	# Cráneo: bóveda, cuencas de los ojos, mandíbula
	J.call(Vector3(0, 1.65, -0.01), 0.1)
	L.call(Vector3(-0.07, 1.6, 0.06), Vector3(0.07, 1.6, 0.06), 0.025)
	for sd in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.028 * s
		es.height = 0.056 * s
		es.radial_segments = 6
		es.rings = 3
		eye.mesh = es
		eye.material_override = dark
		eye.position = Vector3(-sd * 0.04, 1.66, -0.085) * s
		root.add_child(eye)
	L.call(Vector3(-0.05, 1.53, 0.07), Vector3(0.05, 1.53, 0.07), 0.018)
	L.call(Vector3(0, 1.56, 0.09), Vector3(0, 1.5, 0.09), 0.012)
	L.call(Vector3(-0.05, 1.55, 0.02), Vector3(-0.05, 1.5, 0.07), 0.012)
	L.call(Vector3(0.05, 1.55, 0.02), Vector3(0.05, 1.5, 0.07), 0.012)
	# Columna: 7 vértebras cervicales + dorsales + lumbares, en línea
	for i in 14:
		var vy: float = 1.52 - float(i) * 0.045
		J.call(Vector3(0, vy, -0.03), 0.02)
	for i in 13:
		var vy2: float = 1.52 - float(i) * 0.045
		L.call(Vector3(0, vy2, -0.03), Vector3(0, vy2 - 0.045, -0.03), 0.012)
	# Costillas: 7 pares curvos, de la columna al esternón
	for i in 7:
		var ry: float = 1.36 - float(i) * 0.05
		var wide: float = 0.21 - float(i) * 0.01
		for sd in [-1.0, 1.0]:
			var sp := Vector3(0, ry, -0.03)
			var p1 := Vector3(sd * wide, ry - 0.03, 0.0)
			var p2 := Vector3(sd * (wide * 0.8), ry - 0.07, 0.09)
			var sterno := Vector3(sd * 0.02, ry - 0.08, 0.12)
			L.call(sp, p1, 0.011)
			L.call(p1, p2, 0.011)
			if i < 5:
				L.call(p2, sterno, 0.01)
	# Esternón
	L.call(Vector3(0, 1.36, 0.12), Vector3(0, 1.0, 0.12), 0.022)
	for i in 3:
		J.call(Vector3(0, 1.3 - float(i) * 0.12, 0.12), 0.02)
	# Hombros, clavículas, escápulas
	for sd in [-1.0, 1.0]:
		L.call(Vector3(sd * 0.03, 1.43, 0.05), Vector3(sd * 0.2, 1.4, 0.02), 0.014)
		L.call(Vector3(sd * 0.2, 1.4, 0.02), Vector3(sd * 0.14, 1.3, -0.06), 0.01)
		J.call(Vector3(sd * 0.2, 1.39, 0.02), 0.035)
		# Brazo abajo: húmero, codo, radio y cúbito, muñeca, mano
		L.call(Vector3(sd * 0.2, 1.39, 0.02), Vector3(sd * 0.27, 1.1, 0.0), 0.021)
		J.call(Vector3(sd * 0.27, 1.1, 0.0), 0.027)
		L.call(Vector3(sd * 0.27, 1.1, 0.0), Vector3(sd * 0.32, 0.88, 0.02), 0.014)
		L.call(Vector3(sd * 0.29, 1.1, 0.0), Vector3(sd * 0.34, 0.87, 0.02), 0.012)
		J.call(Vector3(sd * 0.32, 0.87, 0.02), 0.02)
		for f in 4:
			var fx: float = sd * (0.33 + float(f) * 0.02)
			L.call(Vector3(sd * 0.32, 0.86, 0.02), Vector3(fx, 0.76 - float(f) * 0.01, 0.03), 0.008)
			L.call(Vector3(fx, 0.76 - float(f) * 0.01, 0.03), Vector3(fx + sd * 0.005, 0.7 - float(f) * 0.01, 0.04), 0.007)
		L.call(Vector3(sd * 0.31, 0.86, 0.02), Vector3(sd * 0.33, 0.7, 0.04), 0.008)
	# Pelvis: sacro y alas ilíacas
	for i in 4:
		J.call(Vector3(0, 0.98 - float(i) * 0.03, -0.03), 0.02)
	for sd in [-1.0, 1.0]:
		L.call(Vector3(0, 0.98, -0.03), Vector3(sd * 0.16, 1.02, 0.03), 0.02)
		L.call(Vector3(sd * 0.16, 1.02, 0.03), Vector3(sd * 0.12, 0.88, 0.1), 0.022)
		L.call(Vector3(sd * 0.12, 0.88, 0.1), Vector3(0, 0.8, 0.12), 0.018)
		J.call(Vector3(sd * 0.11, 0.9, 0.0), 0.04)
	# Piernas: fémur, rótula, tibia, peroné, tobillo, pie
	for sd in [-1.0, 1.0]:
		L.call(Vector3(sd * 0.11, 0.9, 0.0), Vector3(sd * 0.12, 0.5, 0.0), 0.032)
		J.call(Vector3(sd * 0.12, 0.5, 0.0), 0.035)
		var pat := MeshInstance3D.new()
		var ps := SphereMesh.new()
		ps.radius = 0.035 * s
		ps.height = 0.05 * s
		ps.radial_segments = 6
		ps.rings = 3
		pat.mesh = ps
		pat.material_override = white
		pat.position = Vector3(-sd * 0.12, 0.48, -0.035) * s
		root.add_child(pat)
		L.call(Vector3(sd * 0.12, 0.47, 0.0), Vector3(sd * 0.12, 0.08, 0.0), 0.022)
		L.call(Vector3(sd * 0.15, 0.46, -0.01), Vector3(sd * 0.13, 0.1, -0.01), 0.011)
		J.call(Vector3(sd * 0.12, 0.07, 0.0), 0.024)
		for t in 3:
			var tx: float = sd * (0.1 + float(t) * 0.02)
			L.call(Vector3(sd * 0.12, 0.05, 0.02), Vector3(tx, 0.02, 0.12 + float(t) * 0.01), 0.009)
		L.call(Vector3(sd * 0.12, 0.05, 0.02), Vector3(sd * 0.2, 0.02, 0.1), 0.01)
	var aura := MeshInstance3D.new()
	aura.mesh = _splash_mesh(s)
	var amat := StandardMaterial3D.new()
	amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	amat.albedo_color = Color(0.0, 0.65, 0.92, 0.8)
	amat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	amat.cull_mode = BaseMaterial3D.CULL_DISABLED
	amat.render_priority = -1
	aura.material_override = amat
	aura.position = Vector3(0, 0.9 * s, 0)
	aura.name = "aura"
	root.set_meta("s", s)
	root.add_child(aura)
	var bolts := MeshInstance3D.new()
	bolts.name = "bolts"
	bolts.mesh = ImmediateMesh.new()
	var bm2 := StandardMaterial3D.new()
	bm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm2.albedo_color = Color(1.0, 1.0, 0.35)
	bm2.no_depth_test = true
	bolts.material_override = bm2
	bolts.top_level = true
	root.add_child(bolts)
	root.set_meta("scale", s)
	# Si hay un modelo de esqueleto en el proyecto (res://skeleton.glb), se usa en lugar de los huesos armados
	if ResourceLoader.exists("res://skeleton.glb"):
		var scene := load("res://skeleton.glb") as PackedScene
		if scene != null:
			var inst := scene.instantiate() as Node3D
			var wm := StandardMaterial3D.new()
			wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			wm.albedo_color = Color(0.97, 0.97, 1.0)
			wm.no_depth_test = false
			Player._paint_meshes(inst, wm)
			inst.scale = Vector3.ONE * s
			for child in root.get_children():
				if not (str(child.name) in ["sil", "bolts", "aura"]):
					(child as Node3D).visible = false
			root.add_child(inst)
	return root


## Pinta todas las mallas de un modelo con el mismo material.
static func _paint_meshes(n: Node, m: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = m
	for c in n.get_children():
		_paint_meshes(c, m)


## Hueso como cilindro entre dos puntos.
static func _seg(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.radial_segments = 6
	cm.rings = 1
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = maxf(a.distance_to(b), 0.001)
	cm.radial_segments = 6
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	var dir: Vector3 = (b - a).normalized()
	mi.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), (a + b) * 0.5)
	return mi


## Se llama en cada frame mientras dura la descarga: tiembla y redibuja los rayos.
static func update_zap(root: Node3D) -> void:
	var s: float = float(root.get_meta("scale", 1.0))
	if root.has_node("aura"):
		# Chispa de estilo cómic: la forma de salpicadura cambia cada frame
		(root.get_node("aura") as MeshInstance3D).mesh = _splash_mesh(float(root.get_meta("s", 1.0)))
	var im := (root.get_node("bolts") as MeshInstance3D).mesh as ImmediateMesh
	im.clear_surfaces()
	var parent_xf: Transform3D = root.global_transform
	for k in 5:
		var a: Vector3 = Vector3(randf_range(-0.4, 0.4), randf_range(0.2, 1.7), randf_range(-0.3, 0.3)) * s
		var b: Vector3 = Vector3(randf_range(-0.5, 0.5), randf_range(0.2, 1.7), randf_range(-0.4, 0.4)) * s
		a = parent_xf * a
		b = parent_xf * b
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		im.surface_set_color(Color(1.0, 1.0, 0.35))
		for i in 10:
			var t: float = float(i) / 9.0
			var pt: Vector3 = a.lerp(b, t)
			if i > 0 and i < 9:
				pt += Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 0.12 * s
			im.surface_add_vertex(pt)
		im.surface_end()


## Freecam: la cámara se separa del cuerpo y vuela libre (K la apaga).
func toggle_freecam() -> void:
	freecam = not freecam
	if freecam:
		if seat_sid < 0:
			_release_hook()
			release()
		_free_pos = camera.global_position
		camera.top_level = true
		camera.global_position = _free_pos
		notify.emit("Freecam: WASD mueve la cámara, flechas mueven a tu personaje")
	else:
		camera.top_level = false
		camera.position = Vector3(0, 1.6, 0)
		camera.rotation = Vector3.ZERO
		notify.emit("Freecam apagada")


func _freecam_move(delta: float) -> void:
	var d: Vector3 = _move_axes()
	if _key(Controls.k(4)):
		d.y += 1.0
	if _key(Controls.k(5)):
		d.y -= 1.0
	var dir: Vector3 = camera.global_transform.basis * d
	var speed: float = 14.0 * (3.0 if _key(Controls.k(6)) else 1.0)
	_free_pos += dir.normalized() * speed * delta
	camera.global_position = _free_pos


## Muestra el arma equipada: en primera persona (cámara) y en la mano del cuerpo.
func _sync_gun() -> void:
	var nm: String = item_id().substr(2) if is_weapon() else ""
	if item_id() == "physgun":
		nm = "Physgun"
	if nm == _gun_name:
		return
	_gun_name = nm
	if _gun_view != null:
		_gun_view.queue_free()
		_gun_view = null
	if _gun_body != null:
		_gun_body.queue_free()
		_gun_body = null
	if nm == "":
		return
	_gun_view = WeaponModels.build(nm)
	camera.add_child(_gun_view)
	_gun_view.position = Vector3(0.28, -0.26, -0.55)
	_gun_view.rotation.y = PI
	_gun_view.scale = Vector3.ONE * 0.8
	_gun_view.visible = is_multiplayer_authority()
	if _model_root != null:
		var arms: Array = _model_root.get_meta("arms", [])
		if arms.size() >= 2:
			_gun_body = WeaponModels.build(nm)
			(arms[1] as Node3D).add_child(_gun_body)
			_gun_body.position = Vector3(0.06, -0.55, 0.1)


## Destello en la punta del arma: un brillo corto y una luz que se apaga enseguida.
func _muzzle_flash(col: Color) -> void:
	_recoil = 1.0
	for host in [_gun_view, _gun_body]:
		if host == null or not is_instance_valid(host):
			continue
		var f := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.08
		sm.height = 0.16
		f.mesh = sm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = col
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 4.0
		f.material_override = m
		f.position = Vector3(0, 0, 0.45)
		host.add_child(f)
		var lt := OmniLight3D.new()
		lt.light_color = col
		lt.light_energy = 3.0
		lt.omni_range = 5.0
		lt.position = Vector3(0, 0, 0.45)
		host.add_child(lt)
		get_tree().create_timer(0.05).timeout.connect(func() -> void:
			if is_instance_valid(f):
				f.queue_free()
			if is_instance_valid(lt):
				lt.queue_free())


## Forma de salpicadura azul (con picos irregulares) para el aura eléctrica.
static func _splash_mesh(s: float) -> ImmediateMesh:
	var im := ImmediateMesh.new()
	var n: int = 14
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var a0: float = TAU * float(i) / float(n)
		var a1: float = TAU * float(i + 1) / float(n)
		var r0: float = (1.0 if i % 2 == 0 else 0.6) * s * randf_range(0.9, 1.1)
		var r1: float = (1.0 if (i + 1) % 2 == 0 else 0.6) * s * randf_range(0.9, 1.1)
		im.surface_add_vertex(Vector3.ZERO)
		im.surface_add_vertex(Vector3(cos(a0) * r0, sin(a0) * r0, 0.0))
		im.surface_add_vertex(Vector3(cos(a1) * r1, sin(a1) * r1, 0.0))
	im.surface_end()
	return im


## Animación del arma en primera persona: retroceso al disparar y balanceo al caminar.
func _animate_gun(delta: float) -> void:
	_recoil = maxf(0.0, _recoil - delta * 9.0)
	if _gun_view == null or not is_instance_valid(_gun_view):
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var moving: float = clampf(Vector2(velocity.x, velocity.z).length() / 6.0, 0.0, 1.0)
	var bob: Vector3 = Vector3(sin(t * 7.0) * 0.012, absf(sin(t * 7.0)) * 0.012, 0.0) * moving
	_gun_view.position = Vector3(0.28, -0.26, -0.55) + bob + Vector3(0.0, 0.0, _recoil * 0.14)
	_gun_view.rotation = Vector3(_recoil * 0.3, PI, 0.0)


## Daño por caída (solo desde cierta altura) y por ser aplastado por objetos pesados que caen o se mueven rápido.
func _after_move(delta: float, pre_vy: float) -> void:
	_crush_cd = maxf(0.0, _crush_cd - delta)
	if _pull.length() > 0.01:
		# Solo empuje horizontal y con tope: nunca hacia arriba
		var hp: Vector3 = Vector3(_pull.x, 0.0, _pull.z)
		velocity += hp * delta * 12.0
		var hv: Vector3 = Vector3(velocity.x, 0.0, velocity.z).limit_length(8.0)
		velocity.x = hv.x
		velocity.z = hv.z
		_pull = _pull.lerp(Vector3.ZERO, minf(1.0, delta * 8.0))
	if is_on_floor():
		if not _was_floor and _fall_v < -12.0 and not _slam_hit:
			receive_hit(clampf((-_fall_v - 12.0) * 3.0, 0.0, 80.0))
		_slam_hit = false
		_fall_v = 0.0
	elif pre_vy < 0.0:
		_fall_v = minf(_fall_v, pre_vy)
	_was_floor = is_on_floor()
	if _crush_cd <= 0.0:
		for i in get_slide_collision_count():
			var rb := get_slide_collision(i).get_collider() as RigidBody3D
			if rb != null:
				var s: float = rb.linear_velocity.length()
				if s > 6.0:
					receive_hit(clampf(s * 2.0, 0.0, 40.0))
					_crush_cd = 0.4
					break

