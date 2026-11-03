extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	for pair in [[5, "quick"], [6, "descent"], [7, "real"]]:
		var main = scene.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		var button: Button = main.intro_overlay.get_child(0).get_child(0).get_child(pair[0])
		var point := button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		Input.parse_input_event(motion)
		await process_frame
		assert(root.gui_get_hovered_control() == button)
		var press := InputEventMouseButton.new()
		press.position = point
		press.global_position = point
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var release := InputEventMouseButton.new()
		release.position = point
		release.global_position = point
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		Input.parse_input_event(release)
		await process_frame
		print("clicked=", pair[1], " actual=", main.run_mode)
		assert(main.intro_overlay == null)
		assert(main.run_mode == pair[1])
		main.queue_free()
		await process_frame
	quit(0)
