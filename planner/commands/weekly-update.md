---
description: 주간 업데이트 보고서 생성. Jira 스프린트 진행률 + 이슈 요약 + 다음 주 계획.
---

# Weekly Update — 주간 보고서 생성

## Usage

```
/weekly-update                    → 이번 주 보고서 생성
/weekly-update --team             → 팀 전체 보고서 (멤버별 진행 현황)
/weekly-update --exec             → 경영진용 요약 (임팩트 중심, 1페이지)
```

## 용도

**PM의 반복 산출물인 주간 보고서를 Jira 데이터 기반으로 자동 생성**
- 이번 주 완료/진행중/블로커 이슈 자동 집계
- 스토리 포인트 기반 지표 계산 (전주 대비 변화율 포함)
- 모드별 최적화된 보고서 포맷 (기본/팀/경영진)

---

## Phase 1: 데이터 수집

### 1-1. Jira 이슈 조회

```typescript
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)

// 이번 주 완료된 이슈
completed = mcp__jira__jira_search({
  jql: "project = PROJ AND status changed to Done DURING (startOfWeek(), now()) ORDER BY updated DESC"
})

// 현재 진행 중인 이슈
in_progress = mcp__jira__jira_search({
  jql: "project = PROJ AND status = 'In Progress' ORDER BY priority DESC"
})

// 블로커 이슈
blocked = mcp__jira__jira_search({
  jql: "project = PROJ AND (status = 'Blocked' OR labels = blocked) ORDER BY priority DESC"
})

// 이번 주 신규 생성된 이슈
created = mcp__jira__jira_search({
  jql: "project = PROJ AND created >= startOfWeek() ORDER BY created DESC"
})

console.log(`
데이터 수집 완료:
- 완료: ${completed.total}건
- 진행 중: ${in_progress.total}건
- 블로커: ${blocked.total}건
- 신규: ${created.total}건
`)
```

### 1-2. Jira 실패 시 수동 입력

```typescript
if (jira_unavailable) {
  console.log(`
  ⚠️  Jira MCP 연결 실패.

  확인: .claude/.env 의 JIRA_TOKEN, JIRA_URL, JIRA_USERNAME

  수동 입력 모드로 전환합니다.
  `)

  AskUserQuestion([
    {
      question: "이번 주 완료된 항목을 알려주세요.",
      header: "완료 항목",
      description: "이슈키, 제목, SP, 담당자 (예: PROJ-123 사용자 인증 v2 8SP 김개발)"
    },
    {
      question: "현재 블로커가 있나요?",
      header: "블로커/리스크",
      description: "블로커 이슈와 영향 범위"
    },
    {
      question: "다음 주 주요 계획은?",
      header: "다음 주 계획",
      description: "우선순위순 주요 작업"
    }
  ])
}
```

### 1-3. 전주 데이터 조회 (변화율 계산용)

```typescript
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
last_week_completed = mcp__jira__jira_search({
  jql: "project = PROJ AND status changed to Done DURING (startOfWeek(-1w), startOfWeek()) ORDER BY updated DESC"
})

last_week_sp = last_week_completed.issues.reduce(
  (sum, i) => sum + (i.story_points || 0), 0
)
```

---

## Phase 2: 지표 계산

```typescript
const metrics = {
  completed_sp: completed.issues.reduce((sum, i) => sum + (i.story_points || 0), 0),
  completed_count: completed.total,
  in_progress_count: in_progress.total,
  blocked_count: blocked.total,
  created_count: created.total,
  last_week_sp: last_week_sp,
  sp_change_rate: last_week_sp > 0
    ? Math.round(((completed_sp - last_week_sp) / last_week_sp) * 100)
    : null
}

// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체
sprint_issues = mcp__jira__jira_search({
  jql: "project = PROJ AND sprint in openSprints()"
})

const sprint_total_sp = sprint_issues.issues.reduce(
  (sum, i) => sum + (i.story_points || 0), 0
)
const sprint_done_sp = sprint_issues.issues
  .filter(i => i.status === "Done")
  .reduce((sum, i) => sum + (i.story_points || 0), 0)

metrics.sprint_progress = sprint_total_sp > 0
  ? Math.round((sprint_done_sp / sprint_total_sp) * 100)
  : 0
```

---

## Phase 3: 보고서 작성

### 3-1. 모드별 분기

```typescript
if (args.exec) {
  // 경영진용: 1페이지 요약, 기술 디테일 제거
  report_mode = "exec"
} else if (args.team) {
  // 팀용: 멤버별 진행 그룹핑
  report_mode = "team"
} else {
  report_mode = "default"
}
```

### 3-2. content-writer 에이전트 호출

```typescript
Bash("mkdir -p plans")

Agent("content-writer", `
주간 업데이트 보고서를 작성하세요.

## 모드: ${report_mode}

## 입력 데이터
### 완료 이슈
${completed.issues.map(i =>
  `- ${i.key}: ${i.summary} (${i.story_points || 0}SP, ${i.assignee})`
).join('\n')}

### 진행 중 이슈
${in_progress.issues.map(i =>
  `- ${i.key}: ${i.summary} (${i.story_points || 0}SP, ${i.assignee}, ${i.status})`
).join('\n')}

### 블로커 이슈
${blocked.issues.map(i =>
  `- ${i.key}: ${i.summary} (영향: ${i.priority}, ${i.assignee})`
).join('\n')}

### 신규 이슈
${created.issues.map(i =>
  `- ${i.key}: ${i.summary} (${i.type}, ${i.priority})`
).join('\n')}

### 지표
- 완료 SP: ${metrics.completed_sp} (전주: ${metrics.last_week_sp}, 변화: ${metrics.sp_change_rate}%)
- 블로커: ${metrics.blocked_count}건
- 스프린트 진행률: ${metrics.sprint_progress}%

## 보고서 형식

${report_mode === "exec" ? `
### 경영진용 (--exec)
1페이지 이내. 기술 용어 제거. 비즈니스 임팩트 중심.

# Weekly Update — ${current_date}

## 이번 주 핵심 (3줄 이내)
- 핵심 성과 1 (비즈니스 임팩트)
- 핵심 성과 2
- 주요 리스크 (있으면)

## 지표
| 항목 | 이번 주 | 전주 | 변화 |
|------|---------|------|------|

## 리스크/대응
| 리스크 | 영향 | 대응 |
|--------|------|------|

## 다음 주 핵심 (3줄 이내)
` : report_mode === "team" ? `
### 팀 보고서 (--team)
멤버별 완료/진행 그룹핑. assignee 기준.

# Weekly Update (Team) — ${current_date}

## 팀 지표 요약
| 항목 | 이번 주 | 전주 | 변화 |
|------|---------|------|------|

## 멤버별 현황
### {멤버명}
| 상태 | 이슈 | 제목 | SP |
|------|------|------|----|
(완료/진행중/블로커 구분)

## 블로커/리스크
## 다음 주 계획
` : `
### 기본 보고서

# Weekly Update — ${current_date}

## 이번 주 핵심
- ✅ 주요 완료 항목 (이슈키)
- 🔄 주요 진행 항목 (진행률)
- 🚫 블로커 (있으면)

## 지표
| 항목 | 이번 주 | 전주 | 변화 |
|------|---------|------|------|
| 완료 SP | | | |
| 블로커 | | | |
| 스프린트 진행률 | | | |

## 완료 항목
| 이슈 | 제목 | SP | 담당 |
|------|------|-----|------|

## 진행 중
| 이슈 | 제목 | SP | 담당 | 진행률 |
|------|------|-----|------|--------|

## 블로커/리스크
| 이슈 | 내용 | 영향 | 대응 |
|------|------|------|------|

## 신규 이슈
| 이슈 | 제목 | 타입 | 우선순위 |
|------|------|------|---------|

## 다음 주 계획
1. 우선순위순 계획 항목 (이슈키)
2. ...
`}

## 작성 규칙
- 모든 이슈에 Jira 키 포함
- 지표 변화에 ⚠️ 표시 (블로커 증가, SP 감소 등)
- "이번 주 핵심"은 비개발자도 이해할 수 있는 수준으로 작성
- 블로커에는 반드시 "대응" 칼럼 포함
- 데이터 없는 섹션도 "해당 없음"으로 명시 (섹션 누락 금지)

## 저장
Write("plans/weekly-update-${current_date}.md", report_content)
`)
```

---

## Phase 4: 저장

```typescript
// Phase 3에서 content-writer가 저장 완료
// 파일 존재 확인
file_exists = Glob(`plans/weekly-update-${current_date}.md`)

if (!file_exists) {
  Bash("mkdir -p plans")
  Write(`plans/weekly-update-${current_date}.md`, report_content)
}

console.log(`
✅ 주간 보고서 생성 완료

파일: plans/weekly-update-${current_date}.md
모드: ${report_mode === "exec" ? "경영진용" : report_mode === "team" ? "팀 보고서" : "기본"}
기간: ${start_of_week} ~ ${current_date}

지표 요약:
- 완료: ${metrics.completed_sp} SP (${metrics.completed_count}건)
- 진행 중: ${metrics.in_progress_count}건
- 블로커: ${metrics.blocked_count}건
- 스프린트 진행률: ${metrics.sprint_progress}%
- 전주 대비: ${metrics.sp_change_rate > 0 ? '+' : ''}${metrics.sp_change_rate}%

다음 단계:
- 팀 공유 또는 이해관계자 전달
- /weekly-update --exec 로 경영진용 요약 별도 생성
- /sprint-plan --current 로 스프린트 상세 점검
`)
```

---

## 예외 처리

### Jira 프로젝트 키 미확인

```typescript
if (!project_key) {
  AskUserQuestion({
    question: "Jira 프로젝트 키를 알려주세요.",
    header: "프로젝트 키",
    description: "예: PROJ, TEAM, BACKEND 등. CLAUDE.md에 명시하면 이후 자동 인식됩니다."
  })
}
```

### 이번 주 데이터 없음

```typescript
if (completed.total === 0 && in_progress.total === 0) {
  console.log(`
  ⚠️  이번 주 완료/진행 이슈가 없습니다.

  확인 사항:
  1. Jira 프로젝트 키(PROJ)가 맞는지 확인
  2. 이슈 상태 전환이 Jira에 반영되었는지 확인
  3. 스프린트가 활성 상태인지 확인
  `)
}
```

### 전주 데이터 없음 (변화율 계산 불가)

```typescript
if (last_week_sp === 0) {
  // 변화율 "N/A"로 표시, 워크플로 중단하지 않음
  metrics.sp_change_rate = null
}
```

---

## 주의사항

### 금지사항
- ❌ Jira에 없는 이슈를 임의로 추가 금지 (데이터 기반 보고서)
- ❌ 블로커의 "대응" 칼럼 비우기 금지 (대응 미정이면 "검토 중" 표시)
- ❌ 전주 대비 악화 지표를 숨기거나 축소 금지
- ❌ `plans/` 외 경로에 저장 금지
- ❌ 경영진용(--exec)에 기술 구현 디테일 포함 금지

### 권장사항
- ✅ 매주 금요일에 실행하여 주간 리듬 확보
- ✅ "이번 주 핵심"은 3줄 이내, 비개발자 대상 작성
- ✅ 블로커에는 담당자 + 예상 해소 시점 포함
- ✅ 다음 주 계획은 우선순위순 정렬
- ✅ `--team` 모드는 1:1 미팅 자료로 활용
- ✅ 기존 보고서(`plans/weekly-update-*.md`)와 트렌드 비교 활용

---

## Examples

### 예시 1: 기본 주간 보고서
```
/weekly-update
→ Jira 조회 → 지표 계산 → 보고서 생성
→ plans/weekly-update-2026-03-14.md
```

### 예시 2: 팀 보고서
```
/weekly-update --team
→ Jira 조회 → 멤버별 그룹핑 → 팀 보고서 생성
→ plans/weekly-update-2026-03-14.md (멤버별 현황 포함)
```

### 예시 3: 경영진용 요약
```
/weekly-update --exec
→ Jira 조회 → 1페이지 요약 생성 (기술 디테일 제거)
→ plans/weekly-update-2026-03-14.md (임팩트 중심)
```

### 예시 4: Jira 연결 실패
```
/weekly-update
→ ⚠️ Jira 연결 실패 → 수동 입력 모드
→ 완료/블로커/계획 입력 → 보고서 생성
→ plans/weekly-update-2026-03-14.md
```
