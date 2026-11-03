extends SceneTree

const Collection = preload("res://scripts/collection.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := "user://test_specimen_collection.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var ledger = Collection.new()
	ledger.save_path = path
	ledger.load_collection()
	var entries: Array = [{"entity_id": "moss_hart"}, {"entity_id": "ember_moth"}, {"entity_id": "glass_fox"}]
	var choices: Array = [{"entity_id": "ember_moth", "correct": true}, {"entity_id": "ember_moth", "correct": true}, {"entity_id": "moss_hart", "correct": true}]
	assert(ledger.award(entries, choices) == "ember_moth")
	var reloaded = Collection.new()
	reloaded.save_path = path
	reloaded.load_collection()
	assert(reloaded.owned == ["ember_moth"])
	assert(reloaded.award(entries, choices) == "moss_hart")
	assert(reloaded.award(entries, choices) == "glass_fox")
	assert(reloaded.award(entries, choices) == "")
	assert(reloaded.owned.size() == 3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PASS: collection award, persistence, no duplicates")
	quit(0)
