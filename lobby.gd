class_name LobbyUI
extends Control
## Menú de inicio: usuario, un jugador y multijugador (Local por red / Online por servidores guardados).

signal single_requested(player_name: String)
signal host_requested(player_name: String, online: bool)
signal join_requested(player_name: String, address: String, port: int)
signal touch_toggled
signal options_requested
signal quit_requested
var _changelog_panel: PanelContainer

const SAVE_PATH := "user://servers.json"
const DEFAULT_PORT := 7777

var lan: Lan = null
var touch: bool = false

var name_edit: LineEdit
var info_label: Label
var main_page: VBoxContainer
var multi_page: VBoxContainer
var local_box: VBoxContainer
var online_box: VBoxContainer
var lan_list: VBoxContainer
var saved_list: VBoxContainer
var add_name: LineEdit
var add_addr: LineEdit
var touch_btn: Button
var saved: Array = []
var _lan_sig: String = ""


var _bg: Texture2D = null


func _ready() -> void:
	add_child(Settings.version_badge())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://lobby_bg.png"):
		_bg = load("res://lobby_bg.png") as Texture2D
	resized.connect(queue_redraw)
	_load_saved()

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.custom_minimum_size = Vector2(460, 0)
	add_child(panel)
	# Columna a la izquierda, centrada verticalmente
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = 70.0

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	_lang_btn = _btn(Lang.name_label(), _cycle_lang)
	_build_map_ui(col)

	var title := Label.new()
	title.text = "SANDBOX"
	title.add_theme_font_size_override("font_size", 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.visible = false
	col.add_child(title)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Tu nombre (vacío = Jugador1, Jugador2...)"
	name_edit.max_length = 16
	_options_panel = PanelContainer.new()
	_options_panel.visible = false
	_options_panel.add_theme_stylebox_override("panel", _rounded_bg())
	add_child(_options_panel)
	_options_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_options_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_options_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 10)
	_options_panel.add_child(ov)
	var ol := Label.new()
	ol.text = Lang.t("Opciones")
	ol.add_theme_font_size_override("font_size", 26)
	ov.add_child(ol)
	var nl := Label.new()
	nl.text = Lang.t("Tu nombre (vacío = Jugador1, Jugador2...)")
	ov.add_child(nl)
	name_edit.custom_minimum_size = Vector2(380, 40)
	ov.add_child(name_edit)
	ov.add_child(_btn("Volver", _toggle_options))

	# ---- Página principal
	main_page = VBoxContainer.new()
	main_page.add_theme_constant_override("separation", 10)
	col.add_child(main_page)
	main_page.add_child(_btn("Un jugador", _on_single))
	main_page.add_child(_btn("Multijugador", _show_multi))
	main_page.add_child(_btn("Opciones", _toggle_options))
	main_page.add_child(_btn("Novedades", _toggle_changelog))
	main_page.add_child(_btn("Salir", func() -> void: quit_requested.emit()))
	touch_btn = _btn("", _on_touch)
	main_page.add_child(touch_btn)
	_refresh_touch_text()

	# ---- Página multijugador
	multi_page = VBoxContainer.new()
	multi_page.add_theme_constant_override("separation", 10)
	multi_page.visible = false
	col.add_child(multi_page)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	multi_page.add_child(tabs)
	tabs.add_child(_btn("Local", _show_local))
	tabs.add_child(_btn("Online", _show_online))

	local_box = VBoxContainer.new()
	local_box.add_theme_constant_override("separation", 8)
	multi_page.add_child(local_box)
	local_box.add_child(_btn("Crear servidor local", _on_host_local))
	var l1 := Label.new()
	l1.text = "Servidores encontrados en tu red:"
	local_box.add_child(l1)
	lan_list = VBoxContainer.new()
	lan_list.add_theme_constant_override("separation", 6)
	local_box.add_child(lan_list)

	online_box = VBoxContainer.new()
	online_box.add_theme_constant_override("separation", 8)
	online_box.visible = false
	multi_page.add_child(online_box)
	online_box.add_child(_btn("Crear servidor online", _on_host_online))
	var l2 := Label.new()
	l2.text = "Servidores guardados:"
	online_box.add_child(l2)
	saved_list = VBoxContainer.new()
	saved_list.add_theme_constant_override("separation", 6)
	online_box.add_child(saved_list)
	var l3 := Label.new()
	l3.text = "Agregar un servidor (se guarda con su nombre):"
	online_box.add_child(l3)
	add_name = LineEdit.new()
	add_name.placeholder_text = "Nombre del servidor (ej: ian server)"
	online_box.add_child(add_name)
	add_addr = LineEdit.new()
	add_addr.placeholder_text = "Dirección del servidor"
	online_box.add_child(add_addr)
	online_box.add_child(_btn("Guardar servidor", _on_add_saved))

	multi_page.add_child(_btn("Volver", _show_main))

	# ---- Mensajes (errores / estado)
	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(420, 0)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.visible = false
	col.add_child(info_label)

	_rebuild_saved()


# ================================================================ Estilos

func _draw() -> void:
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.05, 0.18), true)


func _panel_style() -> StyleBox:
	return StyleBoxEmpty.new()


func _unused_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.96)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.08)
	return sb


func _flat(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	return sb


var _lang_btn: Button


## Cambia el idioma. Se aplica completo al volver a iniciar el juego.
func _cycle_lang() -> void:
	Lang.cycle()
	_lang_btn.text = Lang.name_label()


var _map_btn: Button
var _map_title: Label
var _options_panel: PanelContainer
var _pending: String = ""
var _map_panel: PanelContainer


## Mapas disponibles (todos los paquetes).
func _all_maps() -> Array:
	return Content.maps() + ContentExtra.maps() + ContentMore.maps()


func _map_label() -> String:
	var maps: Array = _all_maps()
	var idx: int = clampi(MapPick.index, 0, maps.size() - 1)
	return Lang.t("Mapa: ") + str(maps[idx]["name"])


## Botón "Mapa" y un panel tipo galería para elegir el mapa antes de jugar.
func _build_map_ui(col: VBoxContainer) -> void:
	_map_btn = _btn(_map_label(), _toggle_map_panel)
	col.add_child(_map_btn)
	_changelog_panel = PanelContainer.new()
	_changelog_panel.visible = false
	_changelog_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_changelog_panel.add_theme_stylebox_override("panel", _full_bg())
	add_child(_changelog_panel)
	var cv := VBoxContainer.new()
	_changelog_panel.add_child(cv)
	var ct := Label.new()
	ct.text = Lang.t("Novedades") + "  " + Changelog.VERSION
	ct.add_theme_font_size_override("font_size", 28)
	cv.add_child(ct)
	var csc := ScrollContainer.new()
	csc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cv.add_child(csc)
	var cl := VBoxContainer.new()
	cl.add_theme_constant_override("separation", 10)
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	csc.add_child(cl)
	for entry in Changelog.ENTRIES:
		var hv := Label.new()
		hv.text = str(entry[0])
		hv.add_theme_font_size_override("font_size", 22)
		cl.add_child(hv)
		for line in entry[1]:
			var ll := Label.new()
			ll.text = "• " + Lang.t(str(line))
			ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cl.add_child(ll)
	cv.add_child(_btn("Cerrar", _toggle_changelog))
	_map_panel = PanelContainer.new()
	_map_panel.visible = false
	add_child(_map_panel)
	_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_panel.add_theme_stylebox_override("panel", _full_bg())
	_map_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_map_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new()
	_map_panel.add_child(v)
	var title := Label.new()
	title.text = Lang.t("Elegí un mapa")
	_map_title = title
	v.add_child(title)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var maps: Array = _all_maps()
	for i in maps.size():
		var b := Button.new()
		b.text = str(maps[i]["name"])
		b.pressed.connect(Sfx.play.bind("click"))
		b.mouse_entered.connect(Sfx.play.bind("hover"))
		b.custom_minimum_size = Vector2(176, 96)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color.from_hsv(float(i) / float(maps.size()), 0.5, 0.45)
		sb.set_corner_radius_all(10)
		b.add_theme_stylebox_override("normal", sb)
		b.pressed.connect(_pick_map.bind(i))
		grid.add_child(b)
	v.add_child(_btn("Cancelar", _cancel_map))


func _full_bg() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.09, 0.97)
	sb.set_content_margin_all(40)
	return sb


func _toggle_changelog() -> void:
	_changelog_panel.visible = not _changelog_panel.visible


func _toggle_map_panel() -> void:
	_pending = ""
	_map_panel.visible = not _map_panel.visible
	_fit_map()


## Ocupa toda la pantalla (antes quedaba como un recuadro chico arriba a la izquierda).
func _fit_map() -> void:
	_map_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_map_panel.position = Vector2.ZERO
	_map_panel.size = get_viewport_rect().size


func _cancel_map() -> void:
	_pending = ""
	_map_panel.visible = false


## Abre la galería; al elegir un mapa se arranca la partida de ese tipo.
func _start_with_map(kind: String) -> void:
	_pending = kind
	_fit_map()
	_map_panel.move_to_front()
	_map_title.text = Lang.t("Elegí un mapa para empezar")
	_map_panel.visible = true


func _toggle_options() -> void:
	options_requested.emit()


func _rounded_bg() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.09, 0.94)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	return sb


func _pick_map(i: int) -> void:
	MapPick.index = i
	_map_btn.text = _map_label()
	_map_panel.visible = false
	var k: String = _pending
	_pending = ""
	if k == "single":
		single_requested.emit(player_name())
	elif k == "local":
		host_requested.emit(player_name(), false)
	elif k == "online":
		host_requested.emit(player_name(), true)


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = Lang.t(text)
	b.flat = true
	b.pressed.connect(Sfx.play.bind("click"))
	b.mouse_entered.connect(Sfx.play.bind("hover"))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(340, 46)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color(0.35, 0.9, 1.0))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.6, 0.15))
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	b.add_theme_constant_override("outline_size", 6)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	return b


# ================================================================ Páginas

func player_name() -> String:
	return Settings.player_name


func _show_main() -> void:
	main_page.visible = true
	multi_page.visible = false
	if lan != null:
		lan.stop_listening()
	clear_info()


func _show_multi() -> void:
	main_page.visible = false
	multi_page.visible = true
	_show_local()


func _show_local() -> void:
	local_box.visible = true
	online_box.visible = false
	_lan_sig = "?"
	if lan != null and not lan.start_listening():
		show_error("No se pudo escuchar la red local (puerto %d ocupado). Si ya tenés otro juego abierto en esta PC, cerralo." % Lan.PORT)
	else:
		clear_info()


func _show_online() -> void:
	local_box.visible = false
	online_box.visible = true
	if lan != null:
		lan.stop_listening()
	_rebuild_saved()
	clear_info()


func show_error(msg: String) -> void:
	info_label.text = "⚠ " + msg
	info_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	info_label.visible = true


func show_info(msg: String) -> void:
	info_label.text = msg
	info_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	info_label.visible = true


func clear_info() -> void:
	info_label.visible = false


func set_touch(v: bool) -> void:
	touch = v
	_refresh_touch_text()


func _refresh_touch_text() -> void:
	touch_btn.text = "Controles táctiles: " + ("ON" if touch else "OFF")


# ================================================================ Acciones

func _on_single() -> void:
	_start_with_map("single")


func _on_touch() -> void:
	touch_toggled.emit()


func _on_host_local() -> void:
	_start_with_map("local")


func _on_host_online() -> void:
	_start_with_map("online")


func _join(address: String, port: int) -> void:
	show_info("Conectando a %s ..." % address)
	join_requested.emit(player_name(), address, port)


# ================================================================ Servidores guardados (Online)

func _load_saved() -> void:
	saved = []
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) == TYPE_ARRAY:
		saved = parsed


func _save_saved() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(saved))
		f.close()


func _on_add_saved() -> void:
	var n: String = add_name.text.strip_edges()
	var a: String = add_addr.text.strip_edges()
	if a == "":
		show_error("Escribí la dirección del servidor para guardarlo.")
		return
	if n == "":
		n = a
	saved.append({"name": n, "address": a})
	_save_saved()
	add_name.clear()
	add_addr.clear()
	_rebuild_saved()
	clear_info()


func _remove_saved(i: int) -> void:
	if i >= 0 and i < saved.size():
		saved.remove_at(i)
		_save_saved()
		_rebuild_saved()


func _join_saved(i: int) -> void:
	if i < 0 or i >= saved.size():
		return
	var entry: Dictionary = saved[i]
	var addr: String = str(entry["address"])
	var port: int = DEFAULT_PORT
	if addr.contains(":"):
		var parts: PackedStringArray = addr.split(":")
		addr = parts[0]
		port = int(parts[1])
	_join(addr, port)


func _clear_children(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func _rebuild_saved() -> void:
	_clear_children(saved_list)
	if saved.is_empty():
		var l := Label.new()
		l.text = "(todavía no guardaste ninguno)"
		saved_list.add_child(l)
		return
	for i in saved.size():
		var entry: Dictionary = saved[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var b := _btn("%s (UNIRSE)" % str(entry["name"]), _join_saved.bind(i))
		row.add_child(b)
		var x := _btn("✕", _remove_saved.bind(i))
		x.size_flags_horizontal = Control.SIZE_SHRINK_END
		x.custom_minimum_size = Vector2(46, 46)
		row.add_child(x)
		saved_list.add_child(row)


# ================================================================ Servidores de la red local

func _process(_delta: float) -> void:
	if lan == null or not multi_page.visible or not local_box.visible:
		return
	var sig: String = JSON.stringify(lan.servers.keys())
	for ip in lan.servers:
		var s: Dictionary = lan.servers[ip]
		sig += "%s%s%s" % [str(s.get("name", "")), str(s.get("players", 0)), str(s.get("map", ""))]
	if sig == _lan_sig:
		return
	_lan_sig = sig
	_clear_children(lan_list)
	if lan.servers.is_empty():
		var l := Label.new()
		l.text = "(buscando servidores...)"
		lan_list.add_child(l)
		return
	for ip2 in lan.servers:
		var s2: Dictionary = lan.servers[ip2]
		var text: String = "%s (UNIRSE)  ·  %d jugadores  ·  %s" % [str(s2.get("name", "Servidor")), int(s2.get("players", 1)), str(s2.get("map", ""))]
		lan_list.add_child(_btn(text, _join.bind(str(ip2), int(s2.get("port", DEFAULT_PORT)))))
