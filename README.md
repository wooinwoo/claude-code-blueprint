<p align="center">
  <img src="assets/cover.png" alt="Claude Code Blueprint" width="100%">
</p>

# CCB — Claude Code Blueprint

> 커맨드 하나. 역할 넷. 모든 프로젝트에 설정 완료.

## 왜 만들었나

Claude Code를 프로젝트마다 세팅하다 보면 같은 룰, 같은 에이전트, 같은 MCP 설정을 반복하게 됩니다.
하나를 개선하면 나머지 프로젝트는 옛날 버전 그대로고요.

코드 중복을 라이브러리로 해결하듯, Claude Code 설정도 **중앙 템플릿 하나에서 관리하고 프로젝트에는 설치만** 하는 방식이 필요했습니다.

프론트엔드, 백엔드, 디자이너, 기획자마다 필요한 도구가 다르니 **역할별 프로필** 시스템을 얹었습니다.

```powershell
.\setup.ps1 react-next C:\path\to\project
```

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│  LAYER 3: Stack / Profile                       │
│  react-next │ nestjs │ designer │ planner       │
│  역할 전용 에이전트, 커맨드, 룰, 스킬           │
├─────────────────────────────────────────────────┤
│  LAYER 2: Common                                │
│  /commit, /jira, /code-review                   │
│  PR 규칙, MCP 래퍼, 공통 설정                   │
├─────────────────────────────────────────────────┤
│  LAYER 1: Base (교체 가능)                       │
│  커뮤니티 에이전트, 룰, 스킬                     │
│  sync.ps1로 동기화 — 직접 수정 금지              │
└─────────────────────────────────────────────────┘
                      │
                      │ setup.ps1
                      ▼
              project/.claude/
```

각 계층이 아래를 기반으로 쌓입니다. Base는 **교체 가능** — 현재 [everything-claude-code](https://github.com/affaan-m/everything-claude-code)를 쓰지만, 어떤 소스든 갈아끼울 수 있습니다.

---

## 구성 요소

### 프로필

| Profile | 대상 | Agents | Commands | Rules | MCP |
|---------|------|--------|----------|-------|-----|
| **react-next** | React/Next.js 개발자 | 15 | 11 | 18 | 9 |
| **nestjs** | NestJS 백엔드 개발자 | 15 | 10 | 15 | 9 |
| **designer** | UI/UX + 퍼블리싱 | 3 | 6 | 4 | 6 |
| **planner** | PM / 기획자 | 3 | 11 | 3 | 4 |

### Dev (react-next, nestjs)

| Command | 설명 |
|---------|------|
| `/orchestrate` | 6-Phase 파이프라인: 설계 → 브랜치 → 구현 → 리뷰 → PR → 정리 |
| `/code-review` | 5개 리뷰 에이전트 병렬 실행 (코드, 컨벤션, 보안, 성능, 타당성) |
| `/build-fix` | lint → type → build 에러 자동 수정 루프 |
| `/test-coverage` | 커버리지 분석 + 미커버 테스트 자동 생성 |
| `/commit` | Conventional commit (스코프 자동 감지) |

### Designer

| Command | 설명 |
|---------|------|
| `/design-system` | 토큰 감사, 컴포넌트 분석, 패턴 제안 |
| `/publish-check` | Lighthouse + Playwright 반응형 + 소스 정적 분석 |
| `/figma-to-code` | Figma Dev Mode MCP → 코드 생성 |
| `/design-review` | 3개 에이전트 병렬 리뷰: 디자인, 접근성, 마크업 |
| `/design-qa` | Figma 시안 vs 구현물 비교 |
| `/discover` | 컴포넌트 인벤토리, 미사용/유사 컴포넌트 탐지 |

### Planner

| Command | 설명 |
|---------|------|
| `/research` | 리서치 플랜 수립 → WebSearch 실행 (market/user/tech) |
| `/prd` | 10섹션 PRD 생성 (완전성 자동 검증) |
| `/story-map` | Walking Skeleton MVP 검증 |
| `/competitive-analysis` | 기능 매트릭스 + SWOT (WebSearch 기반) |
| `/okr` | OKR 생성/검토 (정성적 O, 정량적 KR 자동 검증) |
| `/spec` | 경량 기능 명세 (수용기준 테스트 가능성 체크) |
| `/sprint-plan` | 용량 기반 스프린트 계획 (캐리오버 포함) |
| `/retro` | 4L / Starfish / Sailboat 프레임워크 |
| `/launch` | 런치 체크리스트 + 롤백 계획 + 릴리스 노트 |
| `/weekly-update` | 주간 리포트 (default / team / exec 모드) |
| `/roadmap` | RICE 스코어링 + OKR 연계 |

> 모든 Planner 커맨드는 Jira 없이도 동작합니다. 미연결 시 수동 입력으로 자동 전환.

---

## Quick Start

```powershell
# 1. 클론
git clone https://github.com/rstful/claude-code-blueprint.git

# 2. 프로젝트에 설치
cd claude-code-blueprint
.\setup.ps1 react-next C:\path\to\my-project

# 3. 토큰 설정 (선택)
notepad C:\path\to\my-project\.claude\.env
# GITHUB_PAT=ghp_xxx
# JIRA_TOKEN=xxx

# 4. CLAUDE.md 작성
# 프로젝트 개요, 기술 스택, 구조, 컨벤션
```

### 업데이트

```powershell
cd claude-code-blueprint && git pull
.\setup.ps1 react-next C:\path\to\my-project   # 재설치
```

---

## MCP Servers

| Server | 용도 | 프로필 |
|--------|------|--------|
| github | PR, Issue, Repo 관리 | 전체 |
| mcp-atlassian | Jira 이슈 관리 | 전체 |
| context7 | npm/프레임워크 라이브 문서 | 전체 |
| memory | 세션 간 영구 메모리 | 전체 |
| figma-dev-mode | Figma 시안 연동 | designer |
| playwright | 브라우저 자동화 | designer, dev |
| mysql | DB 쿼리 | dev |
| aws | AWS 서비스 | dev |

---

## 커스터마이징

```
common/rules/         → 모든 프로필에 적용
common/commands/       → 모든 프로필에 적용
react-next/rules/     → React 프로젝트에만 적용
designer/commands/     → 디자이너 프로필에만 적용
planner/agents/        → 기획자 프로필에만 적용
```

`base/`는 `sync.ps1`이 덮어씁니다. Base 동작을 수정하려면 `common/` 또는 스택 폴더에서 override하세요.

### Exclude System

```jsonc
// exclude.json — upstream 동기화 시 제외할 항목
{
  "rules": ["golang", "python"],
  "agents": ["go-reviewer.md"],
  "skills": ["django-patterns"]
}
```

제외된 항목은 `base/_excluded/`에 보관됩니다 (삭제되지 않음).

---

## 설치 후 할 일

1. **CLAUDE.md** — 프로젝트 개요, 기술 스택, 구조 작성
2. **.claude/.env** — 토큰 입력 (GITHUB_PAT, JIRA_TOKEN)
3. **.mcp.json** — 안 쓰는 MCP 서버 제거
4. **.claude/rules/project.md** — 프로젝트 전용 규칙 추가 (선택)

---

## 참고

- Base upstream: [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- [CLAUDE.md 가이드](https://velog.io/@surim014/claude-md-guide)

---

<p align="center">
  <sub>Built with Claude Code. Configured by CCB.</sub>
</p>
