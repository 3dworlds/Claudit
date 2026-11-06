class_name TouchControls
extends Control
## Controles táctiles: joystick izquierdo fijo, mirar arrastrando a la derecha,
## botones de acción y botón MENÚ (lobby) arriba a la izquierda.

var enabled: bool = false
var blocked: bool = false
var move: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var jump_held: bool = false
var fire_held: bool = false

var _pending: Dictionary = {}
var _touch_btn: Dictionary = {}
var _stick_idx: int = -1
var _look_idx: int = -1

const STICK_RADIUS := 85.0
const LABELS := {
	"fire": "DISPARAR",
	"jump": "SALTAR",
	"freeze": "CONGELAR",
	"cycle": "ARMA",
	"menu": "OBJETOS",
	"lobby": "MENÚ",
}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _stick_center() -> Vector2:
	return Vector2(size.x * 0.14, size.y - 170.0)


func _button_layout() -> Dictionary:
	var s: Vector2 = size
	return {
		"lobby": [Vector2(60.0, 200.0), 36.0],
		"menu": [Vector2(s.x - 60.0, 60.0), 40.0],
		"fire": [Vector2(s.x - 130.0, s.y - 130.0), 72.0],
		"jump": [Vector2(s.x - 290.0, s.y - 110.0), 52.0],
		"freeze": [Vector2(s.x - 290.0, s.y - 240.0), 44.0],
		"cycle": [Vector2(s.x - 130.0, s.y - 270.0), 44.0],
	}


func _button_at(p: Vector2) -> String:
	var lay: Dictionary = _button_layout()
	for key in lay:
		var entry: Array = lay[key]
		var c: Vector2 = entry[0]
		var r: float = entry[1]
		if p.distance_to(c) <= r:
			return key
	return ""


func _process(_delta: float) -> void:
	if not enabled:
		return
	if blocked:
		# Con un menú abierto no hay movimiento ni disparo
		move = Vector2.ZERO
		jump_held = false
		fire_held = false
	queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	var font: Font = ThemeDB.fallback_font

	# Joystick
	var sc: Vector2 = _stick_center()
	draw_circle(sc, STICK_RADIUS, Color(1, 1, 1, 0.12))
	draw_arc(sc, STICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 2.0)
	draw_circle(sc + move * STICK_RADIUS, 30.0, Color(1, 1, 1, 0.45))

	# Botones
	var lay: Dictionary = _button_layout()
	for key in lay:
		var entry: Array = lay[key]
		var c: Vector2 = entry[0]
		var r: float = entry[1]
		var active: bool = (key == "fire" and fire_held) or (key == "jump" and jump_held)
		draw_circle(c, r, Color(1, 1, 1, 0.45 if active else 0.2))
		draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
		draw_string(font, c + Vector2(-r, 6.0), LABELS[key], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 13, Color(1, 1, 1, 0.9))


func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_press(t.index, t.position)
		else:
			_lift(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_drag(d.index, d.position, d.relative)


func _press(idx: int, p: Vector2) -> void:
	var b: String = _button_at(p)
	if blocked and b != "lobby":
		return
	if b != "":
		_touch_btn[idx] = b
		if b == "fire":
			fire_held = true
			_pending["fire"] = true
		elif b == "jump":
			jump_held = true
		else:
			_pending[b] = true
		return
	if blocked:
		return
	if _stick_idx == -1 and p.x < size.x * 0.45:
		_stick_idx = idx
		move = ((p - _stick_center()) / STICK_RADIUS).limit_length(1.0)
	elif _look_idx == -1:
		_look_idx = idx


func _lift(idx: int) -> void:
	if _touch_btn.has(idx):
		var b: String = _touch_btn[idx]
		_touch_btn.erase(idx)
		if b == "fire":
			fire_held = false
			_pending["release"] = true
		elif b == "jump":
			jump_held = false
	if idx == _stick_idx:
		_stick_idx = -1
		move = Vector2.ZERO
	if idx == _look_idx:
		_look_idx = -1


func _drag(idx: int, p: Vector2, rel: Vector2) -> void:
	if idx == _stick_idx:
		move = ((p - _stick_center()) / STICK_RADIUS).limit_length(1.0)
	elif idx == _look_idx:
		look_delta += rel


func consume(action: String) -> bool:
	if _pending.has(action):
		_pending.erase(action)
		return true
	return false


func clear_pending() -> void:
	_pending.clear()
