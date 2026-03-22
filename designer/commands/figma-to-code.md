---
description: Figma 시안을 코드로 변환. Figma Dev Mode MCP 서버로 디자인 스펙 추출 + 컴포넌트/페이지 코드 생성.
---

# Figma to Code — Figma 시안 → 코드 변환

## 전제 조건

- **Figma Desktop 앱**이 실행 중이어야 함
- **Dev Mode MCP 서버**가 활성화되어 있어야 함 (SSE at `localhost:3845`, 서버명: `figma-dev-mode-mcp-server`)
- 변환할 노드를 **Figma에서 미리 선택**해야 함 — MCP 도구는 현재 선택된 노드를 기반으로 동작

## Usage

```
/figma-to-code                  → 현재 Figma 선택 노드에서 스펙 추출 + 코드 생성
/figma-to-code --component      → 단일 컴포넌트 코드 생성
/figma-to-code --page           → 전체 페이지 레이아웃 생성
/figma-to-code --tokens         → 디자인 토큰만 추출
```

> **참고**: Figma URL을 인자로 전달하지 않음. Figma Desktop에서 직접 노드를 선택한 상태에서 명령 실행.

> **Figma MCP 미연결 시**: "Figma Dev Mode MCP에 연결할 수 없습니다." → 대안 안내:
> 1. 스크린샷/이미지를 제공하면 시각 기반으로 코드 생성
> 2. Figma Desktop 실행 + Dev Mode 활성화 후 재시도
> 3. `--tokens` 모드는 프로젝트 CSS 토큰만 분석하므로 Figma 없이도 동작

## 실행 절차

### Phase 1: Figma 데이터 추출 (MCP 도구 호출)

Figma에서 노드를 선택한 상태에서 다음 도구를 호출한다.

**Step 1-1: 기존 코드 매핑 확인**

먼저 선택된 컴포넌트에 이미 코드 매핑이 있는지 확인:

```
mcp__figma-dev-mode-mcp-server__get_code_connect
```

- 매핑이 존재하면 → 기존 코드 컴포넌트 정보를 기반으로 코드 생성 (Phase 3로 바로 이동 가능)
- 매핑이 없으면 → Step 1-2로 진행

**Step 1-2: 디자인 컨텍스트 추출 (PRIMARY)**

```
mcp__figma-dev-mode-mcp-server__get_design_context
```

이 도구가 **핵심**. 선택된 Figma 노드의 구조화된 표현을 React + Tailwind 코드 형태로 반환한다. 반환 결과에 포함되는 정보:
- 레이아웃 구조 (flex/grid)
- 색상, 타이포그래피, 스페이싱
- 컴포넌트 계층 구조
- Tailwind 클래스 매핑

**대규모 디자인 fallback**: `get_design_context` 결과가 너무 클 경우:

1. `mcp__figma-dev-mode-mcp-server__get_metadata` 호출 — sparse XML로 노드 트리(레이어 ID, 이름, 타입, 위치, 크기)만 가져옴
2. XML에서 핵심 노드 식별
3. Figma에서 개별 하위 노드를 선택한 후 `get_design_context`를 부분적으로 호출

**`--tokens` 모드일 경우**:

```
mcp__figma-dev-mode-mcp-server__get_variable_defs
```

선택된 노드에 사용된 변수와 스타일을 추출 — 색상, 스페이싱, 타이포그래피 토큰. Phase 2의 토큰 매핑에 직접 사용.

**코드 컴포넌트 매핑 제안이 필요할 경우**:

```
mcp__figma-dev-mode-mcp-server__get_code_connect_suggestions
```

Figma 컴포넌트와 코드베이스의 코드 컴포넌트 간 매핑을 자동으로 감지·제안.

### Phase 2: 스펙 분석 및 프로젝트 토큰 정제

> `get_design_context`가 이미 React + Tailwind 코드를 반환하므로, Phase 2는 **프로젝트 고유 토큰과의 정합성을 검증·정제**하는 단계다. raw 변환이 아닌 refinement.

**색상 매핑**

1. 프로젝트 내 디자인 토큰 파일 탐색:
   - `tailwind.config.{js,ts}` — `theme.colors`
   - `src/styles/tokens.css` 또는 `variables.css` — CSS custom properties
   - `src/tokens/**/*.{json,ts}` — 토큰 JSON
2. `get_design_context`가 반환한 색상 값과 프로젝트 토큰 비교:
   - 일치 → 프로젝트 토큰으로 교체 (예: `bg-[#6366F1]` → `bg-primary`)
   - 허용 오차 ±5 내 유사 색상 → 가장 가까운 토큰 제안 + 원본 주석
   - 토큰 없는 신규 색상 → `--tokens` 섹션에 신규 토큰 제안으로 분리
3. `get_variable_defs`로 추출한 Figma 변수가 있으면 → 프로젝트 토큰 이름과 1:1 매핑 시도

**타이포그래피 매핑**

`get_design_context`가 반환한 텍스트 스타일을 프로젝트 커스텀 scale과 대조 (커스텀 scale이 없으면 Tailwind 기본 사용):

| fontSize | Tailwind 클래스 |
|----------|----------------|
| 12px | `text-xs` |
| 14px | `text-sm` |
| 16px | `text-base` |
| 18px | `text-lg` |
| 20px | `text-xl` |
| 24px | `text-2xl` |
| 30px | `text-3xl` |
| 36px | `text-4xl` |

fontWeight: 400 → `font-normal`, 500 → `font-medium`, 600 → `font-semibold`, 700 → `font-bold`

lineHeight: `AUTO`이면 생략, 숫자면 `leading-[{value}px]` 또는 가장 가까운 scale.

**스페이싱 스냅 (8px 그리드)**

`get_design_context` 결과의 스페이싱 값을 프로젝트 spacing scale에 정렬:

| 범위 | 변환 | Tailwind |
|------|------|----------|
| 0 | 0 | `p-0` |
| 1-2px | 1px | `p-px` |
| 3-6px | 4px | `p-1` |
| 7-10px | 8px | `p-2` |
| 11-14px | 12px | `p-3` |
| 15-18px | 16px | `p-4` |
| 19-22px | 20px | `p-5` |
| 23-28px | 24px | `p-6` |
| 29-36px | 32px | `p-8` |
| 37-48px | 40px | `p-10` |
| 49px 이상 | 가장 가까운 4배수 | `p-[Npx]` |

원본 값과 스냅 값이 3px 이상 차이나면 주석으로 원본 명시.

**Auto-layout → Flexbox/Grid 매핑 (검증용)**

`get_design_context`가 반환한 레이아웃을 검증하는 참조표:

| Figma | CSS | Tailwind |
|-------|-----|----------|
| `layoutMode: HORIZONTAL` | `display: flex; flex-direction: row` | `flex flex-row` |
| `layoutMode: VERTICAL` | `display: flex; flex-direction: column` | `flex flex-col` |
| `primaryAxisAlignItems: SPACE_BETWEEN` | `justify-content: space-between` | `justify-between` |
| `primaryAxisAlignItems: CENTER` | `justify-content: center` | `justify-center` |
| `counterAxisAlignItems: CENTER` | `align-items: center` | `items-center` |
| `counterAxisAlignItems: STRETCH` | `align-items: stretch` | `items-stretch` |
| `layoutWrap: WRAP` + HORIZONTAL | `display: flex; flex-wrap: wrap` | `flex flex-wrap` |
| `layoutMode: NONE` + 다수 자식 | Grid 검토 | `grid grid-cols-N` |
| `itemSpacing` | `gap` | `gap-N` |

`layoutSizingHorizontal: FILL` → `w-full`, `HUG` → `w-fit`, `FIXED` → `w-[Npx]`

### Phase 3: 코드 생성

`get_design_context`의 React + Tailwind 출력을 기반으로, Phase 2에서 정제한 토큰을 적용하여 최종 코드를 생성한다.

**`--component` 모드** — React/TSX 단일 컴포넌트:

```tsx
// 생성 예시
interface ButtonProps {
  label: string;
  variant?: 'primary' | 'secondary';
  onClick?: () => void;
}

export function Button({ label, variant = 'primary', onClick }: ButtonProps) {
  return (
    <button
      onClick={onClick}
      className={cn(
        'flex items-center justify-center px-4 py-2 rounded-lg text-sm font-medium',
        variant === 'primary' && 'bg-primary text-white',
        variant === 'secondary' && 'bg-surface text-primary border border-primary',
      )}
    >
      {label}
    </button>
  );
}
```

**`--page` 모드** — 전체 페이지 레이아웃. 섹션별 컴포넌트 분리 제안 포함.

**`--tokens` 모드** — `get_variable_defs` 결과를 프로젝트 토큰과 비교하여 추출:

```css
/* 신규 토큰 제안 */
:root {
  --color-accent-500: #6366F1;   /* Figma: #6366F1 — 기존 토큰 없음 */
  --spacing-18: 72px;             /* Figma: 72px — 비표준 값 */
}
```

프레임워크 우선순위:
1. 프로젝트에 Tailwind가 있으면 → Tailwind 클래스 기반 생성
2. Tailwind 없고 CSS modules 있으면 → CSS modules + CSS 변수
3. 둘 다 없으면 → 인라인 스타일 + CSS 변수 (마이그레이션 주석 포함)

이미지/아이콘 처리:
- 이미지 노드 → `<img src="/images/placeholder.png" alt="[이미지 설명]" />`
- 아이콘 컴포넌트 → `<Icon name="[아이콘명]" />` (실제 아이콘 라이브러리 import는 수동 연결 필요)

### Phase 4: 시각 검증 (선택)

`--component` 또는 `--page` 생성 후 Playwright로 렌더링 비교:

1. 생성된 컴포넌트를 임시 HTML/스토리북 환경에 마운트
2. Playwright 스크린샷 캡처 (동일 뷰포트)
3. Figma 노드 썸네일과 나란히 비교 출력

자동 실행 조건: Playwright MCP 사용 가능 + 개발 서버 실행 중일 때만 진행. 조건 미충족 시 단계 스킵하고 안내 메시지 출력.

## 출력 형식

```markdown
# Figma to Code Report

## 노드 정보
- 노드: [노드명] (FRAME / COMPONENT)
- 크기: 375x812
- Code Connect: [매핑 있음/없음]

## Figma 변수 (get_variable_defs)
| Figma 변수 | 값 | 프로젝트 토큰 매핑 |
|------------|-----|-------------------|
| colors/primary | #6366F1 | --color-primary (일치) |
| colors/error | #FF6B6B | (없음) → --color-error-400 제안 |

## 디자인 토큰 매핑
| Figma 값 | 매핑 토큰 | 신규 여부 |
|----------|-----------|-----------|
| #6366F1 | --color-primary (var) | 기존 |
| #F3F4F6 | --color-surface | 기존 |
| #FF6B6B | (없음) → --color-error-400 제안 | 신규 |

## 생성 코드
[get_design_context 기반 정제된 컴포넌트 코드 블록]

## 스냅 조정 내역
| 원본 | 조정 | 항목 |
|------|------|------|
| 13px padding | 12px (p-3) | CardWrapper padding-top |
| 22px gap | 20px (gap-5) | ListItem itemSpacing |

## 시각 검증
| — | 결과 |
|---|------|
| Figma 썸네일 vs 렌더링 | 유사도 92% (수동 확인 권장) |
```

## 주의사항

- **Figma Desktop 앱 + Dev Mode MCP 서버 필수**: `figma-dev-mode-mcp-server`가 `localhost:3845`에서 SSE로 실행 중이어야 함. Figma Desktop의 Dev Mode에서 MCP 서버를 활성화해야 한다.
- **선택 기반 동작**: 모든 MCP 도구는 Figma에서 **현재 선택된 노드**를 대상으로 동작. 명령 실행 전에 변환할 프레임/컴포넌트를 Figma에서 선택해야 함.
- **대규모 노드 주의**: 복잡한 페이지 전체를 선택하면 `get_design_context` 응답이 클 수 있음. `get_metadata`로 구조를 먼저 파악한 후 하위 노드를 개별 선택하여 처리.
- 색상 허용 오차(±5) 자동 매핑은 제안이며, 최종 결정은 디자이너와 협의.
- `--page` 모드로 생성된 코드는 반드시 반응형 처리를 별도로 검토 (`/publish-check` 연계 권장).
- 이미지/아이콘 placeholder는 실제 에셋 경로로 수동 교체 필요.
- 생성된 코드는 초안이며, 인터랙션(hover, focus, transition)은 수동 보완 필요.
