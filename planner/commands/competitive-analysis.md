---
description: 경쟁사 분석 실행. WebSearch 데이터 수집 → 기능 매트릭스 → SWOT/포지셔닝 분석.
---

# Competitive Analysis — 경쟁 분석 워크플로

## Usage

```
/competitive-analysis Notion Coda Monday       → 특정 경쟁사 분석
/competitive-analysis                          → 경쟁사 목록 질문 후 분석
/competitive-analysis --feature 실시간 협업     → 단일 기능 기준 경쟁사 비교
```

## 용도

**경쟁사 대비 제품 포지셔닝 파악 및 차별화 전략 수립**
- 기능 비교 매트릭스
- SWOT 분석
- 포지셔닝 맵
- 차별화 기회 도출

---

## Phase 1: 준비

### 1-1. 기존 분석 확인

```typescript
// plans/ 디렉토리에서 기존 경쟁 분석 문서 탐색
existing = Glob("plans/competitive-analysis-*.md")

if (existing.length > 0) {
  // 가장 최근 파일 읽기
  latest = Read(existing[0])
  console.log(`
  기존 분석 발견: ${existing[0]}
  작성일: ${latest.date}
  경쟁사: ${latest.competitors}
  `)
}
```

### 1-2. 경쟁사 목록 확정

```typescript
if (args.competitors) {
  // 인자로 경쟁사가 지정된 경우
  competitors = args.competitors  // ["Notion", "Coda", "Monday"]
} else {
  // 사용자에게 질문
  AskUserQuestion({
    question: "분석할 경쟁사를 입력하세요 (쉼표 구분)",
    header: "경쟁사 선택",
    options: [
      {
        label: "직접 입력",
        description: "경쟁사명을 쉼표로 구분하여 입력"
      },
      {
        label: "기존 목록 사용",
        description: `이전 분석의 경쟁사: ${existing_competitors}`,
        visible: existing.length > 0
      }
    ]
  })
}
```

### 1-3. 우리 제품 정보 확인

```typescript
// plans/ 에서 제품 정보 탐색
product_docs = Glob("plans/prd-*.md")
roadmap_docs = Glob("plans/roadmap-*.md")

if (product_docs.length > 0) {
  our_product = Read(product_docs[0])
} else {
  AskUserQuestion({
    question: "우리 제품의 핵심 기능과 타겟 고객을 간략히 설명해주세요.",
    header: "제품 정보"
  })
}
```

### 1-4. 분석 범위 결정

```typescript
if (args.feature) {
  // --feature 모드: 단일 기능 심층 비교
  analysis_mode = "feature_focus"
  target_feature = args.feature  // e.g. "실시간 협업"
} else {
  analysis_mode = "full"
}
```

---

## Phase 2: 데이터 수집

### 2-1. WebSearch 실행 (경쟁사별)

**각 경쟁사에 대해 4가지 카테고리로 검색합니다:**

```typescript
for (const competitor of competitors) {
  // 1. 제품 기능
  WebSearch({ query: `${competitor} product features ${current_year}` })
  WebSearch({ query: `${competitor} 주요 기능 특징 ${current_year}` })

  // 2. 가격 정책
  WebSearch({ query: `${competitor} pricing plans ${current_year}` })
  WebSearch({ query: `${competitor} 요금제 가격` })

  // 3. 고객 리뷰/평판
  WebSearch({ query: `${competitor} customer reviews pros cons` })
  WebSearch({ query: `${competitor} G2 review rating` })

  // 4. 비즈니스 정보
  WebSearch({ query: `${competitor} funding revenue company size ${current_year}` })
  WebSearch({ query: `${competitor} 투자 매출 기업 규모` })
}
```

**`--feature` 모드 추가 검색:**

```typescript
if (analysis_mode === "feature_focus") {
  for (const competitor of competitors) {
    WebSearch({ query: `${competitor} ${target_feature} feature review` })
    WebSearch({ query: `${competitor} ${target_feature} comparison benchmark` })
    WebSearch({ query: `${competitor} ${target_feature} 기능 사용법 리뷰` })
  }
}
```

### 2-2. researcher-strategist 에이전트 데이터 가공

```typescript
structured_data = Agent("researcher-strategist", `
다음 웹 검색 결과를 경쟁사별로 구조화해줘.

원시 데이터:
{search_results}

경쟁사 목록: {competitors}

각 경쟁사에 대해 아래 형식으로 정리해줘:

## {경쟁사명}

### 제품 개요
- 핵심 제품: {제품명, 카테고리}
- 타겟 고객: {B2B/B2C, 기업 규모, 산업}
- 주요 USP: {핵심 차별점 1-3가지}

### 기능 목록
- {기능 1}: {설명} — 강도: STRONG/MEDIUM/WEAK
- {기능 2}: {설명} — 강도: STRONG/MEDIUM/WEAK

### 가격
- {플랜명}: ${가격}/월 — {포함 기능}

### 시장 위치
- 추정 매출/규모: {데이터}
- 투자: {시리즈, 금액}
- 시장 점유율: {데이터 또는 '미확인'}

### 강점/약점
- 강점: {고객 리뷰 기반}
- 약점: {고객 리뷰 기반}

### 데이터 신뢰도
- 출처: {사용된 소스 목록}
- 신뢰도: HIGH/MEDIUM/LOW — {판단 근거}

데이터가 불충분한 항목은 '미확인'으로 표기하고,
추정치는 '~' 접두사를 붙여줘 (예: ~$50M).
`)
```

**예외 처리:**

```typescript
// 검색 결과가 부족한 경쟁사
if (search_results[competitor].length < 3) {
  console.log(`
  ⚠️  ${competitor}: 검색 결과 부족 (${search_results[competitor].length}건)
  → 수동 조사가 필요할 수 있습니다.
  `)
}
```

---

## Phase 3: 매트릭스 구축

### 3-1. 기능 비교 매트릭스

```typescript
// Phase 2 데이터를 기반으로 매트릭스 생성
// --feature 모드: target_feature의 세부 항목으로 행 구성
// full 모드: 전체 기능 카테고리로 행 구성

if (analysis_mode === "feature_focus") {
  // 단일 기능의 세부 비교
  matrix_rows = [
    `${target_feature} — 기본 기능`,
    `${target_feature} — 고급 기능`,
    `${target_feature} — UI/UX`,
    `${target_feature} — 성능/안정성`,
    `${target_feature} — 가격 (해당 기능)`,
    `${target_feature} — API/연동`,
  ]
} else {
  // 전체 기능 카테고리
  matrix_rows = extract_feature_categories(structured_data)
}
```

**매트릭스 출력 형식:**

```
## 기능 비교 매트릭스

| 기능            | 우리 제품 | Notion  | Coda    | Monday  |
|-----------------|----------|---------|---------|---------|
| 실시간 협업      | ✅ 강함   | ✅ 강함  | ⚠️ 보통 | ❌ 없음  |
| AI 기능         | ⚠️ 보통   | ✅ 강함  | ✅ 강함  | ⚠️ 보통  |
| 워크플로 자동화  | ✅ 강함   | ⚠️ 보통  | ⚠️ 보통 | ✅ 강함  |
| API 확장성      | ✅ 강함   | ✅ 강함  | ⚠️ 보통 | ✅ 강함  |
| 모바일 앱       | ⚠️ 보통   | ✅ 강함  | ❌ 없음  | ✅ 강함  |

범례: ✅ 강함(STRONG) | ⚠️ 보통(MEDIUM) | ❌ 없음/약함(WEAK/NONE)
```

### 3-2. 가격 비교표

```
## 가격 비교

| 플랜        | 우리 제품  | Notion   | Coda     | Monday   |
|-------------|----------|----------|----------|----------|
| Free        | ✅ 있음   | ✅ 있음  | ✅ 있음   | ✅ 있음  |
| Team/Pro    | $10/월   | $10/월   | $12/월   | $9/월    |
| Business    | $20/월   | $18/월   | $22/월   | $16/월   |
| Enterprise  | 문의     | 문의     | 문의      | 문의     |
```

---

## Phase 4: 분석

### 4-1. researcher-strategist 에이전트 전략 분석

```typescript
analysis_result = Agent("researcher-strategist", `
다음 경쟁 분석 데이터를 기반으로 전략 분석을 수행해줘.

우리 제품 정보:
{our_product_info}

경쟁사 구조화 데이터:
{structured_data}

기능 비교 매트릭스:
{feature_matrix}

가격 비교:
{pricing_comparison}

분석 모드: {analysis_mode}  // 'full' 또는 'feature_focus: {target_feature}'

아래 4가지를 작성해줘:

## 1. SWOT 분석

### Strengths (강점)
- {경쟁사 대비 우리가 명확히 우위인 영역}
  - 근거: {매트릭스 데이터 참조}

### Weaknesses (약점)
- {경쟁사 대비 열위인 영역}
  - 근거: {매트릭스 데이터 참조}
  - 영향도: HIGH/MEDIUM/LOW

### Opportunities (기회)
- {시장에서 아직 채워지지 않은 니즈}
  - 경쟁사 현황: {어떤 경쟁사도 강하지 않은 영역}

### Threats (위협)
- {경쟁사가 빠르게 강화하고 있는 영역}
  - 대응 시급성: HIGH/MEDIUM/LOW

## 2. 포지셔닝 맵

2x2 포지셔닝 맵을 텍스트로 표현:
- X축: {가장 차별적인 축 선택, 예: 기능 복잡도}
- Y축: {두 번째 축, 예: 가격}
- 각 제품의 위치와 이유

## 3. 차별화 기회

### 즉시 실행 가능 (3개월 이내)
1. {기회}: {구체적 액션} — 예상 임팩트: HIGH/MEDIUM

### 중기 (3-6개월)
1. {기회}: {구체적 액션} — 예상 임팩트: HIGH/MEDIUM

### 장기 (6개월+)
1. {기회}: {구체적 액션} — 예상 임팩트: HIGH/MEDIUM

## 4. 추천 전략 (우선순위순)

1. **{전략명}**: {구체적 실행 방안}
   - 타겟 경쟁사: {누구를 이기기 위한 전략인지}
   - 필요 리소스: {예상 투입}
   - 기대 효과: {정량적 목표}

2. **{전략명}**: ...

feature_focus 모드인 경우, 모든 분석을 '${target_feature}' 기능에 집중해줘.
`)
```

### 4-2. 결과 통합

```typescript
// SWOT, 포지셔닝, 차별화 기회를 하나의 문서로 통합
analysis_result = {
  swot: strategist_output.swot,
  positioning: strategist_output.positioning,
  differentiation: strategist_output.differentiation,
  recommendations: strategist_output.recommendations
}
```

---

## Phase 5: 저장

### 5-1. content-writer 에이전트 문서 작성

```typescript
Bash("mkdir -p plans")

Agent("content-writer", `
다음 경쟁 분석 결과를 최종 보고서로 작성해줘.

경쟁사 데이터: {structured_data}
기능 매트릭스: {feature_matrix}
가격 비교: {pricing_comparison}
전략 분석: {analysis_result}
분석 모드: {analysis_mode}
분석일: {current_date}

파일 경로: plans/competitive-analysis-{YYYY-MM-DD}.md

아래 형식으로 Write 도구를 사용해 저장해줘:

---

# 경쟁 분석 보고서

- 작성일: {YYYY-MM-DD}
- 분석 대상: {경쟁사 목록}
- 분석 모드: {전체 분석 / 기능 집중: {feature}}

## 요약 (Executive Summary)
{3-5줄 핵심 요약: 주요 발견, 우리 포지션, 핵심 추천}

## 1. 경쟁사 개요
| 회사 | 주요 제품 | 타겟 고객 | 추정 규모 | 핵심 강점 |
|------|-----------|----------|----------|----------|

## 2. 기능 비교 매트릭스
{Phase 3 매트릭스}

## 3. 가격 비교
{Phase 3 가격표}

## 4. SWOT 분석
{Phase 4 SWOT}

## 5. 포지셔닝 맵
{Phase 4 포지셔닝}

## 6. 차별화 기회
{Phase 4 차별화}

## 7. 추천 전략
{Phase 4 추천 전략}

## 8. 데이터 신뢰도
| 경쟁사 | 데이터 충분도 | 주요 출처 | 추가 조사 필요 |
|--------|-------------|----------|--------------|

## 부록: 원시 데이터 출처
- {URL 또는 출처 목록}

---
`)
```

### 5-2. 완료 메시지

```
분석 완료!

파일: plans/competitive-analysis-{YYYY-MM-DD}.md
경쟁사: {competitors.join(", ")}
모드: {analysis_mode === "feature_focus" ? `기능 집중: ${target_feature}` : "전체 분석"}

주요 발견:
- 강점: {top strength}
- 약점: {top weakness}
- 핵심 기회: {top opportunity}

다음 단계:
- /prd 로 차별화 기능 PRD 작성
- /roadmap 로 전략 로드맵 반영
- /okr 로 전략 목표 설정
```

---

## 예외 처리

### WebSearch 실패

```typescript
// 검색이 전혀 안 되는 경우
if (all_search_failed) {
  console.log(`
  ⚠️  웹 검색 실패. 네트워크 또는 WebSearch 도구 상태를 확인하세요.

  대안:
  1. 경쟁사 웹사이트 URL을 직접 제공해주세요 → WebFetch로 수집
  2. 기존 분석 문서가 있다면 해당 데이터를 기반으로 분석
  `)
}
```

### 경쟁사 정보 부족

```typescript
// 특정 경쟁사 데이터가 불충분한 경우
if (insufficient_data_competitors.length > 0) {
  AskUserQuestion({
    question: `다음 경쟁사의 데이터가 부족합니다: ${insufficient_data_competitors.join(", ")}`,
    header: "데이터 부족",
    options: [
      {
        label: "가용 데이터로 진행",
        description: "불충분한 항목은 '미확인'으로 표기"
      },
      {
        label: "추가 정보 제공",
        description: "URL이나 문서를 직접 제공"
      },
      {
        label: "해당 경쟁사 제외",
        description: "분석 대상에서 제거"
      }
    ]
  })
}
```

---

## 주의사항

### 금지사항
- ❌ 검증되지 않은 수치를 확정적으로 서술 금지 (반드시 '~' 또는 '추정' 표기)
- ❌ 출처 없는 주장 금지 (모든 데이터에 출처 명시)
- ❌ 오래된 데이터 사용 금지 (1년 이상 전 데이터는 경고 표기)

### 권장사항
- ✅ 경쟁사 3-5개가 최적 (너무 많으면 분석 깊이 저하)
- ✅ `--feature` 모드는 특정 기능 의사결정 시 사용
- ✅ 분기 1회 이상 업데이트 권장
- ✅ 분석 후 `/prd` 또는 `/roadmap`과 연계

---

## Examples

### 예시 1: 전체 분석
```
/competitive-analysis Notion Coda Monday
```
→ 3개 경쟁사 전체 기능/가격/SWOT 분석 → `plans/competitive-analysis-2026-03-14.md`

### 예시 2: 기능 집중 분석
```
/competitive-analysis --feature AI 자동화 Notion Coda
```
→ "AI 자동화" 기능만 심층 비교 → 세부 항목별 강도 평가

### 예시 3: 대화형
```
/competitive-analysis
→ "분석할 경쟁사를 입력하세요"
→ "Figma, Sketch, Adobe XD"
→ 분석 실행
```
