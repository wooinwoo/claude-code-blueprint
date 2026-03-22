---
description: 테스트 커버리지 분석 + 미커버 영역 자동 테스트 생성.
---

# Test Coverage — 커버리지 분석 & 갭 채우기

## Usage

```
/test-coverage                → 전체 프로젝트 커버리지 분석
/test-coverage src/auth       → 특정 디렉토리만
/test-coverage gap            → 미커버 영역만 리포트
/test-coverage fill           → 미커버 영역 테스트 자동 생성
```

## Phase 0: 테스트 인프라 확인

```bash
# test 스크립트 존재 확인
Grep('"test":', path="package.json")
# 테스트 러너 감지
Grep("vitest|jest", path="package.json")
```

test 스크립트가 없으면:

```typescript
AskUserQuestion([{
  question: "테스트 인프라가 없습니다. 지금 셋업할까요?",
  header: "테스트 인프라",
  options: [
    { label: "vitest로 셋업", description: "vitest + @testing-library 설치 (React 권장)" },
    { label: "jest로 셋업", description: "jest + ts-jest 설치" },
    { label: "취소", description: "테스트 없이 종료" }
  ]
}])
```

선택 시:
1. 해당 러너 + 라이브러리 설치 (`${pm} add -D ...`)
2. 설정 파일 생성 (vitest.config.ts / jest.config.js)
3. setup 파일 생성 (src/test/setup.ts)
4. package.json scripts 추가 (test, test:watch, test:coverage)
5. `${pm} test --passWithNoTests` 로 동작 확인
6. Phase 1로 계속 진행

---

## Phase 1: 커버리지 수집

### 1-1. Vitest 커버리지 실행

```bash
pnpm vitest run --coverage --reporter=json --outputFile=coverage-report.json
```

> `vitest.config` 에 `coverage.provider` 미설정 시:
> ```bash
> pnpm dlx @vitest/coverage-v8
> pnpm vitest run --coverage
> ```

### 1-2. 커버리지 파싱

```
📊 Coverage Summary
─────────────────────────────
Statements:  78.2%  (1,245/1,593)
Branches:    65.1%  (312/479)
Functions:   82.4%  (298/362)
Lines:       79.0%  (1,198/1,516)

Target: 80% (lines)
Gap:    -1.0% (18 lines 부족)
```

---

## Phase 2: 갭 분석

### 2-1. 미커버 파일 목록 (하위 80%)

```
📋 Under-covered Files (bottom 20)
─────────────────────────────────────
File                          Lines   Uncov  Cov%
src/features/bid/utils.ts       120     45   62.5%
src/hooks/useSearchFilters.ts    85     30   64.7%
src/lib/api/client.ts            60     20   66.7%
...
```

### 2-2. 미커버 함수/분기 상세

```
🔍 Uncovered Details: src/features/bid/utils.ts
─────────────────────────────────────────────────
Line 42-58:  formatBudget() — else 분기 (억 단위 미만)
Line 73-89:  parseBidStatus() — "cancelled" case
Line 95-110: calculateDDay() — 음수 D-Day 처리
```

---

## Phase 3: 갭 채우기 (`fill` 모드)

### 3-1. 테스트 생성 우선순위

```
Priority:
1. [CRITICAL] 비즈니스 로직 유틸 (formatBudget, parseBidStatus 등)
2. [HIGH]     커스텀 훅 (useSearchFilters, useBidDetail 등)
3. [MEDIUM]   API 클라이언트 에러 핸들링
4. [LOW]      UI 컴포넌트 분기 렌더링
```

### 3-2. 테스트 생성 규칙

- 기존 테스트 파일이 있으면 **기존 파일에 추가**
- 없으면 동일 디렉토리에 `*.test.ts(x)` 생성
- Arrange-Act-Assert 패턴
- 테스트명: 한국어 허용 (`it('억 단위 미만 금액을 만원 단위로 포맷한다')`)
- mock은 최소한으로, 실제 로직 테스트 우선

### 3-3. 생성 후 검증

```bash
# 새 테스트만 실행
pnpm vitest run --reporter=verbose {new_test_files}

# 전체 재측정
pnpm vitest run --coverage
```

### 3-4. 결과 리포트

```
✅ Coverage Gap Fill 완료

생성된 테스트:
- src/features/bid/__tests__/utils.test.ts (+3 tests)
- src/hooks/__tests__/useSearchFilters.test.tsx (+2 tests)

커버리지 변화:
  Lines:   79.0% → 83.2% (+4.2%)
  Target:  80% ✅ 달성

새 테스트 결과: 5/5 passed
```

---

## Arguments

$ARGUMENTS:
- (없음) — 전체 커버리지 리포트
- `{path}` — 특정 디렉토리/파일만 분석
- `gap` — 미커버 영역 리포트만 (테스트 생성 안 함)
- `fill` — 미커버 영역 테스트 자동 생성
- `fill {path}` — 특정 영역만 테스트 생성

## 주의사항

- ❌ 스냅샷 테스트 자동 생성 금지 (유지보수 비용 높음)
- ❌ 구현 상세(내부 state, private method) 테스트 금지
- ✅ 공개 인터페이스(export 함수, 훅 반환값, 컴포넌트 렌더 결과) 중심
- ✅ 엣지 케이스 우선 (null, undefined, 빈 배열, 경계값)
- ✅ 기존 테스트 스타일/패턴 따르기
