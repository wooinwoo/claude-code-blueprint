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

## 토큰 비용

### 세션 고정 비용 (매번 로드)

| | react-next | nestjs | fullstack |
|--|-----------|--------|-----------|
| CLAUDE.md | ~500 | ~500 | ~500 |
| Rules (항상 로드) | ~2,500 | ~2,000 | ~3,000 |
| Rules (조건부 로드) | 해당 파일 작업 시만 | 동일 | 동일 |
| Skills descriptions | ~800 | ~700 | ~800 |
| **합계** | **~3,800** | **~3,200** | **~4,300** |

fullstack이 가장 비쌈 — react + nestjs 룰 합산.

base-common 룰 9개는 paths 없이 항상 로드. `performance.md`, `patterns.md` 등에 paths를 추가하면 줄일 수 있으나, 범용 룰이라 어떤 파일 패턴에 걸어야 할지 애매.

---

## 커맨드별 성능

### /orchestrate

| | Standard | Full |
|--|----------|------|
| 토큰 | 30K~100K | 80K~200K |
| 시간 | 17~46분 | 38~96분 |
| 리뷰 에이전트 | 2~4개, 1라운드 | 6~8개, 2라운드 |
| Phase 0 스캔 | 스킵 | 실행 (5~15K) |
| TDD | 선택 | 강제 |

### /code-review

| | 수치 |
|--|------|
| 에이전트 | 5개 순차 |
| 토큰 | 5~15K |
| 시간 | 3~10분 |

### /lighthouse

| | 수치 |
|--|------|
| 시간 | 페이지당 15~30초 |
| 라우트 탐지 | Next/TanStack/React Router/Vite (커스텀은 --pages 수동) |
| 동적 라우트 | 제외 |

### /refactor-clean

| | 수치 |
|--|------|
| NestJS 오탐 | 데코레이터 필터로 방지 |
| 시간 | 대형 프로젝트 30초+ |

---

## 프론트엔드

### 현재 상태
- orchestrate Phase 3: 컴포넌트→페이지 순서 구현
- react-reviewer: hooks/렌더 최적화 패턴 검증
- Lighthouse: PR 전 자동 체크 (Phase 4-0)
- Rules 21개 중 스택 룰 5개는 paths로 조건부 로드

### 개선 여지

**1. base-common 룰 14개가 항상 로드**

스택 룰 5개는 paths 걸었지만 base 14개는 항상 로드. 전부 읽힐 필요 있는지.

**2. 프론트에 design-system 커맨드 없음**

디자이너 프로필에만 있음. 프론트 개발자도 토큰 관리가 필요할 수 있음.
→ common/에 올리거나 프론트에 경량 버전 추가

---

## 백엔드

### 현재 상태
- orchestrate Phase 3: Entity→Service→Controller 순서
- database-reviewer: 스키마 변경 감지
- nestjs-pattern-reviewer: NestJS 특화 패턴 검증
- knip NestJS 데코레이터 오탐 필터 적용

### 개선 여지

**3. ORM별 분기 없음**

orchestrate가 TypeORM/Prisma/Drizzle을 모두 언급하지만 Phase 3 구현 패턴이 ORM마다 다름:
- TypeORM: Entity → Migration → Repository
- Prisma: schema.prisma → prisma generate → Service
- Drizzle: schema.ts → migrate → Service

현재는 Claude가 알아서 감지. 명시적 분기를 넣으면 정확도↑, 코드량↑.

**4. E2E 테스트 선택적**

orchestrate Phase 3에서 유닛 테스트는 생성하지만 E2E는 선택적. NestJS 강점이 E2E인데 활용 부족.
→ Full 모드에서 E2E 강제 여부

---

## 풀스택

### 현재 상태
- API 계약(Contract) 먼저 정의 → 백엔드 구현 → 프론트 연동
- scope 분기: 기본 fullstack, --front, --back
- 모노레포 감지 (pnpm-workspace.yaml, turbo.json 등)
- state 파일에 develop_progress로 서브스텝 추적

### 개선 여지

**5. 리뷰 에이전트 순차 실행**

5~8개 에이전트가 하나씩 돌아감.
- 병렬 시 시간 1/3 감소
- 순차 시 앞 에이전트 결과를 뒤가 참고 가능 (중복 지적 방지)
- 병렬 시 토큰 총량은 동일 또는 증가

→ 시간 vs 품질 트레이드오프

**6. Standard/Full 선택 기준 없음**

사용자가 매번 판단. 변경 규모 기반 자동 추천 가능:
- 파일 1~5개 → Standard
- 파일 10개+ 또는 새 모듈 → Full
- 첫 기능 → Full

**7. 구현 순서 고정 (백엔드 → 프론트)**

항상 백엔드 먼저. UI 프로토타입 먼저 만들고 API 스펙을 도출하는 경우도 있음.
기존 API가 있고 프론트만 새로 만드는 건 --front로 해결됨.

→ 현재 유지 vs Phase 1에서 순서 선택

**8. 모노레포 감지 후 동작 불명확**

감지는 하지만 그 다음이 애매:
- 프론트/백이 다른 패키지면 각각 install? 각각 빌드?
- 공유 타입 패키지가 있으면 거기에 API Contract을 넣는지?

→ 감지 후 구체적 동작 명시 필요

**9. fullstack 에이전트 동기화**

fullstack/agents/는 react-next + nestjs에서 복사한 파일. 원본 수정 시 fullstack에 자동 반영 안 됨.
- 수동 동기화 유지 (현재) — 수정 시 3곳 바꿔야 함
- setup.ps1에서 동적 합성 — fullstack/ 폴더 자체가 불필요해짐. setup.ps1 복잡도 증가

**10. pseudocode 해석 편차**

같은 orchestrate 실행해도 Claude가 매번 약간 다르게 동작. Phase 3 구현 순서, 검증 루프 횟수, 리뷰 출력 형식 등. 출력 형식을 더 강제하면 일관성↑, 유연성↓. 현재가 적정선으로 판단.

---

## 논의 포인트 요약

| # | 주제 | 선택지 | 영향 |
|---|------|--------|------|
| 1 | base 룰 항상 로드 | paths 추가 vs 유지 | 토큰 절약 vs 누락 위험 |
| 2 | 프론트 design-system | common 이동 vs 경량 버전 | 토큰 관리 편의 |
| 3 | ORM별 분기 | 암묵적 vs 명시적 | 정확도 vs 코드량 |
| 4 | NestJS E2E 강제 | Full에서 강제 vs 선택 유지 | 테스트 커버리지 |
| 5 | 리뷰 에이전트 순차 vs 병렬 | 시간↓ vs 품질↑ | orchestrate 시간 1/3 |
| 6 | Standard/Full 자동 추천 | 규모 기반 추천 | 판단 부담 |
| 7 | 풀스택 구현 순서 | 고정 vs 선택 | 유연성 vs 복잡성 |
| 8 | 모노레포 후속 동작 | 구체화 필요 | 안정성 |
| 9 | fullstack 에이전트 동기화 | 수동 vs 동적 합성 | 유지보수 |
| 10 | pseudocode 편차 | 더 강제 vs 유지 | 일관성 vs 유연성 |
