extends Control

var time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("#071310"), true)
	var center := Vector2(w * 0.5, h * 0.51)
	for ring in range(5):
		var radius := 135.0 + float(ring) * 72.0
		draw_arc(center, radius, 0.0, TAU, 96, Color(0.34, 0.61, 0.61, 0.08 + float(ring) * 0.012), 1.0)
	for side in [-1.0, 1.0]:
		var edge := w * (0.0 if side < 0.0 else 1.0)
		for strand in range(9):
			var start_y := float(strand) * h / 8.0
			var bend := 85.0 + float(strand % 3) * 24.0
			var points := PackedVector2Array([
				Vector2(edge, start_y),
				Vector2(edge - side * bend, start_y + 22.0),
				Vector2(edge - side * (bend + 45.0), h * 0.51 + (start_y - h * 0.5) * 0.4),
				Vector2(edge - side * (bend + 95.0), h * 0.51)
			])
			draw_polyline(points, Color(0.29, 0.51, 0.47, 0.24), 1.0 + float(strand % 3), true)
			if strand % 2 == 0:
				var light := points[2]
				var brightness := 0.35 + 0.2 * sin(time * 1.4 + float(strand))
				draw_circle(light, 2.2, Color(0.46, 0.85, 0.96, brightness))
	for mote in range(18):
		var x := fmod(float(mote * 173 + 71), maxf(w, 1.0))
		var y := fmod(float(mote * 113 + 29) - time * (5.0 + float(mote % 3) * 2.0) + h * 8.0, maxf(h, 1.0))
		draw_circle(Vector2(x, y), 1.1, Color(0.76, 0.9, 0.83, 0.12 + 0.08 * sin(time + float(mote))))
