# CCB — Claude Code Blueprint

Claude Code 설정 템플릿. `setup.ps1` 한 줄로 에이전트, 커맨드, 룰, 스킬, 훅, MCP 서버가 세팅됩니다.

## 프로필

```powershell
.\setup.ps1 react-next C:\path\to\project    # React/Next.js 개발자
.\setup.ps1 nestjs C:\path\to\project        # NestJS 백엔드 개발자
.\setup.ps1 designer C:\path\to\project      # 퍼블리싱 디자이너
.\setup.ps1 planner C:\path\to\project       # PM / 기획자
```

## Quick Start

```powershell
# 1. 클론
git clone https://github.com/rstful/claude-code-blueprint.git

# 2. 프로젝트에 설치
cd claude-code-blueprint
.\setup.ps1 react-next C:\path\to\my-project

# 3. 토큰 설정 (선택)
notepad C:\path\to\my-project\.claude\.env

# 4. CLAUDE.md 작성
# 프로젝트 개요, 기술 스택, 구조, 컨벤션
```

## 구조

```
Base (교체 가능한 베이스)          ← ECC 등 커뮤니티 소스. sync.ps1로 동기화
  ↓
Common (팀 공통)                  ← /commit, /jira, /code-review, PR 규칙
  ↓
Stack / Profile (역할별)          ← react-next, nestjs, designer, planner
  ↓ setup.ps1
프로젝트/.claude/                 ← 위 3개 계층이 합쳐져서 설치됨
```

- **Base**는 직접 수정하지 않음. 다른 소스로 갈아끼울 수 있음
- **Common**은 모든 프로필에 공통 적용
- **Stack/Profile**은 역할별로 다른 세트 제공

## 프로필별 구성

| | react-next | nestjs | designer | planner |
|--|-----------|--------|----------|---------|
| 에이전트 | 15개 | 15개 | 3개 | 3개 |
| 커맨드 | 11개 | 10개 | 6개 | 11개 |
| 룰 | 18개 | 15개 | 4개 | 3개 |
| MCP 서버 | 9개 | 9개 | 6개 | 4개 |

### Dev (react-next, nestjs)

- `/orchestrate` — 6-Phase 개발 파이프라인 (설계 → 구현 → 리뷰 → PR)
- `/code-review` — 5개 리뷰 에이전트 병렬 실행
- `/build-fix` — lint → type → build 순서로 에러 자동 수정
- `/test-coverage` — 커버리지 분석 + 미커버 테스트 자동 생성

### Designer

- `/design-system tokens|audit|component|suggest` — 디자인 토큰 관리
- `/publish-check` — Lighthouse + Playwright + 소스 정적분석
- `/figma-to-code` — Figma Dev Mode MCP로 시안 → 코드
- `/design-review` — 디자인/접근성/마크업 3개 에이전트 병렬 리뷰

### Planner

- `/research` — 리서치 플랜 수립 → WebSearch 실행
- `/prd` — 10섹션 PRD 생성 (완전성 자동 검증)
- `/story-map` — Walking Skeleton MVP 검증
- `/okr` — OKR 생성/검토 (정성O, 정량KR 자동 검증)
- `/competitive-analysis` — 경쟁사 분석 (기능 매트릭스 + SWOT)

> 모든 Planner 커맨드는 Jira 없이도 동작합니다.

## 설치 후 할 일

1. **CLAUDE.md** — 프로젝트 개요, 기술 스택, 구조 작성
2. **.claude/.env** — 토큰 입력 (선택: GITHUB_PAT, JIRA_TOKEN)
3. **.mcp.json** — 안 쓰는 MCP 서버 제거

## 업데이트

```powershell
cd claude-code-blueprint && git pull
.\setup.ps1 react-next C:\path\to\my-project   # 재설치
```

## MCP 서버

| 서버 | 용도 | 프로필 |
|------|------|--------|
| github | PR/Issue | 전체 |
| mcp-atlassian | Jira | 전체 |
| context7 | 라이브 문서 | 전체 |
| memory | 세션 간 메모리 | 전체 |
| figma-dev-mode | Figma 시안 | designer |
| playwright | 브라우저 자동화 | designer, dev |
| mysql | DB 쿼리 | dev |
| aws | AWS 서비스 | dev |

## 커스터마이징

```
common/rules/         → 모든 프로필에 적용
react-next/rules/     → React에만 적용
designer/commands/     → 디자이너에만 적용
```

`base/`는 sync.ps1이 덮어씁니다. 수정이 필요하면 common/ 또는 stack/에서 override하세요.

## 참고

- Base: [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- [CLAUDE.md 가이드](https://velog.io/@surim014/claude-md-guide)
