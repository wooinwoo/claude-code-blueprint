---
name: contrast-checker
description: Use this skill to check and fix color contrast ratios for WCAG compliance. Calculates contrast ratios and suggests accessible alternatives.
---

# Contrast Checker Skill

색상 대비율 검증 및 WCAG 준수를 위한 대안 제시.

## When to Activate

- 색상 조합 결정 시
- 접근성 리뷰에서 대비율 문제 발견 시
- 디자인 시스템 색상 정의 시
- 다크 모드 색상 설정 시
- Tailwind 색상 클래스 선택 시

## WCAG 2.x Contrast Requirements

| 레벨 | 일반 텍스트 | 큰 텍스트 (18px+/14px bold+) | UI 컴포넌트 |
|------|-------------|------------------------------|-------------|
| AA | 4.5:1 | 3:1 | 3:1 |
| AAA | 7:1 | 4.5:1 | — |

> **큰 텍스트 기준**: CSS `font-size: 18px` 이상 또는 `font-size: 14px` + `font-weight: 700` 이상.
> 이 기준을 충족하면 AA 통과에 3:1만 필요하므로, 대비가 부족할 때 텍스트 크기를 키우는 것도 유효한 전략이다.

## APCA — WCAG 3.0 초안의 새 대비 알고리즘

APCA(Advanced Perceptual Contrast Algorithm)는 WCAG 3.0 초안에서 채택한 차세대 대비 측정 방식이다.

**기존 WCAG 2.x 대비율과 차이점:**

| 항목 | WCAG 2.x | APCA |
|------|----------|------|
| 계산 방식 | 상대 휘도 비율 (L1+0.05)/(L2+0.05) | 인지 명도 차이 (비대칭) |
| 전경/배경 구분 | 없음 (순서 무관) | 있음 (흰 글씨/검은 배경 ≠ 검은 글씨/흰 배경) |
| 결과 범위 | 1:1 ~ 21:1 | 0 ~ ±108 Lc |
| 폰트 크기 반영 | 일반/큰 텍스트 2단계만 | 폰트 크기+두께별 세분화된 기준 |
| 상태 | W3C 권고안 (확정) | W3C 초안 (개발 중) |

APCA는 인간의 시각 인지를 더 정확히 반영하지만 아직 초안이므로, **현재 실무에서는 WCAG 2.x AA 기준을 우선 적용**하고 APCA는 참고용으로 확인한다.

## Contrast Calculation (WCAG 2.x)

상대 휘도(relative luminance) 기반:

```
R_lin = (R/255 <= 0.04045) ? R/255/12.92 : ((R/255 + 0.055)/1.055)^2.4
G_lin, B_lin 동일

L = 0.2126 × R_lin + 0.7152 × G_lin + 0.0722 × B_lin
Contrast Ratio = (L1 + 0.05) / (L2 + 0.05)   (L1 > L2)
```

## oklch 기반 대비 조정

oklch는 인간의 인지와 일치하는 균일 색공간이므로 L(명도) 값만 조정해도 색조를 유지하면서 대비를 확보할 수 있다.

```css
/* 대비 부족 시 oklch lightness로 조정 */
--color-text: oklch(0.25 0.02 260);      /* 어두운 텍스트 */
--color-bg: oklch(0.98 0.01 260);        /* 밝은 배경 */
/* 명도 차이 0.73 → AA 통과 */

/* 다크 모드 반전 — 명도만 뒤집으면 색조 유지 */
[data-theme="dark"] {
  --color-text: oklch(0.92 0.02 260);    /* 밝은 텍스트 */
  --color-bg: oklch(0.15 0.01 260);      /* 어두운 배경 */
  /* 명도 차이 0.77 → AA 통과 */
}
```

**oklch 명도 가이드**: 전경과 배경의 L 값 차이가 약 0.6 이상이면 대부분 AA를 통과한다. 정확한 판정은 반드시 sRGB 변환 후 WCAG 공식으로 계산해야 한다.

## Quick Reference — 흔한 실수

| 전경 | 배경 | 대비율 | 판정 | 비고 |
|------|------|--------|------|------|
| #999 | #fff | 2.85:1 | ❌ FAIL | 회색 본문 텍스트 — 가장 흔한 실수 |
| #767676 | #fff | 4.54:1 | ✅ AA | 회색 텍스트의 AA 최소 경계값 |
| #595959 | #fff | 7.0:1 | ✅ AAA | 충분한 대비 |
| #fff | #0066ff | 3.95:1 | ❌ FAIL | 파란 버튼 위 흰 글씨 |
| #fff | #0055cc | 5.36:1 | ✅ AA | 버튼 배경을 어둡게 조정 |
| #aaa | #fff | 2.32:1 | ❌ FAIL | placeholder 텍스트 |
| #757575 | #fff | 4.60:1 | ✅ AA | placeholder 최소값 |
| #999 | #f5f5f5 | 2.58:1 | ❌ FAIL | disabled 상태 (면제 대상이지만 가독성 권장) |
| #6b6b6b | #fff | 5.36:1 | ✅ AA | 14px 이하 작은 텍스트에 권장 |

> **주의**: disabled 상태(`aria-disabled`, `:disabled`)는 WCAG 1.4.3 면제 대상이지만, 사용자가 "비활성"임을 인지할 수 있을 정도의 대비는 유지하는 것이 좋다 (최소 2.5:1 이상 권장).

> **작은 텍스트 주의**: 12-14px 텍스트는 일반 텍스트 기준(4.5:1)이 적용된다. 이 크기에서는 5:1 이상을 목표로 하면 실제 가독성이 확보된다.

## Tailwind에서 대비 확보 실전 패턴

```html
<!-- BAD: 대비 부족 (gray-400 on gray-100 ≈ 2.3:1) -->
<p class="text-gray-400 bg-gray-100">읽기 어려움</p>

<!-- GOOD: AA 통과 (gray-700 on gray-100 ≈ 7.2:1) -->
<p class="text-gray-700 bg-gray-100">명확한 텍스트</p>

<!-- GOOD: 다크모드 포함 양쪽 AA 통과 -->
<p class="text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-900">
  양쪽 통과
</p>

<!-- BAD: placeholder 대비 부족 -->
<input class="placeholder:text-gray-300" placeholder="검색어 입력" />

<!-- GOOD: placeholder AA 통과 -->
<input class="placeholder:text-gray-500" placeholder="검색어 입력" />

<!-- BAD: 버튼 위 흰 텍스트 대비 부족 -->
<button class="bg-blue-400 text-white">제출</button>

<!-- GOOD: 배경을 어둡게 -->
<button class="bg-blue-700 text-white">제출</button>
```

**Tailwind gray 스케일 대비 참고** (배경 white 기준):

| 클래스 | hex | 대비율 | 판정 |
|--------|-----|--------|------|
| gray-300 | #d1d5db | 1.75:1 | ❌ |
| gray-400 | #9ca3af | 2.66:1 | ❌ |
| gray-500 | #6b7280 | 4.63:1 | ✅ AA |
| gray-600 | #4b5563 | 7.01:1 | ✅ AAA |
| gray-700 | #374151 | 9.68:1 | ✅ AAA |

## Fix Strategy

대비율 부족 시 조정 순서:

1. **전경색 명도 조정** — oklch L 값을 낮춰 텍스트를 어둡게 (밝은 배경)
2. **배경색 명도 조정** — 배경을 더 밝게 또는 더 어둡게
3. **oklch 미세 튜닝** — 채도(C)와 색상(H)을 유지하면서 명도(L)만 이동
4. **텍스트 크기 키우기** — 18px 이상이면 큰 텍스트 기준(3:1) 적용 가능
5. **폰트 굵기 올리기** — 14px + bold(700)도 큰 텍스트 기준 적용 가능
