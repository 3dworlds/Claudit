class_name ItemIcon
extends Control
## Icono dibujado por código: cubo (bloques y objetos), esfera, arma (silueta) o herramienta (llave).

var kind: String = "cube"
var col: Color = Color.WHITE


func _init(k: String = "cube", c: Color = Color.WHITE) -> void:
	kind = k
	col = c
	custom_minimum_size = Vector2(30, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c: Vector2 = size / 2.0
	var s: float = minf(size.x, size.y) * 0.3
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35), true)
	match kind:
		"cube":
			_cube(c, s)
		"sphere":
			draw_circle(c, s, col.darkened(0.25))
			draw_circle(c + Vector2(-s * 0.3, -s * 0.3), s * 0.3, col.lightened(0.45))
		"gun":
			draw_rect(Rect2(c + Vector2(-s * 1.1, -s * 0.35), Vector2(s * 1.9, s * 0.55)), col, true)
			draw_rect(Rect2(c + Vector2(-s * 0.25, s * 0.2), Vector2(s * 0.5, s * 0.9)), col.darkened(0.35), true)
		"tool":
			draw_line(c + Vector2(-s, s), c + Vector2(s * 0.3, -s * 0.3), col, 4.0, true)
			draw_arc(c + Vector2(s * 0.4, -s * 0.4), s * 0.5, 0.0, TAU, 16, col, 3.0, true)
		_:
			draw_rect(Rect2(c - Vector2(s, s), Vector2(s * 2.0, s * 2.0)), col, true)


func _cube(c: Vector2, s: float) -> void:
	var top := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, -s * 0.5), c + Vector2(0, 0), c + Vector2(-s, -s * 0.5)])
	var left := PackedVector2Array([c + Vector2(-s, -s * 0.5), c + Vector2(0, 0), c + Vector2(0, s), c + Vector2(-s, s * 0.5)])
	var right := PackedVector2Array([c + Vector2(0, 0), c + Vector2(s, -s * 0.5), c + Vector2(s, s * 0.5), c + Vector2(0, s)])
	draw_colored_polygon(top, col.lightened(0.25))
	draw_colored_polygon(left, col)
	draw_colored_polygon(right, col.darkened(0.25))
