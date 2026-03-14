---
name: deep-research
description: Use this skill for deep web research using multiple search strategies. Combines broad searches, focused queries, and source validation.
---

# Deep Research Skill

다중 검색 전략을 활용한 심층 웹 리서치.

## When to Activate

- 깊이 있는 리서치가 필요할 때
- 여러 소스에서 교차 검증이 필요할 때
- 최신 데이터/트렌드 수집
- 전문적인 산업 정보 검색

## Search Strategy

### 1. Broad → Focused
```
Round 1: 넓은 키워드로 시장 개요 파악
Round 2: 발견된 핵심 키워드로 심화 검색
Round 3: 특정 데이터 포인트 타겟 검색
```

### 2. Source Triangulation
```markdown
각 핵심 데이터 포인트에 대해:
1. 공식 소스 (정부, 기관)
2. 산업 보고서 (Gartner, IDC, McKinsey)
3. 전문 미디어 (TechCrunch, The Information)
→ 3개 소스 교차 확인 후 확신도 부여
```

### 3. Temporal Search
```
같은 주제를 시간대별로 검색:
- "[주제] 2024" / "[주제] 2025" → 트렌드 파악
- "[주제] forecast" / "[주제] prediction" → 전망
```

## Validation Checklist
- [ ] 출처가 1차 소스인가?
- [ ] 발행일이 최근인가?
- [ ] 저자/기관의 전문성은?
- [ ] 다른 소스에서 확인 가능한가?
- [ ] 이해충돌(conflict of interest)은?

## Output Format
```markdown
### [검색 주제]

**핵심 발견**: [한 줄 요약]

**데이터 포인트**:
| 데이터 | 소스 | 날짜 | 신뢰도 |
|--------|------|------|--------|

**인사이트**: [분석]
**한계**: [주의사항]
```
