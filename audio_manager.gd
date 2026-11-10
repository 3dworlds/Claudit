class_name AudioManager
extends Node
## Música: lee todos los .ogg, .mp3 y .wav de la carpeta res://music y los reproduce en bucle.
## Para agregar música, copiá los archivos a la carpeta "music" de tu proyecto (al lado de project.godot).

const MUSIC_DIR := "res://music"

var player: AudioStreamPlayer
var tracks: Array = []
var index: int = 0
var on: bool = true


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -8.0
	add_child(player)
	player.finished.connect(next)
	tracks = _scan()
	if tracks.size() > 0:
		_play(0)


func _scan() -> Array:
	var out: Array = []
	var d := DirAccess.open(MUSIC_DIR)
	if d == null:
		return out
	for f in d.get_files():
		var fname: String = str(f)
		if fname.ends_with(".ogg") or fname.ends_with(".mp3") or fname.ends_with(".wav"):
			out.append(MUSIC_DIR + "/" + fname)
	out.sort()
	return out


func _play(i: int) -> void:
	if tracks.is_empty():
		return
	index = wrapi(i, 0, tracks.size())
	var s := load(str(tracks[index])) as AudioStream
	if s == null:
		return
	player.stream = s
	if on:
		player.play()


func next() -> void:
	_play(index + 1)


func toggle() -> void:
	on = not on
	if on:
		_play(index)
	else:
		player.stop()


func now_playing() -> String:
	if tracks.is_empty():
		return "sin música (poné archivos en res://music)"
	return str(tracks[index]).get_file()
