class_name Settings
## Ajustes generales y de video. Se guardan en user://settings.json (junto con el idioma).

const PATH := "user://settings.json"
const RESOLUTIONS := [
	Vector2i(1280, 720), Vector2i(1280, 768), Vector2i(1360, 768), Vector2i(1366, 768),
	Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440),
]
const SHADERS := ["Ninguno", "Viñeta", "Retro", "Cálido", "Sepia", "Blanco y negro", "Pixelado", "Negativo", "Cómic", "Ruido de película", "Ondas", "Aberración cromática", "Brillo suave", "Alto contraste", "Glitch", "Bordes", "Vintage", "Neón", "Azul duotono", "Gamma alto", "Escaneo", "Viñeta fuerte", "Rojo cine", "Pastel"]
const DISPLAY_MODES := ["ventana", "completa", "sin_bordes"]
const GRAPHICS := ["Mínimo", "Ultra bajo", "Muy bajo", "Bajo", "Bajo+", "Bajo++", "Medio-", "Medio", "Medio+", "Alto-", "Alto", "Alto+", "Ultra", "RTX", "RTX+", "RTX Extremo", "RTX Ultra", "RTX Ultra+", "RTX Infinito", "RTX Dios", "RTX Cósmico", "RTX Quantum", "RTX Omega", "RTX Legendario", "RTX Mítico", "RTX Divino", "RTX Titan", "RTX Nova", "RTX Máximo", "RTX Absoluto"]

static var player_name: String = ""
static var first_run_done: bool = false
static var display_mode: String = "ventana"
static var resolution: Vector2i = Vector2i(1280, 720)
static var scale_pct: int = 100
static var shader_idx: int = 0
static var graphics_idx: int = 10
static var time_idx: int = 0
const TIMES := ["Día", "Atardecer", "Noche", "Amanecer", "Nublado"]
static var volume_pct: int = 100
static var sensitivity_pct: int = 100


static func load_all() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	player_name = str(d.get("name", ""))
	first_run_done = bool(d.get("first_run_done", false))
	display_mode = str(d.get("display", "ventana"))
	var r: Array = d.get("resolution", [1280, 720])
	if r.size() == 2:
		resolution = Vector2i(int(r[0]), int(r[1]))
	scale_pct = clampi(int(d.get("scale", 100)), 50, 100)
	shader_idx = clampi(int(d.get("shader", 0)), 0, SHADERS.size() - 1)
	graphics_idx = clampi(int(d.get("graphics", 10)), 0, GRAPHICS.size() - 1)
	time_idx = clampi(int(d.get("time", 0)), 0, TIMES.size() - 1)
	volume_pct = clampi(int(d.get("volume", 100)), 0, 100)
	sensitivity_pct = clampi(int(d.get("sens", 100)), 25, 300)


static func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"lang": Lang.current,
		"name": player_name,
		"first_run_done": first_run_done,
		"display": display_mode,
		"resolution": [resolution.x, resolution.y],
		"scale": scale_pct,
		"shader": shader_idx,
		"graphics": graphics_idx,
		"time": time_idx,
		"volume": volume_pct,
		"sens": sensitivity_pct,
	}))
	f.close()


## Aplica video y escala. En celular no hay ventana que cambiar.
static func apply() -> void:
	# Volumen general (afecta música y sonidos)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume_pct / 100.0)))
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.root.scaling_3d_scale = scale_pct / 100.0
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return
	match display_mode:
		"completa":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(resolution)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"sin_bordes":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(resolution)


## Etiqueta chica arriba a la derecha con la versión de la app (v + application/config/version).
static func version_badge() -> Control:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.9)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(4)
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = "v" + str(ProjectSettings.get_setting("application/config/version", ""))
	l.add_theme_font_size_override("font_size", 12)
	pc.add_child(l)
	pc.name = "VersionBadge"
	pc.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pc.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pc.offset_right = -8.0
	pc.offset_top = 8.0
	return pc

