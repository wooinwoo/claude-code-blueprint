---
description: 컴포넌트 디스커버리. 현재 프로젝트의 UI 패턴/컴포넌트 현황 탐색 및 분석.
---

# Discover — 컴포넌트 디스커버리

## Usage

```
/discover                       → 현재 프로젝트의 UI 패턴/컴포넌트 전체 탐색
/discover --unused              → 미사용 컴포넌트 탐색
/discover --similar             → 유사/중복 컴포넌트 탐색
/discover --deps <component>    → 특정 컴포넌트 의존성 트리 분석
```

## 실행 절차

### Phase 1: 컴포넌트 파일 수집

Glob으로 컴포넌트 파일 수집 (프로젝트 루트 `path` 지정 필수):

```
Glob("**/*.{tsx,jsx,vue}", path="<project_root>/src/components")
Glob("**/*.{tsx,jsx,vue}", path="<project_root>/src/ui")
Glob("**/*.{tsx,jsx,vue}", path="<project_root>/app/components")
```

> 상대 경로 패턴은 Glob `path` 파라미터 없이 사용하면 0건 반환될 수 있다. 반드시 `path`를 프로젝트 루트 또는 대상 디렉토리 절대 경로로 지정.

각 파일에서 추출할 정보:
- 컴포넌트명 (파일명 기준)
- export 방식 (default / named)
- props 정의 (interface/type/defineProps)

### Phase 2: 사용처 카운트

Grep으로 각 컴포넌트의 import/사용 횟수 집계:

- `import.*<ComponentName>` 패턴으로 import 횟수
- `<ComponentName` 패턴으로 JSX/template 직접 사용 횟수
- 파일별 사용처 목록 수집

`--unused` 모드: 사용 횟수 0인 컴포넌트 필터링.

`--deps <component>` 모드: 대상 컴포넌트가 import하는 컴포넌트 + 대상을 import하는 컴포넌트를 재귀적으로 추적하여 의존성 트리 구성.

### Phase 3: 패턴 분석

수집된 데이터로 다음을 분석:

- **사용 빈도**: 상위/하위 컴포넌트 순위
- **유사 컴포넌트 그룹핑** (`--similar`): 컴포넌트 **정의** 기준으로 유사성 분석 (import/사용처는 제외)
  - **파일명 기반**: `*Badge*.tsx`, `*Card*.tsx` 등 접미사/접두사 공유 파일 그룹핑
  - **export 함수명 기반**: `Grep("export (default |)(function|const) \\w*(Badge|Card|Modal)", glob="src/components/**/*.tsx")`
  - Props 구조 유사도: 동일한 prop 이름을 3개 이상 공유하는 컴포넌트
  - 주의: 단순 import/사용을 검색하면 노이즈가 과다함 → 반드시 **정의(export)** 기준으로 탐색
- **고아 컴포넌트** (`--unused`): 단 한 곳에서도 import되지 않는 파일
- **순환 의존성** 감지: A→B→A 패턴

### Phase 4: 리포트 출력

분석 결과를 아래 출력 형식으로 정리하여 콘솔에 출력.

## 출력 형식

### 기본 (`/discover`)

```markdown
# Component Discovery Report

## 요약
- 전체 컴포넌트: N개
- 미사용: N개
- 유사/중복 의심: N그룹

## 컴포넌트 목록 (사용 빈도 순)
| 컴포넌트 | 경로 | 사용 횟수 | 비고 |
|----------|------|-----------|------|
| Button   | src/components/Button.tsx | 42 | — |
| Modal    | src/components/Modal.tsx  | 8  | — |
| OldCard  | src/components/OldCard.tsx | 0 | 미사용 의심 |
```

### 미사용 (`--unused`)

```markdown
# Unused Components

| 컴포넌트 | 경로 | 마지막 수정 |
|----------|------|-------------|
| OldCard  | src/components/OldCard.tsx | 2024-08-12 |
| TestModal | src/components/TestModal.tsx | 2024-06-03 |

→ 제거 전 git log로 히스토리 확인 권장
```

### 유사/중복 (`--similar`)

```markdown
# Similar/Duplicate Components

## 그룹 1: Card 계열 (3개)
- Card.tsx — 사용 23회
- CardItem.tsx — 사용 12회 (Card와 props 80% 유사)
- CardSmall.tsx — 사용 4회 (Card의 size="sm" 변형 가능성)
→ 제안: CardSmall을 Card size prop으로 통합 검토

## 그룹 2: ...
```

### 의존성 트리 (`--deps <component>`)

```markdown
# Dependency Tree: Button

## Button이 사용하는 컴포넌트 (하위 의존)
Button
└── Icon (src/components/Icon.tsx)
    └── SvgSprite (src/components/SvgSprite.tsx)

## Button을 사용하는 컴포넌트 (상위 의존)
Button ← Form (8회)
Button ← Modal (3회)
Button ← Header (2회)
Button ← ... (총 N개 컴포넌트)
```

## 주의사항

- 동적 import (`React.lazy`, `defineAsyncComponent`)는 정적 분석으로 감지되지 않을 수 있음. 결과에 `*동적 import 미포함*` 주석 표시.
- 스토리북(`.stories.tsx`) / 테스트(`.test.tsx`, `.spec.tsx`) 파일의 import는 사용 횟수에서 제외.
- `--unused` 결과를 곧바로 삭제하지 말고, `git log --follow` 로 히스토리 확인 후 판단.
- 모노레포 구조(패키지 간 cross-import)는 경로 패턴을 수동으로 보정 필요.
