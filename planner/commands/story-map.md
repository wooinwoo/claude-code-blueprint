---
description: 사용자 스토리 맵 작성. 활동-태스크-스토리 계층 구조 + 릴리스 라인 매핑.
---

# Story Map — 사용자 스토리 맵

## Usage

```
/story-map <feature>                → 기능별 스토리 맵 생성
/story-map --journey <persona>      → 페르소나별 전체 사용자 여정 맵
/story-map --prioritize             → 기존 스토리 맵 릴리스 라인 재조정
```

## 용도

**사용자 중심 기능 분해**
- Activity → Task → User Story 계층 구조 생성
- 릴리스 라인(MVP / v1.1 / v2) 매핑
- PRD 기반 스토리 도출
- 추정(S/M/L) 및 우선순위 결정

---

## Phase 1: 컨텍스트 수집

### 1-1. 관련 PRD 탐색

```typescript
// 기능명으로 기존 PRD 검색
const prd_files = Glob("plans/prd-*{feature}*.md")

if (prd_files.length > 0) {
  const prd_content = Read(prd_files[0])
  // PRD에서 요구사항, 사용자 스토리, 기능 명세 추출
  console.log(`
  📄 관련 PRD 발견: ${prd_files[0]}
  → PRD 내용을 스토리 맵의 기초 자료로 활용합니다.
  `)
}
```

**PRD 없을 때:**
```
관련 PRD가 없습니다. 사용자 입력 기반으로 스토리 맵을 생성합니다.
```

### 1-2. 핵심 정보 수집

```typescript
AskUserQuestion([
  {
    question: "이 기능의 타겟 페르소나는 누구인가요?",
    header: "타겟 페르소나",
    description: `PRD가 있으면 PRD의 사용자 스토리에서 추출합니다.
없으면 직접 입력하세요.
예: "온라인 쇼핑을 주로 하는 30대 직장인"`,
    options: [
      // PRD에서 추출한 페르소나가 있으면 옵션으로 제시
      { label: "{prd_persona}", description: "PRD에서 추출" },
      { label: "직접 입력", description: "페르소나를 직접 정의" }
    ]
  },
  {
    question: "이 사용자의 핵심 목표(Goal)는 무엇인가요?",
    header: "사용자 목표",
    description: `사용자가 이 기능을 통해 달성하려는 것.
예: "원하는 상품을 빠르게 찾아서 구매한다"`,
    options: []  // 자유 입력
  }
])
```

---

## Phase 2: Activity 발견 (Backbone)

### 2-1. ux-researcher 에이전트 — 상위 활동 도출

```typescript
const activities_result = Agent("ux-researcher", `페르소나: {persona}
사용자 목표: {goal}
{prd_content가 있으면: '관련 PRD 내용:\n' + prd_summary}

이 페르소나가 '{goal}'을 달성하기 위해 수행하는 3-5개의 상위 사용자 활동(Activity)을 식별해줘.
각 Activity는 사용자가 하는 '큰 단위의 행동'이야 (backbone).

반드시 아래 형식으로 응답해줘:

## Activities (Backbone)

1. **{활동명}** — {1문장 설명}
   - 시작 조건: {사용자가 이 활동을 시작하는 트리거}
   - 완료 조건: {이 활동이 끝나는 시점}

2. **{활동명}** — {1문장 설명}
   ...

## 활동 흐름
{Activity 1} → {Activity 2} → ... (사용자의 자연스러운 흐름 순서)`)
```

### 2-2. 사용자 확인

```typescript
AskUserQuestion([
  {
    question: "도출된 활동(Activity) 목록이 맞나요?",
    header: "Activity 검토",
    description: `${activities_list}
수정하거나 추가/삭제할 활동이 있으면 입력하세요.`,
    options: [
      { label: "확인", description: "이대로 진행" },
      { label: "수정", description: "활동 추가/삭제/변경" }
    ]
  }
])

// "수정" 선택 시 → 사용자 입력 반영 후 다시 확인
```

---

## Phase 3: Task 분해

### 3-1. Activity별 Task 도출

각 Activity에 대해 ux-researcher 에이전트를 호출합니다.

> 독립적인 Activity들이므로 **병렬 실행 가능** (Task tool 동시 호출).

```typescript
// Activity마다 1회
const task_result = Agent("ux-researcher", `페르소나: {persona}
사용자 목표: {goal}

Activity '{activity_name}'을 3-7개의 Task로 분해해줘.
각 Task는 Activity 안에서 사용자가 수행하는 '구체적인 단계'야.

반드시 아래 형식으로 응답해줘:

### Activity: {activity_name}

#### Tasks
{activity_number}.1 **{태스크명}** — {1문장 설명}
  - 사용자 행동: {사용자가 실제로 하는 것}
  - 시스템 응답: {시스템이 제공하는 것}

{activity_number}.2 **{태스크명}** — {1문장 설명}
  ...

#### Critical Path
필수 태스크: [{필수}] / 선택 태스크: [{선택}]`)
```

### 3-2. Task 목록 확인

```
📋 Task 분해 결과

Activity 1: {활동명}
  1.1 {태스크} — {설명}
  1.2 {태스크} — {설명}
  1.3 {태스크} — {설명}

Activity 2: {활동명}
  2.1 {태스크} — {설명}
  2.2 {태스크} — {설명}
  ...

수정이 필요하면 입력하세요. 없으면 "확인"을 입력하세요.
```

---

## Phase 4: Story 생성 + 추정 + 릴리스 라인

### 4-1. Task별 User Story 생성

각 Task에서 User Story를 자동 생성합니다:

```
형식: "As a {persona}, I want to {action}, so that {benefit}"

예시:
Task 1.1 "상품 검색" →
  - As a 30대 직장인, I want to 키워드로 상품을 검색할 수 있다, so that 원하는 상품을 빠르게 찾을 수 있다.
  - As a 30대 직장인, I want to 최근 검색어를 볼 수 있다, so that 반복 검색을 빠르게 할 수 있다.
```

### 4-2. 스토리 배치별 추정 + 릴리스 라인

Activity 단위로 묶어서 사용자에게 확인합니다:

```typescript
// Activity마다 한 번씩 AskUserQuestion
for (const activity of activities) {
  AskUserQuestion([
    {
      question: `Activity "${activity.name}"의 스토리를 검토하세요.`,
      header: `📝 ${activity.name} — 스토리 검토`,
      description: `각 스토리의 추정(S/M/L)과 릴리스 라인(MVP/v1.1/v2)을 입력하세요.

| # | 스토리 | 추정 | 릴리스 |
|---|--------|------|--------|
| 1 | As a... I want to... so that... | ? | ? |
| 2 | As a... I want to... so that... | ? | ? |
| 3 | As a... I want to... so that... | ? | ? |

추정 기준:
- S: 반나절 이하
- M: 1-2일
- L: 3일 이상

릴리스 기준:
- MVP: 첫 출시에 반드시 포함
- v1.1: 첫 출시 직후 빠르게 추가
- v2: 장기 로드맵

각 스토리 번호와 함께 "1:S/MVP, 2:M/v1.1, 3:L/v2" 형태로 입력하세요.
스토리 추가/삭제/수정도 가능합니다.`,
      options: []  // 자유 입력
    }
  ])
}
```

**추정 가이드:**
```
추정 참고:
- S (Small): API 호출 1개, UI 컴포넌트 1-2개, 반나절 이하
- M (Medium): API 연동 + UI + 상태 관리, 1-2일
- L (Large): 복잡한 로직 + 다수 화면 + 테스트, 3일 이상
  → L은 스토리를 더 작게 분할하는 것을 권장합니다
```

---

## Phase 5: 조립 및 저장

### 5-1. content-writer 에이전트로 문서 조립

```typescript
const story_map_doc = Agent("content-writer", `다음 스토리 맵 데이터를 문서로 작성해줘.

기능: {feature}
페르소나: {persona}
사용자 목표: {goal}
관련 PRD: {prd_file 또는 '없음'}

Activities, Tasks, Stories 데이터:
{collected_data}

아래 형식으로 plans/story-map-{feature}.md에 작성해줘:

# Story Map: {기능명}

## 메타 정보
- **날짜**: {date}
- **페르소나**: {persona}
- **사용자 목표**: {goal}
- **관련 PRD**: {prd_file}
- **상태**: Draft

## 요약
- Activities: {count}개
- Tasks: {count}개
- Stories: {count}개 (MVP: {n} / v1.1: {n} / v2: {n})
- 추정 합계: S×{n} + M×{n} + L×{n}

## 릴리스 라인 개요
| 릴리스 | 스토리 수 | 추정 규모 | 핵심 기능 |
|--------|----------|----------|----------|
| MVP | {n} | {추정합} | {주요 기능 요약} |
| v1.1 | {n} | {추정합} | {주요 기능 요약} |
| v2 | {n} | {추정합} | {주요 기능 요약} |

## Story Map

### Activity 1: {활동명}
> {활동 설명}

#### Task 1.1: {태스크명}
| 릴리스 | 스토리 | 추정 |
|--------|--------|------|
| MVP | As a {persona}, I want to {action}, so that {benefit} | S |
| v1.1 | As a {persona}, I want to {action}, so that {benefit} | M |

#### Task 1.2: {태스크명}
...

### Activity 2: {활동명}
...

## 의존성
- Story {x} → Story {y} (선행 관계)

## 참고사항
- {PRD에서 가져온 관련 컨텍스트}
- {추정 시 고려한 리스크}`)
```

### 5-2. 저장

```typescript
Bash("mkdir -p plans")
// content-writer가 Write 도구로 직접 저장
// plans/story-map-{feature}.md
```

### 5-3. 완료 메시지

```
✅ 스토리 맵 완료!

📄 문서: plans/story-map-{feature}.md
👤 페르소나: {persona}
🎯 목표: {goal}

구조:
- Activities: {n}개
- Tasks: {n}개
- Stories: {n}개

릴리스 배분:
- MVP: {n}개 (S×{n}, M×{n}, L×{n})
- v1.1: {n}개
- v2: {n}개
```

---

## 변형 모드

### `--journey <persona>` — 사용자 여정 맵

기능 단위가 아닌, 페르소나의 **전체 서비스 경험**을 매핑합니다.

```
차이점:
- 특정 기능이 아닌, 서비스 전체 여정을 대상으로 함
- Activity가 서비스 접점 단위 (가입 → 탐색 → 구매 → 사후관리)
- 감정 곡선 (Emotion Map) 포함
- 터치포인트별 Pain Point / Opportunity 식별
```

```typescript
const journey_result = Agent("ux-researcher", `페르소나: {persona}
서비스: {service_name}

이 페르소나의 전체 서비스 사용 여정을 매핑해줘.
서비스 인지 → 가입 → 핵심 사용 → 재방문/이탈까지의 전체 흐름.

반드시 아래 형식으로:

## Journey Map

### Stage 1: {단계명}
- **터치포인트**: {접점}
- **행동**: {사용자가 하는 것}
- **생각**: {사용자가 생각하는 것}
- **감정**: 😊/😐/😤 (긍정/중립/부정)
- **Pain Point**: {불편}
- **Opportunity**: {개선 기회}

### Stage 2: ...

## Emotion Curve
(ASCII 그래프: 각 Stage의 감정 변화)

## Top Opportunities
1. {가장 큰 개선 기회와 기대 효과}`)
```

저장: `plans/journey-map-{persona}.md`

### `--prioritize` — 기존 스토리 맵 재조정

```typescript
// 1. 기존 스토리 맵 파일 찾기
const story_maps = Glob("plans/story-map-*.md")

if (story_maps.length === 0) {
  console.log("기존 스토리 맵이 없습니다. /story-map <feature>로 먼저 생성하세요.")
  return
}

// 여러 파일이면 선택
if (story_maps.length > 1) {
  AskUserQuestion([
    {
      question: "어떤 스토리 맵을 조정하시겠습니까?",
      header: "스토리 맵 선택",
      options: story_maps.map(f => ({
        label: f,
        description: ""
      }))
    }
  ])
}

// 2. 파일 읽기
const content = Read(selected_file)

// 3. 각 스토리의 릴리스 라인을 사용자와 재조정
// Phase 4-2와 동일한 AskUserQuestion 사용
// 변경된 내용으로 파일 업데이트
```

---

## 예외 처리

### PRD 파일 없음

```
관련 PRD가 없습니다 (plans/prd-*{feature}*.md).
사용자 입력만으로 스토리 맵을 생성합니다.
→ Phase 1에서 추가 컨텍스트를 더 상세하게 질문합니다.
```

### 스토리가 너무 클 때 (L 추정)

```
⚠️  스토리 "{story}"의 추정이 L입니다.
L 스토리는 더 작은 스토리로 분할하는 것을 권장합니다.

분할하시겠습니까?
- 분할: ux-researcher가 하위 스토리 제안
- 유지: L 그대로 유지
```

### 기존 스토리 맵 없음 (`--prioritize`)

```
기존 스토리 맵 파일이 없습니다 (plans/story-map-*.md).
/story-map <feature>로 먼저 스토리 맵을 생성하세요.
```

---

## 주의사항

### 금지사항
- ❌ 사용자 스토리를 개발 태스크로 작성하지 않음 (기술 용어 배제)
- ❌ 추정/릴리스 라인을 자동 결정하지 않음 (반드시 사용자 확인)
- ❌ Activity를 7개 이상 생성하지 않음 (3-5개 유지)
- ❌ 한 번에 모든 스토리를 물어보지 않음 (Activity 단위로 나눠서)

### 권장사항
- ✅ PRD가 있으면 반드시 참조하여 정합성 유지
- ✅ "As a... I want to... so that..." 형식 엄수
- ✅ MVP 스토리는 최소화 (핵심 가치만)
- ✅ L 추정 스토리는 분할 권장
- ✅ 의존성 관계 명시 (어떤 스토리가 선행되어야 하는지)

---

## Examples

### 예시 1: 기능별 스토리 맵
```
/story-map 상품-검색
```
→ PRD 탐색 → 페르소나/목표 수집 → Activity 도출 → Task 분해 → Story 생성 + 추정 → plans/story-map-상품-검색.md 저장

### 예시 2: 사용자 여정 맵
```
/story-map --journey 신규-사용자
```
→ 서비스 전체 여정 매핑 → 감정 곡선 → Pain Point/Opportunity → plans/journey-map-신규-사용자.md 저장

### 예시 3: 우선순위 재조정
```
/story-map --prioritize
```
→ 기존 스토리 맵 읽기 → 각 스토리 릴리스 라인 재조정 → 파일 업데이트
