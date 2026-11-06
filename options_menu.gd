class_name OptionsMenu
extends Control
## Menú de opciones: General (nombre, idioma) y Video (modo, resolución, escala, shader).
## Se usa desde el lobby, desde la pausa y en el primer inicio (modo first_run).

signal changed
signal closed

var first_run: bool = false
var _tab_body: VBoxContainer
var _name_edit: LineEdit
var _lang_btn: Button
var _mode_opt: OptionButton
var _res_opt: OptionButton
var _scale_slider: HSlider
var _scale_label: Label
var _shader_opt: OptionButton
var _gfx_opt: OptionButton
var _panel: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# Contenedor a pantalla completa que centra el panel (sin cálculos de anclas)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _bg())
	_panel.custom_minimum_size = get_viewport_rect().size - Vector2(60, 60)
	center.add_child(_panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	var title := Label.new()
	title.text = Lang.t("Opciones")
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	tabs.add_child(_tab_btn("General", _show_general))
	if not (OS.has_feature("mobile") or OS.has_feature("web")):
		tabs.add_child(_tab_btn("Video", _show_video))

	_tab_body = VBoxContainer.new()
	_tab_body.add_theme_constant_override("separation", 10)
	_tab_body.custom_minimum_size = Vector2(460, 300)
	root.add_child(_tab_body)

	var bottom := HBoxContainer.new()
	root.add_child(bottom)
	var close_txt: String = "Empezar" if first_run else "Volver"
	var close := Button.new()
	close.text = Lang.t(close_txt)
	close.custom_minimum_size = Vector2(160, 42)
	close.pressed.connect(_close)
	bottom.add_child(close)
	_show_general()


func open() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_show_general()


func _close() -> void:
	if first_run:
		Settings.first_run_done = true
		first_run = false
	Settings.player_name = _name_edit.text.strip_edges() if _name_edit != null else Settings.player_name
	Settings.save()
	visible = false
	closed.emit()


func _tab_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = Lang.t(text)
	b.custom_minimum_size = Vector2(120, 38)
	b.pressed.connect(cb)
	b.pressed.connect(Sfx.play.bind("click"))
	b.mouse_entered.connect(Sfx.play.bind("hover"))
	return b


func _clear() -> void:
	for c in _tab_body.get_children():
		c.queue_free()


func _row(label_text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = Lang.t(label_text)
	l.custom_minimum_size = Vector2(190, 0)
	h.add_child(l)
	_tab_body.add_child(h)
	return h


func _show_general() -> void:
	_clear()
	var nh := _row("Tu nombre (vacío = Jugador1, Jugador2...)")
	_name_edit = LineEdit.new()
	_name_edit.text = Settings.player_name
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(240, 36)
	_name_edit.text_changed.connect(func(t: String) -> void:
		Settings.player_name = t.strip_edges()
		Settings.save()
		changed.emit())
	nh.add_child(_name_edit)

	var lh := _row("Idioma")
	_lang_btn = Button.new()
	_lang_btn.text = Lang.name_label()
	_lang_btn.custom_minimum_size = Vector2(240, 36)
	_lang_btn.pressed.connect(func() -> void:
		Lang.cycle()
		_lang_btn.text = Lang.name_label()
		changed.emit())
	lh.add_child(_lang_btn)

	var vh := _row("Volumen general")
	var vs := HSlider.new()
	vs.min_value = 0
	vs.max_value = 100
	vs.step = 5
	vs.value = Settings.volume_pct
	vs.custom_minimum_size = Vector2(240, 24)
	vs.value_changed.connect(func(v: float) -> void:
		Settings.volume_pct = int(v)
		_video_changed())
	vh.add_child(vs)

	var sh2 := _row("Sensibilidad del mouse")
	var ss := HSlider.new()
	ss.min_value = 25
	ss.max_value = 300
	ss.step = 5
	ss.value = Settings.sensitivity_pct
	ss.custom_minimum_size = Vector2(240, 24)
	ss.value_changed.connect(func(v: float) -> void:
		Settings.sensitivity_pct = int(v)
		_video_changed())
	sh2.add_child(ss)

	var note := Label.new()
	note.text = Lang.t("El idioma se aplica al reiniciar el juego.")
	note.modulate = Color(1, 1, 1, 0.7)
	_tab_body.add_child(note)


func _show_video() -> void:
	_clear()
	var mh := _row("Modo de pantalla")
	_mode_opt = OptionButton.new()
	for t in ["Ventana", "Pantalla completa", "Pantalla completa sin bordes"]:
		_mode_opt.add_item(Lang.t(t))
	_mode_opt.selected = Settings.DISPLAY_MODES.find(Settings.display_mode)
	_mode_opt.custom_minimum_size = Vector2(240, 36)
	_mode_opt.item_selected.connect(func(i: int) -> void:
		Settings.display_mode = Settings.DISPLAY_MODES[i]
		_video_changed())
	mh.add_child(_mode_opt)

	var rh := _row("Resolución")
	_res_opt = OptionButton.new()
	for r in Settings.RESOLUTIONS:
		var rv: Vector2i = r
		var tag: String = ""
		if rv.y == 720 or rv.y == 768 or rv.y == 900 or rv.y == 1080 or rv.y == 1440:
			tag = " (%dp)" % rv.y
		_res_opt.add_item("%dx%d%s" % [rv.x, rv.y, tag])
	var ri: int = Settings.RESOLUTIONS.find(Settings.resolution)
	_res_opt.selected = ri if ri >= 0 else 0
	_res_opt.custom_minimum_size = Vector2(240, 36)
	_res_opt.item_selected.connect(func(i: int) -> void:
		Settings.resolution = Settings.RESOLUTIONS[i]
		_video_changed())
	rh.add_child(_res_opt)

	var sh := _row("Escala de resolución")
	_scale_slider = HSlider.new()
	_scale_slider.min_value = 50
	_scale_slider.max_value = 100
	_scale_slider.step = 5
	_scale_slider.value = Settings.scale_pct
	_scale_slider.custom_minimum_size = Vector2(180, 24)
	_scale_label = Label.new()
	_scale_label.text = "%d%%" % Settings.scale_pct
	_scale_slider.value_changed.connect(func(v: float) -> void:
		Settings.scale_pct = int(v)
		_scale_label.text = "%d%%" % Settings.scale_pct
		_video_changed())
	sh.add_child(_scale_slider)
	sh.add_child(_scale_label)

	var gh := _row("Calidad gráfica")
	_gfx_opt = OptionButton.new()
	for g in Settings.GRAPHICS:
		_gfx_opt.add_item(Lang.t(g))
	_gfx_opt.selected = Settings.graphics_idx
	_gfx_opt.custom_minimum_size = Vector2(240, 36)
	_gfx_opt.item_selected.connect(func(i: int) -> void:
		Settings.graphics_idx = i
		_video_changed())
	gh.add_child(_gfx_opt)

	var hh := _row("Shader")
	_shader_opt = OptionButton.new()
	for s in Settings.SHADERS:
		_shader_opt.add_item(Lang.t(s))
	_shader_opt.selected = Settings.shader_idx
	_shader_opt.custom_minimum_size = Vector2(240, 36)
	_shader_opt.item_selected.connect(func(i: int) -> void:
		Settings.shader_idx = i
		_video_changed())
	hh.add_child(_shader_opt)


func _video_changed() -> void:
	Settings.apply()
	Settings.save()
	changed.emit()


func _bg() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.97)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(22)
	return sb
