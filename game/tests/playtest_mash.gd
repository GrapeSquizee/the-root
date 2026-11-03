extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	main.intro_overlay.get_child(0).get_child(0).get_child(6).pressed.emit()
	while not main.showing_result:
		main._choose(main.choice_left)
		if main.showing_campfire:
			main._checkpoint_choice(0)
			main._continue_checkpoint()
			main._answer_review(main.review_answer_id)
			main._leave_campfire()
	print("MASH: floor=", main.descent_reached, " correct=", main.descent_hits, " time=", main.clock_remaining, " chaos=", main.logic.chaos, " embers=", main.embers)
	quit(0)
