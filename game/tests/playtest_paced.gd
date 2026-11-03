extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var quick = scene.instantiate()
	root.add_child(quick)
	await process_frame
	await process_frame
	quick.intro_overlay.get_child(0).get_child(0).get_child(5).pressed.emit()
	await create_timer(1.15).timeout
	_press_category(quick, "living")
	await create_timer(1.15).timeout
	_press_category(quick, "light_feeder")
	await create_timer(2.15).timeout
	print("QUICK: reached=", quick.root_marks.size(), " timeout=", quick.logic.card_results[0]["outcome"], " combo=", quick.combo_count)
	_save("playtest-quick-timeout.png")
	quick.queue_free()
	await process_frame
	var descent = scene.instantiate()
	root.add_child(descent)
	await process_frame
	await process_frame
	descent.intro_overlay.get_child(0).get_child(0).get_child(6).pressed.emit()
	for floor in range(descent.descent_total):
		await create_timer(1.15).timeout
		if descent.showing_result:
			break
		var target := str(descent.logic.step()["correct_category_id"])
		if floor == 4:
			target = str(descent.logic.step()["distractor_category_id"])
		_press_category(descent, target)
		if descent.showing_campfire:
			print("CAMPFIRE: floor=", descent.descent_reached, " remaining=", descent.clock_remaining, " embers=", descent.embers)
			await create_timer(2.0).timeout
			_save("playtest-campfire-%02d.png" % descent.descent_reached)
			descent._checkpoint_choice(0)
			descent._continue_checkpoint()
			descent._answer_review(descent.review_answer_id)
			if descent.embers >= 4:
				descent.campfire_time_button.pressed.emit()
			if descent.embers >= 3:
				descent.campfire_insight_button.pressed.emit()
			descent._leave_campfire()
			await create_timer(1.55).timeout
	print("DESCENT: reached=", descent.descent_reached, " correct=", descent.descent_hits, " time=", descent.clock_remaining, " checkpoint=", descent.checkpoints_reached, " result=", descent.showing_result)
	_save("playtest-descent-result.png")
	quit(0)


func _press_category(main: Control, category_id: String) -> void:
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_A if main.choice_left == category_id else KEY_D
	main._input(key)


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	var result := image.save_png("res://../research/shared-plan/" + name)
	print("snapshot=", name, " result=", result)
