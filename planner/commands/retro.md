---
description: 스프린트/프로젝트 회고 진행. Jira 데이터 기반 구조화된 회고 + 액션 아이템 추적.
---

# Retro — 스프린트/프로젝트 회고

## Usage

```
/retro                              → 최근 종료 스프린트 회고
/retro --format 4L                  → 포맷 지정 (Phase 2 스킵)
/retro --format starfish            → Starfish 포맷
/retro --format sailboat            → Sailboat 포맷
/retro --project <name>             → 프로젝트 회고 (스프린트 데이터 없음)
```

## 용도

**스프린트/프로젝트 회고 진행**
- Jira 데이터 기반 스프린트 분석
- 구조화된 회고 포맷 (4L / Starfish / Sailboat)
- 이전 회고 액션 아이템 추적
- 팀 회고 문서 자동 생성

---

## Phase 1: 데이터 수집

### 1-1. Jira 스프린트 데이터 조회

```typescript
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
// --project 모드면 이 단계 스킵 → Phase 1-3으로 직행

// 최근 종료 스프린트의 이슈 조회
const completed_issues = mcp__jira__jira_search({
  jql: "project = PROJ AND sprint in closedSprints() AND status = Done ORDER BY updated DESC",
  limit: 50
})

const carryover_issues = mcp__jira__jira_search({
  jql: "project = PROJ AND sprint in closedSprints() AND status != Done ORDER BY updated DESC",
  limit: 50
})

// 스프린트 중간 추가된 이슈 (created가 스프린트 시작일 이후)
const added_midSprint = mcp__jira__jira_search({
  jql: "project = PROJ AND sprint in closedSprints() AND created >= '{sprint_start_date}' ORDER BY created DESC",
  limit: 30
})
```

**예외 처리:**
```
Jira 연결 실패 시:
→ "Jira에 접근할 수 없습니다. 수동으로 스프린트 데이터를 입력하시겠습니까?"
→ AskUserQuestion: [수동 입력 / Jira 없이 진행 / 취소]
```

### 1-2. 스프린트 통계 집계

```
📊 스프린트 요약

스프린트: Sprint {N} ({start_date} ~ {end_date})
완료:     {completed_count}건 ({completed_sp} SP)
캐리오버: {carryover_count}건 ({carryover_sp} SP)
중간 추가: {added_count}건
완료율:   {completion_rate}%

커밋된 SP: {committed_sp}
완료된 SP: {completed_sp}
달성률:   {sp_rate}%
```

### 1-3. 이전 회고 액션 아이템 확인

```typescript
// 이전 회고 파일 검색
const prev_retro = Glob("plans/retro-sprint-*.md")
// 가장 최근 파일 읽기
if (prev_retro.length > 0) {
  const content = Read(prev_retro[prev_retro.length - 1])
  // Action Items 섹션 추출
}
```

**이전 액션 아이템 출력:**
```
📋 이전 회고 액션 아이템 (Sprint {N-1})

| # | 항목 | 담당 | 기한 | 상태 |
|---|------|------|------|------|
| 1 | 코드 리뷰 시간 단축 | 김OO | 03/07 | ❓ 확인 필요 |
| 2 | E2E 테스트 추가 | 이OO | 03/14 | ❓ 확인 필요 |

→ Phase 4에서 각 항목의 완료 여부를 확인합니다.
```

**이전 회고 없을 때:**
```
이전 회고 파일이 없습니다. 첫 회고로 진행합니다.
```

---

## Phase 2: 포맷 선택

> `--format` 플래그가 있으면 이 Phase를 건너뛰고, 지정된 포맷으로 Phase 3 진행.

```typescript
AskUserQuestion([
  {
    question: "회고 포맷을 선택하세요",
    header: "회고 포맷",
    options: [
      {
        label: "4L (기본)",
        description: "Liked / Learned / Lacked / Longed For — 가장 범용적"
      },
      {
        label: "Starfish",
        description: "Keep / More / Less / Stop / Start — 행동 변화 중심"
      },
      {
        label: "Sailboat",
        description: "Wind / Anchor / Rocks / Island — 비유적 접근, 팀 빌딩에 적합"
      }
    ]
  }
])
```

---

## Phase 3: 회고 진행 (Interactive Q&A)

선택된 포맷에 따라 각 카테고리를 **하나씩** AskUserQuestion으로 질문합니다.
Jira 데이터를 대화 촉매로 활용합니다.

### 3-1. 포맷별 질문

#### 4L 포맷

```typescript
// 1. Liked
AskUserQuestion([
  {
    question: "이번 스프린트에서 좋았던 것은?",
    header: "😊 Liked",
    description: `참고: 이번 스프린트에서 ${completed_count}건을 완료했습니다.
특히 ${top_completed_issues}가 완료됐습니다.
잘 된 프로세스, 협업, 기술적 성과 등을 자유롭게 입력하세요.
(여러 항목은 줄바꿈으로 구분)`,
    options: []  // 자유 입력
  }
])

// 2. Learned
AskUserQuestion([
  {
    question: "이번 스프린트에서 배운 것은?",
    header: "📚 Learned",
    description: "새로 알게 된 기술, 프로세스 개선점, 팀 다이나믹 인사이트 등",
    options: []
  }
])

// 3. Lacked
AskUserQuestion([
  {
    question: "이번 스프린트에서 부족했던 것은?",
    header: "😤 Lacked",
    description: `참고: 캐리오버된 이슈가 ${carryover_count}건 있습니다.
${carryover_issues_list}
이 캐리오버의 원인이나, 부족했던 자원/시간/역량 등을 입력하세요.`,
    options: []
  }
])

// 4. Longed For
AskUserQuestion([
  {
    question: "다음 스프린트에서 바라는 것은?",
    header: "🙏 Longed For",
    description: "새로운 도구, 프로세스 변경, 팀 구조 개선 등 바라는 것",
    options: []
  }
])
```

#### Starfish 포맷

```typescript
// 순서대로 하나씩 질문
// 1. Keep Doing — "지금 잘 하고 있어서 계속할 것"
// 2. More Of — "더 많이 할 것"
// 3. Less Of — "줄일 것"
// 4. Stop Doing — "멈출 것"
// 5. Start Doing — "새로 시작할 것"

// 예시: 캐리오버 이슈가 있으면
// "PROJ-123(결제 리팩토링)이 캐리오버됐는데, 추정이 잘못됐을까요? 아니면 다른 이유가 있나요?"
// → Less Of 또는 Stop Doing에 대한 힌트 제공
```

#### Sailboat 포맷

```typescript
// 1. Wind (추진력) — "우리를 앞으로 나아가게 한 것"
// 2. Anchor (장애물) — "우리를 붙잡고 있는 것"
// 3. Rocks (리스크) — "앞에 놓인 위험/장애물"
// 4. Island (목표) — "우리가 향하는 목적지"
```

### 3-2. Jira 기반 대화 촉매

각 질문 시 관련 Jira 데이터를 context로 제공합니다:

```
캐리오버 이슈 언급:
→ "PROJ-123(결제 API 리팩토링)이 캐리오버됐습니다. 원인이 무엇이었을까요?"

중간 추가 이슈 언급:
→ "PROJ-456(긴급 버그 수정)이 스프린트 중간에 추가됐습니다. 계획에 영향을 줬나요?"

완료율 낮을 때:
→ "이번 스프린트 완료율이 {rate}%입니다. 추정이 과했을까요, 예상치 못한 업무가 있었을까요?"
```

### 3-3. 프로젝트 회고 모드 (`--project`)

> 스프린트 데이터 대신 프로젝트 전반을 회고합니다.

```typescript
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
const project_issues = mcp__jira__jira_search({
  jql: "project = PROJ AND type = Epic ORDER BY created ASC",
  limit: 50
})

// 프로젝트 관련 문서 탐색
const project_docs = Glob("plans/*{project_name}*.md")
```

질문 범위가 스프린트 → 프로젝트로 확장:
- "프로젝트 전체에서 가장 잘 된 것은?"
- "프로젝트 진행 중 가장 큰 병목은?"
- "다음 프로젝트에서 반드시 개선할 것은?"

---

## Phase 4: 액션 아이템

### 4-1. 이전 액션 아이템 리뷰

```typescript
// 이전 회고 액션 아이템이 있으면 하나씩 확인
if (prev_action_items.length > 0) {
  for (const item of prev_action_items) {
    AskUserQuestion([
      {
        question: `이전 액션 아이템: "${item.title}" (담당: ${item.assignee}) — 완료됐나요?`,
        header: "이전 액션 아이템 확인",
        options: [
          { label: "완료", description: "성공적으로 이행됨" },
          { label: "진행 중", description: "아직 진행 중, 이번 스프린트에서 계속" },
          { label: "미완료", description: "시작하지 못함" },
          { label: "폐기", description: "더 이상 유효하지 않음" }
        ]
      }
    ])
  }
}
```

### 4-2. 새 액션 아이템 수집

```typescript
AskUserQuestion([
  {
    question: "이번 회고에서 도출된 액션 아이템을 입력하세요.",
    header: "새 액션 아이템",
    description: `회고 내용을 바탕으로 구체적인 액션을 정해주세요.
각 항목은 아래 형식으로 입력:
  항목 | 담당자 | 기한
  예: 코드 리뷰 가이드 작성 | 김OO | 03/21

여러 항목은 줄바꿈으로 구분합니다.`,
    options: []  // 자유 입력
  }
])
```

**액션 아이템 원칙:**
- 구체적이고 측정 가능해야 함
- 반드시 담당자와 기한 포함
- 한 스프린트 안에 완료 가능한 크기

---

## Phase 5: 문서 작성 및 저장

### 5-1. content-writer 에이전트로 문서 작성

```typescript
const retro_doc = Agent("content-writer", `다음 회고 데이터를 문서로 작성해줘.

스프린트 정보:
- 스프린트: {sprint_name}
- 기간: {start_date} ~ {end_date}
- 완료: {completed_count}건 ({completed_sp} SP)
- 캐리오버: {carryover_count}건 ({carryover_sp} SP)
- 완료율: {completion_rate}%

회고 포맷: {format_name}
회고 내용:
{collected_responses}

이전 액션 아이템 상태:
{prev_action_items_review}

새 액션 아이템:
{new_action_items}

아래 형식으로 작성해줘:

# 회고 — {sprint_name}

## 메타 정보
- **날짜**: {date}
- **포맷**: {format_name}
- **참여자**: {participants}
- **상태**: Final

## 스프린트 요약
(통계 표)

## 회고 내용
(포맷별 섹션)

## 이전 액션 아이템 리뷰
| # | 항목 | 담당 | 상태 |
(이전 항목 결과)

## 새 액션 아이템
| # | 항목 | 담당 | 기한 |
(새 액션 아이템)

## 참고 데이터
- 완료 이슈 목록
- 캐리오버 이슈 목록

파일 경로: plans/retro-sprint-{n}.md`)
```

### 5-2. 저장

```typescript
Bash("mkdir -p plans")
// content-writer가 Write 도구로 직접 저장
// plans/retro-sprint-{n}.md

// 프로젝트 회고인 경우:
// plans/retro-project-{name}.md
```

### 5-3. 완료 메시지

```
✅ 회고 완료!

📄 문서: plans/retro-sprint-{n}.md
📊 포맷: {format_name}

스프린트 요약:
- 완료율: {completion_rate}%
- SP 달성률: {sp_rate}%
- 캐리오버: {carryover_count}건

새 액션 아이템: {new_action_items_count}건
이전 액션 아이템: 완료 {done}/{total}건
```

---

## 예외 처리

### Jira 접근 불가

```
Jira에 접근할 수 없습니다.

선택하세요:
1. 수동 입력 — 스프린트 데이터를 직접 입력
2. 데이터 없이 진행 — 통계 없이 회고만 진행
3. 취소

→ "수동 입력" 선택 시:
  AskUserQuestion: "완료 이슈 수, 캐리오버 이슈 수, SP 정보를 입력하세요"
```

### 이전 회고 파일 없음

```
이전 회고 파일이 없습니다 (plans/retro-sprint-*.md).
첫 회고로 진행합니다. 이전 액션 아이템 리뷰를 건너뜁니다.
```

### 스프린트 데이터 없음

```
종료된 스프린트를 찾을 수 없습니다.
→ AskUserQuestion: [스프린트 이름 직접 입력 / 프로젝트 회고로 전환 / 취소]
```

---

## 주의사항

### 금지사항
- ❌ 회고 내용을 임의로 판단하거나 평가하지 않음
- ❌ 사용자 응답을 수정/보완하지 않음 (원문 그대로 기록)
- ❌ 액션 아이템을 자동 생성하지 않음 (사용자가 직접 결정)
- ❌ 팀원 개인을 비난하는 내용 기록 금지

### 권장사항
- ✅ Jira 데이터를 대화 촉매로 활용 (답을 유도하지 않고, 떠올리게 함)
- ✅ 각 카테고리를 하나씩 질문 (한 번에 전부 물어보지 않음)
- ✅ 이전 액션 아이템 반드시 리뷰
- ✅ 액션 아이템은 구체적 + 담당자 + 기한 필수

---

## Examples

### 예시 1: 기본 회고
```
/retro
```
→ Jira에서 최근 종료 스프린트 조회 → 통계 출력 → 4L 포맷 선택 → 카테고리별 Q&A → 액션 아이템 → 저장

### 예시 2: 포맷 지정
```
/retro --format starfish
```
→ Jira 데이터 수집 → Starfish 포맷으로 바로 진행 (Phase 2 스킵) → Keep/More/Less/Stop/Start 질문

### 예시 3: 프로젝트 회고
```
/retro --project 결제-리뉴얼
```
→ 스프린트 데이터 대신 프로젝트 전체 Epic/이슈 조회 → 프로젝트 범위 회고 → plans/retro-project-결제-리뉴얼.md 저장

### 예시 4: 캐리오버 많은 스프린트
```
/retro
```
→ 캐리오버 5건 감지 → "PROJ-123(결제 API)이 캐리오버됐는데, 추정이 과했을까요?" 형태로 대화 유도
