extends Control

const SKY := Color("#74d9f4")
const PALE := Color("#d5f3ee")
const EARTH := Color("#62877d")

var species := ""
var stage := 0
var elapsed := 0.0
var caption := "분류가 세계에 남기는 모습"
var residents: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func reveal(entity_id: String, depth: int, name_ko: String) -> void:
	species = entity_id
	stage = depth
	var found := false
	for resident in residents:
		if str(resident["id"]) == entity_id:
			resident["stage"] = maxi(int(resident["stage"]), depth)
			found = true
			break
	if not found:
		residents.append({"id": entity_id, "stage": depth, "name": name_ko, "x": 32.0, "absorbed": false, "flash": 0.0})
	caption = "%s  /  %s   ·   나무로 향한 표본 %d" % [name_ko, ["", "자리가 열렸다", "움직임이 드러났다", "다음 세대가 나타났다"][mini(depth, 3)], residents.size()]
	set_process(true)
	queue_redraw()


func reset() -> void:
	species = ""
	stage = 0
	residents.clear()
	elapsed = 0.0
	caption = "분류가 세계에 남기는 모습"
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if size.x < 150.0:
		return
	elapsed += delta
	var tree_x := size.x - 68.0
	for resident in residents:
		if bool(resident["absorbed"]):
			resident["flash"] = maxf(0.0, float(resident["flash"]) - delta)
			continue
		var pace := 30.0 + float(int(resident["stage"])) * 4.0
		resident["x"] = float(resident["x"]) + delta * pace
		if float(resident["x"]) >= tree_x:
			resident["x"] = tree_x
			resident["absorbed"] = true
			resident["flash"] = 1.2
			caption = "나무가 %s의 빛을 받아들였다   ·   뿌리에 남은 빛 %d" % [resident["name"], absorbed_count()]
	queue_redraw()


func absorbed_count() -> int:
	var count := 0
	for resident in residents:
		if bool(resident["absorbed"]):
			count += 1
	return count


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color("#071916"), true)
	draw_line(Vector2(0, h - 15), Vector2(w, h - 15), EARTH, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(12, 17), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PALE)
	_draw_destination_tree(Vector2(w - 39.0, h - 15.0), absorbed_count())
	if residents.is_empty():
		return
	for i in range(residents.size()):
		var resident := residents[i]
		var resident_stage := int(resident["stage"])
		var phase := elapsed * (2.2 if resident_stage >= 2 else 1.1) + float(i) * 1.7
		var x := float(resident["x"])
		if bool(resident["absorbed"]):
			var flash := float(resident["flash"])
			if flash > 0.0:
				var impact := Vector2(w - 45.0, h - 28.0)
				var fraction := flash / 1.2
				var ring_radius := 8.0 + (1.0 - fraction) * 26.0
				draw_circle(impact, ring_radius, Color(0.45, 0.85, 0.95, fraction * 0.32))
				draw_arc(impact, ring_radius, 0.0, TAU, 32, Color(SKY, fraction), 2.0)
				for spark in range(8):
					var angle := float(spark) * TAU / 8.0
					var direction := Vector2(cos(angle), sin(angle))
					draw_line(impact + direction * (ring_radius + 2.0), impact + direction * (ring_radius + 8.0), Color(PALE, fraction), 1.5)
				var rising := impact.lerp(Vector2(w - 39.0, h - 51.0), 1.0 - fraction)
				draw_circle(rising, 4.0 + fraction * 3.0, Color(PALE, fraction))
			continue
		var hop := absf(sin(phase * 2.2)) * (9.0 if resident_stage >= 2 else 3.0)
		var y := h - 20.0 - hop
		_draw_creature(str(resident["id"]), Vector2(x, y), 1.08, phase)
		if resident_stage >= 3:
			_draw_creature(str(resident["id"]), Vector2(x - 22.0, h - 20.0 - absf(sin(phase * 2.7 + 1.0)) * 5.0), 0.46, phase + 1.0)


func _draw_destination_tree(base: Vector2, souls: int) -> void:
	var glow := Color("#74d9f4")
	var trunk := Color("#a7c2a9")
	var crown := base + Vector2(0, -36)
	draw_circle(crown, 21.0 + float(souls) * 1.5, Color(0.45, 0.85, 0.95, 0.1 + float(souls) * 0.035))
	draw_line(base, crown, trunk, 4.0)
	for branch in [Vector2(-17, -25), Vector2(17, -25), Vector2(-13, -45), Vector2(13, -48)]:
		draw_line(crown, base + branch, trunk, 2.0)
		draw_circle(base + branch, 3.2, glow)
	draw_line(base, base + Vector2(-14, 6), glow.darkened(0.35), 2.0)
	draw_line(base, base + Vector2(15, 6), glow.darkened(0.35), 2.0)
	draw_circle(crown, 3.0, PALE)
	for i in range(souls):
		var angle := float(i) * TAU / 6.0 + elapsed * 0.7
		draw_circle(crown + Vector2(cos(angle) * 14.0, sin(angle) * 13.0), 2.2, PALE)


func _draw_creature(species_id: String, p: Vector2, scale_factor: float, phase: float) -> void:
	var tint := SKY if species_id in ["glass_fox", "echo_eel", "mirror_hare"] else Color("#bbd7b4")
	if species_id == "water":
		var drop := PackedVector2Array([
			p + Vector2(0, -19) * scale_factor,
			p + Vector2(-10, -2) * scale_factor,
			p + Vector2(-8, 7) * scale_factor,
			p + Vector2(0, 11) * scale_factor,
			p + Vector2(8, 7) * scale_factor,
			p + Vector2(10, -2) * scale_factor
		])
		draw_colored_polygon(drop, SKY.darkened(0.2))
		draw_circle(p + Vector2(-3, -3) * scale_factor, 2.5 * scale_factor, PALE)
	elif species_id == "ember_moth":
		draw_circle(p + Vector2(-11, -3) * scale_factor, 11.0 * scale_factor, tint.darkened(0.35))
		draw_circle(p + Vector2(11, -3) * scale_factor, 11.0 * scale_factor, tint.darkened(0.35))
		draw_circle(p, 5.0 * scale_factor, PALE)
	elif species_id == "time_snail":
		draw_circle(p + Vector2(-6, -8) * scale_factor, 12.0 * scale_factor, tint.darkened(0.25))
		draw_arc(p + Vector2(-6, -8) * scale_factor, 6.0 * scale_factor, 0.0, TAU, 20, PALE, 1.4)
		draw_line(p, p + Vector2(17, 0) * scale_factor, tint, 5.0 * scale_factor)
	elif species_id == "echo_eel":
		var points := PackedVector2Array()
		for i in range(8):
			points.append(p + Vector2(float(i - 4) * 5.0, sin(phase * 3.0 + float(i)) * 5.0) * scale_factor)
		draw_polyline(points, tint, 4.0 * scale_factor, true)
	else:
		draw_circle(p, 11.0 * scale_factor, tint.darkened(0.15))
		draw_circle(p + Vector2(11, -8) * scale_factor, 6.0 * scale_factor, tint)
		for foot in [-6.0, 7.0]:
			draw_line(p + Vector2(foot, 5) * scale_factor, p + Vector2(foot - 3, 13) * scale_factor, tint, 2.0 * scale_factor)
		if species_id in ["moss_hart", "mirror_hare"]:
			draw_line(p + Vector2(10, -12) * scale_factor, p + Vector2(5, -25) * scale_factor, tint, 2.0 * scale_factor)
			draw_line(p + Vector2(15, -12) * scale_factor, p + Vector2(19, -24) * scale_factor, tint, 2.0 * scale_factor)
		if species_id == "glass_fox":
			draw_line(p + Vector2(-8, 0) * scale_factor, p + Vector2(-24, -7) * scale_factor, tint, 5.0 * scale_factor)
		elif species_id == "dog":
			draw_line(p + Vector2(-8, 0) * scale_factor, p + Vector2(-20, -11) * scale_factor, tint, 4.0 * scale_factor)
			draw_line(p + Vector2(11, -10) * scale_factor, p + Vector2(13, -2) * scale_factor, tint.darkened(0.25), 4.0 * scale_factor)
		elif species_id == "cat":
			draw_line(p + Vector2(-9, 0) * scale_factor, p + Vector2(-22, -13) * scale_factor, tint, 2.0 * scale_factor)
			draw_line(p + Vector2(9, -13) * scale_factor, p + Vector2(6, -20) * scale_factor, tint, 2.0 * scale_factor)
			draw_line(p + Vector2(14, -13) * scale_factor, p + Vector2(18, -20) * scale_factor, tint, 2.0 * scale_factor)
		elif species_id == "platypus":
			draw_line(p + Vector2(15, -7) * scale_factor, p + Vector2(25, -5) * scale_factor, tint.darkened(0.2), 4.0 * scale_factor)
			draw_line(p + Vector2(-9, 0) * scale_factor, p + Vector2(-22, 5) * scale_factor, tint.darkened(0.35), 5.0 * scale_factor)
