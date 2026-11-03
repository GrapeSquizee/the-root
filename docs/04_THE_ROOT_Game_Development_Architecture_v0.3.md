# THE ROOT — Game Development Architecture
## Vertical Slice 한 판 구현 구조 v0.3

> 목적: 기획을 더 추가하는 문서가 아니라 **실제로 어떤 순서와 모듈로 한 판을 만드는지**를 정의한다.

---

# 1. Vertical Slice Definition of Done

다음 흐름이 처음부터 끝까지 끊기지 않고 실행되면 v0.1 Vertical Slice 완성으로 본다.

```text
TITLE
→ Cycle 1 (5분)
→ Result
→ Reward
→ Random Shop
→ Purchase / Hold / Upgrade / Equip
→ Cycle 2 (5분)
→ Result
→ ORDER 100%
→ Credits Bonus Classification
→ Overflow
→ CHAOS 100%
→ Hard Mode Attribute Puzzle 1개
→ END OF VERTICAL SLICE
```

---

# 2. 구현 우선순위

## Phase 1 — 카드 1장
가장 먼저 아래만 만든다.

```text
JSON 로드
→ 고양이 카드 표시
→ Left/Right 선택
→ 정답 판정
→ 다음 Depth
→ Complete
```

그래픽 품질보다 데이터 왕복을 먼저 검증한다.

완료 조건:
- 코드에 고양이 정답이 하드코딩되어 있지 않음
- JSON 수정으로 문제를 바꿀 수 있음

## Phase 2 — Entity Loop
- 20개 카드
- start_depth
- Complete
- Wrong
- LOCK
- SKIP
- OBSERVE

## Phase 3 — 5분 Cycle
- Timer
- Streak
- Score
- ORDER / CHAOS
- Result screen
- 플레이 로그

## Phase 4 — 성장
- Reward
- Currency
- Materials
- Inventory
- 3-slot Loadout
- Upgrade

## Phase 5 — Shop
- 5 random slots
- first shop guarantee
- enhanced equipment
- HOLD
- refresh cost
- purchase

## Phase 6 — Cycle 2
- 복습 start_depth
- 장비 효과
- 난이도 상승
- 분위기 변화

## Phase 7 — Ending
- ORDER 100%
- credit bonus cards
- int32 overflow 연출
- Hard Mode teaser

---

# 3. Scene Responsibilities

## `bootstrap.tscn`
- 데이터 로드
- Save load
- 버전 검사
- Title로 이동

## `gameplay.tscn`
가장 중요한 화면.

자식 예:
```text
Gameplay
├─ BackgroundLayer
├─ WorldTreeLayer
├─ EntityCardContainer
├─ ChoiceOverlay
├─ HUD
│  ├─ Timer
│  ├─ OrderGauge
│  ├─ ChaosGauge
│  ├─ Score
│  ├─ Streak
│  └─ Depth
├─ ActionBar
│  ├─ Observe
│  ├─ Lock
│  └─ Skip
└─ EffectsLayer
```

## `entity_card.tscn`
- 이미지
- 개체명
- drag offset
- swipe preview
- left/right category preview

정답 로직을 가지지 않는다.

## `shop.tscn`
- 5 stock slots
- held state
- refresh button/cost
- currency/material UI
- buy/equip/upgrade modal

---

# 4. Domain Models

GDScript Dictionary로 시작해도 되지만 필드를 명확히 유지한다.

## Entity
```text
entity_id
name_ko
name_en
scientific_name
difficulty
max_depth
path[]
steps[]
observe_hint
complete_bonus
cycle data
hardmode_attributes[]
```

## QuestionStep
```text
depth
parent_category_id
correct_category_id
distractor_category_id
base_score
is_final
```

## EquipmentInstance
```text
instance_id
item_id
level
mastery
equipped_slot
acquired_at
```

동일 item_id를 여러 개 허용할지 여부는 정식 게임에서 결정 가능하다. Vertical Slice는 item_id별 1개 보유로 단순화해도 된다.

## ShopOffer
```text
offer_id
product_type
item_id/material_id
level
quantity
price
held
generated_cycle
```

---

# 5. Core Systems

## ClassificationSystem
책임:
- 현재 Entity
- 현재 Depth
- 정답 확인
- 다음 Depth
- Lock/Skip/Complete 상태

하면 안 되는 것:
- 점수 계산
- 사운드 직접 실행
- 저장 파일 직접 수정

결과 Event만 발행한다.

## ScoreSystem
- Depth score
- Complete
- Observe
- Fast
- Streak
- Field Notes

## OrderChaosSystem
- 정답 ORDER
- 오답 CHAOS
- Skip CHAOS
- Stabilizer 적용
- 시각 단계 threshold 발생

## CycleSystem
- 300초
- 카드 index
- 20 card limit
- timer expiry
- Cycle complete

## ObservationSystem
- 개체당 1회 검사
- hint 반환
- Lens 적용
- 사용 로그

## EquipmentSystem
- 장착 슬롯 3
- level 효과 조회
- effect modifier 반환

## MasterySystem
효과가 실제로 발동했을 때만:
```text
Lens        observe_effect_applied
Hourglass   fast_bonus_triggered
Bookmark    skip_effect_applied
Stabilizer  wrong_answer_mitigated
FieldNotes  entity_complete_with_equipped
```

## ShopSystem
- stock generation
- no duplicate equipment
- first shop guarantee
- HOLD
- refresh
- purchase
- pricing

---

# 6. Gameplay Event Flow

카드 시작:

```text
CycleSystem
→ entity_started(entity_id, start_depth)
→ ClassificationSystem loads step
→ UI renders
```

선택:

```text
UI
→ submit_choice(category_id)
→ ClassificationSystem.resolve()
→ choice_resolved(result)
```

정답:

```text
ScoreSystem.add_depth_score()
StreakSystem.increment()
ClassificationSystem.next_depth()
```

최종 정답:

```text
ScoreSystem.add_complete_bonus()
EquipmentSystem.apply_field_notes()
ScoreSystem.apply_observe_modifier()
ScoreSystem.apply_fast_bonus()
ScoreSystem.apply_streak()
→ entity_completed
```

오답:

```text
ScoreSystem.apply_wrong_loss(50%)
EquipmentSystem.get_wrong_chaos()
OrderChaosSystem.add_chaos()
StreakSystem.reset()
→ entity_failed
```

---

# 7. OBSERVE

```text
if observe_used:
    reject

observe_used = true
hint = entity.observe_hint
penalty = EquipmentSystem.get_observe_penalty()
card_modifier *= (1 - penalty)
MasterySystem.on_observe_effect()
```

중요:
Lens가 없으면 -30%.
Lens +5면 -15%.

---

# 8. LOCK

현재까지 맞힌 결과를 확정한다.

```text
LOCK
→ current card score bank
→ no Complete Bonus
→ no deeper Depth
→ entity ends as partial success
```

로그에:
- locked_depth
- max_depth
- potential_depth_lost

를 저장하면 향후 “겁이 나서 깊게 안 들어가는 플레이” 분석이 가능하다.

---

# 9. SKIP

기본:
```text
score = 0
time -= 5
chaos += 2
streak = 0
```

Bookmark가 있으면 효과를 덮어쓴다.

SKIP은 정답/오답 데이터를 남기지 않지만 entity_mastery에는 skip_count를 증가시킨다.

---

# 10. Shop Algorithm

## Initial generation
5 slots.

권장 슬롯:
```text
Slot 1 equipment 100%
Slot 2 equipment 70 / material 30
Slot 3 equipment 50 / material 50
Slot 4 material 100
Slot 5 equipment 35 / material 60 / Unknown 5
```

첫 상점:
- Slot 1은 무조건 강화품
- +1 70%
- +2 30%

일반 장비 강화 roll:
```text
+0 45
+1 30
+2 15
+3 8
+4 2
```

동일 장비 item_id 중복 금지.

## HOLD
`held_offer_id` 1개.

Refresh/다음 Cycle 재생성 시:
```text
held offer copy
+ remaining slots reroll
```

## Refresh
```text
refresh_count = 0

costs = [50,100,200,400]
```

4회 이후 버튼 disabled.

---

# 11. Upgrade

```text
+0 → +1 120 + material 1
+1 → +2 180 + material 2
+2 → +3 280 + material 3
+3 → +4 420 + material 5
+4 → +5 650 + material 8 + Unknown 1
```

검사:
```text
has currency?
has dedicated material?
has unknown fragment?
level < 5?
```

모두 만족:
- 재화 차감
- level +1
- 실패 없음
- Save 즉시

---

# 12. Reward

Cycle result에서:
- 분류 성과
- score
- perfect complete
- best streak
- deepest
- Observe
- Skip

를 기반으로 reward를 계산한다.

Vertical Slice 기본 범위:
```text
Currency         350~500
High performance up to 650
Common materials 3~5
High performance up to 7
Unknown          0~1
```

첫 Shop 경험을 위해 Cycle 1 reward는 장비 1개 또는 저강화 완제품에 접근할 수 있는 범위로 보정한다.

---

# 13. Save

Vertical Slice부터 자동저장 포인트:

```text
Cycle 시작
Entity 종료
Cycle 종료
Shop 구매
HOLD 변경
Upgrade
Equip 변경
Overflow 직전
Hard Mode unlock
```

세이브가 깨졌을 때 카드 중간으로 복구할 필요는 없다.
최근 완료 Entity 이후 상태로 복구하는 정도면 충분하다.

---

# 14. Analytics / Playtest

개발 빌드 결과 화면에 Debug tab을 둬도 좋다.

확인할 것:
```text
cards_seen
cards_completed
avg_depth
avg_response_ms
observe_rate
skip_rate
wrong_rate
lock_rate
currency_earned
shop_refresh_count
held_offer_count
item_purchase
```

Entity별:
```text
wrong_rate by depth
observe_rate
avg lock depth
```

이 데이터로:
- 너무 쉬운 문제
- 나쁜 Distractor
- 지나치게 비싼 Observe
- 사실상 안 쓰는 Skip
- 과도하게 강한 아이템

을 조정한다.

---

# 15. Visual Progression Hooks

게임 시스템은 배경에 직접 접근하지 않고 progression event를 보낸다.

예:
```text
order_threshold_changed(25)
order_threshold_changed(50)
chaos_threshold_changed(20)
cycle_phase_changed("challenge")
```

VisualDirector가:
- 배경 색
- particles
- World Tree
- 음악 layer

를 변경한다.

게임 규칙과 연출을 분리해야 밸런스 조정 시 화면 코드가 깨지지 않는다.

---

# 16. Ending Implementation

ORDER 100%는 실제 Cycle 2 결과에서 연출용 target으로 맞춘다.

Credit Bonus Stage:
- scripted entity sequence
- huge point reward
- normal classification UI를 재활용
- 연출만 별도

Overflow:
```text
display = 2147483647
bonus = 1
display = -2147483648
```

실제 global score 변수는 64-bit로 유지한다.

---

# 17. Hard Mode Teaser

Vertical Slice에서 필요한 것만 구현:

```text
SIMILARITY 0.000%

ATTRIBUTE:
Warm-blooded

[ Dolphin ]
[ Shark ]
[ Penguin ]
[ Whale ]
```

복수 선택 가능.

Submit 후:
- 정답/오답 비교
- Similarity 미세 상승
- 작은 행성 visual spawn
- END OF VERTICAL SLICE

전체 행성 시뮬레이션은 v0.1 범위 밖이다.

---

# 18. 개발 체크리스트

## Data
- [ ] JSON schema loader
- [ ] 30 entities load
- [ ] all question steps valid
- [ ] category IDs valid
- [ ] no missing distractor
- [ ] item/economy config valid

## Gameplay
- [ ] swipe/keyboard
- [ ] D1~D6
- [ ] start_depth
- [ ] Observe
- [ ] Lock
- [ ] Skip
- [ ] Wrong
- [ ] Complete
- [ ] Fast Bonus
- [ ] Streak

## Meta
- [ ] Result
- [ ] Reward
- [ ] Inventory
- [ ] Equip 3
- [ ] Upgrade
- [ ] Random Shop
- [ ] Hold
- [ ] Refresh

## Ending
- [ ] ORDER 100
- [ ] credits gameplay
- [ ] overflow
- [ ] Hard Mode teaser

## Save
- [ ] progress
- [ ] economy
- [ ] equipment
- [ ] mastery
- [ ] event logs

---

# 19. 구현 중 하지 말아야 할 것

Vertical Slice에서는 다음을 먼저 만들지 않는다.
- 완전한 전체 Master Tree
- 수천 개 Entity
- 전체 Hard Mode 행성 시뮬레이션
- 온라인 서버
- 계정 시스템
- 멀티플레이
- 복잡한 제작 트리
- 과도한 랜덤 옵션 장비
- 전체 모바일 최적화
- 자체 Canon 편집 웹서비스

먼저 **15분짜리 한 판이 재미있는지** 검증한다.

---

# 20. 첫 개발 마일스톤

첫 milestone의 목표는:

> 고양이 → 물 → 오리너구리 3개체를 데이터로 읽어 한 Cycle에서 정상 분류하고, OBSERVE/LOCK/SKIP과 결과 로그가 저장되는 빌드.

이것이 되면 30개체 확장은 콘텐츠 입력 문제다.

그 다음:
> Cycle 1 → Shop → Cycle 2

까지 연결하고 마지막으로 Overflow/Hard Mode teaser를 붙인다.
