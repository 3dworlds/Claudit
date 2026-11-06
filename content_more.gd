class_name ContentMore
## Más contenido: objetos, armas, mapas y vehículos. Todo es determinista (host y clientes iguales).


static func props() -> Dictionary:
	return {
		"Gema azul": {"cat": "Fantasía", "shape": "sphere", "size": Vector3(0.3, 0.3, 0.3), "mass": 2.0, "color": "3366ff", "tex": "ice"},
		"Estatua de piedra": {"cat": "Fantasía", "shape": "box", "size": Vector3(1, 2, 1), "mass": 60.0, "color": "9a9a9a", "tex": "stone"},
		"Pulpo de goma": {"cat": "Juguetes", "shape": "sphere", "size": Vector3(0.5, 0.5, 0.5), "mass": 0.8, "color": "aa33cc", "bounce": 0.9},
		"Bola de cristal": {"cat": "Fantasía", "shape": "sphere", "size": Vector3(0.35, 0.35, 0.35), "mass": 1.0, "color": "ccf0ff", "tex": "ice"},
		"Pizza gigante": {"cat": "Comida", "shape": "cylinder", "size": Vector3(0.8, 0.1, 0.8), "mass": 4.0, "color": "ffcc66"},
		"Cactus de juguete": {"cat": "Juguetes", "shape": "cylinder", "size": Vector3(0.15, 0.8, 0.15), "mass": 0.5, "color": "33aa55"},
		"Piedra musgosa": {"cat": "Naturaleza", "shape": "sphere", "size": Vector3(0.5, 0.5, 0.5), "mass": 14.0, "color": "4a6b3a", "tex": "grass"},
		"Cofre de madera": {"cat": "Contenedores", "shape": "box", "size": Vector3(0.8, 0.5, 0.5), "mass": 10.0, "color": "8b5a2b", "tex": "wood"},
		"Mini cohete": {"cat": "Fantasía", "shape": "cylinder", "size": Vector3(0.15, 1.2, 0.15), "mass": 2.0, "color": "ee3333"},
		"Balón de hielo": {"cat": "Deportes", "shape": "sphere", "size": Vector3(0.4, 0.4, 0.4), "mass": 3.0, "color": "c8f4ff", "tex": "ice"},
	}


static func weapons() -> Array:
	return [
		{"name": "Escopeta de plasma", "dmg": 8.0, "pellets": 6, "spread": 0.1, "cd": 0.7, "auto": false, "range": 30.0, "blast": 0.0, "knock": 8.0, "color": "ff66ff"},
		{"name": "Lanza de rayo", "dmg": 45.0, "pellets": 1, "spread": 0.0, "cd": 1.4, "auto": false, "range": 350.0, "blast": 0.0, "knock": 14.0, "color": "66ffff"},
		{"name": "Minigun de nieve", "dmg": 9.0, "pellets": 1, "spread": 0.05, "cd": 0.04, "auto": true, "range": 160.0, "blast": 0.0, "knock": 3.0, "freeze": false, "color": "e0f7ff"},
		{"name": "Mortero", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 1.6, "auto": false, "range": 300.0, "blast": 7.0, "knock": 0.0, "color": "ff9900"},
		{"name": "Pistola de púas", "dmg": 22.0, "pellets": 3, "spread": 0.05, "cd": 0.5, "auto": false, "range": 90.0, "blast": 0.0, "knock": 5.0, "color": "bbbbbb"},
		{"name": "Látigo eléctrico", "dmg": 6.0, "pellets": 1, "spread": 0.0, "cd": 0.7, "auto": false, "range": 8.0, "blast": 0.0, "knock": 10.0, "stun": 1.2, "color": "ffff88"},
	]


static func maps() -> Array:
	var out: Array = []

	var cave: Array = []
	for i in 10:
		var a: float = float(i) * 0.63
		cave.append({"size": Vector3(3, 6, 3), "pos": Vector3(cos(a) * 22.0, 3.0, sin(a) * 22.0), "rot": Vector3.ZERO, "color": "7fd6ff", "tex": "ice"})
	cave.append({"size": Vector3(60, 0.5, 60), "pos": Vector3(0, -0.25, 0), "rot": Vector3.ZERO, "color": "3a4a66", "tex": "stone"})
	out.append({"name": "Cueva de cristal", "spawn": Vector3(0, 1, 0), "boxes": cave})

	var toys: Array = []
	for i in 6:
		var x: float = -20.0 + float(i) * 8.0
		toys.append({"size": Vector3(3, 1.5, 3), "pos": Vector3(x, 0.75, 0), "rot": Vector3.ZERO, "color": ["ff4455", "44aaff", "ffdd33"][i % 3], "tex": ""})
		toys.append({"size": Vector3(1.5, 3, 1.5), "pos": Vector3(x, 3.0, 4), "rot": Vector3.ZERO, "color": "ffffff", "tex": ""})
	out.append({"name": "Ciudad de juguete", "spawn": Vector3(0, 1, -6), "boxes": toys})

	var tower: Array = []
	for i in 14:
		var ang: float = float(i) * 0.9
		tower.append({"size": Vector3(4, 0.5, 4), "pos": Vector3(cos(ang) * 6.0, 1.0 + float(i) * 2.2, sin(ang) * 6.0), "rot": Vector3(0, rad_to_deg(-ang), 0), "color": "6a5acd", "tex": "metal"})
	out.append({"name": "Torre infinita", "spawn": Vector3(0, 1, 0), "boxes": tower})

	var reef: Array = []
	for i in 9:
		reef.append({"size": Vector3(2.5, 2.0 + float(i % 3), 2.5), "pos": Vector3(-16.0 + float(i) * 4.0, 1.0, float((i * 5) % 7) - 3.0), "rot": Vector3.ZERO, "color": "ff7f7f", "tex": "rust"})
	reef.append({"size": Vector3(70, 1.0, 70), "pos": Vector3(0, -0.5, 0), "rot": Vector3.ZERO, "color": "d9b77a", "tex": "sand"})
	out.append({"name": "Arrecife", "spawn": Vector3(-20, 3, 0), "boxes": reef})
	return out


static func prefabs() -> Dictionary:
	var v: Dictionary = {}

	var camioneta: Array = [
		Content._e("Metal", Vector3(0, 0, 0), "3a6e3a", Vector3(2.0, 0.5, 4.2)),
		Content._e("Metal", Vector3(0, 0.8, 0.8), "3a6e3a", Vector3(1.8, 0.8, 1.8)),
		Content._e("Vidrio", Vector3(0, 0.9, 0.5), "", Vector3(1.6, 0.5, 1.4)),
		Content._e("Asiento", Vector3(0, 0.4, 0.5)),
	]
	camioneta.append_array(Content._wheels4(1.1, -0.2, -1.5, 1.4, "Rueda grande"))
	v["Camioneta"] = {"cat": "Vehículos", "blocks": camioneta}

	var moto: Array = [
		Content._e("Metal", Vector3(0, 0.2, 0), "ffcc00", Vector3(0.4, 0.4, 2.2)),
		Content._e("Asiento", Vector3(0, 0.5, 0.2)),
		Content._e("Propulsor", Vector3(0, 0.2, 1.3)),
		Content._e("Rueda grande", Vector3(0, -0.15, -1.0)),
		Content._e("Rueda grande", Vector3(0, -0.15, 1.1)),
	]
	v["Moto"] = {"cat": "Vehículos", "blocks": moto}

	var globo: Array = [
		Content._e("Globo", Vector3(0, 3.0, 0), "ff5577"),
		Content._e("Globo", Vector3(0.5, 3.2, 0.3), "ffcc33"),
		Content._e("Madera", Vector3(0, 0.3, 0), "b5834a", Vector3(1.0, 0.6, 1.0)),
		Content._e("Asiento", Vector3(0, 0.7, 0)),
	]
	v["Globo aerostático"] = {"cat": "Aviones", "blocks": globo}

	var dron: Array = [
		Content._e("Plástico", Vector3(0, 0, 0), "333842", Vector3(0.8, 0.2, 0.8)),
		Content._e("Rotor", Vector3(0, 0.25, 0)),
		Content._e("Asiento", Vector3(0, 0.15, 0)),
		Content._e("Luz", Vector3(0, -0.15, 0)),
	]
	v["Dron"] = {"cat": "Aviones", "blocks": dron}
	return v
