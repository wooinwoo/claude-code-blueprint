---
description: PRD(Product Requirements Document) 작성/업데이트/리뷰. Jira 연동, 리서치 에이전트 활용, 10개 섹션 완전성 검증.
---

# PRD — 제품 요구사항 문서 작성

## Usage

```
/prd <feature-name>                → 새 PRD 작성
/prd <feature-name> PROJ-123       → Jira 이슈 연동 PRD 작성
/prd <feature-name> --update       → 기존 PRD 업데이트
/prd <feature-name> --review       → PRD 완전성 리뷰 (갭 리포트)
```

---

## Phase 1: 준비

### 1-1. Jira 이슈 조회 (선택)

```typescript
// 인자에 Jira 키가 있으면
if (jira_key) {
  issue = mcp__jira__jira_get_issue({ issue_key: jira_key })

  console.log(`
  이슈: ${issue.key}
  제목: ${issue.summary}
  설명: ${issue.description}
  에픽: ${issue.epic}
  라벨: ${issue.labels}
  `)

  // 이슈 정보를 Q&A 기본값으로 활용
  feature_context = {
    summary: issue.summary,
    description: issue.description,
    acceptance_criteria: issue.acceptance_criteria
  }
}

// 예외: Jira 연결 실패 시
catch (error) {
  console.log("⚠️ Jira 연결 실패. 수동 입력 모드로 전환합니다.")
  // Q&A로 대체 — 워크플로 중단하지 않음
}
```

### 1-2. 기존 PRD 탐색

```typescript
// plans/ 디렉토리에서 기존 PRD 검색
existing = Glob("plans/prd-*.md")

if (existing.length > 0) {
  console.log("기존 PRD 목록:")
  existing.forEach(f => console.log(`  - ${f}`))
}

// 동일 feature-name PRD 존재 여부 확인
target = Glob(`plans/prd-${feature_name}.md`)
if (target.length > 0) {
  console.log(`⚠️ plans/prd-${feature_name}.md 이미 존재합니다.`)
  console.log("--update 플래그로 업데이트하거나, 다른 이름을 사용하세요.")
  return
}
```

### 1-3. Q&A 정보 수집

```typescript
AskUserQuestion([
  {
    question: "이 기능의 목적은 무엇인가요?",
    header: "1. 목적 (Purpose)",
    description: "어떤 문제를 해결하나요? 왜 지금 만드나요?",
    // Jira 이슈가 있으면 기본값 제공
    default: feature_context?.description || ""
  },
  {
    question: "주요 타겟 사용자는 누구인가요?",
    header: "2. 타겟 사용자 (Target Users)",
    options: [
      { label: "내부 직원", description: "운영팀, CS팀, 관리자" },
      { label: "B2B 고객", description: "기업 관리자, 담당자" },
      { label: "B2C 사용자", description: "일반 최종 사용자" },
      { label: "개발자", description: "API/SDK 사용자" },
      { label: "직접 입력", description: "별도 타겟 사용자 설명" }
    ]
  },
  {
    question: "성공을 어떻게 측정하나요?",
    header: "3. 성공 지표 (Success Metrics)",
    description: "예: DAU 10% 증가, 전환율 5% 개선, CS 인입 30% 감소",
    // 정량적 목표가 없으면 "추후 정의"도 가능
  },
  {
    question: "이번 범위에 포함/제외할 내용은?",
    header: "4. 범위 (Scope)",
    description: "MVP에 반드시 포함할 것 / 의도적으로 제외할 것"
  },
  {
    question: "기술적 제약이나 의존성이 있나요?",
    header: "5. 제약사항 (Constraints)",
    options: [
      { label: "기존 API 호환", description: "Breaking change 불가" },
      { label: "성능 요구사항", description: "응답시간, 처리량 제약" },
      { label: "보안/규제", description: "개인정보, 인증, 규제 준수" },
      { label: "일정", description: "특정 출시일 고정" },
      { label: "없음", description: "특별한 제약 없음" },
      { label: "직접 입력", description: "별도 제약사항 설명" }
    ]
  }
])

// 수집 결과를 state에 저장
state.qa_results = { purpose, target_users, success_metrics, scope, constraints }
```

---

## Phase 2: 리서치 (선택)

### 2-1. 리서치 필요성 확인

```typescript
AskUserQuestion([
  {
    question: "배경 데이터 수집을 위한 리서치를 실행할까요?",
    header: "리서치",
    options: [
      { label: "예 — 시장/경쟁 리서치", description: "researcher-strategist 에이전트가 시장 데이터 수집 (1-2분)" },
      { label: "예 — 사용자 리서치", description: "ux-researcher 에이전트가 사용자 니즈 분석 (1-2분)" },
      { label: "건너뛰기", description: "바로 PRD 초안 작성으로" }
    ]
  }
])
```

### 2-2. 리서치 실행

```typescript
if (user_chose_market) {
  // researcher-strategist 에이전트 호출
  research_result = Agent("researcher-strategist", `
    다음 기능에 대한 시장 배경 데이터를 수집하세요.

    기능: ${feature_name}
    목적: ${state.qa_results.purpose}
    타겟: ${state.qa_results.target_users}

    조사 항목:
    1. 유사 기능을 제공하는 경쟁사/제품 3-5개
    2. 관련 시장 트렌드 2-3개
    3. 벤치마크 데이터 (있으면)

    출력 형식:
    ### 경쟁사 현황
    | 경쟁사 | 유사 기능 | 차별점 | 출처 |
    |--------|----------|--------|------|

    ### 시장 트렌드
    1. [트렌드] — 근거: [데이터/출처]

    ### 시사점
    [PRD에 반영할 인사이트]
  `)
}

if (user_chose_user) {
  research_result = Agent("ux-researcher", `
    다음 기능의 사용자 니즈를 분석하세요.

    기능: ${feature_name}
    타겟: ${state.qa_results.target_users}
    해결 문제: ${state.qa_results.purpose}

    분석 항목:
    1. 타겟 사용자의 주요 페인 포인트 3-5개
    2. 예상 사용자 시나리오 2-3개
    3. 유사 제품 사용자 피드백 패턴

    출력 형식:
    ### 페인 포인트
    1. [페인 포인트] — 심각도: HIGH/MEDIUM/LOW

    ### 사용자 시나리오
    | As a... | I want to... | So that... |

    ### 인사이트
    [PRD에 반영할 사용자 인사이트]
  `)
}

state.research_result = research_result
```

---

## Phase 3: 초안 작성

### 3-1. content-writer 에이전트 호출

```typescript
Bash("mkdir -p plans")
Agent("content-writer", `
  PRD를 작성하세요.

  ## 입력 데이터
  기능명: ${feature_name}
  Jira: ${jira_key || "없음"}

  ### Q&A 결과
  - 목적: ${state.qa_results.purpose}
  - 타겟 사용자: ${state.qa_results.target_users}
  - 성공 지표: ${state.qa_results.success_metrics}
  - 범위: ${state.qa_results.scope}
  - 제약사항: ${state.qa_results.constraints}

  ### 리서치 결과
  ${state.research_result || "리서치 미실행"}

  ## PRD 템플릿 (10개 섹션 모두 작성 필수)

  # PRD: ${feature_name}

  ## 1. 개요
  - **작성자**: (사용자 입력 또는 "TBD")
  - **작성일**: ${today} (YYYY-MM-DD)
  - **상태**: Draft
  - **관련 Jira**: ${jira_key || "N/A"}
  - **관련 OKR**: (plans/okr-*.md에서 매칭되는 OKR 참조)

  ## 2. 배경 및 목적
  ### 문제 정의
  [Q&A의 '목적' 기반 — 구체적인 문제 서술]
  ### 기회
  [이 기능이 제공하는 비즈니스/사용자 가치]
  ### 근거 데이터
  [리서치 결과 또는 Q&A에서 언급된 데이터. 없으면 "데이터 수집 필요" 표시]

  ## 3. 목표 및 성공 지표
  | 지표 | 현재 | 목표 | 측정 방법 |
  |------|------|------|-----------|
  [Q&A의 '성공 지표' 기반]

  ## 4. 사용자 스토리
  | As a... | I want to... | So that... |
  |---------|-------------|------------|
  [타겟 사용자 기반 3-5개 스토리]

  ## 5. 기능 명세
  ### 5.1 범위 (In Scope)
  [Q&A의 '범위' 기반 — 구체적 기능 목록]
  ### 5.2 범위 외 (Out of Scope)
  [의도적 제외 항목과 이유]
  ### 5.3 상세 요구사항
  [기능별 상세 스펙]

  ## 6. 디자인
  [와이어프레임/목업 필요 여부, UI 요구사항 — 상세 디자인은 "별도 작성 예정" 가능]

  ## 7. 기술 고려사항
  [Q&A의 '제약사항' 기반 — API, 데이터 모델, 의존성, 마이그레이션]

  ## 8. 릴리스 계획
  - Phase 1 (MVP): [핵심 기능]
  - Phase 2: [확장 기능]
  - Phase 3: [최적화/고도화]

  ## 9. 리스크 및 완화 방안
  | 리스크 | 확률 | 영향 | 완화 방안 |
  |--------|------|------|-----------|
  [최소 2-3개]

  ## 10. 참고 자료
  [리서치 출처, 관련 문서, 링크]

  ## 작성 규칙
  - 모든 주장에 근거 데이터 포함 (없으면 "데이터 수집 필요" 명시)
  - 추상적 표현 금지 ("개선", "향상" → 구체적 수치/기준)
  - 10개 섹션 모두 빠짐없이 작성
  - 데이터 부족 섹션은 "[TBD — 추가 조사 필요: 조사 항목]" 형식으로 표시

  ## 저장 경로
  Write("plans/prd-${feature_name}.md", prd_content)
`)
```

---

## Phase 4: 완전성 검증

### 4-1. 10개 섹션 체크

```typescript
prd_content = Read(`plans/prd-${feature_name}.md`)

// 필수 섹션 검증
required_sections = [
  "## 1. 개요",
  "## 2. 배경 및 목적",
  "## 3. 목표 및 성공 지표",
  "## 4. 사용자 스토리",
  "## 5. 기능 명세",
  "## 6. 디자인",
  "## 7. 기술 고려사항",
  "## 8. 릴리스 계획",
  "## 9. 리스크 및 완화 방안",
  "## 10. 참고 자료"
]

missing = required_sections.filter(s => !prd_content.includes(s))
tbd_items = prd_content.match(/\[TBD.*?\]/g) || []
```

### 4-2. 결과 보고

```
📋 PRD 완전성 검증

섹션 체크 (10/10):
✅ 1. 개요
✅ 2. 배경 및 목적
✅ 3. 목표 및 성공 지표
✅ 4. 사용자 스토리
✅ 5. 기능 명세
⚠️ 6. 디자인 — [TBD — 디자인 미확정]
✅ 7. 기술 고려사항
✅ 8. 릴리스 계획
✅ 9. 리스크 및 완화 방안
✅ 10. 참고 자료

미완성 항목: 1개
- 섹션 6: 디자인 — 와이어프레임/목업 추가 필요

저장 위치: plans/prd-{feature_name}.md
```

---

## Phase 5: 저장 및 Jira 연동

### 5-1. 파일 저장 확인

```typescript
// Phase 3에서 content-writer가 저장 완료
// 파일 존재 확인
file_exists = Glob(`plans/prd-${feature_name}.md`)

if (!file_exists) {
  // content-writer가 저장 실패한 경우 직접 저장
  Write(`plans/prd-${feature_name}.md`, prd_content)
}
```

### 5-2. Jira 코멘트 (선택)

```typescript
if (jira_key) {
  mcp__jira__jira_add_comment({
    issue_key: jira_key,
    body: `PRD 작성 완료: plans/prd-${feature_name}.md\n\n섹션 완전성: ${complete_count}/10\n미완성: ${tbd_items.length}개 항목`
  })
}
```

### 5-3. 완료 메시지

```
✅ PRD 작성 완료

파일: plans/prd-{feature_name}.md
완전성: 9/10 섹션 완성
미완성: 1개 (디자인 — TBD)
리서치: 시장 리서치 반영됨
Jira: PROJ-123에 코멘트 추가됨

다음 단계:
| 항목 | 담당 | 액션 |
|------|------|------|
| 디자인 와이어프레임 | 디자이너 | 섹션 6 업데이트 |
| 이해관계자 리뷰 | PM | 상태를 "In Review"로 변경 |
| 기술 검토 | Tech Lead | 섹션 7 보완 |
```

---

## `--update` 모드

### 기존 PRD 수정

```typescript
// 1. 기존 PRD 읽기
prd = Read(`plans/prd-${feature_name}.md`)

if (!prd) {
  console.log(`❌ plans/prd-${feature_name}.md 파일을 찾을 수 없습니다.`)
  existing = Glob("plans/prd-*.md")
  console.log("기존 PRD:", existing)
  return
}

// 2. 현재 섹션 목록 출력
console.log(`
현재 PRD 구조:
1. 개요 — 완성
2. 배경 및 목적 — 완성
3. 목표 및 성공 지표 — 완성
4. 사용자 스토리 — 완성
5. 기능 명세 — 완성
6. 디자인 — [TBD]
7. 기술 고려사항 — 완성
8. 릴리스 계획 — 완성
9. 리스크 및 완화 방안 — 완성
10. 참고 자료 — 완성
`)

// 3. 수정 대상 질문
AskUserQuestion([
  {
    question: "어떤 섹션을 업데이트하시겠어요?",
    header: "섹션 선택",
    options: [
      { label: "특정 섹션 번호", description: "예: 3, 5, 6" },
      { label: "전체 업데이트", description: "모든 섹션 재검토" },
      { label: "TBD 항목만", description: "미완성 항목만 채우기" }
    ]
  },
  {
    question: "업데이트 내용을 알려주세요",
    header: "변경 사항",
    description: "새로운 정보, 변경된 요구사항, 추가 데이터 등"
  }
])

// 4. Edit으로 특정 섹션만 수정
Edit(`plans/prd-${feature_name}.md`, {
  old_string: "기존 섹션 내용",
  new_string: "업데이트된 섹션 내용"
})

// 5. 상태 업데이트
Edit(`plans/prd-${feature_name}.md`, {
  old_string: "**상태**: Draft",
  new_string: "**상태**: In Review"
})
```

---

## `--review` 모드

### PRD 완전성 리뷰

```typescript
// 1. 기존 PRD 읽기
prd = Read(`plans/prd-${feature_name}.md`)

if (!prd) {
  console.log(`❌ plans/prd-${feature_name}.md 파일을 찾을 수 없습니다.`)
  return
}

// 2. 각 섹션별 품질 검증
review_criteria = {
  "1. 개요":       "작성일, 상태, 관련 OKR이 있는가",
  "2. 배경 및 목적": "문제 정의가 구체적인가, 근거 데이터가 있는가",
  "3. 목표 및 성공 지표": "정량적 지표가 있는가, 측정 방법이 명시되었는가",
  "4. 사용자 스토리": "최소 3개 스토리, As-a/I-want-to/So-that 형식인가",
  "5. 기능 명세":   "In/Out Scope 구분, 상세 요구사항이 있는가",
  "6. 디자인":      "와이어프레임/목업 링크 또는 UI 요구사항이 있는가",
  "7. 기술 고려사항": "API, 데이터 모델, 의존성이 명시되었는가",
  "8. 릴리스 계획":  "Phase별 구분이 있는가, 일정 추정이 있는가",
  "9. 리스크":      "최소 2개 리스크, 완화 방안이 있는가",
  "10. 참고 자료":  "출처 링크가 있는가"
}

// 3. 갭 리포트 출력
console.log(`
📋 PRD 리뷰 — plans/prd-${feature_name}.md

| 섹션 | 상태 | 이슈 |
|------|------|------|
| 1. 개요 | ✅ PASS | — |
| 2. 배경 및 목적 | ⚠️ WARN | 근거 데이터 없음 |
| 3. 목표 및 성공 지표 | ✅ PASS | — |
| 4. 사용자 스토리 | ⚠️ WARN | 2개뿐 (최소 3개 권장) |
| 5. 기능 명세 | ✅ PASS | — |
| 6. 디자인 | ❌ FAIL | 섹션 전체 TBD |
| 7. 기술 고려사항 | ✅ PASS | — |
| 8. 릴리스 계획 | ✅ PASS | — |
| 9. 리스크 | ✅ PASS | — |
| 10. 참고 자료 | ⚠️ WARN | 출처 링크 1개뿐 |

요약: PASS 7 / WARN 2 / FAIL 1

추천 액션:
1. [FAIL] 섹션 6 — 디자인 와이어프레임 추가 → /prd ${feature_name} --update
2. [WARN] 섹션 2 — 근거 데이터 보완 → /research --market ${feature_name}
3. [WARN] 섹션 4 — 사용자 스토리 1개 추가
`)
```

---

## 주의사항

### 금지사항
- ❌ 근거 없는 주장 작성 금지 — 데이터 없으면 `[TBD]` 표시
- ❌ 10개 섹션 중 하나라도 누락 금지
- ❌ 추상적 성공 지표 금지 ("개선", "향상" → 구체적 수치)
- ❌ `plans/` 외 경로에 저장 금지

### 권장사항
- ✅ Jira 이슈 있으면 반드시 연동 (컨텍스트 활용)
- ✅ 리서치 결과가 있으면 섹션 2, 10에 반영
- ✅ 기존 OKR (`plans/okr-*.md`)과 연결
- ✅ TBD 항목에 "무엇을 조사해야 하는지" 구체적으로 명시
- ✅ `--review` 후 `--update`로 이어서 보완

---

## Examples

### 예시 1: Jira 연동 PRD
```
/prd payment-retry PROJ-456
```
→ Jira PROJ-456 조회 → Q&A → 시장 리서치 → PRD 작성 → plans/prd-payment-retry.md 저장

### 예시 2: 독립 PRD
```
/prd onboarding-v2
```
→ Q&A → 리서치 건너뛰기 → PRD 작성 → plans/prd-onboarding-v2.md 저장

### 예시 3: 리뷰 후 업데이트
```
/prd onboarding-v2 --review
→ 갭 리포트 확인
/prd onboarding-v2 --update
→ 섹션 6 디자인 추가, 섹션 2 데이터 보완
```
