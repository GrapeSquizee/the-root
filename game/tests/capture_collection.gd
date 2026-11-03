extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main._show_collection()
	await process_frame
	_save("ui-preview-collection-locked.png")
	main._close_collection()
	main.intro_overlay.get_child(0).get_child(0).get_child(6).pressed.emit()
	await process_frame
	await process_frame
	_save("ui-preview-familiar-opening.png")
	while not main.showing_result:
		if main.showing_campfire:
			await create_timer(1.55).timeout
			_save("ui-preview-witness-%02d.png" % main.descent_reached)
			main._checkpoint_choice(0)
			await process_frame
			_save("ui-preview-witness-answer-%02d.png" % main.descent_reached)
			main._continue_checkpoint()
			main._answer_review(main.review_answer_id)
			main._leave_campfire()
			await create_timer(1.55).timeout
		else:
			var previous_index: int = main.logic.current_index
			main._choose(str(main.logic.step()["correct_category_id"]))
			if main.logic.current_index > previous_index:
				main.habitat_response._process(2.0)
	await process_frame
	await process_frame
	_save("ui-preview-completion-reward.png")
	main.habitat_response._process(3.0)
	main.habitat_response._process(0.35)
	await process_frame
	_save("ui-preview-tree-absorption.png")
	main._show_collection()
	await process_frame
	_save("ui-preview-collection-earned.png")
	quit(0)


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	print("capture:", name, " ", image.save_png("res://../research/shared-plan/" + name))
