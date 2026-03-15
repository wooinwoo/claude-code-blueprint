---
description: 프로덕트 로드맵 생성/업데이트/우선순위 조정. OKR 연동, Jira 에픽 동기화, RICE 스코어링.
---

# Roadmap — 로드맵 관리

## Usage

```
/roadmap                          → 현재 로드맵 조회 + Jira 상태 동기화
/roadmap create                   → 새 분기 로드맵 생성
/roadmap update                   → 기존 로드맵 Jira 동기화 업데이트
/roadmap prioritize               → 백로그 RICE 스코어링 + 정렬
```

---

## 기본 모드 (인자 없음): 로드맵 조회

### 현재 로드맵 읽기 + Jira 동기화

```typescript
// 1. 최신 로드맵 파일 찾기
roadmaps = Glob("plans/roadmap-*.md")

if (roadmaps.length === 0) {
  console.log("❌ 로드맵 파일이 없습니다. /roadmap create 로 생성하세요.")
  return
}

// 가장 최신 로드맵 읽기
latest = roadmaps[roadmaps.length - 1]
roadmap_content = Read(latest)

console.log(`📋 현재 로드맵: ${latest}`)

// 2. Jira에서 에픽 상태 동기화
try {
  epics = mcp__jira__jira_search({
    jql: "type = Epic AND status != Done ORDER BY rank ASC",
    fields: "summary,status,priority,customfield_10014"  // story points
  })

  // ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
  // 로드맵의 이니셔티브와 Jira 에픽 상태 매칭
  console.log(`
  📊 Jira 동기화 결과

  | 이니셔티브 | 로드맵 상태 | Jira 상태 | 차이 |
  |-----------|-----------|----------|------|
  | 결제 리팩토링 | In Progress | In Progress | ✅ 일치 |
  | 온보딩 v2 | Planned | To Do | ✅ 일치 |
  | 알림 시스템 | In Progress | Done | ⚠️ 불일치 → 업데이트 필요 |
  `)
} catch (error) {
  console.log("⚠️ Jira 연결 실패. 로드맵 파일만 표시합니다.")
  // 로드맵 내용 그대로 출력
}

// 3. 로드맵 내용 출력 (상태 동기화 반영)
console.log(roadmap_content)
```

---

## `create` 모드: 새 로드맵 생성

### Phase 1: 데이터 수집

```typescript
// 1-1. OKR 조회
okr_files = Glob("plans/okr-*.md")

if (okr_files.length > 0) {
  okr_content = Read(okr_files[okr_files.length - 1])
  console.log(`📋 OKR 로드됨: ${okr_files[okr_files.length - 1]}`)
} else {
  console.log("⚠️ OKR 파일 없음. OKR 없이 진행합니다.")
  console.log("💡 /okr 커맨드로 OKR을 먼저 작성하면 로드맵 품질이 향상됩니다.")
  okr_content = null
}

// 1-2. 기존 PRD 수집
prd_files = Glob("plans/prd-*.md")
prd_summaries = prd_files.map(f => {
  content = Read(f)
  // 각 PRD에서 개요 + 성공 지표 섹션만 추출
  return { file: f, summary: extractSection(content, "1. 개요"), metrics: extractSection(content, "3. 목표") }
})

// 1-3. Jira 에픽/백로그 조회
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
try {
  epics = mcp__jira__jira_search({
    jql: "type = Epic AND status != Done ORDER BY rank ASC",
    fields: "summary,status,priority,labels,description"
  })

  backlog = mcp__jira__jira_search({
    jql: "type = Story AND status = 'To Do' AND sprint is EMPTY ORDER BY priority DESC",
    fields: "summary,priority,story_points,labels"
  })

  console.log(`
  Jira 데이터:
  - 진행 중 에픽: ${epics.length}개
  - 미할당 백로그: ${backlog.length}개
  `)
} catch (error) {
  console.log("⚠️ Jira 연결 실패. 수동 입력으로 전환합니다.")
  epics = []
  backlog = []
}

// 1-4. 분기 확인
AskUserQuestion([
  {
    question: "어떤 분기 로드맵을 생성하시겠어요?",
    header: "대상 분기",
    options: [
      { label: "2026 Q2", description: "4월-6월" },
      { label: "2026 Q3", description: "7월-9월" },
      { label: "2026 Q4", description: "10월-12월" },
      { label: "직접 입력", description: "연도/분기 지정" }
    ]
  },
  {
    question: "로드맵에 추가할 이니셔티브가 있나요? (Jira 외)",
    header: "추가 항목",
    description: "Jira에 없지만 로드맵에 포함할 전략적 이니셔티브"
  }
])

state.quarter = selected_quarter
state.data = { okr: okr_content, prds: prd_summaries, epics, backlog, additional: user_input }
```

### Phase 2: RICE 스코어링

```typescript
// 모든 백로그 아이템에 RICE 적용
// RICE = (Reach × Impact × Confidence) / Effort

items = [...state.data.epics, ...state.data.backlog, ...state.data.additional]

console.log(`
📊 RICE 스코어링 — ${items.length}개 항목

각 항목의 RICE 값을 입력해주세요.
Jira에 값이 있으면 자동 채움, 없으면 질문합니다.
`)

AskUserQuestion([
  {
    question: "각 항목의 RICE 값을 확인/조정해주세요",
    header: "RICE 입력",
    description: `
Reach: 분기당 영향받는 사용자 수
Impact: 0.25(minimal) / 0.5(low) / 1(medium) / 2(high) / 3(massive)
Confidence: 0.5(low) / 0.8(medium) / 1.0(high)
Effort: 인-스프린트 (1 sprint = 1.0)

현재 데이터 기반 추정값:
| 항목 | Reach | Impact | Confidence | Effort | RICE |
|------|-------|--------|------------|--------|------|
| 결제 리팩토링 | 5000 | 2 | 0.8 | 3 | 2667 |
| 온보딩 v2 | 8000 | 2 | 0.8 | 2 | 6400 |
| 알림 시스템 | 3000 | 1 | 0.8 | 1 | 2400 |

수정이 필요한 항목과 값을 알려주세요 (없으면 "확인")
    `
  }
])

// RICE 정렬
scored_items = items.map(item => ({
  ...item,
  rice: (item.reach * item.impact * item.confidence) / item.effort
})).sort((a, b) => b.rice - a.rice)

// 리스크 가중치 적용
adjusted_items = scored_items.map(item => ({
  ...item,
  adjusted_rice: item.rice * (item.risk_factor || 1.0)
}))

console.log(`
📊 RICE 정렬 결과

| 순위 | 항목 | RICE | 리스크 보정 |
|------|------|------|-----------|
| 1 | 온보딩 v2 | 6400 | 6400 |
| 2 | 결제 리팩토링 | 2667 | 2134 (리스크 0.8) |
| 3 | 알림 시스템 | 2400 | 2400 |
`)

state.scored_items = adjusted_items
```

### Phase 3: 전략 에이전트

```typescript
Agent("researcher-strategist", `
  분기 로드맵의 전략적 배치를 결정하세요.

  ## 입력 데이터

  ### OKR (현재 분기)
  ${state.data.okr || "OKR 미설정"}

  ### RICE 정렬된 백로그
  ${JSON.stringify(state.scored_items)}

  ### 기존 PRD
  ${state.data.prds.map(p => p.summary).join("\n")}

  ## 분석 요청
  1. OKR과의 정렬도 분석 — 각 이니셔티브가 어떤 KR에 기여하는지
  2. 의존성 맵 — 이니셔티브 간 선후관계
  3. 리소스 분배 — 분기 내 실행 가능한 범위 (팀 크기 감안)
  4. 추천 배치 — Month 1 / Month 2 / Month 3 배치 제안

  ## 출력 형식
  ### OKR 정렬
  | 이니셔티브 | 관련 OKR | 기여도 |
  |-----------|---------|--------|

  ### 의존성 맵
  이니셔티브A → 이니셔티브C (A 완료 후 C 착수)
  이니셔티브B → (독립)

  ### 추천 배치
  | 시기 | 이니셔티브 | 근거 |
  |------|-----------|------|
  | Month 1 | ... | RICE 최고 + 의존성 없음 |
  | Month 2 | ... | Month 1 결과 의존 |
  | Month 3 | ... | 안정화 + 다음 분기 준비 |

  ### 리스크 및 대안
  | 리스크 | 완화 방안 |
  |--------|----------|
`)

state.strategy = strategist_result
```

### Phase 4: 로드맵 문서 생성

```typescript
Bash("mkdir -p plans")
Agent("content-writer", `
  분기 로드맵 문서를 작성하세요.

  ## 입력 데이터
  분기: ${state.quarter}
  전략 분석: ${state.strategy}
  RICE 스코어: ${JSON.stringify(state.scored_items)}
  OKR: ${state.data.okr || "미설정"}

  ## 로드맵 템플릿

  # Product Roadmap — ${state.quarter}

  - **작성일**: ${today}
  - **상태**: Draft
  - **관련 OKR**: [plans/okr 파일 참조]

  ---

  ## 전략 목표
  1. [OKR 기반 목표 1]
  2. [OKR 기반 목표 2]
  3. [OKR 기반 목표 3]

  ## 분기 로드맵

  ### Month 1 (${month1})
  | 우선순위 | 이니셔티브 | 목표 | 상태 | RICE | 담당 |
  |----------|-----------|------|------|------|------|

  ### Month 2 (${month2})
  | 우선순위 | 이니셔티브 | 목표 | 상태 | RICE | 담당 |
  |----------|-----------|------|------|------|------|

  ### Month 3 (${month3})
  | 우선순위 | 이니셔티브 | 목표 | 상태 | RICE | 담당 |
  |----------|-----------|------|------|------|------|

  ## 의존성 맵
  \`\`\`
  [이니셔티브A] → [이니셔티브C]
  [이니셔티브B] → (독립)
  \`\`\`

  ## RICE 스코어 요약
  | 이니셔티브 | Reach | Impact | Confidence | Effort | RICE | 비고 |
  |-----------|-------|--------|------------|--------|------|------|

  ## 리스크 및 대안
  | 리스크 | 확률 | 영향 | 완화 방안 |
  |--------|------|------|-----------|

  ## Next Steps
  | 항목 | 담당 | 기한 |
  |------|------|------|

  ## 저장 경로
  Write("plans/roadmap-${year}-Q${quarter_num}.md", content)
`)
```

### Phase 5: 저장 및 완료

```typescript
file_path = `plans/roadmap-${year}-Q${quarter_num}.md`

// 파일 존재 확인
file_exists = Glob(file_path)
if (!file_exists) {
  Write(file_path, roadmap_content)
}

// Jira에 에픽 업데이트 (선택)
if (epics.length > 0) {
  AskUserQuestion([
    {
      question: "Jira 에픽에 분기 라벨을 추가할까요?",
      header: "Jira 동기화",
      options: [
        { label: "예", description: `에픽에 "${state.quarter}" 라벨 추가` },
        { label: "아니오", description: "로드맵 파일만 저장" }
      ]
    }
  ])

  if (user_chose_yes) {
    state.scored_items.forEach(item => {
      if (item.jira_key) {
        try {
          mcp__jira__jira_update_issue({
            issue_key: item.jira_key,
            fields: { labels: { add: state.quarter } }
          })
        } catch (error) {
          console.log(`⚠️ Jira ${item.jira_key} 업데이트 실패. 문서는 정상 저장됨.`)
        }
      }
    })
  }
}

console.log(`
✅ 로드맵 생성 완료

파일: ${file_path}
분기: ${state.quarter}
이니셔티브: ${state.scored_items.length}개
OKR 연동: ${okr_content ? "✅" : "❌ (OKR 미설정)"}
Jira 동기화: ${user_chose_yes ? "✅" : "❌"}

다음 단계:
| 항목 | 담당 | 액션 |
|------|------|------|
| 로드맵 리뷰 | 팀 전체 | 리뷰 미팅 일정 잡기 |
| 에픽 생성 | PM | 미할당 이니셔티브 Jira 에픽 생성 |
| 스프린트 계획 | PM | /sprint-plan 으로 상세 계획 |
`)
```

---

## `update` 모드: 기존 로드맵 동기화

```typescript
// 1. 최신 로드맵 읽기
roadmaps = Glob("plans/roadmap-*.md")
latest = roadmaps[roadmaps.length - 1]
roadmap = Read(latest)

// 2. Jira 현재 상태 조회
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
try {
  epics = mcp__jira__jira_search({
    jql: "type = Epic ORDER BY rank ASC",
    fields: "summary,status,priority"
  })
} catch (error) {
  console.log("⚠️ Jira 연결 실패. 수동 업데이트 모드입니다.")
}

// 3. 상태 비교 및 업데이트
// 로드맵 테이블의 '상태' 컬럼을 Jira 현재 상태로 업데이트
epics.forEach(epic => {
  Edit(latest, {
    old_string: `| ... | ${epic.summary} | ... | ${old_status} |`,
    new_string: `| ... | ${epic.summary} | ... | ${epic.status} |`
  })
})

// 4. 변경 사항 요약
console.log(`
✅ 로드맵 업데이트 완료: ${latest}

변경 사항:
| 이니셔티브 | 이전 상태 | 현재 상태 |
|-----------|----------|----------|
| 결제 리팩토링 | In Progress | In Progress (변경 없음) |
| 알림 시스템 | In Progress | Done ✨ |
| 온보딩 v2 | Planned | In Progress ▶️ |
`)
```

---

## `prioritize` 모드: RICE 스코어링 전용

```typescript
// Phase 2만 단독 실행

// 1. 데이터 수집
try {
  backlog = mcp__jira__jira_search({
    jql: "type in (Epic, Story) AND status in ('To Do', 'In Progress') ORDER BY rank ASC",
    fields: "summary,priority,story_points,labels"
  })
} catch (error) {
  console.log("⚠️ Jira 연결 실패.")
  AskUserQuestion([{
    question: "우선순위를 매길 항목을 나열해주세요",
    header: "백로그 항목",
    description: "항목명을 줄바꿈으로 구분하여 입력"
  }])
}

// 2. RICE 입력 + 계산 (Phase 2와 동일)
// ... (위 Phase 2 로직 참조)

// 3. 결과 출력 (파일 저장 안함 — 화면 출력만)
console.log(`
📊 RICE 우선순위 결과

| 순위 | 항목 | Reach | Impact | Confidence | Effort | RICE |
|------|------|-------|--------|------------|--------|------|
| 1 | 온보딩 v2 | 8000 | 2 | 0.8 | 2 | 6400 |
| 2 | 결제 리팩토링 | 5000 | 2 | 0.8 | 3 | 2667 |
| 3 | 알림 시스템 | 3000 | 1 | 0.8 | 1 | 2400 |

💡 로드맵에 반영하려면: /roadmap create 또는 /roadmap update
`)
```

---

## 주의사항

### 금지사항
- ❌ RICE 없이 "감"으로 우선순위 결정 금지
- ❌ OKR과 무관한 이니셔티브를 상위에 배치 금지
- ❌ 의존성 무시하고 순서 배치 금지
- ❌ `plans/` 외 경로에 저장 금지
- ❌ 기존 로드맵 파일 덮어쓰기 금지 (update 모드는 Edit 사용)

### 권장사항
- ✅ OKR을 먼저 작성 (`/okr`) 후 로드맵 생성
- ✅ 리스크 계수를 RICE에 반영 (Adjusted RICE)
- ✅ Jira 에픽과 1:1 매핑 유지
- ✅ 월별 배치에 여유 버퍼 포함 (100% 할당 금지)
- ✅ `update` 모드로 주기적 Jira 동기화

---

## Examples

### 예시 1: 새 분기 로드맵
```
/roadmap create
```
→ OKR 로드 → Jira 에픽 조회 → RICE 스코어링 → 전략 분석 → plans/roadmap-2026-Q2.md 저장

### 예시 2: 현재 로드맵 조회
```
/roadmap
```
→ 최신 로드맵 표시 + Jira 상태 동기화 비교

### 예시 3: 우선순위만 빠르게
```
/roadmap prioritize
```
→ 백로그 RICE 스코어링 → 정렬 결과 출력 (파일 저장 없음)

### 예시 4: 상태 업데이트
```
/roadmap update
```
→ Jira 에픽 상태 조회 → 로드맵 상태 컬럼 동기화 → 변경 사항 리포트
