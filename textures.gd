class_name Textures
extends RefCounted
## Texturas procedurales (sin archivos). Son grises/claras: se multiplican por el color del objeto.
## Nombres: wood, metal, brick, stone, grass, sand, ice, cloth, carbon, checker, grid.

const SIZE := 128

static var _cache: Dictionary = {}


## variant: clave del objeto (por ejemplo su color). Cada variante tiene un dibujo propio de la misma familia.
static func get_tex(tname: String, variant: String = "") -> Texture2D:
	if tname == "":
		return null
	var key: String = tname if variant == "" else tname + "#" + variant
	if _cache.has(key):
		return _cache[key]
	var salt: int = 0 if variant == "" else absi(variant.hash()) % 100000
	var tex: Texture2D = _make(tname, salt)
	_cache[key] = tex
	return tex


## Aplica la textura a un material. Usa triplanar para que no se estire al escalar bloques.
static func apply(mat: StandardMaterial3D, tname: String, tile: float = 0.5, variant: String = "") -> void:
	var tex: Texture2D = get_tex(tname, variant)
	if tex == null:
		return
	mat.albedo_texture = tex
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(tile, tile, tile)
	if tname == "metal" or tname == "carbon":
		mat.metallic = 0.5
		mat.roughness = 0.45
	elif tname == "ice":
		mat.roughness = 0.15


static func names() -> Array:
	return ["wood", "metal", "brick", "stone", "grass", "sand", "ice", "cloth", "carbon", "grid", "rust", "bark", "snow", "lava", "neon"]


static func pick(tname: String, shape: String, seed_key: String = "") -> String:
	if tname != "":
		return tname
	if seed_key != "":
		# Textura distinta según el color del bloque (siempre la misma para ese color)
		var all: Array = names()
		return str(all[absi(seed_key.hash()) % all.size()])
	match shape:
		"box":
			return "stone"
		"sphere":
			return "cloth"
		"cylinder":
			return "metal"
		"cone":
			return "grass"
		_:
			return "cloth"


static func _make(tname: String, salt: int = 0) -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = (hash(tname) + salt) % 100000
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(tname) + salt
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var v: float = _value(tname, x, y, noise, rng)
			v = clampf(v, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _value(tname: String, x: int, y: int, noise: FastNoiseLite, rng: RandomNumberGenerator) -> float:
	var fx: float = float(x)
	var fy: float = float(y)
	match tname:
		"wood":
			var warp: float = noise.get_noise_2d(fx * 0.4, fy * 0.08) * 6.0
			return 0.78 + 0.22 * sin((fy + warp) * 0.55)
		"metal":
			return 0.82 + 0.18 * noise.get_noise_2d(fx * 0.15, fy * 4.0)
		"brick":
			var row: int = y / 16
			var off: int = 16 if row % 2 == 1 else 0
			var bx: int = (x + off) % 32
			var by: int = y % 16
			if by < 2 or bx < 2:
				return 0.55
			return 0.88 + 0.12 * noise.get_noise_2d(fx * 2.0, fy * 2.0)
		"stone":
			return 0.7 + 0.3 * (noise.get_noise_2d(fx * 0.9, fy * 0.9) * 0.5 + 0.5)
		"grass":
			return 0.65 + 0.35 * (noise.get_noise_2d(fx * 3.0, fy * 3.0) * 0.5 + 0.5)
		"sand":
			return 0.86 + 0.14 * rng.randf()
		"ice":
			return 0.9 + 0.1 * noise.get_noise_2d(fx * 0.5, fy * 0.5)
		"cloth":
			return 0.78 + 0.22 * sin(fx * 1.6) * sin(fy * 1.6)
		"carbon":
			var cx: int = (x / 8) % 2
			var cy: int = (y / 8) % 2
			return 0.45 if (cx + cy) % 2 == 0 else 0.7
		"rust":
			return 0.55 + 0.45 * (noise.get_noise_2d(fx * 1.5, fy * 1.5) * 0.5 + 0.5)
		"bark":
			var bw: float = noise.get_noise_2d(fx * 0.2, fy * 0.05) * 4.0
			return 0.5 + 0.5 * sin((fx + bw) * 0.9)
		"snow":
			return 0.93 + 0.07 * noise.get_noise_2d(fx * 2.5, fy * 2.5)
		"lava":
			return 0.35 + 0.65 * (noise.get_noise_2d(fx * 0.7, fy * 0.7) * 0.5 + 0.5)
		"neon":
			return 0.7 if (x % 16 < 1 or y % 16 < 1) else 1.0
		"grid":
			if x % 32 < 2 or y % 32 < 2:
				return 0.55
			return 0.95 + 0.05 * noise.get_noise_2d(fx * 0.6, fy * 0.6)
		"checker":
			var sx: int = (x / 16) % 2
			var sy: int = (y / 16) % 2
			return 1.0 if (sx + sy) % 2 == 0 else 0.15
	return 1.0
