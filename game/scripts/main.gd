extends Control

const Logic = preload("res://scripts/classification.gd")
const RootTrace = preload("res://scripts/root_trace.gd")
const ComboPopup = preload("res://scripts/combo_popup.gd")
const HabitatResponse = preload("res://scripts/habitat_response.gd")
const Collection = preload("res://scripts/collection.gd")
const GuideSigil = preload("res://scripts/guide_sigil.gd")
const GuideBackdrop = preload("res://scripts/guide_backdrop.gd")
const BG := Color("#0a1414")
const DARK := Color("#071312dd")
const PAPER := Color("#081514ee")
const WHITE := Color("#faf7ee")
const INK := Color("#f0e8d7")
const SOFT := Color("#bed0c4")
const GOLD := Color("#cba46a")
const LINE := Color("#806b49")
const QUICK_SECONDS := 2.0
const DESCENT_SECONDS := 22.5
const CHECKPOINT_INTERVAL := 6
const STORY_CHECKPOINTS := [6, 12, 18]
const WRONG_TIME_PENALTY := 3.0
const CAMPFIRE_REST_SECONDS := 2.0
const SHOP_TIME_SECONDS := 3.0
const SHOP_TIME_COST := 4
const SHOP_INSIGHT_COST := 3
const COMBO_EMBER_INTERVAL := 4
const QUICK_VERDICT_SECONDS := 0.65
const SCENE_FADE_OUT_SECONDS := 0.38
const SCENE_FADE_IN_SECONDS := 0.9

var logic = Logic.new()
var collection = Collection.new()
var collection_overlay: ColorRect
var collection_grid: GridContainer
var collection_count: Label
var collection_open := false
var reward_granted_run := false
var awarded_specimen := ""
var body_font: SystemFont
var title_font: SystemFont
var progress_label: Label
var score_label: Label
var chaos_label: Label
var path_label: Label
var path_footer_label: Label
var floor_label: Label
var root_trace: Control
var root_marks: Array[Dictionary] = []
var card_index: Label
var depth_label: Label
var card_name: Label
var card_subtitle: Label
var specimen_texture: TextureRect
var combo_popup: Control
var habitat_response: Control
var combo_count := 0
var max_combo := 0
var prompt_label: Label
var left_button: Button
var right_button: Button
var left_explanation: Label
var right_explanation: Label
var observe_button: Button
var lock_button: Button
var skip_button: Button
var hint_label: Label
var hint_state: Label
var bank_label: Label
var feedback_label: Label
var intro_overlay: ColorRect
var intro_error_label: Label
var game_page: VBoxContainer
var header_shade: ColorRect
var brand_subtitle: Label
var clock_label: Label
var clock_bar: ProgressBar
var clock_remaining := 0.0
var clock_running := false
var run_mode := "real"
var descent_hits := 0
var descent_reached := 0
var descent_best := 0
var descent_total := 0
var embers := 0
var insight_remaining := 0
var showing_campfire := false
var campfire_overlay: ColorRect
var transition_overlay: ColorRect
var transition_tween: Tween
var transition_active := false
var checkpoint_title: Label
var checkpoint_mark: Label
var campfire_review: Label
var campfire_choice_left: Button
var campfire_choice_right: Button
var campfire_continue: Button
var review_left_id := ""
var review_right_id := ""
var review_answer_id := ""
var review_lines: Array[String] = []
var review_answered := false
var checkpoint_phase := ""
var guide_dialogue: Dictionary = {}
var guide_beat: Dictionary = {}
var story_stance := ""
var campfire_wallet: Label
var campfire_time_button: Button
var campfire_insight_button: Button
var bought_time := false
var bought_insight := false
var checkpoints_reached := 0
var choice_left := ""
var choice_right := ""
var showing_verdict := false
var showing_result := false
var quick_verdict_token := 0


func _ready() -> void:
	if not logic.load_data():
		var error_label := Label.new()
		error_label.text = "data/prototype.json을 읽지 못했습니다."
		add_child(error_label)
		return
	collection.load_collection()
	var guide_file := FileAccess.open("res://data/guide_dialogue.json", FileAccess.READ)
	if guide_file != null:
		var guide_data = JSON.parse_string(guide_file.get_as_text())
		if guide_data is Dictionary:
			guide_dialogue = guide_data
	body_font = SystemFont.new()
	body_font.font_names = PackedStringArray(["Malgun Gothic", "Noto Sans CJK KR", "Arial"])
	title_font = SystemFont.new()
	title_font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	_build_ui()
	logic.start()
	_render()
	_show_intro()


func _input(event: InputEvent) -> void:
	if transition_active:
		return
	if collection_open:
		if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept")):
			_close_collection()
		return
	if intro_overlay != null:
		return
	if not event.is_pressed() or event.is_echo():
		return
	if showing_campfire:
		var checkpoint_key := event as InputEventKey
		if event.is_action_pressed("ui_accept"):
			_continue_checkpoint()
		elif event.is_action_pressed("ui_left") or (checkpoint_key != null and (checkpoint_key.keycode == KEY_A or checkpoint_key.physical_keycode == KEY_A)):
			_checkpoint_choice(0)
		elif event.is_action_pressed("ui_right") or (checkpoint_key != null and (checkpoint_key.keycode == KEY_D or checkpoint_key.physical_keycode == KEY_D)):
			_checkpoint_choice(1)
		return
	if showing_verdict:
		if event.is_action_pressed("ui_accept"):
			showing_verdict = false
			_render()
			_start_clock()
			get_viewport().set_input_as_handled()
		return
	if showing_campfire or showing_result or logic.is_finished():
		return
	var key := event as InputEventKey
	var left_pressed := event.is_action_pressed("ui_left") or (key != null and (key.keycode == KEY_A or key.physical_keycode == KEY_A))
	var right_pressed := event.is_action_pressed("ui_right") or (key != null and (key.keycode == KEY_D or key.physical_keycode == KEY_D))
	if left_pressed:
		_choose(choice_left)
		get_viewport().set_input_as_handled()
	elif right_pressed:
		_choose(choice_right)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not clock_running or transition_active:
		return
	clock_remaining = maxf(0.0, clock_remaining - delta)
	_update_clock()
	if clock_remaining <= 0.0:
		if run_mode == "descent":
			_show_result()
		else:
			_timeout()


func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/world-tree.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color("#06121166")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	header_shade = ColorRect.new()
	header_shade.color = Color("#061211cc")
	header_shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header_shade.custom_minimum_size.y = 104
	header_shade.offset_bottom = 104
	add_child(header_shade)
	var outer := _margin(34, 25, 34, 23)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer)
	var page := VBoxContainer.new()
	game_page = page
	page.add_theme_constant_override("separation", 15)
	outer.add_child(page)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 61
	header.add_theme_constant_override("separation", 24)
	page.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", -4)
	header.add_child(brand)
	brand.add_child(_label("T H E   R O O T", 26, WHITE, true))
	brand_subtitle = _label("CLASSIFICATION ARCHIVE  /  FIELD TEST 03", 11, GOLD)
	brand.add_child(brand_subtitle)
	progress_label = _label("", 14, WHITE)
	header.add_child(progress_label)
	score_label = _label("", 14, WHITE)
	header.add_child(score_label)
	chaos_label = _label("", 14, GOLD)
	header.add_child(chaos_label)
	page.add_child(_rule(GOLD, 2))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 15)
	page.add_child(body)
	_build_path(body)
	_build_card(body)
	_build_notes(body)
	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 32
	page.add_child(footer)
	footer.add_child(_label("THE ROOT   /   모든 선택은 세계의 구조로 남는다", 12, GOLD))
	feedback_label = _label("A / D · ← / →  또는 선택지로 분류하세요.", 14, WHITE)
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(feedback_label)
	_build_campfire()
	_build_collection()
	_build_transition()


func _build_path(body: HBoxContainer) -> void:
	var panel := _panel(DARK, GOLD, 1)
	panel.custom_minimum_size.x = 207
	body.add_child(panel)
	var pad := _margin(20, 21, 17, 21)
	panel.add_child(pad)
	var column := _column(17)
	pad.add_child(column)
	column.add_child(_label("01   /   THE TREE", 11, GOLD))
	column.add_child(_rule(Color("#41655b"), 1))
	column.add_child(_label("분류 경로", 22, WHITE))
	floor_label = _label("", 14, GOLD)
	column.add_child(floor_label)
	path_label = _label("", 15, Color("#d1e1d5"))
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	path_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(path_label)
	root_trace = RootTrace.new()
	root_trace.custom_minimum_size.y = 300
	root_trace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_trace.visible = false
	column.add_child(root_trace)
	column.add_child(_rule(Color("#41655b"), 1))
	path_footer_label = _label("맞힐수록 다음 갈래가\n열립니다.", 12, Color("#9db8a9"))
	column.add_child(path_footer_label)


func _build_card(body: HBoxContainer) -> void:
	var panel := _panel(PAPER, GOLD, 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(panel)
	var pad := _margin(24, 17, 24, 17)
	panel.add_child(pad)
	var column := _column(8)
	pad.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	card_index = _label("", 12, SOFT)
	card_index.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(card_index)
	depth_label = _label("", 12, SOFT)
	top.add_child(depth_label)
	column.add_child(_rule(LINE, 1))
	card_name = _label("", 35, INK)
	card_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(card_name)
	card_subtitle = _label("", 14, SOFT)
	card_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(card_subtitle)
	prompt_label = _label("이 개체는 어디에 속할까요?", 17, GOLD)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(prompt_label)
	var timer_row := HBoxContainer.new()
	timer_row.add_theme_constant_override("separation", 12)
	column.add_child(timer_row)
	clock_label = _label("", 15, GOLD)
	clock_label.custom_minimum_size.x = 87
	timer_row.add_child(clock_label)
	clock_bar = ProgressBar.new()
	clock_bar.min_value = 0
	clock_bar.max_value = QUICK_SECONDS
	clock_bar.show_percentage = false
	clock_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock_bar.custom_minimum_size.y = 8
	clock_bar.add_theme_stylebox_override("background", _style(Color("#26342f"), LINE, 0))
	clock_bar.add_theme_stylebox_override("fill", _style(GOLD, GOLD, 0))
	timer_row.add_child(clock_bar)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	column.add_child(choices)
	var left := _choice_column(choices, "01  /  LEFT")
	left_button = _choice_button()
	left_button.pressed.connect(func():
		if showing_result and run_mode == "descent":
			_show_collection()
		else:
			_choose(choice_left)
	)
	left.add_child(left_button)
	left_explanation = _label("", 14, SOFT)
	left_explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_explanation.custom_minimum_size.y = 65
	left.add_child(left_explanation)
	var art_frame := _panel(Color("#0b1917"), GOLD, 1)
	art_frame.custom_minimum_size = Vector2(207, 248)
	choices.add_child(art_frame)
	var art_pad := _margin(3, 3, 3, 3)
	art_frame.add_child(art_pad)
	specimen_texture = TextureRect.new()
	specimen_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	specimen_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_pad.add_child(specimen_texture)
	combo_popup = ComboPopup.new()
	combo_popup.anchor_left = 0.5
	combo_popup.anchor_right = 0.5
	combo_popup.anchor_top = 1.0
	combo_popup.anchor_bottom = 1.0
	combo_popup.offset_left = -116
	combo_popup.offset_right = 116
	combo_popup.offset_top = -38
	combo_popup.offset_bottom = 30
	specimen_texture.add_child(combo_popup)
	var right := _choice_column(choices, "02  /  RIGHT")
	right_button = _choice_button()
	right_button.pressed.connect(func():
		if showing_verdict:
			showing_verdict = false
			_render()
			_start_clock()
		elif showing_result:
			_restart_run()
		else:
			_choose(choice_right)
	)
	right.add_child(right_button)
	right_explanation = _label("", 14, SOFT)
	right_explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_explanation.custom_minimum_size.y = 65
	right.add_child(right_explanation)
	column.add_child(_rule(LINE, 1))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	column.add_child(actions)
	habitat_response = HabitatResponse.new()
	habitat_response.custom_minimum_size.y = 72
	habitat_response.visible = false
	column.add_child(habitat_response)
	observe_button = _action_button("관찰  −30%")
	observe_button.pressed.connect(_observe)
	actions.add_child(observe_button)
	lock_button = _action_button("여기서 확정")
	lock_button.pressed.connect(_lock)
	actions.add_child(lock_button)
	skip_button = _action_button("건너뛰기")
	skip_button.pressed.connect(_skip)
	actions.add_child(skip_button)


func _build_notes(body: HBoxContainer) -> void:
	var panel := _panel(DARK, GOLD, 1)
	panel.custom_minimum_size.x = 233
	body.add_child(panel)
	var pad := _margin(18, 21, 17, 21)
	panel.add_child(pad)
	var column := _column(16)
	pad.add_child(column)
	column.add_child(_label("02   /   FIELD NOTES", 11, GOLD))
	column.add_child(_rule(Color("#41655b"), 1))
	column.add_child(_label("관찰 기록", 22, WHITE))
	hint_state = _label("", 12, GOLD)
	column.add_child(hint_state)
	hint_label = _label("", 15, WHITE)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(hint_label)
	column.add_child(_rule(Color("#41655b"), 1))
	bank_label = _label("", 13, Color("#d1e1d5"))
	bank_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(bank_label)
	column.add_child(_label("용어의 뜻은 선택지 아래에\n항상 무료로 표시됩니다.", 11, Color("#9db8a9")))


func _build_campfire() -> void:
	campfire_overlay = ColorRect.new()
	campfire_overlay.color = Color("#071310")
	campfire_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	campfire_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	campfire_overlay.visible = false
	add_child(campfire_overlay)
	var chamber := GuideBackdrop.new()
	chamber.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	campfire_overlay.add_child(chamber)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	campfire_overlay.add_child(center)
	var panel := _panel(Color("#0d1b18"), GOLD, 1)
	panel.custom_minimum_size = Vector2(660, 0)
	center.add_child(panel)
	var pad := _margin(34, 28, 34, 28)
	panel.add_child(pad)
	var column := _column(10)
	pad.add_child(column)
	var sigil := GuideSigil.new()
	sigil.custom_minimum_size.y = 88
	column.add_child(sigil)
	checkpoint_mark = _label("✦   CHECKPOINT   /   THE WITNESS", 13, GOLD)
	checkpoint_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(checkpoint_mark)
	checkpoint_title = _label("뿌리의 목소리", 34, WHITE)
	checkpoint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(checkpoint_title)
	column.add_child(_rule(LINE, 1))
	campfire_review = _label("", 16, WHITE)
	campfire_review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	campfire_review.custom_minimum_size.y = 95
	column.add_child(campfire_review)
	var recall_choices := HBoxContainer.new()
	recall_choices.add_theme_constant_override("separation", 9)
	column.add_child(recall_choices)
	campfire_choice_left = _action_button("")
	campfire_choice_left.pressed.connect(func(): _checkpoint_choice(0))
	recall_choices.add_child(campfire_choice_left)
	campfire_choice_right = _action_button("")
	campfire_choice_right.pressed.connect(func(): _checkpoint_choice(1))
	recall_choices.add_child(campfire_choice_right)
	column.add_child(_rule(LINE, 1))
	campfire_wallet = _label("", 14, GOLD)
	column.add_child(campfire_wallet)
	campfire_time_button = _action_button("불씨 4개  /  남은 시간 +3초")
	campfire_time_button.pressed.connect(_buy_time)
	column.add_child(campfire_time_button)
	campfire_insight_button = _action_button("불씨 3개  /  다음 3갈래 정답 표시")
	campfire_insight_button.pressed.connect(_buy_insight)
	column.add_child(campfire_insight_button)
	campfire_continue = _choice_button()
	campfire_continue.text = "더 깊이 내려가기   →"
	campfire_continue.pressed.connect(_continue_checkpoint)
	column.add_child(campfire_continue)


func _build_transition() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color("#02070700")
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_overlay.visible = false
	add_child(transition_overlay)


func _build_collection() -> void:
	collection_overlay = ColorRect.new()
	collection_overlay.color = Color("#030b0af2")
	collection_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	collection_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	collection_overlay.visible = false
	add_child(collection_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	collection_overlay.add_child(center)
	var panel := _panel(Color("#0c1b18"), GOLD, 1)
	panel.custom_minimum_size.x = 760
	center.add_child(panel)
	var pad := _margin(30, 24, 30, 24)
	panel.add_child(pad)
	var column := _column(12)
	pad.add_child(column)
	var title := _label("세계의 봉인 표본", 31, WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	collection_count = _label("", 14, GOLD)
	collection_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(collection_count)
	column.add_child(_rule(LINE, 1))
	collection_grid = GridContainer.new()
	collection_grid.columns = 3
	collection_grid.add_theme_constant_override("h_separation", 10)
	collection_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(collection_grid)
	var close := _action_button("도감 닫기   /   ESC")
	close.pressed.connect(_close_collection)
	column.add_child(close)


func _show_collection() -> void:
	for child in collection_grid.get_children():
		child.queue_free()
	var entries: Array = logic.entities if logic.mode_id == "fantasy" else _fantasy_entities()
	for entity in entries:
		var specimen_id := str(entity["entity_id"])
		var acquired: bool = collection.owned.has(specimen_id)
		var tile := _panel(Color("#102622") if acquired else Color("#101a19"), Color("#74d9f4") if acquired else LINE, 1)
		tile.custom_minimum_size = Vector2(220, 196)
		collection_grid.add_child(tile)
		var pad := _margin(8, 8, 8, 8)
		tile.add_child(pad)
		var stack := _column(3)
		pad.add_child(stack)
		var image := TextureRect.new()
		image.custom_minimum_size.y = 142
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if acquired:
			image.texture = load("res://assets/specimen-%s.svg" % specimen_id)
		stack.add_child(image)
		var name := _label(str(entity["name_ko"]) if acquired else "미복원 표본", 16, WHITE if acquired else SOFT)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(name)
	collection_count.text = "복원 %d / %d   ·   뿌리 원정 완주마다 새 표본 하나" % [collection.owned.size(), entries.size()]
	collection_overlay.visible = true
	collection_overlay.move_to_front()
	collection_open = true


func _close_collection() -> void:
	collection_overlay.visible = false
	collection_open = false


func _fantasy_entities() -> Array:
	var file := FileAccess.open("res://data/fantasy.json", FileAccess.READ)
	if file == null:
		return []
	var data = JSON.parse_string(file.get_as_text())
	return data.get("entities", []) if data is Dictionary else []


func _render() -> void:
	progress_label.text = "SPECIMEN  %02d / %02d" % [mini(logic.current_index + 1, logic.entities.size()), logic.entities.size()]
	score_label.text = "SCORE  %04d" % logic.total_score
	chaos_label.text = "CHAOS  %02d" % logic.chaos
	if logic.is_finished():
		_show_result()
		return
	showing_result = false
	var entity := logic.entity()
	var step := logic.step()
	var options: Array[String] = [str(step["correct_category_id"]), str(step["distractor_category_id"])]
	if (logic.current_index + logic.depth) % 2 == 0:
		options.reverse()
	choice_left = options[0]
	choice_right = options[1]
	card_index.text = "ARCHIVE  /  %s" % str(entity["entity_id"]).to_upper()
	depth_label.text = "DEPTH %d / %d" % [logic.depth, entity["max_depth"]]
	card_name.text = str(entity["name_ko"])
	card_subtitle.text = "%s    ·    %s" % [entity["name_en"], entity["scientific_name"]]
	var art_base := "res://assets/specimen-%s" % str(entity["entity_id"])
	var art_path := art_base + (".svg" if FileAccess.file_exists(art_base + ".svg") else ".png")
	specimen_texture.texture = load(art_path)
	prompt_label.text = "남은 시간에 최대한 깊이 내려가세요" if run_mode == "descent" else ("2초 안에 분류하세요" if _is_quick_mode() else "이 개체는 어디에 속할까요?")
	left_button.text = "←  " + logic.category_name(choice_left)
	right_button.text = logic.category_name(choice_right) + "  →"
	if run_mode == "descent" and insight_remaining > 0:
		if choice_left == str(step["correct_category_id"]):
			left_button.text = "✦  " + left_button.text
		else:
			right_button.text = "✦  " + right_button.text
	left_explanation.text = logic.category_explanation(choice_left)
	right_explanation.text = logic.category_explanation(choice_right)
	left_button.disabled = false
	right_button.disabled = false
	observe_button.visible = not _is_timed_mode()
	lock_button.visible = not _is_timed_mode()
	skip_button.visible = not _is_timed_mode()
	habitat_response.visible = _is_timed_mode()
	observe_button.disabled = logic.observed
	lock_button.disabled = logic.card_points <= 0
	skip_button.disabled = false
	var lines: Array[String] = ["●  THE ROOT"]
	for i in range(logic.depth - 1):
		lines.append("│")
		lines.append("●  " + logic.category_name(str(entity["path"][i])))
	lines.append("│\n◇  다음 갈래")
	path_label.text = "\n".join(lines)
	floor_label.text = "FLOOR  %02d / %02d" % [descent_reached + 1, descent_total] if run_mode == "descent" else ""
	floor_label.visible = run_mode == "descent"
	_sync_root_trace()
	hint_state.text = "즉시 판독  /  %d단계" % logic.depth if _is_timed_mode() else ("관찰 완료" if logic.observed else "관찰 가능  /  1회")
	var field_note := str(entity.get("field_note", "선택지의 뜻을 먼저 비교하세요. 추가 단서가 필요하면 관찰을 사용합니다."))
	hint_label.text = str(entity.get("quick_clues", [])[logic.depth - 1]) if _is_timed_mode() else field_note + ("\n\n추가 관찰  /  " + logic.active_hint if logic.observed else "")
	bank_label.text = "도달 %d/%d층  ·  정확 %d\n불씨 %d개" % [descent_reached, descent_total, descent_hits, embers] if run_mode == "descent" else ("현재 카드 누적  %d점\n시간 초과 시 카드 종료" % logic.card_points if _is_quick_mode() else "현재 카드 누적  %d점\n확정하면 깊이 보너스는 포기" % logic.card_points)
	clock_label.visible = _is_timed_mode()
	clock_bar.visible = _is_timed_mode()
	_update_clock()
	_update_descent_hud()


func _choose(category_id: String) -> void:
	if showing_campfire or showing_verdict or showing_result or logic.is_finished():
		return
	if _is_timed_mode() and clock_running and clock_remaining <= 0.0:
		if run_mode == "descent":
			_show_result()
		else:
			_timeout()
		return
	clock_running = false
	var before := logic.entity()
	var before_index: int = logic.current_index
	var before_depth: int = logic.depth
	var direction := -1 if category_id == choice_left else 1
	var response := logic.choose(category_id)
	if response.is_empty():
		return
	_record_combo(bool(response["correct"]))
	if bool(response["correct"]):
		habitat_response.reveal(str(before["entity_id"]), before_depth, str(before["name_ko"]))
	if _is_timed_mode():
		root_marks.append({"direction": direction, "correct": bool(response["correct"])})
	if run_mode == "descent":
		descent_reached += 1
		descent_best = maxi(descent_best, before_depth)
		if bool(response["correct"]):
			descent_hits += 1
			embers += 1
			if combo_count % COMBO_EMBER_INTERVAL == 0:
				embers += 1
		else:
			clock_remaining = maxf(0.0, clock_remaining - WRONG_TIME_PENALTY)
			_update_clock()
		if insight_remaining > 0:
			insight_remaining -= 1
		feedback_label.text = "정답  /  %d COMBO · 불씨 +1" % combo_count if bool(response["correct"]) else "오답  /  시간 −3초 · 다음 갈래로"
		if logic.is_finished() or clock_remaining <= 0.0:
			_show_result()
		else:
			_render()
			if STORY_CHECKPOINTS.has(descent_reached):
				_show_campfire()
			else:
				_start_clock()
		return
	if logic.current_index > before_index:
		_show_verdict(before)
		return
	if bool(response["correct"]):
		feedback_label.text = "정답  /  %s" % logic.category_name(category_id)
	else:
		feedback_label.text = "오답의 흔적을 남기고 계속 진행  /  정답: %s" % logic.category_name(str(response["correct_category_id"]))
	_render()
	_start_clock()


func _record_combo(correct: bool) -> void:
	if correct:
		combo_count += 1
		max_combo = maxi(max_combo, combo_count)
		combo_popup.pop(combo_count)
	else:
		combo_count = 0
		combo_popup.clear()


func _show_campfire() -> void:
	clock_running = false
	showing_campfire = true
	checkpoints_reached += 1
	clock_remaining += CAMPFIRE_REST_SECONDS
	_update_clock()
	bought_time = false
	bought_insight = false
	review_answered = false
	checkpoint_phase = "question"
	guide_beat = guide_dialogue.get(str(descent_reached), {}).duplicate(true)
	if descent_reached == 12:
		guide_beat["opening"] = guide_beat.get("opening_clean" if logic.chaos == 0 else "opening_wrong", guide_beat.get("opening", ""))
	elif descent_reached == 18:
		guide_beat["opening"] = guide_beat.get("opening_" + story_stance, guide_beat.get("opening", ""))
	review_lines.clear()
	var recent: Array[Dictionary] = logic.choices.slice(maxi(0, logic.choices.size() - CHECKPOINT_INTERVAL))
	for result in logic.card_results.slice(maxi(0, logic.card_results.size() - 2)):
		var name := str(result["entity_id"])
		for entry in logic.entities:
			if str(entry["entity_id"]) == name:
				name = str(entry["name_ko"])
				break
		var branches: Array[String] = []
		for record in recent:
			if str(record["entity_id"]) == str(result["entity_id"]):
				branches.append(logic.category_name(str(record["correct_category_id"])))
		review_lines.append("· %s  /  %s" % [name, " → ".join(branches)])
	var review_record: Dictionary = recent.back()
	for record in recent:
		if not bool(record["correct"]):
			review_record = record
			break
	var review_entity: Dictionary = {}
	for entry in logic.entities:
		if str(entry["entity_id"]) == str(review_record["entity_id"]):
			review_entity = entry
			break
	var review_depth := int(review_record["depth"])
	var review_step: Dictionary = review_entity["steps"][review_depth - 1]
	review_answer_id = str(review_step["correct_category_id"])
	review_left_id = review_answer_id if checkpoints_reached % 2 == 0 else str(review_step["distractor_category_id"])
	review_right_id = str(review_step["distractor_category_id"]) if checkpoints_reached % 2 == 0 else review_answer_id
	campfire_choice_left.text = "A  /  " + str(guide_beat.get("questions", ["길을 묻는다", "기록을 묻는다"])[0])
	campfire_choice_right.text = "D  /  " + str(guide_beat.get("questions", ["길을 묻는다", "기록을 묻는다"])[1])
	campfire_choice_left.disabled = false
	campfire_choice_right.disabled = false
	campfire_choice_left.visible = true
	campfire_choice_right.visible = true
	campfire_continue.disabled = true
	campfire_continue.visible = false
	campfire_review.text = "목소리  /  %s\n\n%s" % [str(guide_beat.get("opening", "나무의 뿌리가 무언가를 기억하고 있다.")), "어떻게 개입할까?" if descent_reached == 12 else "무엇을 물을까?"]
	checkpoint_title.text = "뿌리의 목소리"
	checkpoint_mark.text = "✦   %02d층   /   THE WITNESS" % descent_reached
	_enter_checkpoint_scene()
	_update_campfire_shop()


func _enter_checkpoint_scene() -> void:
	if transition_tween != null:
		transition_tween.kill()
	if DisplayServer.get_name() == "headless":
		game_page.visible = false
		header_shade.visible = false
		campfire_overlay.visible = true
		transition_overlay.visible = false
		transition_active = false
		return
	transition_active = true
	transition_overlay.visible = true
	transition_overlay.color = Color("#02070700")
	transition_tween = create_tween()
	transition_tween.tween_property(transition_overlay, "color:a", 1.0, SCENE_FADE_OUT_SECONDS)
	transition_tween.tween_callback(func():
		game_page.visible = false
		header_shade.visible = false
		campfire_overlay.visible = true
	)
	transition_tween.tween_interval(0.14)
	transition_tween.tween_property(transition_overlay, "color:a", 0.0, SCENE_FADE_IN_SECONDS)
	transition_tween.tween_callback(func():
		transition_overlay.visible = false
		transition_active = false
	)


func _exit_checkpoint_scene() -> void:
	if transition_tween != null:
		transition_tween.kill()
	if DisplayServer.get_name() == "headless":
		campfire_overlay.visible = false
		game_page.visible = true
		header_shade.visible = true
		transition_overlay.visible = false
		transition_active = false
		return
	transition_active = true
	transition_overlay.visible = true
	transition_overlay.color = Color("#02070700")
	transition_tween = create_tween()
	transition_tween.tween_property(transition_overlay, "color:a", 1.0, SCENE_FADE_OUT_SECONDS)
	transition_tween.tween_callback(func():
		campfire_overlay.visible = false
		game_page.visible = true
		header_shade.visible = true
	)
	transition_tween.tween_interval(0.14)
	transition_tween.tween_property(transition_overlay, "color:a", 0.0, SCENE_FADE_IN_SECONDS)
	transition_tween.tween_callback(func():
		transition_overlay.visible = false
		transition_active = false
	)


func _checkpoint_choice(index: int) -> void:
	if not showing_campfire:
		return
	if checkpoint_phase == "question":
		checkpoint_phase = "response"
		if descent_reached == 12:
			story_stance = "intercept" if index == 0 else "trace"
		var questions: Array = guide_beat.get("questions", ["길을 묻는다", "기록을 묻는다"])
		var answers: Array = guide_beat.get("answers", ["길은 계속된다.", "기록은 남는다."])
		campfire_review.text = "당신  /  %s\n\n목소리  /  %s" % [questions[index], answers[index]]
		campfire_choice_left.disabled = true
		campfire_choice_right.disabled = true
		campfire_choice_left.visible = false
		campfire_choice_right.visible = false
		campfire_continue.text = "기억을 판독한다   →"
		campfire_continue.disabled = false
		campfire_continue.visible = true
	elif checkpoint_phase == "review":
		_answer_review(review_left_id if index == 0 else review_right_id)


func _continue_checkpoint() -> void:
	if checkpoint_phase == "response":
		_begin_review()
	elif checkpoint_phase == "shop":
		_leave_campfire()


func _begin_review() -> void:
	checkpoint_phase = "review"
	campfire_choice_left.text = "A  /  " + logic.category_name(review_left_id)
	campfire_choice_right.text = "D  /  " + logic.category_name(review_right_id)
	campfire_choice_left.disabled = false
	campfire_choice_right.disabled = false
	campfire_choice_left.visible = true
	campfire_choice_right.visible = true
	campfire_continue.disabled = true
	campfire_continue.visible = false
	var recent: Dictionary = logic.choices.slice(maxi(0, logic.choices.size() - CHECKPOINT_INTERVAL)).back()
	for choice in logic.choices.slice(maxi(0, logic.choices.size() - CHECKPOINT_INTERVAL)):
		if not bool(choice["correct"]):
			recent = choice
			break
	var found_name := ""
	var clue := ""
	for entity in logic.entities:
		if str(entity["entity_id"]) == str(recent["entity_id"]):
			found_name = str(entity["name_ko"])
			clue = str(entity["quick_clues"][int(recent["depth"]) - 1])
			break
	campfire_review.text = "%d층의 기억  /  지난 단서 하나를 다시 판독하세요.\n\n%s  /  %s" % [descent_reached, found_name, clue]
	campfire_continue.text = "더 깊이 내려가기   →"


func _answer_review(category_id: String) -> void:
	if not showing_campfire or review_answered or checkpoint_phase != "review":
		return
	review_answered = true
	checkpoint_phase = "shop"
	var correct := category_id == review_answer_id
	if correct:
		embers += 1
	campfire_choice_left.disabled = true
	campfire_choice_right.disabled = true
	campfire_choice_left.visible = false
	campfire_choice_right.visible = false
	campfire_continue.disabled = false
	campfire_continue.visible = true
	var judgement := "다시 맞혔습니다  /  불씨 +1" if correct else "다시 살펴볼 갈래  /  " + logic.category_name(review_answer_id)
	campfire_review.text = "%s\n%s\n\n%s" % [judgement, str(guide_beat.get("after_review", "기록은 뿌리에 남았다.")), "\n".join(review_lines)]
	_update_campfire_shop()


func _update_campfire_shop() -> void:
	campfire_wallet.visible = checkpoint_phase == "shop"
	campfire_time_button.visible = checkpoint_phase == "shop"
	campfire_insight_button.visible = checkpoint_phase == "shop"
	campfire_wallet.text = "불씨 %d개   ·   대화 보상 +2초   ·   남은 시간 %.1f초" % [embers, clock_remaining]
	campfire_time_button.disabled = not review_answered or bought_time or embers < SHOP_TIME_COST
	campfire_insight_button.disabled = not review_answered or bought_insight or embers < SHOP_INSIGHT_COST


func _buy_time() -> void:
	if not showing_campfire or not review_answered or bought_time or embers < SHOP_TIME_COST:
		return
	embers -= SHOP_TIME_COST
	bought_time = true
	clock_remaining += SHOP_TIME_SECONDS
	_update_clock()
	_update_campfire_shop()


func _buy_insight() -> void:
	if not showing_campfire or not review_answered or bought_insight or embers < SHOP_INSIGHT_COST:
		return
	embers -= SHOP_INSIGHT_COST
	bought_insight = true
	insight_remaining += 3
	_update_campfire_shop()


func _leave_campfire() -> void:
	if not showing_campfire or not review_answered or checkpoint_phase != "shop":
		return
	showing_campfire = false
	_exit_checkpoint_scene()
	_render()
	if descent_reached == 12:
		brand_subtitle.text = "CLASSIFICATION ARCHIVE  /  INTERVENTION DETECTED"
		feedback_label.text = "권한 밖 개입 기록  /  %s" % ("연결 차단 시도" if story_stance == "intercept" else "미등록 경로 추적")
	_start_clock()


func _is_quick_mode() -> bool:
	return run_mode == "quick"


func _is_timed_mode() -> bool:
	return run_mode == "quick" or run_mode == "descent"


func _start_clock() -> void:
	if _is_quick_mode():
		clock_remaining = QUICK_SECONDS
	clock_running = _is_timed_mode() and not showing_verdict and not showing_result and not logic.is_finished() and intro_overlay == null
	_update_clock()


func _update_clock() -> void:
	if clock_label == null:
		return
	clock_label.text = "%.1f초" % clock_remaining
	clock_label.add_theme_color_override("font_color", Color("#f19b80") if clock_remaining <= 0.6 else GOLD)
	clock_bar.value = clock_remaining


func _update_descent_hud() -> void:
	if run_mode != "descent":
		return
	progress_label.text = "DEPTH  %02d / %02d" % [descent_reached, descent_total]
	score_label.text = "CORRECT  %d" % descent_hits


func _sync_root_trace() -> void:
	path_label.visible = not _is_timed_mode()
	root_trace.visible = _is_timed_mode()
	path_footer_label.text = "● 하늘색 정답\n× 붉은색 오답" if _is_timed_mode() else "맞힐수록 다음 갈래가\n열립니다."
	if _is_timed_mode():
		root_trace.set_marks(root_marks, descent_total)


func _timeout() -> void:
	if not clock_running or logic.is_finished():
		return
	clock_running = false
	combo_count = 0
	combo_popup.clear()
	var before := logic.entity()
	logic.timeout()
	_show_verdict(before)


func _observe() -> void:
	if logic.observe():
		feedback_label.text = "관찰 기록 공개  /  최종 카드 점수 −30%"
		_render()


func _lock() -> void:
	var before := logic.entity()
	if logic.lock():
		_show_verdict(before)


func _skip() -> void:
	combo_count = 0
	combo_popup.clear()
	var before := logic.entity()
	logic.skip()
	_show_verdict(before)


func _show_verdict(previous: Dictionary) -> void:
	clock_running = false
	clock_label.visible = false
	clock_bar.visible = false
	showing_verdict = true
	var result: Dictionary = logic.card_results.back()
	var outcome := str(result["outcome"])
	var headings := {
		"complete": "경로 복원",
		"mixed": "흔적을 품은 경로",
		"lock": "분류 확정",
		"wrong": "질서 불일치",
		"skip": "분류 보류"
		,"timeout": "시간 초과"
	}
	progress_label.text = "SPECIMEN  %02d / %02d" % [logic.current_index, logic.entities.size()]
	score_label.text = "SCORE  %04d" % logic.total_score
	chaos_label.text = "CHAOS  %02d" % logic.chaos
	card_index.text = "CLASSIFICATION RECORD  /  %s" % str(previous["entity_id"]).to_upper()
	depth_label.text = "DEPTH %d / %d" % [result["last_depth"], previous["max_depth"]]
	card_name.text = str(headings.get(outcome, outcome))
	card_subtitle.text = "%s    ·    %s" % [previous["name_ko"], previous["scientific_name"]]
	prompt_label.text = "이 선택이 세계의 분류 기록에 남았습니다."
	left_button.text = "+%d점" % result["score_gained"]
	left_button.disabled = true
	right_button.text = "결과 보기  →" if logic.is_finished() else "다음 개체  →"
	right_button.disabled = false
	left_explanation.text = "이번 카드"
	right_explanation.text = "계속 진행"
	observe_button.disabled = true
	lock_button.disabled = true
	skip_button.disabled = true
	var known: Array[String] = ["THE ROOT"]
	for i in range(mini(int(result["last_depth"]), previous["path"].size())):
		known.append(logic.category_name(str(previous["path"][i])))
	path_label.text = "\n│\n".join(known)
	_sync_root_trace()
	hint_state.text = "판정  /  " + _outcome_name(outcome)
	if outcome == "wrong":
		var last_choice: Dictionary = logic.choices.back()
		hint_label.text = "선택한 갈래: %s\n\n정답 갈래: %s\n\n%s" % [
			logic.category_name(str(last_choice["chosen"])),
			logic.category_name(str(last_choice["correct_category_id"])),
			logic.category_explanation(str(last_choice["correct_category_id"]))
		]
	elif outcome == "timeout":
		hint_label.text = "2초 안에 갈래를 정하지 못했습니다.\n\n이번 단계의 정답: %s" % logic.category_name(str(previous["steps"][int(result["last_depth"]) - 1]["correct_category_id"]))
	elif outcome == "mixed":
		hint_label.text = "오답 %d개가 뿌리에 흔적으로 남았습니다.\n\n그래도 이 표본의 마지막 갈래까지 내려갔습니다." % int(result["mistakes"])
	elif outcome == "skip":
		hint_label.text = "아직 이 개체의 자리를 정하지 않았습니다."
	else:
		hint_label.text = "현재 깊이의 분류가 기록되었습니다."
	bank_label.text = "획득 점수  %d\n누적 CHAOS  %d" % [result["score_gained"], logic.chaos]
	feedback_label.text = "잠시 후 다음 기록으로 넘어갑니다." if _is_quick_mode() else "다음 기록으로 진행하려면 오른쪽 버튼을 누르세요."
	if _is_quick_mode():
		quick_verdict_token += 1
		_auto_advance_quick_verdict(quick_verdict_token)


func _auto_advance_quick_verdict(token: int) -> void:
	await get_tree().create_timer(QUICK_VERDICT_SECONDS).timeout
	if not is_inside_tree() or token != quick_verdict_token or not showing_verdict:
		return
	showing_verdict = false
	_render()
	_start_clock()


func _show_result() -> void:
	clock_running = false
	clock_label.visible = false
	clock_bar.visible = false
	showing_result = true
	if run_mode == "descent":
		_show_descent_result()
		return
	card_index.text = "ARCHIVE COMPLETE"
	depth_label.text = "%02d / %02d" % [logic.entities.size(), logic.entities.size()]
	card_name.text = "첫 분류 완료"
	card_subtitle.text = "SCORE %d    /    CHAOS %d" % [logic.total_score, logic.chaos]
	var lines: Array[String] = []
	for result in logic.card_results:
		var name := str(result["entity_id"])
		for entry in logic.entities:
			if entry["entity_id"] == result["entity_id"]:
				name = str(entry["name_ko"])
				break
		lines.append("%s  ·  %s" % [name, _outcome_name(str(result["outcome"]))])
	prompt_label.text = "분류 결과가 기록되었습니다."
	left_button.text = "THE ROOT"
	left_button.disabled = true
	right_button.text = "다시 도전하기  →"
	right_button.disabled = false
	left_explanation.text = ""
	right_explanation.text = ""
	observe_button.disabled = true
	lock_button.disabled = true
	skip_button.disabled = true
	path_label.text = "\n".join(lines)
	_sync_root_trace()
	hint_state.text = "기록 저장"
	var saved := logic.save_log()
	hint_label.text = "플레이 로그가 저장됐습니다." if not saved.is_empty() else "플레이 로그 저장 실패"
	bank_label.text = "선택·점수 기록 완료" if not saved.is_empty() else "기록을 확인하세요"
	feedback_label.text = "다시 도전하기를 눌러 새 분류를 시작하세요."


func _show_descent_result() -> void:
	if descent_reached >= descent_total and not reward_granted_run:
		reward_granted_run = true
		awarded_specimen = collection.award(_collectible_entities(), logic.choices)
	if awarded_specimen != "":
		specimen_texture.texture = load("res://assets/specimen-%s.svg" % awarded_specimen)
		habitat_response.reveal(awarded_specimen, 3, _specimen_name(awarded_specimen))
	combo_popup.clear()
	progress_label.text = "DEPTH  %02d / %02d" % [descent_reached, descent_total]
	score_label.text = "CORRECT  %d" % descent_hits
	chaos_label.text = "CHAOS  %02d" % logic.chaos
	card_index.text = "DESCENT RECORD  /  WITNESS RUN"
	depth_label.text = "%02d / %02d" % [descent_reached, descent_total]
	card_name.text = "세계의 봉인 해제" if descent_reached >= descent_total else "도달 깊이  %d층" % descent_reached
	card_subtitle.text = "정확 %d개    ·    최고 콤보 %d    ·    남은 시간 %.1f초" % [descent_hits, max_combo, clock_remaining]
	prompt_label.text = "완주 보상  /  %s 봉인 표본 획득" % _specimen_name(awarded_specimen) if awarded_specimen != "" else ("모든 봉인 표본을 복원했습니다." if descent_reached >= descent_total else "제한 시간 동안 세계에 새긴 분류입니다.")
	left_button.text = "봉인 표본 도감  /  %d·%d" % [collection.owned.size(), _collectible_entities().size()]
	left_button.disabled = false
	right_button.text = "다시 내려가기  →"
	right_button.disabled = false
	left_explanation.text = "완주하면 새 표본 하나를 복원합니다"
	right_explanation.text = "새 도전"
	var records: Array[String] = []
	for choice in logic.choices:
		if bool(choice["correct"]):
			records.append("%s  ·  %d층" % [logic.category_name(str(choice["chosen"])), int(choice["depth"])])
	for result in logic.card_results:
		if str(result["outcome"]) == "wrong":
			records.append("◇  분기 붕괴")
	path_label.text = "\n│\n".join(records) if not records.is_empty() else "도달한 갈래 없음"
	_sync_root_trace()
	hint_state.text = "마지막 속삭임" if descent_reached >= descent_total else ("시간 종료" if clock_remaining <= 0.0 else "탐사 완료")
	var saved := logic.save_log("descent", {"depth_reached": descent_reached, "correct_choices": descent_hits, "max_depth": descent_total, "best_branch_depth": descent_best, "max_combo": max_combo, "checkpoints_reached": checkpoints_reached, "embers_remaining": embers, "remaining_seconds": clock_remaining, "intervention": story_stance})
	var ending_key := "ending_" + story_stance if story_stance != "" else "ending"
	hint_label.text = str(guide_dialogue.get(str(descent_total), {}).get(ending_key, "나무가 조용히 흔들렸다.")) if descent_reached >= descent_total else "%d층을 내려갔습니다.\n\n맞힌 갈래 %d개 · 최고 콤보 %d" % [descent_reached, descent_hits, max_combo]
	bank_label.text = ("개입 기록  /  " + ("연결 차단" if story_stance == "intercept" else "빛 추적")) if descent_reached >= descent_total else ("기록 저장 완료" if not saved.is_empty() else "기록 저장 실패")
	feedback_label.text = "도감을 열거나 다시 내려가세요."


func _specimen_name(specimen_id: String) -> String:
	for entity in logic.entities:
		if str(entity["entity_id"]) == specimen_id:
			return str(entity["name_ko"])
	return specimen_id


func _collectible_entities() -> Array:
	var eligible: Array = []
	for entity in logic.entities:
		if bool(entity.get("collectible", false)):
			eligible.append(entity)
	return eligible


func _outcome_name(outcome: String) -> String:
	match outcome:
		"complete": return "완주"
		"mixed": return "오답을 안고 완주"
		"lock": return "확정"
		"wrong": return "오답"
		"skip": return "건너뜀"
		"timeout": return "시간 초과"
	return outcome


func _show_intro() -> void:
	intro_overlay = ColorRect.new()
	intro_overlay.color = Color("#06121066")
	game_page.visible = false
	header_shade.visible = false
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(intro_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.add_child(center)
	var column := _column(20)
	column.custom_minimum_size.x = 640
	center.add_child(column)
	var eyebrow := _label("FROM CHAOS, PATTERNS EMERGE  /  FIELD TEST 04", 13, GOLD)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)
	column.add_child(_rule(GOLD, 1))
	var title := _label("THE ROOT", 71, WHITE, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := _label("새 관찰자 접속. 당신에게 분류 권한이 주어졌습니다.", 20, WHITE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var section := _label("한 갈래에 2초, 또는 뿌리의 목소리를 따라 더 깊이", 15, GOLD)
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(section)
	var start := _choice_button()
	start.text = "2초 분류   /   미지의 생물   →"
	start.custom_minimum_size = Vector2(280, 58)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(func(): _start_mode("res://data/fantasy.json", "TWO SECOND CLASSIFICATION", "quick"))
	column.add_child(start)
	var descent := _choice_button()
	descent.text = "뿌리 원정   /   어디까지 내려갈까   →"
	descent.custom_minimum_size = Vector2(390, 58)
	descent.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	descent.pressed.connect(func(): _start_mode("res://data/descent.json", "WITNESS DESCENT", "descent"))
	column.add_child(descent)
	var practice := _action_button("현실 개체 연습   /   고양이 · 물 · 오리너구리")
	practice.custom_minimum_size = Vector2(390, 43)
	practice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	practice.pressed.connect(func(): _start_mode("res://data/prototype.json", "REAL WORLD", "real"))
	column.add_child(practice)
	var collection_button := _action_button("봉인 표본 도감   /   수집 현황")
	collection_button.custom_minimum_size = Vector2(390, 43)
	collection_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	collection_button.pressed.connect(_show_collection)
	column.add_child(collection_button)
	intro_error_label = _label("", 13, Color("#f19b80"))
	intro_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_error_label.visible = false
	column.add_child(intro_error_label)


func _start_mode(data_path: String, label: String, selected_mode: String) -> void:
	if not logic.load_data(data_path):
		intro_error_label.text = "분류 기록을 열지 못했습니다: %s" % data_path
		intro_error_label.visible = true
		return
	run_mode = selected_mode
	logic.continue_on_wrong = _is_timed_mode()
	logic.start()
	root_marks.clear()
	combo_count = 0
	combo_popup.clear()
	habitat_response.reset()
	max_combo = 0
	story_stance = ""
	reward_granted_run = false
	awarded_specimen = ""
	descent_hits = 0
	descent_reached = 0
	descent_best = 0
	embers = 0
	insight_remaining = 0
	checkpoints_reached = 0
	showing_campfire = false
	campfire_overlay.visible = false
	quick_verdict_token += 1
	descent_total = 0
	for entry in logic.entities:
		descent_total += int(entry["steps"].size())
	clock_remaining = DESCENT_SECONDS if run_mode == "descent" else QUICK_SECONDS
	clock_bar.max_value = DESCENT_SECONDS if run_mode == "descent" else QUICK_SECONDS
	brand_subtitle.text = "CLASSIFICATION ARCHIVE  /  %s" % label
	showing_verdict = false
	showing_result = false
	_render()
	intro_overlay.queue_free()
	intro_overlay = null
	game_page.visible = true
	header_shade.visible = true
	_start_clock()


func _restart_run() -> void:
	logic.start()
	root_marks.clear()
	combo_count = 0
	combo_popup.clear()
	habitat_response.reset()
	max_combo = 0
	reward_granted_run = false
	awarded_specimen = ""
	descent_hits = 0
	descent_reached = 0
	descent_best = 0
	embers = 0
	insight_remaining = 0
	checkpoints_reached = 0
	showing_campfire = false
	campfire_overlay.visible = false
	quick_verdict_token += 1
	clock_remaining = DESCENT_SECONDS if run_mode == "descent" else QUICK_SECONDS
	showing_result = false
	feedback_label.text = "새 도전을 시작했습니다."
	story_stance = ""
	_render()
	_start_clock()


func _choice_column(parent: HBoxContainer, caption: String) -> VBoxContainer:
	var column := _column(7)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var upper_space := Control.new()
	upper_space.custom_minimum_size.y = 41
	column.add_child(upper_space)
	column.add_child(_label(caption, 11, SOFT))
	return column


func _choice_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = 59
	button.add_theme_font_override("font", body_font)
	button.add_theme_font_size_override("font_size", 18)
	_set_button_palette(button, Color("#10231f"), INK, GOLD, Color("#071715"), Color("#26342f"), Color("#d9e2d8"))
	return button


func _action_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 41
	button.add_theme_font_override("font", body_font)
	button.add_theme_font_size_override("font_size", 14)
	_set_button_palette(button, Color("#142820"), INK, Color("#d7b985"), Color("#071715"), Color("#27332f"), Color("#d6ddd5"))
	return button


func _set_button_palette(button: Button, normal_bg: Color, normal_text: Color, active_bg: Color, active_text: Color, disabled_bg: Color, disabled_text: Color) -> void:
	button.add_theme_color_override("font_color", normal_text)
	button.add_theme_color_override("font_hover_color", active_text)
	button.add_theme_color_override("font_pressed_color", active_text)
	button.add_theme_color_override("font_hover_pressed_color", active_text)
	button.add_theme_color_override("font_focus_color", normal_text)
	button.add_theme_color_override("font_disabled_color", disabled_text)
	button.add_theme_stylebox_override("normal", _style(normal_bg, GOLD, 1))
	button.add_theme_stylebox_override("hover", _style(active_bg, GOLD, 1))
	button.add_theme_stylebox_override("pressed", _style(active_bg, GOLD, 1))
	button.add_theme_stylebox_override("hover_pressed", _style(active_bg, GOLD, 1))
	button.add_theme_stylebox_override("disabled", _style(disabled_bg, LINE, 1))
	var focus_style := _style(Color.TRANSPARENT, GOLD, 2)
	focus_style.draw_center = false
	button.add_theme_stylebox_override("focus", focus_style)


func _label(value: String, size: int, color: Color, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", title_font if serif else body_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _rule(color: Color, height: int) -> ColorRect:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size.y = height
	return rule


func _column(separation: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	return column


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _panel(fill: Color, stroke: Color, border: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(fill, stroke, border))
	return panel


func _style(fill: Color, stroke: Color, border: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = stroke
	style.set_border_width_all(border)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style
