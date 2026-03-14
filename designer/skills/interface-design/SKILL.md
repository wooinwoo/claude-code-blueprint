---
name: interface-design
description: Use this skill when designing complete interfaces or screens. Covers information architecture, user flow design, and interaction patterns.
---

# Interface Design Skill

완전한 인터페이스/화면 설계를 위한 정보 구조, 사용자 흐름, 인터랙션 패턴 가이드.

## When to Activate

- 새로운 화면/페이지 설계
- 사용자 흐름(user flow) 설계
- 인터랙션 패턴 결정
- 네비게이션 구조 설계

## Information Architecture

### 콘텐츠 계층
1. **Primary Action**: 화면당 1개의 주요 액션
2. **Visual Hierarchy**: F패턴 또는 Z패턴 고려
3. **Progressive Disclosure**: 필수 정보만 먼저, 상세는 접기/모달

### 네비게이션 패턴
| 패턴 | 사용 시점 |
|------|-----------|
| Top Nav | 5개 이하 주요 메뉴 |
| Side Nav | 깊은 계층, 많은 메뉴 |
| Tab Bar | 모바일, 3-5개 주요 섹션 |
| Breadcrumb | 깊은 계층 탐색 |

## Interaction Patterns

### 상태 표시
- **Loading**: skeleton > spinner (레이아웃 시프트 방지)
- **Empty**: 일러스트 + 안내 메시지 + CTA
- **Error**: 인라인 에러 > 토스트 > 모달 (심각도 순)
- **Success**: 토스트 (자동 사라짐) 또는 인라인 확인

### 폼 디자인
- 레이블은 입력 필드 위 (모바일 친화적)
- 실시간 유효성 검사 (blur 시)
- 에러 메시지는 필드 바로 아래
- 제출 버튼은 비활성화 대신 에러 표시
