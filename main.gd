extends Node3D
## Sandbox estilo Garry's Mod: mundo, objetos, efectos, HUD y guardado.
## Adjuntá este script a un Node3D raíz.

const SAVE_PATH := "user://sandbox_save.json"
const HELP_TEXT := "CONTROLES\n\nWASD mover · Shift correr · Espacio saltar\nN noclip (Espacio sube, C baja, Shift acelera)\n1-6 o rueda: cambiar herramienta\nClick izq: usar herramienta · Click der: congelar (Physgun)\nRueda con Physgun: acercar o alejar\n\nQ menú de objetos · F congelar todo · G gravedad\nT cámara lenta · Ctrl+S guardar · Ctrl+L cargar\nH esta ayuda · Esc soltar el mouse"

const PROPS := {
	"Caja": {"shape": "box", "size": Vector3(1, 1, 1), "mass": 5.0},
	"Caja grande": {"shape": "box", "size": Vector3(2, 2, 2), "mass": 30.0},
	"Tabla": {"shape": "box", "size": Vector3(3, 0.2, 1), "mass": 8.0},
	"Esfera": {"shape": "sphere", "size": Vector3(0.5, 0.5, 0.5), "mass": 4.0},
	"Pelota rebotona": {"shape": "sphere", "size": Vector3(0.35, 0.35, 0.35), "mass": 1.0, "bounce": 0.85},
	"Barril": {"shape": "cylinder", "size": Vector3(0.5, 1.2, 0.5), "mass": 10.0},
	"Barril explosivo": {"shape": "cylinder", "size": Vector3(0.5, 1.2, 0.5), "mass": 10.0, "explosive": true, "color": "ff6a2a"},
}

const GRID_SHADER := """
shader_type spatial;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 coord = wp.xz * 0.5;
	vec2 g = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float line = min(g.x, g.y);
	ALBEDO = mix(vec3(0.15), vec3(0.45), 1.0 - clamp(line, 0.0, 1.0));
}
"""

var player: Player
var gravity_on: bool = true
var all_frozen: bool = false

var menu_root: CenterContainer
var help_panel: CenterContainer
var search_box: LineEdit
var grid: GridContainer
var hotbar: HBoxContainer
var slot_panels: Array[PanelContainer] = []
var info_label: Label
var toast_box: VBoxContainer
var fps_clock: float = 0.0


func _ready() -> void:
	_build_world()
	_build_hud()

	player = Player.new()
	player.world = self
	player.position = Vector3(0, 1, 0)
	add_child(player)
	player.tool_changed.connect(_on_tool_changed)
	player.notify.connect(toast)
	_on_tool_changed(0)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ================================================================ Mundo

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_density = 0.003
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var floor_body := _static_box(Vector3(300, 1, 300), Vector3(0, -0.5, 0), Vector3.ZERO)
	var shader := Shader.new()
	shader.code = GRID_SHADER
	var grid_mat := ShaderMaterial.new()
	grid_mat.shader = shader
	(floor_body.get_child(0) as MeshInstance3D).material_override = grid_mat

	_static_box(Vector3(6, 1, 6), Vector3(10, 0.5, -8), Vector3.ZERO, Color(0.6, 0.4, 0.3))
	_static_box(Vector3(8, 0.5, 4), Vector3(-10, 1.0, -8), Vector3(0, 0, 20), Color(0.3, 0.5, 0.7))
	_static_box(Vector3(20, 4, 1), Vector3(0, 2, -20), Vector3.ZERO, Color(0.25, 0.25, 0.3))


func _static_box(size: Vector3, pos: Vector3, rot_deg: Vector3, color: Color = Color.WHITE) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	body.add_child(mesh)
	body.add_child(col)
	body.position = pos
	body.rotation_degrees = rot_deg
	add_child(body)
	return body


# ================================================================ Props

func spawn_prop(kind: String, pos: Vector3, rot: Vector3 = Vector3.ZERO, color: Color = Color(0, 0, 0, 0), puff: bool = true) -> RigidBody3D:
	var cfg: Dictionary = PROPS[kind]
	var size: Vector3 = cfg.size
	var mesh: Mesh
	var shape: Shape3D

	match cfg.shape:
		"box":
			var m := BoxMesh.new()
			m.size = size
			mesh = m
			var s := BoxShape3D.new()
			s.size = size
			shape = s
		"sphere":
			var m := SphereMesh.new()
			m.radius = size.x
			m.height = size.x * 2.0
			mesh = m
			var s := SphereShape3D.new()
			s.radius = size.x
			shape = s
		"cylinder":
			var m := CylinderMesh.new()
			m.top_radius = size.x
			m.bottom_radius = size.x
			m.height = size.y
			mesh = m
			var s := CylinderShape3D.new()
			s.radius = size.x
			s.height = size.y
			shape = s

	var body := RigidBody3D.new()
	body.mass = cfg.mass
	body.gravity_scale = 1.0 if gravity_on else 0.0
	body.freeze = all_frozen
	body.add_to_group("props")
	body.set_meta("kind", kind)
	if cfg.has("explosive"):
		body.set_meta("explosive", true)
	if cfg.has("bounce"):
		var pm := PhysicsMaterial.new()
		pm.bounce = cfg.bounce
		body.physics_material_override = pm

	var mat := StandardMaterial3D.new()
	mat.roughness = 0.6
	if color.a > 0.0:
		mat.albedo_color = color
	elif cfg.has("color"):
		mat.albedo_color = Color.html("#" + cfg.color)
	else:
		mat.albedo_color = _random_color()
	if cfg.has("explosive"):
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.4

	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.material_override = mat
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(mi)
	body.add_child(cs)

	body.position = pos
	body.rotation = rot
	add_child(body)

	if puff:
		burst(pos, Color(0.85, 0.85, 0.85), 14)
	return body


func spawn_in_front(kind: String) -> void:
	var cam: Camera3D = player.camera
	var pos: Vector3 = cam.global_position - cam.global_transform.basis.z * 3.0
	spawn_prop(kind, pos, Vector3(0, player.rotation.y, 0))
	toast("Creado: " + kind)


func remove_prop(body: RigidBody3D) -> void:
	if _is_explosive(body):
		explode(body.global_position, 7.0, 45.0)
	body.queue_free()


func clone_prop(body: RigidBody3D) -> void:
	var kind: String = body.get_meta("kind", "Caja")
	var mi := body.get_node("Mesh") as MeshInstance3D
	var mat := mi.material_override as StandardMaterial3D
	var offset := Vector3(randf_range(-1.5, 1.5), 1.0, randf_range(-1.5, 1.5))
	spawn_prop(kind, body.global_position + offset, body.rotation, mat.albedo_color)
	toast("Clonado: " + kind)


func paint_prop(body: RigidBody3D) -> void:
	var mi := body.get_node("Mesh") as MeshInstance3D
	var mat := mi.material_override as StandardMaterial3D
	mat.albedo_color = _random_color()
	burst(body.global_position, mat.albedo_color, 20)


func clear_props() -> void:
	player.release()
	get_tree().call_group("props", "queue_free")
	toast("Escena limpia")


func _is_explosive(body: RigidBody3D) -> bool:
	return body.has_meta("explosive") and bool(body.get_meta("explosive"))


func _random_color() -> Color:
	return Color.from_hsv(randf(), 0.6, 0.9)


# ================================================================ Explosiones y efectos

func explode(pos: Vector3, radius: float = 6.0, power: float = 40.0) -> void:
	burst(pos, Color(1.0, 0.55, 0.15), 80)
	burst(pos, Color(0.3, 0.3, 0.32), 30)
	_flash(pos)

	# Screenshake según qué tan cerca estés
	var dist_player: float = player.global_position.distance_to(pos)
	player.add_shake(clampf(1.0 - dist_player / 30.0, 0.0, 1.0) * 1.2)

	# Knockback al jugador
	if dist_player < radius:
		var pd: Vector3 = (player.global_position - pos + Vector3.UP).normalized()
		player.knockback(pd * power * 0.15 * (1.0 - dist_player / radius))

	for n in get_tree().get_nodes_in_group("props"):
		var rb := n as RigidBody3D
		if rb == null or rb.freeze:
			continue
		var offset: Vector3 = rb.global_position - pos
		var d: float = offset.length()
		if d > radius:
			continue
		var falloff: float = 1.0 - d / radius
		var dir: Vector3 = (offset + Vector3.UP * 0.5).normalized()
		rb.apply_central_impulse(dir * power * falloff * rb.mass)

		# Reacción en cadena con barriles explosivos
		if _is_explosive(rb) and falloff > 0.2:
			rb.set_meta("explosive", false)
			get_tree().create_timer(0.12).timeout.connect(explode.bind(rb.global_position, radius, power))


func burst(pos: Vector3, color: Color, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.8
	p.spread = 180.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 12.0
	p.gravity = Vector3(0, -9.8, 0)

	var m := SphereMesh.new()
	m.radius = 0.08
	m.height = 0.16
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	m.material = mat
	p.mesh = m

	p.position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.5).timeout.connect(p.queue_free)


func _flash(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.35)
	light.omni_range = 14.0
	light.light_energy = 10.0
	light.position = pos
	add_child(light)
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.5)
	tw.tween_callback(light.queue_free)


# ================================================================ Modos globales

func toggle_gravity() -> void:
	gravity_on = not gravity_on
	var s: float = 1.0 if gravity_on else 0.0
	player.gravity_scale = s
	for n in get_tree().get_nodes_in_group("props"):
		var rb := n as RigidBody3D
		if rb != null:
			rb.gravity_scale = s
	toast("Gravedad " + ("activada" if gravity_on else "desactivada"))


func toggle_slow_mo() -> void:
	var slow: bool = Engine.time_scale >= 0.5
	Engine.time_scale = 0.25 if slow else 1.0
	toast("Cámara lenta " + ("activada" if slow else "desactivada"))


func toggle_freeze_all() -> void:
	all_frozen = not all_frozen
	for n in get_tree().get_nodes_in_group("props"):
		var rb := n as RigidBody3D
		if rb != null:
			rb.freeze = all_frozen
			if all_frozen:
				rb.linear_velocity = Vector3.ZERO
				rb.angular_velocity = Vector3.ZERO
	toast("Todo congelado" if all_frozen else "Todo descongelado")


# ================================================================ Guardado

func _v_to_arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _arr_to_v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


func save_scene() -> void:
	var data: Array = []
	for n in get_tree().get_nodes_in_group("props"):
		var rb := n as RigidBody3D
		if rb == null:
			continue
		var mi := rb.get_node("Mesh") as MeshInstance3D
		var mat := mi.material_override as StandardMaterial3D
		data.append({
			"kind": rb.get_meta("kind", "Caja"),
			"pos": _v_to_arr(rb.global_position),
			"rot": _v_to_arr(rb.rotation),
			"color": mat.albedo_color.to_html(false),
		})
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		toast("No se pudo guardar")
		return
	f.store_string(JSON.stringify(data))
	f.close()
	toast("Escena guardada (%d objetos)" % data.size())


func load_scene() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		toast("No hay escena guardada")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_ARRAY:
		toast("Archivo de guardado inválido")
		return

	clear_props()
	var count: int = 0
	for item in parsed:
		var d: Dictionary = item
		if not PROPS.has(d.kind):
			continue
		var p: Array = d.pos
		var r: Array = d.rot
		spawn_prop(d.kind, _arr_to_v(p), _arr_to_v(r), Color.html("#" + d.color), false)
		count += 1
	toast("Escena cargada (%d objetos)" % count)


# ================================================================ HUD

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# Mira con anillo
	var cross := Control.new()
	cross.set_anchors_preset(Control.PRESET_FULL_RECT)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross.draw.connect(_draw_crosshair.bind(cross))
	layer.add_child(cross)

	# Barra de herramientas
	hotbar = HBoxContainer.new()
	hotbar.add_theme_constant_override("separation", 8)
	hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 20)
	hotbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hotbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hotbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hotbar)
	for i in Player.TOOLS.size():
		var slot := PanelContainer.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := Label.new()
		l.text = "%d  %s" % [i + 1, Player.TOOLS[i]]
		slot.add_child(l)
		hotbar.add_child(slot)
		slot_panels.append(slot)

	# Panel de info
	var info_panel := PanelContainer.new()
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_theme_stylebox_override("panel", _panel_style(0.6, 14))
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 14)
	info_panel.add_child(info_label)
	layer.add_child(info_panel)
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)

	# Notificaciones
	toast_box = VBoxContainer.new()
	toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	toast_box.add_theme_constant_override("separation", 6)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(toast_box)
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 20)
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH

	# Ayuda
	help_panel = _make_overlay(layer)
	var hp := PanelContainer.new()
	hp.add_theme_stylebox_override("panel", _panel_style(0.95, 18))
	var help := Label.new()
	help.text = HELP_TEXT
	hp.add_child(help)
	help_panel.add_child(hp)

	# Menú de spawn
	menu_root = _make_overlay(layer)
	var mp := PanelContainer.new()
	mp.add_theme_stylebox_override("panel", _panel_style(0.95, 18))
	mp.custom_minimum_size = Vector2(640, 480)
	menu_root.add_child(mp)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	mp.add_child(col)

	var title := Label.new()
	title.text = "Spawn de objetos"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Buscar objeto..."
	search_box.text_changed.connect(_filter_grid)
	col.add_child(search_box)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for kind in PROPS:
		var btn := _make_button(kind, Color(0.12, 0.14, 0.2), Color(0.2, 0.7, 0.85))
		btn.pressed.connect(spawn_in_front.bind(kind))
		grid.add_child(btn)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var b_clear := _make_button("Limpiar todo", Color(0.35, 0.12, 0.12), Color(0.8, 0.25, 0.25))
	b_clear.pressed.connect(clear_props)
	var b_save := _make_button("Guardar", Color(0.12, 0.3, 0.2), Color(0.25, 0.75, 0.45))
	b_save.pressed.connect(save_scene)
	var b_load := _make_button("Cargar", Color(0.12, 0.2, 0.35), Color(0.3, 0.55, 0.9))
	b_load.pressed.connect(load_scene)
	for b in [b_clear, b_save, b_load]:
		(b as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)


func _make_overlay(layer: CanvasLayer) -> CenterContainer:
	var root := CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	layer.add_child(root)
	return root


func _make_button(text: String, base: Color, hover: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(190, 50)
	btn.add_theme_stylebox_override("normal", _button_style(base))
	btn.add_theme_stylebox_override("hover", _button_style(hover))
	btn.add_theme_stylebox_override("pressed", _button_style(hover.darkened(0.3)))
	btn.add_theme_stylebox_override("focus", _button_style(base))
	return btn


func _panel_style(alpha: float, radius: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11, alpha)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.08)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	return sb


func _button_style(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	return sb


func _slot_style(selected: bool) -> StyleBoxFlat:
	var sb := _panel_style(0.9 if selected else 0.6, 10)
	sb.set_content_margin_all(8)
	if selected:
		sb.bg_color = Color(0.25, 0.85, 0.95, 0.95)
	return sb


func _draw_crosshair(ctrl: Control) -> void:
	var c: Vector2 = ctrl.size / 2.0
	ctrl.draw_arc(c, 9.0, 0.0, TAU, 32, Color(1, 1, 1, 0.75), 1.5)
	ctrl.draw_circle(c, 2.0, Color(1, 1, 1, 0.95))


func _on_tool_changed(index: int) -> void:
	for i in slot_panels.size():
		var slot: PanelContainer = slot_panels[i]
		var sel: bool = i == index
		slot.add_theme_stylebox_override("panel", _slot_style(sel))
		var l := slot.get_child(0) as Label
		l.add_theme_color_override("font_color", Color.BLACK if sel else Color.WHITE)


func toast(msg: String) -> void:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _panel_style(0.85, 12))
	var l := Label.new()
	l.text = msg
	p.add_child(l)
	toast_box.add_child(p)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


func _filter_grid(text: String) -> void:
	var q: String = text.to_lower()
	for b in grid.get_children():
		var btn := b as Button
		btn.visible = q.is_empty() or btn.text.to_lower().contains(q)


func _process(delta: float) -> void:
	fps_clock += delta
	if fps_clock < 0.2:
		return
	fps_clock = 0.0

	var count: int = get_tree().get_nodes_in_group("props").size()
	var flags := PackedStringArray()
	if player.noclip:
		flags.append("NOCLIP")
	if not gravity_on:
		flags.append("SIN GRAVEDAD")
	if Engine.time_scale < 0.5:
		flags.append("CÁMARA LENTA")
	if all_frozen:
		flags.append("CONGELADO")

	var text: String = "FPS  %d\nObjetos  %d\nVelocidad  %.1f m/s" % [Engine.get_frames_per_second(), count, player.velocity.length()]
	if not flags.is_empty():
		text += "\n" + " · ".join(flags)
	info_label.text = text


# ================================================================ Input

func _toggle_menu() -> void:
	menu_root.visible = not menu_root.visible
	help_panel.visible = false
	search_box.clear()
	_filter_grid("")
	player.release()
	_sync_mouse()


func _close_panels() -> void:
	menu_root.visible = false
	help_panel.visible = false
	player.release()
	_sync_mouse()


func _sync_mouse() -> void:
	var overlay_open: bool = menu_root.visible or help_panel.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if overlay_open else Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not menu_root.visible and not help_panel.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	elif event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo:
			return
		if k.ctrl_pressed and k.keycode == KEY_S:
			save_scene()
			return
		if k.ctrl_pressed and k.keycode == KEY_L:
			load_scene()
			return
		match k.keycode:
			KEY_Q: _toggle_menu()
			KEY_H:
				help_panel.visible = not help_panel.visible
				menu_root.visible = false
				_sync_mouse()
			KEY_F: toggle_freeze_all()
			KEY_G: toggle_gravity()
			KEY_T: toggle_slow_mo()
			KEY_ESCAPE: _close_panels()
