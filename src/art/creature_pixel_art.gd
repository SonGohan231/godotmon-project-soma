extends RefCounted
class_name CreaturePixelArt

const TYPE_COLORS := {
	"KONTAKT":Color8(190,170,135),"NERW":Color8(225,206,76),"REZONANS":Color8(121,92,194),
	"PIEZO":Color8(84,206,224),"ODDECH":Color8(167,220,213),"GRAWITACJA":Color8(104,96,123),
	"PLYN":Color8(79,164,187),"OGIEN":Color8(221,94,62),"WODA":Color8(69,122,203),
	"DREWNO":Color8(84,158,83),"ZIEMIA":Color8(150,111,67),"METAL":Color8(157,170,181),
	"MISTYCZNE":Color8(192,101,198)
}

static func battle_texture(species_id: StringName, back_view: bool = false) -> Texture2D:
	return ImageTexture.create_from_image(_draw_species(species_id, 32, back_view, 0))

static func mini_texture(species_id: StringName, frame: int = 0) -> Texture2D:
	return ImageTexture.create_from_image(_draw_species(species_id, 16, false, posmod(frame, 2)))

static func _draw_species(species_id: StringName, size: int, back_view: bool, frame: int) -> Image:
	var entry := CreatureDex.get_species(species_id)
	var family := int(entry.get("family_id", 1))
	var stage := clampi(int(entry.get("stage", 1)), 1, 3)
	var types: Array = entry.get("types", ["KONTAKT"])
	var primary := Color(TYPE_COLORS.get(String(types[0]), TYPE_COLORS["KONTAKT"]))
	var secondary := primary.lightened(0.18)
	if types.size() > 1:
		secondary = Color(TYPE_COLORS.get(String(types[1]), primary.lightened(0.18)))
	var outline := primary.darkened(0.58)
	var shadow := primary.darkened(0.28)
	var highlight := primary.lightened(0.30)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))

	var scale := 1.0 if size >= 32 else 0.5
	var cx := int(round(float(size) * 0.50))
	var cy := int(round(float(size) * (0.60 + (0.02 if frame == 1 else 0.0))))
	var rx := maxi(3, int(round((5.0 + stage * 2.0) * scale)))
	var ry := maxi(3, int(round((4.0 + stage * 1.7) * scale)))
	_draw_ellipse(image, cx, cy, rx, ry, primary, outline)

	# Head placement and silhouette are deterministic per family, producing 150 distinct forms.
	var head_shift := int(round(float(((family * 7) % 5) - 2) * scale))
	var head_r := maxi(2, int(round((3.0 + stage * 0.8) * scale)))
	var head_y := cy - ry + maxi(1, int(round(2.0 * scale)))
	_draw_circle(image, cx + head_shift, head_y, head_r, primary.lightened(0.05), outline)

	# Tail / crest / wings / heavy feet variants make families readable even at 16 px.
	var tail_dir := -1 if family % 2 == 0 else 1
	if family % 3 != 0:
		var tail_y := cy + int(round(1.0 * scale)) + (1 if frame == 1 else 0)
		_draw_line(image, cx + tail_dir * rx, tail_y, cx + tail_dir * (rx + maxi(2, int(round((3 + stage) * scale)))), tail_y - maxi(1, int(round(2.0 * scale))), outline)
	if family % 4 == 0 || String(types[0]) in ["ODDECH","REZONANS","MISTYCZNE"]:
		var wing_w := maxi(2, int(round((3.0 + stage) * scale)))
		_draw_triangle(image, Vector2i(cx-rx+1, cy-1), Vector2i(cx-rx-wing_w, cy-ry), Vector2i(cx-rx, cy+2), secondary, outline)
		_draw_triangle(image, Vector2i(cx+rx-1, cy-1), Vector2i(cx+rx+wing_w, cy-ry), Vector2i(cx+rx, cy+2), secondary, outline)
	if family % 5 == 0 || String(types[0]) in ["ZIEMIA","GRAWITACJA"]:
		var foot_y := cy + ry
		_draw_line(image, cx-rx/2, foot_y, cx-rx/2-1, foot_y+maxi(1,int(round(2.0*scale))), outline)
		_draw_line(image, cx+rx/2, foot_y, cx+rx/2+1, foot_y+maxi(1,int(round(2.0*scale))), outline)
	if family % 7 == 0 || String(types[0]) in ["PIEZO","METAL"]:
		var crest_h := maxi(2, int(round((2.0 + stage) * scale)))
		_draw_triangle(image, Vector2i(cx+head_shift-1, head_y-head_r+1), Vector2i(cx+head_shift, head_y-head_r-crest_h), Vector2i(cx+head_shift+1, head_y-head_r+1), secondary, outline)

	# Secondary type marking and stage stripe.
	var stripe_y := cy + (1 if back_view else 0)
	for x in range(cx-rx+2, cx+rx-1):
		if (x + family + stage) % maxi(2, 5-stage) == 0:
			_set(image, x, stripe_y, secondary)
	if stage >= 2:
		_set(image, cx, cy-1, highlight)
	if stage == 3:
		_set(image, cx-1, cy, highlight)
		_set(image, cx+1, cy, highlight)

	if back_view:
		# Back sprite: dorsal markings instead of face pixels.
		_draw_line(image, cx+head_shift, head_y-head_r+1, cx, cy+ry-2, shadow)
		_set(image, cx-1, cy-2, secondary)
		_set(image, cx+1, cy-2, secondary)
	else:
		var eye_y := head_y
		var eye_dx := maxi(1, int(round(1.5 * scale)))
		_set(image, cx+head_shift-eye_dx, eye_y, Color8(30,35,38))
		_set(image, cx+head_shift+eye_dx, eye_y, Color8(30,35,38))
		if size >= 32:
			_set(image, cx+head_shift-eye_dx, eye_y-1, Color.WHITE)
	return image

static func _draw_ellipse(image: Image, cx: int, cy: int, rx: int, ry: int, fill: Color, outline: Color) -> void:
	for y in range(cy-ry-1, cy+ry+2):
		for x in range(cx-rx-1, cx+rx+2):
			var dx := float(x-cx) / maxf(1.0, float(rx))
			var dy := float(y-cy) / maxf(1.0, float(ry))
			var d := dx*dx + dy*dy
			if d <= 1.0:
				_set(image, x, y, outline if d >= 0.72 else fill)

static func _draw_circle(image: Image, cx: int, cy: int, radius: int, fill: Color, outline: Color) -> void:
	for y in range(cy-radius-1, cy+radius+2):
		for x in range(cx-radius-1, cx+radius+2):
			var d := Vector2(float(x-cx), float(y-cy)).length()
			if d <= float(radius):
				_set(image, x, y, outline if d >= float(radius)-0.8 else fill)

static func _draw_line(image: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var points := maxi(abs(x1-x0), abs(y1-y0))
	if points <= 0:
		_set(image, x0, y0, color)
		return
	for i in range(points+1):
		var t := float(i) / float(points)
		_set(image, int(round(lerpf(float(x0), float(x1), t))), int(round(lerpf(float(y0), float(y1), t))), color)

static func _draw_triangle(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, fill: Color, outline: Color) -> void:
	_draw_line(image, a.x, a.y, b.x, b.y, outline)
	_draw_line(image, b.x, b.y, c.x, c.y, outline)
	_draw_line(image, c.x, c.y, a.x, a.y, outline)
	var center := Vector2i(int(round(float(a.x+b.x+c.x)/3.0)), int(round(float(a.y+b.y+c.y)/3.0)))
	_set(image, center.x, center.y, fill)

static func _set(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 && y >= 0 && x < image.get_width() && y < image.get_height():
		image.set_pixel(x, y, color)
