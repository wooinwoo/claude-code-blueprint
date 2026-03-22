# CCB 수정 가이드

수정할 때 뭘 건드려야 하고, 뭘 건드리면 안 되는지. 부작용 체크리스트.

---

## 수정하면 안 되는 것

| 경로 | 이유 | 대안 |
|------|------|------|
| `base/` 내부 파일 | sync.ps1이 덮어씀 | common/ 또는 stack/에서 override |
| `base/_excluded/` | 참조용 보관. 건드릴 필요 없음 | exclude.json 수정 |

---

## 수정 시 영향 범위 맵

### 룰 수정

| 수정 대상 | 영향 범위 | 재설치 필요 |
|-----------|-----------|------------|
| `common/rules/*.md` | 모든 프로필 | O (setup.ps1) |
| `react-next/rules/*.md` | react-next + fullstack | O |
| `nestjs/rules/*.md` | nestjs + fullstack | O |
| `designer/rules/*.md` | designer만 | O |
| `planner/rules/*.md` | planner만 | O |
| `fullstack/rules/*.md` | fullstack만 | O |

### 에이전트 수정

| 수정 대상 | 영향 범위 |
|-----------|-----------|
| `base/agents/*.md` | 모든 dev + fullstack |
| `react-next/agents/*.md` | react-next만 |
| `nestjs/agents/*.md` | nestjs만 |
| `fullstack/agents/*.md` | fullstack만 |

**주의: fullstack의 에이전트는 react-next + nestjs에서 복사한 것.**
원본(react-next, nestjs)을 수정해도 fullstack에는 반영 안 됨.
fullstack 에이전트를 별도로 수정하거나, 원본 수정 후 fullstack에도 복사해야 함.

### 커맨드 수정

| 수정 대상 | 영향 범위 | 비고 |
|-----------|-----------|------|
| `common/commands/*.md` | dev 전체 + non-dev 유틸 3개 | non-dev는 commit, jira, guide만 |
| `react-next/commands/orchestrate.md` | react-next만 | fullstack은 별도 orchestrate |
| `fullstack/commands/orchestrate.md` | fullstack만 | react-next와 독립 |

### setup.ps1 수정

**가장 주의가 필요한 파일.**

| 수정 위치 | 영향 | 체크리스트 |
|-----------|------|-----------|
| ValidateSet (22줄) | 프로필 추가/삭제 | DevStacks 배열(42줄)도 같이 수정 |
| `$nonDevBaseRulesAllow` (119줄) | non-dev에 설치되는 base 룰 | 추가 시 토큰 비용 증가 |
| `$nonDevBaseSkillsAllow` (202줄) | non-dev에 설치되는 base 스킬 | 추가 시 토큰 비용 증가 |
| `$nonDevCommonCmdsAllow` (184줄) | non-dev에 설치되는 common 커맨드 | 개발 전용 커맨드 넣지 않도록 주의 |
| Copy-LayerDir Sources | 어떤 폴더가 어디로 복사되는지 | 경로 오타 시 설치 실패 |

### settings.json 수정

| 파일 | 영향 | 주의 |
|------|------|------|
| `common/settings.json` | dev 프로필 신규 설치 | **기존 프로젝트에는 반영 안 됨** (있으면 SKIP) |
| `designer/settings.json` | designer 신규 설치 | 동일 |
| `planner/settings.json` | planner 신규 설치 | 동일 |

기존 프로젝트에 permissions 변경을 반영하려면:
1. 해당 프로젝트의 `.claude/settings.json` 직접 편집
2. 또는 삭제 후 setup.ps1 재실행 (기존 커스터마이징 날아감)

---

## 새 프로필 추가하는 법

1. 폴더 생성: `새프로필/agents/`, `새프로필/commands/`, `새프로필/rules/`, `새프로필/skills/`
2. `setup.ps1` 수정:
   - ValidateSet에 프로필명 추가 (22줄)
   - dev면 `$DevStacks` 배열에 추가 (42줄)
   - non-dev면 non-dev 분기에 자동으로 탐
3. `새프로필/settings.json` 생성 (non-dev면 continuous-learning hooks 빼기)
4. `새프로필/mcp-configs/.mcp.json` 생성
5. `새프로필/hooks/hooks.json` 생성 (필요 시)
6. README.md 프로필 테이블에 추가

### 새 프로필 체크리스트

- [ ] 폴더 구조 생성
- [ ] setup.ps1 ValidateSet + DevStacks 수정
- [ ] settings.json에 continuous-learning hooks 여부 확인 (non-dev면 빼기)
- [ ] settings.json에 enabledPlugins 추가 (LSP 등)
- [ ] MCP 서버 설정 (불필요한 서버 제거)
- [ ] README.md 업데이트
- [ ] CLAUDE.md 인벤토리 업데이트
- [ ] 테스트 설치 (빈 폴더에 setup.ps1 돌려보기)

---

## 새 커맨드 추가하는 법

1. 해당 프로필의 `commands/` 폴더에 `.md` 파일 생성
2. frontmatter에 `description` 필수
3. `disable-model-invocation: true` 넣을지 결정 (부수효과 있으면 넣기)
4. 모든 프로필에 적용하려면 `common/commands/`에

### 커맨드가 에이전트를 참조하면

- 에이전트 파일이 해당 프로필의 `agents/`에 있는지 확인
- 이름 정확히 매칭 (파일명에서 `.md` 뺀 것 = 에이전트 이름)
- 에이전트의 tools, model이 커맨드 의도에 맞는지 확인

### 커맨드가 MCP 도구를 참조하면

- `.mcp.json`에 해당 서버가 있는지 확인
- 서버가 없을 때의 폴백 로직 필수 (try/catch 또는 조건 분기)
- 특히 Jira — 모든 `mcp__jira__*` 호출에 try/catch + 수동 입력 폴백

---

## 새 에이전트 추가하는 법

1. 해당 프로필의 `agents/` 폴더에 `.md` 파일 생성
2. frontmatter 필수: `name`, `description`, `model`, `tools`
3. "검토하지 않는 것" 섹션 필수 — 다른 에이전트와 역할 중복 방지
4. 출력 형식 명시 — 심각도 테이블 등

### 모델 선택 가이드

| 모델 | 용도 | 비용 |
|------|------|------|
| `opus` | 아키텍처 설계, 전략 분석 | 높음 |
| `sonnet` | 코드 리뷰, 구현, 일반 분석 | 중간 |
| `haiku` | 문서 작성, 코드 탐색, 빠른 작업 | 낮음 |

---

## 문제 해결

### "커맨드가 /에 안 뜸"

1. `.claude/commands/` 또는 `.claude/skills/`에 파일 있는지 확인
2. frontmatter `description`이 있는지 확인
3. `user-invocable: false`가 아닌지 확인
4. Claude Code 재시작

### "에이전트가 안 불림"

1. `.claude/agents/`에 파일 있는지 확인
2. frontmatter `name`이 커맨드에서 참조하는 이름과 일치하는지 확인
3. `tools`에 필요한 도구가 있는지 확인

### "권한 때문에 멈춤"

1. `.claude/settings.json`의 `allow` 목록 확인
2. 걸리는 명령어 추가: `"Bash(명령어:*)"` 형식
3. 현재 allow 목록: 80개 명령어 (curl, grep, sed 등 셸 유틸 포함)

### "설정 변경이 안 먹힘"

settings.json은 **기존 파일이 있으면 setup.ps1이 안 건드림**.
기존 프로젝트에 반영하려면:
1. 해당 프로젝트 `.claude/settings.json` 직접 편집
2. 또는 삭제 후 setup.ps1 재실행

### "Non-dev에 개발 도구가 깔림"

setup.ps1의 허용 목록 확인:
- `$nonDevBaseRulesAllow` — base 룰 중 non-dev에 허용할 것
- `$nonDevBaseSkillsAllow` — base 스킬 중 non-dev에 허용할 것
- `$nonDevCommonCmdsAllow` — common 커맨드 중 non-dev에 허용할 것
