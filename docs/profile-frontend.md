# CCB Frontend (react-next) 프로필 상세

`setup.ps1 react-next <경로>`

---

## 설치 구성

| 항목 | 수량 | 출처 |
|------|------|------|
| Agents | 16 | base 7 + common 1 + react-next 8 |
| Commands | 15 | base 3 + common 9 + react-next 3 |
| Rules | 21 | base-common 9 + base-typescript 5 + ccb-common 2 + ccb-stack 5 |
| Skills | 19 | base 16 + react-next 3 |
| Hooks | 2 | base (pre/post tool use) |
| MCP | 9 | github, jira, context7, memory, figma, playwright, mysql, aws, aws-api |
| Plugins | 1 | typescript-lsp |

---

## 상황별 커맨드 가이드

| 상황 | 커맨드 |
|------|--------|
| 새 기능 만들기 | `/orchestrate` |
| 빠른 버그 수정 (1~3 파일) | `/fix` |
| 코드 리뷰 받기 | `/code-review` |
| 빌드 깨짐 | `/build-fix` |
| 배포 전 성능 체크 | `/lighthouse` |
| 테스트 커버리지 올리기 | `/test-coverage` |
| 데드코드 정리 | `/refactor-clean` |
| 전체 검증 (lint+type+build+test) | `/verify` |
| 커밋 | `/commit` |
| Jira 이슈 관리 | `/jira` |
| 뭘 써야 할지 모르겠음 | `/guide` |

---

## 커맨드 상세

### /orchestrate

6-Phase 개발 파이프라인. `--full`로 고품질 모드.

```
/orchestrate 상품 검색 페이지
/orchestrate --full 상품 검색 페이지
/orchestrate                            ← 이어서 진행
```

#### 내부 동작

```
[Full] Phase 0: Scan
  에이전트: general-purpose (codebase scanner)
  동작: 프로젝트에서 유사 구현 탐색. 재사용 컴포넌트, API 패턴, 상태 관리, 폴더 컨벤션 파악
  출력: plans/{slug}-scan.md
  ↓
Phase 1: Plan
  에이전트: architect (opus, Full만), planner (opus), feasibility-reviewer (sonnet)
  동작: Q&A → 플랜 작성 → 사용자 승인
  Standard: 간단 플랜 (Pages/Components/Hooks/API 체크리스트)
  Full: Opus architect가 컴포넌트 트리, 데이터 흐름도, 인터페이스 계약, 상태 설계, 에러 매트릭스 작성
  MCP: mcp__jira__jira_get_issue (Jira 이슈 있으면)
  출력: plans/{slug}.md
  ↓
Phase 2: Branch
  동작: git worktree add + pnpm install
  ↓
Phase 3: Develop
  참조 Skills: react-patterns, react-testing, react-data-patterns
  참조 Rules: react-composition, react-rendering, a11y, nextjs-app-router, nextjs-performance, coding-style
  동작:
    Standard: 구현 → 검증 루프 (lint→type→build→test, 최대 3회)
    Full: TDD (RED→GREEN→리팩토링) → 검증 루프
  Bash: pnpm lint --fix, pnpm tsc --noEmit, pnpm build, pnpm test
  ↓
Phase 4: PR
  4-0. Lighthouse 체크 (dev 서버 실행 중일 때만)
    Bash: curl (서버 감지), npx lighthouse
    기준: Performance < 50 또는 Accessibility < 80이면 경고

  4-1. 에이전트 리뷰
    Standard — 변경 파일 기준 선별 투입:
      | 에이전트 | 투입 조건 |
      |---------|----------|
      | code-reviewer (sonnet) | 항상 |
      | security-reviewer (sonnet) | .env, auth, token 관련 파일 |
      | react-reviewer (sonnet) | .tsx/.jsx 변경 시 |
      | performance-reviewer (sonnet) | hooks, 대량 렌더링 관련 |
      | convention-reviewer (sonnet) | 네이밍/구조 변경 시 |

    Full — 전원 투입 2라운드:
      위 5개 + feasibility-reviewer, impact-analyzer

  4-2. 커밋 + PR 생성
    Bash: git add, git commit, git push, gh pr create
  ↓
Phase 5: Feedback
  동작: PR 코멘트 반영. /orchestrate 재실행으로 진입
  ↓
Phase 6: Clean
  동작: git worktree remove, git branch -d
```

#### State 파일

`.orchestrate/{slug}.json`에 저장. 세션 끊겨도 이어서 진행.

```json
{
  "slug": "product-search",
  "feature": "상품 검색 페이지",
  "mode": "standard",
  "phase": "develop",
  "branch": "feature/product-search"
}
```

---

### /code-review

5개 에이전트 순차 리뷰.

```
/code-review
```

#### 내부 동작

```
1. git diff main...HEAD로 변경 파일 수집
2. 파일별로 에이전트 투입 결정
3. 순차 실행:
   code-reviewer (sonnet)         → 가독성, 중복, 에러 처리
   convention-reviewer (sonnet)   → 네이밍, 구조, import 순서
   security-reviewer (sonnet)     → XSS, 시크릿, 인증, 의존성
   performance-reviewer (sonnet)  → 렌더링, N+1, 번들, 메모리
   react-reviewer (sonnet)        → hooks 규칙, 렌더 최적화, 컴포넌트 구조
4. CRITICAL/HIGH/MEDIUM/LOW 통합 리포트
```

참조 Rules: coding-style, security, testing, react-composition, react-rendering

---

### /build-fix

빌드 에러 자동 수정 루프.

```
/build-fix
```

#### 내부 동작

```
1. pnpm lint --fix → 실패 시 에러 분석 → 수정
2. pnpm tsc --noEmit → 타입 에러 수정
3. pnpm build → 빌드 에러 수정
4. 최대 5회 반복
```

참조 Rules: coding-style, testing
에이전트: 없음 (Claude가 직접 수정)

---

### /lighthouse

페이지별 Lighthouse 분석.

```
/lighthouse
/lighthouse --pages /,/login,/dashboard
/lighthouse --threshold 90
```

#### 내부 동작

```
1. dev 서버 감지 (포트 3000, 5173, 5174, 4200, 8080 순서)
2. 라우트 자동 탐지
   - Next.js: app/**/page.tsx, pages/**/*.tsx
   - TanStack Router: src/routes/**/*.tsx
   - React Router: src/router.tsx
   - Vite: src/pages/**/*.tsx
3. 페이지별 npx lighthouse 실행
   - Performance, Accessibility, Best Practices, SEO
   - Core Web Vitals: LCP, FCP, TBT, CLS
4. 기준 미달 페이지별 원인 + 개선 제안
```

MCP 폴백: Chrome 없으면 mcp__playwright__browser_evaluate로 기본 측정
Bash: curl, npx lighthouse, rm

---

### /test-coverage

커버리지 분석 + 테스트 자동 생성.

```
/test-coverage
/test-coverage fill      ← 미커버 테스트 생성
```

#### 내부 동작

```
1. pnpm vitest run --coverage → JSON 리포트
2. 미커버 파일/함수/브랜치 식별
3. fill 모드: 우선순위 기반 테스트 생성 → 실행 → 검증
```

참조 Skills: react-testing
참조 Rules: testing
Bash: pnpm vitest run --coverage, pnpm test

---

### /refactor-clean

knip 데드코드 분석 + 자동 제거.

```
/refactor-clean
/refactor-clean exports|deps|files
/refactor-clean fix
```

#### 내부 동작

```
1. pnpm dlx knip --reporter=json → 미사용 export/deps/files
2. pnpm dlx depcheck → 미사용 의존성
3. SAFE/REVIEW/SKIP 분류
   SAFE: import 0건 → 자동 제거
   REVIEW: 동적 import 가능성 → 사용자 확인
   SKIP: entry point, config, .d.ts
4. fix 모드: SAFE 자동 제거 → lint+type+build+test 검증
```

Bash: pnpm dlx knip, pnpm dlx depcheck, pnpm build, pnpm tsc, pnpm test

---

### /verify

전체 검증.

```
/verify
```

#### 내부 동작

```
1. pnpm build
2. pnpm tsc --noEmit
3. pnpm lint
4. pnpm test
5. console.log 감사
6. git status 확인
7. 번들 분석 (full/pre-pr 모드)
8. 접근성 스팟 체크 (pre-pr 모드)
```

참조 Skills: verification-loop
참조 Rules: testing, coding-style

---

### /commit

```
/commit
```

동작: staged 분석 → type 자동 선택 (feat/fix/refactor/docs/chore) → scope 자동 감지 → 메시지 생성 → 확인 → git commit
참조 Rules: git-workflow
금지: Co-Authored-By, git add -A

---

### /fix

```
/fix 로그인 시 500 에러
/fix PROJ-123
```

동작: Jira 조회 → Q&A → 수정 → lint+build 검증 → 수동 테스트 대기 → 커밋
MCP: mcp__jira__jira_get_issue
참조 Rules: git-workflow, security, testing

---

### /jira

```
/jira bug 로그인 실패
/jira task API 연동
```

MCP: mcp__jira__jira_search, mcp__jira__jira_create_issue, mcp__jira__jira_transition_issue

---

## Agents 상세

### base (7개)

| 에이전트 | 모델 | 역할 | 도구 |
|---------|------|------|------|
| architect | opus | 아키텍처 설계 | Read, Grep, Glob, Bash |
| build-error-resolver | sonnet | 빌드 에러 해결 | Read, Write, Edit, Bash, Grep, Glob |
| doc-updater | haiku | 문서/코드맵 업데이트 | Read, Write, Edit, Grep, Glob |
| e2e-runner | sonnet | E2E 테스트 생성/실행 | Read, Write, Edit, Bash, Grep, Glob |
| planner | opus | 기능 설계/분해 | Read, Grep, Glob |
| refactor-cleaner | sonnet | 데드코드 제거 | Read, Write, Edit, Bash, Grep, Glob |
| tdd-guide | sonnet | TDD 가이드 | Read, Write, Edit, Bash, Grep, Glob |

### common (1개)

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| explorer | haiku | 코드베이스 탐색 (읽기 전용) |

### react-next (8개)

| 에이전트 | 모델 | 역할 | 제외 범위 |
|---------|------|------|----------|
| code-reviewer | sonnet | 가독성, 중복, 에러 처리 | 컨벤션, 보안, 성능, React 패턴 |
| convention-reviewer | sonnet | 네이밍, 구조, import | 코드 품질, 보안, 성능 |
| security-reviewer | sonnet | XSS, 시크릿, 인증, 의존성 | 코드, 컨벤션, 성능 |
| performance-reviewer | sonnet | 렌더링, N+1, 번들, 메모리 | 코드, 컨벤션, 보안 |
| react-reviewer | sonnet | hooks, 렌더 최적화, 컴포넌트 구조 | 성능, 보안, 코드, 컨벤션 |
| feasibility-reviewer | sonnet | 플랜 타당성 검증 | - |
| impact-analyzer | sonnet | 변경 영향 범위 분석 | - |
| next-build-resolver | sonnet | Next.js/Vite 빌드 에러 해결 | - |

---

## Rules 상세

### 항상 로드 (14개)

**base-common (9개)**

| 파일 | 내용 |
|------|------|
| agents.md | 에이전트 사용 규칙 |
| coding-style.md | 코딩 스타일 (네이밍, 포맷) |
| development-workflow.md | 개발 워크플로우 |
| git-workflow.md | 커밋 메시지, 브랜치 전략 |
| hooks.md | 훅 작성 규칙 |
| patterns.md | 공통 패턴 |
| performance.md | 성능 규칙 |
| security.md | 보안 규칙 |
| testing.md | 테스트 규칙 |

**base-typescript (5개)**

| 파일 | 내용 |
|------|------|
| coding-style.md | TS 코딩 스타일 |
| hooks.md | TS 훅 규칙 |
| patterns.md | TS 패턴 |
| security.md | TS 보안 |
| testing.md | TS 테스트 |

### 조건부 로드 (7개)

**ccb-common (2개, 항상)**

| 파일 | 내용 |
|------|------|
| jira.md | Jira 이슈 규칙 |
| pull-request.md | PR 작성 규칙 |

**ccb-stack (5개, paths 매칭 시만)**

| 파일 | paths | 내용 |
|------|-------|------|
| react-composition.md | `src/**/*.{tsx,jsx}` | 합성 컴포넌트, Props |
| react-rendering.md | `src/**/*.{tsx,jsx}` | 리렌더 최적화 |
| a11y.md | `src/**/*.{tsx,jsx}` | WCAG AA 접근성 |
| nextjs-app-router.md | `app/**/*`, `next.config.*` | App Router 패턴 |
| nextjs-performance.md | `app/**/*`, `src/**/*.{ts,tsx}` | Next.js 성능 |

---

## Skills 상세

### base (16개)

| 스킬 | 활성화 시점 |
|------|------------|
| api-design | API 설계 시 |
| coding-standards | 코드 작성 시 |
| continuous-learning-v2 | 학습 시스템 |
| database-migrations | DB 마이그레이션 시 |
| deployment-patterns | 배포 관련 |
| docker-patterns | Docker 관련 |
| e2e-testing | E2E 테스트 작성 시 |
| eval-harness | 평가 |
| frontend-patterns | 프론트 패턴 |
| iterative-retrieval | 검색 |
| postgres-patterns | PostgreSQL 관련 |
| search-first | 검색 우선 |
| security-review | 보안 리뷰 시 |
| strategic-compact | 컨텍스트 압축 |
| tdd-workflow | TDD 시 |
| verification-loop | 검증 루프 |

### react-next (3개)

| 스킬 | 활성화 시점 |
|------|------------|
| react-patterns | React 컴포넌트 작성 시 |
| react-testing | React 테스트 작성 시 |
| react-data-patterns | 데이터 페칭/캐싱 시 |

---

## Hooks

`settings.json`에 정의:

| 이벤트 | 동작 |
|--------|------|
| PreToolUse (*) | continuous-learning-v2 관찰 (pre) |
| PostToolUse (*) | continuous-learning-v2 관찰 (post) |

`hooks/hooks.json`에 정의:

base hooks (check-console-log, suggest-compact 등)
