---
description: 디자인 시스템 관리. 토큰 조회, 일관성 감사, 컴포넌트 분석, 패턴 제안의 4개 서브커맨드 제공.
---

# Design System — 디자인 시스템 관리

## Usage

```
/design-system tokens              → 현재 디자인 토큰 목록 + 사용 빈도 조회
/design-system audit               → 하드코딩/미사용/중복 토큰 감사
/design-system component <name>    → 특정 컴포넌트 사용처 + prop + variant 분석
/design-system suggest             → 반복 패턴 탐지 + 컴포넌트화/토큰화 제안
```

---

## `tokens` — 디자인 토큰 조회

### Phase 1: 토큰 소스 탐색

Glob + Grep으로 프로젝트 내 토큰 정의 파일을 우선순위 순서로 탐색:

```
// Tailwind v3 (JS config)
Glob("tailwind.config.{js,ts,mjs,cjs}")

// Tailwind v4 (@theme in CSS — tailwind.config 없으면 반드시 확인)
Grep("@theme", glob="**/*.css")

// 기타 토큰 소스
Glob("src/**/tokens.{css,json,ts,js}")
Glob("src/**/variables.{css,scss}")
Glob("src/**/theme.{ts,js,json}")
Glob("**/design-tokens/**/*.{json,ts}")
```

Tailwind v4 판별: `tailwind.config.*` 없고 CSS에 `@theme {` 블록이 있으면 v4. `@theme` 내부의 `--color-*`, `--font-*`, `--shadow-*` 등이 토큰.

파일 0개이면 `디자인 토큰 파일을 찾을 수 없습니다.` 출력 후 종료.

### Phase 2: 토큰 파싱

Read로 파일을 읽고 카테고리별 추출:

| 카테고리 | 탐색 패턴 | 예시 |
|----------|-----------|------|
| 카테고리 | v3 (JS config) | v4 (@theme CSS) | 예시 |
|----------|----------------|-----------------|------|
| **색상** | `theme.colors` | `--color-*` | `--color-primary-500: #1e40af` |
| **타이포그래피** | `theme.fontSize` | `--font-*`, `--text-*` | `--font-sans: 'Pretendard'` |
| **스페이싱** | `theme.spacing` | `--spacing-*` | `--spacing-4: 16px` |
| **브레이크포인트** | `theme.screens` | `--breakpoint-*` | `--breakpoint-sm: 640px` |
| **그림자** | `theme.boxShadow` | `--shadow-*` | `--shadow-md: 0 12px 24px...` |
| **보더** | `theme.borderRadius` | `--radius-*` | `--radius-lg: 8px` |
| **레이아웃** | — | 커스텀 변수 | `--sidebar-width: 270px` |

**v3**: `theme.extend`와 기본 `theme`를 모두 파싱. extend가 기본을 덮어쓰면 최종 값만 표시.
**v4**: `@theme { }` 블록 내 모든 `--*` 변수를 파싱. `@theme inline { }` 블록은 shadcn/radix 등 UI 라이브러리 토큰 — 별도 섹션으로 표시.

### Phase 3: 사용 빈도 분석

Grep으로 각 토큰의 사용 횟수 집계:

```
// Tailwind 클래스 사용 (variant 포함: bg-primary/50, text-primary-foreground 등)
Grep("bg-primary|text-primary|border-primary|ring-primary|outline-primary", glob="**/*.{tsx,jsx,vue,html}")  → count
// opacity modifier (bg-primary/50 등)
Grep("primary/\\d+", glob="**/*.{tsx,jsx,vue,html}")  → count
// -foreground 파생 토큰 (text-primary-foreground 등)
Grep("primary-foreground|secondary-foreground|muted-foreground|accent-foreground", glob="**/*.{tsx,jsx,vue,html}")  → count
// CSS 변수 직접 사용
Grep("var\\(--color-primary|var\\(--primary", glob="**/*.{css,scss,tsx,jsx}")  → count
```

각 토큰 이름에 대해 위 패턴을 반복. 토큰명이 `primary`이면 `primary`를 치환하여 검색.

### 출력 형식

카테고리별 테이블로 출력. 사용 횟수 0인 토큰은 `⚠️` 표시.

```markdown
## 색상 (Colors) — 12개
| 토큰명 | 값 | Tailwind 클래스 | 사용 횟수 |
|--------|-----|----------------|----------|
| primary | #6366F1 | bg-primary, text-primary | 47 |
| surface | #F3F4F6 | bg-surface | 23 |
| accent-300 | #A5B4FC | bg-accent-300 | ⚠️ 0 |
```

---

## `audit` — 디자인 시스템 일관성 감사

### Phase 1: 하드코딩 탐지

Grep으로 토큰을 우회한 직접 값 사용을 탐지:

```
// 색상 하드코딩 (inline style, CSS 변수 직접 할당만 — Tailwind arbitrary는 별도)
// style={{ color: '#xxx' }} 또는 fill="#xxx" 패턴
Grep("style=.*#[0-9a-fA-F]|fill=\"#|stroke=\"#", glob="**/*.{tsx,jsx,vue}")
Grep("rgb\\(|rgba\\(|hsl\\(", glob="**/*.{tsx,jsx,vue,css}")

// Tailwind arbitrary value (전체 패턴)
Grep("(bg|text|border|ring|outline|fill|stroke)-\\[#", glob="**/*.{tsx,jsx,vue}")  // 색상 arbitrary
Grep("(p|px|py|pt|pr|pb|pl|m|mx|my|mt|mr|mb|ml)-\\[", glob="**/*.{tsx,jsx,vue}")  // 스페이싱
Grep("(w|h|min-w|min-h|max-w|max-h|gap|top|left|right|bottom|inset)-\\[", glob="**/*.{tsx,jsx,vue}")  // 사이징/위치
Grep("(rounded|border|text)-\\[\\d", glob="**/*.{tsx,jsx,vue}")  // 보더/폰트 arbitrary

// CSS/SCSS 내 하드코딩
Grep("color:\\s*#|background:\\s*#|border.*:\\s*#", glob="**/*.{css,scss}")
Grep("font-size:\\s*\\d+px|margin:\\s*\\d+px|padding:\\s*\\d+px", glob="**/*.{css,scss}")
```

심각도 기준:
- **HIGH**: 색상 하드코딩 (`#hex`, `rgb()`) — 테마 전환 시 깨짐
- **MEDIUM**: Tailwind arbitrary value (`bg-[#xxx]`) — 토큰 대체 가능
- **LOW**: 스페이싱 arbitrary (`p-[13px]`) — 그리드 이탈 가능성

### Phase 2: 미사용 토큰

`tokens` 결과에서 사용 횟수 0인 항목을 추출. 다크모드 전용(`dark:`)이나 반응형 전용 토큰은 **REVIEW** 태그 부여.

### Phase 3: 중복 토큰

동일 값에 다른 이름이 매핑된 토큰 탐지:

```typescript
// 예: primary-500과 brand-main이 둘 다 #6366F1
const duplicates = tokens.filter((a, b) => a.value === b.value && a.name !== b.name)
```

### 출력 형식

```markdown
## 요약
| 항목 | 개수 | 심각도 |
|------|------|--------|
| 색상 하드코딩 | 15 | HIGH |
| Tailwind arbitrary | 23 | MEDIUM |
| 미사용 토큰 | 4 | MEDIUM |
| 중복 토큰 | 2 | LOW |

## 하드코딩 이슈
| 파일 | 라인 | 하드코딩 값 | 대체 토큰 제안 | 심각도 |
|------|------|-------------|---------------|--------|
| Card.tsx | 23 | bg-[#6366F1] | bg-primary | HIGH |
| Nav.tsx | 45 | p-[13px] | p-3 (12px) | LOW |

## 미사용 토큰
| 토큰명 | 값 | 정의 위치 | 비고 |
|--------|-----|-----------|------|
| accent-300 | #A5B4FC | tailwind.config.ts:24 | 삭제 후보 |

## 중복 토큰
| 토큰 A | 토큰 B | 공통 값 | 통합 제안 |
|--------|--------|---------|----------|
| primary-500 | brand-main | #6366F1 | → primary로 통일 |
```

---

## `component <name>` — 컴포넌트 분석

### Phase 1: 컴포넌트 파일 탐색

```
// 대소문자 모두 탐색 (shadcn/ui는 소문자 파일명 관례)
Glob("**/{name}.{tsx,jsx,vue}")
Glob("**/{Name_lowercase}.{tsx,jsx,vue}")
Glob("**/{name}/index.{tsx,jsx,vue}")
Glob("**/{name}/*.{tsx,jsx,vue}")
```

0개이면 유사 이름 재탐색: `Glob("**/*{name}*.{tsx,jsx,vue}")` (대소문자 무시) → `"Button을 찾을 수 없습니다. 유사: IconButton.tsx, ButtonGroup.tsx"`

### Phase 2: 사용처 검색

```
Grep("import.*{name}|from.*{name}", glob="**/*.{tsx,jsx,vue,ts,js}")
Grep("<{name}[\\s/>]", glob="**/*.{tsx,jsx,vue}")
```

### Phase 3: Prop 분석

Read로 파일을 읽고 Props 추출. 다음 패턴 모두 탐색:

- `interface {Name}Props` — 명시적 인터페이스
- `type {Name}Props` — 타입 별칭
- `React.ComponentProps<"tag"> & { ... }` — 교차 타입 (shadcn/ui 관례)
- `VariantProps<typeof ...>` — cva variant props (자동 추론)

각 prop의 타입, 필수/선택 여부, 기본값을 정리.

### Phase 4: Variant 목록

```
Grep("cva\\(|variants:", path="컴포넌트_파일_경로")       → cva 패턴
Grep("variant.*===|size.*===", path="컴포넌트_파일_경로")  → 조건부 className
Grep("cn\\(|clsx\\(", path="컴포넌트_파일_경로")           → cn/clsx 내 조건부
```

### 출력 형식

```markdown
## Props
| Prop | 타입 | 필수 | 기본값 |
|------|------|------|--------|
| variant | 'primary' \| 'secondary' \| 'ghost' | ✕ | 'primary' |
| size | 'sm' \| 'md' \| 'lg' | ✕ | 'md' |
| children | ReactNode | ✔ | — |

## Variants (cva)
| Variant | 값 | 클래스 |
|---------|-----|--------|
| variant | primary | bg-primary text-white |
| size | sm | px-3 py-1.5 text-xs |

## 사용처 — 18개 파일
| 파일 | 라인 | 사용 형태 |
|------|------|-----------|
| Header.tsx | 24 | `<Button variant="primary">` |
| LoginForm.tsx | 45 | `<Button variant="secondary" size="lg">` |
```

---

## `suggest` — 패턴 제안

### Phase 1: 반복 패턴 탐지

Grep으로 동일 className 조합 3회+ 등장을 검색:

```
Grep("className=\"([^\"]{30,})\"", glob="**/*.{tsx,jsx,vue}", output_mode="content")
Grep("style=\\{\\{([^}]{20,})\\}\\}", glob="**/*.{tsx,jsx,vue}")
```

결과에서 동일 문자열 3회 이상 등장하는 항목을 추출.

### Phase 2: 컴포넌트화 후보

유사 JSX 구조 반복 탐지:

```
Grep("<(svg|Icon)[^>]*>.*<(span|p)>", glob="**/*.{tsx,jsx,vue}")          → 아이콘+텍스트
Grep("<div.*className=.*rounded.*shadow", glob="**/*.{tsx,jsx,vue}")       → 카드형
Grep("<li.*className=.*flex.*items-center", glob="**/*.{tsx,jsx,vue}")     → 리스트 아이템
```

각 후보: 등장 파일 수, 공통 구조 요약, 제안 컴포넌트명.

### Phase 3: 제안서 생성

탐지 결과를 **토큰화 제안** / **컴포넌트화 제안**으로 분류:

```markdown
## 토큰화 제안
| 패턴 | 등장 횟수 | 현재 사용 | 제안 토큰명 |
|------|----------|-----------|------------|
| #6366F1 | 7 | bg-[#6366F1] | bg-accent |
| 13px padding | 5 | p-[13px] | p-3 통일 |

## 컴포넌트화 제안
| 패턴 | 등장 횟수 | 등장 파일 | 제안 컴포넌트명 |
|------|----------|-----------|----------------|
| 아이콘+라벨 | 8 | Header, Sidebar, Nav | `<IconLabel>` |
| 카드 | 6 | Dashboard, Profile | `<Card>` |

## 제안 상세
각 컴포넌트화 후보별로 현재 반복 코드 + 제안 컴포넌트 코드 블록을 포함.
```

---

## 주의사항

- **토큰 소스 우선순위**: `tailwind.config` → CSS custom properties → 전용 토큰 파일(JSON/TS). 여러 소스가 있으면 모두 병합 표시.
- **Figma 연동**: Figma Dev Mode MCP 서버가 활성화되어 있으면 `mcp__figma-dev-mode-mcp-server__get_variable_defs`로 Figma 변수를 가져와 프로젝트 토큰과 1:1 매핑 비교 가능.
- **모노레포 환경**: 패키지 경로를 인자로 명시하여 범위 한정: `/design-system audit packages/ui/`. 루트 실행 시 전체 대상.
- **`audit` ↔ `tokens` 관계**: `audit`는 내부적으로 `tokens` 결과를 참조. `tokens`를 먼저 실행하면 캐시 재사용.
- **`suggest` 정확도 한계**: 문자열 패턴 매칭 기반이므로 동적 className(변수, 삼항 연산자)은 미탐지 가능. 결과는 참고용.
- **대형 프로젝트**: 파일 1000개+ 이면 Grep 범위를 `src/` 하위로 제한하여 성능 확보.
