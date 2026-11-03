extends RefCounted

const DATA_PATH := "res://data/prototype.json"

var entities: Array[Dictionary] = []
var category_names: Dictionary = {}
var plain_explanations: Dictionary = {}
var current_index := 0
var depth := 0
var card_points := 0
var total_score := 0
var chaos := 0
var streak := 0
var observed := false
var card_started_ms := 0
var choices: Array[Dictionary] = []
var card_results: Array[Dictionary] = []
var card_actions: Array[Dictionary] = []
var mode_id := "real"
var active_hint := ""
var continue_on_wrong := false
var card_mistakes := 0


func load_data(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return false
	entities.clear()
	mode_id = str(parsed.get("mode_id", "real"))
	category_names = parsed.get("categories", {})
	plain_explanations = parsed.get("plain_explanations", {})
	for entry in parsed.get("entities", []):
		if entry is Dictionary:
			entities.append(entry)
	return entities.size() > 0 and category_names.size() > 0


func start() -> void:
	current_index = 0
	total_score = 0
	chaos = 0
	streak = 0
	choices.clear()
	card_results.clear()
	card_actions.clear()
	_begin_card()


func is_finished() -> bool:
	return current_index >= entities.size()


func entity() -> Dictionary:
	if is_finished():
		return {}
	return entities[current_index]


func step() -> Dictionary:
	return entity().get("steps", [])[depth - 1]


func category_name(category_id: String) -> String:
	return str(category_names.get(category_id, category_id))


func category_explanation(category_id: String) -> String:
	return str(plain_explanations.get(category_id, ""))


func observe() -> bool:
	if is_finished() or observed:
		return false
	observed = true
	active_hint = str(entity().get("observe_hints", {}).get(str(depth), entity().get("observe_hint", "")))
	card_actions.append({"action": "observe", "entity_id": entity()["entity_id"], "depth": depth})
	return true


func lock() -> bool:
	if is_finished() or card_points <= 0:
		return false
	_finish_card("lock")
	return true


func skip() -> void:
	if is_finished():
		return
	chaos += 2
	streak = 0
	_finish_card("skip")


func timeout() -> void:
	if is_finished():
		return
	chaos += 5
	streak = 0
	_finish_card("timeout")


func choose(category_id: String) -> Dictionary:
	if is_finished():
		return {}
	var question := step()
	var correct := category_id == str(question["correct_category_id"])
	var outcome := {
		"entity_id": entity()["entity_id"],
		"depth": depth,
		"chosen": category_id,
		"correct_category_id": question["correct_category_id"],
		"correct": correct,
		"response_ms": Time.get_ticks_msec() - card_started_ms,
		"observe_used": observed
	}
	choices.append(outcome)
	if correct:
		card_points += int(question["base_score"])
		if bool(question["is_final"]):
			if card_mistakes == 0:
				card_points += int(entity()["complete_bonus"])
				streak += 1
			_finish_card("complete" if card_mistakes == 0 else "mixed")
		else:
			depth += 1
	else:
		chaos += 5
		streak = 0
		if continue_on_wrong:
			card_mistakes += 1
			if bool(question["is_final"]):
				_finish_card("mixed")
			else:
				depth += 1
		else:
			_finish_card("wrong")
	return outcome


func _begin_card() -> void:
	if is_finished():
		return
	depth = int(entity().get("start_depth", 1))
	card_points = 0
	card_mistakes = 0
	observed = false
	active_hint = ""
	card_started_ms = Time.get_ticks_msec()


func _finish_card(outcome: String) -> void:
	var earned := card_points
	if outcome == "skip":
		earned = 0
	elif outcome == "wrong" or outcome == "timeout":
		earned = roundi(float(earned) * 0.5)
	if observed:
		earned = roundi(float(earned) * 0.7)
	# The full design's fast bonus applies to a complete card only.
	if outcome == "complete":
		var elapsed := Time.get_ticks_msec() - card_started_ms
		if elapsed <= 3000:
			earned = roundi(float(earned) * 1.5)
		elif elapsed <= 5000:
			earned = roundi(float(earned) * 1.25)
	total_score += earned
	var result := {
		"entity_id": entity()["entity_id"],
		"outcome": outcome,
		"last_depth": depth,
		"score_gained": earned,
		"mistakes": card_mistakes,
		"observe_used": observed,
		"chaos_total": chaos
	}
	card_results.append(result)
	card_actions.append({"action": outcome, "entity_id": entity()["entity_id"], "depth": depth, "score_gained": earned})
	current_index += 1
	_begin_card()


func save_log(run_mode: String = "", extra: Dictionary = {}) -> String:
	var log_mode := run_mode if not run_mode.is_empty() else mode_id
	var path := "user://first_classification_%s_log.json" % log_mode
	var payload := {
		"prototype_version": 1,
		"mode_id": mode_id,
		"run_mode": log_mode,
		"completed_at_unix": Time.get_unix_time_from_system(),
		"total_score": total_score,
		"chaos": chaos,
		"choices": choices,
		"card_results": card_results,
		"card_actions": card_actions
	}
	payload.merge(extra)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(payload, "\t"))
	return ProjectSettings.globalize_path(path)
