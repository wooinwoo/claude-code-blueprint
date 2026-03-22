---
description: 단독 코드 리뷰 실행. 스택별 리뷰 에이전트를 병렬로 호출.
---

# Code Review — 단독 코드 리뷰

## Usage

```
/code-review                    → 현재 브랜치 변경사항 전체 리뷰
/code-review src/features/auth  → 특정 디렉토리만 리뷰
/code-review --staged           → staged 변경사항만 리뷰
/code-review --last-commit      → 마지막 커밋 리뷰
```

## 용도

**orchestrate 없이 빠르게 리뷰할 때:**
- PR 올리기 전 셀프 리뷰
- 다른 사람 코드 리뷰 요청받았을 때
- 특정 파일/디렉토리만 빠르게 점검

**orchestrate와 차이:**
| | orchestrate | /code-review |
|---|---|---|
| 워크트리 | ✅ | ❌ |
| 플랜/브랜치 | ✅ | ❌ |
| 리뷰 | Phase 4에서 실행 | 즉시 실행 |
| 수정 | 자동 수정 + 재검증 | 리포트만 (수정 안 함) |
| 소요 시간 | 5-10분 | 1-2분 |

---

## Phase 1: 변경사항 수집 (스크립트)

### 1-1. diff 수집 — 스크립트로 확정적 데이터 확보

```bash
# 스크립트가 git diff를 구조화된 JSON으로 수집
node .claude/scripts-ccb/collect-diff.js main
```

스크립트가 반환하는 JSON:
```json
{
  "baseBranch": "main",
  "mergeBase": "abc1234",
  "totalFiles": 6,
  "totalAdded": 150,
  "totalRemoved": 30,
  "categories": { "react": 3, "typescript": 2, "test": 1 },
  "files": [
    { "filePath": "src/features/bid/BidList.tsx", "status": "M", "category": "react", "lines": { "added": 45, "removed": 10 }, "diff": "..." },
    ...
  ]
}
```

**이 JSON이 팩트.** LLM은 이 데이터를 기반으로 리뷰함. diff 수집을 스킵하거나 일부만 보는 편차 없음.

### 1-2. 변경 파일 분류

스크립트가 자동 분류 (`category` 필드):
- `react`: .tsx/.jsx
- `nestjs`: controller/service/module 등
- `database`: entity/schema/migration
- `test`: .test./.spec./.e2e-
- `typescript`: 기타 .ts/.js
- `style`: .css/.scss
- `config`: .json/.yaml/.md

---

## Phase 2: 스택별 에이전트 병렬 호출

### React-Next 스택

**5개 에이전트 병렬 실행:**

```
┌─────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│ code-       │ convention- │ security-   │ performance-│ react-      │
│ reviewer    │ reviewer    │ reviewer    │ reviewer    │ reviewer    │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ 로직/버그   │ 네이밍/구조 │ XSS/인젝션  │ 번들/메모리 │ 훅/렌더링   │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

각 에이전트에게 전달하는 컨텍스트:
- diff 내용
- 변경 파일 전체 소스 (diff만으로는 문맥 부족)
- 관련 룰 파일 경로

### NestJS 스택

**5개 에이전트 병렬 실행:**

```
┌─────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│ code-       │ convention- │ security-   │ database-   │ nestjs-     │
│ reviewer    │ reviewer    │ reviewer    │ reviewer    │ pattern-    │
│             │             │             │             │ reviewer    │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ 로직/버그   │ 네이밍/구조 │ 인증/인가   │ N+1/인덱스  │ DI/모듈     │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

---

## Phase 3: 결과 통합

### 3-1. 이슈 분류

| 심각도 | 기준 | 예시 |
|--------|------|------|
| **CRITICAL** | 버그, 보안 취약점, 데이터 손실 위험 | XSS, SQL injection, race condition |
| **HIGH** | 성능 저하, 패턴 위반, 유지보수 위험 | 불필요한 리렌더, 미처리 에러 |
| **MEDIUM** | 컨벤션 위반, 가독성 | 네이밍, import 순서, 매직 넘버 |
| **LOW** | 개선 제안, 스타일 | 더 나은 패턴 제안, 타입 개선 |

### 3-2. 리뷰 리포트

```
📝 Code Review Report
═══════════════════════════════════════

Review Scope: 6 files changed (+142, -38)
Agents: 5/5 completed

🔴 CRITICAL (1)
──────────────
[security-reviewer] src/features/auth/LoginForm.tsx:28
  dangerouslySetInnerHTML에 사용자 입력 직접 전달 — XSS 취약점
  → sanitize-html 또는 DOMPurify 적용 필요

🟡 HIGH (2)
──────────────
[react-reviewer] src/hooks/useBidSearch.ts:15
  useEffect 내에서 setState를 조건 없이 호출 — 무한 루프 위험
  → 의존성 배열 확인 또는 조건 추가

[performance-reviewer] src/features/bid/BidList.tsx:42
  map 내부에서 매 렌더마다 새 객체 생성 — 자식 리렌더 유발
  → useMemo 또는 컴포넌트 분리

🔵 MEDIUM (3)
──────────────
[convention-reviewer] src/lib/format.ts:5
  함수명 fmt → formatCurrency로 변경 권장 (네이밍 컨벤션)

[code-reviewer] src/features/bid/BidCard.tsx:18
  optional chaining 누락 — bid.company?.name 사용 권장

[convention-reviewer] src/features/bid/BidList.tsx:1
  import 순서: 외부 → 내부 → 상대경로 순으로 정렬 필요

⚪ LOW (1)
──────────────
[react-reviewer] src/features/bid/BidCard.tsx:35
  Props 타입을 별도 파일로 분리 고려 (선택사항)

═══════════════════════════════════════
Summary: 1 CRITICAL, 2 HIGH, 3 MEDIUM, 1 LOW
Action Required: CRITICAL과 HIGH 수정 후 PR 권장
```

---

## Phase 4: 후속 조치 안내

```
📋 다음 단계:

CRITICAL/HIGH 수정이 필요합니다.

빠른 수정:
  /fix src/features/auth/LoginForm.tsx    → XSS 취약점 수정
  /fix src/hooks/useBidSearch.ts          → useEffect 무한 루프 수정

전체 수정 후 재검증:
  /verify pre-pr
```

> 리뷰 결과는 **리포트만 제공**하고 자동 수정하지 않음.
> 수정이 필요하면 `/fix` 또는 직접 수정 후 `/code-review` 재실행.

---

## 주의사항

- ❌ 리뷰 중 코드 수정 금지 (읽기 전용)
- ❌ 테스트 파일의 컨벤션 이슈는 LOW로 분류
- ✅ 에이전트 간 중복 이슈는 하나만 리포트 (가장 관련 높은 에이전트 것)
- ✅ diff가 10줄 이하면 에이전트 1개 (code-reviewer)만 실행
- ✅ diff가 없으면 "리뷰할 변경사항 없음" 출력 후 중단
