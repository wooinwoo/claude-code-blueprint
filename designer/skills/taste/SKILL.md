---
name: taste
description: Use this skill to ensure high design quality and avoid generic AI aesthetics. Provides opinionated design guidance for distinctive, memorable interfaces.
---

# Taste Skill — 디자인 감각 가이드

제네릭한 AI 미학을 넘어서 독창적이고 기억에 남는 인터페이스를 만들기 위한 가이드.

## When to Activate

- 새로운 디자인 시스템 구축
- 랜딩 페이지/마케팅 페이지 제작
- UI의 "느낌"을 결정할 때
- 디자인이 "AI스럽다"는 피드백을 받았을 때

## Anti-Patterns

구체적인 BAD/GOOD 코드 예시는 `rules/anti-ai-slop.md` 참조. 이 스킬은 "왜 피해야 하는지" 판단 기준을 제공.

- 제네릭한 것을 피하려면: **이 디자인이 브랜드 로고를 가려도 우리 제품인지 알 수 있는가?**
- AI스러운 것을 피하려면: **이 디자인을 3번 재생성하면 매번 비슷한 결과가 나오는가?** (나온다면 제네릭)

## Good Taste Principles

### 제약이 창의성을 만든다
- 색상: 1-2개 악센트 컬러만 사용
- 폰트: 2개 이하 (1개도 충분)
- 여백: 넉넉하게 — 공간은 고급스러움의 표현

### 디테일이 차이를 만든다
- 마이크로 인터랙션 (hover 트랜지션, 포커스 링)
- 의도적인 타이포그래피 (tracking, leading 미세조정)
- 그리드 깨기: 의도적 비대칭으로 시각적 흥미

### 콘텐츠가 디자인이다
- 더미 텍스트(Lorem ipsum) 사용 금지
- 실제 데이터와 카피로 디자인
- 에지 케이스 (긴 텍스트, 빈 상태) 고려

## Design Decision Framework
1. **누구를 위한 디자인인가?** (사용자 프로필)
2. **어떤 감정을 전달할 것인가?** (신뢰/에너지/평온/전문성)
3. **경쟁자와 어떻게 다른가?** (차별점)
