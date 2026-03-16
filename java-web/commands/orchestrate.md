---
description: Java 웹 프로젝트 변경 파이프라인. JSP/CSS/Java 수정을 계획 → 구현 → 검증 → PR 순서로 진행.
arguments: Jira 이슈 키 또는 작업 설명
---

# /orchestrate — Java Web Pipeline

## Usage

```
/orchestrate PMSB-123
/orchestrate 급여 목록 페이지 테이블 UI 개선
```

## Phase 1: Plan

1. Jira 이슈가 있으면 `mcp__mcp-atlassian__jira_get_issue`로 상세 조회
2. 없으면 사용자에게 Q&A (최대 3개 질문)
3. 영향 받는 파일 파악:
   - JSP: `src/main/webapp/` 아래 관련 페이지
   - CSS: `src/main/webapp/css/pms/` 아래 관련 스타일시트
   - Java: Controller/Service/Mapper 변경 필요 여부
   - MyBatis: `src/main/resources/mapper/` 매퍼 변경 필요 여부
4. **planner** 에이전트로 구현 계획 작성
5. 사용자 확인 후 진행

## Phase 2: Branch

```bash
git checkout -b feature/{jira-key}-{slug}
# 또는
git checkout -b fix/{jira-key}-{slug}
```

## Phase 3: Develop

구현 + 검증 루프 (최대 3회):

1. JSP/CSS/Java 파일 수정
2. 검증:
   ```bash
   # Gradle 빌드 확인
   ./gradlew classes
   # JSP 컴파일 에러 확인 (bootRun으로 확인)
   ./gradlew bootRun &
   sleep 10
   curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/
   ```
3. 빌드 실패 시 **build-error-resolver** 에이전트 호출
4. 성공 시 Phase 4로

## Phase 4: Review & PR

1. **code-reviewer** 에이전트로 코드 리뷰
2. **security-reviewer** 에이전트로 보안 점검
3. CRITICAL/HIGH 이슈 수정
4. 커밋 + PR 생성:
   ```bash
   git add -A
   git commit -m "feat(PMSB-123): 급여 목록 테이블 UI 개선"
   git push -u origin HEAD
   gh pr create --title "feat(PMSB-123): 급여 목록 테이블 UI 개선" --body "..."
   ```

## Phase 5: Clean

```bash
git checkout main
git branch -d feature/{jira-key}-{slug}
```

## 상태 추적

`.orchestrate/{slug}.json`에 상태 저장. 중단 시 `/orchestrate` 재실행하면 이어서 진행.

## 주의사항

- JSP 수정 시 `<c:out>`으로 XSS 방지 필수
- MyBatis 매퍼 수정 시 `#{}` 바인딩 필수 (`${}` 금지)
- CSS 수정 시 기존 Tailwind 클래스와 충돌 확인
- 빌드 확인 없이 PR 생성 금지
