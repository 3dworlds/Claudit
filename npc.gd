class_name NPC
extends CharacterBody3D
## NPC. El host simula la IA; en los clientes es un "puppet" que sigue la posición enviada por el host.

const KINDS := {
	"Vagabundo": {"hp": 60.0, "speed": 2.0, "mode": "wander", "color": "7fbf7f", "size": 1.0},
	"Zombi": {"hp": 80.0, "speed": 3.4, "mode": "chase", "dmg": 10.0, "color": "6b8e4e", "size": 1.0},
	"Soldado": {"hp": 100.0, "speed": 2.6, "mode": "shoot", "dmg": 8.0, "color": "8a7a5a", "size": 1.0},
	"Gigante": {"hp": 400.0, "speed": 2.2, "mode": "chase", "dmg": 25.0, "color": "a05050", "size": 1.8},
}

var world: Node = null
var nid: int = 0
var kind: String = "Vagabundo"
var puppet: bool = false
var hp: float = 60.0
var max_hp: float = 60.0
var stun_time: float = 0.0
var _zap_until: int = 0
var net_pos: Vector3 = Vector3.ZERO
var net_yaw: float = 0.0
var net_hp: float = 60.0

var _label: Label3D
var _wander_dir: Vector3 = Vector3.ZERO
var _wander_t: float = 0.0
var _atk_cd: float = 0.0
var _last_text: String = ""
var _bones: Node3D = null
var _model_root: Node3D = null
var _anim_last: Vector3 = Vector3.ZERO
var _anim_speed: float = 0.0


func _process(delta: float) -> void:
	_anim_speed = (global_position - _anim_last).length() / maxf(delta, 0.001)
	_anim_last = global_position
	if _model_root != null:
		Humanoid.animate(_model_root, Time.get_ticks_msec() / 1000.0, _anim_speed, not is_on_floor(), stun_time > 0.0, false, delta)


func _ready() -> void:
	add_to_group("npcs")
	var cfg: Dictionary = KINDS[kind]
	var m: float = float(cfg["size"])
	max_hp = float(cfg["hp"])
	hp = max_hp
	net_hp = max_hp
	net_pos = position

	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4 * m
	cap.height = 1.8 * m
	shape.shape = cap
	shape.position.y = 0.9 * m
	add_child(shape)

	var color: Color = Color.html("#" + str(cfg["color"]))
	var model: Dictionary = Humanoid.build(self, color)
	(model["root"] as Node3D).scale = Vector3.ONE * m
	_model_root = model["root"] as Node3D

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.008
	_label.font_size = 48
	_label.outline_size = 12
	_label.no_depth_test = true
	_label.position.y = 2.3 * m
	add_child(_label)
	_refresh_label()


func _refresh_label() -> void:
	# Histéresis: la descarga se mantiene visible 250 ms después de la última señal de stun (evita parpadeo)
	if stun_time > 0.0:
		_zap_until = Time.get_ticks_msec() + 250
	var zapped: bool = Time.get_ticks_msec() < _zap_until
	if zapped and _bones == null:
		_bones = Player.make_zap_rig(1.8 * float(KINDS[kind]["size"]))
		add_child(_bones)
	if _bones != null:
		_bones.visible = zapped
		if zapped:
			Player.update_zap(_bones)
	if _model_root != null:
		_model_root.visible = not zapped
	var text: String = "%s  %d" % [kind, int(ceil(net_hp if puppet else hp))]
	if stun_time > 0.0:
		text += "  ⚡"
	if text != _last_text:
		_last_text = text
		_label.text = text


func take_damage(dmg: float, knock: Vector3) -> void:
	if puppet or world.god_npcs:
		return
	hp -= dmg
	Sfx.play("hurt")
	velocity += knock.limit_length(25.0)
	if hp <= 0.0:
		world.npcs.kill(nid)


func stun(sec: float) -> void:
	if puppet:
		return
	stun_time = maxf(stun_time, sec)


func _has_line(target: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.6, target.global_position + Vector3.UP * 1.2)
	q.exclude = [get_rid()]
	var res: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return res.is_empty() or res.get("collider") == target


func _physics_process(delta: float) -> void:
	if puppet:
		global_position = global_position.lerp(net_pos, minf(1.0, 14.0 * delta))
		rotation.y = lerp_angle(rotation.y, net_yaw, minf(1.0, 12.0 * delta))
		_refresh_label()
		return

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	if global_position.y < -80.0:
		world.npcs.kill(nid)
		return

	var cfg: Dictionary = KINDS[kind]
	var m: float = float(cfg["size"])
	var speed: float = float(cfg["speed"])
	var want := Vector3.ZERO
	var face := Vector3.ZERO

	if stun_time > 0.0:
		stun_time -= delta
	else:
		_atk_cd = maxf(0.0, _atk_cd - delta)
		var target: Node3D = world.npcs.nearest_player(global_position, 30.0)
		match str(cfg["mode"]):
			"wander":
				_wander_t -= delta
				if _wander_t <= 0.0:
					_wander_t = randf_range(1.5, 4.0)
					var a: float = randf() * TAU
					_wander_dir = Vector3(cos(a), 0.0, sin(a)) if randf() < 0.7 else Vector3.ZERO
				want = _wander_dir
				face = _wander_dir
			"chase":
				if target != null:
					var to: Vector3 = target.global_position - global_position
					to.y = 0.0
					var dist: float = to.length()
					if dist > 0.01:
						face = to / dist
					if dist > 1.5 * m:
						want = face
					elif _atk_cd <= 0.0:
						_atk_cd = 1.0
						world.npc_melee(self, target, float(cfg["dmg"]))
			"shoot":
				if target != null:
					var to2: Vector3 = target.global_position - global_position
					to2.y = 0.0
					var dist2: float = to2.length()
					if dist2 > 0.01:
						face = to2 / dist2
					if dist2 > 14.0:
						want = face
					elif dist2 < 7.0:
						want = -face
					if dist2 < 28.0 and _atk_cd <= 0.0 and _has_line(target):
						_atk_cd = 1.2
						world.npc_shoot(self, target, float(cfg["dmg"]))

	if face.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-face.x, -face.z), minf(1.0, 8.0 * delta))

	velocity.x = move_toward(velocity.x, want.x * speed, speed * 8.0 * delta)
	velocity.z = move_toward(velocity.z, want.z * speed, speed * 8.0 * delta)
	move_and_slide()

	for i in get_slide_collision_count():
		var c: KinematicCollision3D = get_slide_collision(i)
		var rb := c.get_collider() as RigidBody3D
		if rb != null:
			rb.apply_central_impulse(-c.get_normal() * 1.5 * m)

	_refresh_label()
