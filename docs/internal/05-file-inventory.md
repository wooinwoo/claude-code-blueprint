# CCB 파일 인벤토리

모든 파일의 역할과 위치. 2026-03-22 기준.

---

## 루트 스크립트

| 파일 | 역할 |
|------|------|
| `setup.ps1` | 프로젝트에 CCB 설치 |
| `sync.ps1` | ECC → base/ 동기화 |
| `update.ps1` | 기설치 프로젝트 일괄 업데이트 |
| `exclude.json` | ECC에서 제외할 항목 |
| `VERSION` | 현재 버전 |

---

## common/ (전 프로필 공통)

### commands/ (9개)

| 파일 | 역할 | non-dev 포함 |
|------|------|-------------|
| `build-fix.md` | lint→type→build 에러 자동 수정 | X |
| `code-review.md` | 5개 에이전트 병렬 리뷰 | X |
| `commit.md` | Conventional commit 생성 | O |
| `fix.md` | 경량 버그 수정 (1-3 파일) | X |
| `guide.md` | 상황별 커맨드 추천 | O |
| `jira.md` | Jira 이슈 생성/관리 | O |
| `learn.md` | 학습 시스템 | X |
| `lighthouse.md` | 페이지별 Lighthouse 분석 | X |
| `refactor-clean.md` | knip 데드코드 분석+제거 | X |

### rules/ (2개)

| 파일 | 역할 |
|------|------|
| `jira.md` | Jira 이슈 생성 규칙 |
| `pull-request.md` | PR 작성 규칙 |

### scripts/ (3개)

| 파일 | 역할 |
|------|------|
| `run-github-mcp.cjs` | GitHub MCP 래퍼 (.env에서 PAT 로드) |
| `run-jira-mcp.cjs` | Jira MCP 래퍼 (.env에서 토큰 로드) |
| `run-db-mcp.cjs` | DB MCP 래퍼 (.env에서 URL 로드) |

### settings.json

- permissions: allow 80개 + deny 15개
- enabledPlugins: typescript-lsp
- hooks: continuous-learning-v2 (pre/post tool use)

### mcp-configs/.mcp.json

- 9개 서버: github, mcp-atlassian, context7, memory, figma, aws, aws-api, playwright, mysql

---

## react-next/

### agents/ (8개)

| 파일 | 모델 | 역할 |
|------|------|------|
| `code-reviewer.md` | sonnet | 코드 품질 (가독성, 중복, 에러 처리) |
| `convention-reviewer.md` | sonnet | 컨벤션 (네이밍, 구조, import) |
| `feasibility-reviewer.md` | sonnet | 플랜 타당성 검증 |
| `impact-analyzer.md` | sonnet | 변경 영향 범위 분석 |
| `next-build-resolver.md` | sonnet | Next.js/Vite 빌드 에러 해결 |
| `performance-reviewer.md` | sonnet | 성능 (번들, 메모리, 렌더링) |
| `react-reviewer.md` | sonnet | React 패턴 (hooks, 렌더 최적화) |
| `security-reviewer.md` | sonnet | 보안 (XSS, secrets, auth) |

### commands/ (3개)

| 파일 | 역할 |
|------|------|
| `orchestrate.md` | 6-Phase 개발 파이프라인 (--full 고품질) |
| `test-coverage.md` | 커버리지 분석 + 미커버 테스트 생성 |
| `verify.md` | lint+type+build+test 일괄 검증 |

### rules/ (5개)

| 파일 | 역할 |
|------|------|
| `a11y.md` | 접근성 규칙 |
| `nextjs-app-router.md` | Next.js App Router 패턴 |
| `nextjs-performance.md` | Next.js 성능 규칙 |
| `react-composition.md` | React 합성 패턴 |
| `react-rendering.md` | React 렌더링 최적화 |

### skills/ (3개)

`react-data-patterns/`, `react-patterns/`, `react-testing/`

---

## nestjs/

### agents/ (8개)

code-reviewer, convention-reviewer, database-reviewer, feasibility-reviewer,
impact-analyzer, nestjs-pattern-reviewer, schema-designer, security-reviewer

### commands/ (2개)

| 파일 | 역할 |
|------|------|
| `orchestrate.md` | 6-Phase 백엔드 파이프라인 |
| `wt.md` | Git worktree 관리 |

### rules/ (2개)

`backend-architecture.md`, `nestjs-e2e-testing.md`

### skills/ (1개)

`hexagonal-architecture/`

---

## fullstack/

### agents/ (11개)

react-next 8개 + nestjs 전용 3개 (database-reviewer, nestjs-pattern-reviewer, schema-designer)

### commands/ (4개)

| 파일 | 역할 |
|------|------|
| `orchestrate.md` | 풀스택 파이프라인 (scope: fullstack/front/back) |
| `test-coverage.md` | react-next에서 복사 |
| `verify.md` | react-next에서 복사 |
| `wt.md` | nestjs에서 복사 |

### rules/ (7개)

react-next 5개 + nestjs 2개 전부 합침

### skills/ (4개)

react 3개 + hexagonal-architecture

---

## designer/

### agents/ (3개)

| 파일 | 모델 | 역할 |
|------|------|------|
| `design-reviewer.md` | sonnet | 시각 디자인 일관성 |
| `a11y-reviewer.md` | sonnet | WCAG AA 접근성 |
| `markup-reviewer.md` | sonnet | 시맨틱 HTML, CSS |

### commands/ (6개)

| 파일 | 역할 |
|------|------|
| `design-review.md` | 3개 에이전트 병렬 리뷰 |
| `design-system.md` | 토큰 조회/감사/분석/제안 |
| `publish-check.md` | Lighthouse+Playwright+정적분석 |
| `discover.md` | 컴포넌트 인벤토리 |
| `figma-to-code.md` | Figma→코드 변환 |
| `design-qa.md` | Figma 시안 vs 구현 비교 |

### rules/ (4개)

`anti-ai-slop.md`, `design-tokens.md`, `responsive.md`, `motion.md`

### skills/ (4개)

`contrast-checker/`, `interface-design/`, `taste/`, `web-design-guidelines/`

---

## planner/

### agents/ (3개)

| 파일 | 모델 | 역할 |
|------|------|------|
| `researcher-strategist.md` | opus | 시장 분석 + 전략 |
| `ux-researcher.md` | sonnet | 사용자 리서치 |
| `content-writer.md` | sonnet | 문서 작성 (Pyramid, MECE) |

### commands/ (11개)

| 파일 | 역할 |
|------|------|
| `prd.md` | 10섹션 PRD |
| `spec.md` | 경량 기능 명세 |
| `research.md` | 리서치 플랜 → WebSearch |
| `competitive-analysis.md` | 경쟁사 분석 |
| `okr.md` | OKR 생성/검토 |
| `roadmap.md` | RICE 스코어링 로드맵 |
| `story-map.md` | Walking Skeleton MVP |
| `sprint-plan.md` | 스프린트 계획 |
| `retro.md` | 회고 (4L/Starfish/Sailboat) |
| `launch.md` | 런치 체크리스트 |
| `weekly-update.md` | 주간 리포트 |

### rules/ (3개)

`document-format.md`, `prioritization.md`, `research-methodology.md`

### skills/ (2개)

`business-frameworks/`, `stakeholder-communication/`

---

## base/ (ECC에서 동기화)

### agents/ (7개)

architect, build-error-resolver, doc-updater, e2e-runner, planner, refactor-cleaner, tdd-guide

### skills/ (16개)

api-design, coding-standards, continuous-learning-v2, database-migrations,
deployment-patterns, docker-patterns, e2e-testing, eval-harness,
frontend-patterns, iterative-retrieval, postgres-patterns, search-first,
security-review, strategic-compact, tdd-workflow, verification-loop

### rules/common/ (9개)

agents, coding-style, development-workflow, git-workflow, hooks,
patterns, performance, security, testing

### rules/typescript/ (5개)

coding-style, hooks, patterns, security, testing
