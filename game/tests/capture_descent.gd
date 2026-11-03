extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame
	_save("ui-preview-title-modes.png")
	main.intro_overlay.get_child(0).get_child(0).get_child(6).pressed.emit()
	for category in ["living", "hunter", "living", "live_bearing", "non_living", "matter"]:
		main._choose(category)
	await create_timer(1.55).timeout
	_save("ui-preview-campfire.png")
	main._checkpoint_choice(0)
	main._continue_checkpoint()
	main._answer_review(main.review_answer_id)
	main._buy_time()
	main._leave_campfire()
	await create_timer(1.55).timeout
	for category in ["living", "light_feeder", "spore_bearing"]:
		main._choose(category)
	await process_frame
	_save("ui-preview-deep-specimen.png")
	main._process(40.0)
	await process_frame
	_save("ui-preview-campfire-result.png")
	quit(0)


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	var result := image.save_png("res://../research/shared-plan/" + name)
	print("capture:", name, " ", result, " size:", image.get_size())
