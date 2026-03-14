# 문서 포맷 규칙

모든 프로덕트 문서는 일관된 구조와 포맷을 따름.

## 1. 문서 구조 [CRITICAL]

모든 문서는 다음 헤더 포함:

```markdown
# [문서 제목]

- **작성자**:
- **작성일**: YYYY-MM-DD
- **상태**: Draft / In Review / Approved / Archived
- **관련**: [OKR/에픽/이슈 링크]

---

[본문]
```

## 2. 데이터 근거 [HIGH]

주장이나 결정에는 반드시 근거 데이터 포함.

```markdown
BAD:
"사용자들이 이 기능을 원합니다"
"시장이 성장하고 있습니다"

GOOD:
"CS 인입 중 23%가 해당 기능 요청 (2024 Q3 기준, n=847)"
"시장 규모 $12B, CAGR 15.3% (Gartner 2024)"
```

## 3. 액션 아이템 [HIGH]

모든 문서는 구체적인 다음 단계(Next Steps)로 끝남.

```markdown
BAD:
"추가 논의 필요"
"검토 후 진행"

GOOD:
## Next Steps
| 항목 | 담당 | 기한 |
|------|------|------|
| 사용자 인터뷰 5건 진행 | PM | 2024-03-15 |
| 기술 검토 미팅 | Tech Lead | 2024-03-12 |
```

## 4. 파일 저장 [MEDIUM]

```
plans/
├── prd-{feature-name}.md
├── roadmap-{year}-{quarter}.md
├── okr-{year}-{quarter}.md
├── research-{topic}-{date}.md
├── retro-sprint-{n}.md
├── story-map-{feature}.md
└── launch-{feature}.md
```
