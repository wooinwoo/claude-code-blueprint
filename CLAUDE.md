# wiw_claude-code

회사 프로젝트용 Claude Code 설정 템플릿. [everything-claude-code(ECC)](https://github.com/affaan-m/everything-claude-code) 베이스 + 회사 공통 + 스택별(React/Next.js, NestJS) 계층 구조.

## Architecture

```
ECC (upstream) ──sync.ps1──→ base/ ──┐
                                     ├──setup.ps1──→ 프로젝트/.claude/
                     common/ ────────┤
                     [stack]/ ───────┘
```

### 3-Layer System (Dev Stacks)

| 계층 | 경로 | 수정 | 역할 |
|------|------|------|------|
| **Base** | `base/` | sync.ps1만 (직접 수정 금지) | ECC에서 동기화한 에이전트, 룰, 스킬, 훅 |
| **Common** | `common/` | 자유 | 회사 공통 커맨드, 룰, MCP 래퍼, 설정 |
| **Stack** | `react-next/` or `nestjs/` or `java-web/` | 자유 | 스택 전용 에이전트, 커맨드, 룰, 스킬 |

### Non-Dev Profiles

| 프로필 | 경로 | 용도 | 레이어 |
|--------|------|------|--------|
| **Designer** | `designer/` | UI/UX 디자인, 접근성, 마크업 리뷰 | base(선택적) + designer/ |
| **Planner** | `planner/` | PM, 리서치, 전략, 문서 작성 | base(선택적) + planner/ |

### File Delivery Method

| 항목 | 전달 방식 | 갱신 |
|------|-----------|------|
| rules/, hooks/, contexts/, scripts/ | **파일 복사** | `setup.ps1` 재실행 |
| agents/, commands/, skills/ | **파일 복사** | `setup.ps1` 재실행 |
| settings.json, .mcp.json, .env | **최초 1회 복사** (이미 있으면 SKIP) | 수동 |

## Active Inventory (exclude.json 적용 후)

### Agents — 24개 (base 7 + common 1 + stack 8×2)

**Base (7)**: architect, build-error-resolver, doc-updater, e2e-runner, planner, refactor-cleaner, tdd-guide

**Common (1)**: explorer

**React-Next (8)**: code-reviewer, convention-reviewer, feasibility-reviewer, impact-analyzer, next-build-resolver, performance-reviewer, react-reviewer, security-reviewer

**NestJS (8)**: code-reviewer, convention-reviewer, database-reviewer, feasibility-reviewer, impact-analyzer, nestjs-pattern-reviewer, schema-designer, security-reviewer

### Commands — 15개 (base 1 + common 8 + stack 3+2)

**Base (1)**: verify

**Common (8)**: build-fix, code-review, commit, fix, guide, jira, learn, refactor-clean

**React-Next (3)**: orchestrate, test-coverage, verify (overrides base)

**NestJS (2)**: orchestrate, wt

### Rules — 23개 (base 13 + common 2 + stack 5+2)

**Base-Common (8)**: agents, claude-usage, coding-style, git-workflow, hooks, patterns, security, testing
— 우선순위 태깅 적용: `[CRITICAL]` / `[HIGH]` / `[MEDIUM]`

**Base-TypeScript (5)**: coding-style, hooks, patterns, security, testing

**Common (2)**: jira, pull-request

**React-Next (5)**: a11y, nextjs-app-router, nextjs-performance, react-composition, react-rendering

**NestJS (2)**: backend-architecture, nestjs-e2e-testing

### Skills — 11개 (base 7 + stack 3+1)

**Base (7)**: clickhouse-io, continuous-learning-v2, eval-harness, iterative-retrieval, security-review, strategic-compact, verification-loop

**React-Next (3)**: react-data-patterns, react-patterns, react-testing

**NestJS (1)**: hexagonal-architecture

### Hooks — `base/hooks/hooks.json`

| 시점 | 훅 수 | 주요 기능 |
|------|-------|-----------|
| PreToolUse | 5 | dev server tmux 강제, push 전 리뷰 리마인더, .md 생성 차단, compaction 제안, continuous-learning 관찰 |
| PostToolUse | 5 | PR URL 로깅, 빌드 분석, auto-format, typecheck, console.log 경고, continuous-learning 관찰 |
| PreCompact | 1 | 상태 저장 |
| SessionStart | 1 | 이전 컨텍스트 로드, 패키지 매니저 감지 |
| Stop | 1 | console.log 최종 체크 |
| SessionEnd | 2 | 세션 상태 저장, 패턴 추출 평가 |

### Contexts — 3개

dev (개발), research (리서치), review (코드 리뷰)

---

## Designer Profile Inventory

`setup.ps1 designer` — 퍼블리싱까지 하는 디자이너 프로필. HTML/CSS/Tailwind 마크업 + Figma 디자인 + 접근성/반응형 검증. base-typescript 스킵, 빌드/테스트 도구 최소화.

### Agents — 3개

**Designer (3)**: design-reviewer, a11y-reviewer, markup-reviewer

### Commands — 6개

**Designer (6)**: design-review, design-system, publish-check, discover, figma-to-code, design-qa

### Rules — 4개

**Designer (4)**: anti-ai-slop, design-tokens(+다크모드/CSS변수전략), responsive, motion

### Skills — 6개

**Base (7)** + **Designer (6)**: frontend-design, interface-design, taste, web-design-guidelines, contrast-checker, excalidraw-diagram

### Contexts — 5개

**Base (3)** + **Designer (2)**: design, publish

### Hooks — `designer/hooks/hooks.json`

| 시점 | 훅 수 | 주요 기능 |
|------|-------|-----------|
| PostToolUse | 1 | 접근성 자동체크 (img alt, 키보드 이벤트) |

### MCP Servers — 6개

jira, github, context7, memory, figma, playwright (mysql/aws 제거)

---

## Planner Profile Inventory

`setup.ps1 planner` — PM/기획 전문 프로필. 개발 도구 최소화, 리서치/문서 도구 중심.

### Agents — 3개

**Planner (3)**: researcher-strategist(시장분석+전략 통합), ux-researcher, content-writer

### Commands — 11개

**Planner (11)**: prd, roadmap, research, competitive-analysis, okr, sprint-plan, retro, story-map, launch, weekly-update, spec

### Rules — 3개

**Planner (3)**: document-format, research-methodology, prioritization

### Skills — 2개

**Base (7)** + **Planner (2)**: business-frameworks, stakeholder-communication

### Contexts — 5개

**Base (3)** + **Planner (2)**: research (planner 확장), writing

### Hooks — `planner/hooks/hooks.json`

| 시점 | 훅 수 | 주요 기능 |
|------|-------|-----------|
| PostToolUse | 1 | 문서 포맷 체크 (plans/ 작성 시 날짜/상태 누락 경고) |

### MCP Servers — 4개

jira, github, context7, memory (mysql/aws/playwright 제거)

## Key Commands

### `/orchestrate` — 6-Phase Pipeline (스택별)
```
Phase 1: Plan     → architect + planner 에이전트로 설계
Phase 2: Branch   → worktree 격리 + 브랜치 생성
Phase 3: Develop  → 구현 + 검증 루프 (최대 3회)
Phase 4: PR       → 5개 리뷰 에이전트 병렬 실행 + PR 생성
Phase 5: Feedback → GitHub @claude 멘션으로 피드백 반영
Phase 6: Clean    → worktree/브랜치 정리
```
`--full` 플래그: Phase 0(코드베이스 스캔) + Architect(opus) 심층 설계 + TDD + 전원 리뷰 2라운드 (에이전트 10-12개, ~2x 토큰)
상태 파일: `.orchestrate/{slug}.json` — 중단 시 `/orchestrate` 재실행하면 이어서 진행 (모드 자동 유지)

### `/fix` — 경량 수정 (1-3 파일)
Jira 연동 + Q&A → 수정 → 검증 → 수동 테스트 → 커밋/푸시

### `/code-review` — 단독 리뷰
스택별 5개 에이전트 병렬 실행, CRITICAL/HIGH/MEDIUM/LOW 심각도 분류

### `/build-fix` — 빌드 복구
lint → type → build 순서로 에러 수정, 최대 5회 루프

### `/test-coverage` — 커버리지 분석
Vitest 커버리지 수집 + `fill` 모드로 미커버 테스트 자동 생성

### `/refactor-clean` — 데드코드 정리
knip/depcheck/ts-prune → SAFE/REVIEW/SKIP 분류 → `fix` 모드로 안전 제거

### `/commit`, `/jira`, `/learn`, `/guide`
커밋 생성, Jira 관리, 학습 시스템, 상황별 커맨드 추천

## Scripts

### Management Scripts (루트)

| 스크립트 | 용도 | 실행 |
|----------|------|------|
| `setup.ps1 <stack> <path>` | 프로젝트에 설치 | `.\setup.ps1 react-next C:\path\to\project` / `.\setup.ps1 designer C:\path\to\project` |
| `sync.ps1` | ECC upstream → base/ 동기화 | `.\sync.ps1` |
| `update.ps1` | 기설치 프로젝트 일괄 업데이트 | `.\update.ps1` |

### MCP Wrapper Scripts (`common/scripts/`)

| 스크립트 | 역할 |
|----------|------|
| `run-github-mcp.cjs` | `.env`에서 GITHUB_PAT 로드 → GitHub MCP 서버 실행 |
| `run-jira-mcp.cjs` | `.env`에서 JIRA_TOKEN/URL/USERNAME 로드 → Jira MCP 실행 |
| `run-db-mcp.cjs` | `.env`에서 DATABASE_URL 로드 → MySQL MCP 실행 |

### Hook Scripts (`base/scripts/hooks/`)

auto-format.js, block-docs.js, check-console-log.js, evaluate-session.js, log-pr-url.js, pre-compact.js, session-end.js, session-start.js, suggest-compact.js, typecheck.js, warn-console-log.js

## MCP Servers (9개)

| 서버 | 용도 | 필요 토큰 |
|------|------|-----------|
| github | PR/Issue/Repo | GITHUB_PAT |
| mcp-atlassian | Jira 이슈 관리 | JIRA_TOKEN, JIRA_URL, JIRA_USERNAME |
| context7 | npm/프레임워크 라이브 문서 | 없음 |
| memory | 세션 간 영구 메모리 | 없음 |
| figma-dev-mode | Figma 디자인 연동 | 로컬 SSE 서버 |
| aws | AWS 코어 서비스 | AWS_PROFILE |
| aws-api | AWS API 관리 | AWS_PROFILE |
| playwright | 브라우저 자동화/테스트 | 없음 |
| mysql | DB 쿼리 실행 | DATABASE_URL |

## Permission System (`common/settings.json`)

### Allow List (54개)
git (add/branch/checkout/commit/diff/log/merge/pull/push/stash/status/worktree/remote/rev-parse/show/tag), gh (pr/api/issue), pnpm (install/build/lint/test/dev/biome/tsc/exec), npm (install/run/test), npx, node, tsc, 셸 유틸 (ls/cd/mkdir/cp/mv/rm/cat/jq/bash/date/tail/head/find/wc/echo/pwd/test/if)

### Deny List (15개 — 파괴적 명령 차단)
git push --force/-f, git reset --hard, git clean -f, git checkout/restore ., rm -rf, del/rmdir /s /q, git branch -D, DROP TABLE/DATABASE, git rebase -i, git push origin --delete main/master

## Dashboard (Cockpit)

`dashboard/` — 멀티 프로젝트 모니터링 로컬 웹앱

| 탭 | 기능 |
|----|------|
| **Overview** | 프로젝트 카드 (세션/브랜치/모델/변경사항/PR), 비용 차트, Dev Server, IDE 연동 |
| **Terminal** | 멀티 터미널 (탭/분할), 브랜치 선택, 검색, 세션 복원 |
| **Changes** | 2-컬럼 diff, 구문 강조 (15+ 언어), Stage/Unstage, AI Auto Commit (Haiku) |

**Tech**: Node.js (http) + ES modules + xterm.js + Chart.js + Tauri 2 (데스크톱)
**실행**: `cd dashboard && npm install && npm start` → `http://localhost:3847`
**설치**: `Cockpit_1.3.0_x64-setup.exe` (Tauri 데스크톱 앱)

## Exclude System (`exclude.json`)

sync.ps1이 ECC에서 동기화 후 `base/_excluded/`로 이동할 항목:

- **Rules**: golang, python (미사용 언어)
- **Agents**: go-build-resolver, go-reviewer, python-reviewer
- **Commands**: 30개 (go-*, python-*, multi-*, pm2, sessions, checkpoint, ECC 메타 커맨드 → common/에 대체 커맨드 있음)
- **Skills**: 16개 (django-*, springboot-*, golang-*, python-*, java-*, jpa-*, configure-ecc)

제외된 항목은 삭제되지 않고 `base/_excluded/`에 보관 (참조 가능).

## CI/CD

`.github/workflows/claude-pr-review.yml` — PR 코멘트에 `@claude` 멘션 시 Claude Code Action 실행
- PR 피드백 자동 반영 (Phase 5)
- lint + build + test 검증 후 커밋/푸시
- 필요 시크릿: `CLAUDE_CODE_OAUTH_TOKEN`, `SECRETS_ADMIN_PAT`

## Conventions

### 파일 작성 규칙
- 커맨드: frontmatter (`---description---`) + Usage + Phase별 절차 + Arguments + 주의사항
- 룰: 제목 + 우선순위 태그 `[CRITICAL/HIGH/MEDIUM]` + BAD/GOOD 코드 예시
- 에이전트: 역할 + 검토 범위 (include/exclude 도메인) + 출력 포맷 + Red Flags
- 스킬: `SKILL.md` 파일 (디렉토리 단위)

### 수정 규칙
- `base/` 직접 수정 금지 → ECC 변경은 sync.ps1로, 오버라이드는 common/ 또는 stack/
- 한국어 기본 (커맨드 설명, 룰 예시, 에이전트 출력)
- 에이전트 간 리뷰 도메인 중복 없음 (각 에이전트가 명시적 include/exclude 가짐)

### 프로젝트 설치 후 개발자 작업
1. `CLAUDE.md` — 프로젝트 개요, 기술 스택, 구조, 컨벤션 작성
2. `.claude/.env` — 토큰 입력 (GITHUB_PAT, JIRA_TOKEN 등)
3. `.mcp.json` — 불필요한 MCP 서버 제거
4. `.claude/rules/project.md` — 프로젝트 전용 룰 추가 (선택)
