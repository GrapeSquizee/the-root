extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_save("ui-preview-title.png")
	main.intro_overlay.get_child(0).get_child(0).get_child(5).pressed.emit()
	await process_frame
	_save("ui-preview-fantasy.png")
	main._choose("living")
	main._choose("light_feeder")
	await process_frame
	_save("ui-preview-fantasy-d3.png")
	main._skip()
	main.right_button.pressed.emit()
	await process_frame
	_save("ui-preview-ember-moth.png")
	main._skip()
	main.right_button.pressed.emit()
	await process_frame
	_save("ui-preview-glass-fox.png")
	main._skip()
	await process_frame
	_save("ui-preview-verdict.png")
	main.right_button.pressed.emit()
	await process_frame
	_save("ui-preview-result.png")
	quit(0)


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	var result := image.save_png("res://../research/shared-plan/" + name)
	print("capture:", name, " ", result, " size:", image.get_size())
