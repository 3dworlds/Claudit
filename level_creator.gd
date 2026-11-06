class_name LevelCreator
extends RefCounted
## Creador de niveles: guarda lo que construiste (bloques, vehículos, objetos y mapa)
## como archivos de nivel en user://levels. Se carga con el mismo formato que la partida.

const DIR := "user://levels"


static func ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


## Ruta nueva para guardar un nivel (con fecha y hora, así se ordenan solos).
static func new_path() -> String:
	ensure_dir()
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	return "%s/nivel_%s.json" % [DIR, stamp]


## Ruta del nivel más reciente, o "" si no hay niveles guardados.
static func last_path() -> String:
	ensure_dir()
	var files: PackedStringArray = DirAccess.get_files_at(DIR)
	var levels: Array = []
	for f in files:
		if str(f).ends_with(".json"):
			levels.append(str(f))
	levels.sort()
	if levels.is_empty():
		return ""
	return DIR + "/" + str(levels[levels.size() - 1])
