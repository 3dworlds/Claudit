class_name Settings
## Ajustes generales y de video. Se guardan en user://settings.json (junto con el idioma).

const PATH := "user://settings.json"
const RESOLUTIONS := [
	Vector2i(1280, 720), Vector2i(1280, 768), Vector2i(1360, 768), Vector2i(1366, 768),
	Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440),
]
const SHADERS := ["Ninguno", "Viñeta", "Retro", "Cálido"]
const DISPLAY_MODES := ["ventana", "completa", "sin_bordes"]
const GRAPHICS := ["Bajo", "Medio", "Alto", "RTX (Ultra)"]

static var player_name: String = ""
static var first_run_done: bool = false
static var display_mode: String = "ventana"
static var resolution: Vector2i = Vector2i(1280, 720)
static var scale_pct: int = 100
static var shader_idx: int = 0
static var graphics_idx: int = 2
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
	graphics_idx = clampi(int(d.get("graphics", 2)), 0, GRAPHICS.size() - 1)
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
