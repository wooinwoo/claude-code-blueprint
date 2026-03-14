---
description: 디자인 시스템 관리. 토큰 정의, 컴포넌트 카탈로그 조회, 일관성 검사.
---

# Design System — 디자인 시스템 관리

## Usage

```
/design-system tokens              → 현재 디자인 토큰 목록 조회
/design-system audit               → 디자인 시스템 일관성 감사
/design-system component <name>    → 특정 컴포넌트 사용 현황 분석
/design-system suggest             → 디자인 시스템에 추가할 패턴 제안
```

## 기능

### `tokens` — 토큰 조회
1. CSS 변수, Tailwind 설정, 디자인 토큰 파일 탐색
2. 색상, 타이포그래피, 스페이싱, 브레이크포인트 정리
3. 사용 빈도와 함께 표시

### `audit` — 일관성 감사
1. 하드코딩된 값 탐지 (색상, 폰트, 여백)
2. 디자인 토큰 미사용 파일 목록
3. 미사용 토큰 식별
4. 중복 토큰 발견

### `component <name>` — 컴포넌트 분석
1. 해당 컴포넌트의 모든 사용처 검색
2. prop 사용 패턴 분석
3. 변형(variant) 목록 정리

### `suggest` — 패턴 제안
1. 반복되는 스타일 패턴 탐지
2. 컴포넌트화 가능한 UI 패턴 식별
3. 디자인 시스템 추가 제안서 생성

## 주의사항
- 디자인 토큰 소스: tailwind.config, CSS custom properties, 전용 토큰 파일 순 탐색
- Figma 디자인 참조 시 `mcp__figma-dev-mode-mcp-server__*` 도구 활용
