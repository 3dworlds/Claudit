class_name Player
extends CharacterBody3D
## Jugador en primera persona: caminar, noclip, knockback y herramientas.

signal tool_changed(index: int)
signal notify(msg: String)

const SPEED := 6.0
const SPRINT_SPEED := 10.0
const JUMP_VELOCITY := 5.5
const NOCLIP_SPEED := 14.0
const MOUSE_SENS := 0.003
const TOOLS := ["Physgun", "Borrador", "Empuje", "Explosión", "Clonar", "Pintor"]

var world: Node = null
var camera: Camera3D
var held_body: RigidBody3D = null
var hold_distance: float = 4.0
var tool_index: int = 0
var noclip: bool = false
var gravity_scale: float = 1.0
var shake: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _layer: int = 1
var _mask: int = 1


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	camera = Camera3D.new()
	camera.position.y = 1.6
	add_child(camera)
	camera.make_current()

	_layer = collision_layer
	_mask = collision_mask


func _is_active() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func _key(k: Key) -> bool:
	return _is_active() and Input.is_physical_key_pressed(k)


func _move_axes() -> Vector3:
	var d := Vector3.ZERO
	if _key(KEY_W): d.z -= 1.0
	if _key(KEY_S): d.z += 1.0
	if _key(KEY_A): d.x -= 1.0
	if _key(KEY_D): d.x += 1.0
	return d


func _process(delta: float) -> void:
	# Screenshake (lo dispara la explosión)
	if shake > 0.0:
		camera.h_offset = randf_range(-1.0, 1.0) * shake * 0.1
		camera.v_offset = randf_range(-1.0, 1.0) * shake * 0.1
		shake = maxf(0.0, shake - delta * 2.0)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func add_shake(amount: float) -> void:
	shake = minf(shake + amount, 2.0)


func knockback(v: Vector3) -> void:
	if not noclip:
		velocity += v


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active():
		return

	if event is InputEventMouseMotion:
		var m := event as InputEventMouseMotion
		rotate_y(-m.relative.x * MOUSE_SENS)
		camera.rotation.x = clampf(camera.rotation.x - m.relative.y * MOUSE_SENS, -1.5, 1.5)

	elif event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_LEFT:
			if b.pressed:
				_use_tool()
			else:
				release()
		elif b.button_index == MOUSE_BUTTON_RIGHT and b.pressed:
			_freeze_held()
		elif b.pressed and (b.button_index == MOUSE_BUTTON_WHEEL_UP or b.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var up: bool = b.button_index == MOUSE_BUTTON_WHEEL_UP
			if is_instance_valid(held_body):
				hold_distance = clampf(hold_distance + (0.5 if up else -0.5), 1.5, 30.0)
			else:
				_set_tool(wrapi(tool_index + (-1 if up else 1), 0, TOOLS.size()))

	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_N:
				_toggle_noclip()
			elif k.keycode >= KEY_1 and k.keycode <= KEY_6:
				_set_tool(k.keycode - KEY_1)


func _toggle_noclip() -> void:
	noclip = not noclip
	if noclip:
		collision_layer = 0
		collision_mask = 0
		velocity = Vector3.ZERO
		notify.emit("Noclip activado")
	else:
		collision_layer = _layer
		collision_mask = _mask
		notify.emit("Noclip desactivado")


func _physics_process(delta: float) -> void:
	if noclip:
		_fly(delta)
	else:
		_walk(delta)
	_update_held()


func _walk(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * gravity_scale * delta

	var axes: Vector3 = _move_axes()
	var wish: Vector3 = (transform.basis * Vector3(axes.x, 0.0, axes.z)).normalized()
	var speed: float = SPRINT_SPEED if _key(KEY_SHIFT) else SPEED

	if _key(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	velocity.x = move_toward(velocity.x, wish.x * speed, speed * 10.0 * delta)
	velocity.z = move_toward(velocity.z, wish.z * speed, speed * 10.0 * delta)
	move_and_slide()

	# Empujar objetos al chocar con ellos
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider() as RigidBody3D
		if col != null:
			col.apply_central_impulse(-c.get_normal() * 2.0)


func _fly(delta: float) -> void:
	var d: Vector3 = _move_axes()
	if _key(KEY_SPACE): d.y += 1.0
	if _key(KEY_C): d.y -= 1.0
	var dir: Vector3 = (camera.global_transform.basis * d).normalized()
	var speed: float = NOCLIP_SPEED * (2.0 if _key(KEY_SHIFT) else 1.0)
	global_position += dir * speed * delta


func _update_held() -> void:
	if not is_instance_valid(held_body):
		held_body = null
		return
	var target: Vector3 = camera.global_position - camera.global_transform.basis.z * hold_distance
	held_body.linear_velocity = (target - held_body.global_position) * 12.0
	held_body.angular_velocity *= 0.9


func _raycast(dist: float = 100.0) -> Dictionary:
	var from: Vector3 = camera.global_position
	var to: Vector3 = from - camera.global_transform.basis.z * dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)


func _use_tool() -> void:
	var hit: Dictionary = _raycast()
	var has_hit: bool = not hit.is_empty()
	var pos: Vector3 = hit.get("position", Vector3.ZERO) if has_hit else camera.global_position - camera.global_transform.basis.z * 30.0

	var body: RigidBody3D = null
	if has_hit:
		body = hit.get("collider") as RigidBody3D

	# La explosión funciona aunque no apuntes a nada
	if not has_hit and tool_index != 3:
		return

	match tool_index:
		0: # Physgun
			if body != null:
				held_body = body
				body.freeze = false
				hold_distance = camera.global_position.distance_to(pos)
		1: # Borrador
			if body != null:
				world.remove_prop(body)
		2: # Empuje
			if body != null:
				var impulse: Vector3 = -camera.global_transform.basis.z * 12.0 * body.mass
				body.apply_impulse(impulse, pos - body.global_position)
		3: # Explosión
			world.explode(pos, 6.0, 40.0)
		4: # Clonar
			if body != null:
				world.clone_prop(body)
		5: # Pintor
			if body != null:
				world.paint_prop(body)


func _freeze_held() -> void:
	if is_instance_valid(held_body):
		held_body.linear_velocity = Vector3.ZERO
		held_body.angular_velocity = Vector3.ZERO
		held_body.freeze = true
	release()


func release() -> void:
	held_body = null


func _set_tool(i: int) -> void:
	release()
	tool_index = i
	tool_changed.emit(i)
