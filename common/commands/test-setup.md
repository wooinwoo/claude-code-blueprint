---
description: 테스트 인프라 셋업. 프로젝트에 테스트 러너/라이브러리가 없을 때 자동 설치 + 설정.
---

# Test Setup — 테스트 인프라 셋업

## Usage

```
/test-setup              → 프로젝트 감지 후 자동 셋업
/test-setup vitest       → vitest 강제 (React/Next.js)
/test-setup jest         → jest 강제 (NestJS)
```

---

## Phase 1: 현재 상태 감지

```bash
# 테스트 러너 감지
Grep("vitest|jest|mocha|@testing-library", path="package.json")

# 테스트 설정 파일 존재 여부
Glob("vitest.config.*")
Glob("jest.config.*")

# 기존 테스트 파일 수
test_count=$(find src -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l)

# package.json test 스크립트
Grep('"test":', path="package.json")
```

### 감지 결과 출력

```
📋 테스트 인프라 현황

테스트 러너:     {vitest|jest|없음}
설정 파일:       {vitest.config.ts|jest.config.js|없음}
테스트 파일:     {n}개
test 스크립트:   {"vitest run"|"jest"|없음}
커버리지 도구:   {v8|istanbul|없음}
```

---

## Phase 2: 셋업 (인프라 없을 때)

### 프레임워크 자동 판별

```bash
# React/Next.js → vitest
Grep("react|next", path="package.json") → vitest

# NestJS → jest
Grep("@nestjs", path="package.json") → jest

# 판별 불가 → 사용자에게 질문
AskUserQuestion([{
  question: "어떤 테스트 러너를 사용할까요?",
  options: [
    { label: "vitest", description: "빠름. React/Vite/Next.js 권장" },
    { label: "jest", description: "안정적. NestJS/범용" }
  ]
}])
```

### vitest 셋업 (React/Next.js)

```bash
${pm} add -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/test/**', '**/*.d.ts']
    }
  },
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') }
  }
})
```

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom/vitest'
```

package.json scripts 추가:
```json
{
  "test": "vitest run",
  "test:watch": "vitest",
  "test:coverage": "vitest run --coverage"
}
```

### jest 셋업 (NestJS)

```bash
${pm} add -D jest @nestjs/testing supertest @types/jest @types/supertest ts-jest
```

```javascript
// jest.config.js
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: { '^.+\\.(t|j)s$': 'ts-jest' },
  collectCoverageFrom: ['**/*.(t|j)s', '!**/*.module.ts', '!**/main.ts'],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
};
```

```json
// test/jest-e2e.json
{
  "moduleFileExtensions": ["js", "json", "ts"],
  "rootDir": "..",
  "testEnvironment": "node",
  "testRegex": ".e2e-spec.ts$",
  "transform": { "^.+\\.(t|j)s$": "ts-jest" }
}
```

package.json scripts 추가:
```json
{
  "test": "jest",
  "test:watch": "jest --watch",
  "test:coverage": "jest --coverage",
  "test:e2e": "jest --config ./test/jest-e2e.json"
}
```

---

## Phase 3: 샘플 테스트 생성

셋업 후 **샘플 테스트 1개** 생성하여 동작 확인.

### vitest 샘플

```typescript
// src/test/sample.test.ts
import { describe, it, expect } from 'vitest'

describe('test setup', () => {
  it('works', () => {
    expect(1 + 1).toBe(2)
  })
})
```

### jest 샘플

```typescript
// src/test/sample.spec.ts
describe('test setup', () => {
  it('works', () => {
    expect(1 + 1).toBe(2)
  })
})
```

### 실행 확인

```bash
${pm} test
# 1 test passed → 셋업 완료
```

실패하면 에러 분석 → 설정 수정 → 재실행.

---

## Phase 4: 완료 메시지

```
✅ 테스트 인프라 셋업 완료

설치됨:
- {vitest|jest} + {라이브러리들}
- 설정: {vitest.config.ts|jest.config.js}
- 셋업: {src/test/setup.ts}
- 스크립트: test, test:watch, test:coverage

다음 단계:
- /test-coverage fill → 기존 코드에 테스트 자동 생성
- /orchestrate → 새 기능 개발 시 테스트 자동 포함
```

---

## 이미 테스트 인프라가 있을 때

```
ℹ️ 테스트 인프라가 이미 설치되어 있습니다.

테스트 러너:   vitest
테스트 파일:   15개
커버리지:      67%

추가 작업이 필요하면:
- /test-coverage → 커버리지 확인
- /test-coverage fill → 미커버 테스트 생성
```
