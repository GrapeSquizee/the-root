# THE ROOT — Dataset Specification
## Vertical Slice Canon / Economy Data v0.3

> 런타임 기준 파일:
> - `THE_ROOT_Vertical_Slice_DevData_v0.2.xlsx`
> - `THE_ROOT_Vertical_Slice_DevData_v0.2.json`

---

# 1. 데이터 설계 목표

THE ROOT의 핵심 IP는 그래픽보다 **분류 Canon과 관계 데이터**다.

같은 데이터가 다음 기능을 동시에 지원해야 한다.
- 본편 Entity → Category
- 단계별 Distractor
- OBSERVE
- Complete/Depth 난이도
- Branch 진행
- 플레이 로그
- Hard Mode Attribute → Entity
- Earth Similarity
- 도감/수집
- 콘텐츠 검수

---

# 2. Source of Truth

개발/편집:
**Excel / SQLite Canon**

Godot runtime:
**JSON export**

원칙:
- 게임 코드에 Entity별 if문 금지
- 카테고리/점수/아이템을 코드에 하드코딩하지 않음
- ID는 영문 snake_case
- UI 표시는 name_ko/name_en으로 분리
- 정답 변경은 데이터 버전 변경으로 관리

---

# 3. Vertical Slice 30개체

## Living 18
1. 고양이
2. 검독수리
3. 황제펭귄
4. 큰돌고래
5. 듀공
6. 오리너구리
7. 작은갈색박쥐
8. 백상아리
9. 혹등아귀
10. 참문어
11. 돌산호
12. 서양꿀벌
13. 거미
14. 해바라기
15. 이끼
16. 표고버섯
17. 빵효모
18. 대장균

## Non-living 12
1. 물
2. 얼음
3. 금
4. 철
5. 소금
6. 석영
7. 다이아몬드
8. 태양
9. 지구
10. 달
11. 망치
12. 스마트폰

의도:
**생물 분류 게임처럼 보이지 않도록 Vertical Slice부터 Living/Non-living 양쪽을 검증한다.**

---

# 4. Canon Path

개체는 `path[]`를 가진다.

예:

```json
{
  "entity_id": "platypus",
  "path": [
    "physical",
    "living",
    "animalia",
    "chordata",
    "mammalia",
    "monotremata"
  ]
}
```

각 path element가 D1~D6이다.

모든 개체가 D6일 필요는 없다.

예:
```text
이끼
PHYSICAL → LIVING → PLANT → BRYOPHYTA
Max D4
```

낮은 Max Depth는 Complete Bonus로 보정한다.

---

# 5. 게임 Canon과 실제 학술 분류

THE ROOT는 실제 계통을 참고하지만 게임에서는 선택 가능한 분기로 압축한다.

예:
```text
실제 생물 계통
Domain → Kingdom → Phylum → Class → Order → Family → Genus → Species ...

THE ROOT Vertical Slice
Physical → Living → Animal → Chordate → Mammal → Monotremata
```

중간 노드를 생략했다고 해서 과학적 분류를 새로 주장하는 것이 아니다.

목적:
- 두 선택지 카드 구조
- 최대 D6
- 플레이 속도
- 의미 있는 분류 판단

---

# 6. Question Step

한 행/객체가 한 Depth 문제를 의미한다.

필수 필드:
```text
entity_id
depth
parent_category_id
correct_category_id
distractor_category_id
base_score
is_final
observe_allowed
```

예:
```text
platypus / D5
parent       chordata
correct      mammalia
distractor   aves
```

Vertical Slice에서는 Distractor를 자동 생성하지 않고 **수동 승인된 값**을 사용한다.

---

# 7. 좋은 Distractor의 조건

좋은 오답:
- 플레이어가 실제로 헷갈릴 법함
- 같은 상위 Branch에서 비교 가능
- 정답을 모르면 고민이 생김
- 억지 말장난이 아님

나쁜 오답:
```text
BAT
MAMMAL / MINERAL
```

좋은 오답:
```text
BAT
MAMMAL / BIRD
```

정식 게임에서도 자동 sibling 선택만 사용하지 않고 승인된 distractor 품질 데이터를 유지한다.

---

# 8. OBSERVE 데이터

개체마다 Vertical Slice용 힌트 1개를 가진다.

원칙:
- 정답 카테고리 이름을 직접 말하지 않는다.
- 핵심 판별 속성을 알려준다.
- 짧고 즉시 읽힌다.
- 과학적 사실이어야 한다.

예:
```text
오리너구리
"알을 낳지만 털과 젖샘을 가진다."
```

```text
돌산호
"폴립이 촉수와 자포세포로 먹이를 잡는 동물이다."
```

Runtime:
- 개체당 1회
- 카드 최종점수 -30%

---

# 9. Difficulty

Vertical Slice difficulty: 1~8.

이는 학술 난이도가 아니라 **게임 플레이 체감 난이도**다.

영향 요소:
- familiarity
- visual confusion
- taxonomy difficulty
- surprise factor
- distractor quality

현재 대표:
- 고양이 1
- 지구 1
- 황제펭귄 4
- 큰돌고래 5
- 듀공 6
- 오리너구리 7
- 혹등아귀 7
- 돌산호 8
- 대장균 8

---

# 10. Cycle Data

## Cycle 1
1. `cat` — 고양이
2. `water` — 물
3. `sunflower` — 해바라기
4. `gold` — 금
5. `golden_eagle` — 검독수리
6. `hammer` — 망치
7. `moon` — 달
8. `iron` — 철
9. `honey_bee` — 서양꿀벌
10. `smartphone` — 스마트폰
11. `emperor_penguin` — 황제펭귄
12. `spider` — 거미
13. `common_octopus` — 참문어
14. `bottlenose_dolphin` — 큰돌고래
15. `shiitake` — 표고버섯
16. `little_brown_bat` — 작은갈색박쥐
17. `stony_coral` — 돌산호
18. `platypus` — 오리너구리
19. `dugong` — 듀공
20. `humpback_anglerfish` — 혹등아귀

Start Depth:
- 1~4번: D1
- 5~10번: D2
- 11~20번: D3

## Cycle 2
1. `ice` — 얼음
2. `salt` — 소금
3. `quartz` — 석영
4. `earth` — 지구
5. `moss` — 이끼
6. `bakers_yeast` — 빵효모
7. `great_white_shark` — 백상아리
8. `diamond` — 다이아몬드
9. `sun` — 태양
10. `e_coli` — 대장균
11. `emperor_penguin` — 황제펭귄
12. `bottlenose_dolphin` — 큰돌고래
13. `little_brown_bat` — 작은갈색박쥐
14. `stony_coral` — 돌산호
15. `platypus` — 오리너구리
16. `dugong` — 듀공
17. `humpback_anglerfish` — 혹등아귀
18. `common_octopus` — 참문어
19. `honey_bee` — 서양꿀벌
20. `shiitake` — 표고버섯

신규 초반 카드와 복습 카드를 혼합한다.

Cycle 1 복습 핵심은 D4~D5부터 시작해 이미 배운 상위 분류를 반복하지 않는다.

---

# 11. 점수 데이터

```text
depth_scores
D1 10
D2 15
D3 25
D4 40
D5 70
D6 120
```

Complete:
```text
Max D4 80
Max D5 100
Max D6 120
+
(difficulty - 1) * 10
```

기타:
```text
OBSERVE        -30%
Wrong          current card -50%, Chaos +5
SKIP           0 score, -5 sec, Chaos +2
Fast ≤3 sec    +50%
Fast ≤5 sec    +25%
```

---

# 12. 장비 데이터

장비 슬롯: 3

## Lens
Effect key:
`observe_penalty_pct`

| Level | 값 |
|---|---:|
| +0 | 30 |
| +1 | 27 |
| +2 | 24 |
| +3 | 21 |
| +4 | 18 |
| +5 | 15 |

Mastery:
`observe_effect_applied` 12회

## Hourglass
Effect key:
`fast_window_bonus_sec`

| Level | 추가 시간 |
|---|---:|
| +0 | 0.0 |
| +1 | 0.4 |
| +2 | 0.8 |
| +3 | 1.2 |
| +4 | 1.6 |
| +5 | 2.0 |

## Bookmark
+0: -5초 / Chaos +2  
+5: -3초 / Chaos +1

Mastery: 8회

## Stabilizer
오답 Chaos:
`5 → 4.5 → 4 → 3.5 → 3 → 2`

Mastery: 10회

## Field Notes
Complete Bonus:
`0% → 5% → 10% → 15% → 20% → 25%`

Mastery: 20회

---

# 13. 재료

| ID | 재료 | 주요 용도 | 상점 기준가 |
|---|---|---|---:|
| glass_shard | Glass Shard | Lens | 50 |
| broken_gear | Broken Gear | Hourglass / Bookmark | 55 |
| faded_ink | Faded Ink | Field Notes | 50 |
| copper_coil | Copper Coil | Stabilizer | 60 |
| unknown_fragment | Unknown Fragment | +5 / Hard Mode | 280 |

재료 파밍 강도: NORMAL

Cycle 기준:
- 일반 재료 3~5
- 고성과 최대 7
- Unknown Fragment 0~1

---

# 14. 강화 비용

| From | To | 화폐 | 전용재료 | Unknown |
|---:|---:|---:|---:|---:|
| +0 | +1 | 120 | 1 | 0 |
| +1 | +2 | 180 | 2 | 0 |
| +2 | +3 | 280 | 3 | 0 |
| +3 | +4 | 420 | 5 | 0 |
| +4 | +5 | 650 | 8 | 1 |

- 실패 없음
- +5가 본편 MAX
- 수치는 `BALANCE_V0.2`, 플레이테스트 조정 가능

---

# 15. 상점 데이터

5 Slots.

## 강화 레벨 확률
```text
+0 45%
+1 30%
+2 15%
+3  8%
+4  2%
+5  0%
```

## 첫 상점
저강화 장비 1개 보장:
```text
+1 70%
+2 30%
```

## 가격 배수
```text
+0 ×1.0
+1 ×1.5
+2 ×2.3
+3 ×3.5
+4 ×5.0
```

## HOLD
- 1 slot
- manual refresh 유지
- 다음 Cycle shop refresh에도 유지

## Refresh
```text
1: 50
2: 100
3: 200
4: 400
```

한 상점 최대 4회.

---

# 16. Hard Mode Attribute

각 Entity는 Hard Mode용 attribute/value를 가진다.

예:

```text
platypus
mammal       true
oviparous    true
has_fur      true
lactation    true
```

```text
e_coli
bacterium               true
prokaryote               true
membrane_bound_nucleus   false
unicellular              true
gram_negative            true
```

Hard Mode에서는 이 관계를 역으로 사용한다.

```text
ATTRIBUTE → ENTITIES
```

---

# 17. Mastery

Mastery는 Hard Mode 개인화와 별개로 **MAX 장비 진화 조건**이다.

```text
Lens         12 Observe effects
Hourglass    20 Fast Bonus triggers
Bookmark      8 Skip mitigations
Stabilizer   10 Wrong mitigations
Field Notes  20 Completes
```

상점에서 +4 장비를 바로 사더라도 Mastery=0.

---

# 18. 로그 스키마

반드시 저장:

```text
run_id
cycle_id
entity_id
depth
start_depth
options
chosen
correct
response_ms
observe_used
skip_used
lock_used
locked_depth
score_gained
chaos_gained
streak_before
streak_after
equipped_items
```

Entity mastery 집계:
```text
seen_count
correct_count
wrong_count
observe_count
skip_count
deepest_correct_depth
avg_response_ms
mastery_score
```

Hard Mode가 이 데이터를 사용한다.

---

# 19. 데이터 상태 태그

권장:
- `LOCKED`: 사용자와 확정
- `APPROVED_VS`: Vertical Slice Canon 승인
- `BALANCE_V0.2`: 플레이테스트 전 밸런스 초안
- `WORKING_NAME`: 표시명 미확정
- `PROVISIONAL_HM_COST`: Hard Mode 경제 미확정

게임 로직은 상태와 관계없이 값을 읽을 수 있지만, 출시 체크 시 LOCKED/APPROVED 여부를 검사한다.

---

# 20. 권위 출처

생물:
- NCBI Taxonomy
- Kew Plants of the World Online

화학:
- PubChem

광물:
- Mindat

천문:
- NASA Science

인공물 보조 ontology:
- Wikidata

Spreadsheet의 각 개체 `source_url` 컬럼을 유지한다.

정식 Canon Freeze 전에는:
1. 자동 검증
2. 출처 재확인
3. 수동 리뷰
4. `canon_version` 발행

순서로 확정한다.
