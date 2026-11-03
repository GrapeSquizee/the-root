extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.intro_overlay.get_child(0).get_child(0).get_child(6).pressed.emit()
	main._choose("living")
	main._choose("light_feeder")
	await process_frame
	await process_frame
	await process_frame
	print("combo dip y=", main.combo_popup.banner.position.y)
	var image := root.get_texture().get_image()
	var result := image.save_png("res://../research/shared-plan/ui-preview-combo.png")
	print("capture combo: ", result, " count: ", main.combo_count, " visible: ", main.combo_popup.visible)
	await create_timer(0.35).timeout
	assert(absf(main.combo_popup.banner.position.y) < 1.0, "combo should return to its resting position")
	quit(0)
