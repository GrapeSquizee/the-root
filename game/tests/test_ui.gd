extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	assert(main.intro_overlay != null)
	main.intro_overlay.get_child(0).get_child(0).get_child(7).pressed.emit()
	assert(main.intro_overlay == null)
	for button in [main.left_button, main.right_button, main.observe_button, main.lock_button, main.skip_button]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var background: StyleBoxFlat = button.get_theme_stylebox(state)
			var text_state := "font_color" if state == "normal" else "font_%s_color" % state
			var foreground: Color = button.get_theme_color(text_state)
			assert(_contrast(background.bg_color, foreground) >= 4.5, "Button contrast: " + state)
	assert(main.card_name.text == "고양이")
	assert(main.left_button.text != main.right_button.text)
	assert("실제로 존재" in main.left_explanation.text or "실제로 존재" in main.right_explanation.text)
	main._observe()
	assert("털" in main.hint_label.text)
	main._choose("physical")
	assert("DEPTH 2" in main.depth_label.text)
	assert("세포" in main.left_explanation.text or "세포" in main.right_explanation.text)
	main._lock()
	assert(main.card_name.text == "분류 확정")
	var blocked_index: int = main.logic.current_index
	var arrow := InputEventKey.new()
	arrow.pressed = true
	arrow.keycode = KEY_LEFT
	main._input(arrow)
	assert(main.logic.current_index == blocked_index)
	main.right_button.pressed.emit()
	assert(main.card_name.text == "물")
	main._skip()
	assert(main.card_name.text == "분류 보류")
	main.right_button.pressed.emit()
	assert(main.card_name.text == "오리너구리")
	main._skip()
	assert(main.card_name.text == "분류 보류")
	main.right_button.pressed.emit()
	assert(main.card_name.text == "첫 분류 완료")
	assert("다시 도전하기" in main.right_button.text)
	main.right_button.pressed.emit()
	assert(main.card_name.text == "고양이")
	var fantasy = scene.instantiate()
	root.add_child(fantasy)
	fantasy.intro_overlay.get_child(0).get_child(0).get_child(5).pressed.emit()
	assert(fantasy.logic.mode_id == "fantasy")
	assert(fantasy.card_name.text == "서리뿔")
	assert("다시 자란다" in fantasy.hint_label.text)
	assert(fantasy.clock_running)
	assert(is_equal_approx(fantasy.clock_remaining, 2.0))
	assert(not fantasy.observe_button.visible)
	var left_key := InputEventKey.new()
	left_key.pressed = true
	left_key.keycode = KEY_A
	var right_key := InputEventKey.new()
	right_key.pressed = true
	right_key.keycode = KEY_D
	if fantasy.choice_left == "living":
		fantasy._input(left_key)
	else:
		fantasy._input(right_key)
	assert(fantasy.logic.depth == 2)
	assert(fantasy.combo_count == 1)
	assert(fantasy.combo_popup.visible)
	assert(fantasy.habitat_response.species == "moss_hart")
	assert(fantasy.habitat_response.stage == 1)
	assert("달빛" in fantasy.hint_label.text)
	assert(is_equal_approx(fantasy.clock_remaining, 2.0))
	var arrow_right := InputEventKey.new()
	arrow_right.pressed = true
	arrow_right.keycode = KEY_RIGHT
	var arrow_left := InputEventKey.new()
	arrow_left.pressed = true
	arrow_left.keycode = KEY_LEFT
	if fantasy.choice_left == "light_feeder":
		fantasy._input(arrow_left)
	else:
		fantasy._input(arrow_right)
	assert(fantasy.logic.depth == 3)
	assert(fantasy.combo_count == 2)
	assert(fantasy.habitat_response.stage == 2)
	fantasy._process(2.1)
	assert(fantasy.showing_verdict)
	assert(fantasy.logic.card_results[0]["outcome"] == "timeout")
	assert(fantasy.logic.chaos == 5)
	assert(not fantasy.clock_running)
	await create_timer(0.75).timeout
	assert(fantasy.card_name.text == "재나방", "quick verdict should advance automatically")
	var descent = scene.instantiate()
	root.add_child(descent)
	descent.intro_overlay.get_child(0).get_child(0).get_child(6).pressed.emit()
	assert(descent.run_mode == "descent")
	assert(descent.logic.mode_id == "descent")
	assert(descent.descent_total == 27)
	assert(descent.card_name.text == "강아지")
	assert(is_equal_approx(descent.clock_remaining, 22.5))
	descent._process(1.0)
	assert(is_equal_approx(descent.clock_remaining, 21.5))
	descent._choose("living")
	assert(descent.descent_hits == 1)
	assert(descent.combo_count == 1)
	assert(descent.descent_reached == 1)
	assert(descent.root_marks.size() == 1)
	assert(descent.root_trace.visible)
	assert(descent.descent_best == 1)
	assert(is_equal_approx(descent.clock_remaining, 21.5), "descent timer must not reset per choice")
	descent._choose("light_feeder")
	assert(descent.logic.current_index == 1, "final wrong branch should advance to the next specimen")
	assert(descent.logic.depth == 1)
	assert(descent.descent_reached == 2)
	assert(descent.descent_hits == 1)
	assert(descent.combo_count == 0)
	assert(not descent.combo_popup.visible)
	assert(not descent.root_marks[1]["correct"])
	assert(not descent.showing_verdict)
	assert(is_equal_approx(descent.clock_remaining, 18.5), "wrong choice must cost time")
	descent._process(20.0)
	assert(descent.showing_result)
	assert("도달 깊이  2층" in descent.card_name.text)
	assert(not descent.clock_running)
	descent.right_button.pressed.emit()
	assert(descent.descent_hits == 0)
	assert(descent.descent_reached == 0)
	assert(descent.habitat_response.residents.is_empty())
	assert(descent.root_marks.is_empty())
	assert(is_equal_approx(descent.clock_remaining, 22.5))
	for specimen in range(descent.logic.entities.size()):
		var current: Dictionary = descent.logic.entity()
		for question in current["steps"]:
			descent._choose(str(question["correct_category_id"]))
			if descent.showing_campfire:
				assert(descent.descent_reached in [6, 12, 18])
				assert(not descent.clock_running)
				var rested: float = descent.clock_remaining
				descent._process(5.0)
				assert(is_equal_approx(descent.clock_remaining, rested))
				assert(descent.embers >= 4)
				assert("목소리" in descent.campfire_review.text)
				assert(descent.checkpoint_phase == "question")
				if descent.descent_reached == 12:
					assert("틀린 이름 하나 없이" in descent.campfire_review.text)
				descent._checkpoint_choice(0)
				assert(descent.checkpoint_phase == "response")
				assert("당신" in descent.campfire_review.text)
				descent._continue_checkpoint()
				assert(descent.checkpoint_phase == "review")
				assert("지난 단서" in descent.campfire_review.text)
				assert(descent.campfire_continue.disabled)
				assert(descent.campfire_time_button.disabled)
				descent._answer_review(descent.review_answer_id)
				assert(descent.review_answered)
				assert(not descent.campfire_continue.disabled)
				descent._buy_time()
				assert(is_equal_approx(descent.clock_remaining, rested + 3.0))
				if descent.descent_reached == 6:
					descent._buy_insight()
					assert(descent.insight_remaining == 3)
				descent._leave_campfire()
				assert(descent.clock_running)
				if descent.descent_reached == 6:
					assert("✦" in descent.left_button.text or "✦" in descent.right_button.text)
	assert(descent.showing_result)
	assert(descent.descent_hits == 27)
	assert(descent.descent_reached == 27)
	assert(descent.habitat_response.residents.size() == 10)
	assert(descent.habitat_response.residents[0]["id"] == "dog")
	assert(descent.habitat_response.residents[9]["id"] == "time_snail")
	assert(descent.descent_best == 3)
	assert(descent.max_combo == 27)
	assert(descent.checkpoints_reached == 3)
	assert(descent.card_name.text == "세계의 봉인 해제")
	assert(descent.reward_granted_run)
	assert(descent.story_stance == "intercept")
	assert("두 번째 나무" in descent.hint_label.text)
	assert(not descent.left_button.disabled)
	descent._restart_run()
	while not descent.showing_result:
		if descent.showing_campfire:
			descent._checkpoint_choice(1)
			descent._continue_checkpoint()
			descent._answer_review(descent.review_answer_id)
			descent._leave_campfire()
		else:
			descent._choose(str(descent.logic.step()["correct_category_id"]))
	assert(descent.story_stance == "trace")
	assert("이름 없는 빈 공간" in descent.hint_label.text)
	print("PASS: scene, choices, observe, lock, skip, results, restart")
	quit(0)


func _contrast(a: Color, b: Color) -> float:
	var first := _luminance(a)
	var second := _luminance(b)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)


func _luminance(color: Color) -> float:
	return 0.2126 * _linear(color.r) + 0.7152 * _linear(color.g) + 0.0722 * _linear(color.b)


func _linear(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)
