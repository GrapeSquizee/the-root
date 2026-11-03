extends RefCounted

const DEFAULT_PATH := "user://specimen_collection.json"

var save_path := DEFAULT_PATH
var owned: Array[String] = []


func load_collection() -> void:
	owned.clear()
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary and data.get("specimens") is Array:
		for value in data["specimens"]:
			var specimen_id := str(value)
			if not owned.has(specimen_id):
				owned.append(specimen_id)


func award(entities: Array, choices: Array) -> String:
	var best_id := ""
	var best_hits := -1
	for entity in entities:
		var specimen_id := str(entity["entity_id"])
		if owned.has(specimen_id):
			continue
		var hits := 0
		for choice in choices:
			if str(choice["entity_id"]) == specimen_id and bool(choice["correct"]):
				hits += 1
		if hits > best_hits:
			best_id = specimen_id
			best_hits = hits
	if best_id == "":
		return ""
	owned.append(best_id)
	if not save_collection():
		owned.erase(best_id)
		return ""
	return best_id


func save_collection() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "specimens": owned}, "  "))
	return true
