extends RefCounted
## 낮 분류 → 저녁 준비 → 밤 방어 → 새벽 정산 루프의 규칙.
## 화면과 분리해 두어 헤드리스 테스트에서 그대로 돌릴 수 있다.
## 기준 문서: docs/13_THE_ROOT_컨셉_재설계_낮_분류_밤_방어.md, docs/14_THE_ROOT_세계_규칙.md

signal changed

const DAYS := 3
const CARDS_PER_DAY := 6
const TUTORIAL_LIMIT := 4.0
const ADAPTED_LIMIT := 2.0
const NIGHT_LENGTH := 75.0
const WAVE_TIMES := [0.0, 22.0, 44.0]
const EXTRA_WAVE_TIME := 60.0
const EXTRA_WAVE_RED_THRESHOLD := 4
const UNDOER_SPEED := 46.0
const YELLOW_SLOW := 0.45
const CUT_TIME := 3.2
const MEND_RADIUS := 130.0
const SLOW_SCALE := 0.35
const FIX_COOLDOWN := 2
const HAND_LIMIT := 3
const CLOTH_LINES := 12

# 정착지 그래프. 좌표는 화면 1280x720 기준 지도 영역 안이다.
const NODES := {
	"edge_w": {"label": "끊어진 도로", "kind": "edge", "pos": Vector2(90, 330)},
	"edge_n": {"label": "북쪽 비탈", "kind": "edge", "pos": Vector2(560, 95)},
	"edge_e": {"label": "동쪽 숲", "kind": "edge", "pos": Vector2(1010, 300)},
	"eunsol": {"label": "은솔네", "kind": "house", "pos": Vector2(360, 470), "names": 2},
	"elder": {"label": "노인네", "kind": "house", "pos": Vector2(300, 260), "names": 2},
	"neighbor": {"label": "이웃 여자네", "kind": "house", "pos": Vector2(520, 230), "names": 2},
	"potlid": {"label": "솥뚜껑 남자네", "kind": "house", "pos": Vector2(770, 230), "names": 1},
	"storage": {"label": "창고", "kind": "house", "pos": Vector2(820, 470), "names": 1},
	"well": {"label": "우물", "kind": "well", "pos": Vector2(600, 520)},
	"cloth": {"label": "기록 천", "kind": "cloth", "pos": Vector2(560, 380)},
}

const EDGES := [
	["edge_w", "elder"], ["edge_w", "eunsol"],
	["edge_n", "neighbor"], ["edge_n", "elder"],
	["edge_e", "potlid"], ["edge_e", "storage"],
	["elder", "neighbor"], ["neighbor", "potlid"], ["eunsol", "storage"],
	["elder", "cloth"], ["neighbor", "cloth"], ["potlid", "cloth"],
	["eunsol", "cloth"], ["storage", "cloth"], ["well", "cloth"], ["eunsol", "well"],
]

# 분류 카드. 지구 개체(연우가 아는 것)와 이 세계의 대상이 섞인다.
# steps: [왼쪽, 오른쪽, 정답 인덱스]
const CARDS := [
	{"name": "물", "world": "earth", "steps": [["생물", "무생물", 1], ["물질", "인공물", 0]]},
	{"name": "흰다리", "world": "here", "note": "등에 이끼 같은 잎이 난 짐승", "steps": [["생물", "무생물", 0], ["식물", "동물", 1]]},
	{"name": "낙엽 벌레", "world": "here", "note": "낙엽처럼 생겼지만 다리로 걷는다", "steps": [["생물", "무생물", 0], ["식물", "동물", 1], ["절지동물", "척삭동물", 0]]},
	{"name": "작은갈색박쥐", "world": "earth", "steps": [["생물", "무생물", 0], ["식물", "동물", 1], ["조류", "포유류", 1]]},
	{"name": "은솔의 수첩", "world": "here", "steps": [["생물", "무생물", 1], ["물질", "인공물", 1]]},
	{"name": "거울토끼", "world": "here", "note": "투명한 옆구리 안에 작은 토끼가 웅크려 있다", "steps": [["생물", "무생물", 0], ["식물", "동물", 1], ["절지동물", "척삭동물", 1]]},
	{"name": "돌산호", "world": "earth", "steps": [["생물", "무생물", 0], ["동물", "식물", 0]]},
	{"name": "숯", "world": "here", "steps": [["생물", "무생물", 1], ["물질", "인공물", 0]]},
	{"name": "황제펭귄", "world": "earth", "steps": [["생물", "무생물", 0], ["식물", "동물", 1], ["조류", "포유류", 0]]},
	{"name": "표고버섯", "world": "earth", "steps": [["생물", "무생물", 0], ["균류", "식물", 0]]},
	{"name": "노란 실", "world": "here", "steps": [["생물", "무생물", 1], ["물질", "인공물", 1]]},
	{"name": "오리너구리", "world": "earth", "steps": [["생물", "무생물", 0], ["식물", "동물", 1], ["조류", "포유류", 1]]},
	{"name": "우물 이끼", "world": "here", "note": "돌벽 틈에 붙어 자란다", "steps": [["생물", "무생물", 0], ["동물", "식물", 1]]},
	{"name": "듀공", "world": "earth", "steps": [["생물", "무생물", 0], ["식물", "동물", 1], ["어류", "포유류", 1]]},
	{"name": "나무껍질 조각", "world": "here", "steps": [["생물", "무생물", 1], ["물질", "인공물", 0]]},
	{"name": "거미", "world": "earth", "steps": [["생물", "무생물", 0], ["식물", "동물", 1], ["절지동물", "척삭동물", 0]]},
	{"name": "빗물 통", "world": "here", "steps": [["생물", "무생물", 1], ["물질", "인공물", 1]]},
	{"name": "참문어", "world": "earth", "steps": [["생물", "무생물", 0], ["식물", "동물", 1], ["연체동물", "척삭동물", 0]]},
]

var rng := RandomNumberGenerator.new()

var phase := "title" # title, day, evening, night, dawn, end
var day := 1
var stability := 0.003

# 자원
var ieum := 0          # 실타래: 정답으로 쌓이는 방어 자원
var yeoyu := 0.0       # 집중: 빠른 정답으로 쌓이는 느린 시간(초)
var hand := 0          # 서린의 손 굳기
var fix_cooldown := 0
var fixed_tonight := false
var fixed_today := false

# 정착지 상태
var houses := {}       # id -> {names, red, blur, cut}
var yellow := {}       # 간선 키 -> true
var cloth_hp := CLOTH_LINES  # 기록 천에 남은 선. 0이 되면 고정의 기준이 사라진다.
var leaves := 0
var names_lost_total := 0

# 낮
var deck: Array = []
var card_index := 0
var step_index := 0
var timer := 0.0
var time_limit := TUTORIAL_LIMIT
var adaptation_notice := false
var last_feedback := ""
var day_log := {"correct": 0, "wrong": 0, "blur": 0, "locked": 0}

# 밤
var night_time := 0.0
var waves: Array = []  # {time, spawn, count, fired}
var undoers: Array = [] # {path, seg, t, cutting, cut_left, pos}
var slowing := false
var night_log := {"names_lost": 0, "mended": 0, "cloth_hits": 0}
var dawn_report := {}


func _init(seed_value := 0) -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	for id in NODES:
		if NODES[id]["kind"] == "house":
			houses[id] = {"names": NODES[id]["names"], "red": 0, "blur": false, "cut": 0.0}


# ---------- 공통 ----------

static func edge_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


func neighbors(id: String) -> Array:
	var out: Array = []
	for e in EDGES:
		if e[0] == id:
			out.append(e[1])
		elif e[1] == id:
			out.append(e[0])
	return out


func node_pos(id: String) -> Vector2:
	return NODES[id]["pos"]


func house_ids() -> Array:
	var out: Array = []
	for id in NODES:
		if NODES[id]["kind"] == "house":
			out.append(id)
	return out


func red_count() -> int:
	var n := 0
	for id in houses:
		n += houses[id]["red"]
	return n


func names_left() -> int:
	var n := 0
	for id in houses:
		n += houses[id]["names"]
	return n


# ---------- 낮 ----------

func start_game() -> void:
	day = 1
	start_day()


func start_day() -> void:
	phase = "day"
	fixed_tonight = false
	day_log = {"correct": 0, "wrong": 0, "blur": 0, "locked": 0}
	yeoyu = 0.0
	# 첫날은 튜토리얼(4.0), 둘째 날부터 2.0. 소설 9화의 `튜토리얼 종료.`와 같은 자리다.
	time_limit = TUTORIAL_LIMIT if day == 1 else ADAPTED_LIMIT
	adaptation_notice = day == 2
	var pool: Array = CARDS.duplicate()
	pool.shuffle()
	deck = []
	var ids := house_ids()
	for i in CARDS_PER_DAY:
		var card: Dictionary = pool[i % pool.size()].duplicate(true)
		# 카드마다 그 대상이 걸린 집을 정한다. 오답이면 그 집에 붉은 줄이 남는다.
		card["house"] = ids[i % ids.size()]
		deck.append(card)
	card_index = 0
	step_index = 0
	timer = time_limit
	last_feedback = ""
	changed.emit()


func card() -> Dictionary:
	if card_index < deck.size():
		return deck[card_index]
	return {}


func step() -> Array:
	var c := card()
	if c.is_empty():
		return []
	return c["steps"][step_index]


func update_day(delta: float) -> void:
	if phase != "day" or card().is_empty():
		return
	timer -= delta
	if timer <= 0.0:
		timer = 0.0
		_finish_card("blur")


func choose(side: int) -> bool:
	if phase != "day" or card().is_empty():
		return false
	var s := step()
	var correct: bool = side == int(s[2])
	if correct:
		ieum += 1
		yeoyu += timer * 0.25
		step_index += 1
		if step_index >= card()["steps"].size():
			_finish_card("correct")
		else:
			timer = time_limit
			last_feedback = "맞았다. 한 단계 더 내려간다."
			changed.emit()
	else:
		_finish_card("wrong")
	return correct


## 여기서 멈추기(LOCK). 맞힌 깊이까지만 실타래로 남기고 더 내려가지 않는다.
func lock() -> bool:
	if phase != "day" or step_index == 0:
		return false
	_finish_card("locked")
	return true


func _finish_card(outcome: String) -> void:
	var c := card()
	var h: Dictionary = houses[c["house"]]
	match outcome:
		"correct":
			day_log["correct"] += 1
			last_feedback = "%s — 하늘색 선이 이어졌다." % c["name"]
		"locked":
			day_log["locked"] += 1
			last_feedback = "%s — 여기서 멈췄다." % c["name"]
		"wrong":
			day_log["wrong"] += 1
			# 깊이 욕심을 내다 틀리면 굵은 붉은 줄이 남는다(13번 문서 4.2절).
			var weight := 1 if step_index == 0 else 2
			h["red"] = min(h["red"] + weight, 3)
			last_feedback = "%s — 틀렸다. %s에 붉은 줄이 남았다." % [c["name"], NODES[c["house"]]["label"]]
		"blur":
			day_log["blur"] += 1
			# 시간 초과는 오답으로 치지 않는다(세계 규칙 2.4절).
			h["blur"] = true
			last_feedback = "%s — 숫자가 0이 되었다. 시간 초과로 스크린이 번졌다." % c["name"]
	card_index += 1
	step_index = 0
	timer = time_limit
	if card_index >= deck.size():
		start_evening()
	else:
		changed.emit()


# ---------- 저녁 ----------

func start_evening() -> void:
	phase = "evening"
	_plan_waves()
	changed.emit()


func _plan_waves() -> void:
	waves = []
	var spawns := ["edge_w", "edge_n", "edge_e"]
	for i in WAVE_TIMES.size():
		waves.append({"time": WAVE_TIMES[i], "spawn": spawns[rng.randi() % spawns.size()], "count": 2 + day - 1 + i / 2, "fired": false})
	if red_count() >= EXTRA_WAVE_RED_THRESHOLD:
		waves.append({"time": EXTRA_WAVE_TIME, "spawn": spawns[rng.randi() % spawns.size()], "count": 3, "fired": false})


## 저녁에 미리 보여 줄 해체자 경로(Into the Breach식 예고).
func predicted_paths() -> Array:
	var out: Array = []
	for w in waves:
		out.append(route_from(w["spawn"]))
	return out


func toggle_yellow(a: String, b: String) -> bool:
	if phase != "evening":
		return false
	var key := edge_key(a, b)
	if yellow.has(key):
		yellow.erase(key)
		ieum += 1
		changed.emit()
		return true
	if ieum < 1:
		return false
	yellow[key] = true
	ieum -= 1
	changed.emit()
	return true


func can_fix() -> bool:
	return fix_cooldown == 0 and hand < HAND_LIMIT and cloth_hp > 0 and not fixed_tonight


## 고정: 이번 밤 동안 집의 이름과 천의 선은 끊기지 않는다. 대신 내일은 자라는 것이 멈춘다.
func fix() -> bool:
	if not can_fix() or not (phase == "evening" or phase == "night"):
		return false
	fixed_tonight = true
	fixed_today = true
	hand += 1
	fix_cooldown = FIX_COOLDOWN
	for id in houses:
		houses[id]["cut"] = 0.0
	changed.emit()
	return true


# ---------- 밤 ----------

func start_night() -> void:
	phase = "night"
	night_time = 0.0
	undoers = []
	night_log = {"names_lost": 0, "mended": 0, "cloth_hits": 0}
	changed.emit()


## 해체자의 길: 붉은 줄이 걸린 집이 있으면 그쪽을 거쳐 기록 천으로 간다.
func route_from(spawn: String) -> Array:
	var best_red := ""
	var best_len := 999
	for id in houses:
		if houses[id]["red"] > 0 and houses[id]["names"] > 0:
			var p := _bfs(spawn, id)
			# 굵은 줄일수록 더 멀리서도 끌어당긴다.
			var score: int = p.size() - houses[id]["red"]
			if not p.is_empty() and score < best_len:
				best_len = score
				best_red = id
	if best_red != "":
		var first := _bfs(spawn, best_red)
		var second := _bfs(best_red, "cloth")
		return first + second.slice(1)
	return _bfs(spawn, "cloth")


func _bfs(from: String, to: String) -> Array:
	var prev := {from: ""}
	var queue: Array = [from]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if cur == to:
			break
		for n in neighbors(cur):
			# 해체자는 우물 쪽으로는 들어가지 않는다(번진 스크린을 건드리지 못한다).
			if n == "well" or prev.has(n):
				continue
			prev[n] = cur
			queue.append(n)
	if not prev.has(to):
		return []
	var path: Array = []
	var node := to
	while node != "":
		path.push_front(node)
		node = prev[node]
	return path


func time_scale() -> float:
	return SLOW_SCALE if slowing and yeoyu > 0.0 else 1.0


## real_delta는 실제 시간, 게임 시간은 느린 시간 배율을 곱해 진행한다.
func update_night(real_delta: float) -> void:
	if phase != "night":
		return
	if slowing and yeoyu > 0.0:
		yeoyu = max(yeoyu - real_delta, 0.0)
	var delta := real_delta * time_scale()
	night_time += delta
	for w in waves:
		if not w["fired"] and night_time >= w["time"]:
			w["fired"] = true
			for i in w["count"]:
				_spawn(w["spawn"], i * 0.35)
	for u in undoers.duplicate():
		_step_undoer(u, delta)
	if night_time >= NIGHT_LENGTH or (cloth_hp <= 0):
		start_dawn()
		return
	var all_fired := true
	for w in waves:
		all_fired = all_fired and w["fired"]
	if all_fired and undoers.is_empty() and night_time > WAVE_TIMES[-1] + 5.0:
		start_dawn()
		return
	changed.emit()


func _spawn(spawn: String, offset: float) -> void:
	var path := route_from(spawn)
	if path.size() < 2:
		return
	undoers.append({"path": path, "seg": 0, "t": -offset, "cutting": false, "cut_left": 0.0, "pos": node_pos(spawn)})


func _step_undoer(u: Dictionary, delta: float) -> void:
	var path: Array = u["path"]
	if u["cutting"]:
		var here: String = path[u["seg"]]
		if fixed_tonight and houses.has(here):
			u["cutting"] = false
			return
		u["cut_left"] -= delta
		if houses.has(here):
			houses[here]["cut"] = 1.0 - u["cut_left"] / _cut_time(here)
		if u["cut_left"] <= 0.0:
			u["cutting"] = false
			if houses.has(here) and houses[here]["names"] > 0:
				houses[here]["names"] -= 1
				houses[here]["cut"] = 0.0
				night_log["names_lost"] += 1
				names_lost_total += 1
		return
	if u["seg"] >= path.size() - 1:
		# 기록 천에 닿았다. 고정한 밤에는 천의 선도 못 박혀 있어 끊기지 않는다.
		if not fixed_tonight:
			cloth_hp -= 1
			night_log["cloth_hits"] += 1
		undoers.erase(u)
		return
	var a: String = path[u["seg"]]
	var b: String = path[u["seg"] + 1]
	var length := node_pos(a).distance_to(node_pos(b))
	var speed := UNDOER_SPEED * (YELLOW_SLOW if yellow.has(edge_key(a, b)) else 1.0)
	u["t"] += delta * speed / length
	if u["t"] < 0.0:
		u["pos"] = node_pos(a)
		return
	if u["t"] >= 1.0:
		u["seg"] += 1
		u["t"] = 0.0
		u["pos"] = node_pos(b)
		# 이름이 남은 집에 닿으면 멈춰서 줄에 걸린 이름을 끊는다.
		if houses.has(b) and houses[b]["names"] > 0 and not fixed_tonight:
			u["cutting"] = true
			u["cut_left"] = _cut_time(b)
		return
	u["pos"] = node_pos(a).lerp(node_pos(b), u["t"])


func _cut_time(house: String) -> float:
	# 붉은 줄이 걸린 집은 더 빨리 끊긴다(게임에서 더한 규칙).
	return CUT_TIME / (1.0 + houses[house]["red"])


## 잇기: 끊기는 곳을 다시 잇는다. 주변의 해체자가 한꺼번에 흩어진다(소설 16화).
func mend(node_id: String) -> bool:
	if phase != "night" or ieum < 1:
		return false
	var center := node_pos(node_id)
	var scattered := 0
	for u in undoers.duplicate():
		if (u["pos"] as Vector2).distance_to(center) <= MEND_RADIUS:
			undoers.erase(u)
			scattered += 1
	if scattered == 0:
		return false
	ieum -= 1
	night_log["mended"] += 1
	if houses.has(node_id):
		houses[node_id]["cut"] = 0.0
	changed.emit()
	return true


# ---------- 새벽 ----------

func start_dawn() -> void:
	phase = "dawn"
	slowing = false
	undoers = []
	for id in houses:
		houses[id]["cut"] = 0.0
	var gain := 0.0
	var leaf := 0
	if fixed_today:
		# 고정한 날은 자라는 것이 멈춘다. 새 잎이 펴지지 않고 안정화율도 오르지 않는다.
		leaf = 0
	else:
		leaf = 1
		gain = 0.002 * day_log["correct"] + 0.001 * day_log["locked"]
	gain -= 0.001 * night_log["names_lost"]
	stability = max(stability + gain, 0.0)
	leaves += leaf
	dawn_report = {
		"day": day,
		"names_lost": night_log["names_lost"],
		"mended": night_log["mended"],
		"cloth_hits": night_log["cloth_hits"],
		"leaf": leaf,
		"gain": gain,
		"fixed": fixed_today,
	}
	changed.emit()


func next_day() -> void:
	if phase != "dawn":
		return
	if fix_cooldown > 0:
		fix_cooldown -= 1
	fixed_today = false
	# 다시 맞히면 바로잡힌다: 붉은 줄은 하루에 한 칸씩 옅어진다(재출제는 다음 단계에서).
	for id in houses:
		houses[id]["red"] = max(houses[id]["red"] - 1, 0)
	yellow = {}
	if day >= DAYS or cloth_hp <= 0:
		phase = "end"
		changed.emit()
		return
	day += 1
	start_day()
