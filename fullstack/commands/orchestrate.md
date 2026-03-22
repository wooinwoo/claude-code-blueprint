---
description: Fullstack feature pipeline. Frontend + Backend 동시 구현. Plan → Branch → Develop → Merge & PR. --front/--back으로 한쪽만 가능.
---

# Orchestrate — Fullstack Pipeline

## Usage

```
/orchestrate 상품 검색 + API                     → 풀스택 (기본)
/orchestrate --front 검색 결과 UI                → 프론트만
/orchestrate --back 검색 API 엔드포인트          → 백엔드만
/orchestrate --full 상품 검색 + API              → 풀스택 Full 모드
/orchestrate --full --front 검색 결과 UI         → 프론트만 Full 모드
/orchestrate PROJ-123                            → Jira 이슈 기반
/orchestrate                                     → 현재 phase 감지 후 자동 진행
```

> `--front`과 `--back`을 동시에 지정하면 fullstack으로 처리합니다 (둘 다 = 전체).

## Scope & Mode

### Scope (범위)

| 스코프 | 플래그 | 설명 |
|--------|--------|------|
| **Fullstack** | (기본) | 프론트 + 백엔드 동시 구현. API 계약 먼저 정의 |
| **Frontend** | `--front` | 프론트엔드만. 기존 API 연동 또는 Mock |
| **Backend** | `--back` | 백엔드만. API 엔드포인트 + DB + 테스트 |

### Mode (품질)

| 모드 | 플래그 | 에이전트 | 설명 |
|------|--------|---------|------|
| **Standard** | (기본) | 5-8개 | 빠른 반복. 선택적 리뷰, 1라운드 |
| **Full** | `--full` | 12-16개 | 최대 품질. 코드베이스 스캔 + architect 설계 + TDD + 전원 리뷰 2라운드 |

state 파일에 `"scope"`와 `"mode"` 저장 → 세션 복구 시 자동 유지.

## Pipeline Detection

**`.orchestrate/` 디렉토리의 `{slug}.json` 파일로 파이프라인을 추적합니다.**

### 파이프라인 선택

| 상황 | 동작 |
|------|------|
| `/orchestrate 검색 페이지` | 새 파이프라인 시작 → `.orchestrate/{slug}.json` 생성 |
| `/orchestrate` + state 1개 | 그 파이프라인 이어감 |
| `/orchestrate` + state 여러개 | 현재 브랜치로 매칭. 못 찾으면 목록 → AskUserQuestion |
| `/orchestrate` + state 0개 | 아래 **신규 파이프라인 가이드** 실행 |

### 신규 파이프라인 가이드 (인수 없이 진입 시)

```typescript
// Step 1: 뭘 만들지
AskUserQuestion([{
  question: "어떤 기능을 만들까요?",
  header: "기능 설명",
  description: "자연어로 설명하거나, Jira 이슈 키(예: PROJ-123)를 입력하세요."
}])

// Step 2: 범위 선택
AskUserQuestion([{
  question: "구현 범위를 선택하세요.",
  header: "스코프",
  options: [
    { label: "Fullstack", description: "프론트 + 백엔드 동시 구현 (API 계약 먼저)" },
    { label: "Frontend", description: "프론트엔드만 (기존 API 연동 또는 Mock)" },
    { label: "Backend", description: "백엔드만 (API + DB + 테스트)" }
  ]
}])

// Step 3: 모드 선택
AskUserQuestion([{
  question: "어떤 모드로 진행할까요?",
  header: "파이프라인 모드",
  options: [
    { label: "Standard", description: "빠른 반복. 에이전트 5-8개, 리뷰 1라운드" },
    { label: "Full", description: "최대 품질. 코드베이스 스캔 + architect 설계 + TDD + 리뷰 2라운드" }
  ]
}])
```

### Phase 감지

state 파일에서 **`phase`, `mode`, `scope`를 모두 읽습니다**:

```bash
phase=$(jq -r '.phase' .orchestrate/{slug}.json)
mode=$(jq -r '.mode' .orchestrate/{slug}.json)     # "standard" 또는 "full"
scope=$(jq -r '.scope' .orchestrate/{slug}.json)   # "fullstack", "frontend", "backend"
```

```
[Full] Phase 0: Scan  → 코드베이스 패턴 스캔 (scope에 따라 프론트/백/둘 다)
                         ↓
Phase 1: Plan          → API 계약 먼저 → 프론트/백 설계 → 승인
                         ↓
Phase 2: Branch        → 워크트리 + 브랜치 생성
                         ↓
Phase 3: Develop       → 구현 (scope에 따라 순서 다름)
                         ↓
Phase 4: PR            → Lighthouse + 에이전트 리뷰 → PR 생성
                         ■ 정지
Phase 5: Feedback      → PR 코멘트 반영
Phase 6: Clean         → 워크트리/브랜치 정리
```

### 자동 연결 규칙

Phase 1 승인 후 **Phase 2→3→4를 한 번에 실행**합니다.
사용자 입력이 필요한 시점은 **Phase 1 (플랜 승인)**과 **Phase 5 (리뷰 피드백)** 뿐입니다.

---

## Phase 0: Codebase Scan

> `mode == "standard"` → 스킵, Phase 1 직행

```
Codebase Scanner (subagent_type: general-purpose)
prompt: "프로젝트에서 '{feature_description}'과 유사한 기존 구현을 찾아줘.

스캔 범위: {scope}

먼저 프로젝트 구조를 파악해줘:
- 모노레포인지 (pnpm-workspace.yaml, turbo.json, nx.json, lerna.json 확인)
- 모노레포면 패키지 경로 (packages/*, apps/* 등)
- 단일 레포면 프론트/백 소스 위치 (src/, src/client/, src/server/ 등)
- 패키지 매니저 (pnpm/npm/yarn/bun — lock 파일로 판별)

그 다음 scope에 따라:
- fullstack: 프론트엔드 + 백엔드 모두
- frontend: 프론트엔드 소스 디렉토리만
- backend: 백엔드 소스 디렉토리만

찾을 것:

[Frontend — scope가 fullstack 또는 frontend일 때]
- 재사용 가능한 컴포넌트, hooks, utils
- API 호출 패턴 (TanStack Query/SWR, axios wrapper)
- 상태 관리 패턴
- 스타일링/테스트 패턴

[Backend — scope가 fullstack 또는 backend일 때]
- 기존 모듈/컨트롤러/서비스 구조
- Entity/DTO 패턴
- Guard/Interceptor/Pipe 사용법
- DB 쿼리 패턴 (TypeORM/Prisma/Drizzle)
- E2E 테스트 패턴

[공통]
- 폴더 구조 컨벤션
- API 라우팅/네이밍 규칙"
```

스캔 결과를 `plans/{slug}-scan.md`에 저장. Phase 1, 3에서 참조.

---

## Phase 1: Plan

> **모드 분기**:
> - Standard: 간단 플랜 (체크리스트)
> - Full: **architect(opus) 에이전트가 심층 설계** — 컴포넌트 트리, 데이터 흐름도, 인터페이스 계약, 에러 매트릭스

### 1-1. Jira 확인

Jira 이슈가 있으면 가져오고, 없으면 새로 생성하거나 standalone.

### 1-2. 요구사항 Q&A

> **스코프 분기**: scope에 따라 질문이 달라짐

**Fullstack:**
- 목적과 사용자 가치
- **API 계약** — 엔드포인트, 요청/응답 스펙, 인증/인가
- UI/UX 명세 — 화면, 인터랙션, 반응형
- **데이터 모델** — 테이블/엔티티 구조, 관계
- 상태 관리 — 서버 상태(Query) vs 클라이언트 상태
- 에러/로딩/빈 상태 UI + API 에러 응답
- **비즈니스 로직 위치** — 프론트에서 처리 vs API에서 처리

**Frontend만:** 목적, UI/UX, 데이터 흐름, 상태 관리, 반응형

**Backend만:** 목적, API 스펙, 데이터 모델, 비즈니스 로직, 인증/인가, 검증 규칙

### 1-3. 플랜 작성

> **스코프 분기**: fullstack은 API 계약이 핵심

#### Fullstack 플랜

```markdown
# {feature name}

## Tracking
- Issue: {JIRA-KEY 또는 standalone}
- Scope: fullstack
- Mode: {standard|full}

## API Contract (프론트-백 공유 인터페이스)

### Endpoints
| Method | Path | Request | Response | Auth |
|--------|------|---------|----------|------|
| GET | /api/v1/products | { page, limit, filter } | { items[], total } | Bearer |
| POST | /api/v1/products | { name, price, ... } | { id, ...created } | Bearer |

### Shared Types
```typescript
// 프론트와 백에서 동일하게 사용
interface Product {
  id: string;
  name: string;
  price: number;
}

interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}
```

## Backend Architecture

### Modules
- [ ] {ModuleName} — {역할}

### Entities / DTOs
- [ ] {Entity} — {테이블 설명}
- [ ] {CreateDto} — {검증 규칙}

### Services
- [ ] {ServiceName} — {비즈니스 로직}

## Frontend Architecture

### Pages / Routes
- [ ] {PageName} — {설명}

### Components
- [ ] {ComponentName} — {역할}

### Hooks / State
- [ ] {useHookName} — {목적}

## Implementation Order
1. **API Contract** — 공유 타입 정의
2. **Backend** — Entity → Service → Controller → E2E 테스트
3. **Frontend** — API 서비스 → Hooks → 컴포넌트 → 페이지
4. **통합 확인** — 프론트 ↔ 백 연동
```

#### Frontend / Backend 단독 플랜

해당 스택의 기존 orchestrate 플랜 형식 사용.

### 1-4. 사용자 승인

승인 후 **멈추지 않고 Phase 2→3→4 연속 실행**.

플랜 저장 전 디렉토리 확인:
```bash
mkdir -p plans
mkdir -p .orchestrate
```

---

## Phase 2: Branch

```bash
git worktree add .worktrees/{slug} -b feature/{slug}
cd .worktrees/{slug}

# 패키지 매니저 자동 감지 (lock 파일 기준)
if [ -f pnpm-lock.yaml ]; then pnpm install
elif [ -f package-lock.json ]; then npm install
elif [ -f yarn.lock ]; then yarn install
elif [ -f bun.lockb ]; then bun install
elif [ -f package.json ]; then npm install  # lock 없으면 npm 기본
else echo "⚠️ package.json 없음 — install 스킵"
fi
```

### git remote 확인

```bash
# PR 생성을 위해 remote 필요. 없으면 Phase 4에서 PR 스킵
remote_exists=$(git remote -v | head -1)
if [ -z "$remote_exists" ]; then
  echo "⚠️ git remote 없음. Phase 4에서 PR 생성을 스킵하고 로컬 커밋만 진행합니다."
fi
```

---

## Phase 3: Develop

> **스코프 분기**: 구현 순서가 달라짐

### Fullstack — 백엔드 먼저, 프론트 나중

API가 먼저 있어야 프론트에서 연동할 수 있음. Mock 대신 실제 API 사용.

```
Step 1: 공유 타입 정의 (API Contract의 TypeScript 타입)
        ↓
Step 2: 백엔드 구현
        - Entity/DTO 생성
        - Service 비즈니스 로직
        - Controller 엔드포인트
        - E2E 테스트
        ↓
Step 3: 백엔드 검증 루프 (lint → type → build → test, 최대 3회)
        ↓
Step 4: 프론트엔드 구현
        - API 서비스 (실제 백엔드 연동)
        - Custom hooks (TanStack Query)
        - UI 컴포넌트
        - 페이지 조립
        ↓
Step 5: 프론트엔드 검증 루프 (lint → type → build → test, 최대 3회)
        ↓
Step 6: 통합 확인
        - 공유 타입 일치: 프론트 API 서비스와 백엔드 DTO 간 타입 불일치 없는지 tsc 확인
        - 백엔드 E2E 테스트 실행 (있으면)
        - 프론트 빌드 성공 확인 (백엔드 연동 코드 포함)
        - 에러 핸들링 코드 존재 확인: Grep으로 API 서비스에서 401/404/500 처리 여부
```

### Frontend / Backend 단독

해당 스택의 기존 orchestrate Phase 3 로직 사용.

### 검증 루프 (공통)

```bash
# package.json scripts 확인 후 있는 것만 실행
# 감지된 패키지 매니저 사용 (Phase 2에서 저장)
if script_exists "lint"; then ${pm} lint --fix; fi
if script_exists "tsc" || has_tsconfig; then ${pm} tsc --noEmit; fi
if script_exists "build"; then ${pm} build; fi
if script_exists "test"; then ${pm} test; fi
```

스크립트가 하나도 없으면 "⚠️ 검증 스크립트 없음 — 타입체크만 시도" 후 `npx tsc --noEmit`만 실행.
실패 시 에러 분석 → 수정 → 재검증. 최대 3회.

### [Full] TDD 모드

각 구현 그룹마다 테스트 먼저 (RED) → 구현 (GREEN) → 리팩토링 → 커밋.

---

## Phase 4: PR

### 4-0. Lighthouse 체크

> scope가 backend만이면 스킵. dev 서버 미실행 시 스킵.

```typescript
if (scope !== "backend") {
  const devServer = Bash("curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 || curl -s -o /dev/null -w '%{http_code}' http://localhost:5173")

  if (devServer === "200") {
    // Lighthouse 실행 — Performance, Accessibility, Best Practices
    // Performance < 50 또는 Accessibility < 80이면 경고 (차단 안 함)
  }
}
```

### 4-1. 에이전트 리뷰

> **스코프 분기**: 투입 에이전트가 달라짐
> **모드 분기**: Standard는 1라운드, **Full은 2라운드** (1라운드 피드백 반영 후 재리뷰)

#### Fullstack — 프론트 + 백엔드 리뷰어 전부 투입

| 에이전트 | 구분 | 투입 조건 |
|---------|------|----------|
| **Code Review** | 필수 | 항상 |
| **Security Review** | 필수 | 항상 |
| **React Reviewer** | 조건부 | .tsx/.jsx 변경 시 |
| **Performance Reviewer** | 조건부 | 컴포넌트/훅 변경 시 |
| **NestJS Pattern Reviewer** | 조건부 | .module.ts/.controller.ts 변경 시 |
| **Database Reviewer** | 조건부 | .entity.ts/.migration.ts, schema.prisma, drizzle schema 변경 시 |
| **Convention Reviewer** | 선택 | Full 모드에서만 |
| **Schema Designer** | 선택 | Full 모드 + DB 스키마 변경 시 |

#### Frontend / Backend 단독

해당 스택의 기존 리뷰 에이전트 사용.

### 4-2. 커밋 & PR 생성

```bash
git add {specific files}
git commit -m "{type}({scope}): {description}"

# remote 있으면 push + PR
if git remote -v | grep -q origin; then
  git push -u origin {branch}
  gh pr create --title "{type}({scope}): {description}" --body "..."
else
  echo "⚠️ git remote 없음. 로컬 커밋만 완료. push/PR은 remote 설정 후 수동으로."
fi
```

PR 본문 (PR 생성 시):
- 변경 요약 (프론트/백 구분)
- API Contract 변경 사항
- 테스트 결과
- Lighthouse 점수 (해당 시)

**여기서 정지. 리뷰 대기. (remote 없으면 로컬 커밋 상태로 종료)**

---

## Phase 5: Feedback

PR 코멘트 반영. `/orchestrate` 재실행으로 진입.

---

## Phase 6: Clean

```bash
git worktree remove .worktrees/{slug}
git branch -d feature/{slug}
```

---

## State 파일

```json
{
  "slug": "product-search",
  "feature": "상품 검색 + API",
  "scope": "fullstack",
  "mode": "standard",
  "phase": "develop",
  "branch": "feature/product-search",
  "jira_key": "PROJ-123",
  "created_at": "2026-03-22T10:00:00Z",
  "worktree_path": ".worktrees/product-search",
  "plan_path": "plans/product-search.md",
  "scan_path": "plans/product-search-scan.md",
  "package_manager": "pnpm",
  "project_structure": "monorepo",
  "develop_progress": {
    "shared_types": "done",
    "backend_impl": "done",
    "backend_verify": "done",
    "frontend_impl": "in_progress",
    "frontend_verify": "pending",
    "integration": "pending"
  }
}
```

`develop_progress`는 fullstack scope일 때만 사용. frontend/backend 단독이면 불필요.
세션 복구 시 `develop_progress`를 읽어 완료된 step은 건너뛰고 이어서 진행.
