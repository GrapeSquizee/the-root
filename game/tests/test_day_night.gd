extends SceneTree
## 낮과 밤 루프 규칙 검사. 실행:
## Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_day_night.gd

const Logic = preload("res://daynight/day_night_logic.gd")


func _initialize() -> void:
	var g = Logic.new(7)
	g.start_game()
	assert(g.phase == "day")
	assert(g.time_limit == Logic.TUTORIAL_LIMIT)

	# 첫 카드: 끝까지 맞히면 이음과 여유가 쌓인다.
	var first: Dictionary = g.card()
	for s in first["steps"]:
		assert(g.choose(int(s[2])))
	assert(g.ieum == first["steps"].size())
	assert(g.yeoyu > 0.0)
	assert(g.day_log["correct"] == 1)

	# 둘째 카드: 한 단계 맞히고 틀리면 굵은 붉은 줄.
	var second: Dictionary = g.card()
	var house: String = second["house"]
	assert(g.choose(int(second["steps"][0][2])))
	assert(not g.choose(1 - int(second["steps"][1][2])))
	assert(g.houses[house]["red"] == 2, "깊이 욕심 오답은 굵은 줄")

	# 셋째 카드: 시간 초과는 오답이 아니라 흐릿한 선택.
	var third: Dictionary = g.card()
	var reds_before: int = g.red_count()
	g.update_day(10.0)
	assert(g.day_log["blur"] == 1)
	assert(g.houses[third["house"]]["blur"])
	assert(g.red_count() == reds_before, "시간 초과는 붉은 줄을 남기지 않는다")

	# 넷째 카드: 확정은 한 단계 이상 맞힌 뒤에만.
	assert(not g.lock())
	assert(g.choose(int(g.step()[2])))
	assert(g.lock())

	while g.phase == "day":
		g.choose(int(g.step()[2]))
	assert(g.phase == "evening")

	# 해체자 경로는 붉은 줄이 걸린 집을 거쳐 기록 천으로 간다.
	for path in g.predicted_paths():
		assert(path[-1] == "cloth")
		assert(not path.has("well"), "해체자는 우물로 들어가지 않는다")
		assert(path.has(house), "붉은 줄 쪽으로 끌려간다")

	# 노란 실은 이음 1을 쓴다.
	var ieum_before: int = g.ieum
	assert(g.toggle_yellow("edge_w", "elder"))
	assert(g.ieum == ieum_before - 1)

	# 아무것도 안 하면 이름을 잃는다.
	var idle = _clone_to_night(g)
	_run_night(idle, false)
	assert(idle.phase == "dawn")
	assert(idle.dawn_report["names_lost"] > 0, "막지 않으면 이름을 잃는다")

	# 고정하면 이번 밤 이름은 지키지만 새 잎이 펴지지 않는다.
	var fixed = _clone_to_night(g)
	assert(fixed.fix())
	assert(fixed.hand == 1)
	_run_night(fixed, false)
	assert(fixed.dawn_report["names_lost"] == 0)
	assert(fixed.dawn_report["leaf"] == 0)
	fixed.next_day()
	assert(fixed.time_limit == Logic.ADAPTED_LIMIT, "둘째 날부터 2.0")
	assert(not fixed.can_fix(), "고정은 재사용 간격이 있다")

	# 이음으로 막으면 잃는 이름이 줄어든다.
	var mended = _clone_to_night(g)
	mended.ieum = 50
	_run_night(mended, true)
	assert(mended.dawn_report["mended"] > 0)
	assert(mended.dawn_report["names_lost"] < idle.dawn_report["names_lost"])

	print("test_day_night: ok (idle lost %d, mended lost %d)" % [idle.dawn_report["names_lost"], mended.dawn_report["names_lost"]])
	quit(0)


func _clone_to_night(src) -> Object:
	var g = Logic.new(7)
	g.day = src.day
	g.ieum = src.ieum
	g.yeoyu = src.yeoyu
	g.houses = src.houses.duplicate(true)
	g.yellow = src.yellow.duplicate()
	g.day_log = src.day_log.duplicate()
	g.waves = src.waves.duplicate(true)
	g.phase = "evening"
	g.start_night()
	return g


func _run_night(g, auto_mend: bool) -> void:
	var guard := 0
	while g.phase == "night" and guard < 20000:
		g.update_night(1.0 / 30.0)
		if auto_mend:
			for id in g.houses:
				if g.houses[id]["cut"] > 0.5:
					g.mend(id)
		guard += 1
