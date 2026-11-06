class_name Sfx
## Efectos de sonido. Sfx.play("disparo") reproduce sounds/<archivo>.mp3 sin agregar nodos a la escena.

const FILES := {
	"disparo": "res://sounds/gunshot.mp3",
	"click": "res://sounds/select_buttonsfx.mp3",
	"hover": "res://sounds/select.mp3",
	"taser": "res://sounds/taser_1.mp3",
	"hurt": "res://sounds/hurt.mp3",
	"minigun": "res://sounds/minigun.mp3",
	"error": "res://sounds/failsfx.mp3",
	"unirse": "res://sounds/join_serversfx.mp3",
}

static var _cache: Dictionary = {}


static func play(key: String) -> void:
	if not FILES.has(key):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	if not _cache.has(key):
		_cache[key] = load(str(FILES[key]))
	var stream: AudioStream = _cache[key]
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.finished.connect(p.queue_free)
	tree.root.add_child(p)
	p.play()


## Reproduce un sonido repetido durante `seconds`. Vuelve a empezar cada vez que termina
## (no depende de la opción de bucle del archivo, que puede no estar activa).
static func loop_for(key: String, seconds: float) -> void:
	if not FILES.has(key):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	if not _cache.has(key):
		_cache[key] = load(str(FILES[key]))
	var stream: AudioStream = _cache[key]
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	tree.root.add_child(p)
	var t_end: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	p.finished.connect(func() -> void:
		if is_instance_valid(p) and Time.get_ticks_msec() < t_end:
			p.play()
		elif is_instance_valid(p):
			p.queue_free())
	p.play()
	tree.create_timer(seconds).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.stop()
			p.queue_free())
