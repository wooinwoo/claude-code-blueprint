# Verification Command — React/Vite/Next.js

프로젝트 전체 검증. 스크립트로 팩트 수집 → LLM이 해석.

## Usage

```
/verify              ← 전체 검증
/verify quick        ← build + type만
/verify full         ← 전체 + 번들 분석 + a11y
```

## Phase 1: 스크립트로 팩트 수집

```bash
# 스크립트가 lint/type/build/test를 순차 실행하고 JSON으로 결과 반환
node .claude/scripts-ccb/run-verify.js
```

스크립트가 반환하는 JSON:
```json
{
  "summary": {
    "packageManager": "pnpm",
    "totalSteps": 6,
    "passed": 4,
    "failed": 1,
    "skipped": 0,
    "warned": 1,
    "totalDuration": 12500
  },
  "steps": [
    { "name": "lint", "status": "pass", "duration": 2300 },
    { "name": "type-check", "status": "fail", "duration": 4100, "error": "src/App.tsx(15,3): error TS2322: ..." },
    { "name": "build", "status": "pass", "duration": 5200 },
    { "name": "test", "status": "pass", "duration": 900 },
    { "name": "console-log-audit", "status": "warn", "count": 3 },
    { "name": "git-status", "status": "pass", "uncommittedFiles": 0 }
  ]
}
```

**이 JSON이 팩트.** 스크립트가 실행 순서, 패키지 매니저 감지, 스크립트 존재 확인을 전부 처리. LLM은 결과를 해석만 함.

## Phase 2: LLM 해석

JSON 결과를 읽고:

1. **fail 항목**: 에러 메시지 분석 → 원인 설명 + 수정 제안
2. **warn 항목**: console.log 위치 안내, 미커밋 파일 안내
3. **skip 항목**: 왜 스킵됐는지 (스크립트 없음, tsconfig 없음 등)
4. **종합 판정**: PR 가능 여부

## Phase 3: 추가 검증 (full 모드)

`full` 또는 `pre-pr` 모드에서만:

### 번들 분석

```bash
# build 결과에서 번들 사이즈 확인
# Vite: dist/assets/*.js 파일 크기
# Next.js: .next/analyze 또는 build 로그
ls -lh dist/assets/*.js 2>/dev/null || ls -lh .next/static/chunks/*.js 2>/dev/null
```

250KB 초과 청크 경고.

### 접근성 스팟 체크

```bash
# 변경 파일에서 a11y 이슈 Grep
git diff main --name-only -- '*.tsx' '*.jsx' | xargs grep -n '<img[^>]*>' | grep -v 'alt='
git diff main --name-only -- '*.tsx' '*.jsx' | xargs grep -n 'onClick' | grep -v 'onKeyDown\|onKeyPress\|role='
```

## 출력

```
VERIFICATION: [PASS/FAIL]

Build:    [OK/FAIL]     (3.2s)
Types:    [OK/X errors] (4.1s)
Lint:     [OK/X issues] (2.3s)
Tests:    [X/Y passed]  (0.9s)
Logs:     [OK/X개]
Git:      [clean/X uncommitted]
Bundle:   [X KB total, largest: Y KB] (full only)
A11y:     [OK/X issues] (full only)

Ready for PR: [YES/NO]
```

fail이 있으면 에러 내용 + 수정 제안 포함.
