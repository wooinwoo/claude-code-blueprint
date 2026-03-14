---
description: 스프린트 계획 수립/점검. Jira 백로그 기반 이슈 선정, 캐퍼시티 관리, 번다운 추적.
---

# Sprint Plan — 스프린트 계획 워크플로

## Usage

```
/sprint-plan                      → 다음 스프린트 계획 수립
/sprint-plan --current            → 현재 스프린트 상태 점검
/sprint-plan --capacity 40        → 캐퍼시티 40SP 기준 계획
```

## 용도

**Jira 백로그 기반 스프린트 계획 수립 및 진행 점검**
- 백로그 우선순위 정렬 + 캐리오버 확인
- 캐퍼시티 기반 이슈 선정
- 스프린트 목표 생성
- 번다운/리스크 추적 (`--current`)

---

## 기본 동작: 다음 스프린트 계획

### Phase 1: 백로그 조회

#### 1-1. Jira 백로그 이슈 조회

```typescript
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)

// 스프린트에 배정되지 않은 To Do 이슈
backlog = mcp__jira__jira_search({
  jql: "project = PROJ AND sprint is EMPTY AND status = 'To Do' ORDER BY priority DESC, rank ASC"
})

if (backlog.total === 0) {
  console.log(`
  ⚠️  백로그에 이슈가 없습니다.

  확인 사항:
  1. Jira 프로젝트 키(PROJ)가 맞는지 확인
  2. 백로그에 'To Do' 상태 이슈가 있는지 확인
  3. /jira 로 이슈를 먼저 생성하세요
  `)
  return
}

console.log(`
백로그 이슈: ${backlog.total}건

| 우선순위 | 이슈 | 제목 | SP | 타입 |
|---------|------|------|----|------|
${backlog.issues.map(i =>
  `| ${i.priority} | ${i.key} | ${i.summary} | ${i.story_points || '-'} | ${i.type} |`
).join('\n')}
`)
```

**Jira 불가 시:**

```typescript
if (jira_unavailable) {
  console.log(`
  ⚠️  Jira MCP 연결 실패.

  확인: .claude/.env 의 JIRA_TOKEN, JIRA_URL, JIRA_USERNAME

  대안:
  1. 이슈 목록을 직접 입력 (이슈키, 제목, SP, 우선순위)
  2. plans/ 내 기존 백로그 문서 참조
  `)

  AskUserQuestion({
    question: "이슈 목록을 어떻게 제공하시겠습니까?",
    header: "백로그 소스",
    options: [
      { label: "직접 입력", description: "이슈 목록 텍스트 입력" },
      { label: "파일 참조", description: "plans/ 내 백로그 파일 지정" }
    ]
  })
}
```

#### 1-2. OKR 연결 확인

```typescript
// 현재 분기 OKR이 있으면 연결 정보 확인
okr_files = Glob("plans/okr-*.md")

if (okr_files.length > 0) {
  current_okr = Read(okr_files[0])
  // 백로그 이슈의 라벨에서 OKR 연결 추출
  for (const issue of backlog.issues) {
    okr_link = issue.labels?.find(l => l.startsWith("okr-"))
    if (okr_link) {
      issue.okr_connection = okr_link  // e.g. "okr-o1-kr2"
    }
  }
}
```

### Phase 2: 캐리오버 확인

```typescript
// 현재 스프린트에서 미완료 이슈 조회
carryover = mcp__jira__jira_search({
  jql: "project = PROJ AND sprint in openSprints() AND status != 'Done' ORDER BY priority DESC"
})

if (carryover.total > 0) {
  console.log(`
  ⚠️  캐리오버 이슈: ${carryover.total}건 (${sum_sp(carryover)} SP)

  | 이슈 | 제목 | SP | 상태 | 이유 |
  |------|------|----|------|------|
  ${carryover.issues.map(i =>
    `| ${i.key} | ${i.summary} | ${i.story_points || '-'} | ${i.status} | - |`
  ).join('\n')}

  → 캐리오버 이슈는 자동으로 다음 스프린트에 포함됩니다.
  `)
}
```

### Phase 3: 캐퍼시티 확인

```typescript
if (args.capacity) {
  // --capacity 플래그로 직접 지정
  capacity = parseInt(args.capacity)
} else {
  AskUserQuestion({
    question: "다음 스프린트 정보를 입력해주세요.",
    header: "스프린트 설정",
    options: [
      {
        label: "팀 캐퍼시티 (SP)",
        description: "이번 스프린트에 소화 가능한 총 스토리 포인트"
      },
      {
        label: "스프린트 기간",
        description: "시작일 ~ 종료일 (기본: 2주)"
      }
    ]
  })
}

// 캐리오버 SP 차감
available_capacity = capacity - sum_sp(carryover)

console.log(`
캐퍼시티: ${capacity} SP
캐리오버: ${sum_sp(carryover)} SP
가용 캐퍼시티: ${available_capacity} SP
`)

if (available_capacity <= 0) {
  console.log(`
  ⚠️  캐리오버(${sum_sp(carryover)} SP)가 캐퍼시티(${capacity} SP)를 초과합니다.
  → 캐리오버 이슈를 줄이거나 캐퍼시티를 재조정하세요.
  `)
}
```

### Phase 4: 이슈 선정

#### 4-1. 우선순위 정렬

```typescript
// RICE 스코어 기반 정렬 (Jira 필드에 RICE가 없으면 priority 사용)
sorted_backlog = backlog.issues.sort((a, b) => {
  // 1차: Jira priority (Highest > High > Medium > Low > Lowest)
  // 2차: OKR 연결 여부 (연결된 이슈 우선)
  // 3차: Jira rank
  return compare_priority(a, b)
})
```

#### 4-2. 캐퍼시티 기반 선정

```typescript
selected = []
remaining_capacity = available_capacity

for (const issue of sorted_backlog) {
  sp = issue.story_points || 0

  // SP 미추정 이슈 경고
  if (sp === 0) {
    unestimated.push(issue)
    continue
  }

  if (sp <= remaining_capacity) {
    selected.push(issue)
    remaining_capacity -= sp
  }
}

// SP 미추정 이슈 처리
if (unestimated.length > 0) {
  console.log(`
  ⚠️  SP 미추정 이슈 ${unestimated.length}건:
  ${unestimated.map(i => `  - ${i.key}: ${i.summary}`).join('\n')}

  → 이 이슈들은 SP 추정 후 포함을 검토하세요.
  `)
}

console.log(`
선정 결과: ${selected.length}건 / ${capacity - remaining_capacity} SP

| 순위 | 이슈 | 제목 | SP | 우선순위 | OKR |
|------|------|------|----|---------|-----|
${selected.map((i, idx) =>
  `| ${idx + 1} | ${i.key} | ${i.summary} | ${i.story_points} | ${i.priority} | ${i.okr_connection || '-'} |`
).join('\n')}

여유: ${remaining_capacity} SP
`)
```

#### 4-3. 사용자 확인

```typescript
AskUserQuestion({
  question: "선정된 이슈 목록을 확인해주세요.",
  header: "이슈 확인",
  options: [
    {
      label: "승인",
      description: "이대로 진행"
    },
    {
      label: "이슈 추가",
      description: "추가할 이슈키 입력"
    },
    {
      label: "이슈 제거",
      description: "제거할 이슈키 입력"
    },
    {
      label: "재정렬",
      description: "다른 기준으로 정렬"
    }
  ]
})
```

### Phase 5: 스프린트 목표 생성

```typescript
sprint_goal = Agent("product-strategist", `
다음 스프린트에 포함된 이슈를 분석하여 스프린트 목표를 생성해줘.

선정 이슈:
${selected.map(i => `- ${i.key}: ${i.summary} (${i.type}, ${i.priority})`).join('\n')}

캐리오버:
${carryover.issues.map(i => `- ${i.key}: ${i.summary} (${i.status})`).join('\n')}

OKR 연결 (있으면):
${okr_connections}

스프린트 목표 작성 규칙:
1. 1-2문장으로 핵심 가치 전달
2. 비즈니스 관점에서 작성 (기술 용어 최소화)
3. 달성 여부를 판단할 수 있는 구체적 표현
4. OKR과의 연결점 명시 (해당 시)

반드시 아래 형식으로 응답해줘:

## 스프린트 목표
{1-2문장 목표}

## 핵심 딜리버리
1. {딜리버리 1}: {관련 이슈 키 목록}
2. {딜리버리 2}: {관련 이슈 키 목록}

## OKR 기여
- {어떤 KR에 기여하는지}
`)
```

### Phase 6: 저장

#### 6-1. 스프린트 번호 결정

```typescript
// 기존 스프린트 계획 파일에서 번호 추출
existing_plans = Glob("plans/sprint-*-plan.md")
if (existing_plans.length > 0) {
  last_number = extract_sprint_number(existing_plans[0])
  sprint_number = last_number + 1
} else {
  sprint_number = 1
}
```

#### 6-2. content-writer 에이전트 문서 작성

```typescript
Bash("mkdir -p plans")

Agent("content-writer", `
스프린트 계획 문서를 작성하고 저장해줘.

파일 경로: plans/sprint-${sprint_number}-plan.md

아래 형식으로 Write 도구를 사용해 저장:

---

# Sprint ${sprint_number} Plan — ${start_date} ~ ${end_date}

- 작성일: ${current_date}
- 상태: PLANNED

## 스프린트 목표
${sprint_goal}

## 핵심 딜리버리
${key_deliveries}

## 선정 이슈
| 순위 | 이슈 | 제목 | SP | 우선순위 | 담당 | OKR |
|------|------|------|----|---------|------|-----|
${selected_issues_table}

## 캐리오버
| 이슈 | 제목 | SP | 이전 상태 |
|------|------|----|----------|
${carryover_table}

## 캐퍼시티
- 총 캐퍼시티: ${capacity} SP
- 신규 이슈: ${new_sp} SP
- 캐리오버: ${carryover_sp} SP
- 여유: ${remaining_capacity} SP
- 활용률: ${utilization}%

## OKR 연결
${okr_mapping}

## 리스크
${identified_risks}

## 수동 테스트 체크리스트
- [ ] {주요 기능 확인 항목}

---
`)
```

#### 6-3. Jira 스프린트 생성 (선택)

```typescript
AskUserQuestion({
  question: "Jira에 스프린트를 생성할까요?",
  header: "Jira 스프린트",
  options: [
    {
      label: "생성",
      description: "Jira 보드에 스프린트 생성 + 이슈 이동"
    },
    {
      label: "스킵",
      description: "문서만 저장 (수동으로 Jira 관리)"
    }
  ]
})

// "생성" 선택 시
if (create_jira_sprint) {
  // 참고: mcp-atlassian에서 스프린트 생성 API가 제공되는 경우
  // 이슈를 스프린트로 이동
  for (const issue of [...selected, ...carryover.issues]) {
    mcp__jira__jira_update_issue({
      issue_key: issue.key,
      fields: { sprint: { id: new_sprint_id } }
    })
  }
}
```

#### 6-4. 완료 메시지

```
스프린트 계획 완료!

파일: plans/sprint-${sprint_number}-plan.md
기간: ${start_date} ~ ${end_date}
이슈: ${selected.length + carryover.total}건 (${total_sp} SP)
여유: ${remaining_capacity} SP

스프린트 목표:
${sprint_goal}

다음 단계:
- /sprint-plan --current 로 진행 상황 점검
- /okr review 로 OKR 진척 확인
```

---

## `--current`: 현재 스프린트 점검

### Phase 1: 현재 스프린트 이슈 조회

```typescript
// 현재 활성 스프린트의 모든 이슈
current_sprint = mcp__jira__jira_search({
  jql: "project = PROJ AND sprint in openSprints() ORDER BY status DESC, priority DESC"
})

if (current_sprint.total === 0) {
  console.log("활성 스프린트가 없습니다.")
  return
}
```

### Phase 2: 번다운 계산

```typescript
// 상태별 집계
done_issues = current_sprint.issues.filter(i => i.status === "Done")
in_progress = current_sprint.issues.filter(i => i.status === "In Progress")
todo_issues = current_sprint.issues.filter(i => i.status === "To Do")

done_sp = sum_sp(done_issues)
in_progress_sp = sum_sp(in_progress)
todo_sp = sum_sp(todo_issues)
total_sp = done_sp + in_progress_sp + todo_sp

// 기간 계산
sprint_plan = Glob("plans/sprint-*-plan.md")
if (sprint_plan.length > 0) {
  plan = Read(sprint_plan[0])
  start_date = extract_start_date(plan)
  end_date = extract_end_date(plan)
}

total_days = diff_days(start_date, end_date)
elapsed_days = diff_days(start_date, current_date)
remaining_days = total_days - elapsed_days

// 예상 완료율 vs 실제 완료율
expected_progress = elapsed_days / total_days
actual_progress = done_sp / total_sp

// 번다운 건강도
if (actual_progress >= expected_progress * 0.9) {
  burndown_status = "HEALTHY"
} else if (actual_progress >= expected_progress * 0.6) {
  burndown_status = "WARNING"
} else {
  burndown_status = "CRITICAL"
}
```

### Phase 3: 리스크 항목 식별

```typescript
at_risk_items = []

for (const issue of current_sprint.issues) {
  // In Progress인데 오래된 이슈
  if (issue.status === "In Progress") {
    days_in_progress = diff_days(issue.status_changed_at, current_date)
    if (days_in_progress > 3) {
      at_risk_items.push({
        issue: issue,
        reason: `In Progress ${days_in_progress}일 경과`,
        severity: days_in_progress > 5 ? "HIGH" : "MEDIUM"
      })
    }
  }

  // To Do인데 스프린트 후반
  if (issue.status === "To Do" && remaining_days < total_days * 0.3) {
    at_risk_items.push({
      issue: issue,
      reason: `잔여 ${remaining_days}일인데 미착수`,
      severity: "HIGH"
    })
  }

  // 높은 SP인데 미완료
  if (issue.story_points >= 5 && issue.status !== "Done" && remaining_days < total_days * 0.5) {
    at_risk_items.push({
      issue: issue,
      reason: `${issue.story_points}SP 대형 이슈 미완료`,
      severity: "MEDIUM"
    })
  }
}
```

### Phase 4: 상태 보고

```
## 스프린트 ${sprint_number} 현황

점검일: ${current_date}
기간: ${start_date} ~ ${end_date} (잔여 ${remaining_days}일)

### 번다운
- 총 SP: ${total_sp}
- 완료: ${done_sp} SP (${Math.round(actual_progress * 100)}%)
- 진행 중: ${in_progress_sp} SP
- 미착수: ${todo_sp} SP
- 기대 진척: ${Math.round(expected_progress * 100)}%
- 상태: ${burndown_status === "HEALTHY" ? "🟢 정상" : burndown_status === "WARNING" ? "🟡 주의" : "🔴 위험"}

### 이슈 현황
| 상태 | 이슈 | 제목 | SP | 담당 |
|------|------|------|----|------|
| ✅ Done | ${done_issues_table} |
| 🔄 In Progress | ${in_progress_table} |
| ⬜ To Do | ${todo_table} |

### 리스크 항목
| 심각도 | 이슈 | 이유 | 권장 조치 |
|--------|------|------|----------|
${at_risk_items.map(r =>
  `| ${r.severity === "HIGH" ? "🔴" : "🟡"} ${r.severity} | ${r.issue.key} | ${r.reason} | ${suggest_action(r)} |`
).join('\n')}

### 권장 조치
${at_risk_items.length > 0 ? `
1. ${specific_actions}
2. 블로커 확인: ${blocked_issues}
3. 스코프 조정 검토: ${scope_candidates}
` : "리스크 항목 없음. 정상 진행 중."}

상태 범례: 🟢 정상 (실제 >= 기대 90%) | 🟡 주의 (60-90%) | 🔴 위험 (<60%)
```

---

## 예외 처리

### Jira 연결 불가

```typescript
if (jira_unavailable) {
  console.log(`
  ⚠️  Jira MCP 연결 실패.

  확인: .claude/.env 의 JIRA_TOKEN, JIRA_URL, JIRA_USERNAME

  대안 (기본 모드):
  - 이슈 목록을 직접 입력하여 계획 수립
  - plans/ 내 기존 문서 기반 계획

  대안 (--current):
  - 기존 스프린트 계획 파일(plans/sprint-*-plan.md)에서 수동 업데이트
  `)
}
```

### 백로그 비어 있음

```typescript
if (backlog.total === 0) {
  console.log(`
  백로그에 이슈가 없습니다.

  다음 단계:
  1. /prd 로 기능 명세 → Jira 이슈 생성
  2. /jira 로 직접 이슈 생성
  3. /okr review 로 미생성 이슈 확인
  `)
}
```

### SP 미추정 이슈 다수

```typescript
if (unestimated.length > backlog.total * 0.5) {
  console.log(`
  ⚠️  백로그의 ${Math.round(unestimated.length / backlog.total * 100)}%가 SP 미추정입니다.

  권장:
  1. 백로그 그루밍 세션에서 SP 추정 후 재실행
  2. 미추정 이슈 제외하고 추정 이슈만으로 계획 (현재 동작)
  `)
}
```

### 캐리오버 과다

```typescript
if (sum_sp(carryover) > capacity * 0.5) {
  console.log(`
  ⚠️  캐리오버(${sum_sp(carryover)} SP)가 캐퍼시티의 50%를 초과합니다.

  권장:
  1. 캐리오버 이슈 중 우선순위 재조정 (일부 백로그로 복귀)
  2. 캐퍼시티 산정 방식 재검토
  3. 이전 스프린트 회고 (/retro) 실행
  `)
}
```

---

## 주의사항

### 금지사항
- ❌ 캐퍼시티 초과 이슈 배정 금지 (여유 SP 0 이하 방지)
- ❌ SP 미추정 이슈 스프린트 포함 금지 (미추정은 별도 표기)
- ❌ Jira 스프린트 강제 시작/종료 금지 (사용자 확인 필수)
- ❌ 캐리오버 이슈 자동 삭제 금지 (반드시 포함 또는 명시적 제거)

### 권장사항
- ✅ 캐퍼시티의 80-90%만 할당 (버퍼 확보)
- ✅ 캐리오버 이슈는 원인 분석 후 포함
- ✅ OKR 연결 이슈 우선 배치
- ✅ `--current`는 스프린트 중간(매주) 실행 권장
- ✅ 스프린트 종료 후 `/retro`와 연계

---

## Examples

### 예시 1: 기본 스프린트 계획
```
/sprint-plan
→ 백로그 조회 → 캐리오버 확인 → 캐퍼시티 질문(40SP) → 이슈 선정 → 목표 생성
→ plans/sprint-5-plan.md
```

### 예시 2: 캐퍼시티 지정
```
/sprint-plan --capacity 30
→ 백로그 조회 → 캐리오버 확인 → 30SP 기준 선정 → 목표 생성
→ plans/sprint-5-plan.md
```

### 예시 3: 현재 스프린트 점검
```
/sprint-plan --current
→ Jira 현재 스프린트 조회 → 번다운 계산 → 리스크 식별
→ 🟡 주의: 실제 35% vs 기대 50%, 리스크 2건
```

### 예시 4: Jira 없이 계획
```
/sprint-plan
→ ⚠️ Jira 연결 실패
→ "직접 입력" 선택
→ 이슈 목록 입력 → 캐퍼시티 기준 선정 → 목표 생성
→ plans/sprint-5-plan.md
```
