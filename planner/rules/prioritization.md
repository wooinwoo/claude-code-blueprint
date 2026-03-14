# 우선순위 결정 규칙

객관적이고 일관된 우선순위 결정을 위한 프레임워크.

## 1. RICE 프레임워크 [CRITICAL]

모든 백로그 우선순위는 RICE 스코어 기반.

```
RICE = (Reach × Impact × Confidence) / Effort

Reach: 분기당 영향받는 사용자 수
Impact: 0.25 (minimal) / 0.5 (low) / 1 (medium) / 2 (high) / 3 (massive)
Confidence: 0.5 (low) / 0.8 (medium) / 1.0 (high)
Effort: 인-스프린트 (1 sprint = 1.0)
```

```markdown
BAD:
"이 기능이 더 중요하다고 생각합니다"
"긴급해서 먼저 해야 합니다"

GOOD:
| 기능 | Reach | Impact | Confidence | Effort | RICE |
|------|-------|--------|------------|--------|------|
| 기능A | 5000 | 2 | 0.8 | 2 | 4000 |
| 기능B | 1000 | 3 | 1.0 | 1 | 3000 |
→ 기능A 우선 (RICE 4000 > 3000)
```

## 2. 긴급/중요 구분 [HIGH]

아이젠하워 매트릭스로 긴급과 중요 구분.

| | 긴급 | 비긴급 |
|---|---|---|
| **중요** | 즉시 실행 | 계획 수립 |
| **비중요** | 위임 | 제거 |

## 3. 의존성 고려 [HIGH]

```markdown
BAD:
RICE만으로 순서 결정 (의존성 무시)

GOOD:
## 의존성 맵
기능A → 기능C (기능A 완료 후 기능C 가능)
기능B → (독립)

→ RICE: A(4000) > C(3500) > B(3000)
→ 최종: A → C → B (의존성 반영)
```

## 4. 리스크 가중치 [MEDIUM]

높은 리스크 항목은 RICE에 리스크 계수 적용.

```
Adjusted RICE = RICE × Risk Factor
Risk Factor: 1.0 (low risk) / 0.8 (medium) / 0.5 (high risk)
```
