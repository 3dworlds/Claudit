class_name Lan
extends Node
## Descubrimiento de servidores en la red local (LAN) con UDP broadcast.
## El host anuncia su servidor cada segundo; el menú escucha y muestra botones para unirse.

const PORT := 7778
const MAGIC := "SANDBOX_V1"

var servers: Dictionary = {}   # ip -> {"name", "port", "players", "map", "seen"}

var _listener: PacketPeerUDP = null
var _sender: PacketPeerUDP = null
var _info: Dictionary = {}
var _send_clock: float = 0.0


func start_listening() -> bool:
	stop_listening()
	var l := PacketPeerUDP.new()
	if l.bind(PORT) != OK:
		return false
	_listener = l
	return true


func stop_listening() -> void:
	if _listener != null:
		_listener.close()
		_listener = null
	servers.clear()


func start_broadcast(info: Dictionary) -> void:
	stop_broadcast()
	_info = info
	var s := PacketPeerUDP.new()
	s.set_broadcast_enabled(true)
	s.set_dest_address("255.255.255.255", PORT)
	_sender = s
	_send_clock = 1.0


func update_info(info: Dictionary) -> void:
	_info = info


func stop_broadcast() -> void:
	if _sender != null:
		_sender.close()
		_sender = null


func _process(delta: float) -> void:
	var now: float = float(Time.get_ticks_msec()) / 1000.0

	if _listener != null:
		while _listener.get_available_packet_count() > 0:
			var pkt: PackedByteArray = _listener.get_packet()
			var ip: String = _listener.get_packet_ip()
			var parsed: Variant = JSON.parse_string(pkt.get_string_from_utf8())
			if typeof(parsed) == TYPE_DICTIONARY:
				var d: Dictionary = parsed
				if str(d.get("magic", "")) == MAGIC:
					d["seen"] = now
					servers[ip] = d
		for ip2 in servers.keys():
			var entry: Dictionary = servers[ip2]
			if now - float(entry["seen"]) > 4.0:
				servers.erase(ip2)

	if _sender != null:
		_send_clock += delta
		if _send_clock >= 1.0:
			_send_clock = 0.0
			var out: Dictionary = _info.duplicate()
			out["magic"] = MAGIC
			_sender.put_packet(JSON.stringify(out).to_utf8_buffer())
