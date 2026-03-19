---
description: Lighthouse 성능/접근성/SEO 분석. 주요 페이지별 점수 체크 + 종합 리포트.
---

# Lighthouse — 페이지별 웹 성능 분석

## Usage

```
/lighthouse                          → 라우트 자동 탐지 + 전체 페이지 분석
/lighthouse --url http://localhost:3000  → 특정 URL부터 시작
/lighthouse --pages /,/login,/dashboard → 특정 페이지만 분석
/lighthouse --threshold 80            → 기준 점수 변경 (기본: 80)
```

---

## Phase 1: 라우트 수집

### 1-1. 개발 서버 확인

```typescript
// 흔한 dev 서버 포트 순서대로 체크
const ports = [3000, 5173, 5174, 4200, 8080, 8000]
let baseUrl = null

for (const port of ports) {
  const status = Bash(`curl -s -o /dev/null -w '%{http_code}' http://localhost:${port}`)
  if (status === "200") {
    baseUrl = `http://localhost:${port}`
    break
  }
}

if (!baseUrl) {
  console.log("⚠️ 실행 중인 dev 서버를 찾을 수 없습니다.")
  console.log("dev 서버를 먼저 실행하거나, --url 옵션으로 URL을 지정하세요.")
  // 종료
}
```

### 1-2. 라우트 자동 탐지

`--pages`가 없으면 프로젝트에서 라우트를 자동 수집합니다.

```typescript
// 프레임워크별 라우트 파일 탐색
const routeFiles = [
  // Next.js App Router
  ...Glob("app/**/page.{tsx,jsx,ts,js}"),
  // Next.js Pages Router
  ...Glob("pages/**/*.{tsx,jsx,ts,js}"),
  // TanStack Router (file-based)
  ...Glob("src/routes/**/*.{tsx,jsx,ts,js}"),
  // React Router (config-based)
  ...Glob("src/router.{tsx,jsx,ts,js}"),
  ...Glob("src/routes.{tsx,jsx,ts,js}"),
  ...Glob("src/app/router.{tsx,jsx,ts,js}"),
  // Vite + React 일반
  ...Glob("src/pages/**/*.{tsx,jsx,ts,js}")
]

// 파일 경로 → URL 경로 변환
// app/dashboard/page.tsx → /dashboard
// pages/auth/login.tsx → /auth/login
// src/routes/settings.tsx → /settings
// _layout, _error, _404 등 제외
```

### 1-3. 페이지 선별

```typescript
// 동적 라우트([id], $id 등)는 제외 (접근 불가)
// 레이아웃/에러 페이지 제외
// 최대 20페이지 (초과 시 사용자에게 선택 요청)

if (pages.length > 20) {
  AskUserQuestion([{
    question: `${pages.length}개 페이지가 발견되었습니다. 분석할 페이지를 선택하세요.`,
    header: "페이지 선택",
    description: pages.map((p, i) => `${i+1}. ${p}`).join('\n'),
    options: [
      { label: "전체 분석", description: "모든 페이지 (시간 오래 걸림)" },
      { label: "상위 10개만", description: "라우트 깊이 얕은 순" },
      { label: "직접 선택", description: "번호로 선택" }
    ]
  }])
}

console.log(`\n📋 분석 대상: ${pages.length}개 페이지`)
pages.forEach(p => console.log(`  - ${p}`))
```

---

## Phase 2: Lighthouse 실행

### 2-1. 페이지별 분석

```typescript
const results = []
const threshold = args.threshold || 80

for (const page of pages) {
  const url = `${baseUrl}${page}`
  console.log(`\n⏳ 분석 중: ${page}`)

  try {
    Bash(`npx lighthouse ${url} --output=json --output-path=./lighthouse-${page.replace(/\//g, '_')}.json --chrome-flags='--headless --no-sandbox' --only-categories=performance,accessibility,best-practices,seo --quiet`)

    const report = JSON.parse(Read(`./lighthouse-${page.replace(/\//g, '_')}.json`))
    const scores = {
      page,
      performance: Math.round(report.categories.performance.score * 100),
      accessibility: Math.round(report.categories.accessibility.score * 100),
      bestPractices: Math.round(report.categories['best-practices'].score * 100),
      seo: Math.round(report.categories.seo.score * 100),
      lcp: report.audits['largest-contentful-paint']?.displayValue || 'N/A',
      fid: report.audits['max-potential-fid']?.displayValue || 'N/A',
      cls: report.audits['cumulative-layout-shift']?.displayValue || 'N/A',
      fcp: report.audits['first-contentful-paint']?.displayValue || 'N/A',
      tbt: report.audits['total-blocking-time']?.displayValue || 'N/A'
    }

    results.push(scores)

    // 진행 상황 출력
    const status = (s) => s >= 90 ? '🟢' : s >= threshold ? '🟡' : '🔴'
    console.log(`  ${status(scores.performance)} Performance: ${scores.performance}  ${status(scores.accessibility)} A11y: ${scores.accessibility}  ${status(scores.bestPractices)} BP: ${scores.bestPractices}  ${status(scores.seo)} SEO: ${scores.seo}`)

  } catch (error) {
    console.log(`  ❌ 실패: ${error.message}`)
    results.push({ page, error: error.message })
  }
}

// 임시 파일 정리
Bash("rm -f ./lighthouse-*.json")
```

### 2-2. Chrome/Lighthouse 없을 때 폴백

```typescript
// Lighthouse CLI 실패 시 Playwright MCP로 기본 측정
if (lighthouse_failed) {
  console.log("⚠️ Chrome/Lighthouse 미설치. Playwright 기본 측정으로 대체합니다.")

  for (const page of pages) {
    mcp__playwright__browser_navigate({ url: `${baseUrl}${page}` })
    const perf = mcp__playwright__browser_evaluate({
      expression: `JSON.stringify({
        domContentLoaded: performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart,
        load: performance.timing.loadEventEnd - performance.timing.navigationStart,
        domNodes: document.querySelectorAll('*').length,
        images: document.querySelectorAll('img').length,
        imagesNoAlt: document.querySelectorAll('img:not([alt])').length
      })`
    })

    results.push({
      page,
      domContentLoaded: perf.domContentLoaded,
      load: perf.load,
      domNodes: perf.domNodes,
      mode: 'playwright-fallback'
    })
  }
}
```

---

## Phase 3: 종합 리포트

```markdown
# Lighthouse Report

## 요약

| 지표 | 평균 | 최저 페이지 | 기준 |
|------|------|------------|------|
| Performance | {avg}점 | {worst_page} ({score}점) | {threshold}점 |
| Accessibility | {avg}점 | {worst_page} ({score}점) | {threshold}점 |
| Best Practices | {avg}점 | {worst_page} ({score}점) | {threshold}점 |
| SEO | {avg}점 | {worst_page} ({score}점) | {threshold}점 |

## 페이지별 상세

| 페이지 | Perf | A11y | BP | SEO | LCP | FCP | TBT | CLS |
|--------|------|------|----|-----|-----|-----|-----|-----|
| / | 92 🟢 | 98 🟢 | 100 🟢 | 90 🟢 | 1.2s | 0.8s | 120ms | 0.01 |
| /dashboard | 64 🔴 | 85 🟡 | 92 🟢 | 80 🟡 | 3.4s | 1.5s | 450ms | 0.12 |
| /auth/login | 88 🟡 | 100 🟢 | 100 🟢 | 95 🟢 | 1.8s | 0.9s | 80ms | 0.00 |

## 기준 미달 페이지

### /dashboard (Performance: 64점 🔴)

| 항목 | 값 | 권장 |
|------|-----|------|
| LCP | 3.4s | < 2.5s |
| TBT | 450ms | < 200ms |
| CLS | 0.12 | < 0.1 |

**주요 원인:**
- 대형 JavaScript 번들 (분석 차트 라이브러리)
- 렌더 블로킹 리소스 3개
- 이미지 lazy loading 미적용

**개선 제안:**
1. 차트 라이브러리 dynamic import 적용
2. 렌더 블로킹 CSS를 critical CSS로 분리
3. `<img loading="lazy">` 적용

## Core Web Vitals 요약

| 지표 | 양호 | 개선 필요 | 나쁨 | 기준 |
|------|------|-----------|------|------|
| LCP | {n}개 | {n}개 | {n}개 | < 2.5s |
| FID/TBT | {n}개 | {n}개 | {n}개 | < 200ms |
| CLS | {n}개 | {n}개 | {n}개 | < 0.1 |
```

---

## 판정 기준

| 점수 | 상태 | 의미 |
|------|------|------|
| 90-100 | 🟢 | 양호 |
| {threshold}-89 | 🟡 | 개선 권장 |
| 0-{threshold-1} | 🔴 | 개선 필요 |

### Core Web Vitals 기준

| 지표 | 양호 | 개선 필요 | 나쁨 |
|------|------|-----------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| FID (First Input Delay) | ≤ 100ms | ≤ 300ms | > 300ms |
| TBT (Total Blocking Time) | ≤ 200ms | ≤ 600ms | > 600ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |
| FCP (First Contentful Paint) | ≤ 1.8s | ≤ 3.0s | > 3.0s |

---

## 주의사항

- dev 서버 기준 측정이므로 프로덕션 점수와 다를 수 있습니다 (dev는 보통 더 느림)
- 동적 라우트 (`[id]`, `$id`)는 자동 탐지에서 제외됩니다. `--pages`로 직접 지정하세요
- SSR/SSG 페이지는 빌드 후 `--url`로 프로덕션 서버를 지정하는 게 더 정확합니다
- Lighthouse는 네트워크/CPU throttling을 적용하므로 실제 체감과 다를 수 있습니다
