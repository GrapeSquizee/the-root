# 공개 본문에서 확인한 규칙

출처: https://chatgpt.com/share/6ab717a7-9f94-83ee-889f-ffa830295c6a

아래는 공개 대화의 요약이다. 첨부파일 원문이나 전체 과거 대화의 복원본이 아니다.

## 상점

- 진열 5칸. Cycle 종료 시 랜덤 갱신.
- HOLD 1칸. 구매하거나 직접 해제하기 전까지 다음 갱신에도 유지.
- 수동 새로고침 비용: 50 → 100 → 200 → 400. 다음 Cycle에서 초기화.
- 첫 상점에는 +1 또는 +2 강화 장비를 최소 1개 보장.
- 두 번째 상점부터 강화 단계 확률: +0 45%, +1 30%, +2 15%, +3 8%, +4 2%. +5는 상점에 등장하지 않음.
- 강화 완제품 가격은 직접 강화 총비용보다 약 15~30% 높음.
- 구매한 강화 장비도 Mastery는 0에서 시작.

첫 상점 예시: Cracked Lens +1 450, Old Hourglass +0 300, Glass Shard ×3 150, Copper Coil ×2 120, Faded Ink ×2 100. 희귀 재고 예시: Precision Lens +4 1,480. 예시 가격을 최종 확정값으로 보지 않는다.

## 확정과 가안

공개 응답은 다음을 LOCKED로 표시했다고 설명한다: +5, 강화 실패 없음, 보통 파밍, 숙련도 진화, 랜덤 상점, HOLD 1칸, 새로고침 비용 수열, 첫 상점 강화품 보장. 여기서 +5의 자세한 적용 규칙은 원문 확인이 필요하다.

장비별 가격, 강화 비용, 재료 단가, Cycle 보상량, Hard Mode 진화 재화 600은 BALANCE_V0.2 또는 PROVISIONAL이라고 설명한다.

## 개발 범위

- 30개체 정답 데이터와 D1~D6.
- Master Tree, Canon Path, Distractor, Observe/Lock/Skip.
- Cycle, Depth, 점수, Overflow, Hard Mode.
- 장비·재료·강화·숙련도·상점.
- 제안된 첫 플레이 빌드: 고양이 → 물 → 오리너구리 3장.
- 문서에 명시했다고 설명한 기술: Godot 4.7.2, GDScript, Git/LFS, JSON/SQLite 역할 분리.

Godot 4.7.2 릴리스의 존재는 공식 페이지에서 별도로 확인했다. 이 확인은 원본 기술 문서의 품질이나 현재 최신 버전 여부를 검증한 것은 아니다.

공식 출처: https://godotengine.org/article/maintenance-release-godot-4-7-2/
