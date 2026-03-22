---
priority: [MEDIUM]
globs: "**/*.{tsx,jsx,css,scss,html}"
---

# 모션/애니메이션 규칙

불필요한 모션을 제거하고, 접근성·성능·일관성을 갖춘 애니메이션 구현.

## 1. prefers-reduced-motion [CRITICAL]

모션 민감 사용자를 위한 필수 대응. 모든 애니메이션에 reduced-motion 분기 적용.

```css
/* BAD — 모든 사용자에게 무조건 애니메이션 적용 */
.card {
  transition: transform 300ms ease;
}
.card:hover {
  transform: translateY(-4px);
}

/* GOOD — prefers-reduced-motion 비활성화 분기 */
.card {
  transition: none;
}

@media (prefers-reduced-motion: no-preference) {
  .card {
    transition: transform 300ms cubic-bezier(0.2, 0, 0, 1);
  }
  .card:hover {
    transform: translateY(-4px);
  }
}
```

```tsx
// GOOD — Tailwind motion-safe: / motion-reduce: 접두사
className="motion-safe:transition-transform motion-safe:duration-300 motion-safe:hover:-translate-y-1"
className="motion-reduce:transition-none"
```

## 2. Duration 스케일 [MEDIUM]

용도에 맞는 duration 선택. 과도하게 긴 duration 남용 금지.

| 스케일 | 범위 | 용도 |
|--------|------|------|
| micro | 100–150ms | 색상 전환, 포커스 링, 토글 |
| small | 200–250ms | 버튼 hover, 아이콘 스핀, 툴팁 |
| medium | 300–400ms | 모달 진입, 드롭다운, 슬라이드 |
| large | 500ms+ | 페이지 전환, 히어로 등장, 스켈레톤 로딩 |

```tsx
// BAD — 단순 hover에 과도한 duration
className="transition-colors duration-1000"

// BAD — 모든 요소에 동일한 duration 일괄 적용
className="transition-all duration-500"

// GOOD — 용도별 duration 선택
className="transition-colors duration-150"          // micro: 색상 전환
className="transition-transform duration-200"       // small: 버튼 hover
className="transition-opacity duration-300"         // medium: 모달 페이드
```

## 3. Easing [HIGH]

목적에 맞는 easing 함수 사용. linear 또는 기본 ease 남발 금지.

```css
/* BAD — 자연스럽지 않은 easing */
transition: transform 300ms linear;
transition: opacity 200ms ease;      /* 의도 불명확 */

/* GOOD — 진입/퇴장/표준 easing 구분 */

/* enter: 빠르게 시작, 천천히 멈춤 (UI 진입) */
transition: transform 300ms cubic-bezier(0, 0, 0.2, 1);

/* exit: 천천히 시작, 빠르게 사라짐 (UI 퇴장) */
transition: opacity 200ms cubic-bezier(0.4, 0, 1, 1);

/* standard: 화면 내 이동, 위치 변경 */
transition: transform 300ms cubic-bezier(0.2, 0, 0, 1);
```

```tsx
// GOOD — Tailwind 커스텀 easing (tailwind.config.ts에 등록 후 사용)
// transitionTimingFunction: { 'enter': 'cubic-bezier(0,0,0.2,1)', 'exit': 'cubic-bezier(0.4,0,1,1)' }
className="ease-enter duration-300 transition-transform"
className="ease-exit duration-200 transition-opacity"
```

## 4. GPU 가속 [HIGH]

브라우저 합성 레이어에서 처리 가능한 속성만 애니메이트. layout/paint를 유발하는 속성 애니메이션 금지.

```css
/* BAD — layout 재계산 유발 (매 프레임 reflow) */
transition: width 300ms, height 300ms;
transition: top 200ms, left 200ms;
transition: margin 300ms, padding 300ms;

/* GOOD — transform/opacity만 애니메이트 (GPU 합성 레이어) */
transition: transform 300ms cubic-bezier(0, 0, 0.2, 1);
transition: opacity 200ms cubic-bezier(0.4, 0, 1, 1);

/* 위치 이동 */
/* BAD */
element.style.left = '100px';

/* GOOD */
transform: translateX(100px);

/* 크기 변경 */
/* BAD */
transition: width 300ms;

/* GOOD */
transform: scaleX(1.2);
```

```tsx
// GOOD — Tailwind transform 유틸리티
className="transition-transform duration-300 hover:translate-x-1 hover:-translate-y-0.5"
className="transition-opacity duration-200 hover:opacity-80"
```

## 5. Tailwind 예시 [MEDIUM]

```tsx
// 색상 전환 (micro)
className="transition-colors duration-150 ease-out hover:bg-primary/10 focus:bg-primary/15"

// 버튼 hover 상승 효과 (small)
className="motion-safe:transition-transform motion-safe:duration-200 motion-safe:hover:-translate-y-0.5 motion-safe:active:translate-y-0"

// 페이드인 등장 애니메이션 (medium)
className="motion-safe:animate-fade-in"   // tailwind.config에 keyframes 등록 필요

// 조건부 모션
className="motion-safe:transition-all motion-safe:duration-300 motion-reduce:transition-none"

// 카드 hover
className="motion-safe:transition-shadow motion-safe:duration-200 hover:shadow-md"
```

## 6. 과도한 모션 금지 [HIGH]

사용자 집중을 방해하거나 인지 부하를 높이는 모션 패턴 사용 금지.

```tsx
// BAD — 자동 재생 비디오 (사용자 제어 불가)
<video autoPlay loop muted />

// GOOD — 사용자 제어 제공
<video controls loop muted />
// 또는 prefers-reduced-motion: reduce 시 재생 중단
```

```css
/* BAD — parallax 스크롤 효과 */
.hero-bg {
  transform: translateY(calc(var(--scroll-y) * 0.5));
}

/* GOOD — parallax 비활성화 */
@media (prefers-reduced-motion: no-preference) {
  .hero-bg {
    transform: translateY(calc(var(--scroll-y) * 0.5));
  }
}
```

```tsx
// BAD — 동시에 3개 이상 애니메이션 실행
<div className="animate-bounce">
  <span className="animate-pulse">
    <i className="animate-spin" />
  </span>
</div>

// GOOD — 핵심 요소 1개만 애니메이션, 나머지 정적
<div>
  <span className="motion-safe:animate-pulse">로딩 중...</span>
</div>
```

금지 패턴 목록:
- 자동 재생 동영상/GIF (사용자 동의 없음)
- 무한 루프 attention-seeker (bounce, shake, wiggle)
- 스크롤 기반 parallax (vestibular disorder 유발)
- 동시 3개 이상 독립 애니메이션
- 1초 이상 지속되는 hover 효과
