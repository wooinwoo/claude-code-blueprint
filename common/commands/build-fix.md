---
description: 빌드 에러 빠르게 수정. lint/type/build 에러를 단계별로 해결.
---

# Build Fix — 빌드 에러 즉시 수정

## Usage

```
/build-fix              → 전체 빌드 파이프라인 수정 (lint → type → build)
/build-fix lint         → lint 에러만 수정
/build-fix types        → 타입 에러만 수정
/build-fix build        → 빌드 에러만 수정
```

## 용도

**빌드가 깨졌을 때 빠르게 복구:**
- `pnpm build` 실패
- `pnpm tsc --noEmit` 에러
- `pnpm lint` 에러

**orchestrate vs build-fix:**
| | orchestrate Phase 3 | /build-fix |
|---|---|---|
| 맥락 | 개발 중 검증 루프 | 빌드 복구 전용 |
| 범위 | 전체 프로젝트 | 에러 파일만 |
| 수정 횟수 | 최대 3회 루프 | 최대 5회 루프 |
| 소요 시간 | orchestrate 전체 중 일부 | 1-3분 단독 |

---

## Phase 1: 에러 수집

### 1-1. Lint 에러

```bash
# Biome (NestJS)
pnpm biome check --write . 2>&1

# ESLint (React)
pnpm lint --format=json 2>&1
```

### 1-2. Type 에러

```bash
pnpm tsc --noEmit 2>&1
```

### 1-3. Build 에러

```bash
pnpm build 2>&1
```

### 1-4. 에러 파싱

```
🔴 Build Errors Found
═══════════════════════

Lint:   3 errors, 2 warnings
Types:  5 errors
Build:  2 errors (from types)

총 에러: 8개 (3 lint + 5 type, build는 type에서 파생)
```

---

## Phase 2: 수정 (순서 중요)

### 수정 순서: Lint → Types → Build

> Lint를 먼저 수정하면 type 에러가 줄어들고, type 에러를 수정하면 build 에러가 사라지는 경우가 많음.

### 2-1. Lint 에러 수정

```
수정 전략:
1. auto-fix 가능 → pnpm lint --fix (또는 biome check --write)
2. auto-fix 불가 → 에러별 수동 수정
```

**자동 수정 가능 항목:**
- import 순서
- unused import 제거
- 세미콜론, 따옴표
- trailing comma

**수동 수정 필요 항목:**
- no-explicit-any → 타입 추론 또는 명시적 타입
- react-hooks/exhaustive-deps → 의존성 배열 수정
- no-unused-vars → 변수 제거 또는 _ 접두사

### 2-2. Type 에러 수정

```
수정 전략 (에러 타입별):
─────────────────────────
TS2322 (Type mismatch)     → 타입 변환 또는 타입 정의 수정
TS2339 (Property not exist)→ 타입에 프로퍼티 추가 또는 optional chaining
TS2345 (Argument type)     → 함수 시그니처 또는 호출부 수정
TS7006 (Implicit any)      → 명시적 타입 추가
TS2307 (Module not found)  → import 경로 또는 의존성 확인
TS18046 (Unknown type)     → 타입 가드 추가
```

**수정 규칙:**
- `as any` 사용 금지 → 올바른 타입 찾기
- 타입 에러 수정이 다른 에러를 만들 수 있으므로 하나 수정 후 재확인
- 제네릭 타입이 복잡하면 타입 유틸리티 (`Pick`, `Omit`, `Partial`) 활용

### 2-3. Build 에러 수정

```
lint + type 수정 후에도 빌드 실패 시:
─────────────────────────────────────
1. 환경 변수 누락 → .env.example 참조
2. import cycle → 순환 의존성 해소
3. dynamic import 오류 → 경로/파일명 확인
4. Vite/webpack 설정 → config 확인
```

---

## Phase 3: 검증 루프

```
Loop (최대 5회):
  1. 수정 적용
  2. 재실행 (lint → type → build)
  3. 에러 남아있으면 → 다시 수정
  4. 에러 0 → 완료
  5. 5회 초과 → 사용자에게 보고 + 남은 에러 목록
```

### 루프 리포트 (매 회차)

```
🔄 Fix Attempt 2/5
───────────────────
Fixed:    TS2322 in src/utils/format.ts:42
Fixed:    TS2339 in src/hooks/useBid.ts:15
Remaining: 1 error (TS2345 in src/api/client.ts:28)
```

---

## Phase 4: 결과

### 성공

```
✅ Build Fix 완료

수정 내역:
  src/utils/format.ts:42     — 반환 타입 string → string | null
  src/hooks/useBid.ts:15     — optional chaining 추가
  src/api/client.ts:28       — 제네릭 타입 파라미터 수정

검증:
  ✅ Lint:  0 errors
  ✅ Types: 0 errors
  ✅ Build: success (2.1s)

총 시도: 2/5
```

### 실패 (5회 초과)

```
⚠️ Build Fix 미완료 (5/5 시도 소진)

수정됨: 6/8 에러
남은 에러:
  TS2345 src/api/client.ts:28
    → Argument of type 'Response' is not assignable to 'ApiResponse<T>'
    → 원인 추정: ApiResponse 제네릭 타입과 실제 fetch 응답 불일치

  TS2322 src/types/bid.ts:15
    → 순환 참조 가능성

권장 조치:
  1. src/api/client.ts의 response 타입 수동 확인
  2. src/types/bid.ts 순환 참조 해소
```

---

## 주의사항

- ❌ `@ts-ignore`, `@ts-nocheck` 추가 금지
- ❌ `as any` 타입 단언 금지
- ❌ eslint-disable 주석 금지 (에러를 숨기지 않음)
- ❌ 에러와 무관한 코드 수정 금지
- ✅ 에러 파일만 수정 (다른 파일 건드리지 않음)
- ✅ 수정마다 재검증
- ✅ 5회 내 해결 불가 시 정직하게 보고
