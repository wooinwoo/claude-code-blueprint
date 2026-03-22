# 에이전트 상세

에이전트는 독립된 컨텍스트에서 실행되는 특화 AI. 메인 대화 토큰을 소비하지 않음.

---

## Base (7개) — 전 프로필 공통

### architect

| | |
|--|--|
| 모델 | opus |
| 도구 | Read, Grep, Glob, Bash |
| 호출 | orchestrate Phase 1 (Full 모드) |

컴포넌트 트리, 데이터 흐름도, 인터페이스 계약, 상태 설계, 에러 매트릭스를 작성.
Phase 0 스캔 결과를 기반으로 기존 패턴과 재사용 에셋을 최대한 활용.

### planner

| | |
|--|--|
| 모델 | opus |
| 도구 | Read, Grep, Glob |
| 호출 | orchestrate Phase 1 |

기능을 구현 가능한 단위로 분해. 병렬 가능 그룹 식별. 각 Task에 파일 목록과 완료 기준 테스트 부여.

### build-error-resolver

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Write, Edit, Bash, Grep, Glob |
| 호출 | /build-fix |

lint → type → build 순서로 에러 분석. 최소 변경으로 수정. 리팩토링 금지. 최대 5회 루프.

### tdd-guide

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Write, Edit, Bash, Grep, Glob |
| 호출 | orchestrate Phase 3 (Full 모드 TDD) |

RED → GREEN → Refactor 사이클 가이드. 테스트 먼저 작성, 최소 구현, 리팩토링.

### e2e-runner

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Write, Edit, Bash, Grep, Glob |
| 호출 | E2E 테스트 작성/실행 시 |

Playwright 기반 E2E 테스트 생성. 주요 사용자 흐름 커버.

### refactor-cleaner

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Write, Edit, Bash, Grep, Glob |
| 호출 | /refactor-clean |

데드코드만 제거. 활성 개발 중인 코드 건드리지 않음. SAFE/REVIEW/SKIP 분류.

### doc-updater

| | |
|--|--|
| 모델 | haiku |
| 도구 | Read, Write, Edit, Grep, Glob |
| 호출 | 문서/코드맵 업데이트 시 |

README, API 문서, 코드맵 업데이트. 가장 저렴한 모델.

---

## Common (1개)

### explorer

| | |
|--|--|
| 모델 | haiku |
| 도구 | Read, Grep, Glob (읽기 전용) |
| 호출 | 코드베이스 탐색 시 자동 |

파일 탐색, 코드 검색, 구조 분석. 쓰기 도구 없음.

---

## Frontend 전용 (8개)

### code-reviewer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | /code-review, orchestrate Phase 4 |
| 담당 | 가독성, 중복, 함수/파일 크기, 에러 처리 |
| 제외 | 컨벤션, 보안, 성능, React 패턴 (다른 에이전트 담당) |

출력: `[SEVERITY] 파일:라인 — 이슈 — 제안`

### convention-reviewer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | /code-review, orchestrate Phase 4 |
| 담당 | 네이밍, 폴더 구조, import 순서, 파일 네이밍 |
| 제외 | 코드 품질, 보안, 성능 |

### security-reviewer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | /code-review, orchestrate Phase 4 (항상) |
| 담당 | XSS, 하드코딩 시크릿, 인증/인가 누락, 의존성 취약점 |
| 제외 | 코드, 컨벤션, 성능 |
| Red Flags | `eval()`, `innerHTML`, `.env`에 토큰, SQL 직접 조합 |

### performance-reviewer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | /code-review, orchestrate Phase 4 (컴포넌트/훅 변경 시) |
| 담당 | 불필요한 리렌더, N+1, 번들 사이즈, 메모리 릭 |
| 제외 | 코드, 컨벤션, 보안 |

### react-reviewer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | /code-review, orchestrate Phase 4 (.tsx/.jsx 변경 시) |
| 담당 | hooks 규칙 (deps, 호출 순서), 렌더 최적화 (memo, useMemo, useCallback), 컴포넌트 합성 |
| 제외 | 성능, 보안, 코드, 컨벤션 |

### feasibility-reviewer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | orchestrate Phase 1 (플랜 검증) |
| 담당 | 플랜의 기술적 타당성, 기존 코드와 충돌 여부, 누락된 엣지케이스 |

### impact-analyzer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | orchestrate Phase 1 (변경 영향 분석) |
| 담당 | 변경 범위 추정, 영향 받는 파일/모듈 식별, 사이드이펙트 예측 |

### next-build-resolver

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Write, Edit, Bash, Grep, Glob |
| 호출 | Next.js/Vite 빌드 에러 시 |
| 담당 | App Router, Server/Client 컴포넌트, Vite 번들러 에러 해결 |

---

## Backend 전용 (8개)

### code-reviewer, convention-reviewer, security-reviewer

프론트와 동일한 역할. NestJS 컨텍스트에서 동작.

### database-reviewer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | /code-review, orchestrate Phase 4 (.entity.ts, schema.prisma, drizzle schema 변경 시) |
| 담당 | 스키마 설계, 인덱스, 쿼리 최적화, 마이그레이션 안전성 |
| 제외 | 코드, 컨벤션, 보안 |

### nestjs-pattern-reviewer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Grep, Glob |
| 호출 | /code-review, orchestrate Phase 4 (.module.ts, .controller.ts 변경 시) |
| 담당 | Module 구조, Provider 등록, Guard/Interceptor/Pipe 사용, DI 패턴 |
| 제외 | 코드, DB, 보안 |

### schema-designer

| | |
|--|--|
| 모델 | sonnet |
| 도구 | Read, Write, Edit, Grep, Glob |
| 호출 | orchestrate Phase 1 (Full, DB 스키마 설계), Phase 4 (Full, 스키마 변경 리뷰) |
| 담당 | ERD, 정규화, 관계 설계, 인덱스 전략 |

### feasibility-reviewer, impact-analyzer

프론트와 동일.

---

## Fullstack — 에이전트 조합

프론트 8개 + 백엔드 전용 3개 = **11개**

| 에이전트 | 출처 | 투입 조건 (orchestrate Phase 4) |
|---------|------|------|
| code-reviewer | react-next | 항상 |
| security-reviewer | react-next | 항상 |
| react-reviewer | react-next | .tsx/.jsx 변경 시 |
| performance-reviewer | react-next | 컴포넌트/훅 변경 시 |
| convention-reviewer | react-next | Full 모드 |
| feasibility-reviewer | react-next | Phase 1 |
| impact-analyzer | react-next | Phase 1 |
| next-build-resolver | react-next | 빌드 에러 시 |
| **database-reviewer** | **nestjs** | .entity.ts, schema.prisma 변경 시 |
| **nestjs-pattern-reviewer** | **nestjs** | .module.ts, .controller.ts 변경 시 |
| **schema-designer** | **nestjs** | Full + DB 스키마 변경 시 |

겹치는 에이전트(code-reviewer 등)는 react-next 버전 사용.

---

## 에이전트 간 역할 분리 원칙

각 에이전트는 **"검토하지 않는 것"**을 명시.
하나의 프롬프트에 "다 봐줘"라고 하면 각 관점이 얕아짐.
역할 분리하면 각 관점에서 더 깊이 파고듦.

```
code-reviewer      → 보안 안 봄 (security-reviewer가 봄)
security-reviewer  → 성능 안 봄 (performance-reviewer가 봄)
react-reviewer     → 컨벤션 안 봄 (convention-reviewer가 봄)
database-reviewer  → NestJS 패턴 안 봄 (nestjs-pattern-reviewer가 봄)
```

중복 지적 방지 + 각 관점 깊이 확보.
