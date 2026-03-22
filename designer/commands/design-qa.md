---
description: 시안 vs 구현물 시각 QA. Figma 스펙 대비 구현 차이점 분석.
---

# Design QA — 시안 대비 구현 검증

## Usage

```
/design-qa                       → 현재 Figma 선택 노드와 구현물 비교
/design-qa --url <url>           → 배포 URL과 Figma 선택 노드 비교
/design-qa --component <name>    → 특정 컴포넌트의 스펙 대비 구현 차이
```

## 전제 조건
- Figma Desktop 앱에서 비교할 노드를 선택한 상태
- Dev Mode MCP 서버 실행 중 (localhost:3845)

> **Figma MCP 미연결 시**: "Figma MCP에 연결할 수 없습니다. 다음 대안을 사용하세요:" → 스크린샷/디자인 스펙을 직접 제공하거나, `--component` 모드로 소스 코드 기반 분석만 진행.

## 실행 절차

### Phase 1: Figma 스펙 수집

```typescript
// Figma에서 현재 선택된 노드의 디자인 스펙 추출
const design_spec = mcp__figma-dev-mode-mcp-server__get_design_context()
const variables = mcp__figma-dev-mode-mcp-server__get_variable_defs()
const metadata = mcp__figma-dev-mode-mcp-server__get_metadata()

// 스펙에서 핵심 속성 파싱
spec = {
  colors: [...],      // fills, strokes
  typography: [...],   // fontSize, fontWeight, lineHeight, fontFamily
  spacing: [...],      // padding, gap, margin
  sizing: [...],       // width, height, constraints
  radius: [...],       // cornerRadius
  shadows: [...],      // effects
  layout: [...]        // layoutMode, alignment
}
```

### Phase 2: 구현물 속성 수집

```typescript
// --url 모드: Playwright로 렌더링된 페이지에서 computed styles 추출
mcp__playwright__browser_navigate({ url: target_url })
const screenshot = mcp__playwright__browser_take_screenshot()

// 대응되는 요소의 computed style 추출
// 셀렉터 전략: 사용자에게 CSS 셀렉터를 질문하거나, Playwright snapshot으로 요소 탐색
// (data-component 등 특정 속성에 의존하지 않음)
const computed = mcp__playwright__browser_evaluate({
  expression: `
    // 셀렉터 우선순위: 사용자 지정 > data-testid > role+name > className
    const el = document.querySelector('${user_selector}')
              || document.querySelector('[data-testid="${component_name}"]')
              || document.querySelector('[class*="${component_name}"]');
    if (!el) return { error: '요소를 찾을 수 없습니다. CSS 셀렉터를 직접 지정해주세요.' };
    const styles = getComputedStyle(el);
    return {
      color: styles.color,
      fontSize: styles.fontSize,
      fontWeight: styles.fontWeight,
      lineHeight: styles.lineHeight,
      padding: styles.padding,
      gap: styles.gap,
      borderRadius: styles.borderRadius,
      boxShadow: styles.boxShadow,
      width: el.offsetWidth,
      height: el.offsetHeight
    };
  `
})
```

```typescript
// --component 모드: 소스 코드에서 직접 추출
// Grep으로 컴포넌트 파일 찾기 → Tailwind 클래스/CSS 값 파싱
component_files = Glob("**/components/**/{name}*.{tsx,jsx}")
source_styles = Read(component_files[0])  // className에서 Tailwind 클래스 추출
```

### Phase 3: 차이 분석

비교 항목별 허용 오차:

| 항목 | 허용 오차 | 판정 |
|------|-----------|------|
| 색상 (hex) | ±0 | EXACT 매칭 필요 |
| 폰트 사이즈 | ±1px | PASS |
| 폰트 웨이트 | ±0 | EXACT |
| 행간 (lineHeight) | ±2px | PASS |
| 패딩/마진 | ±2px | PASS (8px 그리드 snap 결과 차이 허용) |
| 간격 (gap) | ±2px | PASS |
| 모서리 반경 | ±1px | PASS |
| 크기 (width/height) | ±4px | PASS (반응형 차이 허용) |
| 그림자 | blur/spread ±2px, offset ±1px | PASS |

### Phase 4: 보고서 출력

출력 형식:
```markdown
# Design QA Report

## 비교 대상
- Figma: [노드명] (FileKey/NodeId)
- 구현: [URL 또는 컴포넌트 경로]

## 차이점 요약
| 항목 | Figma 스펙 | 구현 값 | 차이 | 판정 |
|------|-----------|---------|------|------|
| 배경색 | #6366F1 | #6366F1 | 0 | ✅ PASS |
| 폰트 사이즈 | 16px | 14px | -2px | ❌ FAIL |
| 패딩 top | 24px | 24px | 0 | ✅ PASS |
| gap | 16px | 12px | -4px | ❌ FAIL |
| border-radius | 8px | 8px | 0 | ✅ PASS |
| box-shadow | 0 4px 6px rgba(0,0,0,0.1) | none | — | ❌ FAIL |

## 스크린샷 비교
[Playwright 캡처 이미지]

## 수정 제안
1. `text-sm` → `text-base` (Card.tsx:23)
2. `gap-3` → `gap-4` (Card.tsx:15)
3. `shadow-md` 추가 (Card.tsx:14)
```

## 주의사항
- `--url` 없이 실행하면 소스 코드 정적 분석만 수행 (computed style 비교 불가)
- Figma Desktop에서 노드 선택이 안 되어 있으면 get_design_context가 빈 결과 반환 → 안내 메시지 출력
- Figma 반응형 설정(constraints)과 실제 CSS 반응형(media query/container query)은 1:1 대응 불가 → 동일 뷰포트에서만 비교
- 폰트 렌더링은 OS/브라우저별 차이가 있으므로 fontFamily 비교는 이름 매칭만 수행
