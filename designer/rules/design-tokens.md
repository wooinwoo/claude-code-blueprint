# 디자인 토큰 규칙

디자인 토큰 사용을 강제하여 시각적 일관성 유지.

## 1. 색상 [CRITICAL]

하드코딩된 색상값 사용 금지. 반드시 디자인 토큰/CSS 변수/Tailwind 설정값 사용.

```tsx
// BAD
style={{ color: '#333', backgroundColor: '#f5f5f5' }}
className="text-[#333] bg-[#f5f5f5]"

// GOOD
className="text-foreground bg-muted"
style={{ color: 'var(--color-text-primary)' }}
```

## 2. 스페이싱 [HIGH]

8px 기반 그리드 시스템. Tailwind spacing scale 또는 CSS 변수 사용.

```tsx
// BAD
style={{ padding: '13px', margin: '7px 15px' }}
className="p-[13px] m-[7px_15px]"

// GOOD
className="p-3 mx-4 my-2"           // 12px, 16px, 8px
className="p-4"                       // 16px (2 unit)
```

## 3. 타이포그래피 [HIGH]

폰트 크기, 줄 간격, 자간은 디자인 시스템 정의값 사용.

```tsx
// BAD
className="text-[15px] leading-[22px]"

// GOOD
className="text-sm leading-normal"    // 시스템 스케일 사용
className="text-body-md"              // 커스텀 유틸리티 사용
```

## 4. 그림자/보더 [MEDIUM]

```tsx
// BAD
className="shadow-[0_2px_8px_rgba(0,0,0,0.12)]"

// GOOD
className="shadow-sm"                 // 시스템 그림자 사용
className="shadow-card"               // 시맨틱 그림자 토큰
```

## 5. 브레이크포인트 [MEDIUM]

Tailwind 기본 또는 프로젝트 정의 브레이크포인트만 사용.

```tsx
// BAD
@media (max-width: 850px) { ... }

// GOOD
@media (max-width: theme('screens.md')) { ... }  // 또는 Tailwind: md:
```

## 6. 다크 모드 [HIGH]

CSS 변수 기반 테마 전환. 하드코딩 색상 금지, 시맨틱 토큰 사용.

### 테마 전환 전략

`data-theme` 속성 또는 `class` 전략으로 테마 전환. `prefers-color-scheme` 미디어 쿼리 기본 지원.

```css
/* GOOD — CSS custom properties 기반 테마 정의 */
:root,
[data-theme="light"] {
  --color-surface: oklch(98% 0 0);
  --color-on-surface: oklch(15% 0 0);
  --color-primary: oklch(55% 0.2 250);
  --color-on-primary: oklch(99% 0 0);
}

[data-theme="dark"] {
  --color-surface: oklch(18% 0 0);
  --color-on-surface: oklch(90% 0 0);
  --color-primary: oklch(70% 0.18 250);
  --color-on-primary: oklch(10% 0 0);
}

/* prefers-color-scheme 미디어 쿼리 — data-theme 미지정 시 OS 설정 따름 */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --color-surface: oklch(18% 0 0);
    --color-on-surface: oklch(90% 0 0);
    --color-primary: oklch(70% 0.18 250);
    --color-on-primary: oklch(10% 0 0);
  }
}
```

### 색상 사용

```tsx
// BAD
className="bg-white text-black"
className="dark:bg-gray-900 dark:text-white"   // 시맨틱 없는 색상 직접 지정

// GOOD
className="bg-surface text-on-surface"         // 시맨틱 토큰 사용
style={{ background: 'var(--color-surface)', color: 'var(--color-on-surface)' }}
```

### Tailwind dark: 접두사

```tsx
// BAD — 단순 색상 반전 (명도 역전, 대비 파괴)
className="bg-white dark:bg-black text-black dark:text-white"

// GOOD — 명도 스케일 재조정 (oklch lightness 기반)
className="bg-surface dark:bg-surface text-on-surface dark:text-on-surface"

// GOOD — Tailwind CSS 변수 연동
// tailwind.config.ts
// colors: { surface: 'var(--color-surface)', 'on-surface': 'var(--color-on-surface)' }
className="bg-surface text-on-surface"         // dark: 접두사 없이도 테마 전환
```

### 시맨틱 토큰 네이밍

| 토큰 | 용도 |
|------|------|
| `surface` | 페이지/카드 배경 |
| `on-surface` | surface 위 텍스트/아이콘 |
| `primary` | 주요 액션/강조색 |
| `on-primary` | primary 위 텍스트/아이콘 |
| `surface-variant` | 보조 배경 (입력창, 칩) |
| `outline` | 보더/구분선 |

## 7. CSS 변수 vs Tailwind 사용 기준 [HIGH]

**CSS 변수를 써야 할 때:**
- 런타임 테마 전환 (다크 모드, 브랜드 테마)
- JavaScript에서 값을 읽거나 변경해야 할 때
- 컴포넌트 레벨 토큰 오버라이드 (data-variant)
- 외부 라이브러리/iframe에 토큰 전달

**Tailwind 유틸리티를 써야 할 때:**
- 빌드 타임에 확정되는 정적 스타일
- 반응형 변형 (sm:, md:, lg:)
- 상태 변형 (hover:, focus:, active:)
- 레이아웃 (flex, grid, spacing)

**둘 다 쓰는 전략 (권장):**
- CSS 변수로 semantic token 정의 → Tailwind theme에서 참조

```css
/* BAD — CSS 변수 남용 — 정적 레이아웃에 변수 불필요 */
.card { display: var(--display-flex); flex-direction: var(--direction-col); }
```

```css
/* GOOD — CSS 변수: 테마 의존 값만 */
:root { --color-primary: oklch(0.55 0.2 260); --radius-md: 0.5rem; }
```

```html
<!-- GOOD — Tailwind: 레이아웃 + 상태 + 반응형 -->
<div class="flex flex-col gap-4 rounded-[--radius-md] bg-[--color-primary] hover:opacity-90 md:flex-row">
```
