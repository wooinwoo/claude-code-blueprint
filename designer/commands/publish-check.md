---
description: 퍼블리시 전 최종 점검. Lighthouse 자동 분석 + 반응형/접근성/성능/SEO 체크리스트 실행.
---

# Publish Check — 배포 전 점검

## Usage

```
/publish-check                    → 소스 코드 정적 분석 + Playwright 검증
/publish-check --url <url>        → 배포된 URL Lighthouse 분석 + Playwright 검증
/publish-check --url <url> --full → Lighthouse + Playwright + 소스 정적 분석 전체
```

## 실행 절차

### Phase 1: Lighthouse 분석 (`--url` 지정 시)

URL이 주어지면 Lighthouse CLI로 자동 점수 수집한다.

```typescript
// Lighthouse CLI 실행
const lh_result = Bash("npx lighthouse ${url} --output=json --output-path=./lighthouse-report.json --chrome-flags='--headless --no-sandbox'")

// Chrome 미설치 시 Playwright 폴백
if (lh_result.error && lh_result.error.includes('Chrome')) {
  console.log("⚠️ Chrome/Lighthouse 미설치 — Playwright MCP로 기본 성능 체크 진행")

  // Playwright로 대체 성능 측정
  mcp__playwright__browser_navigate({ url })
  const perf = mcp__playwright__browser_evaluate({
    expression: `JSON.stringify({
      domContentLoaded: performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart,
      load: performance.timing.loadEventEnd - performance.timing.navigationStart,
      domNodes: document.querySelectorAll('*').length,
      images: document.querySelectorAll('img').length,
      imagesWithoutAlt: document.querySelectorAll('img:not([alt])').length,
      scripts: document.querySelectorAll('script').length,
      stylesheets: document.querySelectorAll('link[rel="stylesheet"]').length
    })`
  })

  // 기본 성능 리포트 출력 (Lighthouse 대체)
  console.log(`
  ⚡ 기본 성능 체크 (Playwright)
  DOMContentLoaded: ${perf.domContentLoaded}ms ${perf.domContentLoaded > 3000 ? '❌' : '✅'}
  Load: ${perf.load}ms ${perf.load > 5000 ? '❌' : '✅'}
  DOM 노드 수: ${perf.domNodes} ${perf.domNodes > 1500 ? '⚠️ 과다' : '✅'}
  이미지: ${perf.images}개 (alt 누락: ${perf.imagesWithoutAlt}개)
  `)
  // Phase 2로 계속 진행
}

// JSON 파싱
const report = Read("./lighthouse-report.json")
const scores = {
  performance: report.categories.performance.score * 100,
  accessibility: report.categories.accessibility.score * 100,
  bestPractices: report.categories['best-practices'].score * 100,
  seo: report.categories.seo.score * 100
}

// 주요 메트릭 추출
const metrics = {
  FCP: report.audits['first-contentful-paint'].displayValue,
  LCP: report.audits['largest-contentful-paint'].displayValue,
  TBT: report.audits['total-blocking-time'].displayValue,
  CLS: report.audits['cumulative-layout-shift'].displayValue,
  SI:  report.audits['speed-index'].displayValue
}
```

Lighthouse JSON에서 추출하는 핵심 지표:

- **Performance**: FCP, LCP, TBT, CLS, Speed Index
- **Accessibility**: 점수 + 개별 audit 결과 (contrast, alt 누락, ARIA 등)
- **Best Practices**: HTTPS, 콘솔 에러, 이미지 비율, deprecated API
- **SEO**: meta 태그, crawlable, mobile-friendly, structured data

점수 기준:
| 범위 | 판정 |
|------|------|
| 90-100 | ✅ GOOD |
| 50-89 | ⚠️ NEEDS IMPROVEMENT |
| 0-49 | ❌ POOR |

---

### Phase 2: Playwright 시각 검증

3개 뷰포트에서 스크린샷 캡처 및 레이아웃/접근성 확인한다.

```typescript
const viewports = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1280, height: 800 }
]

for (const vp of viewports) {
  mcp__playwright__browser_resize({ width: vp.width, height: vp.height })
  mcp__playwright__browser_navigate({ url: target_url })
  const screenshot = mcp__playwright__browser_take_screenshot({ name: `publish-check-${vp.name}` })

  // 가로 스크롤 체크 — overflow-x 깨짐 감지
  const hasHorizontalScroll = mcp__playwright__browser_evaluate({
    expression: "document.documentElement.scrollWidth > document.documentElement.clientWidth"
  })

  // 터치 타겟 크기 체크 (모바일만 — WCAG 2.5.5 기준 44×44px)
  if (vp.name === 'mobile') {
    const smallTargets = mcp__playwright__browser_evaluate({
      expression: `
        [...document.querySelectorAll('a, button, input, select, textarea, [role="button"]')]
          .filter(el => {
            const rect = el.getBoundingClientRect();
            return rect.width < 44 || rect.height < 44;
          })
          .map(el => ({
            tag: el.tagName,
            text: el.textContent?.slice(0, 30),
            width: el.offsetWidth,
            height: el.offsetHeight
          }))
      `
    })
  }

  // 콘텐츠 잘림/겹침 감지
  const overflowIssues = mcp__playwright__browser_evaluate({
    expression: `
      [...document.querySelectorAll('*')]
        .filter(el => {
          const style = getComputedStyle(el);
          return style.overflow === 'hidden' && el.scrollWidth > el.clientWidth;
        })
        .slice(0, 10)
        .map(el => ({ tag: el.tagName, class: el.className?.toString().slice(0, 50) }))
    `
  })
}
```

키보드 접근성 검증:

```typescript
// Tab 키로 포커스 순회 테스트
mcp__playwright__browser_press_key({ key: "Tab" })
const focusedEl = mcp__playwright__browser_evaluate({
  expression: `(() => {
    const el = document.activeElement;
    return {
      tag: el.tagName,
      text: el.textContent?.slice(0, 30),
      hasOutline: getComputedStyle(el).outlineStyle !== 'none'
    }
  })()`
})
// focus outline이 보이지 않으면 경고
// 주요 인터랙티브 요소(링크, 버튼, 입력)까지 Tab으로 도달 가능한지 확인
```

검증 항목 요약:

| 뷰포트 | 검증 내용 |
|---------|-----------|
| **mobile** (375×812) | 가로 스크롤, 오버플로우, 터치 타겟 44px, 텍스트 가독성 |
| **tablet** (768×1024) | 그리드 전환, 네비게이션 변형, 이미지 비율 |
| **desktop** (1280×800) | 전체 레이아웃, 여백, max-width 적용 |

---

### Phase 3: 소스 정적 분석

Grep/Read로 소스 코드에서 직접 패턴을 검색한다.

#### 접근성

```typescript
// img alt 누락 (JSX self-closing /> 대응)
const img_no_alt = Grep({ pattern: '<img\\b(?![^/]*alt=)', glob: '*.{tsx,jsx,html}' })

// onClick만 있고 onKeyDown 없는 비인터랙티브 요소
// JSX는 멀티라인이므로 단일 Grep으로 잡기 어려움 → 2단계 접근
// Step 1: onClick이 있는 div/span 파일 목록
const files_with_click = Grep({ pattern: 'onClick', glob: '*.{tsx,jsx}', output_mode: 'files_with_matches' })
// Step 2: 각 파일을 Read하여 해당 컴포넌트에 onKeyDown/onKeyUp/role이 있는지 확인
// onKeyDown 없으면 접근성 이슈로 보고

// heading 레벨 건너뜀 감지
const h1 = Grep({ pattern: '<h1|<H1', glob: '*.{tsx,jsx,html}' })
const h2 = Grep({ pattern: '<h2|<H2', glob: '*.{tsx,jsx,html}' })
const h3 = Grep({ pattern: '<h3|<H3', glob: '*.{tsx,jsx,html}' })
// h1 없이 h2가 있거나, h2 없이 h3가 있으면 경고

// aria-label 없는 icon-only 버튼
const icon_btn = Grep({ pattern: '<button[^>]*>\\s*<(svg|img|Icon)', glob: '*.{tsx,jsx}' })
```

#### 성능

```typescript
// 이미지 lazy loading 누락
const img_no_lazy = Grep({ pattern: '<img(?![^>]*loading=)[^>]*>', glob: '*.{tsx,jsx,html}' })

// 이미지 srcSet 미적용 (반응형 이미지)
const img_no_srcset = Grep({ pattern: '<img(?![^>]*srcSet|srcset)[^>]*>', glob: '*.{tsx,jsx,html}' })

// webp/avif 미사용 (jpg/png 직접 참조)
const legacy_img = Grep({ pattern: 'src=.*\\.(jpg|png|jpeg)"', glob: '*.{tsx,jsx,html}' })

// 폰트 display swap 미적용
const font_no_swap = Grep({ pattern: '@font-face(?![^}]*font-display)', glob: '*.{css,scss}' })

// 폰트 preload 확인
const font_preload = Grep({ pattern: 'rel="preload".*as="font"', glob: '*.{tsx,jsx,html}' })
```

#### SEO

```typescript
// 필수 메타 태그 존재 확인
const has_title = Grep({ pattern: '<title>', glob: '*.{tsx,jsx,html}' })
const has_meta_desc = Grep({ pattern: 'meta.*name="description"', glob: '*.{tsx,jsx,html}' })
const has_og = Grep({ pattern: 'property="og:', glob: '*.{tsx,jsx,html}' })
const has_twitter = Grep({ pattern: 'name="twitter:', glob: '*.{tsx,jsx,html}' })

// canonical URL
const has_canonical = Grep({ pattern: 'rel="canonical"', glob: '*.{tsx,jsx,html}' })

// sitemap, robots.txt 존재
const has_sitemap = Glob({ pattern: '**/sitemap.xml' })
const has_robots = Glob({ pattern: '**/robots.txt' })

// 구조화된 데이터 (JSON-LD)
const has_jsonld = Grep({ pattern: 'application/ld\\+json', glob: '*.{tsx,jsx,html}' })
```

---

## 출력 형식

```markdown
# Publish Check Report

## Lighthouse Scores (URL: ...)
| 카테고리 | 점수 | 주요 이슈 |
|----------|------|-----------|
| Performance | 92 | LCP 2.1s (PASS) |
| Accessibility | 85 | 3개 contrast 이슈 |
| Best Practices | 100 | — |
| SEO | 91 | og:image 누락 |

### Core Web Vitals
| 메트릭 | 값 | 기준 | 판정 |
|--------|-----|------|------|
| FCP | 1.2s | < 1.8s | ✅ |
| LCP | 2.1s | < 2.5s | ✅ |
| TBT | 120ms | < 200ms | ✅ |
| CLS | 0.05 | < 0.1 | ✅ |

## 반응형 검증
| 뷰포트 | 상태 | 이슈 |
|--------|------|------|
| mobile (375) | ✅ | — |
| tablet (768) | ⚠️ | 네비게이션 잘림 |
| desktop (1280) | ✅ | — |

## 소스 분석
| 항목 | 상태 | 세부 |
|------|------|------|
| img alt | ⚠️ WARN | 2개 누락 (Card.tsx:15, Hero.tsx:8) |
| 키보드 접근성 | ✅ PASS | — |
| heading 구조 | ✅ PASS | h1→h2→h3 순서 정상 |
| 이미지 최적화 | ❌ FAIL | 3개 파일 srcSet 미적용 |
| 폰트 최적화 | ✅ PASS | display:swap 적용 |
| SEO meta | ✅ PASS | title, description, og 모두 존재 |
| sitemap/robots | ⚠️ WARN | robots.txt 없음 |
```

---

## 주의사항

- `--url` 없이 실행 시 Phase 1(Lighthouse) 스킵, Phase 2-3만 실행
- Lighthouse 실행에는 Chrome이 설치되어 있어야 함. Chrome 미설치 시 Phase 1 스킵하고 Phase 2-3만 진행
- 로컬 dev server URL(`localhost:3000`)도 분석 가능
- Lighthouse 미설치 시 첫 실행에서 `npx lighthouse`가 자동 설치 (약 50MB)
- Phase 2 Playwright는 MCP 서버가 연결되어 있어야 동작. 미연결 시 Phase 2 스킵
- 보고서의 각 항목은 PASS/WARN/FAIL 3단계로 표시. FAIL이 1개 이상이면 배포 재고 권장
