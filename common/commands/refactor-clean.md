---
description: 데드코드 분석 및 안전한 제거. 미사용 export, 의존성, 파일 탐지.
---

# Refactor Clean — 데드코드 분석 & 정리

## Usage

```
/refactor-clean              → 전체 분석 리포트
/refactor-clean exports      → 미사용 export만
/refactor-clean deps         → 미사용 의존성만
/refactor-clean files        → 미사용 파일만
/refactor-clean fix          → 분석 후 안전한 항목 자동 제거
```

## Phase 1: 분석

### 1-1. 미사용 Export 탐지

```bash
# knip 설치 (없으면)
pnpm dlx knip --reporter=json > .claude/tmp/knip-report.json 2>&1
```

> knip 실행 불가 시 수동 분석:
> 1. `src/` 하위 모든 `export` 문 수집 (Grep)
> 2. 각 export 이름으로 프로젝트 내 import 검색
> 3. import 없는 export = 미사용 후보

### 1-2. 미사용 의존성 탐지

```bash
# depcheck
pnpm dlx depcheck --json > .claude/tmp/depcheck-report.json 2>&1
```

> depcheck 실행 불가 시 수동 분석:
> 1. package.json dependencies 목록 추출
> 2. 각 패키지명으로 소스코드 내 import/require 검색
> 3. import 없는 패키지 = 미사용 후보

### 1-3. 미사용 파일 탐지

```bash
# knip에서 미사용 파일 정보 추출, 또는:
# ts-prune으로 미참조 파일 탐지
pnpm dlx ts-prune | grep "used in 0 modules"
```

> 수동 분석:
> 1. `src/` 하위 모든 `.ts`, `.tsx` 파일 목록
> 2. 각 파일이 다른 파일에서 import되는지 검색
> 3. entry point (routes, index, config)에서 도달 불가능한 파일 = 미사용

---

### 1-4. NestJS 오탐 필터 (NestJS 프로젝트일 때)

NestJS는 데코레이터 기반 DI를 사용하므로 knip이 오탐할 수 있습니다. 다음 패턴은 **SKIP으로 강제 분류**합니다:

```typescript
// 자동 SKIP 대상 — knip이 "미사용"으로 잡아도 실제로는 DI로 사용 중
const nestjsSkipPatterns = [
  // 데코레이터가 있는 클래스는 NestJS DI 컨테이너가 관리
  /@Injectable\(\)/,     // 서비스, 가드, 인터셉터, 파이프
  /@Controller\(\)/,     // 컨트롤러
  /@Module\(\)/,         // 모듈 (imports/providers/exports로 연결)
  /@Resolver\(\)/,       // GraphQL 리졸버

  // 모듈의 providers/imports에 등록된 클래스
  // → Module 파일을 Read해서 providers 배열 안의 클래스명 추출
  // → 해당 클래스는 SKIP

  // Entity/DTO는 TypeORM/Prisma가 참조
  /@Entity\(\)/,
  /@Schema\(\)/,         // Mongoose
]

// knip 결과에서 위 패턴이 있는 파일은 제거 대상에서 제외
for (const item of knipResults) {
  const content = Read(item.filePath)
  if (nestjsSkipPatterns.some(p => p.test(content))) {
    item.grade = "SKIP"
    item.reason = "NestJS DI 데코레이터 — 직접 import 없어도 사용 중"
  }
}
```

> knip에 NestJS 플러그인이 있지만 데코레이터 기반 DI를 완벽히 추적하지 않습니다.
> 위 필터로 오탐을 줄이되, `@Module()`의 `providers` 배열을 직접 확인하는 게 가장 정확합니다.

---

## Phase 2: 리포트

```
🧹 Dead Code Analysis
═══════════════════════════════════════

📦 미사용 의존성 (3개)
──────────────────────
  - lodash          (package.json → 소스에서 미사용)
  - moment          (package.json → date-fns로 대체됨)
  - @types/lodash   (devDeps → lodash 제거 시 같이 제거)

📤 미사용 Export (7개)
──────────────────────
  src/utils/format.ts
    - formatLegacyDate()     Line 42
    - LEGACY_DATE_FORMAT     Line 3

  src/hooks/useOldFilter.ts
    - useOldFilter()         Line 1  (파일 전체 미사용)

  src/lib/api/deprecated.ts
    - fetchOldEndpoint()     Line 15
    - OldResponseType        Line 5

📄 미사용 파일 (2개)
──────────────────────
  src/hooks/useOldFilter.ts          (0 imports)
  src/components/LegacyBanner.tsx    (0 imports)

═══════════════════════════════════════
Total: 3 deps + 7 exports + 2 files
Safe to remove: 10/12 (2 items need manual review)
```

---

## Phase 3: 안전성 분류

각 항목을 3단계로 분류:

| 등급 | 기준 | 조치 |
|------|------|------|
| **SAFE** | import 0건, 동적 import 없음, 테스트에서도 미사용 | 자동 제거 가능 |
| **REVIEW** | 동적 import 가능성, 설정 파일 참조, 또는 테스트에서만 사용 | 사용자 확인 후 제거 |
| **SKIP** | entry point, config, 타입 선언 파일 | 제거 금지 |

### 자동 제거 제외 대상

- `*.d.ts` 타입 선언 파일
- `vite.config.*`, `tailwind.config.*`, `tsconfig.*`
- `src/app/routes/**` (라우트 entry point)
- `package.json` scripts에서 참조되는 패키지
- `peerDependencies`
- NestJS: `@Injectable`, `@Controller`, `@Module`, `@Resolver`, `@Entity`, `@Schema` 데코레이터가 있는 파일

---

## Phase 4: 제거 (`fix` 모드)

### 4-1. SAFE 항목 자동 제거

```
제거 대상 (SAFE):
1. ✅ lodash — pnpm remove lodash
2. ✅ @types/lodash — pnpm remove -D @types/lodash
3. ✅ formatLegacyDate() — src/utils/format.ts:42 삭제
4. ✅ LEGACY_DATE_FORMAT — src/utils/format.ts:3 삭제
5. ✅ src/hooks/useOldFilter.ts — 파일 삭제
6. ✅ src/components/LegacyBanner.tsx — 파일 삭제
```

### 4-2. REVIEW 항목 사용자 확인

```typescript
AskUserQuestion([{
  question: "다음 항목을 제거할까요?",
  header: "Review",
  options: [
    { label: "moment", description: "date-fns 대체 완료 확인 후 제거" },
    { label: "fetchOldEndpoint", description: "동적 import 가능성 — 확인 필요" }
  ],
  multiSelect: true
}])
```

### 4-3. 제거 후 검증

```bash
# 빌드 확인
pnpm build

# 타입 확인
pnpm tsc --noEmit

# 테스트
pnpm test
```

### 4-4. 결과

```
🧹 Refactor Clean 완료

제거됨:
  - 2 dependencies (lodash, @types/lodash)
  - 4 exports
  - 2 files

검증:
  ✅ Build passed
  ✅ Types OK
  ✅ Tests 42/42 passed

Bundle 변화:
  Before: 245KB → After: 228KB (-17KB, -6.9%)
```

---

## 주의사항

- ❌ 라우트 파일, config 파일 삭제 금지
- ❌ `git add -A` 금지 — 제거한 파일만 개별 스테이징
- ❌ 한 번에 너무 많이 제거하지 않기 — 10개씩 배치
- ✅ 제거 전 반드시 빌드 + 타입 체크
- ✅ 의심스러우면 REVIEW로 분류
- ✅ 제거 후 빈 index.ts (re-export만 있던 파일) 정리
