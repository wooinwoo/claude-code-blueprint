---
description: 디자인 리뷰 실행. 디자인/접근성/마크업 3개 리뷰 에이전트를 병렬 호출하여 통합 리포트 생성.
---

# Design Review — 디자인 품질 리뷰

## Usage

```
/design-review                       → 전체 리뷰 (디자인 + 접근성 + 마크업)
/design-review --a11y-only           → 접근성만 집중 리뷰
/design-review --markup-only         → 마크업만 집중 리뷰
/design-review --design-only         → 디자인 토큰/레이아웃만 리뷰
/design-review --diff                → git diff 변경 파일만 대상으로 리뷰
/design-review src/components/       → 특정 디렉토리만 리뷰
```

플래그 조합 가능: `/design-review --diff --a11y-only` → 변경된 파일 중 접근성만 리뷰

## 실행 절차

### Phase 1: 대상 파일 수집

**Step 1-1: 파일 목록 생성**

기본 모드 — Glob으로 프로젝트 내 UI 관련 파일 전체 수집:

```
Glob("**/*.{tsx,jsx,html,css,scss,vue}")
```

`--diff` 모드 — git diff에서 변경된 파일만 필터링:

```bash
git diff --name-only HEAD~1
```

결과에서 UI 파일 확장자만 필터링: `.tsx`, `.jsx`, `.html`, `.css`, `.scss`, `.vue`

특정 디렉토리 인자가 있으면 해당 경로 하위만 대상으로 제한.

**Step 1-2: 파일 수 검증**

- 파일 0개 → 안내 메시지 출력 후 종료:
  ```
  리뷰 대상 UI 파일이 없습니다. 경로나 --diff 범위를 확인해주세요.
  ```
- 파일 50개 초과 → 경고 출력 후 변경 파일(`git diff`)을 우선 정렬하고, 에이전트당 최대 20파일로 제한. 제외된 파일 목록을 리포트 하단에 별도 표기.
- 파일 20개 이하 → 전체 대상 진행.

**Step 1-3: 파일 목록 구성**

수집된 파일을 줄바꿈 구분 문자열로 구성:

```typescript
const file_list = collected_files.join("\n")
```

### Phase 2: 에이전트 병렬 실행

3개 리뷰 에이전트를 Agent() 함수로 **병렬 호출**한다. 각 에이전트는 독립적으로 파일을 읽고 검토 결과를 반환한다.

```typescript
// 3개 병렬 실행
const [design_result, a11y_result, markup_result] = await Promise.all([
  Agent("design-reviewer", `다음 파일들의 디자인 품질을 검토해줘.\n\n파일 목록:\n${file_list}\n\n검토 기준: 디자인 토큰 사용, 8px 그리드, 컬러 하드코딩, z-index 관리`),
  Agent("a11y-reviewer", `다음 파일들의 접근성을 검토해줘.\n\n파일 목록:\n${file_list}\n\n검토 기준: WCAG 2.1 AA, 대비율, 키보드 접근성, aria 속성, heading 계층`),
  Agent("markup-reviewer", `다음 파일들의 마크업 품질을 검토해줘.\n\n파일 목록:\n${file_list}\n\n검토 기준: 시맨틱 HTML, Tailwind 클래스 중복, CSS 아키텍처, 성능`)
])
```

**플래그별 에이전트 선택**:

| 플래그 | 실행 에이전트 |
|--------|--------------|
| (없음, 전체) | design-reviewer + a11y-reviewer + markup-reviewer |
| `--a11y-only` | a11y-reviewer만 |
| `--markup-only` | markup-reviewer만 |
| `--design-only` | design-reviewer만 |

`--*-only` 플래그가 지정되면 해당 에이전트만 단독 실행한다. `Promise.all` 대신 단일 Agent() 호출.

**각 에이전트의 검토 영역**:

| 에이전트 | 검토 기준 | 심각도 판정 기준 |
|----------|-----------|-----------------|
| **design-reviewer** | 디자인 토큰 사용 여부, 8px 그리드 정합성, 컬러 하드코딩(`#hex` 직접 사용), z-index 무분별 사용, 레이아웃 일관성 | CRITICAL: 토큰 미사용 컬러 10개+, HIGH: 그리드 이탈 5개+, MEDIUM: 개별 하드코딩 |
| **a11y-reviewer** | WCAG 2.1 AA 준수, 색상 대비율 4.5:1, 키보드 접근성(tabindex, onKeyDown), aria-label/role 속성, heading 계층(h1→h2→h3 순서) | CRITICAL: img alt 누락, 키보드 접근 불가, HIGH: 대비율 미달, heading 건너뜀, MEDIUM: aria 보완 필요 |
| **markup-reviewer** | 시맨틱 HTML(`<section>`, `<article>`, `<nav>`), Tailwind 클래스 중복/과다, CSS 아키텍처(BEM/모듈), 렌더링 성능(불필요 리렌더, 인라인 스타일) | CRITICAL: 없음(마크업은 최대 HIGH), HIGH: 비시맨틱 구조, MEDIUM: 클래스 중복, LOW: 네이밍 개선 |

### Phase 3: 통합 리포트

3개 에이전트 결과를 수집하여 심각도별로 통합 정렬한다.

**Step 3-1: 이슈 정규화**

각 에이전트 결과에서 이슈를 추출하고 다음 구조로 정규화:

```typescript
interface ReviewIssue {
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
  category: '디자인' | '접근성' | '마크업'
  file: string      // 파일 경로
  line: number      // 라인 번호
  message: string   // 이슈 설명
  suggestion?: string // 수정 제안 (있으면)
}
```

**Step 3-2: 심각도별 통합 정렬**

정렬 우선순위: CRITICAL > HIGH > MEDIUM > LOW. 동일 심각도 내에서는 카테고리(접근성 > 디자인 > 마크업) 순서.

**Step 3-3: 카테고리별 이슈 수 집계**

각 카테고리 × 심각도 조합의 이슈 수를 요약 테이블로 구성.

## 출력 형식

```markdown
# Design Review Report

## 요약
| 카테고리 | CRITICAL | HIGH | MEDIUM | LOW | 합계 |
|----------|----------|------|--------|-----|------|
| 디자인   | 0        | 2    | 3      | 1   | 6    |
| 접근성   | 1        | 1    | 2      | 0   | 4    |
| 마크업   | 0        | 0    | 4      | 2   | 6    |
| **합계** | **1**    | **3**| **9**  | **3**| **16** |

## 이슈 목록

### CRITICAL
1. [접근성] `img` alt 속성 누락 — `Hero.tsx:15`
   → `<img src={hero} />` → `<img src={hero} alt="메인 배너 이미지" />`

### HIGH
1. [디자인] 컬러 하드코딩 — `Card.tsx:23`
   → `bg-[#6366F1]` → `bg-primary` (디자인 토큰 사용)
2. [접근성] heading 레벨 건너뜀 — `About.tsx:8`
   → `<h1>` 다음 `<h3>` 사용 → `<h2>`로 변경

### MEDIUM
1. [마크업] Tailwind 클래스 중복 — `Button.tsx:12, Button.tsx:28`
   → 동일 클래스 조합 `flex items-center justify-center px-4 py-2` 2회 반복 → 공통 변수 추출
2. [디자인] 8px 그리드 이탈 — `Sidebar.tsx:45`
   → `p-[13px]` → `p-3` (12px) 또는 `p-3.5` (14px)
3. [접근성] aria-label 누락 — `IconButton.tsx:7`
   → 아이콘만 있는 버튼에 `aria-label` 추가 필요
...

### LOW
1. [마크업] `<div>` 과다 사용 — `Footer.tsx:5-20`
   → `<footer>`, `<nav>` 시맨틱 태그 활용 권장
...

## 리뷰 제외 파일 (50파일 초과 시)
- `src/legacy/OldPage.tsx` — 변경 이력 없음, 우선순위 낮음
...
```

`--*-only` 플래그로 단일 에이전트 실행 시 요약 테이블에 해당 카테고리만 표시.

## 주의사항

- **리뷰만 수행**. 코드 수정은 하지 않음. 수정이 필요하면 `/fix` 커맨드를 별도 실행.
- **에이전트당 최대 20파일 권장**. 50파일 초과 시 변경 파일(`git diff`)을 우선 배정하고 나머지는 제외 목록에 표기.
- **`--diff` 모드의 기본 범위**는 `HEAD~1` (최근 1커밋). 커밋 범위를 지정하고 싶으면 인자로 전달: `/design-review --diff HEAD~3`
- 에이전트 결과에 파일 경로와 라인 번호가 포함되지 않으면, 리포트에서 해당 이슈는 파일명만 표기하고 라인은 `?`로 표시.
- 모노레포 환경에서는 패키지 경로를 인자로 명시하여 범위를 한정할 것: `/design-review packages/ui/`
- `/publish-check`과 연계하면 접근성 + 성능 + SEO까지 전체 배포 점검 가능.
