# CCB Backend (nestjs) 프로필 상세

`setup.ps1 nestjs <경로>`

---

## 설치 구성

| 항목 | 수량 | 출처 |
|------|------|------|
| Agents | 16 | base 7 + common 1 + nestjs 8 |
| Commands | 13 | base 3 + common 9 + nestjs 2 |
| Rules | 18 | base-common 9 + base-typescript 5 + ccb-common 2 + ccb-stack 2 |
| Skills | 17 | base 16 + nestjs 1 |
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
| 데드코드 정리 | `/refactor-clean` |
| 전체 검증 (lint+type+build+test) | `/verify` |
| 커밋 | `/commit` |
| Jira 이슈 관리 | `/jira` |
| worktree 관리 | `/wt` |
| 뭘 써야 할지 모르겠음 | `/guide` |

---

## 커맨드 상세

### /orchestrate

6-Phase 개발 파이프라인.

```
/orchestrate 문의 기능
/orchestrate --full 문의 기능
/orchestrate
```

#### 내부 동작

```
[Full] Phase 0: Scan
  에이전트: general-purpose
  동작: DI 패턴, Entity/Repository 구조, Guard/Interceptor, 테스트 패턴 스캔
  ↓
Phase 1: Plan
  에이전트: architect (opus, Full만), planner (opus), feasibility-reviewer (sonnet)
  Full 추가: schema-designer가 DB 스키마 검증
  동작: Q&A → 플랜 (Module/Controller/Service/Entity 체크리스트)
  MCP: mcp__jira__jira_get_issue
  ↓
Phase 2: Branch
  동작: git worktree add + pnpm install
  ↓
Phase 3: Develop
  참조 Skills: hexagonal-architecture
  참조 Rules: backend-architecture, nestjs-e2e-testing, coding-style, security
  구현 순서: Domain Layer → Infrastructure Layer → Application Layer
  Standard: 구현 → 검증 루프
  Full: TDD (RED→GREEN→리팩토링)
  Bash: pnpm biome check, pnpm tsc --noEmit, pnpm build, pnpm test:e2e
  ↓
Phase 4: PR
  에이전트 리뷰:
    Standard — 선별 투입:
      | 에이전트 | 투입 조건 |
      |---------|----------|
      | code-reviewer (sonnet) | 항상 |
      | security-reviewer (sonnet) | auth, guard, token 관련 |
      | database-reviewer (sonnet) | .entity.ts, .migration.ts 변경 시 |
      | nestjs-pattern-reviewer (sonnet) | .module.ts, .controller.ts 변경 시 |
      | convention-reviewer (sonnet) | 네이밍/구조 변경 시 |

    Full — 전원 2라운드:
      위 5개 + schema-designer, feasibility-reviewer, impact-analyzer

  커밋 + PR: git add, git commit, git push, gh pr create
  ↓
Phase 5: Feedback
  ↓
Phase 6: Clean
```

---

### /code-review

5개 에이전트 순차 리뷰.

```
/code-review
```

#### 내부 동작

```
1. git diff main...HEAD
2. 순차 실행:
   code-reviewer (sonnet)              → 가독성, 중복, 에러 처리
   convention-reviewer (sonnet)        → 네이밍, 구조, DI 패턴
   security-reviewer (sonnet)          → 인증, 인가, 인젝션
   database-reviewer (sonnet)          → 스키마, 쿼리, 마이그레이션
   nestjs-pattern-reviewer (sonnet)    → Module 구조, DI, 데코레이터
3. CRITICAL/HIGH/MEDIUM/LOW 통합 리포트
```

참조 Rules: backend-architecture, nestjs-e2e-testing, coding-style, security

---

### /wt

Git worktree 관리.

```
/wt new 기능명       ← worktree + 브랜치 생성 + .env 복사 + install
/wt list            ← 현재 worktree 목록
/wt sync            ← .env를 모든 worktree에 동기화
/wt rm 기능명       ← worktree + 브랜치 삭제
```

Bash: git worktree add/remove/list, pnpm install, cp (.env)

---

### /build-fix

```
/build-fix
```

동작: pnpm biome check → pnpm tsc --noEmit → pnpm build → 최대 5회 루프

---

### /refactor-clean

```
/refactor-clean
/refactor-clean fix
```

동작: knip → depcheck → SAFE/REVIEW/SKIP 분류 → fix 모드에서 자동 제거
NestJS 특화: `@Injectable`, `@Controller`, `@Module`, `@Resolver`, `@Entity`, `@Schema` 데코레이터 파일은 자동 SKIP (knip이 DI 추적 못 함)

---

### /commit, /fix, /jira, /verify, /lighthouse

프론트 프로필과 동일. profile-frontend.md 참조.

---

## Agents 상세

### base (7개)

프론트와 동일. profile-frontend.md 참조.

### common (1개)

explorer (haiku) — 코드베이스 탐색

### nestjs (8개)

| 에이전트 | 모델 | 역할 | 제외 범위 |
|---------|------|------|----------|
| code-reviewer | sonnet | 가독성, 중복, 에러 처리 | 컨벤션, 보안, DB, NestJS 패턴 |
| convention-reviewer | sonnet | 네이밍, 구조, DI 패턴 | 코드 품질, 보안, DB |
| security-reviewer | sonnet | 인증, 인가, 인젝션, 의존성 | 코드, 컨벤션, DB |
| database-reviewer | sonnet | 스키마, 쿼리, 마이그레이션, 인덱스 | 코드, 컨벤션, 보안 |
| nestjs-pattern-reviewer | sonnet | Module 구조, Provider, Guard, Pipe | 코드, DB, 보안 |
| schema-designer | sonnet | DB 스키마 설계 | - |
| feasibility-reviewer | sonnet | 플랜 타당성 | - |
| impact-analyzer | sonnet | 변경 영향 범위 | - |

---

## Rules 상세

### 항상 로드 (16개)

base-common 9개 + base-typescript 5개 + ccb-common 2개 — 프론트와 동일

### 조건부 로드 (2개, paths 매칭 시)

| 파일 | paths | 내용 |
|------|-------|------|
| backend-architecture.md | `src/**/*.ts`, `test/**/*.ts` | 헥사고날 아키텍처, 레이어 분리 |
| nestjs-e2e-testing.md | `src/**/*.ts`, `test/**/*.ts` | E2E 테스트 작성 규칙 |

---

## Skills 상세

### base (16개)

프론트와 동일.

### nestjs (1개)

| 스킬 | 활성화 시점 |
|------|------------|
| hexagonal-architecture | NestJS 모듈 설계 시 |

---

## Hooks

프론트와 동일. continuous-learning-v2 관찰.
