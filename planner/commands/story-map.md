---
description: 사용자 스토리 맵 작성. 활동-태스크-스토리 계층 구조 + 릴리스 라인 매핑. 사용자와 함께 워크숍 형태로 진행.
---

# Story Map — 사용자 스토리 맵

## Usage

```
/story-map <feature>                → 기능별 스토리 맵 생성
/story-map --journey <persona>      → 페르소나별 전체 사용자 여정 맵
/story-map --prioritize             → 기존 스토리 맵 릴리스 라인 재조정
```

## 용도

**사용자 중심 기능 분해 — 워크숍 방식**
- Activity → Task → User Story 계층 구조 생성
- 릴리스 라인(MVP / v1.1 / v2) 매핑
- PRD 기반 스토리 도출
- 추정(S/M/L) 및 우선순위 결정
- **모든 주요 단계에서 사용자 확인/수정/추가를 받는 인터랙티브 프로세스**

---

## 핵심 개념: Walking Skeleton

**Release 1(MVP)은 전체 Activity를 최소한으로 커버하는 최소 스토리 세트**여야 한다.

```
BAD MVP:  Activity 1의 스토리만 완벽하게 구현, Activity 2~4는 미구현
GOOD MVP: Activity 1~4 각각 최소 1개 핵심 스토리 포함 (Walking Skeleton)
```

Walking Skeleton = 모든 뼈대(Activity)를 관통하는 최소한의 동작 가능한 기능.
- 사용자가 전체 흐름을 처음부터 끝까지 경험할 수 있어야 한다.
- 각 Activity에서 "없으면 다음 Activity로 넘어갈 수 없는" 스토리가 MVP 대상.
- 편의 기능, 예외 처리, 고급 기능은 v1.1/v2로 분류.

```
예시 — "상품 구매" 스토리 맵:

Activity:     검색 → 상세 보기 → 장바구니 → 결제
Walking
Skeleton:     키워드 검색  상품 정보   담기/빼기   카드 결제
(MVP)         (1개)       표시(1개)   (2개)      (1개)

v1.1:         필터 검색    리뷰 보기   수량 변경   간편 결제
v2:           추천 검색    비교하기    위시리스트   분할 결제
```

---

## Phase 1: 컨텍스트 수집

### 1-1. 관련 PRD 탐색

```typescript
// 기능명으로 기존 PRD 검색
const prd_files = Glob("plans/prd-*{feature}*.md")

if (prd_files.length > 0) {
  const prd_content = Read(prd_files[0])
  // PRD에서 요구사항, 사용자 스토리, 기능 명세 추출
}
```

**PRD 없을 때:**
```
관련 PRD가 없습니다. 사용자 입력 기반으로 스토리 맵을 생성합니다.
→ Phase 1에서 추가 컨텍스트를 더 상세하게 질문합니다.
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

## Phase 2: Activity 발견 (Backbone) + 사용자 워크숍

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

### 2-2. 사용자 검토 — Activity 확인/수정/추가 (인터랙션 필수)

> **핵심**: 에이전트가 도출한 Activity를 그대로 확정하지 않는다. 반드시 사용자에게 검토받는다.

```typescript
AskUserQuestion([
  {
    question: "도출된 활동(Activity) 목록을 검토해주세요.",
    header: "Activity 워크숍",
    description: `아래 Activity가 사용자의 실제 행동 흐름을 잘 반영하고 있나요?

${activities_list}

다음 중 선택하세요:
1. 확인 — 이대로 진행
2. 수정 — 활동명/설명 변경 (예: "Activity 2 설명을 OO로 수정")
3. 추가 — 빠진 Activity가 있음 (예: "검색 전에 '카테고리 탐색' 활동 추가")
4. 삭제 — 불필요한 Activity 제거 (예: "Activity 4 삭제")
5. 순서 변경 — 흐름 순서 조정 (예: "2번과 3번 순서 바꿈")`,
    options: [
      { label: "확인", description: "이대로 진행" },
      { label: "수정 필요", description: "변경사항을 입력하세요" }
    ]
  }
])

// "수정 필요" 선택 시 → 사용자 피드백 반영 후 다시 확인 (확인될 때까지 반복)
```

---

## Phase 3: Task 분해 + 사용자 검토

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

### 3-2. 사용자 검토 — Activity별 Task 확인 (인터랙션 필수)

> **핵심**: Task 목록도 사용자 확인 없이 확정하지 않는다. Activity별로 나눠서 묻는다 (한 번에 전부 묻지 않음).

```typescript
// Activity마다 한 번씩 확인
for (const activity of activities) {
  AskUserQuestion([
    {
      question: `"${activity.name}" Activity의 Task가 맞나요?`,
      header: `Task 검토 — ${activity.name}`,
      description: `${activity.tasks_list}

이 Task들이 사용자의 실제 행동 단계를 잘 반영하고 있나요?

다음 중 선택하세요:
1. 확인 — 이대로 진행
2. 수정 — Task 변경/추가/삭제
3. 분할 — Task가 너무 크면 더 작게 나눔
4. 병합 — 별도일 필요 없는 Task 합침`,
      options: [
        { label: "확인", description: "이대로 진행" },
        { label: "수정 필요", description: "변경사항을 입력하세요" }
      ]
    }
  ])
  // "수정 필요" 선택 시 → 피드백 반영 후 다시 확인
}
```

---

## Phase 4: Story 생성 + 우선순위 워크숍

### 4-1. Task별 User Story 생성

각 Task에서 User Story를 자동 생성합니다:

```
형식: "As a {persona}, I want to {action}, so that {benefit}"

예시:
Task 1.1 "상품 검색" →
  - As a 30대 직장인, I want to 키워드로 상품을 검색할 수 있다, so that 원하는 상품을 빠르게 찾을 수 있다.
  - As a 30대 직장인, I want to 최근 검색어를 볼 수 있다, so that 반복 검색을 빠르게 할 수 있다.
```

### 4-2. Walking Skeleton 1차 분류

사용자에게 묻기 전에, Walking Skeleton 원칙에 따라 **초안 분류**를 준비한다.

```typescript
// 각 Activity에서 "다음 Activity로 넘어가려면 반드시 필요한" 스토리를 MVP 후보로 표시
const mvp_candidates = activities.map(activity => {
  return activity.stories.filter(story => story.is_critical_path)
})

// Walking Skeleton 검증: 모든 Activity에 최소 1개 MVP 스토리가 있는가?
for (const activity of activities) {
  const mvp_count = activity.stories.filter(s => s.release === 'MVP').length
  if (mvp_count === 0) {
    // 경고: 이 Activity에 MVP 스토리가 없으면 Walking Skeleton이 끊김
    warn(`⚠️ "${activity.name}"에 MVP 스토리가 없습니다. 전체 흐름이 끊깁니다.`)
  }
}
```

### 4-3. 우선순위 워크숍 — 릴리스 라인 결정 (핵심 인터랙션)

> **핵심**: 릴리스 분류(MVP/v1.1/v2)는 Claude가 단독 결정하지 않는다. 사용자와 함께 결정한다.

```typescript
// Activity마다 한 번씩 워크숍
for (const activity of activities) {
  AskUserQuestion([
    {
      question: `"${activity.name}"의 스토리를 릴리스별로 분류해주세요.`,
      header: `릴리스 워크숍 — ${activity.name}`,
      description: `아래는 AI가 제안하는 초안입니다. 자유롭게 수정하세요.

| # | 스토리 | 추정 | 릴리스(제안) | 사유 |
|---|--------|------|-------------|------|
| 1 | As a... I want to... so that... | S | MVP | Walking Skeleton 필수 |
| 2 | As a... I want to... so that... | M | v1.1 | 편의 기능 |
| 3 | As a... I want to... so that... | L | v2 | 고급 기능 |

추정 기준:
- S: 반나절 이하
- M: 1-2일
- L: 3일 이상 (→ 스토리 분할 권장)

릴리스 기준:
- MVP: 전체 흐름(Walking Skeleton)에 필수. 없으면 다음 단계 불가
- v1.1: 첫 출시 직후 추가. UX 향상, 편의 기능
- v2: 장기 로드맵. 고급 기능, 최적화

각 스토리 번호와 함께 "1:S/MVP, 2:M/v1.1" 형태로 입력하세요.
스토리 추가/삭제/수정도 가능합니다.`,
      options: []  // 자유 입력
    }
  ])
}
```

### 4-4. Walking Skeleton 최종 검증

```typescript
// 사용자 결정 반영 후 Walking Skeleton 재검증
const skeleton_check = activities.every(activity => {
  const mvp_stories = activity.stories.filter(s => s.release === 'MVP')
  return mvp_stories.length >= 1
})

if (!skeleton_check) {
  AskUserQuestion([
    {
      question: "Walking Skeleton이 완성되지 않았습니다.",
      header: "⚠️ Walking Skeleton 경고",
      description: `아래 Activity에 MVP 스토리가 없습니다:
${missing_activities.map(a => `- ${a.name}`).join('\n')}

이 상태로 MVP를 출시하면 사용자가 전체 흐름을 경험할 수 없습니다.

1. 해당 Activity에 MVP 스토리 추가
2. 의도적으로 제외 (사유 기록)`,
      options: [
        { label: "스토리 추가", description: "빠진 Activity에 MVP 스토리 추가" },
        { label: "의도적 제외", description: "사유를 기록하고 진행" }
      ]
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
- 추정 합계: S x{n} + M x{n} + L x{n}

## Walking Skeleton (MVP)
> 전체 Activity를 관통하는 최소 기능 세트

| Activity | MVP 스토리 | 추정 |
|----------|-----------|------|
| {활동1} | {핵심 스토리} | S |
| {활동2} | {핵심 스토리} | M |
| ... | ... | ... |

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

## 워크숍 결정 기록
- Activity 검토: {사용자 피드백 요약}
- Task 검토: {사용자 피드백 요약}
- 릴리스 분류: {사용자 결정 사항}

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
스토리 맵 완료!

문서: plans/story-map-{feature}.md
페르소나: {persona}
목표: {goal}

구조:
- Activities: {n}개
- Tasks: {n}개
- Stories: {n}개

Walking Skeleton (MVP): {n}개 스토리 — 전체 Activity 커버 여부: {예/아니오}

릴리스 배분:
- MVP: {n}개 (S x{n}, M x{n}, L x{n})
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
- **감정**: 긍정/중립/부정
- **Pain Point**: {불편}
- **Opportunity**: {개선 기회}

### Stage 2: ...

## Emotion Curve
(각 Stage의 감정 변화 시각화)

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

// 3. Walking Skeleton 재검증 후 릴리스 라인 재조정
// Phase 4-3과 동일한 워크숍 방식으로 사용자와 함께 결정
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
⚠️ 스토리 "{story}"의 추정이 L입니다.
L 스토리는 더 작은 스토리로 분할하는 것을 권장합니다.

분할하시겠습니까?
- 분할: ux-researcher가 하위 스토리 제안
- 유지: L 그대로 유지
```

### Walking Skeleton 미완성

```
⚠️ MVP에 모든 Activity가 포함되지 않았습니다.
아래 Activity에 MVP 스토리가 없습니다:
- {activity_name}

전체 사용자 흐름이 끊길 수 있습니다. 계속하시겠습니까?
```

### 기존 스토리 맵 없음 (`--prioritize`)

```
기존 스토리 맵 파일이 없습니다 (plans/story-map-*.md).
/story-map <feature>로 먼저 스토리 맵을 생성하세요.
```

---

## 주의사항

### 금지사항
- 사용자 스토리를 개발 태스크로 작성하지 않음 (기술 용어 배제)
- 추정/릴리스 라인을 자동 결정하지 않음 (반드시 사용자 확인)
- Activity를 7개 이상 생성하지 않음 (3-5개 유지)
- 한 번에 모든 스토리를 물어보지 않음 (Activity 단위로 나눠서)
- MVP를 특정 Activity에만 집중하지 않음 (Walking Skeleton 원칙)

### 권장사항
- PRD가 있으면 반드시 참조하여 정합성 유지
- "As a... I want to... so that..." 형식 엄수
- MVP는 Walking Skeleton — 전체 Activity를 최소한으로 커버
- L 추정 스토리는 분할 권장
- 의존성 관계 명시 (어떤 스토리가 선행되어야 하는지)
- 매 Phase 주요 결과물마다 사용자에게 확인받기
- 워크숍 결정 기록을 문서에 남기기

---

## Examples

### 예시 1: 기능별 스토리 맵
```
/story-map 상품-검색
```
→ PRD 탐색 → 페르소나/목표 수집 → Activity 도출 + 사용자 확인 → Task 분해 + 사용자 확인 → Story 생성 + 릴리스 워크숍 → Walking Skeleton 검증 → plans/story-map-상품-검색.md 저장

### 예시 2: 사용자 여정 맵
```
/story-map --journey 신규-사용자
```
→ 서비스 전체 여정 매핑 → 감정 곡선 → Pain Point/Opportunity → plans/journey-map-신규-사용자.md 저장

### 예시 3: 우선순위 재조정
```
/story-map --prioritize
```
→ 기존 스토리 맵 읽기 → Walking Skeleton 재검증 → 릴리스 라인 워크숍 → 파일 업데이트
