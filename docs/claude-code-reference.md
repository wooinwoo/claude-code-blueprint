# Claude Code 확장 포인트 전체 레퍼런스

> 공식 문서 기반 전수조사 (2026-03-17 기준)
> 출처: https://code.claude.com/docs/

---

## 파일/폴더 전체 맵

### 프로젝트 레벨

```
프로젝트/
├── CLAUDE.md                        프로젝트 지시 (항상 로드)
├── .mcp.json                        MCP 서버 설정
└── .claude/
    ├── CLAUDE.md                    CLAUDE.md의 대체 위치 (둘 중 하나)
    ├── rules/                       행동 규칙 (항상 로드)
    │   └── *.md
    ├── skills/                      /슬래시커맨드 + 지식
    │   └── <skill-name>/
    │       ├── SKILL.md             필수
    │       ├── reference.md         선택 (필요 시 로드)
    │       ├── examples/            선택
    │       └── scripts/             선택 (실행 가능)
    ├── commands/                    레거시 커맨드 (skills로 통합, 하위호환)
    │   └── *.md
    ├── agents/                      서브에이전트
    │   └── *.md
    ├── settings.json                권한 + hooks + 플러그인 + 모델 (팀 공유)
    └── settings.local.json          개인 설정 (gitignore)
```

### 유저 레벨

```
~/.claude/
├── CLAUDE.md                        개인 글로벌 지시
├── rules/                           개인 글로벌 규칙
├── skills/                          개인 글로벌 스킬
├── agents/                          개인 글로벌 에이전트
├── settings.json                    글로벌 설정
└── projects/<프로젝트>/memory/      Auto Memory
    └── MEMORY.md                    처음 200줄 매 세션 로드

~/.claude.json                       유저 레벨 MCP 서버 설정
```

### 관리 정책 레벨

| OS | 경로 |
|----|------|
| macOS | `/Library/Application Support/ClaudeCode/` |
| Linux/WSL | `/etc/claude-code/` |
| Windows | `C:\Program Files\ClaudeCode\` |

파일: `CLAUDE.md`, `managed-settings.json`, `managed-mcp.json`
→ 조직 전체 적용, 오버라이드 불가

---

## 로딩 타이밍

| 요소 | 로딩 시점 | 토큰 비용 |
|------|-----------|-----------|
| CLAUDE.md | 세션 시작 시 **전문** 로드 | 높음 |
| Rules | 세션 시작 시 **전문** 로드 (`paths` 있으면 조건부) | 높음 |
| Skills | **description만** 상시. 전문은 호출/자동 활성화 시 | 낮음 |
| Agents | 호출 시 **독립 컨텍스트** 생성 | 메인에 영향 없음 |
| Hooks | 이벤트 발생 시 **외부 프로세스** 실행 | 없음 |
| Settings | Claude Code 시작 시 읽음 | 없음 |
| MCP | 시작 시 서버 연결, **도구 description**만 로드 | 낮음 |

**원칙: 짧고 항상 적용 → Rules, 길고 가끔 필요 → Skills**

---

## 1. CLAUDE.md

### 위치와 우선순위

| 위치 | 적용 범위 | 우선순위 |
|------|-----------|----------|
| 관리 정책 경로 | 조직 전체 | 1 (최고, 오버라이드 불가) |
| `./CLAUDE.md` 또는 `./.claude/CLAUDE.md` | 이 프로젝트 | 2 |
| `~/.claude/CLAUDE.md` | 내 모든 프로젝트 | 3 (최저) |

- 상위 디렉토리 CLAUDE.md도 전부 로드됨
- 하위 디렉토리 CLAUDE.md는 해당 폴더 파일 작업 시 로드
- 200줄 이하 권장 (넘으면 준수율 저하)

### `@` 임포트

```markdown
@README.md
@docs/git-instructions.md
@~/.claude/my-project-instructions.md
```

- 상대 경로는 CLAUDE.md 기준
- 최대 5단계 재귀 임포트
- 첫 실행 시 승인 다이얼로그

### 모노레포 제외

```json
// settings.json
{ "claudeMdExcludes": ["**/other-team/CLAUDE.md"] }
```

### Auto Memory

- 위치: `~/.claude/projects/<프로젝트>/memory/`
- `MEMORY.md` 처음 200줄 매 세션 로드
- Claude가 알아서 학습 메모 작성
- `/memory` 명령으로 확인/편집
- `"autoMemoryEnabled": false`로 끄기 가능

### /init

- CLAUDE.md 없으면 자동 생성 (코드베이스 분석)
- 있으면 개선 사항 제안

---

## 2. Rules

### 위치와 우선순위

| 위치 | 적용 범위 |
|------|-----------|
| `~/.claude/rules/` | 내 모든 프로젝트 |
| `.claude/rules/` | 이 프로젝트 (Git 공유 가능) |
| `하위폴더/.claude/rules/` | 해당 폴더 내 파일 작업 시만 |

우선순위: 개인 < 프로젝트 < 하위폴더

### Frontmatter

```yaml
---
paths:
  - "src/components/**/*.tsx"
  - "tests/**/*.test.ts"
---
```

- `paths` 없으면: 항상 로드
- `paths` 있으면: 매칭 파일 작업 시만 로드

glob 패턴: `**/*.ts`, `src/**/*`, `*.{ts,tsx}`

### symlink 지원

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
```

순환 참조 자동 감지.

---

## 3. Skills (Commands 통합)

### Commands → Skills 통합

- `.claude/commands/deploy.md`와 `.claude/skills/deploy/SKILL.md` 둘 다 `/deploy`
- 같은 이름이면 Skills 우선
- commands/ 하위호환 유지
- 새로 만들 때는 Skills 권장

### 구조

```
.claude/skills/<skill-name>/
├── SKILL.md           필수
├── reference.md       선택 (필요 시 Read)
├── examples/          선택
└── scripts/           선택 (실행 가능)
```

### Frontmatter 전체

| 필드 | 필수 | 기본값 | 설명 |
|------|------|--------|------|
| `name` | X | 폴더명 | 소문자+하이픈, 최대 64자 |
| `description` | 권장 | 본문 첫 문단 | Claude 자동 활성화 판단에 사용 |
| `argument-hint` | X | - | 자동완성 힌트. `[issue-number]` |
| `disable-model-invocation` | X | false | true면 사용자만 호출 가능 |
| `user-invocable` | X | true | false면 /메뉴에서 숨김 |
| `allowed-tools` | X | 전체 | 사용 가능 도구 제한 |
| `model` | X | 상속 | sonnet, opus, haiku, 모델 ID |
| `context` | X | - | `fork`이면 서브에이전트 격리 실행 |
| `agent` | X | general-purpose | context:fork 시 에이전트 타입 |
| `hooks` | X | - | 스킬 라이프사이클 훅 |

### 호출 제어

| 설정 | 사용자 /호출 | Claude 자동 | 컨텍스트 |
|------|-------------|-------------|----------|
| (기본값) | O | O | description 상시, 전문은 호출 시 |
| `disable-model-invocation: true` | O | X | description 미로드, 전문은 사용자 호출 시 |
| `user-invocable: false` | X | O | description 상시, 전문은 호출 시 |

### 인수 — $ARGUMENTS

| 변수 | 설명 |
|------|------|
| `$ARGUMENTS` | 전체 인수 |
| `$ARGUMENTS[0]` 또는 `$0` | 첫 번째 인수 |
| `$ARGUMENTS[1]` 또는 `$1` | 두 번째 인수 |
| `${CLAUDE_SESSION_ID}` | 현재 세션 ID |
| `${CLAUDE_SKILL_DIR}` | SKILL.md가 있는 디렉토리 |

$ARGUMENTS가 스킬 내용에 없으면 자동으로 끝에 `ARGUMENTS: <값>` 추가

### 동적 컨텍스트 주입

`` !`셸 명령` `` → 스킬 로드 전에 실행, 결과가 삽입된 후 Claude에게 전달

```markdown
- PR diff: !`gh pr diff`
- 변경 파일: !`gh pr diff --name-only`
```

Claude는 명령 자체를 안 보고 결과만 봄. 도구 호출 턴 소비 없음.

### 위치와 우선순위

| 위치 | 우선순위 |
|------|----------|
| 관리 정책 | 1 (최고) |
| `~/.claude/skills/` | 2 |
| `.claude/skills/` | 3 |
| 플러그인 | 4 (최저) |

### 로딩 예산

- description들은 컨텍스트 윈도우의 ~2% 예산
- 스킬 많으면 일부 잘림
- `/context`로 확인, `SLASH_COMMAND_TOOL_CHAR_BUDGET` 환경변수로 조절

---

## 4. Agents (서브에이전트)

### 빌트인

| 에이전트 | 모델 | 도구 | 용도 |
|----------|------|------|------|
| Explore | Haiku | 읽기 전용 | 파일 탐색, 코드 검색 |
| Plan | 상속 | 읽기 전용 | Plan 모드 컨텍스트 수집 |
| general-purpose | 상속 | 전체 | 복잡한 멀티스텝 |

### 위치와 우선순위

| 위치 | 우선순위 |
|------|----------|
| `--agents` CLI 플래그 (JSON) | 1 (최고) |
| `.claude/agents/` | 2 (프로젝트) |
| `~/.claude/agents/` | 3 (개인) |
| 플러그인 agents/ | 4 (최저) |

### Frontmatter 전체

| 필드 | 필수 | 설명 |
|------|------|------|
| `name` | O | 고유 식별자 (소문자+하이픈) |
| `description` | O | Claude가 위임 판단에 사용 |
| `tools` | X | 사용 가능 도구 (생략하면 전체 상속) |
| `disallowedTools` | X | 차단 도구 |
| `model` | X | sonnet, opus, haiku, 모델 ID, inherit |
| `permissionMode` | X | default, acceptEdits, dontAsk, bypassPermissions, plan |
| `maxTurns` | X | 최대 에이전틱 턴 수 |
| `skills` | X | 시작 시 프리로드할 스킬 (전문 주입) |
| `mcpServers` | X | 이 에이전트에서만 사용할 MCP 서버 |
| `hooks` | X | 라이프사이클 훅 |
| `memory` | X | 영구 메모리: user, project, local |
| `background` | X | true면 항상 백그라운드 |
| `isolation` | X | worktree면 격리된 git worktree |

### Skills에서 호출

```yaml
# SKILL.md
---
context: fork
agent: security-reviewer
---
```

`context: fork` + `agent` 조합으로 스킬 실행 시 서브에이전트 위임.

### MCP 서버 격리

```yaml
---
mcpServers:
  - playwright:           # 인라인 정의 (이 에이전트에서만)
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
  - github               # 참조 (이미 설정된 서버 공유)
---
```

인라인 정의한 MCP 서버는 이 에이전트에서만 연결. 메인 대화에 안 보임.

### 영구 메모리

| 스코프 | 위치 | 용도 |
|--------|------|------|
| user | `~/.claude/agent-memory/<name>/` | 모든 프로젝트 학습 |
| project | `.claude/agent-memory/<name>/` | 이 프로젝트만 (Git 공유 가능) |
| local | `.claude/agent-memory-local/<name>/` | 이 프로젝트만 (Git 제외) |

### 포그라운드 vs 백그라운드

- 포그라운드: 블로킹. 권한 요청/질문이 사용자에게 전달
- 백그라운드: 병렬. 필요 권한 미리 요청, 미승인은 자동 거부
- `Ctrl+B`로 포그라운드 → 백그라운드 전환

### 제한사항

- 서브에이전트는 다른 서브에이전트를 생성할 수 없음
- 중첩 필요 시 메인 대화에서 체이닝

---

## 5. Hooks

### 정의 위치

| 위치 | 적용 범위 |
|------|-----------|
| `~/.claude/settings.json` | 모든 프로젝트 |
| `.claude/settings.json` | 이 프로젝트 (팀 공유) |
| `.claude/settings.local.json` | 이 프로젝트 (개인) |
| 스킬/에이전트 frontmatter | 해당 스킬/에이전트 활성 시만 |

### JSON 구조 (3단 중첩)

```json
{
  "hooks": {
    "이벤트명": [
      {
        "matcher": "정규식 패턴",
        "hooks": [
          {
            "type": "command|http|prompt|agent",
            "command": "실행할 명령",
            "timeout": 600
          }
        ]
      }
    ]
  }
}
```

### 4가지 핸들러 타입

| 타입 | 설명 | 필수 필드 |
|------|------|-----------|
| `command` | 셸 명령 실행 | `command`, (timeout, async, statusMessage) |
| `http` | HTTP POST | `url`, (headers, allowedEnvVars, timeout) |
| `prompt` | LLM 판단 요청 | `prompt`, (model, timeout) |
| `agent` | 서브에이전트 검증 | `prompt`, (timeout) |

### 24개 이벤트

| 이벤트 | matcher 대상 | 차단 가능 | 주요 용도 |
|--------|-------------|-----------|-----------|
| **PreToolUse** | 도구명 | O | 위험 명령 차단, 입력 수정 |
| **PostToolUse** | 도구명 | X | 결과 검증, 경고, 자동 포맷 |
| **PostToolUseFailure** | 도구명 | X | 실패 후 처리 |
| **PermissionRequest** | 도구명 | O | 권한 자동 판단 |
| **UserPromptSubmit** | - | O | 입력 검증, 컨텍스트 추가 |
| **Stop** | - | O | 최종 체크, 계속 지시 |
| **SubagentStart** | 에이전트명 | O | 초기화 |
| **SubagentStop** | 에이전트명 | O | 정리 |
| **SessionStart** | 세션 소스 | X | 환경 설정 |
| **SessionEnd** | 종료 사유 | X | 상태 저장 |
| **PreCompact** | 트리거 | X | 상태 저장 |
| **PostCompact** | 트리거 | X | 후처리 |
| **TaskCompleted** | - | O | 작업 완료 검증 |
| **TeammateIdle** | - | O | 팀 에이전트 관리 |
| **Notification** | 알림 타입 | X | 알림 처리 |
| **ConfigChange** | 설정 소스 | O | 설정 변경 감지 |
| **InstructionsLoaded** | - | X | 지시 파일 로드 추적 |
| **WorktreeCreate** | - | O | worktree 경로 반환 |
| **WorktreeRemove** | - | X | worktree 정리 |
| **Elicitation** | - | O | 사용자 질문 처리 |
| **ElicitationResult** | - | O | 응답 수정 |

### matcher 정규식

```
"Bash"                    Bash만
"Edit|Write"              Edit 또는 Write
"mcp__memory__.*"         Memory MCP 도구 전체
".*"                      모든 도구
```

### Exit Code

| Code | 동작 |
|------|------|
| 0 | 성공. stdout JSON 파싱 |
| 2 | **차단**. stderr가 Claude에게 피드백 |
| 그 외 | 무시 (verbose에서만 표시) |

### PreToolUse 고급 제어

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "설명",
    "updatedInput": { "command": "수정된 명령" },
    "additionalContext": "Claude에게 전달할 컨텍스트"
  }
}
```

입력 수정 가능: Claude가 `npm test`를 실행하려 하면 `npm test -- --watchAll=false`로 바꿔서 실행.

---

## 6. Settings

### 위치와 우선순위

| 위치 | 우선순위 |
|------|----------|
| 관리 정책 (managed-settings.json) | 1 (최고, 오버라이드 불가) |
| CLI 인수 | 2 |
| `.claude/settings.local.json` | 3 |
| `.claude/settings.json` | 4 |
| `~/.claude/settings.json` | 5 (최저) |

### permissions

```json
{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit",
      "Bash(git *)", "Bash(pnpm *)", "Bash(npm *)",
      "Bash(npx *)", "Bash(node *)", "Bash(tsc *)",
      "Bash(ls *)", "Bash(cat *)", "Bash(mkdir *)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git reset --hard*)",
      "Bash(rm -rf*)",
      "Bash(*DROP TABLE*)",
      "Agent(dangerous-agent)"
    ]
  }
}
```

패턴: `Bash(git *)`, `Skill(deploy *)`, `Agent(Explore)`

### 기타

```json
{
  "model": "claude-sonnet-4-6",
  "smallModelOverride": "claude-haiku-4-5",
  "autoMemoryEnabled": true,
  "claudeMdExcludes": ["**/other-team/CLAUDE.md"],
  "enabledPlugins": { "pyright-lsp@official": true }
}
```

---

## 7. MCP

### 프로젝트 레벨

```json
// .mcp.json (프로젝트 루트)
{
  "mcpServers": {
    "github": {
      "command": "node",
      "args": [".claude/scripts/run-github-mcp.cjs"]
    },
    "mcp-atlassian": {
      "command": "node",
      "args": [".claude/scripts/run-jira-mcp.cjs"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/context7-mcp@latest"]
    }
  }
}
```

### 유저 레벨

```json
// ~/.claude.json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/memory-mcp@latest"]
    }
  }
}
```

### 에이전트 내 격리

에이전트 frontmatter에서 인라인 정의하면 해당 에이전트에서만 연결:

```yaml
mcpServers:
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
```

---

## 8. Plugins

### 구조

```
plugin/
├── .claude-plugin/
│   └── plugin.json          매니페스트 (선택)
├── skills/                  스킬
├── commands/                레거시 커맨드
├── agents/                  에이전트
├── hooks/hooks.json         훅
├── .mcp.json                MCP 서버
├── .lsp.json                LSP 서버
├── settings.json            기본 설정
└── scripts/                 유틸리티 스크립트
```

### 설치 스코프

| 스코프 | 설정 파일 | 공유 |
|--------|-----------|------|
| user | `~/.claude/settings.json` | 나만 (기본값) |
| project | `.claude/settings.json` | Git으로 팀 공유 |
| local | `.claude/settings.local.json` | 나만, gitignore |
| managed | managed-settings.json | 조직 전체 |

### LSP 서버

```json
// .lsp.json
{
  "typescript": {
    "command": "typescript-language-server",
    "args": ["--stdio"],
    "extensionToLanguage": {
      ".ts": "typescript",
      ".tsx": "typescriptreact"
    }
  }
}
```

실시간 진단, go-to-definition, find-references 등 코드 인텔리전스 제공.
바이너리는 별도 설치 필요.

공식 플러그인: `pyright-lsp`, `typescript-lsp`, `rust-lsp`

---

## 비공식 (CCB 자체)

| 파일/폴더 | 용도 | 비고 |
|-----------|------|------|
| `.claude/contexts/` | 모드 전환 | 공식 아님. CCB 자체 구현 |

---

## 우선순위 요약

모든 구성 요소에 적용되는 우선순위:

```
관리 정책 (최고)
  > CLI 인수
    > local (settings.local.json)
      > project (.claude/settings.json, .claude/rules/, .claude/skills/)
        > user (~/.claude/)
          > 플러그인 (최저)
```

같은 이름의 스킬/에이전트가 여러 곳에 있으면 높은 우선순위가 이김.
같은 설정이 여러 곳에 있으면 높은 우선순위가 이김.
관리 정책은 절대 오버라이드 불가.
