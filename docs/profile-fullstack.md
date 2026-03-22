# CCB Fullstack 프로필 상세

`setup.ps1 fullstack <경로>`

---

## 설치 구성

| 항목 | 수량 | 출처 |
|------|------|------|
| Agents | 19 | base 7 + common 1 + fullstack 11 (react-next 8 + nestjs 전용 3) |
| Commands | 15 | base 3 + common 9 + fullstack 4 |
| Rules | 23 | base-common 9 + base-typescript 5 + ccb-common 2 + ccb-stack 7 |
| Skills | 20 | base 16 + fullstack 4 (react 3 + hexagonal-architecture) |
| Hooks | 2 | base (pre/post tool use) |
| MCP | 9 | github, jira, context7, memory, figma, playwright, mysql, aws, aws-api |
| Plugins | 1 | typescript-lsp |

---

## 프론트/백엔드 프로필과의 차이

| | react-next | nestjs | **fullstack** |
|--|-----------|--------|---------------|
| Agents | 16 | 16 | **19** (양쪽 합침 + 중복 제거) |
| Commands | 15 | 13 | **15** (orchestrate가 scope 분기) |
| Rules | 21 | 18 | **23** (양쪽 룰 합산) |
| Skills | 19 | 17 | **20** |
| 토큰 고정비용 | ~3,800 | ~3,200 | **~4,300** |
| orchestrate scope | 프론트 고정 | 백엔드 고정 | **fullstack/--front/--back** |

---

## 상황별 커맨드 가이드

| 상황 | 커맨드 |
|------|--------|
| 새 기능 (프론트+백엔드) | `/orchestrate` |
| 프론트만 | `/orchestrate --front` |
| 백엔드만 | `/orchestrate --back` |
| 고품질 모드 | `/orchestrate --full` |
| 빠른 버그 수정 | `/fix` |
| 코드 리뷰 | `/code-review` |
| 빌드 깨짐 | `/build-fix` |
| 배포 전 성능 체크 | `/lighthouse` |
| 테스트 커버리지 | `/test-coverage` |
| 데드코드 정리 | `/refactor-clean` |
| worktree 관리 | `/wt` |
| 커밋 | `/commit` |
| Jira | `/jira` |

---

## 커맨드 상세

### /orchestrate (풀스택 전용)

프론트 + 백엔드 동시 구현. scope + mode 2축 분기.

```
/orchestrate 상품 관리 CRUD + API       ← fullstack (기본)
/orchestrate --front 검색 UI           ← 프론트만
/orchestrate --back 검색 API           ← 백엔드만
/orchestrate --full 상품 관리          ← fullstack + 고품질
/orchestrate --full --front 검색 UI    ← 프론트만 + 고품질
/orchestrate                           ← 이어서 진행
```

인수 없이 실행 시 3단계 가이드:
1. "어떤 기능?" → 자유 입력 또는 Jira 키
2. "범위?" → Fullstack / Frontend / Backend
3. "모드?" → Standard / Full

#### 내부 동작 — Fullstack scope

```
[Full] Phase 0: Scan
  에이전트: general-purpose
  scope에 따라 스캔 범위:
    fullstack: 프론트 + 백엔드 모두
    frontend: 컴포넌트, 페이지, hooks, 서비스
    backend: 모듈, 컨트롤러, 서비스, 엔티티
  추가: 모노레포 감지 (pnpm-workspace.yaml, turbo.json, nx.json)
  추가: 패키지매니저 감지 (lock 파일 기준)
  ↓
Phase 1: Plan
  에이전트: architect (opus, Full), planner (opus)
  핵심: **API Contract 먼저 정의**

  Fullstack Q&A:
    - 목적과 사용자 가치
    - API 계약 (엔드포인트, 요청/응답, 인증)
    - UI/UX 명세
    - 데이터 모델 (테이블/엔티티)
    - 상태 관리 (서버 vs 클라이언트)
    - 비즈니스 로직 위치 (프론트 vs API)

  Frontend Q&A: 목적, UI/UX, 데이터 흐름, 상태 관리
  Backend Q&A: 목적, API 스펙, 데이터 모델, 비즈니스 로직

  플랜 구조 (Fullstack):
    ## API Contract (공유 인터페이스)
    ### Endpoints 테이블
    ### Shared TypeScript Types
    ## Backend Architecture (Module/Entity/Service)
    ## Frontend Architecture (Page/Component/Hook)
    ## Implementation Order

  MCP: mcp__jira__jira_get_issue
  ↓
Phase 2: Branch
  동작: git worktree add + 패키지매니저 자동 감지 install
  ↓
Phase 3: Develop — **백엔드 먼저, 프론트 나중**
  이유: 실제 API가 있어야 프론트에서 Mock 없이 연동 가능

  Step 1: 공유 타입 정의 (API Contract의 TypeScript 타입)
    ↓
  Step 2: 백엔드 구현
    Entity/DTO → Service → Controller → E2E 테스트
    참조 Skills: hexagonal-architecture
    참조 Rules: backend-architecture, nestjs-e2e-testing
    ↓
  Step 3: 백엔드 검증 루프 (lint→type→build→test, 최대 3회)
    ↓
  Step 4: 프론트엔드 구현
    API 서비스 (실제 백엔드 연동) → Custom hooks → UI 컴포넌트 → 페이지
    참조 Skills: react-patterns, react-testing, react-data-patterns
    참조 Rules: react-composition, react-rendering, a11y
    ↓
  Step 5: 프론트엔드 검증 루프 (lint→type→build→test, 최대 3회)
    ↓
  Step 6: 통합 확인
    프론트 → 백엔드 API 호출 정상 확인
    에러 케이스 (401, 404, 500) 핸들링 확인

  --front scope: Step 4-5만
  --back scope: Step 2-3만

  Full 모드: 각 Step에서 TDD 강제

  State 파일에 develop_progress 저장:
    {
      "shared_types": "done",
      "backend_impl": "done",
      "backend_verify": "done",
      "frontend_impl": "in_progress",
      "frontend_verify": "pending",
      "integration": "pending"
    }
  세션 끊기면 완료된 Step은 건너뛰고 이어서 진행
  ↓
Phase 4: PR
  4-0. Lighthouse (scope가 backend가 아닐 때만)
    Bash: curl (서버 감지), npx lighthouse

  4-1. 에이전트 리뷰 — 양쪽 리뷰어 전부 투입

    | 에이전트 | 구분 | 투입 조건 |
    |---------|------|----------|
    | code-reviewer (sonnet) | 필수 | 항상 |
    | security-reviewer (sonnet) | 필수 | 항상 |
    | react-reviewer (sonnet) | 조건부 | .tsx/.jsx 변경 시 |
    | performance-reviewer (sonnet) | 조건부 | 컴포넌트/훅 변경 시 |
    | nestjs-pattern-reviewer (sonnet) | 조건부 | .module.ts/.controller.ts 변경 시 |
    | database-reviewer (sonnet) | 조건부 | .entity.ts, schema.prisma, drizzle schema 변경 시 |
    | convention-reviewer (sonnet) | Full만 | 전체 |
    | schema-designer (sonnet) | Full만 | DB 스키마 변경 시 |

    --front scope: React 리뷰어만
    --back scope: NestJS 리뷰어만

  4-2. 커밋 + PR
    PR 본문: 프론트/백 변경 구분, API Contract 변경사항 포함
  ↓
Phase 5: Feedback → Phase 6: Clean
```

#### State 파일

```json
{
  "slug": "product-search",
  "feature": "상품 검색 + API",
  "scope": "fullstack",
  "mode": "standard",
  "phase": "develop",
  "branch": "feature/product-search",
  "jira_key": "PROJ-123",
  "worktree_path": ".worktrees/product-search",
  "plan_path": "plans/product-search.md",
  "scan_path": "plans/product-search-scan.md",
  "package_manager": "pnpm",
  "project_structure": "monorepo",
  "develop_progress": {
    "shared_types": "done",
    "backend_impl": "in_progress",
    "backend_verify": "pending",
    "frontend_impl": "pending",
    "frontend_verify": "pending",
    "integration": "pending"
  }
}
```

---

### /code-review (풀스택)

양쪽 에이전트 전부 투입. 변경 파일에 따라 자동 선별.

```
/code-review
```

동작:
1. git diff main...HEAD
2. .tsx/.jsx → react-reviewer, performance-reviewer
3. .module.ts/.controller.ts → nestjs-pattern-reviewer
4. .entity.ts/schema.prisma → database-reviewer
5. 전체 → code-reviewer, security-reviewer, convention-reviewer
6. CRITICAL/HIGH/MEDIUM/LOW 통합 리포트

---

### /wt, /test-coverage, /verify, /build-fix, /lighthouse, /refactor-clean, /commit, /fix, /jira

프론트/백엔드 프로필과 동일. 해당 문서 참조.

---

## Agents 상세

### fullstack (11개) = react-next 8 + nestjs 전용 3

**react-next에서 온 것 (8개)**

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| code-reviewer | sonnet | 가독성, 중복, 에러 처리 |
| convention-reviewer | sonnet | 네이밍, 구조, import |
| security-reviewer | sonnet | XSS, 시크릿, 인증 |
| performance-reviewer | sonnet | 렌더링, 번들, 메모리 |
| react-reviewer | sonnet | hooks, 렌더 최적화 |
| feasibility-reviewer | sonnet | 플랜 타당성 |
| impact-analyzer | sonnet | 변경 영향 범위 |
| next-build-resolver | sonnet | 빌드 에러 해결 |

**nestjs 전용 추가 (3개)**

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| database-reviewer | sonnet | 스키마, 쿼리, 마이그레이션, 인덱스 |
| nestjs-pattern-reviewer | sonnet | Module 구조, DI, 데코레이터 |
| schema-designer | sonnet | DB 스키마 설계 |

**중복 해결**: code-reviewer, convention-reviewer, feasibility-reviewer, impact-analyzer, security-reviewer는 react-next 버전 사용 (프론트 관점이 더 범용적).

---

## Rules 상세

### 항상 로드 (16개)

base-common 9 + base-typescript 5 + ccb-common 2 — 프론트/백엔드와 동일

### 조건부 로드 (7개, paths 매칭 시)

**react-next에서 온 것 (5개)**

| 파일 | paths |
|------|-------|
| react-composition.md | `src/**/*.{tsx,jsx}` |
| react-rendering.md | `src/**/*.{tsx,jsx}` |
| a11y.md | `src/**/*.{tsx,jsx}` |
| nextjs-app-router.md | `app/**/*`, `next.config.*` |
| nextjs-performance.md | `app/**/*`, `src/**/*.{ts,tsx}` |

**nestjs에서 온 것 (2개)**

| 파일 | paths |
|------|-------|
| backend-architecture.md | `src/**/*.ts`, `test/**/*.ts` |
| nestjs-e2e-testing.md | `src/**/*.ts`, `test/**/*.ts` |

---

## Skills 상세

### base (16개)

프론트/백엔드와 동일.

### fullstack (4개)

| 스킬 | 출처 | 활성화 시점 |
|------|------|------------|
| react-patterns | react-next | React 컴포넌트 작성 시 |
| react-testing | react-next | React 테스트 작성 시 |
| react-data-patterns | react-next | 데이터 페칭/캐싱 시 |
| hexagonal-architecture | nestjs | NestJS 모듈 설계 시 |

---

## Hooks

프론트/백엔드와 동일. continuous-learning-v2 관찰.

---

## 토큰 비용

fullstack이 가장 비쌈:
- 세션 고정: ~4,300 (react 21 + nestjs 2 = 23 Rules)
- orchestrate fullstack Standard: 50K~150K (백+프론트 순차)
- orchestrate fullstack Full: 120K~300K

절약: paths가 걸린 7개 룰은 해당 파일 작업 시만 로드.
프론트 파일만 작업하면 nestjs 룰 2개는 안 읽힘. 반대도 마찬가지.
