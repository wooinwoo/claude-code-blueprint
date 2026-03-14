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

## WCAG Contrast Requirements

| 레벨 | 일반 텍스트 | 큰 텍스트 (18px+/14px bold+) | UI 컴포넌트 |
|------|-------------|------------------------------|-------------|
| AA | 4.5:1 | 3:1 | 3:1 |
| AAA | 7:1 | 4.5:1 | — |

## Contrast Calculation

상대 휘도(relative luminance) 기반:
```
L = 0.2126 × R + 0.7152 × G + 0.0722 × B
Contrast Ratio = (L1 + 0.05) / (L2 + 0.05)  (L1 > L2)
```

## Quick Reference — 흔한 실수

| 전경 | 배경 | 대비율 | 판정 |
|------|------|--------|------|
| #999 | #fff | 2.85:1 | ❌ FAIL |
| #767676 | #fff | 4.54:1 | ✅ AA |
| #595959 | #fff | 7.0:1 | ✅ AAA |
| #fff | #0066ff | 3.95:1 | ❌ FAIL (일반) |
| #fff | #0055cc | 5.36:1 | ✅ AA |

## Fix Strategy

대비율 부족 시:
1. 전경색을 더 어둡게 (또는 밝은 배경에서)
2. 배경색을 더 밝게/어둡게
3. oklch 명도 조정으로 미세 튜닝
4. 텍스트 크기를 키워서 큰 텍스트 기준 적용
