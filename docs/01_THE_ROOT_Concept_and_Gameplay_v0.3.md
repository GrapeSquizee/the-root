# THE ROOT — Concept & Gameplay Specification
## Vertical Slice 기준 통합 기획서 v0.3

> 이 문서는 THE ROOT의 **게임 콘셉트, 플레이 감정선, 본편/엔딩/Hard Mode 구조와 Vertical Slice 규칙**을 한 곳에 정리한 기준 문서다.  
> 데이터 상세값은 `03_THE_ROOT_Dataset_Spec_v0.3.md`와 `THE_ROOT_Vertical_Slice_DevData_v0.2.xlsx/json`을 기준으로 한다.

---

# 1. 프로젝트 정체성

## 제목
**THE ROOT**

## 장르
- 카드 선택형 분류 퍼즐
- 지식 기반 Push-your-luck
- 성장 / 장비 빌드
- Master Tree 복원
- SF 미스터리
- 2회차형 Hard Mode
- 개인화 역분류 퍼즐

## 핵심 한 줄
**혼돈으로 가득 찬 세계에서 모든 존재를 올바른 카테고리에 분류해 질서를 복원하고, 끝내 모든 분류의 근원인 THE ROOT를 찾아가는 게임.**

## 핵심 플레이 문장
**제한된 시간과 제한된 정보 속에서, 어디까지 확신을 가지고 깊이 들어갈 것인가.**

---

# 2. 세계관의 핵심

## 2.1 CHAOS와 ORDER
세계는 모든 것이 존재하지만 관계와 분류가 무너진 **CHAOS** 상태에서 시작한다.

플레이어가 올바르게 분류하면:
- ORDER 상승
- Master Tree 복원
- 세계의 색과 구조 회복
- 음악과 배경이 안정화

잘못 분류하면:
- CHAOS 상승
- 개체와 환경에 작은 모순/왜곡 발생
- 세계가 시각·음향적으로 불안정해짐

오답은 단순한 X가 아니라 **세계에 잘못된 질서를 주입한 결과**로 표현한다.

## 2.2 플레이어의 위치
플레이어 캐릭터/아바타는 없다.  
플레이어는 세계 밖에서 개체를 관찰하고 분류하는 **신적 관찰자**처럼 기능하지만, 게임은 이를 직접 설명하지 않는다.

## 2.3 정답은 이미 존재한다
본편에서 플레이어가 카테고리를 만드는 것이 아니다.

개발자가 미리 구축한 완전한 정답 체계:
**Master Tree / THE ROOT Canon**

이 존재하며 모든 본편 문제에는 개발자가 고정한 정답이 있다.

따라서 본편에서는:
- `CANONICAL`: 사용 가능
- `DISPUTED`: 일반 문제에서 제외
- `SUBJECTIVE`: 일반 문제에서 제외

과학적/철학적으로 논쟁적인 대상은 THE ROOT Canon에서 명시적으로 결정하지 않는 한 일반 카드로 사용하지 않는다.

---

# 3. Master Tree

Vertical Slice의 기본 상위 구조:

```text
THE ROOT
└─ PHYSICAL
   ├─ LIVING
   │  ├─ ANIMAL
   │  ├─ PLANT
   │  ├─ FUNGI
   │  └─ BACTERIA
   │
   └─ NON-LIVING
      ├─ MATTER
      ├─ ASTRONOMICAL OBJECT
      └─ ARTIFACT
```

실제 학술 계통은 훨씬 깊지만 게임에서는 의미 있는 노드를 골라 **최대 D6의 게임 Canon으로 압축**한다.

D1의 `PHYSICAL / ABSTRACT`는 향후 추상개념 확장을 위한 ROOT 레벨이다. Vertical Slice 30개체는 모두 Physical이므로, 반복감을 줄이기 위해 카드별 `start_depth`로 이미 확인한 상위 분류를 건너뛴다.

---

# 4. 본편 핵심 플레이

화면 중앙에 개체 카드 1장이 나타난다.

플레이어는 Reigns처럼 좌/우 선택으로 두 카테고리 중 하나를 고른다.

PC:
- 마우스 드래그
- 좌/우 방향키

모바일:
- 가로 화면
- 좌/우 스와이프

한 카드는 한 번의 선택으로 끝나지 않는다. 정답을 맞힐수록 하위 Depth로 내려간다.

예:

```text
큰돌고래
D1 PHYSICAL
D2 LIVING
D3 ANIMAL
D4 CHORDATE
D5 MAMMAL
D6 CETACEA
```

각 Depth에서 플레이어는 다음 판단을 한다.

### GUESS / CONTINUE
다음 정답을 직접 선택하고 더 깊게 진행한다.

### OBSERVE
힌트 1개를 본다.  
개체당 **1회만 사용 가능**, 해당 개체 최종 획득점수 **-30%**.

### LOCK / CLASSIFY
현재까지 맞힌 Depth에서 분류를 확정하고 점수를 확보한다. 더 깊은 보너스는 포기한다.

### SKIP
현재 개체를 포기한다.
- 카드 점수 0
- STREAK RESET
- Cycle 시간 -5초
- CHAOS +2

---

# 5. Vertical Slice 확정 규칙

## 5.1 한 판
- Cycle 1: 5분
- 상점/강화
- Cycle 2: 5분
- 엔딩/Overflow/Hard Mode teaser

순수 플레이 약 10분, 상점과 연출 포함 약 15분 전후를 목표로 한다.

## 5.2 카드 수
- Cycle당 최대 20개체
- Vertical Slice Master Pool: 30개체
- 시간이 먼저 끝나면 미처리 카드는 종료
- 모든 카드가 D6일 필요는 없음
- 개체별 Max Depth: D4~D6

## 5.3 난이도 곡선
선택한 곡선: **B**

```text
쉬운 카드
→ 익숙하지만 한 단계 고민
→ 직관을 배신하는 카드
→ 생소하지만 명확한 정답이 있는 카드
```

전문용어 암기만으로 어렵게 만드는 것이 아니라, **겉모습/상식과 실제 분류의 충돌**을 주요 난이도로 사용한다.

대표 카드:
- 황제펭귄: 날지 못하지만 조류
- 박쥐: 날지만 포유류
- 큰돌고래/듀공: 물속 생활 vs 포유류
- 오리너구리: 알을 낳지만 포유류
- 돌산호: 식물처럼 보이지만 동물
- 빵효모: 버섯 형태가 아니지만 균류
- 대장균: 동물/식물/균류가 아닌 Bacteria
- 다이아몬드: 탄소로 이루어졌지만 게임 개체로서는 광물

---

# 6. 점수

## Depth 기본 점수

| Depth | 점수 |
|---|---:|
| D1 | 10 |
| D2 | 15 |
| D3 | 25 |
| D4 | 40 |
| D5 | 70 |
| D6 | 120 |

## 완주 보너스
낮은 Depth 개체도 마지막 단계까지 맞히면 보너스를 받는다.

기본값:
- Max D4: +80
- Max D5: +100
- Max D6: +120

추가 난이도 보정:
`(difficulty - 1) × 10`

따라서 깊이 자체보다 **자기 개체의 Canon 끝까지 완주했다는 것**을 보상한다.

## 오답
- 현재 카드 누적점수 -50%
- CHAOS +5
- STREAK RESET
- 이미 맞힌 상위 분류 기록은 유지

깊게 들어간 플레이어가 한 번 틀렸다고 전체를 잃게 하지 않는다.

## 빠른 완주
- 3초 이내 완주: +50%
- 5초 이내 완주: +25%
- 그 이후 추가 페널티 없음

장비 `Hourglass`는 이 보너스 판정 시간을 늘린다.

---

# 7. Cycle 1 / Cycle 2의 감정선

## Cycle 1 — 규칙 학습과 첫 번째 배신
목표 감정:
**“쉽네” → “생각해야 하네” → “생각보다 만만하지 않다.”**

순서:

1. 고양이
2. 물
3. 해바라기
4. 금
5. 검독수리
6. 망치
7. 달
8. 철
9. 서양꿀벌
10. 스마트폰
11. 황제펭귄
12. 거미
13. 참문어
14. 큰돌고래
15. 표고버섯
16. 작은갈색박쥐
17. 돌산호
18. 오리너구리
19. 듀공
20. 혹등아귀

초반 10개는 속도를 붙이고, 후반의 박쥐/돌산호/오리너구리/듀공/혹등아귀에서 OBSERVE와 LOCK 판단을 유도한다.

## Cycle 2 — 배운 것을 다시 사용
목표 감정:
**“아까 배운 것이 다시 나온다” + “새 Branch가 열린다.”**

순서:

1. 얼음
2. 소금
3. 석영
4. 지구
5. 이끼
6. 빵효모
7. 백상아리
8. 다이아몬드
9. 태양
10. 대장균
11. 황제펭귄
12. 큰돌고래
13. 작은갈색박쥐
14. 돌산호
15. 오리너구리
16. 듀공
17. 혹등아귀
18. 참문어
19. 서양꿀벌
20. 표고버섯

Cycle 1에서 등장한 일부 개체는 D4~D5부터 재출제한다.

예:
```text
Cycle 1: BAT → 상위 분류부터 학습
Cycle 2: BAT → MAMMAL / BIRD 부근부터 재시험
```

---

# 8. 장비 / 성장

장착 슬롯: **3개**

장비:
1. Taxonomic Lens — OBSERVE 패널티 감소
2. Old Hourglass — Fast Bonus 판정시간 증가
3. Bookmark — SKIP 패널티 감소
4. Stabilizer — 오답 CHAOS 감소
5. Field Notes — COMPLETE BONUS 증가

강화:
- +0 ~ +5
- +5 = 본편 MAX
- 강화 실패 없음
- 화폐 + 전용 재료 사용
- +4→+5에는 Unknown Fragment 필요

재료:
- Glass Shard
- Broken Gear
- Faded Ink
- Copper Coil
- Unknown Fragment

재료 파밍 강도: **보통**

---

# 9. 랜덤 상점

Cycle 종료 후 **5칸 랜덤 진열**.

## HOLD
- 동시에 1개 상품 HOLD 가능
- HOLD 상품은 수동 새로고침과 다음 Cycle 자동 갱신에서도 유지
- 구매 또는 HOLD 해제 시 슬롯 반환

## 수동 새로고침
한 상점에서 최대 4회:
1. 50
2. 100
3. 200
4. 400

다음 Cycle에서 비용/횟수 초기화.

## 강화 장비
일반 상점에서 장비가 생성되었을 때 강화 확률:

| 강화 | 확률 |
|---|---:|
| +0 | 45% |
| +1 | 30% |
| +2 | 15% |
| +3 | 8% |
| +4 | 2% |
| +5 | 0% |

**첫 상점만 +1 또는 +2 장비를 최소 1개 보장**한다.
- +1: 70%
- +2: 30%

이는 Vertical Slice에서 플레이어가 강화 완제품 시스템을 반드시 경험하게 하기 위한 보정이다.

강화 완제품은 직접 강화보다 비싸지만 재료와 시간을 건너뛸 수 있다.  
좋은 +3/+4 장비를 보고 재화를 모으거나 HOLD하는 행동을 유도한다.

상점에서 강화 장비를 구매해도 Mastery는 0부터 시작한다.

---

# 10. 아이템 Mastery와 Hard Mode 진화

본편 MAX 장비는 Hard Mode에서 바로 진화하지 않는다.

진화 조건:
1. +5 MAX
2. 해당 장비 효과 사용 Mastery 충족
3. Terraforming Core Fragment ×3
4. Hard Mode 전용 재화

Mastery는 장착만 해서는 오르지 않고 **효과가 실제 발동했을 때만** 증가한다.

| 장비 | Mastery |
|---|---:|
| Lens | OBSERVE 효과 12회 |
| Hourglass | Fast Bonus 발동 20회 |
| Bookmark | SKIP 효과 8회 |
| Stabilizer | 오답 완화 10회 |
| Field Notes | 장착 상태 완주 20회 |

정상적으로 장비를 사용하면 자연스럽게 채워지도록 설계하며, 숙련도만을 위한 별도 노가다를 요구하지 않는다.

진화:
- Taxonomic Lens → Biosphere Scanner
- Old Hourglass → Temporal Modeler
- Bookmark → Reconstruction Index
- Stabilizer → Planetary Stabilizer
- Field Notes → Genome Archive

---

# 11. 시각 / 음악

선택한 분위기 범위: **C — Vertical Slice에서 Overflow까지 경험**

## 초반
- 밝은 자연색
- 크림/녹색/금색
- 편안한 자연음과 잔잔한 악기
- Master Tree가 조금씩 자라남

## 중반
- 청록 / 남색 / 보라 비중 증가
- 리버브/신스 증가
- 카드와 Tree가 더 비현실적으로 보이기 시작

## 후반
- ORDER 100%에서 밝고 장엄하게 완성
- Bonus Classification부터 지나치게 완벽한 연출
- 숫자/글리치가 서서히 개입

---

# 12. 본편 엔딩과 Overflow

Master Tree가 완성되면:

```text
ORDER 100.000%
WORLD RESTORED
```

크레딧이 시작되지만 플레이는 끝나지 않는다.

크레딧 중 Bonus Classification:
- 큰 점수
- 큰 콤보
- ORDER 수치가 계속 증가
- 플레이어에게 승리의 카타르시스 제공

최종:

```text
2,147,483,647
+ 1
= -2,147,483,648
```

음악 정지.

```text
ORDER VALUE INVALID
ORDER 0%
CHAOS 100%
```

**완벽한 질서를 끝까지 밀어붙였더니 다시 완전한 혼돈이 된다.**

---

# 13. Hard Mode

본편:
`Entity → Category`

Hard Mode:
`Attribute → Entity`

ORDER / CHAOS UI는 사라지고 처음에는 단 하나만 보인다.

```text
SIMILARITY
```

본편 플레이 로그를 이용해 개인화한다.
- 틀린 개체
- 어려워한 Depth
- OBSERVE 사용
- SKIP
- 반응 시간
- 수정 기록
- Branch mastery

Hard Mode는 플레이어가 약했던 Attribute/Entity 관계를 더 자주 활용한다.

## 오답의 의미
Hard Mode의 오답은 단순 실패가 아니다.

예:
- 고래 + 아가미
- 곤충 + 8개의 다리
- 보라색 광합성 식물

잘못 연결한 속성은 **새 행성에서 일관된 대체 생물학**이 된다.

따라서 플레이어마다 다른 행성이 만들어질 수 있다.

---

# 14. Hard Mode 최종 반전

플레이어는 자신이 Overflow로 파괴된 지구를 복구한다고 생각한다.

하지만 실제로는:
**본편에서 수집한 분류 데이터를 이용해 새로운 지구 모델을 생성하고 있었다.**

최종:

```text
EARTH SIMILARITY 97.381%

EARTH MODEL COMPLETE.
HABITAT #02 READY.
```

왜 HABITAT #02가 필요한지, 시스템을 만든 존재가 누구인지는 당장 설명하지 않는다.

---

# 15. Vertical Slice 종료 연출

Vertical Slice는 Hard Mode 전체를 구현하지 않는다.

Overflow 이후 첫 번째 역분류 문제까지만 보여준다.

예:

```text
ATTRIBUTE
Warm-blooded

DOLPHIN
SHARK
PENGUIN
WHALE
```

선택 후:

```text
SIMILARITY 0.014%
```

멀리 작은 행성이 나타난다.

```text
THE ROOT
END OF VERTICAL SLICE
```

---

# 16. Vertical Slice 범위

```text
Platform            Windows PC
Aspect              16:9 Landscape
Cycle               2
Cycle Time          5 min
Entities/Cycle      20
Master Pool         30
Max Depth           6
OBSERVE              1회 / -30%
LOCK                 포함
SKIP                 -5 sec / CHAOS +2
Wrong                Card -50% / CHAOS +5
Fast Bonus           3 sec +50%, 5 sec +25%
Streak               포함
ORDER / CHAOS        포함
Equipment Slots      3
Items                5
Materials            5
Upgrade              +0 ~ +5 데이터, VS에서 최소 1회 체험
Shop                 5칸 랜덤 / HOLD / Refresh
Ending               포함
Overflow             포함
Hard Mode            첫 puzzle teaser
Save / Logs          포함
```

---

# 17. 현재 디자인 원칙

1. 본편에는 항상 Canon 정답이 있다.
2. 분류가 어려운 이유는 억지 전문용어보다 **직관과 실제 구조의 충돌**이어야 한다.
3. 모든 개체를 억지로 D6까지 만들지 않는다.
4. 낮은 Max Depth도 Complete Bonus로 가치가 있다.
5. OBSERVE는 강력하지만 비싸다.
6. SKIP은 안전하지만 무료가 아니다.
7. 오답은 도전 의지를 죽일 만큼 가혹하지 않다.
8. 성장 요소는 분류 판단을 보조하지만 지식을 완전히 대체하지 않는다.
9. 상점은 소비처가 아니라 “지금 살 것인가, 좋은 매물을 기다릴 것인가”의 판단 공간이다.
10. Hard Mode는 본편 장비 투자를 완전히 버리지 않지만 새로운 성장축을 요구한다.
11. 시스템과 UI 자체가 서사를 전달하며 긴 설명문에 의존하지 않는다.

---

# 18. 아직 조정 가능한 항목

다음 값은 구현 후 플레이테스트에서 튜닝할 수 있다.
- Cycle 평균 화폐 보상
- 아이템 정확한 판매가
- 재료 드랍률
- Hard Mode 진화 전용 재화 비용
- 일부 Distractor 난이도
- 개체별 difficulty
- STREAK 배율
- ORDER/CHAOS 전체 진행량
- 최종 본편 규모

이 값은 Canon의 정답 구조와 별개로 `Balance/Config` 데이터에서 조정한다.
