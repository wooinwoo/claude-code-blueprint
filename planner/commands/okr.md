---
description: OKR 설계/점검/정렬. Jira 연동 진척 추적, 상위 목표 정렬 맵.
---

# OKR — 목표 및 핵심 결과 관리

## Usage

```
/okr                              → 현재 OKR 조회 + 최신 진척 표시
/okr create                       → 새 OKR 설계
/okr review                       → OKR 진행 상황 점검 (Jira 연동)
/okr align                        → 팀 OKR ↔ 상위 OKR 정렬 확인
```

## OKR 설계 원칙

### Objective (목표)
- 정성적, 영감을 주는 표현 (숫자 금지)
- 1분기 내 달성 가능한 범위
- 팀당 3-5개 이내

### Key Results (핵심 결과)
- 정량적, 측정 가능 (반드시 숫자 포함)
- Objective당 2-4개
- 0-1.0 스케일 (0.7 = 성공)

---

## 서브커맨드: `create`

### Phase 1: 컨텍스트 수집

#### 1-1. 기존 전략 문서 탐색

```typescript
// plans/ 에서 관련 문서 수집
strategy_docs = Glob("plans/roadmap-*.md")
research_docs = Glob("plans/research-*.md")
competitive_docs = Glob("plans/competitive-analysis-*.md")
existing_okr = Glob("plans/okr-*.md")

for (const doc of [...strategy_docs, ...research_docs, ...competitive_docs]) {
  Read(doc)  // 전략 컨텍스트 확보
}

if (existing_okr.length > 0) {
  latest_okr = Read(existing_okr[0])
  console.log(`
  기존 OKR 발견: ${existing_okr[0]}
  → 이전 분기 OKR을 참고하여 연속성을 유지합니다.
  `)
}
```

#### 1-2. 미션/전략 질문

```typescript
AskUserQuestion({
  question: "OKR 설계에 필요한 정보를 알려주세요.",
  header: "OKR 컨텍스트",
  options: [
    {
      label: "회사/팀 미션",
      description: "이 팀이 존재하는 이유, 핵심 가치"
    },
    {
      label: "이번 분기 핵심 방향",
      description: "집중해야 할 영역 (성장/안정성/효율화 등)"
    },
    {
      label: "상위 OKR 참조",
      description: "회사/부서 OKR이 있으면 공유"
    }
  ]
})

AskUserQuestion({
  question: "OKR 기간을 선택하세요.",
  header: "기간 설정",
  options: [
    { label: "2026 Q1", description: "1월-3월" },
    { label: "2026 Q2", description: "4월-6월" },
    { label: "2026 Q3", description: "7월-9월" },
    { label: "2026 Q4", description: "10월-12월" }
  ]
})
```

### Phase 2: OKR 초안 생성

#### 2-1. researcher-strategist 에이전트 OKR 설계

```typescript
okr_draft = Agent("researcher-strategist", `
팀 OKR을 설계해줘.

미션/전략:
{mission_and_strategy}

이번 분기 방향:
{quarterly_direction}

참고 문서 요약:
- 로드맵: {roadmap_summary}
- 리서치: {research_summary}
- 경쟁 분석: {competitive_summary}
- 이전 OKR: {previous_okr_summary}

상위 OKR (있으면):
{upper_okr}

설계 규칙:
1. Objective는 정성적 (숫자 금지, 영감을 주는 표현)
2. Key Result는 정량적 (반드시 숫자 + 단위 포함)
3. Objective당 KR 2-4개
4. 전체 Objective 3-5개
5. 각 KR에 측정 방법 명시
6. 이전 분기 OKR과의 연속성 고려

반드시 아래 형식으로 응답해줘:

## O1: {목표 — 정성적 표현}
연결 상위 OKR: {있으면 명시, 없으면 'N/A'}

- KR1: {측정 지표} — 현재: {현재값} → 목표: {목표값}
  - 측정 방법: {어떻게 측정하는지}
  - Jira 라벨: okr-o1-kr1
- KR2: ...
- KR3: ...

## O2: {목표}
...

## 연간 맥락
- 이번 분기 이 OKR이 연간 전략에 기여하는 방식: {설명}
- 다음 분기 예상 발전 방향: {설명}
`)
```

### Phase 3: OKR 품질 검증

```typescript
// 자동 품질 체크
validation = {
  objectives_qualitative: true,   // O에 숫자 없는지
  kr_measurable: true,            // KR에 숫자 있는지
  kr_count_per_o: true,           // O당 KR 2-4개인지
  total_objectives: true,         // O 3-5개인지
  no_duplicate_kr: true           // KR 간 중복 없는지
}

for (const objective of okr.objectives) {
  // O에 숫자가 포함되면 경고
  if (/\d+/.test(objective.text)) {
    validation.objectives_qualitative = false
    console.log(`⚠️  O${objective.index}: 숫자 포함 — Objective는 정성적이어야 합니다.`)
  }

  // KR에 숫자가 없으면 경고
  for (const kr of objective.key_results) {
    if (!/\d+/.test(kr.text)) {
      validation.kr_measurable = false
      console.log(`⚠️  O${objective.index}-KR${kr.index}: 숫자 없음 — Key Result는 정량적이어야 합니다.`)
    }
  }

  // KR 개수 체크
  if (objective.key_results.length < 2 || objective.key_results.length > 4) {
    validation.kr_count_per_o = false
    console.log(`⚠️  O${objective.index}: KR ${objective.key_results.length}개 — 2-4개 권장.`)
  }
}

// 전체 O 개수 체크
if (okr.objectives.length < 3 || okr.objectives.length > 5) {
  validation.total_objectives = false
  console.log(`⚠️  Objective ${okr.objectives.length}개 — 3-5개 권장.`)
}
```

**검증 실패 시:**

```typescript
if (!all_valid) {
  // researcher-strategist에게 수정 요청
  // 검증 통과할 때까지 반복 (최대 2회)
  console.log("OKR 품질 기준 미달. 수정 중...")
}
```

**사용자 확인:**

```
OKR 초안이 준비되었습니다.

{OKR 전체 내용 표시}

검증 결과:
- ✅ Objective 정성적 표현
- ✅ Key Result 정량적 측정 가능
- ✅ O당 KR 2-4개
- ✅ 전체 O 3-5개

수정이 필요하면 말씀해주세요.
```

### Phase 4: 저장

```typescript
// content-writer 에이전트가 최종 문서 작성
Bash("mkdir -p plans")

Agent("content-writer", `
아래 내용을 Write 도구로 저장해줘.

파일 경로: plans/okr-{year}-Q{quarter}.md

# OKR — {year} Q{quarter}

- 작성일: {current_date}
- 팀: {team_name}
- 상태: DRAFT

${okr_content}

## 측정 계획
| KR | 측정 도구 | 측정 주기 | 담당자 |
|----|----------|----------|--------|
| O1-KR1 | {도구} | {주기} | {담당} |
...

## 정렬 맵
${alignment_map}
`)
```

```
OKR 저장 완료!
파일: plans/okr-{year}-Q{quarter}.md

다음 단계:
- /okr review 로 진행 상황 점검
- /okr align 로 상위 목표 정렬 확인
- /sprint-plan 으로 OKR 기반 스프린트 계획
```

---

## 서브커맨드: `review`

### Phase 1: OKR 로드

```typescript
// 현재 분기 OKR 파일 탐색
okr_files = Glob("plans/okr-*.md")

if (okr_files.length === 0) {
  console.log("OKR 파일이 없습니다. /okr create 로 먼저 생성하세요.")
  return
}

// 여러 개면 선택
if (okr_files.length > 1) {
  AskUserQuestion({
    question: "어떤 OKR을 점검할까요?",
    header: "OKR 선택",
    options: okr_files.map(f => ({
      label: f,
      description: `${extract_period(f)}`
    }))
  })
}

current_okr = Read(selected_okr_file)
```

### Phase 2: Jira 연동 진척 조회

```typescript
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)

// OKR의 각 KR에 대해 Jira에서 관련 이슈 조회
for (const objective of okr.objectives) {
  for (const kr of objective.key_results) {
    // KR에 연결된 Jira 이슈 검색 (라벨 기반)
    jira_label = kr.jira_label  // e.g. "okr-o1-kr1"

    issues = mcp__jira__jira_search({
      jql: `project = PROJ AND labels = '${jira_label}' ORDER BY status ASC`
    })

    // 이슈 상태별 집계
    kr.progress = {
      total: issues.length,
      done: issues.filter(i => i.status === "Done").length,
      in_progress: issues.filter(i => i.status === "In Progress").length,
      todo: issues.filter(i => i.status === "To Do").length,
      story_points_done: sum(issues.filter(i => i.status === "Done").map(i => i.story_points)),
      story_points_total: sum(issues.map(i => i.story_points))
    }
  }
}
```

**Jira 불가 시 대안:**

```typescript
// Jira MCP 연결 실패
if (jira_unavailable) {
  console.log(`
  ⚠️  Jira 연결 불가. 수동 진척 입력 모드로 전환합니다.

  .claude/.env 파일에서 JIRA_TOKEN, JIRA_URL, JIRA_USERNAME을 확인하세요.
  `)

  AskUserQuestion({
    question: "각 KR의 현재 진척도를 0.0-1.0으로 입력해주세요.",
    header: "수동 진척 입력"
  })
}
```

### Phase 3: 점수 계산

```typescript
for (const objective of okr.objectives) {
  for (const kr of objective.key_results) {
    // KR 점수 계산 (0.0 ~ 1.0)
    if (kr.progress.story_points_total > 0) {
      kr.score = kr.progress.story_points_done / kr.progress.story_points_total
    } else if (kr.progress.total > 0) {
      kr.score = kr.progress.done / kr.progress.total
    } else {
      kr.score = 0.0  // 연결된 이슈 없음
    }

    // 리스크 판정
    quarter_progress = days_elapsed / total_quarter_days  // 분기 경과율
    if (kr.score < quarter_progress * 0.5) {
      kr.risk = "AT_RISK"      // 기대 진척의 50% 미만
    } else if (kr.score < quarter_progress * 0.8) {
      kr.risk = "BEHIND"       // 기대 진척의 80% 미만
    } else {
      kr.risk = "ON_TRACK"
    }
  }

  // Objective 점수 = KR 점수 평균
  objective.score = average(objective.key_results.map(kr => kr.score))
}
```

### Phase 4: 진행 보고

```
## OKR 진행 현황 — {year} Q{quarter}

점검일: {current_date}
분기 경과: {quarter_progress_percent}%

### 전체 요약
| Objective | 점수 | 상태 |
|-----------|------|------|
| O1: {제목} | {0.65} | 🟡 BEHIND |
| O2: {제목} | {0.80} | 🟢 ON_TRACK |
| O3: {제목} | {0.30} | 🔴 AT_RISK |

### 상세 진행

#### O1: {목표} — 0.65
| KR | 현재값 | 목표값 | 점수 | 상태 | Jira 이슈 |
|----|--------|--------|------|------|-----------|
| KR1: {지표} | {현재} | {목표} | 0.7 | 🟢 | Done 5/7 |
| KR2: {지표} | {현재} | {목표} | 0.4 | 🔴 | Done 2/8 |
| KR3: {지표} | {현재} | {목표} | 0.8 | 🟢 | Done 4/5 |

#### O2: ...

### 리스크 항목
| KR | 상태 | 원인 | 권장 조치 |
|----|------|------|----------|
| O1-KR2 | 🔴 AT_RISK | In Progress 이슈 3건 정체 | 블로커 확인, 스프린트 우선순위 조정 |
| O3-KR1 | 🔴 AT_RISK | 관련 이슈 미생성 | /sprint-plan 으로 이슈 추가 |

상태 범례: 🟢 ON_TRACK (0.7+) | 🟡 BEHIND (0.5-0.7) | 🔴 AT_RISK (<0.5 상대 경과율)
```

---

## 서브커맨드: `align`

### Phase 1: OKR 파일 로드

```typescript
// 팀 OKR + 상위 OKR 로드
team_okr_files = Glob("plans/okr-*.md")
upper_okr = null

AskUserQuestion({
  question: "상위 OKR(회사/부서)은 어떻게 제공하시겠습니까?",
  header: "상위 OKR 소스",
  options: [
    {
      label: "파일 경로 지정",
      description: "plans/ 내 상위 OKR 파일 선택"
    },
    {
      label: "직접 입력",
      description: "상위 Objective를 텍스트로 입력"
    },
    {
      label: "Jira에서 조회",
      description: "Jira Epic/Initiative에서 상위 목표 추출"
    }
  ]
})

// Jira 조회 선택 시
if (source === "jira") {
  upper_objectives = mcp__jira__jira_search({
    jql: "project = PROJ AND type = Initiative ORDER BY rank ASC"
  })
}
```

### Phase 2: 정렬 매핑

```typescript
// 팀 Objective와 상위 Objective 매핑
alignment = []

for (const team_o of team_okr.objectives) {
  matching_upper = find_matching_upper_objective(team_o, upper_okr)
  alignment.push({
    team_objective: team_o,
    upper_objective: matching_upper,  // null이면 미연결
    connection_strength: matching_upper ? assess_strength(team_o, matching_upper) : "NONE"
  })
}

// 상위 OKR 중 팀 OKR에 연결되지 않은 것 식별
unconnected_upper = upper_okr.objectives.filter(
  uo => !alignment.some(a => a.upper_objective?.id === uo.id)
)
```

### Phase 3: 정렬 보고

```
## OKR 정렬 맵

### 연결 현황

상위 OKR → 팀 OKR 매핑:

  [회사 O1: 시장 1위 달성]
    ├── 팀 O1: 핵심 기능 경쟁력 확보 ──── 연결 강도: STRONG
    └── 팀 O3: 사용자 만족도 향상 ──────── 연결 강도: MEDIUM

  [회사 O2: 수익성 개선]
    └── 팀 O2: 전환율 최적화 ───────────── 연결 강도: STRONG

  [회사 O3: 글로벌 확장]
    └── (미연결) ⚠️

### 정렬 점수
| 팀 Objective | 상위 Objective | 연결 강도 |
|-------------|---------------|----------|
| O1: {팀 목표} | 회사 O1: {상위 목표} | 🟢 STRONG |
| O2: {팀 목표} | 회사 O2: {상위 목표} | 🟢 STRONG |
| O3: {팀 목표} | 회사 O1: {상위 목표} | 🟡 MEDIUM |

### 미연결 항목

#### 상위 OKR에 연결되지 않은 팀 Objective
- (없음 — 모든 팀 O가 상위 O에 연결됨)

#### 팀 OKR에서 다루지 않는 상위 Objective
- ⚠️  회사 O3: 글로벌 확장
  - 권장: 팀 범위 밖이라면 무시, 관련 있다면 O 추가 검토

### 권장 조치
1. {구체적 정렬 개선 방안}
2. {미연결 항목 처리 제안}
```

---

## 기본 동작 (인자 없음)

### 현재 OKR 조회

```typescript
// 가장 최근 OKR 파일 로드
okr_files = Glob("plans/okr-*.md")

if (okr_files.length === 0) {
  console.log(`
  OKR 파일이 없습니다.

  시작하기:
  - /okr create  → 새 OKR 설계
  `)
  return
}

current_okr = Read(okr_files[0])

// Jira에서 간단 진척 조회 (가능하면)
try {
  for (const kr of all_key_results) {
    issues = mcp__jira__jira_search({
      jql: `project = PROJ AND labels = '${kr.jira_label}' AND status = 'Done'`
    })
    kr.quick_progress = issues.length
  }
} catch {
  // Jira 불가 시 파일 내용만 표시
}

// 현재 OKR + 진척 표시
console.log(current_okr_with_progress)
```

---

## 예외 처리

### Jira 연결 불가

```typescript
if (jira_unavailable) {
  console.log(`
  ⚠️  Jira MCP 연결 실패.

  확인 사항:
  1. .claude/.env 의 JIRA_TOKEN 유효 여부
  2. .claude/.env 의 JIRA_URL 정확 여부
  3. .claude/.env 의 JIRA_USERNAME 정확 여부

  대안:
  - review: 수동 진척 입력 모드로 전환
  - create: Jira 라벨 없이 OKR만 생성
  `)
}
```

### 기존 OKR 파일 없음

```typescript
if (okr_files.length === 0 && subcommand !== "create") {
  console.log(`
  OKR 파일이 없습니다.
  /okr create 로 먼저 생성하세요.
  `)
  return
}
```

### 상위 OKR 없음 (align)

```typescript
if (!upper_okr) {
  console.log(`
  ⚠️  상위 OKR을 확인할 수 없습니다.

  대안:
  1. 상위 OKR 텍스트를 직접 입력
  2. 팀 OKR만 단독 검증 (정렬 없이 품질 체크)
  `)
}
```

---

## 주의사항

### 금지사항
- ❌ Objective에 숫자/지표 포함 금지 (정성적이어야 함)
- ❌ KR에 정성적 표현만 사용 금지 (반드시 측정 가능한 숫자 포함)
- ❌ O당 KR 5개 이상 금지 (집중도 저하)
- ❌ Jira 라벨 임의 생성 금지 (기존 라벨 규칙 준수)

### 권장사항
- ✅ 분기 시작 전 `create`, 분기 중 격주 `review`
- ✅ KR 점수 0.7 = 성공 (1.0은 목표가 너무 쉬웠다는 의미)
- ✅ 상위 OKR과 `align` 필수 (팀 OKR이 붕 뜨지 않도록)
- ✅ `/sprint-plan`과 연계하여 KR에 Jira 이슈 연결

---

## Examples

### 예시 1: OKR 생성
```
/okr create
→ 전략 문서 스캔 → 미션 질문 → researcher-strategist 설계 → 품질 검증 → 저장
→ plans/okr-2026-Q2.md
```

### 예시 2: 진행 점검
```
/okr review
→ OKR 로드 → Jira 이슈 조회 → 점수 계산 → 리스크 플래그
→ O1: 0.65 🟡 | O2: 0.80 🟢 | O3: 0.30 🔴
```

### 예시 3: 정렬 확인
```
/okr align
→ 팀 OKR + 상위 OKR 로드 → 매핑 → 미연결 항목 식별
→ "회사 O3: 글로벌 확장이 팀 OKR에 미연결"
```

### 예시 4: 현재 OKR 조회
```
/okr
→ 최신 OKR 파일 표시 + Jira 기반 간단 진척
```
