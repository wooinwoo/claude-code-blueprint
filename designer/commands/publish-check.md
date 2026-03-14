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

URL이 주어지면 Lighthouse CLI로 자동 점수 수집:

```bash
npx lighthouse <url> --output=json --output-path=./lighthouse-report.json --chrome-flags="--headless --no-sandbox"
```

Lighthouse JSON에서 핵심 지표 추출:
- **Performance**: FCP, LCP, TBT, CLS, Speed Index
- **Accessibility**: 점수 + 개별 audit 결과
- **Best Practices**: HTTPS, 콘솔 에러, 이미지 비율
- **SEO**: meta, crawlable, mobile-friendly

### Phase 2: Playwright 시각 검증

3개 뷰포트에서 스크린샷 캡처 및 레이아웃 확인:
- **mobile** (375×812) — 가로 스크롤, 오버플로우, 터치 타겟 44px
- **tablet** (768×1024) — 그리드 전환, 네비게이션 변형
- **desktop** (1280×800) — 전체 레이아웃, 여백

키보드 접근성: Tab 키로 주요 인터랙티브 요소 순회 테스트

### Phase 3: 소스 정적 분석

Grep/Read로 소스 코드에서 직접 확인:

**접근성**
- `<img` 태그에 `alt` 속성 누락
- `onClick`만 있고 `onKeyDown` 없는 `<div>`/`<span>`
- heading 레벨 건너뜀 (h1→h3)

**성능**
- 이미지: webp/avif format, `srcSet`, `loading="lazy"` 적용 여부
- 폰트: `display: swap`, `preload` 적용 여부
- 대형 인라인 스타일, 미사용 import

**SEO**
- `<title>`, `<meta name="description">`, `og:*` 태그 존재
- `sitemap.xml`, `robots.txt` 존재
- canonical URL 설정

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
| 이미지 최적화 | ❌ FAIL | 3개 파일 srcSet 미적용 |
| SEO meta | ✅ PASS | — |
```

## 주의사항
- `--url` 없이 실행 시 Phase 1(Lighthouse) 스킵, Phase 2-3만 실행
- Lighthouse 실행에는 Chrome이 설치되어 있어야 함. Chrome 미설치 시 Phase 1 스킵하고 Phase 2-3만 진행
- 로컬 dev server URL(`localhost:3000`)도 분석 가능
- Lighthouse 미설치 시 첫 실행에서 `npx lighthouse`가 자동 설치 (약 50MB)
