extends Node3D
## Sandbox estilo Garry's Mod: multijugador, mapas, pausa, snapping, armas, efectos y guardado.
## Adjuntá este script a un Node3D raíz. El host es autoritativo: la física corre en el servidor.

const PORT := 7777
const HOTKEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="]
const PALETTE := ["ffffff", "d9d9d9", "7f7f7f", "3f3f3f", "000000", "8b5a2b", "c8a064", "f2d9a0",
	"ff3b30", "ff9500", "ffcc00", "a6e22e", "34c759", "00c7be", "30b0ff", "0a60ff",
	"5e5ce6", "bf5af2", "ff2d55", "ff7a9c", "6b8e4e", "1f6f50", "3a2a1a", "7a4a2a"]
## Textura y color del suelo según el mapa (los demás usan la grilla)
const GROUND := {
	"Desierto": ["sand", "e0c27a"], "Nieve": ["ice", "e8f4ff"], "Volcán": ["stone", "4a3a34"],
	"Ciudad": ["carbon", "6a6b70"], "Aeropuerto": ["stone", "77777a"], "Parque skate": ["stone", "999999"],
	"Rascacielos": ["stone", "808085"], "Lago": ["sand", "c2b280"], "Isla": ["sand", "c2b280"],
	"Puerto": ["sand", "c2b280"], "Pista": ["carbon", "5a5a60"], "Cañón": ["stone", "8a7a6a"],
	"Colinas": ["grass", "6b8e4e"], "Espiral": ["grass", "6b8e4e"], "Puente": ["grass", "6b8e4e"],
}
const SAVE_PATH := "user://sandbox_save.json"
const HELP_TEXT := "CONTROLES\n\nWASD mover · Shift correr · Espacio saltar · N noclip\n1-9, 0, -, = o rueda: elegir ítem de la barra · Click izq: usar · Click der: función secundaria\nTab: mochila (equipá herramientas y armas en la ranura elegida)\nR: gancho whiplash (tira objetos livianos y NPCs hacia vos; te tira a vos hacia lo pesado)\nE: sentarte/bajarte de un vehículo · WASD conducir · Espacio/C inclinar · click: cañones\n\nQ objetos (elegís qué spawnear, se coloca con la herramienta Spawn) · B bloques y colores\nZ gira el bloque fantasma (Shift+Z lo inclina) · L probar construcción · Ctrl+Z deshacer\nX snapping · F congelar todo (host) · G gravedad (host) · T cámara lenta\nCtrl+S / Ctrl+L guardar y cargar (host) · Esc pausa · H ayuda"

var PROPS: Dictionary = Content.props().merged(ContentExtra.props()).merged(ContentMore.props())
var MAPS: Array = Content.maps() + ContentExtra.maps() + ContentMore.maps()
var WEAPONS: Array = Content.weapons() + ContentExtra.weapons() + ContentMore.weapons()

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

var online: bool = false
var touch: bool = false
var map_index: int = 1
var snap_enabled: bool = true
var god_npcs: bool = false
var ground_snap: bool = true
var rebinding: int = -1
var controls_btns: Array = []
var local_player: Player = null
var players: Dictionary = {}      # peer_id -> Player
var props: Dictionary = {}        # pid -> RigidBody3D (en todos los peers)
var next_pid: int = 1
var hold_targets: Dictionary = {} # peer_id -> {"pid": int, "target": Vector3} (solo servidor)
var gravity_on: bool = true
var all_frozen: bool = false
var sync_clock: float = 0.0
var fps_clock: float = 0.0

var hud_layer: CanvasLayer
var lobby_root: Control
var pause_root: Control
var pause_players: Label
var snap_btn: Button
var menu_root: Control
var help_panel: Control
var ip_box: LineEdit
var touch_btn: Button
var search_box: LineEdit
var grid: GridContainer
var slot_panels: Array[PanelContainer] = []
var info_label: Label
var hp_bar: ProgressBar
var armor_bar: ProgressBar
var chat_log: RichTextLabel
var chat_input: LineEdit
var chat_open: bool = false
var options_menu: OptionsMenu
var post_rect: ColorRect
var world_env: WorldEnvironment
var sky_mat: ProceduralSkyMaterial
var sun_node: DirectionalLight3D
var _chat_lines: Array = []
var toast_box: VBoxContainer
var touch_ui: TouchUI
var builder: Builder
var npcs: NpcManager
var lan: Lan
var lobby: LobbyUI
var local_name: String = ""
var water_level: float = -100000.0
var selected_prop: String = "Caja"
var center_mode: bool = false
var audio: AudioManager = null
var body_color: Color = Color(0, 0, 0, 0)
var custom_root: Control
var tex_pick: OptionButton
const PREFS_PATH := "user://prefs.json"
var selected_vehicle: bool = false
var selected_cat: String = "Básicos"
var selected_label: Label
var build_root: Control
var build_info: Label
var pack_root: Control
var pack_info: Label
var connecting: bool = false
var hosting_lan: bool = false
var lan_clock: float = 0.0
var _connect_attempt: int = 0


func _ready() -> void:
	Settings.load_all()
	Settings.apply()
	Lang.load_lang()
	get_tree().set_auto_accept_quit(false)  # el botón atrás y el cierre los maneja _notification
	touch = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

	builder = Builder.new()
	builder.name = "Builder"
	builder.world = self
	add_child(builder)
	npcs = NpcManager.new()
	npcs.name = "Npcs"
	npcs.world = self
	add_child(npcs)
	lan = Lan.new()
	lan.name = "Lan"
	add_child(lan)

	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	audio = AudioManager.new()
	add_child(audio)
	_build_env()
	_build_map(map_index)
	_build_hud()
	_build_buildmenu()
	_build_pack()
	Controls.load_all()
	_build_pause()
	_load_prefs()
	_build_customize()
	_build_lobby()
	_build_options()
	_build_post()

	touch_ui = TouchUI.new()
	touch_ui.visible = false
	touch_ui.action.connect(_on_touch_action)
	add_child(touch_ui)

	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	get_viewport().size_changed.connect(_fit_overlays)
	_fit_overlays()
	multiplayer.connection_failed.connect(_on_connection_failed)
	_sync_mouse()


# ================================================================ Lobby y red

func _build_lobby() -> void:
	var l := LobbyUI.new()
	l.lan = lan
	l.touch = touch
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(l)
	lobby = l
	lobby_root = l
	l.single_requested.connect(_start_local)
	l.options_requested.connect(_open_options)
	l.quit_requested.connect(_ask.bind("¿Seguro que querés salir del juego?", _quit_game))
	l.host_requested.connect(_host)
	l.join_requested.connect(_join)
	l.touch_toggled.connect(_toggle_touch)


func _toggle_touch() -> void:
	# En celular los controles táctiles siempre están activos (si se apagaban, cualquier toque disparaba)
	touch = true if OS.has_feature("mobile") else not touch
	lobby.set_touch(touch)


func _server_name() -> String:
	return "%s server" % local_name


func _lan_info() -> Dictionary:
	return {"name": _server_name(), "port": PORT, "players": players.size(), "map": str(MAPS[map_index]["name"])}


func _name_taken(n: String) -> bool:
	for pid in players:
		var p: Player = players[pid]
		if p.display_name == n:
			return true
	return false


## Sin nombre -> Jugador1, Jugador2... según cuántos "Jugador" ya haya. Nombres repetidos -> ian2, ian3...
func _resolve_name(pname: String) -> String:
	var n: String = pname.strip_edges()
	if n == "":
		var count: int = 1
		for pid in players:
			var p: Player = players[pid]
			if p.display_name.begins_with("Jugador"):
				count += 1
		n = "Jugador%d" % count
	var base: String = n
	var i: int = 2
	while _name_taken(n):
		n = "%s%d" % [base, i]
		i += 1
	return n


## Carga el mapa que eligió el jugador en el lobby.
func _apply_picked_map() -> void:
	if MapPick.index != map_index:
		_build_map(MapPick.index)


func _start_local(pname: String) -> void:
	_apply_picked_map()
	online = false
	local_name = _resolve_name(pname)
	_create_player(1, local_name)
	_hide_lobby()
	toast("Hola, %s" % local_name)


func _host(pname: String, as_online: bool) -> void:
	_apply_picked_map()
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(PORT) != OK:
		lobby.show_error("No se pudo crear el servidor: el puerto %d está ocupado. ¿Ya tenés otro servidor abierto en esta PC?" % PORT)
		return
	multiplayer.multiplayer_peer = peer
	online = true
	local_name = _resolve_name(pname)
	_create_player(1, local_name)
	_hide_lobby()
	if as_online:
		toast("Servidor online abierto (UDP %d). Abrí ese puerto en tu router para que entren desde internet." % PORT)
	else:
		hosting_lan = true
		lan.start_broadcast(_lan_info())
		toast("%s abierto en tu red local" % _server_name())


func _join(pname: String, address: String, port: int) -> void:
	if connecting:
		return
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(address, port) != OK:
		lobby.show_error("No se pudo conectar a «%s»: la dirección no es válida." % address)
		return
	multiplayer.multiplayer_peer = peer
	online = true
	connecting = true
	local_name = pname
	lobby.show_info("Conectando a %s ..." % address)
	_connect_attempt += 1
	get_tree().create_timer(8.0).timeout.connect(_connect_timeout.bind(_connect_attempt, address))


func _connect_timeout(attempt: int, address: String) -> void:
	if connecting and attempt == _connect_attempt:
		_fail_connect("Este servidor no existe o no responde (%s)." % address)


func _fail_connect(msg: String) -> void:
	connecting = false
	online = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	lobby.show_error(msg)


func _on_connection_failed() -> void:
	if connecting:
		_fail_connect("Este servidor no existe o no responde.")


func _on_connected_to_server() -> void:
	connecting = false
	lobby.clear_info()
	_hide_lobby()
	toast("Conectado al servidor")
	_req_register.rpc_id(1, local_name)


func _on_server_disconnected() -> void:
	if connecting:
		_fail_connect("Este servidor no existe o no responde.")
		return
	if not online:
		return
	back_to_lobby()
	lobby.show_error("Se cortó la conexión con el servidor.")


## Un cliente avisa que está listo (con su nombre): el servidor le manda el estado del mundo.
@rpc("any_peer", "reliable")
func _req_register(pname: String) -> void:
	if not _is_host():
		return
	_welcome(multiplayer.get_remote_sender_id(), pname)


func _welcome(id: int, pname: String) -> void:
	var final_name: String = _resolve_name(pname)
	_set_map.rpc_id(id, map_index)
	for pid in props:
		var body: RigidBody3D = props[pid]
		if is_instance_valid(body) and not body.has_meta("structure"):
			_client_spawn.rpc_id(id, body.get_meta("kind"), body.position, body.rotation, _prop_color(body), pid)
	builder.send_state(id)
	npcs.send_state(id)
	for other in players:
		var op: Player = players[other]
		_spawn_player.rpc_id(id, other, op.display_name)
	_spawn_player.rpc(id, final_name)
	_create_player(id, final_name)
	_announce.rpc_id(id, "Bienvenido a %s" % _server_name())
	for other2 in players:
		if other2 != 1 and other2 != id:
			_announce.rpc_id(other2, "%s se unió al servidor" % final_name)
	toast("%s se unió a tu servidor" % final_name)


## Servidor -> clientes: crear el jugador de otro peer.
@rpc("authority", "reliable")
func _spawn_player(pid: int, pname: String) -> void:
	_create_player(pid, pname)


@rpc("authority", "reliable")
func _drop_player(pid: int) -> void:
	_remove_player(pid)


@rpc("authority", "reliable")
func _announce(msg: String) -> void:
	toast(msg)


func _on_peer_disconnected(id: int) -> void:
	if not online or not _is_host():
		return
	var who: String = "Un jugador"
	if players.has(id):
		var gone: Player = players[id]
		who = gone.display_name
	hold_targets.erase(id)
	_remove_player(id)
	_drop_player.rpc(id)
	toast("%s salió del servidor" % who)
	_announce.rpc("%s salió del servidor" % who)


func _create_player(pid: int, pname: String = "") -> void:
	if players.has(pid):
		return
	var p := Player.new()
	p.name = str(pid)
	p.set_multiplayer_authority(pid)
	p.world = self
	p.touch_mode = touch
	p.display_name = pname
	p.body_color = body_color
	p.position = _spawn_point()
	add_child(p)
	players[pid] = p
	if pid == multiplayer.get_unique_id():
		local_player = p
		p.tool_changed.connect(_on_tool_changed)
		p.hotbar_changed.connect(_refresh_hotbar)
		p.notify.connect(toast)
		_refresh_hotbar()
		_on_tool_changed(0)
		touch_ui.player = p
		touch_ui.visible = touch
		_sync_mouse()


func _remove_player(pid: int) -> void:
	if not players.has(pid):
		return
	var p: Player = players[pid]
	players.erase(pid)
	if p == local_player:
		local_player = null
	p.queue_free()


func _spawn_point() -> Vector3:
	var base: Vector3 = MAPS[map_index]["spawn"]
	return base + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))


func _hide_lobby() -> void:
	lan.stop_listening()
	lobby_root.visible = false
	_sync_mouse()


## Vuelve al lobby: cierra la conexión y borra jugadores y props locales.
func back_to_lobby() -> void:
	online = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	for pid in players:
		var p: Player = players[pid]
		p.queue_free()
	players.clear()
	local_player = null
	for pid in props:
		var body: RigidBody3D = props[pid]
		if is_instance_valid(body):
			body.queue_free()
	props.clear()
	hold_targets.clear()
	npcs.clear_local()
	builder.on_cleared()
	lan.stop_broadcast()
	hosting_lan = false
	connecting = false
	touch_ui.player = null
	touch_ui.visible = false
	pause_root.visible = false
	menu_root.visible = false
	help_panel.visible = false
	build_root.visible = false
	pack_root.visible = false
	lobby_root.visible = true
	_sync_mouse()


# ================================================================ Entorno y mapas

func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	var skym := ProceduralSkyMaterial.new()
	skym.sky_top_color = Color(0.12, 0.05, 0.25)
	skym.sky_horizon_color = Color(0.95, 0.4, 0.45)
	skym.ground_horizon_color = Color(0.95, 0.4, 0.45)
	skym.ground_bottom_color = Color(0.1, 0.05, 0.12)
	env.sky.sky_material = skym
	sky_mat = skym
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_density = 0.003
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	world_env = we
	_apply_graphics()

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.1
	sun_node = sun
	sun.shadow_enabled = true
	add_child(sun)
	# Luz de relleno desde el otro lado, sin sombras, para que no quede todo oscuro
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 150, 0)
	fill.light_energy = 0.5
	fill.shadow_enabled = false
	add_child(fill)


## Reconstruye el piso y las cajas del mapa. Borra el mapa anterior.
func _build_map(idx: int) -> void:
	for n in get_tree().get_nodes_in_group("map"):
		n.queue_free()
	map_index = idx
	var m: Dictionary = MAPS[idx]

	var fy: float = float(m.get("floor_y", 0.0))
	water_level = float(m.get("water", -100000.0))
	var g: Array = GROUND.get(str(m["name"]), ["grid", "93a393"])
	_static_box(Vector3(300, 1, 300), Vector3(0, fy - 0.5, 0), Vector3.ZERO, Color.html("#" + str(g[1])), str(g[0]))

	for b in m["boxes"]:
		var d: Dictionary = b
		_static_box(d["size"], d["pos"], d["rot"], Color.html("#" + d["color"]), str(d.get("tex", "")))

	if water_level > -1000.0:
		_make_water()


func _static_box(size: Vector3, pos: Vector3, rot_deg: Vector3, color: Color = Color.WHITE, tex: String = "") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.add_to_group("map")
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	Textures.apply(mat, tex, 0.25)
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


## Solo el host. Cambia de mapa, borra los props y manda el cambio a los clientes.
func change_map(idx: int) -> void:
	if not _is_host():
		toast("Solo el host puede cambiar de mapa")
		return
	clear_props()
	_build_map(idx)
	if multiplayer.get_peers().size() > 0:
		_set_map.rpc(idx)
	if local_player != null:
		local_player.global_position = _spawn_point()
		local_player.velocity = Vector3.ZERO
	toast("Mapa: " + MAPS[idx]["name"])


@rpc("authority", "reliable")
func _set_map(idx: int) -> void:
	_build_map(idx)
	if local_player != null:
		local_player.global_position = _spawn_point()
		local_player.velocity = Vector3.ZERO


# ================================================================ Props

## Crea el nodo visual y físico de un prop. Lo usan el servidor y los clientes.
func _build_prop(kind: String, color: Color) -> RigidBody3D:
	var cfg: Dictionary = PROPS[kind]
	if str(cfg["shape"]) == "compound":
		return _build_compound(kind, color, cfg)
	var size: Vector3 = cfg["size"]
	var mesh: Mesh
	var shape: Shape3D

	match cfg["shape"]:
		"box":
			var m := BoxMesh.new()
			m.size = size
			mesh = m
			var s := BoxShape3D.new()
			s.size = size
			shape = s
		"sphere":
			var m := SphereMesh.new()
			m.radial_segments = 8
			m.rings = 4
			m.radius = size.x
			m.height = size.x * 2.0
			mesh = m
			var s := SphereShape3D.new()
			s.radius = size.x
			shape = s
		"capsule":
			var m := CapsuleMesh.new()
			m.radial_segments = 6
			m.rings = 2
			m.radius = size.x
			m.height = size.y
			mesh = m
			var s := CapsuleShape3D.new()
			s.radius = size.x
			s.height = size.y
			shape = s
		"cone":
			var m := CylinderMesh.new()
			m.radial_segments = 6
			m.rings = 1
			m.top_radius = 0.0
			m.bottom_radius = size.x
			m.height = size.y
			mesh = m
			var s := CylinderShape3D.new()
			s.radius = size.x
			s.height = size.y
			shape = s
		"cylinder":
			var m := CylinderMesh.new()
			m.radial_segments = 6
			m.rings = 1
			m.top_radius = size.x
			m.bottom_radius = size.x
			m.height = size.y
			mesh = m
			var s := CylinderShape3D.new()
			s.radius = size.x
			s.height = size.y
			shape = s

	var body := RigidBody3D.new()
	body.mass = cfg["mass"]
	body.add_to_group("props")
	body.set_meta("kind", kind)
	if cfg.has("explosive"):
		body.set_meta("explosive", true)
	if cfg.has("bounce"):
		var pm := PhysicsMaterial.new()
		pm.bounce = cfg["bounce"]
		body.physics_material_override = pm

	var mat := StandardMaterial3D.new()
	mat.roughness = 0.6
	Textures.apply(mat, Textures.pick(str(cfg.get("tex", "")), str(cfg["shape"])))
	if color.a > 0.0:
		mat.albedo_color = color
	elif cfg.has("color"):
		mat.albedo_color = Color.html("#" + cfg["color"])
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
	return body


## Solo el servidor. Crea el prop y lo replica a los clientes.
func spawn_prop(kind: String, pos: Vector3, rot: Vector3 = Vector3.ZERO, color: Color = Color(0, 0, 0, 0), puff: bool = true) -> RigidBody3D:
	var body := _build_prop(kind, color)
	var pid: int = next_pid
	next_pid += 1
	body.name = "P%d" % pid
	body.set_meta("pid", pid)
	body.gravity_scale = 1.0 if gravity_on else 0.0
	body.freeze = all_frozen or puff
	props[pid] = body
	add_child(body)
	body.global_transform = Transform3D(Basis.from_euler(rot), pos)
	if puff and not all_frozen:
		get_tree().create_timer(0.5).timeout.connect(_release_spawn.bind(body))
	if multiplayer.get_peers().size() > 0:
		_client_spawn.rpc(kind, pos, rot, _prop_color(body), pid)
	if puff:
		burst(pos, Color(0.85, 0.85, 0.85), 14)
	return body


@rpc("authority", "reliable")
func _client_spawn(kind: String, pos: Vector3, rot: Vector3, color: Color, pid: int) -> void:
	if props.has(pid):
		return
	var body := _build_prop(kind, color)
	body.name = "P%d" % pid
	body.set_meta("pid", pid)
	body.freeze = true
	body.gravity_scale = 0.0
	props[pid] = body
	add_child(body)
	body.global_transform = Transform3D(Basis.from_euler(rot), pos)


func request_spawn(kind: String, pos: Vector3, rot: Vector3) -> void:
	if _is_host():
		spawn_prop(kind, pos, rot)
	else:
		_req_spawn.rpc_id(1, kind, pos, rot)


@rpc("any_peer", "reliable")
func _req_spawn(kind: String, pos: Vector3, rot: Vector3) -> void:
	spawn_prop(kind, pos, rot)


func remove_prop(body: RigidBody3D) -> void:
	var pid: int = body.get_meta("pid", -1)
	if _is_explosive(body):
		explode(body.global_position, 7.0, 45.0)
	props.erase(pid)
	body.queue_free()
	if multiplayer.get_peers().size() > 0:
		_client_remove.rpc(pid)


@rpc("authority", "reliable")
func _client_remove(pid: int) -> void:
	var body: RigidBody3D = props.get(pid, null)
	props.erase(pid)
	if is_instance_valid(body):
		body.queue_free()


func clone_prop(body: RigidBody3D) -> void:
	var kind: String = body.get_meta("kind", "Caja")
	var offset := Vector3(randf_range(-1.5, 1.5), 1.5, randf_range(-1.5, 1.5))
	spawn_prop(kind, body.global_position + offset, body.rotation, _prop_color(body))


func paint_prop(body: RigidBody3D) -> void:
	var c: Color = _random_color()
	_set_prop_color(body, c)
	burst(body.global_position, c, 20)
	var pid: int = body.get_meta("pid", -1)
	if multiplayer.get_peers().size() > 0:
		_client_paint.rpc(pid, c)


@rpc("authority", "reliable")
func _client_paint(pid: int, c: Color) -> void:
	var body: RigidBody3D = props.get(pid, null)
	if is_instance_valid(body):
		_set_prop_color(body, c)


func _set_prop_color(body: RigidBody3D, c: Color) -> void:
	var mi := body.get_node("Mesh") as MeshInstance3D
	var mat := mi.material_override as StandardMaterial3D
	mat.albedo_color = c


func _prop_color(body: RigidBody3D) -> Color:
	var mi := body.get_node("Mesh") as MeshInstance3D
	var mat := mi.material_override as StandardMaterial3D
	return mat.albedo_color


func _release_spawn(body: RigidBody3D) -> void:
	if is_instance_valid(body) and not all_frozen:
		body.freeze = false


func _is_explosive(body: RigidBody3D) -> bool:
	return body.has_meta("explosive") and bool(body.get_meta("explosive"))


func _random_color() -> Color:
	return Color.from_hsv(randf(), 0.6, 0.9)


func get_prop(pid: int) -> RigidBody3D:
	return props.get(pid, null)


func clear_props() -> void:
	for pid in props.keys():
		var body: RigidBody3D = props[pid]
		if is_instance_valid(body):
			body.queue_free()
		if multiplayer.get_peers().size() > 0:
			_client_remove.rpc(pid)
	props.clear()
	hold_targets.clear()
	npcs.clear_all()
	builder.on_cleared()
	if local_player != null:
		local_player.release()


func request_clear() -> void:
	if _is_host():
		clear_props()
		toast("Escena limpia")
	else:
		_req_clear.rpc_id(1)


@rpc("any_peer", "reliable")
func _req_clear() -> void:
	clear_props()


# ================================================================ Snapping

func toggle_god_npcs() -> void:
	god_npcs = not god_npcs
	toast("Enemigos invencibles: " + ("sí" if god_npcs else "no"))


func toggle_ground_snap() -> void:
	ground_snap = not ground_snap
	toast("Objetos: " + ("apoyados en el suelo" if ground_snap else "centrados en la mira"))


func toggle_snap() -> void:
	snap_enabled = true
	if snap_btn != null:
		snap_btn.text = "Snap: siempre activo"
	toast("El snap siempre está activo")


func snap_vec(p: Vector3) -> Vector3:
	return Vector3(snappedf(p.x, 0.5), snappedf(p.y, 0.5), snappedf(p.z, 0.5))


func snap_yaw(r: Vector3) -> Vector3:
	return Vector3(r.x, snappedf(r.y, deg_to_rad(45.0)), r.z)


## Al soltar un prop con el Physgun (con snapping activo) lo alinea a la grilla.
func request_snap(pid: int) -> void:
	if _is_host():
		server_snap(pid)
	else:
		_req_snap.rpc_id(1, pid)


@rpc("any_peer", "reliable")
func _req_snap(pid: int) -> void:
	server_snap(pid)


func server_snap(pid: int) -> void:
	var body: RigidBody3D = props.get(pid, null)
	if not is_instance_valid(body):
		return
	for peer in hold_targets.keys():
		if hold_targets[peer]["pid"] == pid:
			hold_targets.erase(peer)
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.global_position = snap_vec(body.global_position)
	body.rotation = snap_yaw(body.rotation)


# ================================================================ Acciones de herramientas

## Lo llama el jugador. En clientes lo manda al servidor.
func request_act(tool: int, pid: int, pos: Vector3, dir: Vector3) -> void:
	if _is_host():
		server_act(tool, pid, pos, dir)
	else:
		_req_act.rpc_id(1, tool, pid, pos, dir)


@rpc("any_peer", "reliable")
func _req_act(tool: int, pid: int, pos: Vector3, dir: Vector3) -> void:
	server_act(tool, pid, pos, dir)


func server_act(tool: int, pid: int, pos: Vector3, dir: Vector3) -> void:
	if tool == 12:
		if npcs.npcs.has(pid):
			npcs.kill(pid)
		return
	if tool == 3:
		explode(pos, 6.0, 40.0)
		return
	if tool == 10:
		pull_props(pos)
		return
	if tool == 11:
		blow_props(pos, dir)
		return
	var body: RigidBody3D = props.get(pid, null)
	if not is_instance_valid(body):
		return
	match tool:
		1:
			remove_prop(body)
		2:
			body.apply_impulse(dir * 12.0 * body.mass, pos - body.global_position)
		4:
			clone_prop(body)
		5:
			paint_prop(body)
		7:
			body.rotation.y += deg_to_rad(45.0)
		8:
			body.mass = minf(body.mass * 2.0, 500.0)
		9:
			server_freeze(pid)
		13:
			var lev: bool = not bool(body.get_meta("levitate", false))
			body.set_meta("levitate", lev)
			body.gravity_scale = 0.0 if lev else (1.0 if gravity_on else 0.0)
		14:
			body.freeze = false
			body.linear_velocity = (pos - body.global_position).normalized() * 30.0 + Vector3.UP * 3.0


# ---------------------------------------------------------------- Physgun

func request_hold(pid: int, target: Vector3, kind: String = "prop") -> void:
	if _is_host():
		server_hold(1, pid, target, kind)
	else:
		_req_hold.rpc_id(1, pid, target, kind)


@rpc("any_peer", "unreliable")
func _req_hold(pid: int, target: Vector3, kind: String) -> void:
	server_hold(multiplayer.get_remote_sender_id(), pid, target, kind)


func server_hold(peer: int, pid: int, target: Vector3, kind: String = "prop") -> void:
	if pid < 0:
		hold_targets.erase(peer)
		return
	hold_targets[peer] = {"pid": pid, "target": target, "kind": kind}


func _apply_holds() -> void:
	for peer in hold_targets:
		var h: Dictionary = hold_targets[peer]
		var kind: String = str(h.get("kind", "prop"))
		if kind == "npc":
			var n: NPC = npcs.npcs.get(h["pid"], null)
			if is_instance_valid(n):
				n.held_until = Time.get_ticks_msec() + 150
				# Sigue el punto de agarre directamente (se mueve siempre, sin salir volando)
				n.velocity = Vector3.ZERO
				n.global_position = n.global_position.lerp(h["target"], 0.2)
			continue
		if kind == "player":
			var pl: Player = players.get(h["pid"], null)
			if is_instance_valid(pl):
				var step: Vector3 = pl.global_position.lerp(h["target"], 0.2)
				var owner_id: int = pl.get_multiplayer_authority()
				if owner_id == multiplayer.get_unique_id():
					pl.receive_pull_pos(step)
				else:
					pl.rpc_id(owner_id, "receive_pull_pos", step)
			continue
		var body: RigidBody3D = props.get(h["pid"], null)
		if not is_instance_valid(body):
			continue
		body.freeze = false
		body.linear_velocity = (h["target"] - body.global_position) * 12.0
		body.angular_velocity *= 0.9


func request_freeze(pid: int) -> void:
	if _is_host():
		server_freeze(pid)
	else:
		_req_freeze.rpc_id(1, pid)


@rpc("any_peer", "reliable")
func _req_freeze(pid: int) -> void:
	server_freeze(pid)


func server_freeze(pid: int) -> void:
	var body: RigidBody3D = props.get(pid, null)
	if not is_instance_valid(body):
		return
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.freeze = true
	for peer in hold_targets.keys():
		if hold_targets[peer]["pid"] == pid:
			hold_targets.erase(peer)


# ---------------------------------------------------------------- Armas

func request_shoot(origin: Vector3, dir: Vector3, weapon: int) -> void:
	if _is_host():
		server_shoot(1, origin, dir, weapon)
	else:
		_req_shoot.rpc_id(1, origin, dir, weapon)


@rpc("any_peer", "reliable")
func _req_shoot(origin: Vector3, dir: Vector3, weapon: int) -> void:
	server_shoot(multiplayer.get_remote_sender_id(), origin, dir, weapon)


func server_shoot(shooter: int, origin: Vector3, dir: Vector3, weapon: int) -> void:
	var w: Dictionary = WEAPONS[clampi(weapon, 0, WEAPONS.size() - 1)]
	var sp: Player = players.get(shooter, null)
	var pellets: int = int(w.get("pellets", 1))
	var spread: float = float(w.get("spread", 0.0))
	var range_m: float = float(w.get("range", 200.0))
	var dmg: float = float(w.get("dmg", 0.0))
	var knock: float = float(w.get("knock", 8.0))
	var stun_s: float = float(w.get("stun", 0.0))
	var freezes: bool = bool(w.get("freeze", false))
	var color: Color = Color.html("#" + str(w.get("color", "ffd055")))
	var ends := PackedVector3Array()
	burst(origin + dir * 0.6, color, 6)
	var blast_pos: Vector3 = Vector3.ZERO
	var got_hit: bool = false

	for i in pellets:
		var d: Vector3 = _spread_dir(dir, spread)
		var far: Vector3 = origin + d * range_m
		var query := PhysicsRayQueryParameters3D.create(origin, far)
		if sp != null:
			query.exclude = [sp.get_rid()]
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		var end: Vector3 = far
		if not hit.is_empty():
			end = hit.get("position", far)
			if not got_hit:
				got_hit = true
				blast_pos = end
			var col: Object = hit.get("collider")
			if col is Player:
				_damage_player(col as Player, dmg)
				if stun_s > 0.0:
					_stun_player(col as Player, stun_s)
			elif col is NPC:
				var npc := col as NPC
				npc.take_damage(dmg, d * knock * 0.4)
				if stun_s > 0.0:
					npc.stun(stun_s)
			elif col is RigidBody3D:
				var rb := col as RigidBody3D
				rb.apply_central_impulse(d * knock * rb.mass)
				if freezes and rb.has_meta("pid"):
					server_freeze(int(rb.get_meta("pid")))
		ends.append(end)
		if not hit.is_empty():
			burst(end, color, 10)

	var blast: float = float(w.get("blast", 0.0))
	if blast > 0.0 and got_hit:
		explode(blast_pos, blast, 35.0)

	for e in ends:
		draw_beam(origin, e, color)
	if multiplayer.get_peers().size() > 0:
		_fx_beams.rpc(origin, ends, color)


func _spread_dir(dir: Vector3, spread: float) -> Vector3:
	if spread <= 0.0:
		return dir
	var right: Vector3 = dir.cross(Vector3.UP).normalized()
	if right.length() < 0.01:
		right = Vector3.RIGHT
	var up: Vector3 = right.cross(dir).normalized()
	return (dir + right * randf_range(-spread, spread) + up * randf_range(-spread, spread)).normalized()


# ---------------------------------------------------------------- Tools de área

func pull_props(center: Vector3) -> void:
	for pid in props:
		var rb: RigidBody3D = props[pid]
		if not is_instance_valid(rb) or rb.freeze:
			continue
		var off: Vector3 = center - rb.global_position
		var d: float = off.length()
		if d > 8.0 or d < 0.1:
			continue
		rb.apply_central_impulse(off.normalized() * 15.0 * (1.0 - d / 8.0) * rb.mass)


func blow_props(center: Vector3, dir: Vector3) -> void:
	for pid in props:
		var rb: RigidBody3D = props[pid]
		if not is_instance_valid(rb) or rb.freeze:
			continue
		var off: Vector3 = rb.global_position - center
		var d: float = off.length()
		if d > 8.0:
			continue
		rb.apply_central_impulse((dir + Vector3.UP * 0.2).normalized() * 25.0 * (1.0 - d / 8.0) * rb.mass)


func _damage_player(p: Player, dmg: float) -> void:
	var owner_id: int = p.get_multiplayer_authority()
	if owner_id == multiplayer.get_unique_id():
		p.receive_hit(dmg)
	else:
		_hurt_owner.rpc_id(owner_id, owner_id, dmg)


## El servidor avisa al dueño del personaje que recibió daño (funciona en PC y en celular).
@rpc("authority", "reliable")
func _hurt_owner(pid: int, dmg: float) -> void:
	if multiplayer.get_unique_id() == pid and local_player != null:
		local_player.receive_hit(dmg)


@rpc("authority", "unreliable")
func _fx_beam(a: Vector3, b: Vector3, color: Color) -> void:
	draw_beam(a, b, color)


func draw_beam(a: Vector3, b: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	mi.mesh = im
	mi.top_level = true
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mi.material_override = mat
	add_child(mi)
	Player.build_bolt(im, a, b, 0.15, Color.WHITE)
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(mi.queue_free)


# ================================================================ Explosiones y efectos

## exclude: jugador que no recibe el empuje (por ejemplo, quien hace el ground slam).
func explode(pos: Vector3, radius: float = 6.0, power: float = 40.0, exclude: Player = null) -> void:
	_explosion_fx(pos)
	if multiplayer.get_peers().size() > 0:
		_fx_explosion.rpc(pos)

	npcs.explosion_damage(pos, radius, power)

	# Knockback a los jugadores cercanos
	for pid in players:
		var p: Player = players[pid]
		if p == exclude:
			continue
		var d: float = p.global_position.distance_to(pos)
		if d < radius:
			var kb: Vector3 = (p.global_position - pos + Vector3.UP).normalized() * power * 0.15 * (1.0 - d / radius)
			var owner_id: int = p.get_multiplayer_authority()
			if owner_id == multiplayer.get_unique_id():
				p.knockback(kb)
			else:
				p.rpc_id(owner_id, "receive_knock", kb)

	# Impulso a los props
	for pid in props:
		var rb: RigidBody3D = props[pid]
		if not is_instance_valid(rb) or rb.freeze:
			continue
		var offset: Vector3 = rb.global_position - pos
		var d2: float = offset.length()
		if d2 > radius:
			continue
		var falloff: float = 1.0 - d2 / radius
		var dir: Vector3 = (offset + Vector3.UP * 0.5).normalized()
		rb.apply_central_impulse(dir * power * falloff * rb.mass)

		# Reacción en cadena con barriles explosivos
		if _is_explosive(rb) and falloff > 0.2:
			rb.set_meta("explosive", false)
			get_tree().create_timer(0.12).timeout.connect(explode.bind(rb.global_position, radius, power))


@rpc("authority", "reliable")
func _fx_explosion(pos: Vector3) -> void:
	_explosion_fx(pos)


func _explosion_fx(pos: Vector3) -> void:
	burst(pos, Color(1.0, 0.55, 0.15), 80)
	burst(pos, Color(0.3, 0.3, 0.32), 30)
	_flash(pos)
	if local_player != null:
		var d: float = local_player.global_position.distance_to(pos)
		local_player.add_shake(clampf(1.0 - d / 30.0, 0.0, 1.0) * 1.2)


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
	m.radial_segments = 8
	m.rings = 4
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


# ================================================================ Sincronización de props

func _physics_process(delta: float) -> void:
	if not _is_host():
		return
	_apply_holds()
	sync_clock += delta
	if sync_clock >= 0.05:
		sync_clock = 0.0
		if multiplayer.get_peers().size() > 0:
			_broadcast_transforms()


func _broadcast_transforms() -> void:
	var ids := PackedInt32Array()
	var xf: Array = []
	for pid in props:
		var body: RigidBody3D = props[pid]
		if is_instance_valid(body):
			ids.append(pid)
			xf.append(body.global_transform)
	_sync_props.rpc(ids, xf)


@rpc("authority", "unreliable")
func _sync_props(ids: PackedInt32Array, xforms: Array) -> void:
	for i in ids.size():
		var body: RigidBody3D = props.get(ids[i], null)
		if is_instance_valid(body):
			body.global_transform = xforms[i]


# ================================================================ Modos globales

func toggle_gravity() -> void:
	if not _is_host():
		toast("Solo el host puede cambiar la gravedad")
		return
	gravity_on = not gravity_on
	var s: float = 1.0 if gravity_on else 0.0
	if local_player != null:
		local_player.gravity_scale = s
	for pid in props:
		var rb: RigidBody3D = props[pid]
		if is_instance_valid(rb):
			rb.gravity_scale = s
	toast("Gravedad " + ("activada" if gravity_on else "desactivada"))


func toggle_slow_mo() -> void:
	var slow: bool = Engine.time_scale >= 0.5
	Engine.time_scale = 0.25 if slow else 1.0
	toast("Cámara lenta " + ("activada" if slow else "desactivada"))


func toggle_freeze_all() -> void:
	if not _is_host():
		toast("Solo el host puede congelar todo")
		return
	all_frozen = not all_frozen
	for pid in props:
		var rb: RigidBody3D = props[pid]
		if is_instance_valid(rb):
			rb.freeze = all_frozen
			if all_frozen:
				rb.linear_velocity = Vector3.ZERO
				rb.angular_velocity = Vector3.ZERO
	toast("Todo congelado" if all_frozen else "Todo descongelado")


# ================================================================ Guardado (solo host)

func _v_to_arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _arr_to_v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


func save_scene(path: String = SAVE_PATH) -> void:
	if not _is_host():
		toast("Solo el host puede guardar")
		return
	var items: Array = []
	for pid in props:
		var rb: RigidBody3D = props[pid]
		if not is_instance_valid(rb) or rb.has_meta("structure"):
			continue
		items.append({
			"kind": rb.get_meta("kind", "Caja"),
			"pos": _v_to_arr(rb.global_position),
			"rot": _v_to_arr(rb.rotation),
			"color": _prop_color(rb).to_html(false),
		})
	var data := {"version": 7, "map": map_index, "props": items, "structures": builder.serialize()}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		toast("No se pudo guardar")
		return
	f.store_string(JSON.stringify(data))
	f.close()
	toast("Partida guardada (%s, %d objetos)" % [MAPS[map_index]["name"], items.size()])


func load_scene(path: String = SAVE_PATH) -> void:
	if not _is_host():
		toast("Solo el host puede cargar")
		return
	if not FileAccess.file_exists(path):
		toast("No hay partida guardada")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))

	var items: Array = []
	var idx: int = map_index
	if typeof(parsed) == TYPE_DICTIONARY:
		items = parsed.get("props", [])
		idx = clampi(int(parsed.get("map", map_index)), 0, MAPS.size() - 1)
	elif typeof(parsed) == TYPE_ARRAY:
		items = parsed  # formato viejo: solo props
	else:
		toast("Archivo de guardado inválido")
		return

	change_map(idx)
	var count: int = 0
	for item in items:
		var d: Dictionary = item
		if not PROPS.has(d["kind"]):
			continue
		var p: Array = d["pos"]
		var r: Array = d["rot"]
		spawn_prop(d["kind"], _arr_to_v(p), _arr_to_v(r), Color.html("#" + d["color"]), false)
		count += 1
	if typeof(parsed) == TYPE_DICTIONARY:
		builder.deserialize(parsed.get("structures", []))
	toast("Partida cargada (%d objetos)" % count)


# ================================================================ Iconos dibujados (sin clase aparte)

# ================================================================ Spawn: fantasma y colocación

func spawn_dims() -> Vector3:
	if selected_vehicle:
		return Vector3(3.0, 2.4, 5.0)
	var cfg: Dictionary = PROPS[selected_prop]
	var sz: Vector3 = cfg.get("size", Vector3.ONE)
	match str(cfg["shape"]):
		"box":
			return sz
		"sphere":
			return Vector3(sz.x * 2.0, sz.x * 2.0, sz.x * 2.0)
		"compound":
			return Vector3(1.5, 1.5, 1.5)
		_:
			return Vector3(sz.x * 2.0, sz.y, sz.x * 2.0)


func spawn_at_ghost(xf: Transform3D) -> void:
	var yaw: float = xf.basis.get_euler().y
	var p: Vector3 = xf.origin
	if snap_enabled:
		p = snap_vec(p)
	if selected_vehicle:
		var dims: Vector3 = spawn_dims()
		var base: Vector3 = p + Vector3.DOWN * (dims.y * 0.5 - 0.6)
		builder.request_prefab(selected_prop, Transform3D(Basis(Vector3.UP, yaw), base))
	else:
		var rot := Vector3(0.0, yaw, 0.0)
		if snap_enabled:
			rot = snap_yaw(rot)
		request_spawn(selected_prop, p, rot)
	toast("Creado: " + selected_prop)


# ================================================================ Construcción, mochila, NPCs y extras (v7)

func _build_compound(kind: String, color: Color, cfg: Dictionary) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = float(cfg["mass"])
	body.add_to_group("props")
	body.set_meta("kind", kind)
	var parts: Array = cfg["parts"]
	for i in parts.size():
		var part: Dictionary = parts[i]
		var psize: Vector3 = part["size"]
		var pos: Vector3 = part["pos"]
		var rv: Vector3 = part["rot"]
		var mesh: Mesh
		var shape: Shape3D
		match str(part["shape"]):
			"box":
				var bm := BoxMesh.new()
				bm.size = psize
				mesh = bm
				var bs := BoxShape3D.new()
				bs.size = psize
				shape = bs
			"sphere":
				var sm := SphereMesh.new()
				sm.radial_segments = 8
				sm.rings = 4
				sm.radius = psize.x
				sm.height = psize.x * 2.0
				mesh = sm
				var ss := SphereShape3D.new()
				ss.radius = psize.x
				shape = ss
			"capsule":
				var cm := CapsuleMesh.new()
				cm.radial_segments = 6
				cm.rings = 2
				cm.radius = psize.x
				cm.height = psize.y
				mesh = cm
				var cs := CapsuleShape3D.new()
				cs.radius = psize.x
				cs.height = psize.y
				shape = cs
			"cone":
				var com := CylinderMesh.new()
				com.radial_segments = 6
				com.rings = 1
				com.top_radius = 0.0
				com.bottom_radius = psize.x
				com.height = psize.y
				mesh = com
				var cos_ := CylinderShape3D.new()
				cos_.radius = psize.x
				cos_.height = psize.y
				shape = cos_
			_:
				var ym := CylinderMesh.new()
				ym.radial_segments = 6
				ym.rings = 1
				ym.top_radius = psize.x
				ym.bottom_radius = psize.x
				ym.height = psize.y
				mesh = ym
				var ys := CylinderShape3D.new()
				ys.radius = psize.x
				ys.height = psize.y
				shape = ys
		var mat := StandardMaterial3D.new()
		mat.roughness = 0.6
		Textures.apply(mat, Textures.pick(str(part["tex"]), str(part["shape"])))
		mat.albedo_color = Color.html("#" + str(part["color"]))
		if i == 0 and color.a > 0.0:
			mat.albedo_color = color
		var t := Transform3D(Basis.from_euler(Vector3(deg_to_rad(rv.x), deg_to_rad(rv.y), deg_to_rad(rv.z))), pos)
		var mi := MeshInstance3D.new()
		mi.name = "Mesh" if i == 0 else "P%d" % i
		mi.mesh = mesh
		mi.material_override = mat
		mi.transform = t
		body.add_child(mi)
		var cshape := CollisionShape3D.new()
		cshape.shape = shape
		cshape.transform = t
		body.add_child(cshape)
	return body


func paint_prop_color(pid: int, c: Color) -> void:
	var body: RigidBody3D = props.get(pid, null)
	if not is_instance_valid(body) or body.has_meta("structure"):
		return
	_set_prop_color(body, c)
	burst(body.global_position, c, 12)
	if multiplayer.get_peers().size() > 0:
		_client_paint.rpc(pid, c)


func _stun_player(p: Player, sec: float) -> void:
	var owner_id: int = p.get_multiplayer_authority()
	if owner_id == multiplayer.get_unique_id():
		p.receive_stun(sec)
	else:
		p.rpc_id(owner_id, "receive_stun", sec)


@rpc("authority", "unreliable")
func _fx_beams(origin: Vector3, ends: PackedVector3Array, color: Color) -> void:
	for e in ends:
		draw_beam(origin, e, color)


func npc_melee(n: Node3D, target: Node3D, dmg: float) -> void:
	var p := target as Player
	if p == null:
		return
	_damage_player(p, dmg)
	var kb: Vector3 = (p.global_position - n.global_position).normalized() * 5.0 + Vector3.UP * 2.0
	var owner_id: int = p.get_multiplayer_authority()
	if owner_id == multiplayer.get_unique_id():
		p.knockback(kb)
	else:
		p.rpc_id(owner_id, "receive_knock", kb)


func npc_shoot(n: Node3D, target: Node3D, dmg: float) -> void:
	var p := target as Player
	if p == null:
		return
	var from: Vector3 = n.global_position + Vector3.UP * 1.5
	var to: Vector3 = p.global_position + Vector3.UP * 1.2
	if randf() < 0.75:
		_damage_player(p, dmg)
	var color := Color(1.0, 0.4, 0.3)
	draw_beam(from, to, color)
	if multiplayer.get_peers().size() > 0:
		_fx_beams.rpc(from, PackedVector3Array([to]), color)


func _make_water() -> void:
	var mi := MeshInstance3D.new()
	mi.add_to_group("map")
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.45, 0.75, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position = Vector3(0, water_level, 0)
	add_child(mi)


# ---------------------------------------------------------------- Menú de bloques y colores (B)

func _build_buildmenu() -> void:
	build_root = _make_overlay(hud_layer)
	var bp := PanelContainer.new()
	bp.add_theme_stylebox_override("panel", _panel_style(0.95, 18))
	var vs: Vector2 = get_viewport().get_visible_rect().size
	bp.custom_minimum_size = Vector2(minf(720.0, vs.x - 40.0), minf(540.0, vs.y - 40.0))
	bp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	build_root.add_child(bp)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	bp.add_child(col)

	var title := Label.new()
	title.text = "Bloques"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)

	build_info = Label.new()
	col.add_child(build_info)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(g)
	for kind in builder.defs:
		var d: Dictionary = builder.defs[kind]
		var c: Color = Color.html("#" + str(d["color"]))
		var btn := _make_button(str(kind), c.darkened(0.45), c)
		btn.custom_minimum_size = Vector2(150, 50)
		btn.pressed.connect(_pick_block.bind(str(kind)))
		g.add_child(btn)

	var ct := Label.new()
	ct.text = "Color (se usa al construir y al pintar)"
	col.add_child(ct)
	var cg := GridContainer.new()
	cg.columns = 12
	cg.add_theme_constant_override("h_separation", 6)
	cg.add_theme_constant_override("v_separation", 6)
	col.add_child(cg)
	for hex in PALETTE:
		var pc: Color = Color.html("#" + str(hex))
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(44, 34)
		sw.add_theme_stylebox_override("normal", _button_style(pc))
		sw.add_theme_stylebox_override("hover", _button_style(pc.lightened(0.25)))
		sw.add_theme_stylebox_override("pressed", _button_style(pc.darkened(0.25)))
		sw.add_theme_stylebox_override("focus", _button_style(pc))
		sw.pressed.connect(_pick_color.bind(pc))
		cg.add_child(sw)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var b_launch := _make_button("▶ Probar / ■ Detener (L)", Color(0.12, 0.3, 0.2), Color(0.25, 0.75, 0.45))
	b_launch.pressed.connect(builder.request_launch)
	var b_undo := _make_button("Deshacer (Ctrl+Z)", Color(0.12, 0.2, 0.35), Color(0.3, 0.55, 0.9))
	b_undo.pressed.connect(builder.request_undo)
	var b_clr := _make_button("Borrar construcciones", Color(0.35, 0.12, 0.12), Color(0.8, 0.25, 0.25))
	b_clr.pressed.connect(builder.request_clear_structs)
	for b in [b_launch, b_undo, b_clr]:
		var bt := b as Button
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bt)
	_refresh_build_info()


func _refresh_build_info() -> void:
	build_info.text = "Bloque elegido: %s  ·  usá la herramienta Construir (Z gira el bloque)" % builder.sel_block


func _pick_block(kind: String) -> void:
	builder.sel_block = kind
	_refresh_build_info()
	_switch_to_item("build")
	toast("Bloque: " + kind)


func _pick_color(c: Color) -> void:
	builder.sel_color = c
	toast("Color elegido")


func _toggle_build() -> void:
	if lobby_root.visible or pause_root.visible:
		return
	build_root.visible = not build_root.visible
	menu_root.visible = false
	help_panel.visible = false
	pack_root.visible = false
	if local_player != null:
		local_player.release()
	_refresh_build_info()
	_sync_mouse()


# ---------------------------------------------------------------- Mochila (herramientas y armas separadas)

func _build_pack() -> void:
	pack_root = _make_overlay(hud_layer)
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", _panel_style(0.95, 18))
	var vs2: Vector2 = get_viewport().get_visible_rect().size
	pp.custom_minimum_size = Vector2(minf(740.0, vs2.x - 40.0), minf(540.0, vs2.y - 40.0))
	pp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pack_root.add_child(pp)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	pp.add_child(col)

	var title := Label.new()
	title.text = "Mochila"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)

	pack_info = Label.new()
	col.add_child(pack_info)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)

	for cat in ["Construcción", "Objetos", "Utilidades"]:
		var lab := Label.new()
		lab.text = str(cat)
		inner.add_child(lab)
		var g := GridContainer.new()
		g.columns = 4
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 8)
		inner.add_child(g)
		for t in Content.tools():
			var td: Dictionary = t
			if str(td["cat"]) != str(cat):
				continue
			var b := _make_button(str(td["name"]), Color(0.12, 0.14, 0.2), Color(0.2, 0.7, 0.85))
			b.custom_minimum_size = Vector2(150, 44)
			b.pressed.connect(_equip.bind(str(td["id"])))
			g.add_child(b)

	var lw := Label.new()
	lw.text = "Armas"
	inner.add_child(lw)
	var gw := GridContainer.new()
	gw.columns = 4
	gw.add_theme_constant_override("h_separation", 8)
	gw.add_theme_constant_override("v_separation", 8)
	inner.add_child(gw)
	for w in WEAPONS:
		var wd: Dictionary = w
		var wc: Color = Color.html("#" + str(wd["color"]))
		var wb := _make_button(str(wd["name"]), wc.darkened(0.6), wc)
		wb.custom_minimum_size = Vector2(150, 44)
		wb.pressed.connect(_equip.bind("w:" + str(wd["name"])))
		gw.add_child(wb)


func _refresh_pack_info() -> void:
	if local_player == null:
		return
	pack_info.text = "Ranura elegida: %s  ·  tocá un ítem para equiparlo ahí. Cambiá de ranura clickeando la barra de abajo." % HOTKEYS[local_player.slot]


func _equip(id: String) -> void:
	if local_player == null:
		return
	local_player.set_slot_item(local_player.slot, id)
	toast("%s equipado en la ranura %s" % [Content.item_label(id), HOTKEYS[local_player.slot]])
	_refresh_pack_info()


func _toggle_pack() -> void:
	if lobby_root.visible or pause_root.visible:
		return
	pack_root.visible = not pack_root.visible
	menu_root.visible = false
	help_panel.visible = false
	build_root.visible = false
	if local_player != null:
		local_player.release()
	_refresh_pack_info()
	_sync_mouse()


# ---------------------------------------------------------------- Botones táctiles

func _on_touch_action(a: String) -> void:
	match a:
		"objetos": _toggle_menu()
		"bloques": _toggle_build()
		"mochila": _toggle_pack()
		"noclip":
			if local_player != null:
				local_player.set_noclip(not local_player.noclip)
		"slowmo": toggle_slow_mo()
		"gravedad": toggle_gravity()
		"congelar": toggle_freeze_all()
		"snap": toggle_snap()
		"probar": builder.request_launch()
		"deshacer": builder.request_undo()
		"ayuda": _toggle_help()
		"invencibles": toggle_god_npcs()
		"apoyar": toggle_ground_snap()
		"personalizar": _open_customize()
		"freecam":
			if local_player != null:
				local_player.toggle_freecam()
		"pausa": _toggle_pause()
		"chat": _open_chat()
		"salir_menu": _ask("¿Seguro que querés salir al menú?", back_to_lobby)
		"salir_juego": _ask("¿Seguro que querés salir del juego?", _quit_game)


# ================================================================ Menú de pausa

func _build_pause() -> void:
	pause_root = _make_overlay(hud_layer)
	pause_root.add_child(Settings.version_badge())
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", _panel_style(0.96, 22))
	pause_root.add_child(pp)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	pp.add_child(col)

	var title := Label.new()
	title.text = "PAUSA"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	pause_players = Label.new()
	pause_players.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(pause_players)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(tabs)

	# ---- Partida
	var p1 := VBoxContainer.new()
	p1.name = Lang.t("Partida")
	p1.add_theme_constant_override("separation", 10)
	tabs.add_child(p1)
	p1.add_child(_wide_button("Continuar", _resume))
	p1.add_child(_wide_button("Guardar partida", save_scene))
	p1.add_child(_wide_button("Cargar partida", load_scene))
	p1.add_child(_wide_button("Guardar nivel", _save_level))
	p1.add_child(_wide_button("Opciones", _open_options))
	p1.add_child(_wide_button("Cargar último nivel", _load_last_level))
	p1.add_child(_wide_button("Personalizar (color y texturas)", _open_customize))

	# ---- Mundo: mapas
	var p2 := VBoxContainer.new()
	p2.name = Lang.t("Mundo")
	p2.add_theme_constant_override("separation", 8)
	tabs.add_child(p2)
	var mlab := Label.new()
	mlab.text = "Mapa (solo el host)"
	p2.add_child(mlab)
	var msc := ScrollContainer.new()
	msc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p2.add_child(msc)
	var mrow := GridContainer.new()
	mrow.columns = 3
	mrow.add_theme_constant_override("h_separation", 8)
	mrow.add_theme_constant_override("v_separation", 8)
	mrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msc.add_child(mrow)
	for i in MAPS.size():
		mrow.add_child(_wide_button(str(MAPS[i]["name"]), change_map.bind(i)))

	# ---- Modos de juego
	var p3 := VBoxContainer.new()
	p3.name = Lang.t("Modos")
	p3.add_theme_constant_override("separation", 10)
	tabs.add_child(p3)
	snap_btn = _wide_button("Snap: siempre activo", toggle_snap)
	p3.add_child(snap_btn)
	p3.add_child(_wide_button("Enemigos invencibles (I)", toggle_god_npcs))
	p3.add_child(_wide_button("Apoyar en el suelo (V)", toggle_ground_snap))
	p3.add_child(_wide_button("Freecam (K)", _toggle_freecam_main))
	p3.add_child(_wide_button("Sin gravedad (G)", toggle_gravity))
	p3.add_child(_wide_button("Cámara lenta (T)", toggle_slow_mo))
	p3.add_child(_wide_button("Congelar todo (F)", toggle_freeze_all))
	p3.add_child(_wide_button("Música on/off", _toggle_music))
	p3.add_child(_wide_button("Siguiente canción", _next_music))

	# ---- Controles (PC): tocá una acción y apretá la tecla nueva
	var p4 := VBoxContainer.new()
	p4.name = Lang.t("Controles")
	p4.add_theme_constant_override("separation", 6)
	tabs.add_child(p4)
	var clab := Label.new()
	clab.text = "Tocá una acción y después apretá la tecla nueva (Esc cancela)"
	p4.add_child(clab)
	var cscroll := ScrollContainer.new()
	cscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p4.add_child(cscroll)
	var cgrid := GridContainer.new()
	cgrid.columns = 2
	cgrid.add_theme_constant_override("h_separation", 8)
	cgrid.add_theme_constant_override("v_separation", 6)
	cgrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cscroll.add_child(cgrid)
	controls_btns.clear()
	for i in Controls.ACTIONS.size():
		var cb := _wide_button("", _start_rebind.bind(i))
		cb.custom_minimum_size = Vector2(0, 40)
		cgrid.add_child(cb)
		controls_btns.append(cb)
	p4.add_child(_wide_button("Restablecer teclas", _reset_controls))
	_refresh_controls_btns()

	# ---- Salir
	var p5 := VBoxContainer.new()
	p5.name = Lang.t("Salir")
	p5.add_theme_constant_override("separation", 10)
	tabs.add_child(p5)
	p5.add_child(_wide_button("Salir al menú", _ask.bind("¿Seguro que querés salir al menú?", back_to_lobby)))
	p5.add_child(_wide_button("Salir del juego", _ask.bind("¿Seguro que querés salir del juego?", _quit_game)))


func _refresh_controls_btns() -> void:
	for i in controls_btns.size():
		var b := controls_btns[i] as Button
		if rebinding == i:
			b.text = "%s: presioná una tecla..." % Controls.ACTIONS[i][0]
		else:
			b.text = "%s: %s" % [Controls.ACTIONS[i][0], Controls.label(i)]


func _start_rebind(i: int) -> void:
	rebinding = i
	_refresh_controls_btns()


func _reset_controls() -> void:
	Controls.reset()
	rebinding = -1
	_refresh_controls_btns()
	toast("Teclas restablecidas")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST and not OS.has_feature("mobile"):
		_quit_game()


## Botón atrás del celular: cierra el menú de pausa; si no está abierto, lo abre.
func _on_back() -> void:
	if options_menu != null and options_menu.visible and not options_menu.first_run:
		options_menu._close()
		return
	if pause_root.visible:
		_resume()
	elif lobby_root.visible:
		_quit_game()
	else:
		_open_pause()


func _quit_game() -> void:
	get_tree().quit()


func _open_pause() -> void:
	_fit_overlays()
	var names := PackedStringArray()
	for pid in players:
		var np: Player = players[pid]
		names.append(np.display_name + (" (host)" if pid == 1 and online else ""))
	pause_players.text = "Jugadores: " + (", ".join(names) if not names.is_empty() else "ninguno")
	pause_root.visible = true
	if local_player != null:
		local_player.release()
	_sync_mouse()


func _resume() -> void:
	pause_root.visible = false
	_sync_mouse()


func _toggle_pause() -> void:
	if lobby_root.visible:
		return
	if pause_root.visible:
		_resume()
	else:
		_open_pause()


# ================================================================ HUD

func _build_hud() -> void:
	# Mira con anillo
	var cross := Control.new()
	cross.set_anchors_preset(Control.PRESET_FULL_RECT)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross.draw.connect(_draw_crosshair.bind(cross))
	hud_layer.add_child(cross)

	# Barra de herramientas (en táctil se oculta y el toast muestra la herramienta)
	var hotbar := HBoxContainer.new()
	hotbar.add_theme_constant_override("separation", 4)
	hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 20)
	hotbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hotbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hotbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotbar.visible = not touch
	hud_layer.add_child(hotbar)
	for i in Player.SLOTS:
		var slot := PanelContainer.new()
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_slot_gui.bind(i))
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 12)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(l)
		slot.add_child(vb)
		hotbar.add_child(slot)
		slot_panels.append(slot)

	# Panel de info
	var info_panel := PanelContainer.new()
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_theme_stylebox_override("panel", _panel_style(0.6, 14))
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 14)
	info_panel.add_child(info_label)
	hud_layer.add_child(info_panel)
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	info_panel.visible = false

	# Vida
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(380, 26)
	hp_bar.max_value = Player.MAX_HP
	hp_bar.value = Player.MAX_HP
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("fill", _button_style(Color(0.3, 0.85, 0.4)))
	hp_bar.add_theme_stylebox_override("background", _button_style(Color(0.1, 0.1, 0.12)))
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hp_bar)
	# Armadura: arriba al medio, debajo de la vida
	armor_bar = ProgressBar.new()
	armor_bar.custom_minimum_size = Vector2(380, 24)
	armor_bar.max_value = 100.0
	armor_bar.value = 100.0
	armor_bar.show_percentage = true
	armor_bar.add_theme_stylebox_override("fill", _button_style(Color(0.3, 0.6, 1.0)))
	armor_bar.add_theme_stylebox_override("background", _button_style(Color(0.1, 0.1, 0.12)))
	armor_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	armor_bar.anchor_left = 0.5
	armor_bar.anchor_right = 0.5
	armor_bar.anchor_top = 0.0
	armor_bar.anchor_bottom = 0.0
	armor_bar.offset_left = -190.0
	armor_bar.offset_right = 190.0
	armor_bar.offset_top = 58.0
	armor_bar.offset_bottom = 84.0
	hud_layer.add_child(armor_bar)
	_build_chat()
	hp_bar.anchor_left = 0.5
	hp_bar.anchor_right = 0.5
	hp_bar.anchor_top = 0.0
	hp_bar.anchor_bottom = 0.0
	hp_bar.offset_left = -190.0
	hp_bar.offset_right = 190.0
	hp_bar.offset_top = 20.0
	hp_bar.offset_bottom = 46.0
	hp_bar.show_percentage = true

	# Notificaciones
	toast_box = VBoxContainer.new()
	toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	toast_box.add_theme_constant_override("separation", 6)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(toast_box)
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 20)
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH

	# Ayuda
	help_panel = _make_overlay(hud_layer)
	var hp := PanelContainer.new()
	hp.add_theme_stylebox_override("panel", _panel_style(0.95, 18))
	var help := Label.new()
	help.text = HELP_TEXT
	hp.add_child(help)
	help_panel.add_child(hp)

	# Menú de objetos (elegís qué spawnear; se coloca con la herramienta Spawn)
	menu_root = _make_overlay(hud_layer)
	var mp := PanelContainer.new()
	mp.add_theme_stylebox_override("panel", _panel_style(0.95, 18))
	var vs3: Vector2 = get_viewport().get_visible_rect().size
	mp.custom_minimum_size = Vector2(minf(760.0, vs3.x - 40.0), minf(540.0, vs3.y - 40.0))
	mp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_root.add_child(mp)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	mp.add_child(col)

	var title := Label.new()
	title.text = "Objetos"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)

	selected_label = Label.new()
	selected_label.text = "Seleccionado: %s  (usá la herramienta Spawn para colocarlo)" % selected_prop
	col.add_child(selected_label)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Buscar objeto o vehículo..."
	search_box.text_changed.connect(_on_search)
	col.add_child(search_box)

	var cats := HFlowContainer.new()
	cats.add_theme_constant_override("h_separation", 6)
	cats.add_theme_constant_override("v_separation", 6)
	col.add_child(cats)
	for cat in Content.prop_categories():
		var cb := _make_button(str(cat), Color(0.18, 0.2, 0.3), Color(0.3, 0.6, 0.9))
		cb.custom_minimum_size = Vector2(100, 36)
		cb.pressed.connect(_select_category.bind(str(cat)))
		cats.add_child(cb)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	_rebuild_prop_grid()

	var npc_title := Label.new()
	npc_title.text = "NPCs"
	col.add_child(npc_title)
	var npc_row := HBoxContainer.new()
	npc_row.add_theme_constant_override("separation", 8)
	col.add_child(npc_row)
	for nk in NPC.KINDS:
		var nb := _make_button(str(nk), Color(0.2, 0.14, 0.14), Color(0.85, 0.4, 0.3))
		nb.custom_minimum_size = Vector2(110, 40)
		nb.pressed.connect(_spawn_npc_from_menu.bind(str(nk)))
		npc_row.add_child(nb)
	var nb_clear := _make_button("Borrar NPCs", Color(0.35, 0.12, 0.12), Color(0.8, 0.25, 0.25))
	nb_clear.custom_minimum_size = Vector2(130, 40)
	nb_clear.pressed.connect(npcs.request_clear)
	npc_row.add_child(nb_clear)

	var b_clear := _make_button("Limpiar todo", Color(0.35, 0.12, 0.12), Color(0.8, 0.25, 0.25))
	b_clear.pressed.connect(request_clear)
	b_clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(b_clear)


func _make_overlay(layer: CanvasLayer) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	layer.add_child(root)
	return root


func _make_button(text: String, base: Color, hover: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(190, 64) if touch else Vector2(190, 50)
	if touch:
		btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_stylebox_override("normal", _button_style(base))
	btn.add_theme_stylebox_override("hover", _button_style(hover))
	btn.add_theme_stylebox_override("pressed", _button_style(hover.darkened(0.3)))
	btn.add_theme_stylebox_override("focus", _button_style(base))
	return btn


func _wide_button(text: String, cb: Callable) -> Button:
	var b := _make_button(Lang.t(text), Color(0.12, 0.14, 0.2), Color(0.2, 0.7, 0.85))
	b.pressed.connect(Sfx.play.bind("click"))
	b.mouse_entered.connect(Sfx.play.bind("hover"))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	return b


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


func _on_tool_changed(slot_index: int) -> void:
	for i in slot_panels.size():
		var sp: PanelContainer = slot_panels[i]
		var sel: bool = i == slot_index
		sp.add_theme_stylebox_override("panel", _slot_style(sel))
		var l := sp.get_child(0).get_child(0) as Label
		l.add_theme_color_override("font_color", Color.BLACK if sel else Color.WHITE)
	if touch and local_player != null:
		toast("Ítem: " + local_player.item_name())


func _refresh_hotbar() -> void:
	var items: Array = Content.default_hotbar()
	if local_player != null:
		items = local_player.hotbar
	for i in slot_panels.size():
		var vb := slot_panels[i].get_child(0) as VBoxContainer
		var l := vb.get_child(0) as Label
		var iid: String = str(items[i])
		l.text = "%s %s" % [HOTKEYS[i], Content.item_label(iid)]


func _on_slot_gui(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and local_player != null and not touch:
			local_player.select_slot(i)
			_refresh_pack_info()


func toast(msg: String) -> void:
	if msg.begins_with("Conectado") or msg.begins_with("Servidor online abierto"):
		Sfx.play("unirse")
	elif msg.begins_with("No se pudo") or msg.begins_with("Solo el host") or msg.begins_with("No hay"):
		Sfx.play("error")
	msg = Lang.t(msg)
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


func _on_search(_text: String) -> void:
	_rebuild_prop_grid()


func _select_category(cat: String) -> void:
	selected_cat = cat
	search_box.clear()
	_rebuild_prop_grid()


func _rebuild_prop_grid() -> void:
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	var q: String = ""
	if search_box != null:
		q = search_box.text.strip_edges().to_lower()
	if selected_cat == "Vehículos" or q != "":
		var all: Dictionary = Content.prefabs().merged(ContentExtra.prefabs()).merged(ContentMore.prefabs())
		for vname in all:
			if q != "" and not str(vname).to_lower().contains(q):
				continue
			var vd: Dictionary = all[vname]
			var vb := _make_button("%s  (%s)" % [str(vname), str(vd["cat"])], Color(0.14, 0.2, 0.12), Color(0.5, 0.8, 0.3))
			vb.pressed.connect(_select_prop.bind(str(vname), true))
			grid.add_child(vb)
	if selected_cat != "Vehículos" or q != "":
		for kind in PROPS:
			var pd: Dictionary = PROPS[kind]
			if q == "":
				if str(pd["cat"]) != selected_cat:
					continue
			elif not str(kind).to_lower().contains(q):
				continue
			var pb := _make_button(str(kind), Color(0.12, 0.14, 0.2), Color(0.2, 0.7, 0.85))
			pb.pressed.connect(_select_prop.bind(str(kind), false))
			grid.add_child(pb)


func _switch_to_item(id: String) -> void:
	if local_player == null:
		return
	for i in local_player.hotbar.size():
		if str(local_player.hotbar[i]) == id:
			local_player.select_slot(i)
			return
	local_player.set_slot_item(local_player.slot, id)


func _select_prop(pname: String, vehicle: bool) -> void:
	selected_prop = pname
	selected_vehicle = vehicle
	selected_label.text = "Seleccionado: %s  (usá la herramienta Spawn para colocarlo)" % pname
	_switch_to_item("spawn")
	toast("Elegido: %s. Click con Spawn para colocarlo" % pname)


## Lo llama la herramienta Spawn: coloca lo que elegiste en el menú de objetos.
func spawn_selected(pos: Vector3, nrm: Vector3, yaw: float) -> void:
	var p: Vector3 = pos + nrm * (2.2 if selected_vehicle else 1.0)
	if snap_enabled:
		p = snap_vec(p)
	if selected_vehicle:
		builder.request_prefab(selected_prop, Transform3D(Basis(Vector3.UP, yaw), p))
	else:
		var rot := Vector3(0.0, yaw, 0.0)
		if snap_enabled:
			rot = snap_yaw(rot)
		request_spawn(selected_prop, p, rot)


func _spawn_npc_from_menu(kind: String) -> void:
	if local_player == null:
		return
	var cam: Camera3D = local_player.camera
	var pos: Vector3 = cam.global_position - cam.global_transform.basis.z * 4.0
	pos.y = local_player.global_position.y + 0.5
	npcs.request_spawn(kind, pos)
	toast("NPC: " + kind)


func _filter_grid(text: String) -> void:
	var q: String = text.to_lower()
	for b in grid.get_children():
		var btn := b as Button
		btn.visible = q.is_empty() or btn.text.to_lower().contains(q)


func _process(delta: float) -> void:
	if local_player != null:
		hp_bar.value = local_player.hp
		armor_bar.value = local_player.armor
		local_player.water_level = water_level
	if hosting_lan:
		lan_clock += delta
		if lan_clock >= 1.0:
			lan_clock = 0.0
			lan.update_info(_lan_info())

	fps_clock += delta
	if fps_clock < 0.2:
		return
	fps_clock = 0.0

	var flags := PackedStringArray()
	if local_player != null and local_player.noclip:
		flags.append("NOCLIP")
	if not gravity_on:
		flags.append("SIN GRAVEDAD")
	if Engine.time_scale < 0.5:
		flags.append("CÁMARA LENTA")
	if all_frozen:
		flags.append("CONGELADO")
	flags.append("SNAP")
	if god_npcs:
		flags.append("ENEMIGOS INVENCIBLES")
	if ground_snap:
		flags.append("APOYADO")

	var text: String = "FPS  %d\nObjetos  %d\nJugadores  %d\nMapa  %s" % [Engine.get_frames_per_second(), props.size(), players.size(), MAPS[map_index]["name"]]
	if local_player != null:
		text += "\nVelocidad  %.1f m/s" % local_player.velocity.length()
	if local_player != null:
		text += "\nÍtem: " + local_player.item_name()
	text += "\nBloque: " + builder.sel_block + "   NPCs: %d" % npcs.npcs.size()
	if builder.launched:
		flags.append("PROBANDO")
	if online:
		text += "\n" + ("HOST" if _is_host() else "CLIENTE")
	if not flags.is_empty():
		text += "\n" + " · ".join(flags)
	info_label.get_parent().visible = not lobby_root.visible
	info_label.text = "FPS  %d" % Engine.get_frames_per_second()


# ================================================================ Input y paneles

func _overlay_open() -> bool:
	return lobby_root.visible or pause_root.visible or menu_root.visible or help_panel.visible or build_root.visible or pack_root.visible or (options_menu != null and options_menu.visible)


func _sync_mouse() -> void:
	if local_player != null:
		local_player.input_enabled = not _overlay_open()
	if touch:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _overlay_open() else Input.MOUSE_MODE_CAPTURED


func _toggle_menu() -> void:
	if lobby_root.visible or pause_root.visible:
		return
	menu_root.visible = not menu_root.visible
	help_panel.visible = false
	build_root.visible = false
	pack_root.visible = false
	search_box.clear()
	_rebuild_prop_grid()
	if local_player != null:
		local_player.release()
	_sync_mouse()


func _toggle_help() -> void:
	if lobby_root.visible or pause_root.visible:
		return
	help_panel.visible = not help_panel.visible
	menu_root.visible = false
	build_root.visible = false
	pack_root.visible = false
	_sync_mouse()


## Esc: cierra lo que esté abierto primero; si no hay nada, abre la pausa.
func _on_escape() -> void:
	if lobby_root.visible:
		return
	if help_panel.visible:
		help_panel.visible = false
		_sync_mouse()
		return
	if build_root.visible or pack_root.visible or menu_root.visible:
		build_root.visible = false
		pack_root.visible = false
		menu_root.visible = false
		_sync_mouse()
		return
	_toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and not touch and not _overlay_open() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	elif event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo:
			return
		if rebinding >= 0:
			if k.keycode != KEY_ESCAPE:
				Controls.set_bind(rebinding, k.keycode)
				toast("Tecla guardada: " + Controls.label(rebinding))
			rebinding = -1
			_refresh_controls_btns()
			return
			# Chat: Enter para escribir, Esc para cerrar
		if chat_open and k.keycode == KEY_ESCAPE:
			_close_chat()
			return
		if not chat_open and (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER) and local_player != null and not lobby_root.visible and not pause_root.visible:
			_open_chat()
			return
		if k.ctrl_pressed and k.keycode == KEY_S:
			save_scene()
			return
		if k.ctrl_pressed and k.keycode == KEY_L:
			load_scene()
			return
		if k.ctrl_pressed and k.keycode == KEY_Z:
			builder.request_undo()
			return
		if k.keycode == KEY_H:
			_toggle_help()
		elif k.keycode == Controls.k(11):
			_toggle_menu()
		elif k.keycode == Controls.k(12):
			_toggle_build()
		elif k.keycode == Controls.k(13):
			_toggle_pack()
		elif k.keycode == Controls.k(14):
			_toggle_help()
		elif k.keycode == Controls.k(15):
			_on_escape()
		elif k.keycode == Controls.k(16):
			toggle_snap()
		elif k.keycode == Controls.k(17):
			toggle_god_npcs()
		elif k.keycode == Controls.k(18):
			toggle_ground_snap()
		elif k.keycode == Controls.k(19):
			toggle_freeze_all()
		elif k.keycode == Controls.k(20):
			toggle_gravity()
		elif k.keycode == Controls.k(21):
			toggle_slow_mo()
		elif k.keycode == Controls.k(22):
			builder.request_launch()


# ================================================================ Personalización (guardada en user://prefs.json)

func _load_prefs() -> void:
	if not FileAccess.file_exists(PREFS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PREFS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	if d.has("body"):
		body_color = Color.html("#" + str(d["body"]))
	if d.has("tex"):
		builder.tex_override = str(d["tex"])


func _save_prefs() -> void:
	var d: Dictionary = {"tex": builder.tex_override}
	if body_color.a > 0.0:
		d["body"] = body_color.to_html(false)
	var f := FileAccess.open(PREFS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
		f.close()


func _build_customize() -> void:
	custom_root = _make_overlay(hud_layer)
	var cp := PanelContainer.new()
	cp.add_theme_stylebox_override("panel", _panel_style(0.96, 18))
	cp.custom_minimum_size = Vector2(560, 0)
	cp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	custom_root.add_child(cp)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	cp.add_child(col)
	var title := Label.new()
	title.text = "Personalizar"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)
	var l1 := Label.new()
	l1.text = "Color del personaje"
	col.add_child(l1)
	var g1 := GridContainer.new()
	g1.columns = 12
	g1.add_theme_constant_override("h_separation", 6)
	g1.add_theme_constant_override("v_separation", 6)
	col.add_child(g1)
	for hex in PALETTE:
		var pc: Color = Color.html("#" + str(hex))
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(36, 30)
		sw.add_theme_stylebox_override("normal", _button_style(pc))
		sw.add_theme_stylebox_override("hover", _button_style(pc.lightened(0.25)))
		sw.add_theme_stylebox_override("pressed", _button_style(pc.darkened(0.25)))
		sw.add_theme_stylebox_override("focus", _button_style(pc))
		sw.pressed.connect(_set_body_color.bind(pc))
		g1.add_child(sw)
	var l2 := Label.new()
	l2.text = "Textura para bloques y objetos sin textura propia"
	col.add_child(l2)
	tex_pick = OptionButton.new()
	var names: Array = Textures.names()
	for i in names.size():
		tex_pick.add_item(str(names[i]), i)
		if str(names[i]) == builder.tex_override:
			tex_pick.select(i)
	tex_pick.item_selected.connect(_on_tex_picked)
	col.add_child(tex_pick)
	col.add_child(_wide_button("Listo", _close_customize))


func _open_customize() -> void:
	pause_root.visible = false
	custom_root.visible = true
	_sync_mouse()


func _close_customize() -> void:
	custom_root.visible = false
	pause_root.visible = true
	_sync_mouse()


func _set_body_color(c: Color) -> void:
	body_color = c
	if local_player != null:
		local_player.body_color = c
		var mat := local_player.body_mesh.material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color = c
	_save_prefs()
	toast("Color guardado")


func _on_tex_picked(i: int) -> void:
	builder.tex_override = str(Textures.names()[i])
	_save_prefs()
	toast("Textura: " + builder.tex_override)


func _toggle_freecam_main() -> void:
	if local_player != null:
		local_player.toggle_freecam()


## Los menús ocupan toda la pantalla (se ajustan si cambia el tamaño de la ventana).
func _fit_overlays() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	for root in [pause_root, menu_root, build_root, pack_root, custom_root, help_panel]:
		if root == null:
			continue
		for c in root.get_children():
			if c.name == "VersionBadge" or not (c is Control):
				continue
			(c as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)


# ================================================================ Música y niveles (pausa)

func _toggle_music() -> void:
	if audio != null:
		audio.toggle()
		toast("Música: " + ("on" if audio.on else "off") + " · " + audio.now_playing())


func _next_music() -> void:
	if audio != null:
		audio.next()
		toast("Suena: " + audio.now_playing())


func _save_level() -> void:
	if not _is_host():
		toast("Solo el host puede guardar niveles")
		return
	var p: String = LevelCreator.new_path()
	save_scene(p)
	toast("Nivel guardado: " + p.get_file())


func _load_last_level() -> void:
	if not _is_host():
		toast("Solo el host puede cargar niveles")
		return
	var p: String = LevelCreator.last_path()
	if p == "":
		toast("Todavía no hay niveles guardados")
		return
	load_scene(p)


# ================================================================ Chat

func _build_chat() -> void:
	chat_log = RichTextLabel.new()
	chat_log.bbcode_enabled = true
	chat_log.scroll_active = false
	chat_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_log.custom_minimum_size = Vector2(340, 150)
	chat_log.anchor_left = 0.0
	chat_log.anchor_right = 0.0
	chat_log.anchor_top = 0.0
	chat_log.anchor_bottom = 0.0
	chat_log.offset_left = 16.0
	chat_log.offset_top = 150.0
	chat_log.offset_right = 356.0
	chat_log.offset_bottom = 300.0
	hud_layer.add_child(chat_log)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Escribí y Enter (Esc cancela)"
	chat_input.anchor_left = 0.0
	chat_input.anchor_right = 0.0
	chat_input.anchor_top = 1.0
	chat_input.anchor_bottom = 1.0
	chat_input.offset_left = 16.0
	chat_input.offset_right = 356.0
	chat_input.offset_top = -104.0
	chat_input.offset_bottom = -72.0
	chat_input.visible = false
	chat_input.text_submitted.connect(_on_chat_submit)
	hud_layer.add_child(chat_input)


func _open_chat() -> void:
	if chat_open or local_player == null:
		return
	chat_open = true
	chat_input.visible = true
	chat_input.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	local_player.input_enabled = false
	chat_input.call_deferred("grab_focus")


func _close_chat() -> void:
	chat_open = false
	chat_input.visible = false
	chat_input.release_focus()
	if local_player != null:
		local_player.input_enabled = true
	_sync_mouse()


func _on_chat_submit(t: String) -> void:
	var txt: String = t.strip_edges()
	_close_chat()
	if txt == "":
		return
	txt = txt.substr(0, 160)
	if not online or multiplayer.multiplayer_peer == null:
		_chat_add(local_player.display_name if local_player != null else "Tú", txt)
	elif _is_host():
		_chat_relay(1, txt)
	else:
		_chat_send.rpc_id(1, txt)


## Un cliente manda su mensaje al servidor.
@rpc("any_peer", "reliable")
func _chat_send(txt: String) -> void:
	if not _is_host():
		return
	_chat_relay(multiplayer.get_remote_sender_id(), txt)


## El servidor reenvía el mensaje a todos (incluido él).
func _chat_relay(sender: int, txt: String) -> void:
	var who: String = "Jugador"
	if players.has(sender):
		who = (players[sender] as Player).display_name
	_chat_msg.rpc(who, txt)


@rpc("authority", "call_local", "reliable")
func _chat_msg(who: String, txt: String) -> void:
	_chat_add(who, txt)


func _chat_add(who: String, txt: String) -> void:
	var safe_who: String = who.replace("[", "[lb]")
	var safe_txt: String = txt.replace("[", "[lb]")
	_chat_lines.append("[b]%s:[/b] %s" % [safe_who, safe_txt])
	while _chat_lines.size() > 8:
		_chat_lines.pop_front()
	chat_log.text = "\n".join(_chat_lines)


# ================================================================ Opciones y video

func _build_options() -> void:
	options_menu = OptionsMenu.new()
	options_menu.first_run = not Settings.first_run_done
	hud_layer.add_child(options_menu)
	options_menu.changed.connect(_apply_post)
	options_menu.closed.connect(_sync_mouse)
	options_menu.edit_touch.connect(_on_edit_touch)
	if options_menu.first_run:
		options_menu.open()


func _open_options() -> void:
	options_menu.open()
	_sync_mouse()


## Shader de pantalla completa: viñeta, retro o cálido (se elige en Opciones → Video).
func _build_post() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	post_rect = ColorRect.new()
	post_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = POST_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	post_rect.material = mat
	layer.add_child(post_rect)
	_apply_post()


func _apply_post() -> void:
	_apply_graphics()
	_apply_time()
	if post_rect == null:
		return
	post_rect.visible = Settings.shader_idx != 0
	(post_rect.material as ShaderMaterial).set_shader_parameter("mode", Settings.shader_idx)


const POST_SHADER := """
shader_type canvas_item;
uniform int mode = 0;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec4 c = texture(screen_tex, SCREEN_UV);
	if (mode == 1) {
		vec2 d = SCREEN_UV - vec2(0.5);
		float v = smoothstep(0.85, 0.25, length(d) * 1.4);
		c.rgb *= mix(0.45, 1.0, v);
	} else if (mode == 2) {
		vec2 px = floor(SCREEN_UV * vec2(320.0, 180.0)) / vec2(320.0, 180.0);
		c = texture(screen_tex, px);
		c.rgb *= 0.9 + 0.1 * sin(SCREEN_UV.y * 720.0 * 3.14159);
	} else if (mode == 3) {
		c.rgb = c.rgb * vec3(1.08, 1.0, 0.88) + vec3(0.02, 0.01, 0.0);
	} else if (mode == 4) {
		float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		c.rgb = vec3(g) * vec3(1.07, 0.95, 0.78);
	} else if (mode == 5) {
		c.rgb = vec3(dot(c.rgb, vec3(0.299, 0.587, 0.114)));
	} else if (mode == 6) {
		vec2 px = floor(SCREEN_UV * vec2(160.0, 90.0)) / vec2(160.0, 90.0);
		c = texture(screen_tex, px);
	} else if (mode == 7) {
		c.rgb = vec3(1.0) - c.rgb;
	} else if (mode == 8) {
		vec3 q = floor(c.rgb * 4.0) / 4.0;
		float e = length(fwidth(SCREEN_UV)) * 200.0;
		c.rgb = q * (1.0 - smoothstep(0.0, 0.05, e) * 0.5);
	} else if (mode == 9) {
		c.rgb += (rnd(SCREEN_UV * 1000.0 + TIME) - 0.5) * 0.15;
	} else if (mode == 10) {
		vec2 uv = SCREEN_UV;
		uv.x += sin(uv.y * 40.0 + TIME * 3.0) * 0.004;
		c = texture(screen_tex, uv);
	} else if (mode == 11) {
		vec2 o = vec2(0.003, 0.0);
		c.r = texture(screen_tex, SCREEN_UV + o).r;
		c.b = texture(screen_tex, SCREEN_UV - o).b;
	} else if (mode == 12) {
		c.rgb = mix(c.rgb, c.rgb * c.rgb * 1.6, 0.5) + 0.05;
	} else if (mode == 13) {
		c.rgb = clamp((c.rgb - vec3(0.5)) * 1.6 + vec3(0.5), 0.0, 1.0);
	}
	if (mode == 14) {
		float s = step(0.98, rnd(vec2(floor(SCREEN_UV.y * 60.0), floor(TIME * 6.0))));
		c = texture(screen_tex, SCREEN_UV + vec2(s * 0.02, 0.0));
	} else if (mode == 15) {
		float e = 1.0 / 1280.0;
		vec3 a = texture(screen_tex, SCREEN_UV + vec2(e, 0.0)).rgb;
		vec3 b = texture(screen_tex, SCREEN_UV - vec2(e, 0.0)).rgb;
		c.rgb = vec3(length(a - b) * 3.0);
	} else if (mode == 16) {
		float g = dot(c.rgb, vec3(0.33));
		c.rgb = mix(c.rgb, vec3(0.9, 0.75, 0.5) * g, 0.5) * vec3(1.0, 0.95, 0.85);
	} else if (mode == 17) {
		c.rgb = pow(c.rgb, vec3(1.8)) * 2.2;
	} else if (mode == 18) {
		float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		c.rgb = mix(vec3(0.02, 0.05, 0.2), vec3(0.6, 0.9, 1.0), g);
	} else if (mode == 19) {
		c.rgb = pow(c.rgb, vec3(0.7));
	} else if (mode == 20) {
		c.rgb *= 0.85 + 0.15 * step(0.5, fract(SCREEN_UV.y * 200.0));
	} else if (mode == 21) {
		vec2 d = SCREEN_UV - vec2(0.5);
		c.rgb *= smoothstep(0.7, 0.1, length(d) * 1.8);
	} else if (mode == 22) {
		c.rgb = vec3(c.r * 1.2, c.g * 0.85, c.b * 0.75);
	} else if (mode == 23) {
		c.rgb = mix(c.rgb, vec3(1.0, 0.85, 0.9), 0.25) + vec3(0.05);
	}
	COLOR = c;
}
"""


## Calidad gráfica: desde Bajo (sin efectos) hasta RTX (Ultra): sombras de oclusión, reflejos,
## iluminación global (SDFGI), niebla volumétrica, bloom y ajuste de color.
## Requiere el renderizador Forward+ o Mobile; en Compatibility algunos efectos no se ven.
## Calidad gráfica: 30 niveles, de Mínimo (muy liviano) a RTX Absoluto.
## Los niveles bajos apagan efectos caros (sombras, oclusión, reflejos, niebla volumétrica) para subir los FPS.
func _apply_graphics() -> void:
	if world_env == null or world_env.environment == null:
		return
	var e: Environment = world_env.environment
	var g: int = Settings.graphics_idx
	var n: float = float(Settings.GRAPHICS.size() - 1)
	var t: float = float(g) / n
	e.tonemap_mode = Environment.TONE_MAPPER_ACES if g >= 12 else Environment.TONE_MAPPER_LINEAR
	e.ssao_enabled = g >= 3
	e.ssao_radius = 0.6 + t * 1.4
	e.ssao_intensity = 0.4 + t * 1.4
	e.ssil_enabled = g >= 18
	e.ssr_enabled = g >= 12
	e.ssr_max_steps = 16 + g * 4
	e.glow_enabled = g >= 3
	e.glow_intensity = 0.1 + t * 0.9
	e.glow_bloom = 0.01 * g
	e.volumetric_fog_enabled = g >= 14
	e.volumetric_fog_density = 0.003 * maxf(0.0, float(g - 13))
	e.sdfgi_enabled = g >= 20
	e.adjustment_enabled = g >= 10
	e.adjustment_saturation = 1.0 + t * 0.15
	e.adjustment_contrast = 1.0 + t * 0.1
	if sun_node != null:
		sun_node.shadow_enabled = g >= 3
	var vp: Viewport = get_viewport()
	if vp != null:
		if g < 4:
			vp.msaa_3d = Viewport.MSAA_DISABLED
		elif g < 14:
			vp.msaa_3d = Viewport.MSAA_2X
		else:
			vp.msaa_3d = Viewport.MSAA_4X

var _confirm_dlg: ConfirmationDialog = null
var _confirm_cb: Callable = Callable()

func _ask(text: String, cb: Callable) -> void:
	if _confirm_dlg == null:
		_confirm_dlg = ConfirmationDialog.new()
		_confirm_dlg.confirmed.connect(func() -> void:
			if _confirm_cb.is_valid():
				_confirm_cb.call())
		hud_layer.add_child(_confirm_dlg)
	_confirm_cb = cb
	_confirm_dlg.dialog_text = Lang.t(text)
	_confirm_dlg.popup_centered()


## En single player (sin red) siempre sos el host.
func _is_host() -> bool:
	return not online or multiplayer.is_server()


## Desde Opciones: entra al modo de edición de los botones táctiles.
func _on_edit_touch() -> void:
	if pause_root.visible:
		_resume()
	if touch_ui != null:
		touch_ui.visible = true
		touch_ui._start_edit()
	_sync_mouse()


## Hora del día: cielo, color del horizonte, intensidad del sol y de la luz de ambiente.
const TIME_PRESETS := [
	{"top": Color(0.12, 0.05, 0.25), "hor": Color(0.95, 0.4, 0.45), "sun": 1.1, "rot": -50.0, "amb": 1.0},
	{"top": Color(0.25, 0.15, 0.35), "hor": Color(1.0, 0.5, 0.2), "sun": 0.7, "rot": -12.0, "amb": 0.8},
	{"top": Color(0.03, 0.05, 0.12), "hor": Color(0.08, 0.1, 0.2), "sun": 0.12, "rot": -70.0, "amb": 0.25, "fog": Color(0.05, 0.06, 0.12), "energy": 0.3},
	{"top": Color(0.2, 0.3, 0.5), "hor": Color(0.9, 0.75, 0.6), "sun": 0.8, "rot": -25.0, "amb": 0.9},
	{"top": Color(0.45, 0.5, 0.55), "hor": Color(0.7, 0.72, 0.75), "sun": 0.35, "rot": -40.0, "amb": 0.9},
]

func _apply_time() -> void:
	if sky_mat == null or sun_node == null:
		return
	var p: Dictionary = TIME_PRESETS[clampi(Settings.time_idx, 0, TIME_PRESETS.size() - 1)]
	sky_mat.sky_top_color = p["top"]
	sky_mat.sky_horizon_color = p["hor"]
	sky_mat.ground_horizon_color = p["hor"]
	sky_mat.ground_bottom_color = p["hor"] * 0.5
	sky_mat.sky_energy_multiplier = p.get("energy", 1.0)
	if world_env != null and world_env.environment != null:
		world_env.environment.background_energy_multiplier = p.get("energy", 1.0)
	sun_node.light_energy = p["sun"]
	sun_node.rotation_degrees = Vector3(p["rot"], -30.0, 0.0)
	if world_env != null and world_env.environment != null:
		world_env.environment.ambient_light_energy = p["amb"]
		world_env.environment.fog_light_color = p.get("fog", Color(0.7, 0.75, 0.8))

