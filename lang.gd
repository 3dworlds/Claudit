class_name Lang
## Idiomas de la interfaz. Español es el idioma original; English traduce menús, lobby,
## pausa y controles de celular. El idioma se guarda en user://settings.json y se aplica al iniciar el juego.

const PATH := "user://settings.json"
const LANGS := ["es", "en"]

static var current: String = "es"

const EN := {
	# Lobby
	"Un jugador": "Single player",
	"Multijugador": "Multiplayer",
	"Local": "Local",
	"Online": "Online",
	"Crear servidor local": "Create local server",
	"Crear servidor online": "Create online server",
	"Guardar servidor": "Save server",
	"Volver": "Back",
	"%s (UNIRSE)": "%s (JOIN)",
	"Controles táctiles: ": "Touch controls: ",
	"Dirección del servidor": "Server address",
	"Nombre del servidor (ej: ian server)": "Server name (e.g. my server)",
	"Servidores encontrados en tu red:": "Servers found on your network:",
	"Servidores guardados:": "Saved servers:",
	"Tu nombre (vacío = Jugador1, Jugador2...)": "Your name (empty = Player1, Player2...)",
	"Agregar un servidor (se guarda con su nombre):": "Add a server (saved with its name):",
	"(buscando servidores...)": "(searching for servers...)",
	"(todavía no guardaste ninguno)": "(you haven't saved any yet)",
	# Menú de pausa
	"Partida": "Game",
	"Mundo": "World",
	"Modos": "Modes",
	"Controles": "Controls",
	"Salir": "Quit",
	"Continuar": "Continue",
	"Guardar partida": "Save game",
	"Cargar partida": "Load game",
	"Guardar nivel": "Save level",
	"Cargar último nivel": "Load last level",
	"Personalizar (color y texturas)": "Customize (color and textures)",
	"Snap: siempre activo": "Snap: always on",
	"Enemigos invencibles (I)": "Invincible enemies (I)",
	"Apoyar en el suelo (V)": "Snap to ground (V)",
	"Freecam (K)": "Freecam (K)",
	"Sin gravedad (G)": "No gravity (G)",
	"Cámara lenta (T)": "Slow motion (T)",
	"Congelar todo (F)": "Freeze all (F)",
	"Música on/off": "Music on/off",
	"Siguiente canción": "Next song",
	"Restablecer teclas": "Reset keys",
	"Salir al menú": "Exit to menu",
	"Salir del juego": "Quit game",
	"Listo": "Done",
	# Controles de celular
	"Pausa": "Pause",
	"Ítem +": "Item +",
	"Ítem -": "Item -",
	"Noclip": "Noclip",
	"Saltar": "Jump",
	"Objetos": "Objects",
	"Ítems": "Items",
	"Gancho": "Hook",
	"Usar": "Use",
	"Disparar": "Shoot",
	"Click izq.": "Left click",
	"Click der.": "Right click",
	"Agachar": "Crouch",
	"Ver armas": "Weapons",
	"Más": "More",
	"Bloques": "Blocks",
	"Sentarse": "Sit",
	"Rotar bloque": "Rotate block",
	"Cámara lenta": "Slow motion",
	"Sin gravedad": "No gravity",
	"Congelar": "Freeze",
	"Snapping": "Snapping",
	"Probar": "Test",
	"Deshacer": "Undo",
	"Invencibles": "Invincible",
	"Apoyar": "Snap",
	"Personalizar": "Customize",
	"Ayuda": "Help",
	"Editar controles": "Edit controls",
	"Cerrar": "Close",
	"Arrastrá un botón. Tocalo para elegirlo.": "Drag a button. Tap it to select it.",
	"Tamaño +": "Size +",
	"Tamaño -": "Size -",
	"Color": "Color",
	"Transparencia": "Opacity",
	"Restablecer": "Reset",
	"Elegí un mapa": "Choose a map",
	"Elegí un mapa para empezar": "Choose a map to start",
	"Cancelar": "Cancel",
	"Opciones": "Options",
	"Empezar": "Start",
	"General": "General",
	"Video": "Video",
	"Modo de pantalla": "Display mode",
	"Resolución": "Resolution",
	"Escala de resolución": "Resolution scale",
	"Shader": "Shader",
	"Idioma": "Language",
	"Ventana": "Windowed",
	"Pantalla completa": "Fullscreen",
	"Pantalla completa sin bordes": "Borderless fullscreen",
	"Ninguno": "None",
	"Viñeta": "Vignette",
	"Retro": "Retro",
	"Cálido": "Warm",
	"El idioma se aplica al reiniciar el juego.": "Language applies when you restart the game.",
	"Calidad gráfica": "Graphics quality",
	"Bajo": "Low",
	"Medio": "Medium",
	"Alto": "High",
	"Volumen general": "Master volume",
	"Sensibilidad del mouse": "Mouse sensitivity",
	"¿Seguro que querés salir al menú?": "Are you sure you want to go back to the menu?",
	"¿Seguro que querés salir del juego?": "Are you sure you want to quit the game?",
	"Novedades": "What's new",
	"Editar controles táctiles": "Edit touch controls",
	"Calidad": "Quality",
	"Sepia": "Sepia",
	"Blanco y negro": "Black and white",
	"Pixelado": "Pixelated",
	"Negativo": "Negative",
	"Cómic": "Comic",
	"Ruido de película": "Film grain",
	"Ondas": "Waves",
	"Aberración cromática": "Chromatic aberration",
	"Brillo suave": "Soft glow",
	"Alto contraste": "High contrast",
	# Avisos del juego
	"Bloque rotado": "Block rotated",
	"Color copiado del bloque": "Block color copied",
	"Conduciendo: WASD, Espacio/C inclinan, click dispara cañones, E baja": "Driving: WASD, Space/C tilt, click fires cannons, E exits",
	"Escalar funciona con bloques de construcción": "Scaling works with building blocks",
	"Esta estructura no tiene asiento": "This structure has no seat",
	"Freecam apagada": "Freecam off",
	"Freecam: WASD mueve la cámara, flechas mueven a tu personaje": "Freecam: WASD moves the camera, arrows move your character",
	"Frená la estructura para editarla (Physgun, click derecho)": "Stop the structure to edit it (Physgun, right click)",
	"Gancho: no hay nada al alcance": "Hook: nothing in reach",
	"Noclip activado": "Noclip on",
	"Noclip desactivado": "Noclip off",
	"Solo los bloques cuadrados se pueden escalar": "Only square blocks can be scaled",
	"Te caíste al vacío: volviste al inicio": "You fell into the void: back to start",
	"Te eliminaron. Reapareciste": "You were eliminated. Respawned",
	"¡Ground slam!": "Ground slam!",
	"Archivo de guardado inválido": "Invalid save file",
	"Bloque: ": "Block: ",
	"Color elegido": "Color chosen",
	"Color guardado": "Color saved",
	"Conectado al servidor": "Connected to server",
	"Construcciones borradas": "Builds erased",
	"Creado: ": "Created: ",
	"Cámara lenta ": "Slow motion ",
	"El snap siempre está activo": "Snap is always on",
	"Enemigos invencibles: ": "Invincible enemies: ",
	"Esa estructura llegó al máximo de bloques": "That structure reached the block limit",
	"Escena limpia": "Scene cleared",
	"Gravedad ": "Gravity ",
	"Mapa: ": "Map: ",
	"Música: ": "Music: ",
	"NPC: ": "NPC: ",
	"Nivel guardado: ": "Level saved: ",
	"No hay partida guardada": "No saved game",
	"No se pudo guardar": "Couldn't save",
	"Objetos: ": "Objects: ",
	"Solo el host puede ": "Only the host can ",
	"Suena: ": "Sound: ",
	"Tecla guardada: ": "Key saved: ",
	"Teclas restablecidas": "Keys reset",
	"Textura: ": "Texture: ",
	"Todavía no hay niveles guardados": "No levels saved yet",
	"Todo congelado": "Everything frozen",
	"Ítem: ": "Item: ",
	"▶ Prueba iniciada: sentate (E) y conducí": "▶ Test started: sit (E) and drive",
}


## Carga el idioma guardado (llamar al iniciar).
static func load_lang() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		var l: String = str((parsed as Dictionary).get("lang", "es"))
		if LANGS.has(l):
			current = l


static func save_lang() -> void:
	Settings.save()


## Traduce un texto en español al idioma actual. Si no hay traducción, devuelve el original.
static func t(s: String) -> String:
	if current != "en":
		return s
	if EN.has(s):
		return str(EN[s])
	# Textos armados con concatenación ("Bloque: " + nombre): traduce solo el prefijo
	for k in EN.keys():
		var key: String = str(k)
		if (key.ends_with(": ") or key.ends_with(" ")) and s.begins_with(key):
			return str(EN[k]) + s.substr(key.length())
	return s


## Cambia al siguiente idioma y lo guarda.
static func cycle() -> void:
	var i: int = LANGS.find(current)
	current = str(LANGS[(i + 1) % LANGS.size()])
	save_lang()


## Texto del botón de idioma (siempre visible en su propio idioma).
static func name_label() -> String:
	return "Idioma: Español" if current == "es" else "Language: English"
