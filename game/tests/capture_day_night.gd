extends SceneTree
## 낮·저녁·밤·새벽 화면을 캡처한다(창 모드로 실행).
## Godot_v4.7.2-stable_win64_console.exe --path game --script res://tests/capture_day_night.gd -- <출력 폴더>


var out_dir := "user://"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	call_deferred("_capture")


func _capture() -> void:
	var view = load("res://daynight/day_night.tscn").instantiate()
	root.add_child(view)
	await _frames(3)
	_save("dn-title.png")
	view.logic.start_game()
	view.logic.choose(int(view.logic.step()[2]))
	await _frames(3)
	_save("dn-day.png")
	while view.logic.phase == "day":
		var s: Array = view.logic.step()
		# 몇 장은 일부러 틀려 붉은 줄을 남긴다.
		var wrong: bool = view.logic.card_index % 3 == 1 and view.logic.step_index == 1
		view.logic.choose(1 - int(s[2]) if wrong else int(s[2]))
	view.logic.toggle_yellow("edge_w", "elder")
	await _frames(3)
	_save("dn-evening.png")
	view.logic.start_night()
	for i in 330:
		view.logic.update_night(1.0 / 30.0)
	await _frames(3)
	_save("dn-night.png")
	view.logic.start_dawn()
	await _frames(3)
	_save("dn-dawn.png")
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _save(file: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png(out_dir.path_join(file))
