# CCB 성능 리뷰 — 프론트 / 백엔드 / 풀스택

---

## 현재 구조

```
setup.ps1 <프로필> <경로>
├── react-next    agents 16 / commands 15 / rules 21 / skills 19
├── nestjs        agents 16 / commands 13 / rules 18 / skills 17
├── fullstack     agents 19 / commands 15 / rules 23 / skills 20
├── designer      agents 3  / commands 9  / rules 8  / skills 7
└── planner       agents 3  / commands 14 / rules 7  / skills 5
```

---

## 프로필별 토큰 비용

### 매 세션 고정 (항상 로드)

| 항목 | react-next | nestjs | fullstack |
|------|-----------|--------|-----------|
| CLAUDE.md | ~500 | ~500 | ~500 |
| Rules (paths 없는 것) | ~2,500 | ~2,000 | ~3,000 |
| Rules (paths 있는 것) | 해당 파일 작업 시만 | 동일 | 동일 |
| Skills descriptions | ~800 | ~700 | ~800 |
| **세션 고정 합계** | **~3,800** | **~3,200** | **~4,300** |

**개선 완료**: 스택 전용 룰 7개에 paths 추가. 해당 파일 작업 시만 로드 → 세션당 ~2,000 토큰 절약.

**남은 개선 여지**: base-common 룰 9개는 paths 없이 항상 로드. 이 중 `performance.md`, `patterns.md` 등은 paths 추가 가능하나, 범용 룰이라 어떤 파일에 걸어야 할지 애매.

---

## 커맨드별 성능

### /orchestrate

| | Standard | Full | 차이 |
|--|----------|------|------|
| 토큰 | 30K~100K | 80K~200K | Full이 2~3배 |
| 시간 | 17~46분 | 38~96분 | Full이 2~3배 |
| 리뷰 에이전트 | 2~4개 | 6~8개 (2라운드) | |
| Phase 0 스캔 | 스킵 | 실행 (5~15K) | |
| TDD | 선택 | 강제 | |

#### 고민 포인트

**1. 리뷰 에이전트가 순차 실행**

현재 에이전트 5~8개가 하나씩 돌아감. 병렬로 돌리면 시간은 1/3로 줄지만:
- 병렬 = 각 에이전트가 독립 컨텍스트 = 토큰 총량 동일 또는 증가
- 순차 = 앞 에이전트 결과를 뒤 에이전트가 참고 가능 (중복 지적 방지)
- Claude Code Agent 도구가 병렬 실행을 지원하긴 하지만, 결과 합치는 로직이 필요

→ **결정 필요**: 시간 줄이기 vs 리뷰 품질. 현재는 품질 우선으로 순차.

**2. Standard vs Full 자동 추천**

사용자가 매번 선택해야 함. 변경 규모로 자동 추천 가능:
- 파일 1~5개 변경 → Standard 추천
- 파일 10개+ 또는 새 모듈 → Full 추천
- 새 프로젝트 첫 기능 → Full 추천

→ **구현하면 좋은 것**: Phase 1에서 변경 예상 규모 파악 후 자동 추천 + 사용자 최종 선택

**3. pseudocode 해석 편차**

같은 orchestrate 실행해도 Claude가 매번 약간 다르게 동작.
- Phase 3 구현 순서가 달라지거나
- 검증 루프 횟수가 다르거나
- 리뷰 출력 형식이 미묘하게 바뀜

→ **완화법**: 출력 형식을 더 구체적으로 (마크다운 테이블 강제 등). 근데 너무 강제하면 유연성 감소. 현재 수준이 적정선으로 판단.

---

### /code-review

| | 현재 | 개선 가능 |
|--|------|-----------|
| 에이전트 | 5개 순차 | 병렬 가능 (위와 동일 트레이드오프) |
| 토큰 | 5~15K (Standard) | 줄이기 어려움 (리뷰 깊이와 직결) |
| 시간 | 3~10분 | 병렬 시 1~3분 |

---

### /lighthouse

| | 현재 | 개선 가능 |
|--|------|-----------|
| 라우트 탐지 | Next/TanStack/React Router/Vite | 커스텀 라우팅이면 못 잡음 → --pages 수동 지정 |
| 동적 라우트 | 제외 | 샘플 ID 넣어서 체크 가능 (미구현) |
| 시간 | 페이지당 15~30초 | Lighthouse CI로 병렬화 가능 (미구현) |

---

### /refactor-clean (knip)

| | 현재 | 개선 가능 |
|--|------|-----------|
| NestJS 오탐 | 데코레이터 필터로 방지 | knip 설정 자동 생성하면 더 정확 |
| 프론트 오탐 | 없음 | dynamic import 감지 보강 가능 |
| 실행 시간 | 대형 프로젝트 30초+ | 캐시/증분 분석 (knip 자체 기능) |

---

## 프론트엔드 관점

### 잘 되는 것
- orchestrate Phase 3에서 컴포넌트→페이지 순서 구현
- react-reviewer가 hooks/렌더 최적화 패턴 잘 잡음
- Lighthouse 자동 체크로 성능 이슈 PR 전 감지

### 고민 포인트

**4. Rules 21개가 과다할 수 있음**

base-common 9 + base-typescript 5 + ccb-common 2 + ccb-stack 5 = 21개.
paths 추가로 스택 룰 5개는 조건부 로드지만, base 14개는 항상 로드.

→ **검토 필요**: base-common의 `performance.md`, `patterns.md` 같은 건 프론트에서만 의미 있는 내용도 포함. 전부 읽힐 필요가 있는지.

**5. Tailwind v4 @theme 지원**

design-system 커맨드에서 v4 @theme 파싱을 추가했지만, 일반 프론트 프로필에는 디자인 시스템 커맨드가 없음. 프론트 개발자도 토큰 관리가 필요할 수 있음.

→ **선택지**: design-system 커맨드를 common/에 올리거나, 프론트에도 경량 버전 추가

---

## 백엔드 관점

### 잘 되는 것
- orchestrate에서 Entity→Service→Controller 순서 구현
- database-reviewer가 스키마 변경 잡음
- nestjs-pattern-reviewer가 NestJS 특화 패턴 검증

### 고민 포인트

**6. ORM별 분기 부족**

현재 orchestrate가 TypeORM/Prisma/Drizzle을 모두 언급하지만, 실제로 ORM별로 다른 Phase 3 구현 패턴이 필요:
- TypeORM: Entity → Migration → Repository
- Prisma: schema.prisma → prisma generate → Service
- Drizzle: schema.ts → migrate → Service

→ **선택지**:
- A. Phase 0 스캔에서 ORM 감지 → Phase 3에서 해당 ORM 패턴 적용 (현재: 암묵적으로 기대)
- B. orchestrate에 ORM별 분기 명시 (코드량 증가)

**7. E2E 테스트 자동화**

orchestrate Phase 3에서 유닛 테스트는 생성하지만 E2E는 선택적.
NestJS의 강점이 E2E인데 활용이 부족.

→ **선택지**: Full 모드에서 E2E 자동 생성 강제

---

## 풀스택 관점

### 잘 되는 것
- API 계약(Contract) 먼저 정의하는 흐름
- 백엔드 먼저 → 프론트 연동 순서
- scope(--front/--back) 분기

### 고민 포인트

**8. 구현 순서 고정 (백엔드 → 프론트)**

현재 항상 백엔드 먼저. 근데 경우에 따라:
- UI 프로토타입 먼저 → API 스펙 도출 → 백엔드 구현이 더 효율적일 수 있음
- 기존 API가 있고 프론트만 새로 만드는 경우도 있음 (이건 --front로 해결)

→ **선택지**:
- A. 현재 유지 (백엔드 먼저). 대부분의 경우에 맞음
- B. Phase 1에서 "구현 순서 선택" 질문 추가 (선택지 늘어남)

**9. 모노레포 감지가 확실한지**

Phase 0에서 pnpm-workspace.yaml, turbo.json 등으로 감지하지만, 감지 후 동작이 명확하지 않음:
- 프론트/백이 다른 패키지면 → 각각 pnpm install? 각각 별도 빌드?
- 공유 타입 패키지가 있으면 → 거기에 API Contract 타입을 넣어야 하는지?

→ **구현 필요**: 모노레포 감지 후의 **구체적 동작** 명시 (현재는 "파악해줘"까지만 있음)

**10. fullstack 에이전트 동기화 문제**

fullstack/agents/는 react-next + nestjs에서 복사한 파일.
원본을 수정하면 fullstack에 자동 반영 안 됨.

→ **선택지**:
- A. 수동 동기화 유지 (현재). 수정 시 3곳 다 바꿔야 함
- B. setup.ps1에서 fullstack 설치 시 react-next + nestjs를 동적으로 합침 (fullstack/ 폴더 자체가 불필요해짐)

B가 장기적으로 맞지만, setup.ps1 복잡도 증가.

---

## 즉시 개선 가능 (완료)

| 항목 | 효과 | 상태 |
|------|------|------|
| Rules paths 추가 | 세션당 ~2,000 토큰 절약 | ✅ 완료 |
| non-dev base 필터링 | 불필요한 개발 룰/스킬 제거 | ✅ 완료 |
| continuous-learning hooks 제거 (non-dev) | 매 도구 사용 에러 방지 | ✅ 완료 |
| allow 목록 확장 | 권한 멈춤 방지 | ✅ 완료 |
| typescript-lsp 플러그인 | 코드 인텔리전스 향상 | ✅ 완료 |

## 논의 필요 (위 고민 포인트 요약)

| # | 주제 | 선택지 | 영향 |
|---|------|--------|------|
| 1 | 리뷰 에이전트 순차 vs 병렬 | 시간↓ vs 품질↑ | orchestrate 시간 1/3 감소 가능 |
| 2 | Standard/Full 자동 추천 | 변경 규모 기반 추천 | 사용자 판단 부담 감소 |
| 5 | 프론트에 design-system 커맨드 | common에 올리기 vs 경량 버전 | 토큰 관리 편의 |
| 6 | ORM별 분기 | 암묵적 vs 명시적 | 백엔드 구현 정확도 |
| 8 | 풀스택 구현 순서 고정 | 유지 vs 선택 | 유연성 vs 복잡성 |
| 9 | 모노레포 감지 후 동작 | 구체화 필요 | 풀스택 안정성 |
| 10 | fullstack 에이전트 동기화 | 수동 vs 동적 합성 | 유지보수 비용 |
