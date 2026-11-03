# THE ROOT — Technical Stack
## Vertical Slice 개발 기술 스택 v0.3

> 목표: Windows에서 먼저 완성되는 15분 내외 Vertical Slice를 만들되, Android 이식과 본편 확장을 막지 않는 구조.

---

# 1. 기준 엔진

## Godot
- **Godot 4.7.2 stable**
- 언어: **GDScript**
- 최초 타깃: **Windows PC**
- 2차 타깃: Android
- 이후: iOS
- 화면: **16:9 Landscape**

검증일: 2026-09-22  
공식 릴리스:
- https://godotengine.org/article/maintenance-release-godot-4-7-2/
- https://godotengine.org/download/archive/

4.8은 2026-09-22 기준 개발 스냅샷 단계이므로 Vertical Slice는 안정 릴리스인 4.7.2에 고정한다.

---

# 2. 왜 Godot + GDScript인가

THE ROOT의 핵심은:
- 복잡한 3D 물리보다 UI/카드 인터랙션
- 데이터 기반 문제 생성
- 빠른 반복
- 애니메이션/사운드/화면 전환
- PC→모바일 확장

따라서 Godot Control UI와 GDScript가 Vertical Slice 속도에 유리하다.

초기 버전에서 C#을 도입할 이유는 없다. 성능 병목이 실제로 확인된 후 필요한 부분만 검토한다.

---

# 3. 개발 환경

```text
Engine          Godot 4.7.2 stable
Language        GDScript
IDE             Godot Script Editor 또는 VS Code
VCS             Git + GitHub
Large Assets    Git LFS
Primary OS      Windows
Data Authoring  Excel + SQLite
Runtime Data    JSON 우선
Save            JSON/ConfigFile 우선, SQLite는 확장 선택지
```

## Git LFS 대상
- PNG/WEBP 원화
- 고용량 사운드
- 음악
- 영상
- 대용량 원본 PSD/Blender 파일을 저장한다면 해당 파일

JSON/GDScript/scene 파일은 일반 Git으로 관리한다.

---

# 4. 데이터 파이프라인

권장 구조:

```text
외부 권위 데이터
NCBI / Kew / PubChem / NASA / Mindat / etc.
        ↓
THE ROOT Canon 편집 데이터
Excel / SQLite
        ↓
Validation
        ↓
Runtime Export
JSON 또는 Godot Resource
        ↓
Godot
```

중요:
**Godot 게임 코드가 Authoring RDB에 직접 의존하지 않게 한다.**

Vertical Slice에서는:
`THE_ROOT_Vertical_Slice_DevData_v0.2.json`

을 런타임 source of truth로 사용하는 것이 가장 단순하다.

SQLite는:
- Canon 편집
- 데이터 검수
- 질의
- 대량 콘텐츠 관리

에 적합하고, 실제 카드 플레이는 export된 JSON을 메모리에 읽어 사용하는 구조를 권장한다.

---

# 5. Canon DB와 Save 분리

향후 SQLite를 직접 사용할 경우 두 DB를 분리한다.

```text
canon.db
- 읽기 중심
- 게임 콘텐츠
- 버전 관리
- Master Tree
- Entity
- Attribute
- Distractor
- Observation

save.db
- 플레이어 변경 데이터
- Cycle
- 문제 로그
- Inventory
- Equipment
- Mastery
- Branch progress
- Hard Mode mapping
```

Canon 업데이트가 플레이어 저장 데이터를 덮어쓰지 않도록 분리한다.

---

# 6. 권장 프로젝트 폴더

```text
the_root/
├─ project.godot
├─ assets/
│  ├─ cards/
│  ├─ backgrounds/
│  ├─ icons/
│  ├─ items/
│  ├─ particles/
│  ├─ music/
│  └─ sfx/
│
├─ data/
│  ├─ the_root_v0.2.json
│  └─ localization/
│
├─ scenes/
│  ├─ bootstrap/
│  │  └─ bootstrap.tscn
│  ├─ title/
│  │  └─ title.tscn
│  ├─ gameplay/
│  │  ├─ gameplay.tscn
│  │  ├─ entity_card.tscn
│  │  ├─ choice_panel.tscn
│  │  └─ hud.tscn
│  ├─ shop/
│  │  └─ shop.tscn
│  ├─ inventory/
│  │  └─ inventory.tscn
│  ├─ result/
│  │  └─ cycle_result.tscn
│  ├─ ending/
│  │  ├─ restored_ending.tscn
│  │  └─ overflow.tscn
│  └─ hardmode/
│     └─ teaser.tscn
│
├─ scripts/
│  ├─ core/
│  │  ├─ game_state.gd
│  │  ├─ event_bus.gd
│  │  ├─ data_repository.gd
│  │  └─ save_manager.gd
│  ├─ gameplay/
│  │  ├─ classification_system.gd
│  │  ├─ question_generator.gd
│  │  ├─ score_system.gd
│  │  ├─ order_chaos_system.gd
│  │  ├─ cycle_system.gd
│  │  ├─ streak_system.gd
│  │  └─ observation_system.gd
│  ├─ economy/
│  │  ├─ inventory_system.gd
│  │  ├─ equipment_system.gd
│  │  ├─ mastery_system.gd
│  │  ├─ reward_system.gd
│  │  └─ shop_system.gd
│  ├─ ending/
│  │  └─ overflow_system.gd
│  └─ hardmode/
│     ├─ similarity_system.gd
│     └─ attribute_mapping_system.gd
│
└─ tests/
   ├─ test_question_generation.gd
   ├─ test_scoring.gd
   ├─ test_shop.gd
   └─ test_save_migration.gd
```

---

# 7. Autoload / Singleton

Vertical Slice 권장 Autoload:

## `GameState`
현재 게임 진행 상태.
- current_cycle
- remaining_time
- order
- chaos
- score
- streak
- current_entity_id
- current_depth
- equipped_items
- run_id

## `DataRepository`
JSON 로드와 조회.
- get_entity(id)
- get_question_step(entity_id, depth)
- get_item(id)
- get_balance(key)
- get_cycle_sequence(cycle)

## `SaveManager`
저장/불러오기.
- profile
- inventory
- mastery
- cycle results
- event logs

## `EventBus`
시스템 결합도를 낮추기 위한 signal 허브.

예:
```text
entity_started
choice_submitted
choice_resolved
observe_used
entity_completed
entity_failed
cycle_completed
shop_opened
item_purchased
item_upgraded
overflow_started
```

---

# 8. UI 구현 원칙

Godot `Control` 계열을 기본으로 한다.

- Anchor/Container 중심
- 픽셀 좌표 하드코딩 최소화
- PC 마우스/키보드와 모바일 터치를 동일한 action으로 추상화
- 16:9 기준으로 구성하되 safe area 대응
- 카드 드래그는 InputEvent를 gameplay command로 변환

입력 예:

```text
ui_left / swipe_left
→ choose_left()

ui_right / swipe_right
→ choose_right()

observe
→ use_observe()

lock
→ lock_classification()

skip
→ skip_entity()
```

---

# 9. 상태 머신

한 개체:

```text
ENTITY_ENTER
  ↓
QUESTION_READY
  ↓
PLAYER_DECISION
  ├─ GUESS
  ├─ OBSERVE
  ├─ LOCK
  └─ SKIP
  ↓
RESOLVE
  ├─ NEXT_DEPTH
  ├─ COMPLETE
  └─ FAIL
  ↓
ENTITY_EXIT
```

Cycle:

```text
CYCLE_START
→ CARD_LOOP
→ TIME_EXPIRED or CARD_LIMIT
→ RESULT
→ REWARD
→ SHOP
→ NEXT_CYCLE
```

Vertical Slice 전체:

```text
TITLE
→ CYCLE_1
→ RESULT_1
→ SHOP_1
→ CYCLE_2
→ RESULT_2
→ WORLD_RESTORED
→ CREDIT_BONUS
→ OVERFLOW
→ HARD_MODE_TEASER
→ END
```

---

# 10. 질문 생성

`QuestionGenerator`는 직접 분류 규칙을 계산하지 않는다.

Runtime JSON의:
- entity.path
- entity.steps
- correct_category_id
- distractor_category_id
- cycle start_depth

를 그대로 사용한다.

Vertical Slice에서는 **정답/오답을 데이터에서 고정**한다.

정식 게임에서 동적 Distractor generation을 추가하더라도 승인된 후보군에서만 선택해야 한다.

---

# 11. 점수 계산 순서

권장 계산 순서:

```text
1. Depth 점수 누적
2. Complete Bonus
3. Field Notes 보정
4. OBSERVE 패널티
5. Fast Bonus
6. Streak 보너스
7. 최종 Card Score 확정
```

오답:
```text
current_card_score × 0.5
CHAOS + equipment-adjusted wrong chaos
streak = 0
```

SKIP:
```text
card_score = 0
time -= equipment-adjusted skip penalty
chaos += equipment-adjusted skip chaos
streak = 0
```

정확한 연산 순서는 구현 후 바꾸지 않도록 테스트 코드로 고정한다.

---

# 12. 상점 생성

Pseudo flow:

```text
open_shop():
    carry held_slot
    generate 5 - held_count slots

    if first_shop:
        force one enhanced equipment (+1 70% / +2 30%)

    for remaining slot:
        choose slot archetype
        choose product type
        if equipment:
            select non-duplicate item_id
            roll enhancement level
            calculate shop price
```

수동 Refresh:
- HOLD 상품 유지
- 나머지 슬롯만 재생성
- 비용 50/100/200/400
- 4회 후 비활성화

---

# 13. 저장 데이터

Vertical Slice부터 저장해야 하는 최소 필드:

```text
player_profile
inventory
equipment_levels
equipment_mastery
held_shop_item
currency
materials
cycle_index
branch_progress
```

문제 로그:

```text
run_id
entity_id
depth
start_depth
left_category_id
right_category_id
chosen_category_id
correct_category_id
correct
response_ms
observe_used
skip_used
locked_depth
score_gained
chaos_gained
streak_before
streak_after
equipped_item_ids
timestamp
```

이 로그는 단순 분석용이 아니라 Hard Mode 개인화 입력이다.

---

# 14. Overflow 구현

보너스 엔딩에서 표시값은 signed 32-bit overflow를 연출한다.

실제 내부 전체 점수 저장을 int32에 의존할 필요는 없다.

권장:
- 실제 저장: 64-bit 정수
- 연출용 `display_order_int32`
- `2,147,483,647 → -2,147,483,648`을 명시적으로 재현

즉 실제 버그를 만드는 것이 아니라 **버그처럼 보이는 결정론적 연출**로 구현한다.

---

# 15. 모바일 호환

처음부터:
- 입력 action 추상화
- 터치 드래그 지원
- UI safe area
- 16:9 기반 반응형 Control
- 작은 텍스트 최소화
- hover에만 의존하는 정보 금지

Windows에서 플레이감이 확정된 뒤 Android export를 붙인다.

---

# 16. 테스트 우선순위

자동 테스트가 특히 필요한 부분:
1. 한 개체의 정답 경로
2. start_depth 적용
3. Complete Bonus
4. Observe -30%
5. 오답 -50%
6. 장비 효과
7. 강화 수치
8. Shop level probability 합계=100
9. 첫 상점 +1/+2 보장
10. HOLD 유지
11. Refresh 비용/횟수
12. Save/load 후 Mastery 보존
13. Overflow sequence

플레이테스트가 필요한 부분:
- 스와이프 감각
- 카드 이동 속도
- 효과음
- 5분 체감
- Hint 문장 길이
- 점수 숫자의 만족감
- 난이도 곡선

---

# 17. 버전 고정 원칙

Vertical Slice 제작 시작 시:
- Godot 버전 고정
- JSON schema version 고정
- Canon version 고정
- Save version 명시

예:
```text
game_version   0.1.0-vs
godot_version  4.7.2
canon_version  0.2
data_version   0.2
save_version   1
```

개발 중 Canon 데이터가 바뀌면 데이터 버전만 올리고 Save migration 필요 여부를 기록한다.
