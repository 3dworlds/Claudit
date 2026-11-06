class_name Controls
extends RefCounted
## Teclas personalizables. Cada acción tiene un número (índice) y una tecla por defecto.
## Se guardan en user://controls.json y se pueden cambiar desde Pausa → Controles.

const PATH := "user://controls.json"

## [nombre, tecla por defecto]. El índice es la posición en esta lista.
const ACTIONS: Array = [
	["Adelante", KEY_W], ["Atrás", KEY_S], ["Izquierda", KEY_A], ["Derecha", KEY_D],
	["Saltar / subir", KEY_SPACE], ["Bajar", KEY_C], ["Correr", KEY_SHIFT],
	["Noclip", KEY_N], ["Gancho", KEY_R], ["Sentarse", KEY_E], ["Freecam", KEY_K],
	["Menú de objetos", KEY_Q], ["Bloques", KEY_B], ["Mochila", KEY_M], ["Info (ayuda)", KEY_TAB],
	["Pausa", KEY_ESCAPE], ["Snap", KEY_X], ["Invencibles", KEY_I], ["Apoyar en el suelo", KEY_V],
	["Congelar todo", KEY_F], ["Gravedad", KEY_G], ["Cámara lenta", KEY_T], ["Probar construcción", KEY_L],
]

static var binds: Dictionary = {}


## Tecla actual de una acción.
static func k(i: int) -> int:
	return int(binds.get(i, ACTIONS[i][1]))


static func set_bind(i: int, key: int) -> void:
	binds[i] = key
	save()


static func reset() -> void:
	binds.clear()
	save()


static func label(i: int) -> String:
	return OS.get_keycode_string(k(i))


static func load_all() -> void:
	binds.clear()
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	for key in d.keys():
		var i: int = int(str(key))
		if i >= 0 and i < ACTIONS.size():
			binds[i] = int(d[key])


static func save() -> void:
	var d: Dictionary = {}
	for i in binds.keys():
		d[str(i)] = int(binds[i])
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
		f.close()
