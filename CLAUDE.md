@AGENTS.md
@docs/AGENTS.md

# Claude Code 메모

- 한국어 문서 검사는 `.claude/agents/korean-proofreader.md`의 `korean-proofreader` 에이전트를 쓴다. 등록된 에이전트를 고를 수 없으면 일반 하위 에이전트에게 `.codex/agents/korean-proofreader.toml`과 `.agents/skills/korean-proofreader/SKILL.md`를 읽게 한다.
- 위 `AGENTS.md`의 `korean_proofreader`는 이 에이전트(`korean-proofreader`)와 같은 역할이다.
- 같은 파일을 Codex와 동시에 고치지 않는다.
- 연재 제목은 「세상을 부수고 싶다고 했더니 분류부터 시켰다」이다. THE ROOT는 게임과 시스템 이름으로 유지한다.
- 소설 다듬기 에이전트: `story-improver`(지루한 지점에 사건 삽입, 떡밥 설계·회수, 원고 수정, `docs/17` 노트 관리), `character-vitality-reviewer`(인물 생동감 검토, 읽기 전용). 기준은 `docs/16_THE_ROOT_생동감_흥미_기준.md`(참고작 「전지적 독자 시점」에서 기법만 추출, 문장 인용 금지).
- 용어는 `docs/20_THE_ROOT_용어_정리.md`를 따른다(예: 게임 재화는 실타래, 서린의 직함은 매듭지기, 도시 복원사, 기록소). 새로 쓰거나 고칠 때 옛 용어를 쓰지 않는다.
