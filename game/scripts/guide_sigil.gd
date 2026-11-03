extends Control

var pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var cyan := Color("#74d9f4")
	var gold := Color("#cba46a")
	var breathing := 0.5 + 0.5 * sin(pulse * 2.2)
	draw_circle(center, 30.0 + breathing * 4.0, Color(0.45, 0.85, 0.95, 0.05 + breathing * 0.04))
	draw_arc(center, 27.0, -PI * 0.75, PI * 0.75, 48, gold.darkened(0.25), 1.0)
	draw_arc(center, 19.0, PI * 0.25, PI * 1.75, 48, cyan.darkened(0.2), 1.0)
	draw_line(center + Vector2(0, 19), center + Vector2(0, -14), cyan, 2.0)
	for side in [-1.0, 1.0]:
		draw_line(center + Vector2(0, -3), center + Vector2(side * 15, -20), cyan, 1.5)
		draw_line(center + Vector2(0, 16), center + Vector2(side * 13, 25), gold, 1.5)
		draw_circle(center + Vector2(side * 15, -20), 2.5, cyan)
	draw_circle(center + Vector2(0, -15), 3.5, Color.WHITE)
