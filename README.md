# wiw_claude-code

Claude Code 설정 템플릿. 프로젝트에 설치하면 에이전트, 커맨드, 룰, 스킬, 훅, MCP 서버가 한 번에 세팅됩니다.

## 프로필

| 프로필 | 대상 | 설치 명령 |
|--------|------|-----------|
| `react-next` | React/Next.js 개발자 | `.\setup.ps1 react-next C:\path\to\project` |
| `nestjs` | NestJS 백엔드 개발자 | `.\setup.ps1 nestjs C:\path\to\project` |
| `designer` | 퍼블리싱까지 하는 디자이너 | `.\setup.ps1 designer C:\path\to\project` |
| `planner` | PM / 기획자 | `.\setup.ps1 planner C:\path\to\project` |

## Quick Start

```powershell
# 1. 클론
git clone <repo-url> C:\_project\template\wiw_claude-code

# 2. 프로젝트에 설치
cd C:\_project\template\wiw_claude-code
.\setup.ps1 react-next C:\path\to\my-project

# 3. 토큰 설정
notepad C:\path\to\my-project\.claude\.env
# GITHUB_PAT=ghp_xxx
# JIRA_TOKEN=xxx (선택)

# 4. CLAUDE.md 작성
# 프로젝트 개요, 기술 스택, 구조, 컨벤션
```

설치 후 Claude Code를 열면 바로 사용 가능합니다.

---

## 아키텍처

```
ECC (upstream) ──sync.ps1──→ base/ ──┐
                                     ├──setup.ps1──→ 프로젝트/.claude/
                     common/ ────────┤
                     [stack]/ ───────┘
```

### 3계층 시스템

| 계층 | 경로 | 역할 | 수정 |
|------|------|------|------|
| **Base** | `base/` | ECC 커뮤니티 에이전트, 룰, 스킬 | sync.ps1만 (직접 수정 금지) |
| **Common** | `common/` | 회사 공통 커맨드, 룰, MCP 래퍼 | 자유 |
| **Stack/Profile** | `react-next/`, `nestjs/`, `designer/`, `planner/` | 역할별 전용 설정 | 자유 |

- **Dev 스택** (react-next, nestjs): base + common + stack 전부 설치
- **Non-dev 프로필** (designer, planner): base 선택적 + common + profile 설치 (TypeScript 룰, 빌드 도구 스킵)

### 전달 방식

| 항목 | 방식 | 업데이트 |
|------|------|----------|
| rules/, hooks/, contexts/, scripts/ | Junction (심볼릭 링크) | `git pull` 시 자동 반영 |
| agents/, commands/, skills/ | 파일 복사 | `setup.ps1` 재실행 필요 |
| settings.json, .mcp.json, .env | 최초 1회 복사 | 수동 편집 |

---

## 프로필별 기능

### Dev: React/Next.js

| 항목 | 수량 | 주요 내용 |
|------|------|-----------|
| Agents | 15 | architect, react-reviewer, performance-reviewer, security-reviewer 등 |
| Commands | 11 | `/orchestrate`, `/code-review`, `/build-fix`, `/test-coverage`, `/commit` 등 |
| Rules | 18 | git-workflow, react-composition, nextjs-app-router, a11y 등 |
| Skills | 10 | react-patterns, security-review, verification-loop 등 |

**핵심 커맨드:**
- `/orchestrate` — 6-Phase 개발 파이프라인 (설계 → 브랜치 → 구현 → 리뷰 → PR)
- `/code-review` — 5개 리뷰 에이전트 병렬 실행
- `/build-fix` — lint → type → build 순서로 에러 자동 수정

### Dev: NestJS

| 항목 | 수량 | 주요 내용 |
|------|------|-----------|
| Agents | 15 | architect, schema-designer, database-reviewer, nestjs-pattern-reviewer 등 |
| Commands | 10 | `/orchestrate`, `/code-review`, `/build-fix`, `/wt`, `/commit` 등 |
| Rules | 15 | backend-architecture (헥사고날), nestjs-e2e-testing 등 |
| Skills | 8 | hexagonal-architecture, security-review 등 |

### Designer

퍼블리싱까지 하는 디자이너용. Figma 연동, 접근성 검증, 디자인 시스템 관리.

| 항목 | 수량 | 주요 내용 |
|------|------|-----------|
| Agents | 3 | design-reviewer, a11y-reviewer, markup-reviewer |
| Commands | 6 | `/design-review`, `/design-system`, `/publish-check`, `/discover`, `/figma-to-code`, `/design-qa` |
| Rules | 4 | anti-ai-slop, design-tokens (+다크모드), responsive, motion |
| Skills | 4 | interface-design, taste, web-design-guidelines, contrast-checker |
| MCP | 6 | jira, github, context7, memory, **figma**, **playwright** |

**핵심 커맨드:**
- `/design-system tokens|audit|component|suggest` — 디자인 토큰 조회/감사/분석
- `/publish-check` — Lighthouse + Playwright 반응형 + 소스 정적분석 (a11y, SEO, 성능)
- `/figma-to-code` — Figma Dev Mode MCP로 시안 → 코드 변환
- `/design-review` — 3개 에이전트 병렬 리뷰 (디자인/접근성/마크업)

### Planner

PM/기획자용. 리서치, 문서 작성, 프로젝트 관리. Jira 선택 연동.

| 항목 | 수량 | 주요 내용 |
|------|------|-----------|
| Agents | 3 | researcher-strategist, ux-researcher, content-writer |
| Commands | 11 | `/prd`, `/spec`, `/research`, `/competitive-analysis`, `/okr`, `/roadmap`, `/story-map`, `/sprint-plan`, `/retro`, `/launch`, `/weekly-update` |
| Rules | 3 | document-format, prioritization (인지 편향 차단), research-methodology |
| Skills | 2 | business-frameworks, stakeholder-communication |
| MCP | 4 | jira, github, context7, memory |

**핵심 커맨드:**
- `/research` — 플래그 없으면 리서치 플랜 수립 → 확인 → 실행. `--market|--user|--tech|--competitor` 직접 지정 가능
- `/prd` — 10섹션 PRD 생성 (TBD 관리, Jira 연동)
- `/story-map` — PRD 기반 스토리맵 + Walking Skeleton MVP 검증
- `/okr` — OKR 생성/검토 (O는 정성적, KR는 정량적 자동 검증)
- `/competitive-analysis` — WebSearch 기반 경쟁사 분석 (기능 매트릭스 + SWOT)

> 모든 커맨드는 **Jira 없이도 동작**합니다. Jira 미연결 시 수동 입력 모드로 자동 전환.

---

## 설치 후 할 일

### 1. CLAUDE.md 작성 (필수)

프로젝트 루트에 `CLAUDE.md`를 작성합니다. Claude가 프로젝트를 이해하는 핵심 파일입니다.

```markdown
# 프로젝트명

## 개요
한 줄 설명

## 기술 스택
- Frontend: React 19, TanStack Router, Tailwind v4
- Backend: NestJS, PostgreSQL

## 프로젝트 구조
src/
├── components/   UI 컴포넌트
├── pages/        페이지
└── services/     API 서비스

## 컨벤션
- 컴포넌트: PascalCase 함수형
- API: RESTful, /api/v1/ prefix
```

### 2. .env 토큰 설정 (선택)

```bash
# .claude/.env
GITHUB_PAT=ghp_xxxxxxxxxxxx           # GitHub MCP용
JIRA_URL=https://company.atlassian.net # Jira MCP용 (선택)
JIRA_USERNAME=email@company.com        # Jira MCP용 (선택)
JIRA_TOKEN=ATATTxxxxxxxx              # Jira MCP용 (선택)
```

### 3. .mcp.json 정리 (선택)

안 쓰는 MCP 서버는 `.mcp.json`에서 제거합니다.

### 4. 프로젝트 전용 룰 추가 (선택)

`.claude/rules/project.md`에 프로젝트만의 규칙을 추가할 수 있습니다.

---

## 업데이트

```powershell
# 템플릿 최신화
cd C:\_project\template\wiw_claude-code
git pull

# junction 항목 (rules, hooks, contexts): 자동 반영됨
# 복사 항목 (agents, commands, skills): 재설치 필요
.\setup.ps1 react-next C:\path\to\my-project
```

### ECC 업스트림 동기화 (관리자)

```powershell
cd C:\_project\template\everything-claude-code && git pull
cd C:\_project\template\wiw_claude-code && .\sync.ps1
git add . && git commit -m "chore: sync ecc" && git push
```

---

## 커스터마이징

### 규칙 추가

```
common/rules/         → 모든 프로필에 적용
react-next/rules/     → React/Next.js에만 적용
designer/rules/       → 디자이너에만 적용
planner/rules/        → 기획자에만 적용
```

### 커맨드 추가

```
common/commands/      → 모든 프로필에 적용
react-next/commands/  → React/Next.js에만 적용
```

### base/ 직접 수정 금지

`base/`는 sync.ps1이 덮어씁니다. ECC 규칙을 수정하고 싶으면 `common/` 또는 스택 폴더에 같은 이름의 파일을 만들어 override하세요.

### 제외 항목 관리

`exclude.json`으로 ECC에서 가져올 항목을 제어합니다.

```jsonc
{
  "rules": ["golang", "python"],
  "agents": ["go-reviewer.md"],
  "commands": ["go-build.md"],
  "skills": ["django-patterns"]
}
```

---

## MCP 서버

| 서버 | 용도 | 토큰 | 프로필 |
|------|------|------|--------|
| github | PR/Issue/Repo | GITHUB_PAT | 전체 |
| mcp-atlassian | Jira 이슈 관리 | JIRA_TOKEN + URL + USERNAME | 전체 |
| context7 | npm/프레임워크 문서 | 없음 | 전체 |
| memory | 세션 간 영구 메모리 | 없음 | 전체 |
| figma-dev-mode | Figma 시안 연동 | 로컬 SSE (localhost:3845) | designer |
| playwright | 브라우저 자동화 | 없음 | designer, dev |
| mysql | DB 쿼리 | DATABASE_URL | dev |
| aws / aws-api | AWS 서비스 | AWS_PROFILE | dev |

---

## Dashboard (Cockpit)

멀티 프로젝트 모니터링 로컬 대시보드.

```powershell
cd dashboard && npm install && npm start
# http://localhost:3847
```

Overview (프로젝트 상태/비용) | Terminal (멀티 터미널) | Changes (2-column diff + AI Auto Commit)

데스크톱 앱: `Cockpit_1.3.0_x64-setup.exe` (Tauri 2)

상세: [dashboard/README.md](dashboard/README.md)

---

## 출처

| 폴더 | 출처 |
|------|------|
| `base/` | [everything-claude-code](https://github.com/affaan-m/everything-claude-code) |
| `common/`, `react-next/`, `nestjs/` | 자체 작성 |
| `designer/`, `planner/` | 자체 작성 |
