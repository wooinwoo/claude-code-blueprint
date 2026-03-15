---
description: 시장/사용자/기술/경쟁사 리서치 실행. WebSearch 기반 데이터 수집 + 에이전트 분석 + 신뢰도 검증.
---

# Research — 리서치 실행

## Usage

```
/research <topic>                  → 일반 주제 리서치 (researcher-strategist)
/research --market <industry>      → 시장 리서치 (규모, 성장률, 트렌드)
/research --user <segment>         → 사용자 리서치 (니즈, 페인포인트, 행동)
/research --tech <technology>      → 기술 리서치 (채택률, 비교, 사례)
/research --competitor <company>   → `/competitive-analysis`로 안내 (전용 커맨드 사용)
```

---

## Phase 1: 리서치 스코핑

### 1-1. 플래그별 방법론 결정

```typescript
// 플래그에 따라 리서치 방법론 + 담당 에이전트 + 검색 쿼리 패턴 결정
const methodology = {
  "--market": {
    agent: "researcher-strategist",
    focus: "시장 규모, 성장률, 주요 플레이어, 트렌드",
    output_sections: ["시장 개요", "시장 규모 및 성장", "주요 플레이어", "트렌드", "시사점"]
  },
  "--user": {
    agent: "ux-researcher",
    focus: "사용자 니즈, 페인포인트, 행동 패턴, 세그먼트",
    output_sections: ["사용자 프로필", "페인 포인트", "니즈 분석", "행동 패턴", "인사이트"]
  },
  "--tech": {
    agent: "researcher-strategist",
    focus: "기술 채택률, 대안 비교, 엔터프라이즈 사례",
    output_sections: ["기술 개요", "채택 현황", "대안 비교", "사례 연구", "추천"]
  },
  // "--competitor" → /competitive-analysis 사용 안내
  // 경쟁사 분석은 전용 커맨드가 더 상세하므로 리다이렉트
  "--competitor": {
    redirect: true,
    message: "경쟁사 분석은 `/competitive-analysis` 커맨드를 사용하세요. 더 상세한 기능 매트릭스, SWOT, 포지셔닝 분석을 제공합니다."
  },
  "default": {
    agent: "researcher-strategist",
    focus: "주제 전반 조사",
    output_sections: ["개요", "주요 발견", "데이터 분석", "시사점", "추가 조사 필요"]
  }
}

// 플래그 있으면 바로 해당 방법론 선택
// 플래그 없으면 → 리서치 플랜 수립 (Phase 1-Plan)
selected = methodology[flag] || null
```

### 1-Plan. 리서치 플랜 수립 (플래그 없이 진입 시)

플래그 없이 `/research <topic>`만 입력하면 바로 검색하지 않고, 리서치 플랜을 먼저 세운다.

```typescript
if (!flag) {
  // Step 1: 기존 맥락 수집
  const existing_docs = Glob("plans/*.md")  // 이미 있는 리서치/PRD/로드맵
  const project_context = Read("CLAUDE.md")  // 프로젝트 개요

  // Step 2: 리서치 플랜 초안 생성
  const plan = Agent("researcher-strategist", `
    주제: ${topic}
    기존 문서: ${existing_docs}
    프로젝트 맥락: ${project_context}

    다음을 포함한 리서치 플랜을 작성해줘:

    1. **리서치 목적**: 이 조사로 답하려는 핵심 질문 3-5개
    2. **리서치 유형**: market / user / tech / competitor 중 가장 적합한 유형 (복합 가능)
    3. **검색 전략**: 검색할 쿼리 목록 (한국어 + 영어, 총 8-12개)
    4. **예상 소스**: 가장 신뢰할 수 있는 1차 소스 (정부 통계, 업계 보고서, 학술 등)
    5. **범위 제한**: 지역, 기간, 산업 한정 조건
    6. **기존 문서와의 관계**: 이미 알고 있는 것 vs 이번에 새로 조사할 것

    형식: 마크다운 테이블 + 불릿 포인트
  `)

  // Step 3: 사용자 확인
  AskUserQuestion([
    {
      question: "리서치 플랜을 확인해주세요. 수정할 부분이 있나요?",
      header: "리서치 플랜 확인",
      description: plan,
      options: [
        { label: "이대로 진행", description: "플랜대로 리서치 실행" },
        { label: "수정 후 진행", description: "핵심 질문이나 검색 전략 수정" },
        { label: "취소", description: "리서치 중단" }
      ]
    }
  ])

  // "수정 후 진행" 선택 시 → 수정 사항 반영 후 재확인
  // "취소" 선택 시 → 종료

  // 플랜에서 결정된 유형으로 methodology 매핑
  selected = methodology[plan.research_type] || methodology["default"]
}
```

### 1-2. 리서치 질문 정의 (플래그 직접 지정 시)

플래그를 직접 지정한 경우 (`/research --market <industry>`) 플랜 단계를 건너뛰고 바로 질문 정의로 진입.

```typescript
if (flag) {
  AskUserQuestion([
    {
      question: "리서치에서 답하고 싶은 핵심 질문은?",
      header: "리서치 질문",
      description: `
  플래그: ${flag}
  조사 주제: ${topic}
  조사 초점: ${selected.focus}

  예시 질문:
  - "이 시장의 향후 3년 성장 전망은?"
  - "타겟 사용자의 가장 큰 페인포인트는?"
  - "이 기술의 프로덕션 채택률은?"
      `,
      // 핵심 질문 1-3개 입력 요청
    },
    {
      question: "조사 범위를 한정할 조건이 있나요?",
      header: "범위 제한",
      options: [
        { label: "지역", description: "한국/미국/글로벌 등" },
        { label: "기간", description: "최근 1년/3년/5년" },
        { label: "산업", description: "특정 산업/버티컬 한정" },
        { label: "없음", description: "범위 제한 없이 전체 조사" }
      ]
    }
  ])
}

state.questions = user_questions
state.scope = user_scope
```

---

## Phase 2: 데이터 수집

### 2-1. WebSearch — 플래그별 쿼리 패턴

```typescript
// --market 플래그: 시장 리서치 쿼리
if (flag === "--market") {
  queries = [
    `"${industry}" market size 2024 2025`,
    `"${industry}" CAGR forecast 2025-2030`,
    `"${industry}" key players market share`,
    `"${industry}" market trends ${year}`,
    `"${industry}" industry report Gartner IDC`,
    `"${industry}" 시장 규모 한국`  // 한국 시장 별도 조사
  ]
}

// --user 플래그: 사용자 리서치 쿼리
if (flag === "--user") {
  queries = [
    `"${segment}" pain points survey`,
    `"${segment}" user behavior study ${year}`,
    `"${segment}" needs analysis research`,
    `"${segment}" customer satisfaction NPS`,
    `"${segment}" user journey challenges`,
    `"${segment}" 사용자 조사 결과`  // 한국어 소스
  ]
}

// --tech 플래그: 기술 리서치 쿼리
if (flag === "--tech") {
  queries = [
    `"${technology}" adoption rate enterprise ${year}`,
    `"${technology}" vs alternatives comparison ${year}`,
    `"${technology}" enterprise use cases production`,
    `"${technology}" pros cons limitations`,
    `"${technology}" benchmark performance`,
    `"${technology}" migration guide best practices`
  ]
}

// --competitor 플래그: 경쟁사 분석 쿼리
if (flag === "--competitor") {
  queries = [
    `"${company}" product features ${year}`,
    `"${company}" pricing plans comparison`,
    `"${company}" reviews G2 Capterra`,
    `"${company}" funding revenue valuation`,
    `"${company}" vs competitors`,
    `"${company}" product roadmap announcements`
  ]
}

// 플래그 없음: 일반 리서치
if (!flag) {
  queries = [
    `"${topic}" overview ${year}`,
    `"${topic}" latest trends ${year}`,
    `"${topic}" analysis report`,
    `"${topic}" statistics data`,
    `"${topic}" expert opinion`
  ]
}

// 검색 실행
search_results = []
for (query of queries) {
  result = WebSearch(query)
  search_results.push({
    query: query,
    results: result,
    timestamp: now()
  })
}

console.log(`
🔍 데이터 수집 완료

검색 쿼리: ${queries.length}개
수집 결과: ${search_results.reduce((sum, r) => sum + r.results.length, 0)}개 소스
`)
```

### 2-2. 내부 문서 탐색

```typescript
// plans/ 디렉토리에서 관련 기존 리서치/PRD 검색
internal_docs = Glob("plans/*.md")

// 관련 문서 찾기
related = internal_docs.filter(doc => {
  content = Read(doc)
  return content.includes(topic) || content.includes(industry || segment || technology || company)
})

if (related.length > 0) {
  console.log(`
  📁 관련 내부 문서:
  ${related.map(f => `  - ${f}`).join("\n")}
  `)
  related_content = related.map(f => Read(f))
} else {
  related_content = []
}
```

### 2-3. Jira 관련 이슈 조회 (선택)

```typescript
try {
  jira_issues = mcp__jira__jira_search({
    jql: `text ~ "${topic}" ORDER BY updated DESC`,
    fields: "summary,description,status,labels",
    max_results: 10
  })

  if (jira_issues.length > 0) {
    console.log(`
    📋 Jira 관련 이슈: ${jira_issues.length}개
    ${jira_issues.map(i => `  - ${i.key}: ${i.summary}`).join("\n")}
    `)
  }
} catch (error) {
  // Jira 연결 실패 — 무시하고 계속
  jira_issues = []
}

state.collected_data = {
  web: search_results,
  internal: related_content,
  jira: jira_issues
}
```

---

## Phase 3: 분석

### 3-1. 에이전트 분석 실행

```typescript
// 플래그별 담당 에이전트 호출
if (flag === "--market" || flag === "--competitor" || flag === "--tech" || !flag) {

  analysis = Agent("researcher-strategist", `
    다음 데이터를 분석하여 리서치 결과를 정리하세요.

    ## 리서치 컨텍스트
    주제: ${topic}
    플래그: ${flag || "일반"}
    핵심 질문: ${state.questions.join(", ")}
    범위: ${state.scope}

    ## 수집 데이터
    ### 웹 검색 결과
    ${JSON.stringify(state.collected_data.web)}

    ### 내부 문서
    ${state.collected_data.internal.join("\n---\n")}

    ### Jira 이슈
    ${state.collected_data.jira.map(i => `${i.key}: ${i.summary}`).join("\n")}

    ## 분석 요청
    1. 핵심 질문에 대한 답변 — 데이터 근거 포함
    2. 주요 수치/통계 정리 — 출처와 신뢰도 명시
    3. 패턴/트렌드 식별 — 복수 소스 교차 확인
    4. 시사점 도출 — 우리 제품에 미치는 영향
    5. 추가 조사 필요 항목 — 데이터 부족 영역

    ## 출력 규칙
    - 모든 수치에 출처 표시: "값 (출처, 날짜, 신뢰도: HIGH/MEDIUM/LOW)"
    - 교차 검증: 핵심 수치는 2개 이상 소스 비교
    - 편향 명시: 데이터 한계/편향 별도 섹션으로
    - 결론 확신도: HIGH/MEDIUM/LOW 표시

    ## 출력 형식
    ${selected.output_sections.map((s, i) => `### ${i+1}. ${s}`).join("\n")}

    ### 데이터 소스
    | 소스 | 유형 | 날짜 | 신뢰도 |
    |------|------|------|--------|

    ### 한계 및 편향
    [데이터 한계, 지역 편향, 시점 편향 등]
  `)
}

if (flag === "--user") {

  analysis = Agent("ux-researcher", `
    다음 데이터를 분석하여 사용자 리서치 결과를 정리하세요.

    ## 리서치 컨텍스트
    타겟 세그먼트: ${topic}
    핵심 질문: ${state.questions.join(", ")}
    범위: ${state.scope}

    ## 수집 데이터
    ### 웹 검색 결과
    ${JSON.stringify(state.collected_data.web)}

    ### 내부 문서
    ${state.collected_data.internal.join("\n---\n")}

    ## 분석 요청
    1. 사용자 프로필/페르소나 — 데이터 기반 특성 정리
    2. 페인 포인트 분류 — 심각도(HIGH/MEDIUM/LOW) 부여
    3. 니즈 분석 — 명시적 니즈 vs 잠재 니즈 구분
    4. 행동 패턴 — 관찰된 행동과 근거
    5. 기회 영역 — 제품 개선/신규 기능 기회

    ## 출력 규칙
    - 관찰 vs 해석 구분 명확히
    - 샘플 크기/대표성 명시
    - 정성 데이터는 패턴화하여 정리
    - 결론 확신도: HIGH/MEDIUM/LOW

    ## 출력 형식
    ### 1. 사용자 프로필
    ### 2. 페인 포인트
    | 페인 포인트 | 심각도 | 빈도 | 근거 |
    |------------|--------|------|------|

    ### 3. 니즈 분석
    | 니즈 | 유형 (명시적/잠재) | 근거 |
    |------|-------------------|------|

    ### 4. 행동 패턴
    ### 5. 인사이트 및 기회

    ### 데이터 소스
    | 소스 | 유형 | 날짜 | 신뢰도 |
    |------|------|------|--------|

    ### 한계 및 편향
    [샘플 편향, 자기보고 한계, 문화적 맥락 등]
  `)
}

state.analysis = analysis
```

---

## Phase 4: 검증

### 4-1. 교차 검증

```typescript
// 핵심 수치/주장에 대한 교차 검증
console.log(`
🔍 교차 검증 실행

핵심 데이터 포인트:
`)

// 분석 결과에서 수치 데이터 추출 후 복수 소스 확인
// 예시:
console.log(`
| 데이터 | 소스 1 | 소스 2 | 소스 3 | 합의 범위 | 신뢰도 |
|--------|--------|--------|--------|----------|--------|
| 시장 규모 | $12B (Gartner) | $11.5B (IDC) | $13.2B (Statista) | $11.5-13.2B | HIGH |
| 성장률 | 15.3% (Gartner) | 14.8% (IDC) | — | 14.8-15.3% | MEDIUM |
| 점유율 1위 | 23% (Gartner) | — | 25% (Statista) | 23-25% | MEDIUM |
`)
```

### 4-2. 신뢰도 평가

```typescript
// 전체 리서치 신뢰도 산정
confidence_factors = {
  source_count: search_results.length,           // 소스 수
  cross_validated: cross_validated_count,         // 교차 검증된 수치 수
  recency: most_recent_source_date,              // 최신 소스 날짜
  primary_sources: primary_source_count,          // 1차 소스 수
  bias_identified: bias_count                     // 식별된 편향 수
}

// 종합 신뢰도
overall_confidence = calculateConfidence(confidence_factors)

console.log(`
📊 리서치 신뢰도 평가

| 항목 | 값 | 평가 |
|------|-----|------|
| 소스 수 | ${confidence_factors.source_count} | ${confidence_factors.source_count >= 5 ? "충분" : "부족"} |
| 교차 검증 | ${confidence_factors.cross_validated}개 수치 | ${confidence_factors.cross_validated >= 3 ? "양호" : "추가 필요"} |
| 최신성 | ${confidence_factors.recency} | ${isRecent(confidence_factors.recency) ? "최신" : "업데이트 필요"} |
| 1차 소스 | ${confidence_factors.primary_sources}개 | ${confidence_factors.primary_sources >= 2 ? "양호" : "보완 필요"} |

종합 신뢰도: ${overall_confidence} (HIGH/MEDIUM/LOW)
`)
```

---

## Phase 5: 보고서 생성

### 5-1. content-writer 에이전트로 보고서 작성

```typescript
const date_slug = new Date().toISOString().slice(0, 10)  // YYYY-MM-DD
const file_path = `plans/research-${topic}-${date_slug}.md`

Bash("mkdir -p plans")
Agent("content-writer", `
  리서치 보고서를 작성하세요.

  ## 입력 데이터
  주제: ${topic}
  플래그: ${flag || "일반"}
  핵심 질문: ${state.questions.join(", ")}
  분석 결과: ${state.analysis}
  교차 검증: ${cross_validation_results}
  종합 신뢰도: ${overall_confidence}

  ## 보고서 템플릿

  # 리서치 보고서: ${topic}

  - **작성일**: ${today}
  - **상태**: Draft
  - **리서치 유형**: ${flag || "일반"}
  - **종합 신뢰도**: ${overall_confidence}
  - **관련 문서**: [연결된 PRD, OKR 등]

  ---

  ## Executive Summary
  [핵심 질문에 대한 1-2문단 요약 답변]

  ## 1. 리서치 목적
  ### 핵심 질문
  ${state.questions.map((q, i) => `${i+1}. ${q}`).join("\n")}

  ### 조사 범위
  ${state.scope}

  ### 방법론
  [사용한 리서치 방법, 데이터 수집 방식]

  ## 2. 주요 발견
  [분석 결과의 핵심 발견사항 — 섹션은 플래그별 output_sections 사용]
  ${selected.output_sections.map((s, i) => `### 2.${i+1} ${s}\n[내용]`).join("\n\n")}

  ## 3. 데이터 분석
  ### 핵심 수치
  | 데이터 | 값 | 출처 | 신뢰도 |
  |--------|-----|------|--------|

  ### 교차 검증 결과
  | 데이터 | 소스 1 | 소스 2 | 합의 범위 |
  |--------|--------|--------|----------|

  ## 4. 시사점
  ### 제품에 미치는 영향
  [분석 결과가 우리 제품/전략에 주는 함의]

  ### 기회 영역
  | 기회 | 임팩트 | 근거 |
  |------|--------|------|

  ### 위험 요소
  | 위험 | 확률 | 근거 |
  |------|------|------|

  ## 5. 한계 및 편향
  - [데이터 한계]
  - [지역/시점/선택 편향]
  - [추가 조사 필요 영역]

  ## 6. 데이터 소스
  | # | 소스 | 유형 | 날짜 | 신뢰도 | URL |
  |---|------|------|------|--------|-----|

  ## 7. Next Steps
  | 항목 | 담당 | 기한 | 비고 |
  |------|------|------|------|
  | [후속 리서치] | | | 데이터 부족 영역 |
  | [PRD 반영] | PM | | /prd에 리서치 결과 연동 |
  | [이해관계자 공유] | PM | | 리뷰 미팅 |

  ## 작성 규칙
  - 모든 수치에 "(출처, 날짜, 신뢰도)" 표시
  - 주장과 근거 1:1 매핑
  - "~인 것 같다" 금지 → 확신도 명시 (HIGH/MEDIUM/LOW)
  - 데이터 없는 영역은 "[데이터 부족 — 추가 조사 필요: 조사 방법]" 표시

  ## 저장 경로
  Write("${file_path}", report_content)
`)
```

### 5-2. 완료 메시지

```
✅ 리서치 완료

파일: plans/research-{topic}-{date}.md
유형: {flag || "일반"}
핵심 질문: {questions.length}개
데이터 소스: {source_count}개
종합 신뢰도: {overall_confidence}

주요 발견:
1. [발견 1 — 한 줄 요약]
2. [발견 2 — 한 줄 요약]
3. [발견 3 — 한 줄 요약]

다음 단계:
| 항목 | 액션 |
|------|------|
| PRD 반영 | /prd <feature> 실행 시 리서치 자동 참조 |
| 추가 리서치 | /research --{other_flag} {topic} |
| 경쟁 분석 | /competitive-analysis {competitor} |
```

---

## 예외 처리

### WebSearch 실패

```typescript
// WebSearch가 결과를 반환하지 않는 경우
if (search_results.length === 0 || all_empty) {
  console.log(`
  ⚠️ 웹 검색 결과가 충분하지 않습니다.

  가능한 원인:
  - 너무 구체적인 검색어 → 범위를 넓혀서 재검색
  - 영문 검색어로 재시도 필요
  - 최근 토픽이라 데이터 부족

  대안:
  1. 검색어를 수정하여 재시도
  2. 내부 문서 기반으로만 분석 진행
  3. 리서치 중단 후 수동 데이터 수집
  `)

  AskUserQuestion([{
    question: "어떻게 진행할까요?",
    header: "데이터 부족",
    options: [
      { label: "검색어 수정", description: "다른 키워드로 재검색" },
      { label: "내부 문서만", description: "기존 plans/ 문서 기반 분석" },
      { label: "중단", description: "수동 데이터 수집 후 재실행" }
    ]
  }])
}
```

### 신뢰도 LOW 경고

```typescript
if (overall_confidence === "LOW") {
  console.log(`
  ⚠️ 종합 신뢰도가 LOW입니다.

  원인:
  - 1차 소스 부족 (${primary_source_count}개)
  - 교차 검증 미달 (${cross_validated_count}개 수치만 검증됨)
  - 데이터 시점이 오래됨

  보고서에 "LOW 신뢰도" 워터마크가 표시됩니다.
  의사결정 전 추가 리서치를 권장합니다.
  `)
}
```

---

## 주의사항

### 금지사항
- ❌ 출처 없는 수치 인용 금지
- ❌ 단일 소스로 결론 도출 금지 (교차 검증 필수)
- ❌ 확신도 표시 없이 결론 작성 금지
- ❌ 편향/한계 섹션 누락 금지
- ❌ `plans/` 외 경로에 저장 금지

### 권장사항
- ✅ 1차 소스 우선 (Gartner, IDC, 정부 통계 > 블로그)
- ✅ 한국어 + 영어 검색 병행 (글로벌 + 로컬 시각)
- ✅ 정량 + 정성 데이터 균형
- ✅ 최근 12개월 이내 데이터 우선
- ✅ 리서치 결과를 PRD/로드맵에 연결 (`/prd`, `/roadmap`)
- ✅ 경쟁사 분석은 `/competitive-analysis`와 병행

---

## Examples

### 예시 1: 시장 리서치
```
/research --market "HR SaaS"
```
→ 시장 규모/성장률/주요 플레이어 검색 → researcher-strategist 분석 → plans/research-hr-saas-2026-03-14.md

### 예시 2: 사용자 리서치
```
/research --user "중소기업 HR 담당자"
```
→ 페인포인트/니즈/행동 패턴 검색 → ux-researcher 분석 → plans/research-중소기업-hr-담당자-2026-03-14.md

### 예시 3: 기술 리서치
```
/research --tech "GraphQL"
```
→ 채택률/비교/사례 검색 → researcher-strategist 분석 → plans/research-graphql-2026-03-14.md

### 예시 4: 경쟁사 분석
```
/research --competitor "Workday"
```
→ 기능/가격/리뷰 검색 → researcher-strategist 분석 → plans/research-workday-2026-03-14.md

### 예시 5: 일반 리서치
```
/research "AI 기반 채용 자동화"
```
→ 전반 조사 검색 → researcher-strategist 분석 → plans/research-ai-기반-채용-자동화-2026-03-14.md
