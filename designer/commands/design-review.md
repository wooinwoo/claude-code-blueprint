---
description: 디자인 리뷰 실행. 디자인/접근성/마크업 리뷰어를 병렬로 호출.
---

# Design Review — 디자인 품질 리뷰

## Usage

```
/design-review                       → 현재 브랜치 변경사항 디자인 리뷰
/design-review src/components/       → 특정 디렉토리만 리뷰
/design-review --a11y-only           → 접근성만 집중 리뷰
/design-review --markup-only         → 마크업만 집중 리뷰
```

## 실행 절차

### Phase 1: 변경 파일 수집
1. `git diff --name-only HEAD~1` 또는 지정 범위에서 UI 관련 파일 필터링
2. `.tsx`, `.jsx`, `.css`, `.scss`, `.html`, `.pen` 파일 대상

### Phase 2: 병렬 리뷰 (3개 에이전트)
각 에이전트를 Agent 도구로 **병렬 실행**:

| 에이전트 | 관점 |
|----------|------|
| **design-reviewer** | 시각적 일관성, 디자인 토큰, 레이아웃 |
| **a11y-reviewer** | WCAG 2.1 AA, 색상 대비, 키보드 접근성 |
| **markup-reviewer** | 시맨틱 HTML, CSS 아키텍처, 네이밍 |

### Phase 3: 통합 리포트
```markdown
# Design Review Report

## Summary
- CRITICAL: N개
- HIGH: N개
- MEDIUM: N개

## Findings (by severity)
...
```

## 주의사항
- 리뷰만 수행. 코드 수정은 하지 않음.
- `--a11y-only`, `--markup-only` 플래그 시 해당 에이전트만 실행
