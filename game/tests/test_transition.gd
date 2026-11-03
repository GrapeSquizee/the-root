extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.intro_overlay.get_child(0).get_child(0).get_child(6).pressed.emit()
	for category in ["living", "hunter", "living", "live_bearing", "non_living", "matter"]:
		main._choose(category)
	assert(main.showing_campfire)
	assert(main.transition_active)
	var paused_time: float = main.clock_remaining
	main._process(1.0)
	assert(is_equal_approx(main.clock_remaining, paused_time))
	await create_timer(1.55).timeout
	assert(main.campfire_overlay.visible)
	assert(not main.game_page.visible)
	assert(not main.transition_active)
	main._checkpoint_choice(0)
	main._continue_checkpoint()
	main._answer_review(main.review_answer_id)
	main._leave_campfire()
	assert(main.transition_active)
	main._process(1.0)
	assert(is_equal_approx(main.clock_remaining, paused_time))
	await create_timer(1.55).timeout
	assert(main.game_page.visible)
	assert(not main.campfire_overlay.visible)
	assert(not main.transition_active)
	print("PASS: fade to separate guide scene and back, timer paused")
	quit(0)
