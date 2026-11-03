extends SceneTree

const HabitatResponse = preload("res://scripts/habitat_response.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var habitat = HabitatResponse.new()
	habitat.size = Vector2(680, 72)
	root.add_child(habitat)
	habitat.reveal("moss_hart", 1, "서리뿔")
	habitat.reveal("moss_hart", 3, "서리뿔")
	habitat.reveal("ember_moth", 2, "재나방")
	assert(habitat.residents.size() == 2)
	assert(habitat.residents[0]["stage"] == 3)
	habitat._process(40.0)
	assert(habitat.absorbed_count() == 2)
	assert(habitat.residents[0]["flash"] > 0.0)
	habitat.reveal("glass_fox", 1, "유리여우")
	assert(habitat.residents.size() == 3)
	assert(habitat.absorbed_count() == 2)
	habitat.reset()
	assert(habitat.residents.is_empty())
	print("PASS: habitat arrival, absorption, retention, reset")
	quit(0)
