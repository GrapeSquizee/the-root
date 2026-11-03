extends Control
## 낮 분류 / 밤 방어 프로토타입 화면. 그림 없이 도형만 쓴다.
## 실행: Godot에서 res://daynight/day_night.tscn을 열고 F6.

const Logic = preload("res://daynight/day_night_logic.gd")

const BG := Color("#14171c")
const PANEL := Color("#1d222a")
const INK := Color("#e8e2d4")
const DIM := Color("#8a8f98")
const SKY := Color("#7fd3f2")      # 정답·복원의 하늘색 선
const RED := Color("#d9574a")      # 연우만 보는 붉은 줄
const YELLOW := Color("#e8c547")   # 서린의 노란 실
const BLUR := Color("#9a8fb0")     # 시간 초과의 흐릿한 선택
const UNDOER := Color("#cfc9bd")   # 회백색 해체자
const CLOTH := Color("#c9b48a")
const NIGHT_TINT := Color(0.03, 0.04, 0.09, 0.55)

var logic: Logic
var font: SystemFont
var hover_node := ""
var hover_edge := []
var pulse := 0.0

var top_label: Label
var info_label: Label
var card_label: Label
var feedback_label: Label
var left_button: Button
var right_button: Button
var lock_button: Button
var action_button: Button
var fix_button: Button


func _ready() -> void:
	logic = Logic.new()
	logic.changed.connect(_refresh)
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "Noto Sans CJK KR", "Arial"])
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 18
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh()


func _build_ui() -> void:
	top_label = _label(Vector2(24, 14), 22)
	info_label = _label(Vector2(24, 50), 16)
	info_label.add_theme_color_override("font_color", DIM)
	card_label = _label(Vector2(1060, 120), 20)
	card_label.size = Vector2(200, 300)
	card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label = _label(Vector2(24, 670), 17)
	feedback_label.size = Vector2(1000, 30)

	left_button = _button(Vector2(1060, 430), Vector2(200, 52), func(): logic.choose(0))
	right_button = _button(Vector2(1060, 490), Vector2(200, 52), func(): logic.choose(1))
	lock_button = _button(Vector2(1060, 560), Vector2(200, 40), func(): logic.lock())
	lock_button.text = "여기서 확정"
	action_button = _button(Vector2(1060, 620), Vector2(200, 52), _on_action)
	fix_button = _button(Vector2(1060, 560), Vector2(200, 46), func(): logic.fix())


func _label(pos: Vector2, size_px: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", INK)
	add_child(l)
	return l


func _button(pos: Vector2, sz: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	add_child(b)
	return b


func _on_action() -> void:
	match logic.phase:
		"title": logic.start_game()
		"evening": logic.start_night()
		"dawn": logic.next_day()
		"end":
			logic = Logic.new()
			logic.changed.connect(_refresh)
			_refresh()


# ---------- 진행 ----------

func _process(delta: float) -> void:
	pulse += delta
	match logic.phase:
		"day": logic.update_day(delta)
		"night":
			logic.slowing = Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			logic.update_night(delta)
	_refresh_dynamic()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if logic.phase == "day":
			if event.keycode == KEY_LEFT or event.keycode == KEY_A:
				logic.choose(0)
			elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
				logic.choose(1)
			elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
				logic.lock()
		elif event.keycode == KEY_ENTER and action_button.visible:
			_on_action()
		elif event.keycode == KEY_F and fix_button.visible:
			logic.fix()
	if event is InputEventMouseMotion:
		hover_node = _node_at(event.position)
		hover_edge = [] if hover_node != "" else _edge_at(event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if logic.phase == "evening":
			var e := _edge_at(event.position)
			if not e.is_empty():
				logic.toggle_yellow(e[0], e[1])
		elif logic.phase == "night":
			var n := _node_at(event.position)
			if n != "":
				logic.mend(n)


func _node_at(p: Vector2) -> String:
	for id in Logic.NODES:
		if logic.node_pos(id).distance_to(p) < 34.0:
			return id
	return ""


func _edge_at(p: Vector2) -> Array:
	for e in Logic.EDGES:
		var a := logic.node_pos(e[0])
		var b := logic.node_pos(e[1])
		var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
		if closest.distance_to(p) < 10.0 and closest.distance_to(a) > 30.0 and closest.distance_to(b) > 30.0:
			return e
	return []


# ---------- 글자 ----------

func _refresh() -> void:
	var ph := logic.phase
	card_label.visible = ph == "day"
	left_button.visible = ph == "day"
	right_button.visible = ph == "day"
	lock_button.visible = ph == "day"
	fix_button.visible = ph == "evening" or ph == "night"
	action_button.visible = ph in ["title", "evening", "dawn", "end"]
	match ph:
		"title":
			top_label.text = "THE ROOT — 낮과 밤 프로토타입"
			info_label.text = "낮에는 분류해서 이음을 모으고, 밤에는 해체자를 막아 이름을 지킨다."
			feedback_label.text = "낮: ←/→ 분류, ↓ 여기서 확정 · 저녁: 선 클릭 = 노란 실 · 밤: 집 클릭 = 이음, Space/우클릭 = 여유(느린 시간), F = 고정"
			action_button.text = "시작 (Enter)"
		"day":
			var s := logic.step()
			if not s.is_empty():
				left_button.text = "← " + s[0]
				right_button.text = s[1] + " →"
			lock_button.disabled = logic.step_index == 0
			feedback_label.text = logic.last_feedback
		"evening":
			top_label.text = "%d일째 저녁" % logic.day
			action_button.text = "밤을 맞는다 (Enter)"
			feedback_label.text = "점선은 해체자가 올 길이다. 선을 눌러 노란 실을 건다(이음 1). 고정은 이번 밤 이름을 지키지만 내일은 자라는 것이 멈춘다."
		"night":
			top_label.text = "%d일째 밤" % logic.day
			feedback_label.text = "사각거리는 소리가 들린다. 끊기는 집을 눌러 다시 잇는다(이음 1)."
		"dawn":
			var r: Dictionary = logic.dawn_report
			top_label.text = "%d일째 새벽" % r["day"]
			var lines := []
			lines.append("잃은 이름 %d · 다시 이은 곳 %d · 기록 천에 닿은 해체자 %d" % [r["names_lost"], r["mended"], r["cloth_hits"]])
			if r["fixed"]:
				lines.append("고정한 날이다. 새 잎이 펴지지 않았다. 서린은 오른손을 주머니에 넣었다.")
			else:
				lines.append("새 잎이 한 장 펴졌다.")
			feedback_label.text = "  ".join(lines)
			action_button.text = "다음 날 (Enter)" if logic.day < Logic.DAYS and logic.cloth_hp > 0 else "끝 (Enter)"
		"end":
			top_label.text = "끝"
			feedback_label.text = "남은 이름 %d · 잃은 이름 %d · 새 잎 %d · 영역 안정화율 %.3f%%" % [logic.names_left(), logic.names_lost_total, logic.leaves, logic.stability]
			if logic.cloth_hp <= 0:
				feedback_label.text += " · 기록 천이 끊겼다."
			action_button.text = "다시 (Enter)"
	if logic.phase in ["evening", "night"]:
		fix_button.disabled = not logic.can_fix()
		fix_button.text = "고정 (F)" if logic.fix_cooldown == 0 else "고정 — %d일 뒤" % logic.fix_cooldown
		if logic.fixed_tonight:
			fix_button.text = "고정됨"


func _refresh_dynamic() -> void:
	info_label.text = "이음 %d   여유 %.1f   서린의 손 %d/%d   기록 천 %d   남은 이름 %d   새 잎 %d   영역 안정화율 %.3f%%" % [
		logic.ieum, logic.yeoyu, logic.hand, Logic.HAND_LIMIT, logic.cloth_hp, logic.names_left(), logic.leaves, logic.stability]
	if logic.phase == "day":
		var c := logic.card()
		if c.is_empty():
			return
		top_label.text = "%d일째 낮 — %d/%d" % [logic.day, logic.card_index + 1, logic.deck.size()]
		var where := "지구에서 알던 것" if c["world"] == "earth" else "이 세계의 것"
		var txt := "%s\n(%s)\n\n" % [c["name"], where]
		if c.has("note"):
			txt += c["note"] + "\n\n"
		txt += "걸린 곳: %s\n\n" % Logic.NODES[c["house"]]["label"]
		if logic.adaptation_notice and logic.card_index == 0 and logic.step_index == 0:
			txt += "적응 구간 종료.\n"
		txt += "분류:" if logic.step_index < c["steps"].size() - 1 else "최종 분류:"
		card_label.text = txt
	elif logic.phase == "night":
		top_label.text = "%d일째 밤 — %.0f" % [logic.day, max(Logic.NIGHT_LENGTH - logic.night_time, 0.0)]


# ---------- 그림 ----------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	draw_rect(Rect2(40, 80, 1000, 580), PANEL)
	_draw_edges()
	if logic.phase == "evening":
		_draw_predictions()
	_draw_nodes()
	if logic.phase == "night":
		draw_rect(Rect2(40, 80, 1000, 580), NIGHT_TINT)
		if logic.time_scale() < 1.0:
			draw_rect(Rect2(40, 80, 1000, 580), Color(0.5, 0.8, 1.0, 0.06))
		if logic.fixed_tonight:
			draw_rect(Rect2(40, 80, 1000, 580), Color(0.9, 0.85, 0.6, 0.05))
		# 끊기는 진행과 해체자는 어둠 위에 그린다.
		for id in logic.houses:
			var cut: float = logic.houses[id]["cut"]
			if cut > 0.0:
				draw_arc(logic.node_pos(id), 36, -PI / 2, -PI / 2 + TAU * cut, 32, RED, 4.0)
		_draw_undoers()
	if logic.phase == "day":
		_draw_timer()


func _draw_edges() -> void:
	for e in Logic.EDGES:
		var a := logic.node_pos(e[0])
		var b := logic.node_pos(e[1])
		var col := Color(SKY, 0.35)
		var w := 2.0
		if logic.yellow.has(Logic.edge_key(e[0], e[1])):
			col = YELLOW
			w = 4.0
		if hover_edge == e and logic.phase == "evening":
			col = col.lightened(0.4)
			w += 2.0
		draw_line(a, b, col, w, true)


func _draw_predictions() -> void:
	for path in logic.predicted_paths():
		for i in path.size() - 1:
			var a := logic.node_pos(path[i])
			var b := logic.node_pos(path[i + 1])
			draw_dashed_line(a, b, Color(UNDOER, 0.8), 2.0, 8.0)


func _draw_nodes() -> void:
	for id in Logic.NODES:
		var n: Dictionary = Logic.NODES[id]
		var p: Vector2 = n["pos"]
		match n["kind"]:
			"edge":
				draw_circle(p, 10, Color(DIM, 0.6))
			"well":
				draw_circle(p, 26, Color("#e9b7c0", 0.5))
				draw_arc(p, 26, 0, TAU, 32, Color("#e9b7c0"), 2.0)
			"cloth":
				var r := Rect2(p - Vector2(34, 22), Vector2(68, 44))
				draw_rect(r, CLOTH if logic.cloth_hp > 0 else Color(CLOTH, 0.25))
				for i in logic.cloth_hp:
					var x := 6.0 + (i % 6) * 10.0
					var y := 10.0 if i < 6 else 26.0
					draw_line(r.position + Vector2(x, y + 10), r.position + Vector2(x + 6, y), Color("#2a2a2a"), 2.0)
			"house":
				var h: Dictionary = logic.houses[id]
				var base := Color("#3a4250")
				draw_rect(Rect2(p - Vector2(26, 20), Vector2(52, 40)), base)
				if h["red"] > 0:
					draw_rect(Rect2(p - Vector2(30, 24), Vector2(60, 48)), RED, false, 1.5 + h["red"] * 1.5)
				if h["blur"]:
					draw_rect(Rect2(p - Vector2(34, 28), Vector2(68, 56)), Color(BLUR, 0.6), false, 1.0)
				for i in h["names"]:
					draw_circle(p + Vector2(-10 + i * 20, 0), 6, INK)
				if h["cut"] > 0.0:
					draw_arc(p, 36, -PI / 2, -PI / 2 + TAU * h["cut"], 32, RED, 4.0)
				if hover_node == id and logic.phase == "night":
					draw_arc(p, 40, 0, TAU, 32, SKY, 2.0)
		draw_string(font, p + Vector2(-40, 44), n["label"], HORIZONTAL_ALIGNMENT_CENTER, 80, 13, DIM)


func _draw_undoers() -> void:
	for u in logic.undoers:
		if u["t"] < 0.0 and u["seg"] == 0:
			continue
		var p: Vector2 = u["pos"]
		var jitter := Vector2(sin(pulse * 9.0 + p.x), cos(pulse * 7.0 + p.y)) * 2.0
		for k in 6:
			var ang := pulse * 3.0 + k * TAU / 6.0
			draw_line(p + jitter, p + jitter + Vector2(cos(ang), sin(ang)) * 14.0, UNDOER, 2.0)
		draw_circle(p + jitter, 6, UNDOER)


func _draw_timer() -> void:
	var ratio := logic.timer / logic.time_limit
	var r := Rect2(1060, 400, 200, 14)
	draw_rect(r, Color("#2a3038"))
	draw_rect(Rect2(r.position, Vector2(r.size.x * ratio, r.size.y)), RED if ratio < 0.3 else SKY)
	draw_string(font, Vector2(1060, 392), "%.1f" % logic.timer, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
