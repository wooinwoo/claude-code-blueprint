---
name: web-design-guidelines
description: Use this skill for comprehensive web design guidelines including layout systems, typography scales, color systems, and responsive design patterns.
---

# Web Design Guidelines Skill

웹 디자인 가이드라인. 레이아웃 시스템, 타이포그래피 스케일, 색상 시스템.

## When to Activate

- 프로젝트 초기 디자인 시스템 설정
- 타이포그래피/컬러 스케일 정의
- 그리드 시스템 설계
- 디자인 문서 작성

## Layout System

### Container
```css
.container {
  --max-width: 1280px;
  --padding: clamp(1rem, 5vw, 3rem);
  width: min(var(--max-width), 100% - var(--padding) * 2);
  margin-inline: auto;
}
```

### Grid
- 12-column grid (데스크톱)
- 4-column grid (모바일)
- Gutter: 16px (모바일), 24px (태블릿), 32px (데스크톱)

## Typography Scale

```css
:root {
  --font-size-xs: clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);
  --font-size-sm: clamp(0.875rem, 0.8rem + 0.375vw, 1rem);
  --font-size-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
  --font-size-lg: clamp(1.125rem, 1rem + 0.625vw, 1.25rem);
  --font-size-xl: clamp(1.25rem, 1rem + 1.25vw, 1.75rem);
  --font-size-2xl: clamp(1.5rem, 1rem + 2.5vw, 2.5rem);
  --font-size-3xl: clamp(2rem, 1.5rem + 2.5vw, 3.5rem);
}
```

## Color System

### Semantic Colors
```css
:root {
  --color-text-primary: oklch(20% 0 0);
  --color-text-secondary: oklch(40% 0 0);
  --color-bg-primary: oklch(100% 0 0);
  --color-bg-secondary: oklch(97% 0 0);
  --color-border: oklch(90% 0 0);
  --color-accent: oklch(55% 0.25 265);
}
```

### Color Palette Generation
- 1개의 브랜드 컬러에서 시작
- oklch로 명도 스케일 생성 (50~950)
- 시맨틱 용도별 매핑 (primary, success, warning, error, info)

## 모던 CSS 패턴

### 1. Container Queries

부모 컨테이너 크기에 따라 컴포넌트 스타일을 변경. 미디어 쿼리가 뷰포트 기준인 것과 달리, 컴포넌트가 실제로 배치된 공간에 반응한다.

```css
.card-container {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card { flex-direction: row; }
}

@container card (min-width: 700px) {
  .card { grid-template-columns: 1fr 2fr; }
}
```

- **Tailwind**: `@container`, `@lg:flex-row` (Tailwind v3.2+)
- **언제 사용**: 동일한 컴포넌트가 사이드바/메인 등 다양한 레이아웃 위치에 배치될 때. 재사용 가능한 카드, 위젯에 적합.

### 2. View Transitions API

페이지 전환 또는 DOM 변경 시 부드러운 애니메이션. SPA에서 native-app 수준의 전환 효과를 CSS만으로 구현한다.

```css
::view-transition-old(root) {
  animation: fade-out 0.3s ease-out;
}
::view-transition-new(root) {
  animation: fade-in 0.3s ease-in;
}

.card {
  view-transition-name: card-hero;
}
```

```js
// DOM 변경 시 전환 트리거
document.startViewTransition(() => {
  updateDOM();
});
```

- **SPA 페이지 전환**: `view-transition-name`으로 요소 간 shared element transition 구현
- **Next.js App Router**: `next/link` + `useTransition` + `document.startViewTransition` 조합으로 활용
- **언제 사용**: 라우트 전환, 리스트 → 상세 페이지 전환, 아이템 추가/삭제 애니메이션

### 3. Scroll-driven Animations

스크롤 위치에 연동된 애니메이션. JavaScript IntersectionObserver 없이 순수 CSS로 스크롤 진입 효과를 구현한다.

```css
@keyframes fade-in {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.reveal {
  animation: fade-in linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}
```

- **JS 대체**: IntersectionObserver + class toggle 패턴을 CSS만으로 대체
- **scroll-timeline**: 특정 컨테이너의 스크롤 위치를 timeline으로 사용
- **view-timeline**: 요소가 뷰포트에 진입/퇴장하는 시점을 timeline으로 사용
- **언제 사용**: 섹션 진입 reveal 효과, 스크롤 진행률 표시, 패럴랙스 효과

### 4. Popover API

JavaScript 없이 팝오버, 드롭다운, 툴팁을 구현. 브라우저 네이티브 `top-layer`로 z-index 충돌 문제를 근본적으로 해결한다.

```html
<button popovertarget="menu">Menu</button>
<div id="menu" popover>
  <nav>...</nav>
</div>
```

```css
[popover] {
  opacity: 0;
  transform: scale(0.95);
  transition: opacity 0.2s, transform 0.2s, display 0.2s allow-discrete;

  &:popover-open {
    opacity: 1;
    transform: scale(1);
  }

  @starting-style {
    &:popover-open {
      opacity: 0;
      transform: scale(0.95);
    }
  }
}
```

- **JS 없이 동작**: `popovertarget` 속성만으로 토글 연결
- **top-layer**: 모달, 드롭다운이 항상 최상위에 렌더링 — z-index 관리 불필요
- **light dismiss**: 팝오버 외부 클릭 시 자동 닫힘 (기본 동작)
- **언제 사용**: 네비게이션 드롭다운, 툴팁, 컨텍스트 메뉴, 토스트 알림

### 5. CSS Nesting

SCSS 없이 네이티브 CSS에서 선택자 중첩. 컴포넌트 스타일을 한 블록에 응집해 가독성을 높인다.

```css
.card {
  padding: 1rem;

  & .title {
    font-size: var(--text-lg);
  }

  &:hover {
    box-shadow: var(--shadow-md);
  }

  &.is-featured {
    border: 2px solid var(--color-accent);
  }

  @media (width >= 768px) {
    padding: 2rem;
  }
}
```

- **`&` 필수**: 부모 선택자 참조 시 명시. `& .child`(자손), `&:hover`(수식어), `&.modifier`(병치)
- **미디어 쿼리 중첩**: `@media`, `@container` 모두 블록 안에 중첩 가능
- **SCSS 마이그레이션**: 문법 거의 동일 — `&` 없이 태그명만 쓰는 경우(`div {}`)는 지원 안 됨
- **언제 사용**: 컴포넌트 단위 스타일 관리, BEM 대체, 상태 변형 스타일 그룹화
