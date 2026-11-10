class_name TouchUI
extends CanvasLayer
## Controles de celular con la distribución del dibujo.
## Personalizables con "Más → Editar controles": arrastrar, cambiar tamaño,
## color y transparencia. Se guardan en user://touch_layout.json.
##
## Multitouch: se pueden apretar varios botones a la vez.

signal action(action_name: String)

const PATH := "user://touch_layout.json"
const STICK_BASE := 180.0

## Paletas de colores disponibles (fill, line, text, press). Alpha se elige aparte.
const PALETTES := {
	"Cian": {"fill": "1a2a33", "line": "ffffff", "text": "ffffff", "press": "40d8f2"},
	"Rojo": {"fill": "331a1a", "line": "ffffff", "text": "ffffff", "press": "ff5555"},
	"Verde": {"fill": "1a331f", "line": "ffffff", "text": "ffffff", "press": "66ff88"},
	"Amarillo": {"fill": "332f1a", "line": "ffffff", "text": "ffffff", "press": "ffe066"},
	"Violeta": {"fill": "2a1a33", "line": "ffffff", "text": "ffffff", "press": "bb88ff"},
}
const ALPHAS := [0.3, 0.6, 0.9]

## Botones por defecto, según el dibujo.
## [etiqueta, forma, nombre, tamaño base, lado horizontal, lado vertical, desplazamiento x, y]
## Lado horizontal: L (izquierda), R (derecha), C (centro). Vertical: T (arriba), B (abajo).
const DEFS := [
	["pausa", "circle", "Pausa", Vector2(100, 100), "L", "T", 10, 10],
	["item+", "up", "Ítem +", Vector2(118, 62), "L", "T", 5, 150],
	["item-", "down", "Ítem -", Vector2(118, 62), "L", "T", 5, 235],
	["noclip", "circle", "Noclip", Vector2(128, 128), "L", "T", 6, 426],
	["saltar", "circle", "Saltar", Vector2(126, 126), "L", "B", 3, 6],
	["objetos", "circle", "Objetos", Vector2(104, 104), "R", "T", 176, 0],
	["items", "circle", "Ítems", Vector2(110, 110), "R", "T", 3, 6],
	["gancho", "circle", "Gancho", Vector2(96, 96), "R", "T", 200, 400],
	["usar", "circle", "Usar", Vector2(156, 156), "R", "T", 180, 218],
	["disparar", "circle", "Click izq.", Vector2(140, 140), "R", "T", 21, 180],
	["derecho", "circle", "Click der.", Vector2(96, 96), "R", "B", 110, 0],
	["agachar", "circle", "Ground slam", Vector2(100, 100), "R", "B", 2, 0],
	["armas", "up", "Ver armas", Vector2(184, 56), "C", "B", -92, 6],
	["mas", "circle", "Más", Vector2(96, 96), "C", "T", -48, 16],
]
const STICK_DEF := {"h": "L", "v": "B", "ox": 230.0, "oy": 30.0, "k": 1.0}


## Botón redondo o triangular con su texto. Se dibuja con los colores de TouchUI.
class Btn extends Control:
	var ui: TouchUI
	var shape: String = "circle"
	var label: String = ""
	var tag: String = ""
	var down: bool = false
	var sel: bool = false

	func _init(u: TouchUI, s: String, t: String, g: String) -> void:
		ui = u
		shape = s
		label = t
		tag = g
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var sz: Vector2 = size
		var c: Vector2 = sz / 2.0
		var r: float = minf(sz.x, sz.y) / 2.0 - 3.0
		var fill: Color = ui.col("press") if down else ui.col("fill")
		var line: Color = Color(1.0, 0.9, 0.2) if sel else ui.col("line")
		var fs: int = maxi(14, int(minf(sz.x, sz.y) * 0.19))
		var font: Font = get_theme_default_font()
		var ty: float = c.y + float(fs) * 0.35
		if shape == "circle":
			draw_circle(c, r, fill)
			draw_arc(c, r, 0.0, TAU, 40, line, 3.0, true)
		else:
			var pts := PackedVector2Array()
			if shape == "up":
				pts = PackedVector2Array([Vector2(c.x, 3), Vector2(sz.x - 3, sz.y - 3), Vector2(3, sz.y - 3)])
			else:
				pts = PackedVector2Array([Vector2(3, 3), Vector2(sz.x - 3, 3), Vector2(c.x, sz.y - 3)])
			draw_colored_polygon(pts, fill)
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, line, 3.0, true)
			ty = c.y + float(fs) * 0.3
		var txt: String = Lang.t(label)
		var ts: Vector2 = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var tp := Vector2((sz.x - ts.x) / 2.0, ty)
		draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.9))
		draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ui.col("text"))


var player: Player = null
var edit_mode: bool = false
var items: Array = []          # [{tag, node, base}]
var _layout: Dictionary = {}   # tag -> {h, v, ox, oy, k}
var _palette_name: String = "Cian"
var _alpha: float = 0.6
var _stick_base: Panel
var _stick_knob: Panel
var _more_panel: PanelContainer
var _edit_bar: PanelContainer
var _edit_label: Label
var _sel: Dictionary = {}
var _stick_touch: int = -1
var _btn_touch: Dictionary = {}   # índice de dedo -> Btn
var _drag: Dictionary = {}        # índice de dedo -> item (modo edición)
var _hot_panel: PanelContainer
var _hot_grid: GridContainer


func _ready() -> void:
	layer = 100
	_load()
	_build_items()
	_build_more_panel()
	_build_hot_panel()
	_build_edit_bar()
	for it in items:
		_place(it)


## Color de la paleta actual (fill usa la transparencia elegida).
func col(key: String) -> Color:
	var pal: Dictionary = PALETTES[_palette_name]
	var c := Color.html(str(pal.get(key, "ffffff")))
	if key == "fill":
		c.a = _alpha
	elif key == "press":
		c.a = 0.9
	return c


# ================================================================ Construcción

func _build_items() -> void:
	# Joystick
	_stick_base = Panel.new()
	_stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stick_base)
	_stick_knob = Panel.new()
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(_stick_knob)
	items.append({"tag": "stick", "node": _stick_base, "base": Vector2(STICK_BASE, STICK_BASE)})

	for row in DEFS:
		var b := Btn.new(self, str(row[1]), str(row[2]), str(row[0]))
		add_child(b)
		items.append({"tag": str(row[0]), "node": b, "base": row[3]})
	_refresh_colors()


## Panel "Ver armas": lista el hotbar para elegir el arma.
func _build_hot_panel() -> void:
	_hot_panel = PanelContainer.new()
	_hot_panel.visible = false
	_hot_panel.add_theme_stylebox_override("panel", _rounded(Color(0.07, 0.08, 0.11, 0.95), 14))
	add_child(_hot_panel)
	_hot_grid = GridContainer.new()
	_hot_grid.columns = 6
	_hot_grid.add_theme_constant_override("h_separation", 8)
	_hot_grid.add_theme_constant_override("v_separation", 8)
	_hot_panel.add_child(_hot_grid)


func _toggle_hot() -> void:
	if _hot_panel.visible:
		_hot_panel.visible = false
		return
	for c in _hot_grid.get_children():
		c.queue_free()
	_hot_grid.columns = maxi(1, player.hotbar.size())
	for i in range(player.hotbar.size()):
		var b := Button.new()
		b.text = "%d %s" % [i + 1, _item_name(str(player.hotbar[i])).left(8)]
		b.custom_minimum_size = Vector2(76, 40)
		if i == player.slot:
			b.add_theme_color_override("font_color", Color(0.25, 0.85, 0.95))
		b.pressed.connect(_pick_slot.bind(i))
		b.pressed.connect(Sfx.play.bind("click"))
		_hot_grid.add_child(b)
	var vs: Vector2 = get_viewport().get_visible_rect().size
	_hot_panel.position = Vector2(vs.x * 0.5 - float(player.hotbar.size()) * 39.0, vs.y - 120.0)
	_hot_panel.visible = true


func _pick_slot(i: int) -> void:
	player.select_slot(i)
	_hot_panel.visible = false


func _item_name(id: String) -> String:
	if id == "":
		return "—"
	var k: int = id.find(":")
	return id.substr(k + 1) if k >= 0 else id


func _build_more_panel() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	_more_panel = PanelContainer.new()
	_more_panel.add_theme_stylebox_override("panel", _rounded(Color(0.07, 0.08, 0.11, 0.95), 16))
	_more_panel.visible = false
	add_child(_more_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(vs.x - 40.0, vs.y - 120.0)
	_more_panel.add_child(scroll)
	var mg := GridContainer.new()
	mg.columns = 4
	mg.add_theme_constant_override("h_separation", 8)
	mg.add_theme_constant_override("v_separation", 8)
	scroll.add_child(mg)
	var entries: Array = [
		["Bloques", "bloques"], ["Sentarse", "sentar"], ["Rotar bloque", "rotar"],
		["Noclip", "noclip"], ["Cámara lenta", "slowmo"], ["Sin gravedad", "gravedad"],
		["Congelar", "congelar"], ["Snapping", "snap"], ["Probar", "probar"],
		["Deshacer", "deshacer"], ["Freecam", "freecam"], ["Invencibles", "invencibles"],
		["Apoyar", "apoyar"], ["Personalizar", "personalizar"], ["Ayuda", "ayuda"],
		["Editar controles", "editar"], ["Salir al menú", "salir_menu"], ["Salir del juego", "salir_juego"],
		["Chat", "chat"],
		["Cerrar", "cerrar"],
	]
	for e in entries:
		var pair: Array = e
		var b := Button.new()
		b.text = Lang.t(str(pair[0]))
		b.custom_minimum_size = Vector2(vs.x / 4.0 - 30.0, 60)
		b.pressed.connect(_on_more_entry.bind(str(pair[1])))
		mg.add_child(b)
	_more_panel.set_anchors_preset(Control.PRESET_FULL_RECT)


func _build_edit_bar() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	_edit_bar = PanelContainer.new()
	_edit_bar.add_theme_stylebox_override("panel", _rounded(Color(0.07, 0.08, 0.11, 0.95), 12))
	_edit_bar.visible = false
	add_child(_edit_bar)
	_edit_bar.position = Vector2(vs.x * 0.5 - 330, 110)
	var col_box := VBoxContainer.new()
	_edit_bar.add_child(col_box)
	_edit_label = Label.new()
	_edit_label.text = Lang.t("Arrastrá un botón. Tocalo para elegirlo.")
	col_box.add_child(_edit_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	col_box.add_child(row)
	_bar_btn(row, "Tamaño +", _resize_sel.bind(0.1))
	_bar_btn(row, "Tamaño -", _resize_sel.bind(-0.1))
	_bar_btn(row, "Color", _cycle_palette)
	_bar_btn(row, "Transparencia", _cycle_alpha)
	_bar_btn(row, "Restablecer", _reset_layout)
	_bar_btn(row, "Listo", _stop_edit)


func _bar_btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = Lang.t(text)
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(cb)
	parent.add_child(b)


func _rounded(c: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(8)
	return sb


# ================================================================ Posición y guardado

func _ldef(tag: String) -> Dictionary:
	if _layout.has(tag):
		return _layout[tag]
	if tag == "stick":
		return STICK_DEF.duplicate()
	for row in DEFS:
		if str(row[0]) == tag:
			return {"h": str(row[4]), "v": str(row[5]), "ox": float(row[6]), "oy": float(row[7]), "k": 1.0}
	return {"h": "L", "v": "T", "ox": 0.0, "oy": 0.0, "k": 1.0}


func _place(it: Dictionary) -> void:
	var n: Control = it["node"]
	var d: Dictionary = _ldef(str(it["tag"]))
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var k: float = clampf(float(d["k"]), 0.5, 2.0)
	var sz: Vector2 = (it["base"] as Vector2) * k
	n.size = sz
	n.custom_minimum_size = sz
	var x: float = 0.0
	match str(d["h"]):
		"R": x = vs.x - sz.x - float(d["ox"])
		"C": x = vs.x * 0.5 + float(d["ox"])
		_: x = float(d["ox"])
	var y: float = 0.0
	match str(d["v"]):
		"B": y = vs.y - sz.y - float(d["oy"])
		_: y = float(d["oy"])
	n.position = Vector2(x, y)
	if str(it["tag"]) == "stick":
		_stick_knob.size = sz * 0.41
		_stick_knob.add_theme_stylebox_override("panel", _rounded(col("press"), 100))
		_center_knob()
	_refresh_stick_style()
	n.queue_redraw()


## Guarda el lugar de un botón como ancla al lado más cercano de la pantalla.
func _store_pos(it: Dictionary) -> void:
	var n: Control = it["node"]
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var c: Vector2 = n.position + n.size * 0.5
	var d: Dictionary = _ldef(str(it["tag"])).duplicate()
	if c.x < vs.x * 0.5:
		d["h"] = "L"
		d["ox"] = n.position.x
	else:
		d["h"] = "R"
		d["ox"] = vs.x - (n.position.x + n.size.x)
	if c.y < vs.y * 0.5:
		d["v"] = "T"
		d["oy"] = n.position.y
	else:
		d["v"] = "B"
		d["oy"] = vs.y - (n.position.y + n.size.y)
	d["k"] = float(d.get("k", 1.0))
	_layout[str(it["tag"])] = d


func _center_knob() -> void:
	var base: Vector2 = _stick_base.size
	_stick_knob.position = base * 0.5 - _stick_knob.size * 0.5


func _load() -> void:
	_layout = {}
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	var pal: String = str(d.get("palette", "Cian"))
	if PALETTES.has(pal):
		_palette_name = pal
	_alpha = float(d.get("alpha", 0.6))
	var items_d: Variant = d.get("items", {})
	if typeof(items_d) == TYPE_DICTIONARY:
		_layout = items_d


func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"palette": _palette_name, "alpha": _alpha, "items": _layout}))
		f.close()


func _refresh_colors() -> void:
	for it in items:
		(it["node"] as Control).queue_redraw()
	_refresh_stick_style()


func _refresh_stick_style() -> void:
	_stick_base.add_theme_stylebox_override("panel", _rounded(_stick_fill(), 100))


func _stick_fill() -> Color:
	var c := col("fill")
	if _sel.has("tag") and _sel["tag"] == "stick" and edit_mode:
		c = Color(1.0, 0.9, 0.2, 0.4)
	return c


# ================================================================ Modo edición

func _start_edit() -> void:
	edit_mode = true
	_more_panel.visible = false
	_edit_bar.visible = true
	_sel = {}
	_drag = {}
	_btn_touch = {}
	_stick_touch = -1
	_refresh_colors()
	if player != null:
		player.touch_move = Vector2.ZERO


func _stop_edit() -> void:
	for it in items:
		_store_pos(it)
	_save()
	edit_mode = false
	_edit_bar.visible = false
	_sel = {}
	_refresh_all_sel()
	_refresh_colors()


func _select(it: Dictionary) -> void:
	_sel = it
	_refresh_all_sel()


func _refresh_all_sel() -> void:
	for it in items:
		var n: Control = it["node"]
		if n is Btn:
			(n as Btn).sel = edit_mode and _sel.has("tag") and _sel["tag"] == it["tag"]
		n.queue_redraw()
	_refresh_stick_style()


func _resize_sel(step: float) -> void:
	if _sel.is_empty():
		_edit_label.text = "Primero tocá un botón para elegirlo."
		return
	var d: Dictionary = _ldef(str(_sel["tag"])).duplicate()
	d["k"] = clampf(float(d.get("k", 1.0)) + step, 0.5, 2.0)
	_layout[str(_sel["tag"])] = d
	_place(_sel)
	_store_pos(_sel)


func _cycle_palette() -> void:
	var names: Array = PALETTES.keys()
	var i: int = names.find(_palette_name)
	_palette_name = str(names[(i + 1) % names.size()])
	_edit_label.text = "Color: " + _palette_name
	_refresh_colors()


func _cycle_alpha() -> void:
	var i: int = ALPHAS.find(_alpha)
	_alpha = float(ALPHAS[(i + 1) % ALPHAS.size()])
	_edit_label.text = "Transparencia: %d%%" % int(_alpha * 100)
	_refresh_colors()


func _reset_layout() -> void:
	_layout = {}
	_palette_name = "Cian"
	_alpha = 0.6
	for it in items:
		_place(it)
	_refresh_colors()
	_edit_label.text = "Diseño restablecido."


# ================================================================ Acciones

func _on_more_entry(action_name: String) -> void:
	if action_name == "cerrar":
		_more_panel.visible = false
		return
	if action_name == "editar":
		_start_edit()
		return
	if action_name == "sentar" and player != null:
		player.toggle_seat()
		return
	if action_name == "rotar" and player != null:
		player.rotate_ghost(false)
		return
	action.emit(action_name)


func _btn_down(tag: String) -> void:
	if tag == "pausa":
		action.emit("pausa")
		return
	if tag == "objetos":
		action.emit("objetos")
		return
	if tag == "items":
		action.emit("mochila")
		return
	if tag == "mas":
		_more_panel.visible = not _more_panel.visible
		_more_panel.move_to_front()
		return
	if player == null:
		return
	if tag == "armas":
		_toggle_hot()
		return
	match tag:
		"item+": player.cycle_slot(1)
		"item-": player.cycle_slot(-1)
		"noclip": player.set_noclip(not player.noclip)
		"saltar": player.touch_jump = true
		"agachar": player.touch_slam = true
		"usar": player.toggle_seat()
		"disparar": player.tool_press()
		"derecho": player.tool_secondary()
		"gancho": player.toggle_hook()


func _btn_up(tag: String) -> void:
	if player == null:
		return
	match tag:
		"saltar": player.touch_jump = false
		"agachar": player.touch_slam = false
		"disparar": player.tool_release()


# ================================================================ Entrada (multitouch)

func _hit(it: Dictionary, pos: Vector2) -> bool:
	return (it["node"] as Control).get_global_rect().has_point(pos)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_down(t)
		else:
			_touch_up(t)
	elif event is InputEventScreenDrag:
		_touch_drag(event as InputEventScreenDrag)


func _touch_down(t: InputEventScreenTouch) -> void:
	if edit_mode:
		for it in items:
			if _hit(it, t.position):
				_select(it)
				_drag[t.index] = it
				get_viewport().set_input_as_handled()
				return
		return
	if player != null and _stick_touch == -1 and _stick_base.get_global_rect().has_point(t.position):
		_stick_touch = t.index
		get_viewport().set_input_as_handled()
		return
	for it in items:
		if str(it["tag"]) == "stick":
			continue
		if _hit(it, t.position):
			var b := it["node"] as Btn
			_btn_touch[t.index] = b
			b.down = true
			b.queue_redraw()
			_btn_down(b.tag)
			get_viewport().set_input_as_handled()
			return


func _touch_up(t: InputEventScreenTouch) -> void:
	if _drag.has(t.index):
		var it: Dictionary = _drag[t.index]
		_drag.erase(t.index)
		_store_pos(it)
		get_viewport().set_input_as_handled()
		return
	if t.index == _stick_touch and player != null:
		_stick_touch = -1
		player.touch_move = Vector2.ZERO
		_center_knob()
		get_viewport().set_input_as_handled()
		return
	if _btn_touch.has(t.index):
		var b2 := _btn_touch[t.index] as Btn
		_btn_touch.erase(t.index)
		b2.down = false
		b2.queue_redraw()
		_btn_up(b2.tag)
		get_viewport().set_input_as_handled()


func _touch_drag(d: InputEventScreenDrag) -> void:
	if _drag.has(d.index):
		var it: Dictionary = _drag[d.index]
		var n: Control = it["node"]
		n.position += d.relative
		get_viewport().set_input_as_handled()
		return
	if d.index == _stick_touch and player != null:
		var c: Vector2 = _stick_base.get_global_rect().get_center()
		var rad: float = _stick_base.size.x * 0.5
		var v: Vector2 = (d.position - c) / rad
		v = v.limit_length(1.0)
		if v.length() < 0.12:
			v = Vector2.ZERO
		player.touch_move = v
		_center_knob()
		_stick_knob.position += v * (rad - _stick_knob.size.x * 0.5)
		get_viewport().set_input_as_handled()
