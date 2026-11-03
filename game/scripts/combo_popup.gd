extends Control

const CYAN := Color("#74d9f4")
const WHITE := Color("#ecfbff")

var combo := 0
var burst := 0.0:
	set(value):
		burst = value
		if is_instance_valid(spark_layer):
			spark_layer.queue_redraw()

var banner: PanelContainer
var count_label: Label
var spark_layer: Control
var animation: Tween
var sparks_animation: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	banner = PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#061614f2")
	style.border_color = CYAN
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color = Color("#74d9f466")
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	banner.add_theme_stylebox_override("panel", style)
	add_child(banner)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 9)
	banner.add_child(row)
	count_label = Label.new()
	count_label.add_theme_font_override("font", _font())
	count_label.add_theme_font_size_override("font_size", 36)
	count_label.add_theme_color_override("font_color", WHITE)
	row.add_child(count_label)
	var word := Label.new()
	word.text = "COMBO"
	word.add_theme_font_override("font", _font())
	word.add_theme_font_size_override("font_size", 15)
	word.add_theme_color_override("font_color", CYAN)
	row.add_child(word)
	spark_layer = Control.new()
	spark_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spark_layer.draw.connect(_draw_sparks)
	add_child(spark_layer)


func pop(value: int) -> void:
	combo = value
	count_label.text = "%02d" % combo
	visible = true
	if animation != null:
		animation.kill()
	if sparks_animation != null:
		sparks_animation.kill()
	banner.pivot_offset = size * 0.5
	banner.position = Vector2.ZERO
	banner.scale = Vector2.ONE
	banner.modulate.a = 1.0
	burst = 1.0
	sparks_animation = create_tween()
	sparks_animation.tween_property(self, "burst", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation = create_tween()
	animation.tween_property(banner, "position:y", 14.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	animation.parallel().tween_property(banner, "scale", Vector2(1.17, 0.82), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	animation.tween_property(banner, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.parallel().tween_property(banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.tween_interval(0.65)
	animation.tween_property(banner, "modulate:a", 0.0, 0.22)
	animation.tween_callback(func(): visible = false)


func clear() -> void:
	combo = 0
	visible = false
	burst = 0.0
	if animation != null:
		animation.kill()
	if sparks_animation != null:
		sparks_animation.kill()


func _draw_sparks() -> void:
	if burst <= 0.0:
		return
	var center := size * 0.5
	var fade := WHITE
	fade.a = burst * 0.95
	for i in range(16):
		var angle := TAU * float(i) / 16.0 + float(combo % 5) * 0.18
		var direction := Vector2(cos(angle), sin(angle))
		var start := center + direction * (41.0 + (1.0 - burst) * 23.0)
		var end := start + direction * (14.0 + (1.0 - burst) * 23.0)
		spark_layer.draw_line(start, end, fade, 2.8 if i % 2 == 0 else 1.7, true)
		spark_layer.draw_circle(end, 2.7 * burst, fade)
	var flare := CYAN
	flare.a = burst * 0.72
	spark_layer.draw_line(Vector2(-18, center.y), Vector2(size.x + 18, center.y), flare, 2.0, true)


func _font() -> SystemFont:
	var result := SystemFont.new()
	result.font_names = PackedStringArray(["Arial Black", "Segoe UI Black", "Arial"])
	return result
