extends Control

const GLOW := Color("#74d9f4")
const CORE := Color("#e4faff")
const SCAR := Color("#ed7775")
const DORMANT := Color("#456057")

var marks: Array[Dictionary] = []
var total_steps := 9
const VISIBLE_STEPS := 9
var growth := 1.0:
	set(value):
		growth = value
		queue_redraw()


func set_marks(value: Array[Dictionary], total: int) -> void:
	var had_new_mark := value.size() > marks.size()
	marks = value.duplicate(true)
	total_steps = maxi(total, 1)
	if had_new_mark:
		growth = 0.0
		var tween := create_tween()
		tween.tween_property(self, "growth", 1.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		growth = 1.0
	queue_redraw()


func _draw() -> void:
	var center := size.x * 0.5
	var top := 18.0
	var step_height := minf(35.0, (size.y - 35.0) / float(VISIBLE_STEPS))
	var first_step := maxi(0, marks.size() - VISIBLE_STEPS + 1)
	var current := Vector2(center, top)
	draw_circle(current, 7.0, GLOW.darkened(0.25))
	draw_circle(current, 3.0, CORE)
	for row in range(mini(VISIBLE_STEPS, total_steps - first_step)):
		var i := first_step + row
		var direction := -1.0 if i % 2 == 0 else 1.0
		if i < marks.size():
			direction = float(marks[i].get("direction", -1))
		var end := Vector2(clampf(current.x + direction * 19.0, 27.0, size.x - 27.0), top + (row + 1) * step_height)
		var unused := Vector2(clampf(current.x - direction * 15.0, 22.0, size.x - 22.0), top + (row + 1) * step_height * 0.65)
		draw_line(current, unused, DORMANT.darkened(0.15), 1.5, true)
		var number_color := DORMANT
		if i < marks.size():
			number_color = GLOW if bool(marks[i].get("correct", false)) else SCAR
		draw_string(ThemeDB.fallback_font, Vector2(4, end.y + 4), "%02d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, number_color)
		if i >= marks.size():
			draw_line(current, end, DORMANT.darkened(0.45), 2.0, true)
			current = end
			continue
		var correct := bool(marks[i].get("correct", false))
		var color := GLOW if correct else SCAR
		var amount := growth if i == marks.size() - 1 else 1.0
		var tip := current.lerp(end, amount)
		var halo := color.darkened(0.5)
		halo.a = 0.2
		var glow := color
		glow.a = 0.5
		var node_glow := color
		node_glow.a = 0.18
		draw_line(current, tip, halo, 16.0, true)
		draw_line(current, tip, glow, 8.0, true)
		draw_line(current, tip, CORE if correct else color.lightened(0.24), 2.5, true)
		draw_circle(tip, 8.0 * amount, node_glow)
		if correct:
			draw_circle(tip, 4.0 * amount, CORE)
		else:
			var cross := 4.5 * amount
			draw_line(tip + Vector2(-cross, -cross), tip + Vector2(cross, cross), CORE, 2.0, true)
			draw_line(tip + Vector2(-cross, cross), tip + Vector2(cross, -cross), CORE, 2.0, true)
		current = end
