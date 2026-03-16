# Curation Guide

sync.ps1로 ECC 업데이트를 가져올 때 **무엇을 포함/제외할지** 판단하는 기준서.
exclude.json 수정 시 이 문서를 참고한다.

## 포함 기준

### Agents
- `/orchestrate`, `/code-review` 파이프라인에서 호출되는 에이전트는 필수
- 스택별(react-next, nestjs)에 동명 에이전트가 있으면 **base는 제외** (setup.ps1이 같은 이름을 덮어쓰므로 base 것은 무의미)
- 모델 지정이 있는 범용 에이전트(opus/sonnet/haiku)는 유지

### Commands
- 실제 워크플로우에서 직접 호출하는 커맨드만 포함
- ECC 내부 메타 커맨드(ECC 관리용)는 제외
- common/에 대체 커맨드가 있으면 base 것은 제외

### Skills
- **에이전트가 `see skill: xxx`로 참조하는 스킬**은 필수
- **훅이 참조하는 스킬** (continuous-learning-v2, strategic-compact)은 필수
- 참조하는 에이전트/훅이 없는 독립 스킬은 아래 기준으로 판단:
  - 우리 스택(React/Next.js, NestJS, TypeScript, PostgreSQL)과 관련 → 유지
  - 범용 개발 패턴(docker, deployment, tdd) → 유지
  - 특정 기술 전용(ClickHouse, Nutrient PDF 등) → 제외
  - 메타/유틸(skill-stocktake, project-guidelines-example) → 제외
  - 니치 패턴(regex-vs-llm, content-hash-cache 등) → 제외

### Rules
- 가볍고 항상 로딩되므로 웬만하면 다 유지
- 미사용 언어(Go, Python, Swift)만 제외

## 제외 사유 분류

| 코드 | 사유 | 예시 |
|------|------|------|
| `lang` | 미사용 언어/플랫폼 | Go, Python, Swift, iOS, C++, Java, Django, Spring Boot |
| `dup` | 스택별에 동명 파일 있어서 base 것이 무의미 | base/agents/code-reviewer (react-next에 동명 존재) |
| `meta` | ECC 관리용 메타 도구 | configure-ecc, skill-stocktake, project-guidelines-example |
| `niche` | 우리 스택과 무관한 특정 기술 | ClickHouse, Nutrient PDF, content-hash-cache |
| `biz` | 개발과 무관한 비즈니스 도구 | investor-materials, article-writing, market-research |
| `unused` | 아무 에이전트/훅도 참조하지 않고 실용성 낮음 | regex-vs-llm, cost-aware-llm-pipeline |
| `replaced` | common/에 대체 커맨드가 있음 | base/commands/orchestrate → common/ or stack/ 에 있음 |

## 현재 제외 목록 (2026-03-03 sync 기준)

### Rules (3 폴더)
| 항목 | 사유 |
|------|------|
| golang/ | lang |
| python/ | lang |
| swift/ | lang |

### Agents (5개)
| 항목 | 사유 |
|------|------|
| go-build-resolver.md | lang |
| go-reviewer.md | lang |
| python-reviewer.md | lang |
| chief-of-staff.md | biz — 커뮤니케이션 트리아지, 개발 무관 |
| code-reviewer.md | dup — react-next/nestjs 에 동명 존재 |

### Commands (37개)
| 항목 | 사유 |
|------|------|
| go-build.md, go-review.md, go-test.md | lang |
| python-review.md | lang |
| multi-backend/execute/frontend/plan/workflow.md | replaced — /orchestrate로 통합 |
| pm2.md | unused |
| sessions.md | meta |
| checkpoint.md | meta |
| claw.md | meta — NanoClaw REPL |
| learn-eval.md | meta |
| promote.md | meta |
| build-fix.md | replaced — common/commands/build-fix.md |
| code-review.md | replaced — common/commands/code-review.md |
| refactor-clean.md | replaced — common/commands/refactor-clean.md |
| e2e.md | replaced — e2e-runner 에이전트가 직접 처리 |
| eval.md | meta |
| evolve.md | meta — continuous-learning 내부 |
| instinct-export/import/status.md | meta — continuous-learning 내부 |
| learn.md | replaced — common/commands/learn.md |
| orchestrate.md | replaced — stack별 orchestrate.md |
| plan.md | replaced — planner 에이전트가 직접 처리 |
| setup-pm.md | meta |
| skill-create.md | meta |
| tdd.md | replaced — tdd-guide 에이전트가 직접 처리 |
| test-coverage.md | replaced — react-next/commands/test-coverage.md |
| update-docs.md | replaced — doc-updater 에이전트가 직접 처리 |

### Skills (39개)
| 항목 | 사유 |
|------|------|
| django-patterns/security/tdd/verification | lang |
| springboot-patterns/security/tdd/verification | lang |
| golang-patterns, golang-testing | lang |
| python-patterns, python-testing | lang |
| java-coding-standards, jpa-patterns | lang |
| swift-actor-persistence, swift-concurrency-6-2, swift-protocol-di-testing | lang |
| swiftui-patterns, liquid-glass-design, foundation-models-on-device | lang |
| cpp-coding-standards, cpp-testing | lang |
| configure-ecc | meta |
| skill-stocktake | meta |
| project-guidelines-example | meta |
| backend-patterns | dup — frontend-patterns + api-design로 커버 |
| article-writing, content-engine | biz |
| investor-materials, investor-outreach | biz |
| market-research | biz |
| visa-doc-translate | biz |
| frontend-slides | biz — 프레젠테이션 슬라이드 |
| continuous-learning (v1) | replaced — v2가 있음 |
| clickhouse-io | niche — ClickHouse 미사용 |
| nutrient-document-processing | niche — PDF 처리 |
| content-hash-cache-pattern | niche |
| cost-aware-llm-pipeline | niche — LLM 파이프라인 빌드 전용 |
| regex-vs-llm-structured-text | niche |
| security-scan | niche — AgentShield CI 전용 |

## 지원 스택

| 스택 | 대상 | base-typescript 룰 | 스택 전용 |
|------|------|-------------------|-----------|
| `react-next` | React/Next.js + TypeScript | O | agents 8, commands 3, rules 5, skills 3 |
| `nestjs` | NestJS + TypeScript | O | agents 8, commands 2, rules 2, skills 1 |
| `java-web` | Spring Boot + JSP + CSS | **X (스킵)** | agents 2, commands 1, rules 2 |

### java-web 스택 특이사항
- `base/rules/typescript/` 제외 — Java 프로젝트에 TS 룰 불필요
- base hooks 중 TS 전용 (post-edit-format, typecheck, console-warn)은 확장자 체크로 자동 no-op
- 스킬 없음 — JSP/CSS 수정 위주라 레퍼런스 스킬 불필요
- 에이전트 2개만: code-reviewer (Java/JSP/CSS), security-reviewer (SQL injection, XSS)

## 다음 패치 시 체크리스트

1. `sync.ps1` 실행 후 `git status`에서 새 파일(untracked) 확인
2. 새 에이전트: 어떤 커맨드/파이프라인에서 호출되는지 확인 → 호출처 없으면 제외 검토
3. 새 스킬: `see skill: xxx` 참조하는 에이전트가 있는지 grep → 없으면 제외 검토
4. 새 커맨드: common/ 또는 stack/에 대체가 있는지 확인 → 있으면 제외
5. 새 룰: 우리 스택 관련인지 확인 → 아니면 제외
6. 이 문서의 제외 목록 업데이트
7. exclude.json 수정 후 `sync.ps1` 재실행
