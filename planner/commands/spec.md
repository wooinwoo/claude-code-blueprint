---
description: 경량 기능 명세서 작성. PRD보다 가볍고 빠르게, 개발팀이 바로 구현할 수 있는 수준.
---

# Spec — 경량 기능 명세서 작성

## Usage

```
/spec <feature>                   → 기능 명세서 작성
/spec <feature> --jira <key>      → Jira 이슈 기반 명세
/spec --list                      → 작성된 명세서 목록
```

## 용도

**PRD의 10개 섹션 대신 5개 핵심 섹션만으로 빠르게 기능 명세 작성**
- 간단한 기능 변경, 개선, 버그 수정에 적합
- 개발팀이 바로 구현 착수할 수 있는 수준의 구체성
- Jira 이슈 연동으로 컨텍스트 자동 수집

---

## `--list` 모드: 명세서 목록 조회

```typescript
existing = Glob("plans/spec-*.md")

if (existing.length === 0) {
  console.log("작성된 명세서가 없습니다.")
  return
}

console.log("작성된 명세서 목록:")
for (const file of existing) {
  content = Read(file)
  // 첫 번째 H1에서 제목 추출
  title = content.match(/^# .+/m)?.[0] || file
  date = file.match(/\d{4}-\d{2}-\d{2}/)?.[0] || "날짜 미확인"
  console.log(`  - ${file} (${date}) — ${title}`)
}
```

---

## Phase 1: 컨텍스트 수집

### 1-1. Jira 이슈 조회 (선택)

```typescript
if (args.jira) {
  issue = mcp__jira__jira_get_issue({ issue_key: args.jira })

  console.log(`
  Jira 이슈 로드:
  이슈: ${issue.key}
  제목: ${issue.summary}
  설명: ${issue.description}
  타입: ${issue.type}
  우선순위: ${issue.priority}
  수용 기준: ${issue.acceptance_criteria || "미정의"}
  `)

  feature_context = {
    summary: issue.summary,
    description: issue.description,
    type: issue.type,
    acceptance_criteria: issue.acceptance_criteria
  }
}

// 예외: Jira 연결 실패 시
catch (error) {
  console.log("⚠️ Jira 연결 실패. 수동 입력 모드로 전환합니다.")
}
```

### 1-2. 기존 명세서 탐색

```typescript
existing_spec = Glob(`plans/spec-${feature_name}-*.md`)

if (existing_spec.length > 0) {
  console.log(`
  ⚠️  동일 기능 명세서가 이미 존재합니다:
  ${existing_spec.map(f => `  - ${f}`).join('\n')}

  새로 작성하면 날짜로 구분됩니다.
  기존 명세를 업데이트하려면 직접 수정하세요.
  `)
}
```

### 1-3. Q&A 정보 수집

```typescript
AskUserQuestion([
  {
    question: "이 기능을 한 두 문장으로 요약해주세요.",
    header: "1. 기능 요약",
    description: "무엇을 만드나요? 어떤 변경인가요?",
    default: feature_context?.summary || ""
  },
  {
    question: "이 기능의 대상 사용자는 누구인가요?",
    header: "2. 대상 사용자",
    options: [
      { label: "일반 사용자", description: "서비스 최종 사용자" },
      { label: "관리자", description: "백오피스/어드민 사용자" },
      { label: "개발자", description: "API/SDK 사용자" },
      { label: "내부 운영팀", description: "CS, 운영, 마케팅" },
      { label: "직접 입력", description: "별도 대상 설명" }
    ]
  },
  {
    question: "성공 기준은 무엇인가요? (측정 가능해야 합니다)",
    header: "3. 성공 기준",
    description: "예: 로딩 시간 2초 이내, 전환율 5% 증가, 에러율 0.1% 미만"
  },
  {
    question: "제약사항이나 주의할 점이 있나요?",
    header: "4. 제약사항",
    options: [
      { label: "기존 API 호환 필수", description: "Breaking change 불가" },
      { label: "성능 제약", description: "응답시간, 동시접속 등" },
      { label: "보안/개인정보", description: "인증, 암호화, 규제" },
      { label: "일정 제약", description: "특정 날짜까지 완료" },
      { label: "없음", description: "특별한 제약 없음" },
      { label: "직접 입력", description: "별도 제약 설명" }
    ]
  }
])

state.qa_results = { summary, target_user, success_criteria, constraints }
```

---

## Phase 2: 명세 작성

### 2-1. content-writer 에이전트 호출

```typescript
Bash("mkdir -p plans")

Agent("content-writer", `
경량 기능 명세서를 작성하세요. PRD가 아닌 **5개 섹션**만 작성합니다.

## 입력 데이터
기능명: ${feature_name}
Jira: ${args.jira || "없음"}

### Q&A 결과
- 요약: ${state.qa_results.summary}
- 대상 사용자: ${state.qa_results.target_user}
- 성공 기준: ${state.qa_results.success_criteria}
- 제약사항: ${state.qa_results.constraints}

### Jira 이슈 정보 (있으면)
${feature_context ? `
- 제목: ${feature_context.summary}
- 설명: ${feature_context.description}
- 타입: ${feature_context.type}
- 기존 AC: ${feature_context.acceptance_criteria || "없음"}
` : "Jira 연동 없음"}

## 명세서 템플릿 (5개 섹션 모두 작성 필수)

# Spec: ${feature_name}

- 작성일: ${current_date}
- 상태: Draft
- Jira: ${args.jira || "N/A"}

## 1. 요약
[1-2문장. 무엇을, 왜 만드는지.]

## 2. 사용자 스토리
| As a... | I want to... | So that... |
|---------|-------------|------------|
[최소 1개, 최대 3개. Q&A의 대상 사용자 기반.]

## 3. 기능 상세
### 입력/출력
- **입력**: [사용자 입력, API 파라미터 등]
- **출력**: [화면 변화, API 응답, 부작용 등]

### 정상 플로우 (Happy Path)
1. [순서대로 기술]
2. ...

### 예외 플로우 (Edge Cases)
| 상황 | 예상 동작 | 비고 |
|------|----------|------|
[최소 2개]

## 4. 수용 기준 (Acceptance Criteria)
- [ ] **Given** [전제] **When** [행동] **Then** [결과]
- [ ] ...
[최소 3개, 최대 7개. 모두 testable해야 함.]

## 5. 범위 외 (Out of Scope)
- [의도적으로 이번에 포함하지 않는 항목과 이유]
- ...

## 작성 규칙
- "요약"은 비개발자도 이해할 수 있는 수준
- 기능 상세의 플로우는 구현이 아닌 사용자 관점으로 작성
- 수용 기준은 반드시 Given/When/Then 형식
- 각 수용 기준이 자동 또는 수동으로 테스트 가능해야 함
- 범위 외 항목에는 "왜 제외하는지" 이유 포함

## 저장
Write("plans/spec-${feature_name}-${current_date}.md", spec_content)
`)
```

---

## Phase 3: 수용 기준 검증

### 3-1. Testable 여부 자동 판단

```typescript
spec_content = Read(`plans/spec-${feature_name}-${current_date}.md`)

// 수용 기준 추출
ac_section = spec_content.match(/## 4\. 수용 기준[\s\S]*?(?=## 5\.)/)?.[0]
ac_items = ac_section?.match(/- \[ \] .+/g) || []

// 각 AC의 testable 여부 검증
validation_results = []

for (const ac of ac_items) {
  // 주관적/모호한 표현 탐지
  subjective_patterns = [
    /편하게|쉽게|빠르게|자연스럽게|직관적/,  // 주관적 부사
    /개선|향상|최적화/,                       // 측정 불가 동사 (수치 없이)
    /적절한|합리적인|좋은/,                   // 주관적 형용사
    /등등|기타|여러/                           // 범위 모호
  ]

  is_subjective = subjective_patterns.some(p => p.test(ac))

  // Given/When/Then 형식 확인
  has_gwt = /Given|When|Then/i.test(ac)

  validation_results.push({
    ac: ac,
    testable: !is_subjective && has_gwt,
    issues: [
      ...(is_subjective ? ["주관적 표현 포함 — 구체적 수치/기준으로 대체 필요"] : []),
      ...(!has_gwt ? ["Given/When/Then 형식 미준수"] : [])
    ]
  })
}

// 검증 결과 출력
failed = validation_results.filter(r => !r.testable)

if (failed.length > 0) {
  console.log(`
  ⚠️  수용 기준 검증 결과: ${failed.length}건 수정 필요

  ${failed.map(f => `
  ❌ ${f.ac}
     문제: ${f.issues.join(', ')}
  `).join('\n')}

  예시:
  BAD:  "사용자가 편하게 느낀다" (주관적 — 측정 불가)
  GOOD: "Given 로그인 상태 When 버튼 클릭 Then 2초 이내 응답" (측정 가능)
  `)

  // 자동 수정 시도
  Agent("content-writer", `
  다음 수용 기준을 testable하게 수정하세요.

  ${failed.map(f => `- 원본: ${f.ac}\n  문제: ${f.issues.join(', ')}`).join('\n')}

  규칙:
  - 주관적 표현 → 구체적 수치/기준
  - Given/When/Then 형식 필수
  - 자동 또는 수동으로 검증 가능해야 함

  수정 결과를 Edit으로 반영하세요.
  파일: plans/spec-${feature_name}-${current_date}.md
  `)
} else {
  console.log(`✅ 수용 기준 ${ac_items.length}건 모두 testable`)
}
```

### 3-2. 수용 기준 수량 확인

```typescript
if (ac_items.length < 3) {
  console.log(`
  ⚠️  수용 기준 ${ac_items.length}건 — 최소 3건 필요.
  기능 상세의 정상 플로우/예외 플로우에서 추가 AC를 도출합니다.
  `)
  // content-writer가 보충
}

if (ac_items.length > 7) {
  console.log(`
  ⚠️  수용 기준 ${ac_items.length}건 — 7건 이하 권장.
  범위가 너무 크면 PRD(/prd)로 전환을 고려하세요.
  `)
}
```

---

## Phase 4: 저장 및 Jira 연동

### 4-1. 파일 저장 확인

```typescript
file_exists = Glob(`plans/spec-${feature_name}-${current_date}.md`)

if (!file_exists) {
  Bash("mkdir -p plans")
  Write(`plans/spec-${feature_name}-${current_date}.md`, spec_content)
}
```

### 4-2. Jira 코멘트 첨부 (선택)

```typescript
if (args.jira) {
  mcp__jira__jira_add_comment({
    issue_key: args.jira,
    body: `기능 명세서 작성 완료: plans/spec-${feature_name}-${current_date}.md\n\n수용 기준: ${ac_items.length}건 (검증 완료)\n상태: Draft`
  })

  console.log(`Jira ${args.jira}에 코멘트 추가됨`)
}
```

### 4-3. 완료 메시지

```
✅ 기능 명세서 작성 완료

파일: plans/spec-${feature_name}-${current_date}.md
섹션: 5/5 완성
수용 기준: ${ac_items.length}건 (testable 검증 완료)
Jira: ${args.jira ? `${args.jira}에 코멘트 추가됨` : "연동 없음"}

다음 단계:
| 항목 | 담당 | 액션 |
|------|------|------|
| 개발 착수 | 개발팀 | AC 기반 구현 시작 |
| 디자인 (필요 시) | 디자이너 | 기능 상세 기반 UI 설계 |
| 이해관계자 확인 | PM | 상태를 "Approved"로 변경 |

참고:
- 범위가 커지면 /prd 로 전환 권장
- 수용 기준은 QA 테스트 시나리오로 직접 사용 가능
```

---

## 예외 처리

### Jira 연결 불가

```typescript
if (jira_unavailable) {
  console.log(`
  ⚠️  Jira MCP 연결 실패.

  확인: .claude/.env 의 JIRA_TOKEN, JIRA_URL, JIRA_USERNAME

  대안: Jira 없이 Q&A 기반으로 명세서 작성 (워크플로 중단 없음)
  `)
  // Q&A로 대체 — Phase 1-3 그대로 진행
}
```

### feature_name 미입력

```typescript
if (!feature_name && !args.list) {
  AskUserQuestion({
    question: "어떤 기능의 명세서를 작성할까요?",
    header: "기능명",
    description: "영문 kebab-case 권장 (예: password-reset, email-notification)"
  })
}
```

### 범위 초과 감지

```typescript
// AC 7개 초과 또는 사용자 스토리 3개 초과 → PRD 전환 제안
if (ac_items.length > 7 || user_stories.length > 3) {
  console.log(`
  ⚠️  기능 범위가 경량 명세에 비해 큽니다.

  권장: /prd ${feature_name} 으로 정식 PRD 작성
  - PRD는 10개 섹션으로 리서치, 릴리스 계획, 리스크 분석 포함
  - 현재 명세 내용은 PRD Q&A 기본값으로 자동 활용됩니다
  `)
}
```

---

## 주의사항

### 금지사항
- ❌ 5개 섹션 중 하나라도 누락 금지
- ❌ 수용 기준에 주관적/모호한 표현 금지 ("개선", "편리", "빠르게" → 구체적 수치)
- ❌ Given/When/Then 형식 미준수 금지
- ❌ `plans/` 외 경로에 저장 금지
- ❌ 수용 기준 3개 미만으로 작성 금지

### 권장사항
- ✅ Jira 이슈 있으면 반드시 `--jira` 연동 (컨텍스트 활용 + 코멘트 추적)
- ✅ 수용 기준은 QA가 바로 테스트 시나리오로 쓸 수 있는 수준
- ✅ 범위 외(Out of Scope)에 "왜 제외하는지" 이유 명시
- ✅ 예외 플로우(Edge Cases)는 개발자가 가장 필요로 하는 부분 — 최소 2개
- ✅ 범위가 커지면 `/prd`로 전환 (명세 내용 자동 재활용)
- ✅ feature_name은 영문 kebab-case 사용 (파일명 일관성)

---

## Examples

### 예시 1: 기본 기능 명세
```
/spec password-reset
→ Q&A → 명세 작성 → AC 검증 → plans/spec-password-reset-2026-03-14.md
```

### 예시 2: Jira 이슈 기반
```
/spec email-notification --jira PROJ-456
→ Jira 조회 → Q&A (Jira 정보 기본값) → 명세 작성 → AC 검증
→ plans/spec-email-notification-2026-03-14.md
→ PROJ-456에 코멘트 추가
```

### 예시 3: 명세서 목록 조회
```
/spec --list
→ plans/spec-password-reset-2026-03-14.md — # Spec: password-reset
→ plans/spec-email-notification-2026-03-14.md — # Spec: email-notification
```

### 예시 4: 범위 초과 → PRD 전환
```
/spec large-feature
→ Q&A → 명세 작성 → AC 8건 + 스토리 4건 감지
→ ⚠️ 범위 초과. /prd large-feature 전환 권장
```
