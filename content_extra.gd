class_name ContentExtra
## Contenido adicional: se suma al de Content (objetos, armas, mapas y vehículos).
## Todo es determinista, así host y clientes generan lo mismo.


static func props() -> Dictionary:
	return {
		"Cubo de nieve": {"cat": "Construcción", "shape": "box", "size": Vector3(1, 1, 1), "mass": 2.0, "color": "ffffff", "tex": "snow"},
		"Piedra de lava": {"cat": "Construcción", "shape": "sphere", "size": Vector3(0.4, 0.4, 0.4), "mass": 6.0, "color": "5a1a0a", "tex": "lava"},
		"Árbol de neón": {"cat": "Construcción", "shape": "cylinder", "size": Vector3(0.2, 2.2, 0.2), "mass": 5.0, "color": "22ffcc", "tex": "neon"},
		"Pared de ladrillo": {"cat": "Construcción", "shape": "box", "size": Vector3(3, 2, 0.3), "mass": 40.0, "color": "b5543a", "tex": "brick"},
		"Tronco de corteza": {"cat": "Construcción", "shape": "cylinder", "size": Vector3(0.3, 3.0, 0.3), "mass": 15.0, "color": "6b4a2a", "tex": "bark"},
		"Bloque oxidado": {"cat": "Construcción", "shape": "box", "size": Vector3(1, 1, 1), "mass": 8.0, "color": "8a4a2a", "tex": "rust"},
		"Dado gigante": {"cat": "Construcción", "shape": "box", "size": Vector3(2, 2, 2), "mass": 20.0, "color": "ffffff"},
		"Barril oxidado": {"cat": "Construcción", "shape": "cylinder", "size": Vector3(0.4, 1.0, 0.4), "mass": 12.0, "color": "8a4a2a", "tex": "rust"},
	}


static func weapons() -> Array:
	return [
		{"name": "Bazuca de pulso", "dmg": 0.0, "pellets": 1, "spread": 0.0, "cd": 2.0, "auto": false, "range": 250.0, "blast": 4.0, "knock": 0.0, "color": "ff00ff"},
		{"name": "Pistola láser", "dmg": 30.0, "pellets": 1, "spread": 0.0, "cd": 0.5, "auto": false, "range": 300.0, "blast": 0.0, "knock": 6.0, "color": "00ff88"},
		{"name": "Arco eléctrico", "dmg": 12.0, "pellets": 1, "spread": 0.0, "cd": 0.4, "auto": true, "range": 25.0, "blast": 0.0, "knock": 4.0, "stun": 1.0, "color": "ffff00"},
		{"name": "Rifle de nieve", "dmg": 35.0, "pellets": 1, "spread": 0.01, "cd": 0.9, "auto": false, "range": 260.0, "blast": 0.0, "knock": 6.0, "freeze": true, "color": "bfeaff"},
	]


static func maps() -> Array:
	var out: Array = []

	var lava: Array = [{"size": Vector3(60, 1, 60), "pos": Vector3(0, -0.5, 0), "rot": Vector3.ZERO, "color": "5a1a0a", "tex": "lava"}]
	for i in 8:
		lava.append({"size": Vector3(4, 0.6, 4), "pos": Vector3(-14.0 + float(i) * 4.0, 1.0 + float(i % 2), 10.0 - float(i % 3) * 5.0), "rot": Vector3.ZERO, "color": "3a3a44", "tex": "stone"})
	out.append({"name": "Volcán de lava", "spawn": Vector3(-16, 1, 0), "boxes": lava})

	var forest: Array = []
	for i in 14:
		var x: float = float((i * 37) % 40) - 20.0
		var z: float = float((i * 53) % 40) - 20.0
		forest.append({"size": Vector3(0.6, 4.0, 0.6), "pos": Vector3(x, 2.0, z), "rot": Vector3.ZERO, "color": "6b4a2a", "tex": "bark"})
		forest.append({"size": Vector3(2.6, 2.4, 2.6), "pos": Vector3(x, 4.8, z), "rot": Vector3.ZERO, "color": "2e6f3a", "tex": "grass"})
	out.append({"name": "Bosque", "spawn": Vector3(0, 1, 26), "boxes": forest})

	var neon: Array = []
	for i in 12:
		var a: float = float(i) * 0.55
		neon.append({"size": Vector3(4, 0.4, 4), "pos": Vector3(cos(a) * 16.0, 4.0 + sin(float(i) * 0.7) * 3.0, sin(a) * 16.0), "rot": Vector3(0, rad_to_deg(-a), 0), "color": "22ffcc", "tex": "neon"})
	out.append({"name": "Plataformas neón", "spawn": Vector3(16, 1, 0), "boxes": neon})
	return out


static func prefabs() -> Dictionary:
	var v: Dictionary = {}
	var coche: Array = [
		Content._e("Metal", Vector3(0, 0, 0), "ff4422", Vector3(1.8, 0.35, 3.6)),
		Content._e("Vidrio", Vector3(0, 0.5, 0.2), "", Vector3(1.4, 0.5, 1.2)),
		Content._e("Asiento", Vector3(0, 0.2, 0.2)),
		Content._e("Propulsor", Vector3(0, 0.1, 1.9)),
	]
	coche.append_array(Content._wheels4(1.0, -0.1, -1.2, 1.2, "Rueda grande"))
	v["Coche de carreras"] = {"cat": "Vehículos", "blocks": coche}

	var tanque: Array = [
		Content._e("Metal", Vector3(0, 0, 0), "66773a", Vector3(2.0, 0.6, 3.6)),
		Content._e("Metal", Vector3(0, 0.55, 0.2), "556633", Vector3(1.4, 0.5, 1.4)),
		Content._e("Cañón", Vector3(0, 0.6, -1.4)),
		Content._e("Asiento", Vector3(0, 0.4, 0.6)),
	]
	tanque.append_array(Content._wheels4(1.2, -0.25, -1.4, 1.2, "Rueda grande"))
	v["Tanque ligero"] = {"cat": "Vehículos", "blocks": tanque}

	var barco: Array = [
		Content._e("Plástico", Vector3(0, 0, 0), "f2f2f2", Vector3(2.0, 0.4, 4.6)),
		Content._e("Plástico", Vector3(0, 0.45, -1.6), "2a6fdb", Vector3(1.8, 0.45, 1.2)),
		Content._e("Asiento", Vector3(0, 0.45, 0.6)),
		Content._e("Hélice", Vector3(0, -0.3, 2.4)),
	]
	v["Lancha rápida"] = {"cat": "Barcos", "blocks": barco}
	return v
