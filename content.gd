class_name Content
## Contenido del sandbox: objetos, armas y mapas.
## Todo es determinista (RandomNumberGenerator con semilla fija) para que host y clientes generen lo mismo.


static func _base_props() -> Dictionary:
	return {
		"Caja": {"shape": "box", "size": Vector3(1, 1, 1), "mass": 5.0},
		"Caja grande": {"shape": "box", "size": Vector3(2, 2, 2), "mass": 30.0},
		"Tabla": {"shape": "box", "size": Vector3(3, 0.2, 1), "mass": 8.0},
		"Esfera": {"shape": "sphere", "size": Vector3(0.5, 0.5, 0.5), "mass": 4.0},
		"Pelota rebotona": {"shape": "sphere", "size": Vector3(0.35, 0.35, 0.35), "mass": 1.0, "bounce": 0.85},
		"Barril": {"shape": "cylinder", "size": Vector3(0.5, 1.2, 0.5), "mass": 10.0},
		"Barril explosivo": {"shape": "cylinder", "size": Vector3(0.5, 1.2, 0.5), "mass": 10.0, "explosive": true, "color": "ff6a2a"},
		"Caja pesada": {"shape": "box", "size": Vector3(1.5, 1.5, 1.5), "mass": 80.0, "color": "555566"},
		"Ladrillo": {"shape": "box", "size": Vector3(1.2, 0.5, 0.6), "mass": 4.0, "color": "b5543a"},
		"Tabla fina": {"shape": "box", "size": Vector3(4, 0.1, 1), "mass": 3.0, "color": "c8a064"},
		"Pilar": {"shape": "box", "size": Vector3(0.5, 4, 0.5), "mass": 25.0, "color": "999999"},
		"Bloque de hielo": {"shape": "box", "size": Vector3(1.5, 1.5, 1.5), "mass": 6.0, "color": "aee8ff", "bounce": 0.3},
		"Madera": {"shape": "box", "size": Vector3(2, 0.4, 0.4), "mass": 2.0, "color": "8b5a2b"},
		"Bloque de metal": {"shape": "box", "size": Vector3(1, 1, 1), "mass": 20.0, "color": "778899"},
		"Lingote de oro": {"shape": "box", "size": Vector3(1, 0.5, 1), "mass": 50.0, "color": "ffd700"},
		"Cubo de gelatina": {"shape": "box", "size": Vector3(1, 1, 1), "mass": 2.0, "color": "ff77cc", "bounce": 0.6},
		"Pelota de playa": {"shape": "sphere", "size": Vector3(0.6, 0.6, 0.6), "mass": 0.5, "color": "ff5577", "bounce": 0.9},
		"Bola de bowling": {"shape": "sphere", "size": Vector3(0.4, 0.4, 0.4), "mass": 12.0, "color": "222244"},
		"Pelota de goma": {"shape": "sphere", "size": Vector3(0.25, 0.25, 0.25), "mass": 0.3, "color": "ff00aa", "bounce": 0.95},
		"Bala de cañón": {"shape": "sphere", "size": Vector3(0.8, 0.8, 0.8), "mass": 60.0, "color": "333333"},
		"Cono": {"shape": "cone", "size": Vector3(0.5, 1.2, 0.5), "mass": 2.0, "color": "ffaa00"},
		"Cono grande": {"shape": "cone", "size": Vector3(1, 2, 1), "mass": 8.0, "color": "ff7700"},
		"Cápsula": {"shape": "capsule", "size": Vector3(0.4, 1.0, 0.4), "mass": 4.0, "color": "88ccff"},
		"Cápsula larga": {"shape": "capsule", "size": Vector3(0.35, 2.0, 0.35), "mass": 6.0, "color": "5599ff"},
		"Tubo": {"shape": "cylinder", "size": Vector3(0.4, 2.5, 0.4), "mass": 6.0, "color": "aaaaaa"},
		"Disco": {"shape": "cylinder", "size": Vector3(1.0, 0.1, 1.0), "mass": 3.0, "color": "ff9933"},
		"Rueda": {"shape": "cylinder", "size": Vector3(0.8, 0.25, 0.8), "mass": 4.0, "color": "222222"},
		"Bidón explosivo": {"shape": "cylinder", "size": Vector3(0.4, 0.8, 0.4), "mass": 12.0, "explosive": true, "color": "ff3333"},
	}


## Cada arma es hitscan. "pellets" son perdigones (escopeta), "blast" hace explosión en el impacto.
static func weapons() -> Array:
	return [
		{"name": "Pistola", "dmg": 25.0, "pellets": 1, "spread": 0.0, "cd": 0.25, "auto": false, "range": 200.0, "blast": 0.0, "knock": 8.0, "color": "ffd055"},
		{"name": "SMG", "dmg": 10.0, "pellets": 1, "spread": 0.03, "cd": 0.08, "auto": true, "range": 150.0, "blast": 0.0, "knock": 4.0, "color": "ffee88"},
		{"name": "Ametralladora", "dmg": 14.0, "pellets": 1, "spread": 0.035, "cd": 0.07, "auto": true, "range": 180.0, "blast": 0.0, "knock": 5.0, "color": "ffe9a0"},
		{"name": "Escopeta", "dmg": 9.0, "pellets": 10, "spread": 0.1, "cd": 0.9, "auto": false, "range": 35.0, "blast": 0.0, "knock": 6.0, "color": "ff8844"},
		{"name": "Rifle", "dmg": 40.0, "pellets": 1, "spread": 0.005, "cd": 0.5, "auto": false, "range": 300.0, "blast": 0.0, "knock": 12.0, "color": "66aaff"},
		{"name": "Francotirador", "dmg": 90.0, "pellets": 1, "spread": 0.0, "cd": 1.4, "auto": false, "range": 500.0, "blast": 0.0, "knock": 20.0, "color": "ffffff"},
		{"name": "Lanzacohetes", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 1.2, "auto": false, "range": 300.0, "blast": 6.0, "knock": 0.0, "color": "ff5500"},
		{"name": "Granada", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 0.8, "auto": false, "range": 60.0, "blast": 4.0, "knock": 0.0, "color": "88ff55"},
		{"name": "Lanzallamas", "dmg": 4.0, "pellets": 4, "spread": 0.25, "cd": 0.05, "auto": true, "range": 12.0, "blast": 0.0, "knock": 2.0, "color": "ff7a1a"},
		{"name": "Rayo", "dmg": 15.0, "pellets": 1, "spread": 0.0, "cd": 0.12, "auto": true, "range": 200.0, "blast": 0.0, "knock": 6.0, "color": "66ccff"},
		{"name": "Pistola de hielo", "dmg": 10.0, "pellets": 1, "spread": 0.0, "cd": 0.3, "auto": false, "range": 120.0, "blast": 0.0, "knock": 6.0, "color": "aaeeff"},
		{"name": "Minigun", "dmg": 8.0, "pellets": 1, "spread": 0.06, "cd": 0.03, "auto": true, "range": 150.0, "blast": 0.0, "knock": 3.0, "color": "dddddd"},
		{"name": "Arco", "dmg": 60.0, "pellets": 1, "spread": 0.0, "cd": 1.0, "auto": false, "range": 250.0, "blast": 0.0, "knock": 15.0, "color": "88ff88"},
		{"name": "Taser", "dmg": 5.0, "pellets": 1, "spread": 0.0, "cd": 1.2, "auto": false, "range": 25.0, "blast": 0.0, "knock": 4.0, "stun": 3.0, "color": "66ddff"},
		{"name": "Cañón de pulso", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 0.4, "auto": false, "range": 200.0, "blast": 0.0, "knock": 25.0, "color": "ff66ff"},
		{"name": "Cañón de energía", "dmg": 60.0, "pellets": 1, "spread": 0.0, "cd": 2.0, "auto": false, "range": 300.0, "blast": 3.0, "knock": 10.0, "color": "00ffaa"},
		{"name": "Revólver", "dmg": 45.0, "pellets": 1, "spread": 0.004, "cd": 0.6, "auto": false, "range": 250.0, "blast": 0.0, "knock": 10.0, "color": "ffcc66"},
		{"name": "Rifle de asalto", "dmg": 18.0, "pellets": 1, "spread": 0.02, "cd": 0.1, "auto": true, "range": 220.0, "blast": 0.0, "knock": 6.0, "color": "ffd780"},
		{"name": "Escopeta de combate", "dmg": 14.0, "pellets": 6, "spread": 0.09, "cd": 0.35, "auto": true, "range": 28.0, "blast": 0.0, "knock": 5.0, "color": "ff9966"},
		{"name": "Escopeta explosiva", "dmg": 10.0, "pellets": 4, "spread": 0.06, "cd": 1.0, "auto": false, "range": 30.0, "blast": 2.5, "knock": 6.0, "color": "ff6633"},
		{"name": "Ballesta", "dmg": 70.0, "pellets": 1, "spread": 0.0, "cd": 1.2, "auto": false, "range": 300.0, "blast": 0.0, "knock": 18.0, "color": "c8a064"},
		{"name": "Railgun", "dmg": 120.0, "pellets": 1, "spread": 0.0, "cd": 2.5, "auto": false, "range": 600.0, "blast": 0.0, "knock": 40.0, "color": "66ffff"},
		{"name": "Lanzagranadas", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 1.0, "auto": false, "range": 80.0, "blast": 5.0, "knock": 0.0, "color": "99ff55"},
		{"name": "Mini cohetes", "dmg": 0.0, "pellets": 1, "spread": 0.02, "cd": 0.35, "auto": true, "range": 200.0, "blast": 3.0, "knock": 0.0, "color": "ff7733"},
		{"name": "Mini nuke", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 5.0, "auto": false, "range": 400.0, "blast": 14.0, "knock": 0.0, "color": "ffff99"},
		{"name": "Pistola de gravedad", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 0.2, "auto": true, "range": 60.0, "blast": 0.0, "knock": -3.0, "color": "bb88ff"},
		{"name": "Cañón repulsor", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 0.3, "auto": false, "range": 60.0, "blast": 0.0, "knock": 40.0, "color": "ff88ff"},
		{"name": "Pistola congeladora", "dmg": 5.0, "pellets": 1, "spread": 0.0, "cd": 0.3, "auto": false, "range": 120.0, "blast": 0.0, "knock": 0.0, "freeze": true, "color": "aaeeff"},
		{"name": "Dardo tranquilizante", "dmg": 2.0, "pellets": 1, "spread": 0.0, "cd": 1.0, "auto": false, "range": 120.0, "blast": 0.0, "knock": 2.0, "stun": 5.0, "color": "88ff88"},
		{"name": "Bobina Tesla", "dmg": 20.0, "pellets": 1, "spread": 0.0, "cd": 0.15, "auto": true, "range": 30.0, "blast": 0.0, "knock": 3.0, "stun": 1.2, "color": "9999ff"},
		{"name": "Rayo", "dmg": 30.0, "pellets": 1, "spread": 0.0, "cd": 1.2, "auto": false, "range": 150.0, "blast": 0.0, "knock": 8.0, "stun": 1.5, "color": "ffff44"},
	]


static func _m(map_name: String, spawn: Vector3, boxes: Array) -> Dictionary:
	return {"name": map_name, "spawn": spawn, "boxes": boxes}


static func _b(size: Vector3, pos: Vector3, rot: Vector3 = Vector3.ZERO, color: String = "666677", tex: String = "") -> Dictionary:
	return {"size": size, "pos": pos, "rot": rot, "color": color, "tex": tex}


static func maps() -> Array:
	var out: Array = []
	out.append(_m("Plano", Vector3(0, 1, 0), []))
	out.append(_m("Rampas", Vector3(0, 1, 6), [
		_b(Vector3(6, 1, 6), Vector3(10, 0.5, -8), Vector3.ZERO, "9a6650"),
		_b(Vector3(8, 0.5, 4), Vector3(-10, 1.0, -8), Vector3(0, 0, 20), "4d80b3"),
		_b(Vector3(20, 4, 1), Vector3(0, 2, -20), Vector3.ZERO, "40404d"),
	]))
	out.append(_m("Arena", Vector3(0, 1, 14), [
		_b(Vector3(40, 4, 1), Vector3(0, 2, -20), Vector3.ZERO, "5a5a66"),
		_b(Vector3(40, 4, 1), Vector3(0, 2, 20), Vector3.ZERO, "5a5a66"),
		_b(Vector3(40, 4, 1), Vector3(-20, 2, 0), Vector3(0, 90, 0), "5a5a66"),
		_b(Vector3(40, 4, 1), Vector3(20, 2, 0), Vector3(0, 90, 0), "5a5a66"),
		_b(Vector3(3, 6, 3), Vector3(8, 3, 8), Vector3.ZERO, "b36b3c"),
		_b(Vector3(3, 6, 3), Vector3(-8, 3, 8), Vector3.ZERO, "b36b3c"),
		_b(Vector3(3, 6, 3), Vector3(8, 3, -8), Vector3.ZERO, "b36b3c"),
		_b(Vector3(3, 6, 3), Vector3(-8, 3, -8), Vector3.ZERO, "b36b3c"),
	]))
	out.append(_m("Torres", Vector3(0, 1, 10), [
		_b(Vector3(4, 4, 4), Vector3(-8, 2, -8), Vector3.ZERO, "3c8c6e"),
		_b(Vector3(3, 3, 3), Vector3(-8, 5.5, -8), Vector3.ZERO, "3c8c6e"),
		_b(Vector3(4, 4, 4), Vector3(8, 2, -8), Vector3.ZERO, "3c8c6e"),
		_b(Vector3(3, 3, 3), Vector3(8, 5.5, -8), Vector3.ZERO, "3c8c6e"),
		_b(Vector3(4, 4, 4), Vector3(0, 2, -16), Vector3.ZERO, "3c8c6e"),
		_b(Vector3(12, 0.5, 2), Vector3(0, 7, -12), Vector3.ZERO, "9a6650"),
	]))
	out.append(_m("Escaleras", Vector3(-20, 1, 0), _stairs()))
	out.append(_m("Laberinto", Vector3(-20, 1, -20), _maze()))
	out.append(_m("Pista", Vector3(25, 1, 0), _track()))
	out.append(_m("Caos", Vector3(0, 1, 0), _chaos()))
	out.append(_m("Espiral", Vector3(8, 1, 0), _spiral()))
	out.append(_m("Cubos flotantes", Vector3(0, 1, 20), _cubes()))
	out.append(_m("Puente", Vector3(-25, 1, 0), [
		_b(Vector3(4, 8, 4), Vector3(-15, 4, 0), Vector3.ZERO, "9a6650"),
		_b(Vector3(4, 8, 4), Vector3(15, 4, 0), Vector3.ZERO, "9a6650"),
		_b(Vector3(34, 0.6, 4), Vector3(0, 8, 0), Vector3.ZERO, "c8a064"),
	]))
	out.append(_m("Colinas", Vector3(0, 3, 0), _hills()))
	out.append(_m("Pirámide", Vector3(0, 1, 16), _pyramid()))
	out.append(_m("Tobogán", Vector3(-18, 11.5, 0), [
		_b(Vector3(10, 1, 10), Vector3(-18, 9.5, 0), Vector3.ZERO, "6b8e4e"),
		_b(Vector3(40, 0.5, 8), Vector3(2, 5, 0), Vector3(0, 0, -15), "4fc3f7"),
	]))
	out.append(_m("Cañón", Vector3(-28, 1, 0), [
		_b(Vector3(60, 12, 2), Vector3(0, 6, -10), Vector3.ZERO, "7a6a5a"),
		_b(Vector3(60, 12, 2), Vector3(0, 6, 10), Vector3.ZERO, "7a6a5a"),
		_b(Vector3(60, 0.5, 22), Vector3(0, 0, 0), Vector3.ZERO, "5a4a3a"),
	]))
	out.append(_m("Jaula", Vector3(0, 1, 0), [
		_b(Vector3(30, 6, 0.5), Vector3(0, 3, -15), Vector3.ZERO, "5c6b7a"),
		_b(Vector3(30, 6, 0.5), Vector3(0, 3, 15), Vector3.ZERO, "5c6b7a"),
		_b(Vector3(0.5, 6, 30), Vector3(-15, 3, 0), Vector3.ZERO, "5c6b7a"),
		_b(Vector3(0.5, 6, 30), Vector3(15, 3, 0), Vector3.ZERO, "5c6b7a"),
		_b(Vector3(30, 0.5, 30), Vector3(0, 6.2, 0), Vector3.ZERO, "40404d"),
	]))
	out.append(_m("Estadio", Vector3(0, 1, 0), _stadium()))
	out.append(_m("Plataformas", Vector3(0, 1, 0), _platforms()))
	out.append({"name": "Lago", "spawn": Vector3(0, 1, 32), "floor_y": -6.0, "water": -0.4, "boxes": _lake()})
	out.append_array(_more_maps())
	return out


static func _stairs() -> Array:
	var a: Array = []
	for i in 12:
		a.append(_b(Vector3(3, 0.5, 2), Vector3(i * 2.5 - 14, 0.25 + i * 0.6, 0), Vector3.ZERO, "7a7a8c"))
	return a


static func _maze() -> Array:
	var a: Array = []
	for i in 9:
		for j in 9:
			if (i * 7 + j * 3) % 4 == 0 and not (i == 0 and j == 0):
				a.append(_b(Vector3(4, 3, 0.5), Vector3(i * 4 - 16, 1.5, j * 4 - 16), Vector3.ZERO, "5c6b7a"))
	return a


static func _track() -> Array:
	var a: Array = []
	for i in 32:
		var ang: float = TAU * float(i) / 32.0
		a.append(_b(Vector3(5.5, 0.5, 4), Vector3(cos(ang) * 25.0, 0.25, sin(ang) * 25.0), Vector3(0, rad_to_deg(-(ang + PI / 2.0)), 0), "3d3d4d"))
	return a


static func _chaos() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var a: Array = []
	for i in 40:
		var pos := Vector3(rng.randf_range(-30.0, 30.0), rng.randf_range(0.5, 8.0), rng.randf_range(-30.0, 30.0))
		if Vector2(pos.x, pos.z).length() < 6.0:
			continue
		var size := Vector3(rng.randf_range(1.0, 5.0), rng.randf_range(0.5, 3.0), rng.randf_range(1.0, 5.0))
		var rot := Vector3(rng.randf_range(-15.0, 15.0), rng.randf_range(0.0, 360.0), rng.randf_range(-15.0, 15.0))
		var col := "%02x%02x%02x" % [rng.randi_range(60, 200), rng.randi_range(60, 200), rng.randi_range(60, 200)]
		a.append(_b(size, pos, rot, col))
	return a


static func _spiral() -> Array:
	var a: Array = []
	for i in 30:
		var ang: float = float(i) * 0.5
		a.append(_b(Vector3(4, 0.4, 3), Vector3(cos(ang) * 8.0, float(i) * 0.5, sin(ang) * 8.0), Vector3(0, rad_to_deg(-ang), 0), "9b59b6"))
	return a


static func _cubes() -> Array:
	var a: Array = []
	for x in 5:
		for y in 3:
			for z in 5:
				if (x + y + z) % 2 == 0:
					a.append(_b(Vector3(2, 0.4, 2), Vector3(x * 5.0 - 10.0, 4.0 + y * 4.0, z * 5.0 - 10.0), Vector3.ZERO, "4fc3f7"))
	return a


static func _hills() -> Array:
	var a: Array = []
	for i in 20:
		var ang: float = float(i) * 0.9
		var r: float = float(i) * 1.2
		a.append(_b(Vector3(6, 1, 6), Vector3(cos(ang) * r, float(i) * 0.4, sin(ang) * r), Vector3(rad_to_deg(0.15), rad_to_deg(ang), 0), "6b8e4e"))
	return a


static func _pyramid() -> Array:
	var a: Array = []
	for i in 8:
		var s: float = 20.0 - float(i) * 2.5
		a.append(_b(Vector3(s, 1, s), Vector3(0, 0.5 + float(i), 0), Vector3.ZERO, "d4a373"))
	return a


static func _stadium() -> Array:
	var a: Array = []
	for ring in 6:
		var r: float = 15.0 + float(ring) * 3.0
		var h: float = 1.0 + float(ring)
		for k in 16:
			var ang: float = TAU * float(k) / 16.0
			a.append(_b(Vector3(3.2, h, 3), Vector3(cos(ang) * r, h * 0.5, sin(ang) * r), Vector3(0, rad_to_deg(-ang), 0), "708090"))
	return a


static func _platforms() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var a: Array = []
	for i in 20:
		var size := Vector3(rng.randf_range(3.0, 6.0), 0.6, rng.randf_range(3.0, 6.0))
		var pos := Vector3(rng.randf_range(-20.0, 20.0), 2.0 + float(i) * 1.1, rng.randf_range(-20.0, 20.0))
		var rot := Vector3(0, rng.randf_range(0.0, 360.0), 0)
		a.append(_b(size, pos, rot, "e0c060"))
	return a


static func _lake() -> Array:
	var a: Array = []
	a.append(_b(Vector3(70, 6, 30), Vector3(0, -3, 35), Vector3.ZERO, "c2b280"))
	a.append(_b(Vector3(6, 0.5, 14), Vector3(0, -0.25, 12), Vector3.ZERO, "8b5a2b"))
	a.append(_b(Vector3(16, 6.5, 16), Vector3(0, -3, -70), Vector3.ZERO, "6b8e4e"))
	a.append(_b(Vector3(2, 1.5, 1.2), Vector3(0, 1.0, -70), Vector3.ZERO, "ffd700"))
	a.append(_b(Vector3(10, 6.5, 10), Vector3(-45, -3, -35), Vector3.ZERO, "6b8e4e"))
	a.append(_b(Vector3(10, 6.5, 10), Vector3(45, -3, -45), Vector3.ZERO, "6b8e4e"))
	return a


## Bloques de construcción (estilo Build a Boat). "density" define masa y flotación.
## "special": wheel, prop (hélice de agua), airprop (hélice de aire), jet, wing, balloon, cannon, seat, light.
## "power" multiplica la fuerza del bloque. "tex" es la textura procedural (ver textures.gd).
static func blocks() -> Dictionary:
	return {
		"Madera": {"shape": "box", "size": Vector3(1, 1, 1), "density": 0.5, "color": "b5834a", "tex": "wood"},
		"Plástico": {"shape": "box", "size": Vector3(1, 1, 1), "density": 0.4, "color": "f2f2f2"},
		"Metal": {"shape": "box", "size": Vector3(1, 1, 1), "density": 3.0, "color": "8a9099", "tex": "metal"},
		"Vidrio": {"shape": "box", "size": Vector3(1, 1, 1), "density": 0.6, "color": "9fe3ff", "alpha": 0.45},
		"Hielo": {"shape": "box", "size": Vector3(1, 1, 1), "density": 0.45, "color": "bfeaff", "tex": "ice", "alpha": 0.8},
		"Piedra": {"shape": "box", "size": Vector3(1, 1, 1), "density": 2.0, "color": "8a8a8a", "tex": "stone"},
		"Ladrillo": {"shape": "box", "size": Vector3(1, 0.5, 0.5), "density": 1.6, "color": "b5543a", "tex": "brick"},
		"Tabla": {"shape": "box", "size": Vector3(3, 0.25, 1), "density": 0.5, "color": "c8a064", "tex": "wood"},
		"Viga": {"shape": "box", "size": Vector3(0.5, 0.5, 3), "density": 0.5, "color": "8b5a2b", "tex": "wood"},
		"Placa": {"shape": "box", "size": Vector3(2, 0.25, 2), "density": 0.4, "color": "dddddd", "tex": "metal"},
		"Pilar": {"shape": "box", "size": Vector3(0.5, 2, 0.5), "density": 0.5, "color": "999999", "tex": "stone"},
		"Timón": {"shape": "box", "size": Vector3(0.15, 1.4, 1.1), "density": 0.3, "color": "dd3333"},
		"Bandera": {"shape": "box", "size": Vector3(1.5, 1, 0.05), "density": 0.05, "color": "ff3344", "tex": "cloth"},
		"Cilindro": {"shape": "cylinder", "size": Vector3(0.5, 1.0, 0.5), "density": 0.5, "color": "cc8844", "tex": "wood"},
		"Esfera": {"shape": "sphere", "size": Vector3(0.5, 0.5, 0.5), "density": 0.5, "color": "dd5566"},
		"Rueda": {"shape": "cylinder", "axis": "x", "size": Vector3(0.5, 0.35, 0.5), "density": 1.0, "color": "2a2a2a", "tex": "carbon", "special": "wheel"},
		"Rueda grande": {"shape": "cylinder", "axis": "x", "size": Vector3(0.9, 0.5, 0.9), "density": 1.0, "color": "2a2a2a", "tex": "carbon", "special": "wheel", "power": 1.6},
		"Hélice": {"shape": "box", "size": Vector3(1.8, 0.12, 0.3), "density": 1.0, "color": "bbbbbb", "special": "prop"},
		"Hélice de avión": {"shape": "box", "size": Vector3(2.2, 0.12, 0.3), "density": 0.6, "color": "dddddd", "special": "airprop"},
		"Propulsor": {"shape": "cylinder", "axis": "z", "size": Vector3(0.4, 1.0, 0.4), "density": 1.5, "color": "ff7a2a", "special": "jet"},
		"Propulsor grande": {"shape": "cylinder", "axis": "z", "size": Vector3(0.6, 1.4, 0.6), "density": 1.5, "color": "ff5522", "special": "jet", "power": 2.2},
		"Globo": {"shape": "sphere", "size": Vector3(0.7, 0.7, 0.7), "density": 0.02, "color": "ff3355", "special": "balloon"},
		"Cañón": {"shape": "cylinder", "axis": "z", "size": Vector3(0.35, 1.4, 0.35), "density": 2.0, "color": "444444", "tex": "metal", "special": "cannon"},
		"Bobina": {"shape": "sphere", "size": Vector3(0.22, 0.22, 0.22), "density": 0.5, "color": "ffe600", "special": "shock"},
		"Rotor": {"shape": "box", "size": Vector3(4, 0.1, 0.3), "density": 0.6, "color": "cccccc", "special": "rotor"},
		"Ala": {"shape": "box", "size": Vector3(6, 0.15, 1.5), "density": 0.3, "color": "eeeeee", "special": "wing"},
		"Asiento": {"shape": "box", "size": Vector3(1, 0.6, 1), "density": 0.5, "color": "7a4a2a", "tex": "cloth", "special": "seat"},
		"Luz": {"shape": "sphere", "size": Vector3(0.3, 0.3, 0.3), "density": 0.2, "color": "fff2a0", "special": "light"},
	}


# ================================================================ Objetos: 10 categorías nuevas

static func prop_categories() -> Array:
	return ["Básicos", "Muebles", "Deportes", "Comida", "Herramientas", "Construcción", "Naturaleza", "Juguetes", "Electrónica", "Contenedores", "Fantasía", "Vehículos"]


static func props() -> Dictionary:
	var out: Dictionary = _base_props()
	for k in out:
		var d: Dictionary = out[k]
		d["cat"] = "Básicos"
	out.merge(_extra_props())
	return out


static func _o(cat: String, shape: String, size: Vector3, mass: float, color: String, extra: Dictionary = {}) -> Dictionary:
	var d: Dictionary = {"cat": cat, "shape": shape, "size": size, "mass": mass, "color": color}
	d.merge(extra)
	return d


static func _pt(shape: String, size: Vector3, pos: Vector3, color: String, tex: String = "", rot: Vector3 = Vector3.ZERO) -> Dictionary:
	return {"shape": shape, "size": size, "pos": pos, "color": color, "tex": tex, "rot": rot}


static func _cmp(cat: String, mass: float, parts: Array) -> Dictionary:
	return {"cat": cat, "shape": "compound", "size": Vector3.ONE, "mass": mass, "color": "ffffff", "parts": parts}


static func _extra_props() -> Dictionary:
	var p: Dictionary = {}
	var X90 := Vector3(0, 0, 90)

	# ---- Muebles
	p["Mesa"] = _cmp("Muebles", 20.0, [
		_pt("box", Vector3(2.0, 0.15, 1.2), Vector3(0, 0.8, 0), "b5834a", "wood"),
		_pt("box", Vector3(0.15, 0.8, 0.15), Vector3(-0.85, 0.4, -0.45), "8b5a2b", "wood"),
		_pt("box", Vector3(0.15, 0.8, 0.15), Vector3(0.85, 0.4, -0.45), "8b5a2b", "wood"),
		_pt("box", Vector3(0.15, 0.8, 0.15), Vector3(-0.85, 0.4, 0.45), "8b5a2b", "wood"),
		_pt("box", Vector3(0.15, 0.8, 0.15), Vector3(0.85, 0.4, 0.45), "8b5a2b", "wood")])
	p["Silla"] = _cmp("Muebles", 6.0, [
		_pt("box", Vector3(0.7, 0.1, 0.7), Vector3(0, 0.5, 0), "b5834a", "wood"),
		_pt("box", Vector3(0.7, 0.8, 0.1), Vector3(0, 0.95, -0.3), "b5834a", "wood"),
		_pt("box", Vector3(0.08, 0.5, 0.08), Vector3(-0.3, 0.25, -0.3), "8b5a2b", "wood"),
		_pt("box", Vector3(0.08, 0.5, 0.08), Vector3(0.3, 0.25, -0.3), "8b5a2b", "wood"),
		_pt("box", Vector3(0.08, 0.5, 0.08), Vector3(-0.3, 0.25, 0.3), "8b5a2b", "wood"),
		_pt("box", Vector3(0.08, 0.5, 0.08), Vector3(0.3, 0.25, 0.3), "8b5a2b", "wood")])
	p["Sofá"] = _cmp("Muebles", 40.0, [
		_pt("box", Vector3(2.2, 0.5, 0.9), Vector3(0, 0.25, 0), "5566aa", "cloth"),
		_pt("box", Vector3(2.2, 0.7, 0.2), Vector3(0, 0.8, -0.35), "5566aa", "cloth"),
		_pt("box", Vector3(0.2, 0.6, 0.9), Vector3(-1.1, 0.55, 0), "445599", "cloth"),
		_pt("box", Vector3(0.2, 0.6, 0.9), Vector3(1.1, 0.55, 0), "445599", "cloth")])
	p["Cama"] = _cmp("Muebles", 45.0, [
		_pt("box", Vector3(2.0, 0.4, 2.2), Vector3(0, 0.2, 0), "8b5a2b", "wood"),
		_pt("box", Vector3(1.9, 0.25, 2.1), Vector3(0, 0.52, 0), "f2f2f2", "cloth"),
		_pt("box", Vector3(0.9, 0.15, 0.4), Vector3(0, 0.72, -0.8), "ffffff", "cloth")])
	p["Estantería"] = _cmp("Muebles", 25.0, [
		_pt("box", Vector3(1.4, 2.0, 0.08), Vector3(0, 1.0, -0.2), "8b5a2b", "wood"),
		_pt("box", Vector3(1.4, 0.06, 0.4), Vector3(0, 0.1, 0), "b5834a", "wood"),
		_pt("box", Vector3(1.4, 0.06, 0.4), Vector3(0, 0.7, 0), "b5834a", "wood"),
		_pt("box", Vector3(1.4, 0.06, 0.4), Vector3(0, 1.3, 0), "b5834a", "wood"),
		_pt("box", Vector3(1.4, 0.06, 0.4), Vector3(0, 1.9, 0), "b5834a", "wood"),
		_pt("box", Vector3(0.06, 2.0, 0.4), Vector3(-0.7, 1.0, 0), "8b5a2b", "wood"),
		_pt("box", Vector3(0.06, 2.0, 0.4), Vector3(0.7, 1.0, 0), "8b5a2b", "wood")])
	p["Lámpara de pie"] = _cmp("Muebles", 4.0, [
		_pt("cylinder", Vector3(0.3, 0.1, 0.3), Vector3(0, 0.05, 0), "333333", "metal"),
		_pt("cylinder", Vector3(0.04, 1.6, 0.04), Vector3(0, 0.9, 0), "333333", "metal"),
		_pt("sphere", Vector3(0.3, 0.3, 0.3), Vector3(0, 1.8, 0), "fff2a0")])

	# ---- Deportes
	p["Pelota de fútbol"] = _o("Deportes", "sphere", Vector3(0.28, 0.28, 0.28), 0.45, "ffffff", {"bounce": 0.7, "tex": "checker"})
	p["Pelota de básquet"] = _o("Deportes", "sphere", Vector3(0.3, 0.3, 0.3), 0.6, "e8731a", {"bounce": 0.8})
	p["Pelota de tenis"] = _o("Deportes", "sphere", Vector3(0.1, 0.1, 0.1), 0.06, "c8e83a", {"bounce": 0.75})
	p["Pelota de rugby"] = _o("Deportes", "capsule", Vector3(0.2, 0.7, 0.2), 0.4, "8b4a2b", {"bounce": 0.4})
	p["Bate"] = _o("Deportes", "cylinder", Vector3(0.05, 1.0, 0.05), 1.0, "c8a064", {"tex": "wood"})
	p["Pesa"] = _cmp("Deportes", 12.0, [
		_pt("cylinder", Vector3(0.04, 1.0, 0.04), Vector3(0, 0.1, 0), "666666", "metal", X90),
		_pt("cylinder", Vector3(0.3, 0.08, 0.3), Vector3(-0.4, 0.1, 0), "222222", "metal", X90),
		_pt("cylinder", Vector3(0.3, 0.08, 0.3), Vector3(0.4, 0.1, 0), "222222", "metal", X90)])
	p["Pelota de golf"] = _o("Deportes", "sphere", Vector3(0.05, 0.05, 0.05), 0.05, "ffffff", {"bounce": 0.8})

	# ---- Comida
	p["Manzana"] = _o("Comida", "sphere", Vector3(0.12, 0.12, 0.12), 0.2, "d62828")
	p["Banana"] = _o("Comida", "capsule", Vector3(0.06, 0.3, 0.06), 0.15, "f7d23e")
	p["Sandía"] = _o("Comida", "sphere", Vector3(0.35, 0.35, 0.35), 6.0, "2e8b3a")
	p["Zanahoria"] = _o("Comida", "cone", Vector3(0.06, 0.3, 0.06), 0.1, "f28c28")
	p["Pizza"] = _o("Comida", "cylinder", Vector3(0.35, 0.04, 0.35), 0.5, "e8a23a")
	p["Hamburguesa"] = _cmp("Comida", 0.4, [
		_pt("cylinder", Vector3(0.18, 0.07, 0.18), Vector3(0, 0.035, 0), "d89a4a"),
		_pt("cylinder", Vector3(0.19, 0.05, 0.19), Vector3(0, 0.095, 0), "5a3a1a"),
		_pt("cylinder", Vector3(0.2, 0.02, 0.2), Vector3(0, 0.13, 0), "4caf50"),
		_pt("cylinder", Vector3(0.18, 0.07, 0.18), Vector3(0, 0.175, 0), "d89a4a")])
	p["Torta"] = _cmp("Comida", 3.0, [
		_pt("cylinder", Vector3(0.35, 0.2, 0.35), Vector3(0, 0.1, 0), "f5d7a1"),
		_pt("cylinder", Vector3(0.27, 0.18, 0.27), Vector3(0, 0.29, 0), "ff9ecb"),
		_pt("sphere", Vector3(0.05, 0.05, 0.05), Vector3(0, 0.42, 0), "d62828")])

	# ---- Herramientas
	p["Martillo"] = _cmp("Herramientas", 1.5, [
		_pt("cylinder", Vector3(0.03, 0.5, 0.03), Vector3(0, 0.25, 0), "b5834a", "wood"),
		_pt("box", Vector3(0.25, 0.1, 0.1), Vector3(0, 0.52, 0), "777777", "metal")])
	p["Pala"] = _cmp("Herramientas", 2.0, [
		_pt("cylinder", Vector3(0.03, 1.1, 0.03), Vector3(0, 0.55, 0), "b5834a", "wood"),
		_pt("box", Vector3(0.25, 0.3, 0.03), Vector3(0, 1.2, 0), "888888", "metal")])
	p["Hacha"] = _cmp("Herramientas", 2.0, [
		_pt("cylinder", Vector3(0.03, 0.8, 0.03), Vector3(0, 0.4, 0), "b5834a", "wood"),
		_pt("box", Vector3(0.2, 0.18, 0.04), Vector3(0.1, 0.75, 0), "888888", "metal")])
	p["Caja de herramientas"] = _o("Herramientas", "box", Vector3(0.6, 0.3, 0.3), 4.0, "cc2222", {"tex": "metal"})
	p["Balde"] = _o("Herramientas", "cylinder", Vector3(0.2, 0.3, 0.2), 1.0, "2a6fdb")
	p["Escalera"] = _cmp("Herramientas", 8.0, [
		_pt("box", Vector3(0.06, 2.0, 0.06), Vector3(-0.25, 1.0, 0), "cccccc", "metal"),
		_pt("box", Vector3(0.06, 2.0, 0.06), Vector3(0.25, 1.0, 0), "cccccc", "metal"),
		_pt("box", Vector3(0.5, 0.05, 0.05), Vector3(0, 0.3, 0), "aaaaaa", "metal"),
		_pt("box", Vector3(0.5, 0.05, 0.05), Vector3(0, 0.75, 0), "aaaaaa", "metal"),
		_pt("box", Vector3(0.5, 0.05, 0.05), Vector3(0, 1.2, 0), "aaaaaa", "metal"),
		_pt("box", Vector3(0.5, 0.05, 0.05), Vector3(0, 1.65, 0), "aaaaaa", "metal")])

	# ---- Construcción
	p["Bolsa de cemento"] = _o("Construcción", "box", Vector3(0.6, 0.15, 0.4), 25.0, "9a9a9a", {"tex": "stone"})
	p["Viga de acero"] = _o("Construcción", "box", Vector3(0.2, 0.2, 3.0), 60.0, "7f8a99", {"tex": "metal"})
	p["Tubería"] = _o("Construcción", "cylinder", Vector3(0.2, 2.0, 0.2), 25.0, "8a9099", {"tex": "metal"})
	p["Cono de tránsito"] = _o("Construcción", "cone", Vector3(0.2, 0.6, 0.2), 1.5, "ff6a00")
	p["Valla"] = _cmp("Construcción", 15.0, [
		_pt("box", Vector3(0.1, 1.2, 0.1), Vector3(-1.0, 0.6, 0), "999999", "metal"),
		_pt("box", Vector3(0.1, 1.2, 0.1), Vector3(1.0, 0.6, 0), "999999", "metal"),
		_pt("box", Vector3(2.1, 0.1, 0.05), Vector3(0, 1.0, 0), "ff6a00"),
		_pt("box", Vector3(2.1, 0.1, 0.05), Vector3(0, 0.5, 0), "ff6a00")])
	p["Barrera de concreto"] = _o("Construcción", "box", Vector3(2.0, 0.8, 0.5), 120.0, "aaaaaa", {"tex": "stone"})
	p["Pallet"] = _cmp("Construcción", 10.0, [
		_pt("box", Vector3(1.2, 0.08, 1.0), Vector3(0, 0.16, 0), "c8a064", "wood"),
		_pt("box", Vector3(1.2, 0.1, 0.15), Vector3(0, 0.05, -0.4), "a67c40", "wood"),
		_pt("box", Vector3(1.2, 0.1, 0.15), Vector3(0, 0.05, 0), "a67c40", "wood"),
		_pt("box", Vector3(1.2, 0.1, 0.15), Vector3(0, 0.05, 0.4), "a67c40", "wood")])

	# ---- Naturaleza
	p["Roca chica"] = _o("Naturaleza", "sphere", Vector3(0.3, 0.3, 0.3), 15.0, "777777", {"tex": "stone"})
	p["Roca grande"] = _o("Naturaleza", "sphere", Vector3(0.8, 0.8, 0.8), 120.0, "6b6b6b", {"tex": "stone"})
	p["Tronco"] = _o("Naturaleza", "cylinder", Vector3(0.25, 2.0, 0.25), 40.0, "7a5230", {"tex": "wood"})
	p["Árbol"] = _cmp("Naturaleza", 80.0, [
		_pt("cylinder", Vector3(0.25, 2.0, 0.25), Vector3(0, 1.0, 0), "7a5230", "wood"),
		_pt("sphere", Vector3(1.2, 1.2, 1.2), Vector3(0, 2.8, 0), "3f8f3a", "grass")])
	p["Pino"] = _cmp("Naturaleza", 70.0, [
		_pt("cylinder", Vector3(0.2, 1.2, 0.2), Vector3(0, 0.6, 0), "6b4a2a", "wood"),
		_pt("cone", Vector3(1.0, 3.0, 1.0), Vector3(0, 2.6, 0), "2e6f3a", "grass")])
	p["Cactus"] = _cmp("Naturaleza", 15.0, [
		_pt("capsule", Vector3(0.3, 2.0, 0.3), Vector3(0, 1.0, 0), "4c9a52"),
		_pt("capsule", Vector3(0.15, 0.8, 0.15), Vector3(0.45, 1.2, 0), "4c9a52"),
		_pt("capsule", Vector3(0.15, 0.7, 0.15), Vector3(-0.45, 0.9, 0), "4c9a52")])
	p["Arbusto"] = _o("Naturaleza", "sphere", Vector3(0.6, 0.6, 0.6), 8.0, "3a7a35", {"tex": "grass"})

	# ---- Juguetes
	p["Cubo de juguete"] = _o("Juguetes", "box", Vector3(0.5, 0.5, 0.5), 1.0, "e63946")
	p["Dado"] = _o("Juguetes", "box", Vector3(0.3, 0.3, 0.3), 0.3, "f5f5f5", {"bounce": 0.3})
	p["Oso de peluche"] = _cmp("Juguetes", 1.5, [
		_pt("sphere", Vector3(0.35, 0.35, 0.35), Vector3(0, 0.35, 0), "9c6b3e", "cloth"),
		_pt("sphere", Vector3(0.22, 0.22, 0.22), Vector3(0, 0.78, 0), "9c6b3e", "cloth"),
		_pt("sphere", Vector3(0.09, 0.09, 0.09), Vector3(-0.17, 0.96, 0), "9c6b3e", "cloth"),
		_pt("sphere", Vector3(0.09, 0.09, 0.09), Vector3(0.17, 0.96, 0), "9c6b3e", "cloth")])
	p["Robot de juguete"] = _cmp("Juguetes", 3.0, [
		_pt("box", Vector3(0.5, 0.6, 0.35), Vector3(0, 0.6, 0), "8a9099", "metal"),
		_pt("box", Vector3(0.35, 0.3, 0.3), Vector3(0, 1.05, 0), "aab2bd", "metal"),
		_pt("box", Vector3(0.12, 0.5, 0.12), Vector3(-0.35, 0.6, 0), "6b7280", "metal"),
		_pt("box", Vector3(0.12, 0.5, 0.12), Vector3(0.35, 0.6, 0), "6b7280", "metal"),
		_pt("box", Vector3(0.15, 0.35, 0.15), Vector3(-0.15, 0.18, 0), "6b7280", "metal"),
		_pt("box", Vector3(0.15, 0.35, 0.15), Vector3(0.15, 0.18, 0), "6b7280", "metal")])
	p["Pato de goma"] = _cmp("Juguetes", 0.4, [
		_pt("sphere", Vector3(0.25, 0.25, 0.25), Vector3(0, 0.25, 0), "ffdd33"),
		_pt("sphere", Vector3(0.15, 0.15, 0.15), Vector3(0, 0.5, -0.1), "ffdd33"),
		_pt("box", Vector3(0.12, 0.05, 0.1), Vector3(0, 0.48, -0.27), "ff8800")])
	p["Trompo"] = _o("Juguetes", "cone", Vector3(0.25, 0.4, 0.25), 0.5, "ff4fa3")
	p["Muñeco de nieve"] = _cmp("Juguetes", 10.0, [
		_pt("sphere", Vector3(0.5, 0.5, 0.5), Vector3(0, 0.5, 0), "ffffff", "ice"),
		_pt("sphere", Vector3(0.38, 0.38, 0.38), Vector3(0, 1.2, 0), "ffffff", "ice"),
		_pt("sphere", Vector3(0.27, 0.27, 0.27), Vector3(0, 1.75, 0), "ffffff", "ice"),
		_pt("cone", Vector3(0.05, 0.25, 0.05), Vector3(0, 1.75, -0.3), "ff7a00", "", Vector3(-90, 0, 0))])

	# ---- Electrónica
	p["Televisor"] = _cmp("Electrónica", 12.0, [
		_pt("box", Vector3(1.2, 0.7, 0.1), Vector3(0, 0.75, 0), "111111"),
		_pt("box", Vector3(1.1, 0.6, 0.02), Vector3(0, 0.75, -0.06), "2a5caa"),
		_pt("box", Vector3(0.4, 0.05, 0.25), Vector3(0, 0.38, 0), "222222")])
	p["Computadora"] = _cmp("Electrónica", 8.0, [
		_pt("box", Vector3(0.6, 0.4, 0.05), Vector3(0, 0.55, 0), "1a1a1a"),
		_pt("box", Vector3(0.55, 0.33, 0.02), Vector3(0, 0.55, -0.03), "4aa3e8"),
		_pt("box", Vector3(0.15, 0.2, 0.15), Vector3(0, 0.25, 0.05), "444444"),
		_pt("box", Vector3(0.5, 0.03, 0.18), Vector3(0, 0.02, -0.3), "dddddd")])
	p["Parlante"] = _o("Electrónica", "box", Vector3(0.4, 0.7, 0.4), 6.0, "1c1c1c")
	p["Microondas"] = _o("Electrónica", "box", Vector3(0.6, 0.35, 0.4), 10.0, "c8c8cc", {"tex": "metal"})
	p["Heladera"] = _o("Electrónica", "box", Vector3(0.7, 1.8, 0.7), 70.0, "f2f2f2", {"tex": "metal"})
	p["Batería"] = _o("Electrónica", "cylinder", Vector3(0.1, 0.4, 0.1), 1.0, "3aa655")

	# ---- Contenedores
	p["Caja de madera"] = _o("Contenedores", "box", Vector3(1, 1, 1), 8.0, "b5834a", {"tex": "wood"})
	p["Cofre del tesoro"] = _cmp("Contenedores", 20.0, [
		_pt("box", Vector3(0.8, 0.4, 0.5), Vector3(0, 0.2, 0), "8b5a2b", "wood"),
		_pt("box", Vector3(0.8, 0.2, 0.5), Vector3(0, 0.5, 0), "7a4a2a", "wood"),
		_pt("box", Vector3(0.12, 0.62, 0.52), Vector3(0, 0.31, 0), "ffd700", "metal")])
	p["Barril de madera"] = _o("Contenedores", "cylinder", Vector3(0.45, 1.0, 0.45), 15.0, "8b5a2b", {"tex": "wood"})
	p["Bidón azul"] = _o("Contenedores", "cylinder", Vector3(0.35, 0.9, 0.35), 12.0, "2a6fdb")
	p["Contenedor marítimo"] = _o("Contenedores", "box", Vector3(6.0, 2.4, 2.4), 400.0, "cc4422", {"tex": "metal"})
	p["Maleta"] = _o("Contenedores", "box", Vector3(0.7, 0.45, 0.25), 4.0, "5a3a22")
	p["Cubo de basura"] = _o("Contenedores", "cylinder", Vector3(0.3, 0.8, 0.3), 3.0, "6b7280", {"tex": "metal"})
	p["Caja fuerte"] = _o("Contenedores", "box", Vector3(0.8, 0.8, 0.8), 200.0, "444b55", {"tex": "metal"})

	# ---- Fantasía y espacio
	p["Cristal"] = _o("Fantasía", "cone", Vector3(0.4, 1.2, 0.4), 6.0, "7ad0ff", {"tex": "ice"})
	p["Meteorito"] = _o("Fantasía", "sphere", Vector3(0.6, 0.6, 0.6), 80.0, "3a2f2a", {"tex": "stone"})
	p["OVNI"] = _cmp("Fantasía", 40.0, [
		_pt("cylinder", Vector3(1.2, 0.15, 1.2), Vector3(0, 0.15, 0), "9aa5b1", "metal"),
		_pt("sphere", Vector3(0.5, 0.5, 0.5), Vector3(0, 0.35, 0), "9fe3ff")])
	p["Cohete"] = _cmp("Fantasía", 30.0, [
		_pt("cylinder", Vector3(0.4, 2.0, 0.4), Vector3(0, 1.0, 0), "f2f2f2", "metal"),
		_pt("cone", Vector3(0.4, 0.9, 0.4), Vector3(0, 2.45, 0), "d62828"),
		_pt("box", Vector3(0.7, 0.5, 0.05), Vector3(0, 0.25, 0), "d62828"),
		_pt("box", Vector3(0.05, 0.5, 0.7), Vector3(0, 0.25, 0), "d62828")])
	p["Poción"] = _cmp("Fantasía", 0.6, [
		_pt("sphere", Vector3(0.25, 0.25, 0.25), Vector3(0, 0.25, 0), "ff4fa3"),
		_pt("cylinder", Vector3(0.07, 0.25, 0.07), Vector3(0, 0.55, 0), "dddddd")])
	p["Huevo de dragón"] = _o("Fantasía", "capsule", Vector3(0.3, 0.8, 0.3), 12.0, "2f9e6a", {"tex": "stone"})
	p["Orbe mágico"] = _o("Fantasía", "sphere", Vector3(0.3, 0.3, 0.3), 2.0, "ffd54a", {"bounce": 0.6})
	return p


# ================================================================ Vehículos prearmados
## Cada bloque: k = bloque, p = posición local, c = color hex (opcional), s = tamaño (solo cajas), r = rotación en grados.
## El frente del vehículo es -Z. Se manejan sentándote (E): WASD, Espacio/C inclinan aviones, click dispara cañones.

static func _e(k: String, p: Vector3, c: String = "", s: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO) -> Dictionary:
	return {"k": k, "p": p, "c": c, "s": s, "r": r}


static func _wheels4(x: float, y: float, z1: float, z2: float, kind: String = "Rueda") -> Array:
	return [_e(kind, Vector3(-x, y, z1)), _e(kind, Vector3(x, y, z1)), _e(kind, Vector3(-x, y, z2)), _e(kind, Vector3(x, y, z2))]


static func prefabs() -> Dictionary:
	var v: Dictionary = {}

	var car: Array = [
		_e("Metal", Vector3(0, 0, 0), "cc2222", Vector3(2.0, 0.4, 4.2)),
		_e("Vidrio", Vector3(0, 0.55, 0.4), "", Vector3(1.7, 0.7, 1.8)),
		_e("Plástico", Vector3(0, 0.95, 0.4), "cc2222", Vector3(1.7, 0.12, 1.8)),
		_e("Asiento", Vector3(0, 0.38, 0.5)),
		_e("Luz", Vector3(-0.7, 0.05, -2.15)), _e("Luz", Vector3(0.7, 0.05, -2.15))]
	car.append_array(_wheels4(1.15, -0.1, -1.4, 1.4))
	v["Auto"] = {"cat": "Autos", "blocks": car}

	var sport: Array = [
		_e("Plástico", Vector3(0, 0, 0), "ffb300", Vector3(1.9, 0.3, 4.4)),
		_e("Vidrio", Vector3(0, 0.4, 0.6), "", Vector3(1.4, 0.5, 1.6)),
		_e("Asiento", Vector3(0, 0.2, 0.7)),
		_e("Propulsor", Vector3(-0.5, 0.1, 2.3)), _e("Propulsor", Vector3(0.5, 0.1, 2.3)),
		_e("Timón", Vector3(0, 0.5, 2.0), "ffb300")]
	sport.append_array(_wheels4(1.1, -0.1, -1.5, 1.5, "Rueda grande"))
	v["Deportivo turbo"] = {"cat": "Autos", "blocks": sport}

	var buggy: Array = [
		_e("Metal", Vector3(0, 0, 0), "3a8f3a", Vector3(1.6, 0.3, 3.0)),
		_e("Pilar", Vector3(-0.7, 0.9, 0.3), "dddddd"), _e("Pilar", Vector3(0.7, 0.9, 0.3), "dddddd"),
		_e("Viga", Vector3(0, 1.85, 0.3), "dddddd", Vector3(1.6, 0.2, 0.2)),
		_e("Asiento", Vector3(0, 0.38, 0.3)),
		_e("Luz", Vector3(0, 0.1, -1.6))]
	buggy.append_array(_wheels4(1.2, 0.0, -1.1, 1.1, "Rueda grande"))
	v["Buggy"] = {"cat": "Autos", "blocks": buggy}

	var truck: Array = [
		_e("Metal", Vector3(0, 0, 0), "3366cc", Vector3(2.2, 0.5, 7.0)),
		_e("Metal", Vector3(0, 1.05, -2.6), "3366cc", Vector3(2.0, 1.6, 1.8)),
		_e("Vidrio", Vector3(0, 1.3, -3.55), "", Vector3(1.8, 0.6, 0.1)),
		_e("Asiento", Vector3(0, 0.55, -2.4)),
		_e("Madera", Vector3(0, 1.05, 1.4), "b5834a", Vector3(2.1, 1.6, 3.8)),
		_e("Luz", Vector3(-0.7, 0.4, -3.55)), _e("Luz", Vector3(0.7, 0.4, -3.55))]
	truck.append_array(_wheels4(1.35, -0.2, -2.4, 0.5, "Rueda grande"))
	truck.append(_e("Rueda grande", Vector3(-1.35, -0.2, 2.8)))
	truck.append(_e("Rueda grande", Vector3(1.35, -0.2, 2.8)))
	v["Camión"] = {"cat": "Autos", "blocks": truck}

	var tank: Array = [
		_e("Metal", Vector3(0, 0, 0), "5a6b3a", Vector3(2.6, 0.8, 4.6)),
		_e("Metal", Vector3(0, 0.7, 0.2), "4d5c30", Vector3(1.6, 0.6, 1.6)),
		_e("Cañón", Vector3(0, 0.75, -1.5)),
		_e("Asiento", Vector3(0, 0.45, 1.0))]
	tank.append_array(_wheels4(1.5, -0.3, -1.7, 0.0, "Rueda grande"))
	tank.append(_e("Rueda grande", Vector3(-1.5, -0.3, 1.7)))
	tank.append(_e("Rueda grande", Vector3(1.5, -0.3, 1.7)))
	v["Tanque"] = {"cat": "Autos", "blocks": tank}

	v["Bote"] = {"cat": "Barcos", "blocks": [
		_e("Madera", Vector3(0, 0, 0), "b5834a", Vector3(2.4, 0.5, 5.0)),
		_e("Madera", Vector3(-1.1, 0.55, 0), "8b5a2b", Vector3(0.2, 0.6, 5.0)),
		_e("Madera", Vector3(1.1, 0.55, 0), "8b5a2b", Vector3(0.2, 0.6, 5.0)),
		_e("Madera", Vector3(0, 0.55, -2.4), "8b5a2b", Vector3(2.0, 0.6, 0.2)),
		_e("Asiento", Vector3(0, 0.55, 0.8)),
		_e("Hélice", Vector3(0, -0.3, 2.75)),
		_e("Pilar", Vector3(0, 1.2, -0.6), "8b5a2b"),
		_e("Bandera", Vector3(0.8, 1.9, -0.6))]}

	v["Lancha"] = {"cat": "Barcos", "blocks": [
		_e("Plástico", Vector3(0, 0, 0), "f2f2f2", Vector3(2.0, 0.4, 5.5)),
		_e("Plástico", Vector3(0, 0.45, -1.8), "2a6fdb", Vector3(1.8, 0.5, 1.4)),
		_e("Vidrio", Vector3(0, 0.95, -0.6), "", Vector3(1.6, 0.5, 0.15)),
		_e("Asiento", Vector3(0, 0.5, 0.2)),
		_e("Hélice", Vector3(-0.5, -0.3, 2.9)), _e("Hélice", Vector3(0.5, -0.3, 2.9)),
		_e("Luz", Vector3(0, 0.3, -2.8))]}

	v["Barco pirata"] = {"cat": "Barcos", "blocks": [
		_e("Madera", Vector3(0, 0, 0), "7a4a2a", Vector3(4.0, 1.0, 9.0)),
		_e("Tabla", Vector3(0, 0.55, 0), "c8a064", Vector3(3.6, 0.1, 8.5)),
		_e("Pilar", Vector3(0, 3.0, 0.0), "8b5a2b", Vector3(0.5, 5.0, 0.5)),
		_e("Placa", Vector3(0, 3.6, -0.5), "f2f2f2", Vector3(3.0, 3.0, 0.1)),
		_e("Bandera", Vector3(0.8, 5.8, 0.0), "111111"),
		_e("Cañón", Vector3(-2.2, 1.0, -1.5), "", Vector3.ZERO, Vector3(0, 90, 0)),
		_e("Cañón", Vector3(-2.2, 1.0, 1.5), "", Vector3.ZERO, Vector3(0, 90, 0)),
		_e("Cañón", Vector3(2.2, 1.0, -1.5), "", Vector3.ZERO, Vector3(0, -90, 0)),
		_e("Cañón", Vector3(2.2, 1.0, 1.5), "", Vector3.ZERO, Vector3(0, -90, 0)),
		_e("Cañón", Vector3(0, 1.0, -4.8)),
		_e("Asiento", Vector3(0, 1.1, 3.0)),
		_e("Hélice", Vector3(-1.0, -0.4, 4.7)), _e("Hélice", Vector3(1.0, -0.4, 4.7)), _e("Hélice", Vector3(0, -0.4, 4.7))]}

	var plane_gear: Array = [_e("Rueda", Vector3(0, -0.8, -1.6)), _e("Rueda", Vector3(-1.0, -0.8, 0.9)), _e("Rueda", Vector3(1.0, -0.8, 0.9))]

	var small: Array = [
		_e("Madera", Vector3(0, 0, 0), "ffffff", Vector3(1.1, 1.0, 4.5)),
		_e("Madera", Vector3(0, 0, -2.6), "cc2222", Vector3(0.9, 0.8, 0.8)),
		_e("Ala", Vector3(-3.55, 0.15, -0.2)), _e("Ala", Vector3(3.55, 0.15, -0.2)),
		_e("Ala", Vector3(0, 0.25, 2.2), "", Vector3(3.0, 0.12, 1.0)),
		_e("Timón", Vector3(0, 0.9, 2.1), "cc2222"),
		_e("Hélice de avión", Vector3(0, 0, -3.1)),
		_e("Asiento", Vector3(0, 0.1, 0.3))]
	small.append_array(plane_gear)
	v["Avioneta"] = {"cat": "Aviones", "blocks": small}

	var jet: Array = [
		_e("Plástico", Vector3(0, 0, 0), "dddddd", Vector3(1.4, 1.2, 7.0)),
		_e("Plástico", Vector3(0, 0, -4.0), "888888", Vector3(1.0, 0.9, 1.2)),
		_e("Vidrio", Vector3(0, 0.85, -1.2), "", Vector3(0.9, 0.5, 1.4)),
		_e("Ala", Vector3(-4.2, 0.0, 0.5), "cccccc", Vector3(7.0, 0.15, 2.0)),
		_e("Ala", Vector3(4.2, 0.0, 0.5), "cccccc", Vector3(7.0, 0.15, 2.0)),
		_e("Ala", Vector3(0, 0.2, 3.2), "cccccc", Vector3(3.6, 0.12, 1.2)),
		_e("Timón", Vector3(0, 1.0, 3.0), "dd3333"),
		_e("Propulsor grande", Vector3(-0.6, 0, 3.9)), _e("Propulsor grande", Vector3(0.6, 0, 3.9)),
		_e("Asiento", Vector3(0, 0.45, -1.2))]
	jet.append_array([_e("Rueda", Vector3(0, -0.9, -2.5)), _e("Rueda", Vector3(-1.0, -0.9, 1.5)), _e("Rueda", Vector3(1.0, -0.9, 1.5))])
	v["Avión a reacción"] = {"cat": "Aviones", "blocks": jet}

	var fighter: Array = jet.duplicate()
	fighter.append(_e("Cañón", Vector3(-2.0, -0.1, -0.8)))
	fighter.append(_e("Cañón", Vector3(2.0, -0.1, -0.8)))
	fighter.append(_e("Propulsor grande", Vector3(0, 0.1, 3.9)))
	v["Caza de combate"] = {"cat": "Aviones", "blocks": fighter}
	v["Silla eléctrica"] = {"cat": "Vehículos", "blocks": [
		_e("Metal", Vector3(0, -0.12, 0), "3a3f4c", Vector3(1.1, 0.16, 1.1)),
		_e("Metal", Vector3(-0.42, -0.42, -0.42), "2a2e38", Vector3(0.14, 0.44, 0.14)),
		_e("Metal", Vector3(0.42, -0.42, -0.42), "2a2e38", Vector3(0.14, 0.44, 0.14)),
		_e("Metal", Vector3(-0.42, -0.42, 0.42), "2a2e38", Vector3(0.14, 0.44, 0.14)),
		_e("Metal", Vector3(0.42, -0.42, 0.42), "2a2e38", Vector3(0.14, 0.44, 0.14)),
		_e("Asiento", Vector3(0, 0.3, 0.0), "5a3a2a", Vector3(0.9, 0.22, 0.9)),
		_e("Metal", Vector3(0, 0.95, 0.4), "555a66", Vector3(0.9, 1.3, 0.14)),
		_e("Metal", Vector3(0, 1.7, 0.42), "2a2e38", Vector3(0.5, 0.36, 0.16)),
		_e("Metal", Vector3(-0.5, 0.62, 0.0), "2a2e38", Vector3(0.14, 0.14, 0.9)),
		_e("Metal", Vector3(0.5, 0.62, 0.0), "2a2e38", Vector3(0.14, 0.14, 0.9)),
		_e("Bobina", Vector3(-0.5, 0.74, 0.02)),
		_e("Bobina", Vector3(0.5, 0.74, 0.02)),
		_e("Bobina", Vector3(0, 1.7, 0.52)),
		_e("Bobina", Vector3(-0.3, 0.25, 0.52)),
		_e("Bobina", Vector3(0.3, 0.25, 0.52))]}
	v["Helicóptero"] = {"cat": "Aviones", "blocks": [
		_e("Plástico", Vector3(0, 0, 0), "2a6fdb", Vector3(1.6, 1.4, 2.6)),
		_e("Vidrio", Vector3(0, 0.2, -1.35), "", Vector3(1.4, 0.9, 0.1)),
		_e("Metal", Vector3(0, 0.1, 2.0), "2a6fdb", Vector3(0.4, 0.4, 3.0)),
		_e("Rotor", Vector3(0, 1.0, 0)),
		_e("Hélice de avión", Vector3(0.3, 0.2, 3.6)),
		_e("Asiento", Vector3(0, -0.45, -0.4)),
		_e("Rueda", Vector3(-0.8, -0.9, 0.0)), _e("Rueda", Vector3(0.8, -0.9, 0.0))]}
	v["Avión de hélice"] = {"cat": "Aviones", "blocks": [
		_e("Plástico", Vector3(0, 0, 0), "f2f2f2", Vector3(1.2, 1.1, 6.0)),
		_e("Ala", Vector3(-3.6, 0.0, -0.2), "cc4422", Vector3(6.0, 0.15, 1.6)),
		_e("Ala", Vector3(3.6, 0.0, -0.2), "cc4422", Vector3(6.0, 0.15, 1.6)),
		_e("Ala", Vector3(0, 0.25, 2.4), "cc4422", Vector3(3.0, 0.12, 1.0)),
		_e("Timón", Vector3(0, 0.9, 2.6), "cc4422"),
		_e("Hélice de avión", Vector3(0, 0, -3.1)),
		_e("Asiento", Vector3(0, 0.45, -0.9)),
		_e("Rueda", Vector3(0, -0.8, -1.8)), _e("Rueda", Vector3(-1.0, -0.8, 0.9)), _e("Rueda", Vector3(1.0, -0.8, 0.9))]}
	v["Jumbo"] = {"cat": "Aviones", "blocks": [
		_e("Plástico", Vector3(0, 0, 0), "eeeeee", Vector3(1.8, 1.8, 12.0)),
		_e("Vidrio", Vector3(0, 0.45, -5.4), "", Vector3(1.4, 0.4, 0.1)),
		_e("Ala", Vector3(-5.0, -0.2, 0.5), "bbbbbb", Vector3(10.0, 0.2, 2.8)),
		_e("Ala", Vector3(5.0, -0.2, 0.5), "bbbbbb", Vector3(10.0, 0.2, 2.8)),
		_e("Propulsor grande", Vector3(-3.0, -0.6, 0.3)), _e("Propulsor grande", Vector3(3.0, -0.6, 0.3)),
		_e("Timón", Vector3(0, 1.6, 5.2), "eeeeee", Vector3(0.15, 2.6, 1.8)),
		_e("Ala", Vector3(0, 0.6, 5.0), "bbbbbb", Vector3(3.6, 0.12, 1.2)),
		_e("Asiento", Vector3(0, 0.95, -4.0)),
		_e("Rueda", Vector3(-0.9, -1.2, -4.0)), _e("Rueda", Vector3(0.9, -1.2, -4.0)), _e("Rueda", Vector3(0, -1.2, 3.0))]}
	return v


# ================================================================ Mapas nuevos

static func _more_maps() -> Array:
	var out: Array = []
	out.append(_m("Aeropuerto", Vector3(0, 1, 40), _airport()))
	out.append(_m("Ciudad", Vector3(0, 1, 0), _city()))
	out.append(_m("Desierto", Vector3(0, 1, 30), _desert()))
	out.append(_m("Nieve", Vector3(0, 1, 20), _snow()))
	out.append(_m("Volcán", Vector3(0, 1, 30), _volcano()))
	out.append({"name": "Isla", "spawn": Vector3(0, 1, 0), "floor_y": -6.0, "water": -0.4, "boxes": _island()})
	out.append(_m("Parque skate", Vector3(0, 1, 20), _skate()))
	out.append(_m("Rampas de saltos", Vector3(0, 1, 40), _jumps()))
	out.append(_m("Rascacielos", Vector3(0, 1, 30), _towers2()))
	out.append({"name": "Puerto", "spawn": Vector3(0, 1, 28), "floor_y": -6.0, "water": -0.4, "boxes": _harbor()})
	return out


static func _airport() -> Array:
	var a: Array = []
	a.append(_b(Vector3(24, 0.2, 260), Vector3(0, 0.0, -80), Vector3.ZERO, "2b2b30", "carbon"))
	for i in 20:
		a.append(_b(Vector3(0.6, 0.22, 6), Vector3(0, 0.01, 30.0 - float(i) * 12.0), Vector3.ZERO, "f2f2f2"))
	a.append(_b(Vector3(34, 8, 12), Vector3(-34, 4, 20), Vector3.ZERO, "9aa0a8", "metal"))
	a.append(_b(Vector3(5, 20, 5), Vector3(-34, 10, 38), Vector3.ZERO, "c0c0c0", "metal"))
	a.append(_b(Vector3(18, 9, 16), Vector3(38, 4.5, 0), Vector3.ZERO, "7a8a9a", "metal"))
	a.append(_b(Vector3(18, 9, 16), Vector3(38, 4.5, -30), Vector3.ZERO, "7a8a9a", "metal"))
	return a


static func _city() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var a: Array = []
	for ix in 6:
		for iz in 6:
			var x: float = (float(ix) - 2.5) * 30.0
			var z: float = (float(iz) - 2.5) * 30.0
			if absf(x) < 14.0 and absf(z) < 14.0:
				continue
			var h: float = rng.randf_range(8.0, 40.0)
			var col: String = "%02x%02x%02x" % [rng.randi_range(110, 190), rng.randi_range(110, 190), rng.randi_range(120, 200)]
			a.append(_b(Vector3(16, h, 16), Vector3(x, h * 0.5, z), Vector3.ZERO, col, "brick" if ix % 2 == 0 else "metal"))
	return a


static func _desert() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var a: Array = []
	for i in 16:
		var pos := Vector3(rng.randf_range(-60.0, 60.0), 0.5, rng.randf_range(-60.0, 40.0))
		var rot := Vector3(rng.randf_range(-8.0, 8.0), rng.randf_range(0.0, 360.0), rng.randf_range(-8.0, 8.0))
		a.append(_b(Vector3(rng.randf_range(10.0, 22.0), rng.randf_range(2.0, 5.0), rng.randf_range(10.0, 22.0)), pos, rot, "e0c27a", "sand"))
	for i in 8:
		var s: float = 24.0 - float(i) * 3.0
		a.append(_b(Vector3(s, 2.0, s), Vector3(-50, 1.0 + float(i) * 2.0, -50), Vector3.ZERO, "d4a373", "sand"))
	return a


static func _snow() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var a: Array = []
	for i in 18:
		var pos := Vector3(rng.randf_range(-50.0, 50.0), 1.0, rng.randf_range(-50.0, 30.0))
		var rot := Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(0.0, 360.0), rng.randf_range(-12.0, 12.0))
		a.append(_b(Vector3(rng.randf_range(8.0, 16.0), rng.randf_range(2.0, 4.0), rng.randf_range(8.0, 16.0)), pos, rot, "f2f8ff", "ice"))
	for i in 6:
		a.append(_b(Vector3(3, 3, 3), Vector3(-10.0 + float(i) * 4.0, 1.5, -20), Vector3(0, rng.randf_range(0.0, 90.0), 0), "bfeaff", "ice"))
	return a


static func _volcano() -> Array:
	var a: Array = []
	for i in 8:
		var s: float = 60.0 - float(i) * 7.0
		a.append(_b(Vector3(s, 2.0, s), Vector3(0, 1.0 + float(i) * 2.0, -20), Vector3.ZERO, "5a3a2a" if i < 6 else "d6451a", "stone"))
	return a


static func _island() -> Array:
	var a: Array = []
	a.append(_b(Vector3(60, 6.5, 60), Vector3(0, -3, 0), Vector3.ZERO, "e0c27a", "sand"))
	a.append(_b(Vector3(20, 3, 20), Vector3(-10, 1.5, -8), Vector3.ZERO, "6b8e4e", "grass"))
	a.append(_b(Vector3(10, 5, 10), Vector3(-10, 3.5, -8), Vector3.ZERO, "6b8e4e", "grass"))
	a.append(_b(Vector3(16, 6.5, 16), Vector3(70, -3, 0), Vector3.ZERO, "e0c27a", "sand"))
	a.append(_b(Vector3(16, 6.5, 16), Vector3(-70, -3, 20), Vector3.ZERO, "e0c27a", "sand"))
	return a


static func _skate() -> Array:
	var a: Array = []
	for i in 4:
		a.append(_b(Vector3(10, 0.5, 6), Vector3(-14.0 + float(i) * 9.0, 1.2, -6), Vector3(0, 0, 25 if i % 2 == 0 else -25), "9aa0a8", "stone"))
	a.append(_b(Vector3(14, 0.15, 0.15), Vector3(0, 0.9, 6), Vector3.ZERO, "dddddd", "metal"))
	a.append(_b(Vector3(0.15, 0.9, 0.15), Vector3(-7, 0.45, 6), Vector3.ZERO, "999999", "metal"))
	a.append(_b(Vector3(0.15, 0.9, 0.15), Vector3(7, 0.45, 6), Vector3.ZERO, "999999", "metal"))
	for i in 6:
		a.append(_b(Vector3(8, 0.4, 1.5), Vector3(0, 0.2 + float(i) * 0.4, -20.0 - float(i) * 1.5), Vector3.ZERO, "b0b0b0", "stone"))
	a.append(_b(Vector3(6, 1.2, 6), Vector3(18, 0.6, 8), Vector3.ZERO, "cc8844", "wood"))
	return a


static func _jumps() -> Array:
	var a: Array = []
	for i in 6:
		a.append(_b(Vector3(8, 0.5, 12), Vector3(0, 1.7, 10.0 - float(i) * 45.0), Vector3(15, 0, 0), "d6a43a" if i % 2 == 0 else "3a8fd6", "wood"))
	a.append(_b(Vector3(20, 0.5, 20), Vector3(0, 6.0, -300), Vector3.ZERO, "6b8e4e", "grass"))
	return a


static func _towers2() -> Array:
	var a: Array = []
	for i in 5:
		var x: float = -48.0 + float(i) * 24.0
		var h: float = 40.0 + float(i % 3) * 14.0
		a.append(_b(Vector3(12, h, 12), Vector3(x, h * 0.5, -10), Vector3.ZERO, "7f8a99", "metal"))
		if i < 4:
			a.append(_b(Vector3(12, 0.6, 4), Vector3(x + 12.0, 30, -10), Vector3.ZERO, "aaaaaa", "metal"))
	return a


static func _harbor() -> Array:
	var a: Array = []
	a.append(_b(Vector3(70, 6, 30), Vector3(0, -3, 35), Vector3.ZERO, "c2b280", "sand"))
	for i in 4:
		a.append(_b(Vector3(4, 0.5, 18), Vector3(-24.0 + float(i) * 16.0, -0.25, 11), Vector3.ZERO, "8b5a2b", "wood"))
	a.append(_b(Vector3(10, 4, 30), Vector3(-45, -1.0, -30), Vector3.ZERO, "7a4a2a", "wood"))
	a.append(_b(Vector3(14, 1, 40), Vector3(50, -0.5, -40), Vector3.ZERO, "6b6b6b", "stone"))
	a.append(_b(Vector3(5, 12, 5), Vector3(50, 6, -60), Vector3.ZERO, "dd3333", "metal"))
	return a


# ================================================================ Ítems (herramientas y armas por separado)
## Cada herramienta y cada arma es un ítem propio. Los ids de armas son "w:<nombre>".

static func tools() -> Array:
	return [
		{"id": "build", "name": "Construir", "cat": "Construcción"},
		{"id": "move", "name": "Mover", "cat": "Construcción"},
		{"id": "scale", "name": "Escalar", "cat": "Construcción"},
		{"id": "rotate", "name": "Rotar", "cat": "Construcción"},
		{"id": "delete", "name": "Borrar", "cat": "Construcción"},
		{"id": "paint", "name": "Pintar", "cat": "Construcción"},
		{"id": "copy", "name": "Copiar", "cat": "Construcción"},
		{"id": "spawn", "name": "Spawn", "cat": "Objetos"},
		{"id": "physgun", "name": "Physgun", "cat": "Objetos"},
		{"id": "push", "name": "Empuje", "cat": "Utilidades"},
		{"id": "explode", "name": "Explosión", "cat": "Utilidades"},
		{"id": "magnet", "name": "Imán", "cat": "Utilidades"},
		{"id": "blower", "name": "Soplador", "cat": "Utilidades"},
		{"id": "teleport", "name": "Teletransporte", "cat": "Utilidades"},
		{"id": "levitate", "name": "Levitar", "cat": "Utilidades"},
		{"id": "mass", "name": "Masa", "cat": "Utilidades"},
		{"id": "freeze", "name": "Congelar", "cat": "Utilidades"},
	]


static func default_hotbar() -> Array:
	return ["build", "move", "scale", "rotate", "delete", "paint", "copy", "spawn", "physgun", "w:Taser", "w:Escopeta", "w:Ametralladora"]


static func item_label(id: String) -> String:
	if id.begins_with("w:"):
		return id.substr(2)
	for t in tools():
		var d: Dictionary = t
		if str(d["id"]) == id:
			return str(d["name"])
	return id
