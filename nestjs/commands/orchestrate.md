---
description: NestJS feature pipeline with worktree isolation. Plan → Branch → Develop → Merge & PR. Use --full for maximum quality.
---

# Orchestrate — NestJS Pipeline

## Usage

```
/orchestrate 1:1 문의 기능 추가
/orchestrate --full 1:1 문의 기능 추가
/orchestrate GIFCA-123
/orchestrate --full GIFCA-123
/orchestrate                → 현재 phase 감지 후 자동 진행
```

## Mode

| 모드 | 플래그 | 에이전트 | 설명 |
|------|--------|---------|------|
| **Standard** | (기본) | 4-7개 | 빠른 반복. 선택적 리뷰, 1라운드 |
| **Full** | `--full` | 10-12개 | 최대 품질. 코드베이스 스캔 + architect 설계 + TDD + 전원 리뷰 2라운드 |

state 파일에 `"mode"` 저장 → 세션 복구 시 모드 자동 유지.

## Pipeline Detection

**`.orchestrate/` 디렉토리의 `{slug}.json` 파일로 파이프라인을 추적합니다.**

여러 기능을 동시에 진행할 수 있습니다 (기능별 state 파일 분리).

### 파이프라인 선택

| 상황 | 동작 |
|------|------|
| `/orchestrate 문의 기능` | 새 파이프라인 시작 → `.orchestrate/{slug}.json` 생성 |
| `/orchestrate` + state 1개 | 그 파이프라인 이어감 |
| `/orchestrate` + state 여러개 | 현재 브랜치(`git branch --show-current`)로 매칭. 못 찾으면 목록 → AskUserQuestion |
| `/orchestrate` + state 0개 | 아래 **신규 파이프라인 가이드** 실행 |

### 신규 파이프라인 가이드 (인수 없이 진입 시)

인수 없이 `/orchestrate`를 실행했고 진행 중인 파이프라인이 없으면, 순서대로 질문합니다:

```typescript
// Step 1: 뭘 만들지
AskUserQuestion([{
  question: "어떤 기능을 만들까요?",
  header: "기능 설명",
  description: "자연어로 설명하거나, Jira 이슈 키(예: PROJ-123)를 입력하세요."
}])

// Step 2: 모드 선택
AskUserQuestion([{
  question: "어떤 모드로 진행할까요?",
  header: "파이프라인 모드",
  options: [
    { label: "Standard", description: "빠른 반복. 에이전트 4-7개, 리뷰 1라운드" },
    { label: "Full", description: "최대 품질. 코드베이스 스캔 + architect 설계 + TDD + 리뷰 2라운드 (에이전트 10-12개)" }
  ]
}])
```

이후 선택된 모드에 따라 Phase 0(Full) 또는 Phase 1(Standard)부터 시작합니다.

### Phase 감지

state 파일에서 **`phase`와 `mode`를 모두 읽습니다**:

```bash
# 세션 복구 시 반드시 두 값 모두 추출
phase=$(jq -r '.phase' .orchestrate/{slug}.json)
mode=$(jq -r '.mode' .orchestrate/{slug}.json)   # "standard" 또는 "full"
```

이후 모든 `> **모드 분기**` 지시에서 이 `mode` 값을 사용합니다.

state 파일의 `phase` 값:

- `"scan"` → **Phase 0: Scan** (full 모드)
- `"branch"` → **Phase 2: Branch**
- `"develop"` → **Phase 3: Develop**
- `"done"` → **Phase 4: PR**
- `"pr"` → **Phase 5: Feedback**
- `"complete"` → **Phase 6: Clean**

```
[Full] Phase 0: Scan  → 기존 코드베이스 패턴 스캔
                         ↓ 자동 연결
Phase 1: Plan          → 사용자와 플랜 협업 → 승인
                         ↓ 자동 연결 (승인 후 멈추지 않고 계속)
Phase 2: Branch        → 워크트리 + 브랜치 생성
                         ↓ 자동 연결
Phase 3: Develop       → 워크트리에서 구현
                         ↓ 자동 연결
Phase 4: PR            → 검증 → 에이전트 리뷰 → 커밋 → PR 생성
                         ■ 여기서 정지 (리뷰 대기)
Phase 5: Feedback      → PR 코멘트 반영 (반복)   ← /orchestrate 수동 호출
Phase 6: Clean         → PR 병합 확인 → 워크트리/브랜치 삭제
```

### 자동 연결 규칙

Phase 1 승인 후 **Phase 2→3→4를 한 번에 실행**합니다. 중간에 멈추지 않습니다.
사용자 입력이 필요한 시점은 **Phase 1 (플랜 승인)**과 **Phase 5 (리뷰 피드백)** 뿐입니다.

state 파일의 phase 값은 **세션 복구용**입니다. 세션이 중간에 끊기면 `/orchestrate`로 해당 phase부터 이어갑니다.

---

## Phase 0: Codebase Scan

> **모드 분기**: state 파일의 `mode` 또는 `--full` 플래그를 확인합니다.
> - `mode == "standard"` → **이 Phase 전체를 건너뛰고 Phase 1로 직행합니다.**
> - `mode == "full"` → 아래 0-1부터 실행합니다.

기존 코드베이스의 패턴과 컨벤션을 먼저 파악합니다. 이 결과는 Phase 1 설계와 Phase 3 구현의 **컨텍스트로 전달**됩니다.

### 0-1. 패턴 스캔 에이전트

```
Codebase Scanner (subagent_type: general-purpose)
prompt: "프로젝트 {project_path}에서 '{feature_description}'과 유사한 기존 구현을 찾아줘.

찾을 것:
- 비슷한 Use Case/Controller가 이미 있는지
- 재사용 가능한 Entity, Value Object, Domain Service
- DI 패턴 (Symbol token 등록 방식, Module provider 구조)
- Repository 패턴 (Drizzle ORM 사용법, Mapper 구조)
- 에러 처리 패턴 (Domain Error, Exception Filter)
- E2E 테스트 패턴 (supertest, 테스트 DB 설정)
- 마이그레이션 패턴 (Drizzle migrate, 스키마 변경 이력)

반드시 아래 형식으로 응답해줘:

## Reusable Assets
- `src/path/Entity.ts` — {재사용 가능 이유}

## Patterns to Follow
- **Entity**: {패턴 설명 + 예시 파일 경로}
- **Repository**: {패턴 설명 + 예시 파일 경로}
- **Use Case**: {패턴 설명 + 예시 파일 경로}
- **Controller/DTO**: {패턴 설명 + 예시 파일 경로}
- **Module**: {패턴 설명 + 예시 파일 경로}
- **E2E Test**: {패턴 설명 + 예시 파일 경로}

## Folder Convention
- Domain: {경로 패턴}
- Infrastructure: {경로 패턴}
- Application: {경로 패턴}

## Anti-Patterns
- {기존 코드에서 발견된 피해야 할 패턴 + 이유}"
```

### 0-2. 스캔 결과 저장

```bash
mkdir -p plans
```

스캔 결과를 `plans/{slug}-scan.md`에 저장합니다. Phase 1, 3에서 참조합니다.

**멈추지 않고 바로 Phase 1을 실행합니다.**

---

## Phase 1: Plan

사용자와 함께 기능 플랜을 작성합니다.

### 1-0. 권한 사전 요청

**파이프라인 시작 시 필요한 모든 권한을 한 번에 요청합니다:**

```typescript
// Phase 2-6에서 사용할 모든 git/bash 명령어 권한 사전 요청
// 사용자가 한 번만 승인하면 이후 자동 진행
allowedPrompts: [
  { tool: "Bash", prompt: "git operations (add, commit, push, checkout, branch, worktree)" },
  { tool: "Bash", prompt: "build and validation (install, biome check, build, test)" },
  { tool: "Bash", prompt: "GitHub CLI operations (gh pr create, view)" },
  { tool: "Bash", prompt: "file operations (cp, mv, rm, mkdir)" }
]
```

### 1-1. Jira 확인

```
기존 Jira 이슈가 있나요?
- Yes: 이슈 키 입력 (예: GIFCA-123)
- No: 새로 생성
- Standalone: Jira 없이 진행
```

### 1-2. 요구사항 Q&A

AskUserQuestion으로 핵심을 명확히:

- **목적과 사용자 가치**
- **API 엔드포인트 스펙** — method, path, request/response
- **비즈니스 규칙과 검증 로직**
- **에러 처리 시나리오**
- **외부 서비스 연동**

### 1-3. Jira 이슈 생성 (필요시)

> 이미 이슈가 있거나 standalone이면 스킵

### 1-4. 플랜 작성

> **모드 분기**: `mode` 값에 따라 아래 **해당 모드 섹션만** 실행합니다.

#### Standard 모드

`plans/{identifier}.md` 생성:

```markdown
# {feature name}

## Tracking
- Issue: {JIRA-KEY 또는 standalone}

## Requirements
{Q&A 결과 정리}

## Affected Layers

### Domain (@gifca/core)
- [ ] Entity: {EntityName}
- [ ] Repository Interface: I{Name}Repository
- [ ] Domain Error: {ErrorName}

### Infrastructure (@gifca/core)
- [ ] Mapper: {Name}Mapper
- [ ] Repository Impl: Drizzle{Name}Repository

### Application (@gifca/app)
- [ ] Use Case: {ActionName}UseCase
- [ ] Controller: {Name}Controller
- [ ] Request DTO: {Action}RequestDto
- [ ] Response DTO: {Action}ResponseDto
- [ ] E2E Test: {name}.e2e-spec.ts

## Implementation Order
1. Entity + Repository Interface + Domain Error
2. Mapper + Repository Impl (Drizzle)
3. Use Case (@Transactional, DI with Symbol)
4. Controller + DTOs + Module registration
5. E2E Test
```

#### [Full] Full 모드 — Architect 설계

Standard 플랜 대신, **architect(opus) 에이전트가 심층 설계 문서를 작성**합니다.

```
Architect Agent (subagent_type: general-purpose, model: opus)
prompt: "코드베이스 스캔 결과: {Phase 0 scan_result}
요구사항: {Q&A 결과}
프로젝트 경로: {project_path}

다음을 설계해줘:

1. **모듈 의존성 그래프** — Module → Provider → Repository → Entity 계층도 (ASCII)
2. **Use Case 시퀀스** — Controller → UseCase → Repository → DB 흐름 (ASCII)
3. **인터페이스 계약** — 실제 TypeScript 코드:
   - Entity (private constructor + create/reconstitute + 도메인 메서드)
   - Repository Interface (Symbol token)
   - Use Case (입력/출력 타입)
   - Request/Response DTO (class-validator 데코레이터)
   - Domain Error
4. **DB 스키마 설계** — 테이블, 컬럼, 타입, 제약조건, 인덱스
5. **에러 시나리오 매트릭스** — 각 실패 시 HTTP 상태코드 + 응답 body

Phase 0 스캔에서 발견된 기존 패턴과 재사용 에셋을 최대한 활용해줘.
기존 코드와 일관된 패턴을 유지해줘.

반드시 아래 형식으로:

## Module Dependency Graph
(ASCII 다이어그램)

## Use Case Sequence
(ASCII 시퀀스 다이어그램)

## Interface Contracts
\`\`\`typescript
// === Entity ===
// === Repository Interface ===
// === Use Case Types ===
// === DTOs ===
// === Domain Errors ===
\`\`\`

## DB Schema Design
| Table | Column | Type | Constraints | Index |
|-------|--------|------|-------------|-------|

## Error Matrix
| Scenario | HTTP Status | Error Code | Response Body |
|----------|------------|------------|---------------|

## Reused Assets (from Phase 0)
- {재사용한 에셋과 이유}

## Implementation Groups
### Group 1 (병렬 가능) — Domain + Infrastructure
- Task 1-A: Entity + Repository Interface + Domain Error → 파일 목록 → 완료 기준
- Task 1-B: Mapper + Repository Impl → 파일 목록 → 완료 기준
### Group 2 (Group 1 완료 후) — Application
- Task 2-A: Use Case + Controller + DTOs + Module → 파일 목록 → 완료 기준
### Group 3 (Group 2 완료 후) — Test
- Task 3-A: E2E Test → 파일 목록 → 완료 기준

## TDD Anchors
- Task 1-A: '{Entity 생성/재구성 테스트}' 먼저 작성
- Task 2-A: '{Use Case 성공/실패 테스트}' 먼저 작성
- Task 3-A: '{E2E 성공 + 400/401/404/409 테스트}' 먼저 작성
"
```

Architect 산출물을 `plans/{identifier}.md`에 저장합니다.

### 1-5. 플랜 검증 에이전트

> **모드 분기**: `mode` 값에 따라 아래 **해당 모드 섹션만** 실행합니다.

#### Standard 모드 — 2개 병렬 (+ Schema 선택적)

플랜을 사용자에게 보여주기 전에, **2개의 Task tool을 병렬 호출**하여 플랜을 검증합니다:

```
Task A — Feasibility Review (subagent_type: general-purpose) — 필수
prompt: "다음 구현 플랜을 검토해줘: {plan 내용}
프로젝트 경로: {project_path}
기존 코드베이스를 읽고, 이 플랜이 기술적으로 타당한지 점검해줘.
체크 항목:
- 기존 코드와 충돌하는 설계가 있는지
- 누락된 의존성이나 선행 작업이 있는지
- 기술적으로 불가능하거나 비효율적인 접근이 있는지
- DB 스키마 변경이 필요한지 (마이그레이션)
- 더 나은 대안이 있는지

반드시 아래 형식으로 응답해줘:
## Verdict: PASS | PASS_WITH_WARNINGS | FAIL
## Risks
### [Critical/High/Medium/Low] {리스크 제목}
- **Impact**: {영향}
- **Mitigation**: {해결 방법}
## DB Migration Required: YES | NO
- {필요 시 마이그레이션 내용}
## Recommendations
- {권장 사항}"

Task B — Impact Analysis (subagent_type: general-purpose) — 필수
prompt: "다음 구현 플랜이 기존 코드에 미치는 영향을 분석해줘: {plan 내용}
프로젝트 경로: {project_path}
체크 항목:
- 변경이 필요한 기존 파일 목록과 신규 생성 파일
- 영향받는 기존 API 엔드포인트
- 영향받는 기존 모듈/서비스/Use Case
- DB 영향 (테이블 변경, 마이그레이션, 인덱스)
- 사이드 이펙트 가능성 (E2E 테스트, 프론트엔드 영향)

반드시 아래 형식으로 응답해줘:
## Impact Score: LOW | MEDIUM | HIGH
## Files
### New Files
- `src/path/file.ts` — {레이어} — {역할}
### Modified Files
- `src/path/existing.ts` — {변경 내용과 이유}
## DB Impact
- {테이블/컬럼/인덱스 변경 사항}
## Side Effects
- {사이드 이펙트 설명}
## Dependencies
- {선행 작업이 필요한 항목}"
```

**Feasibility 결과에서 다음 중 하나라도 언급되면, Schema Design 에이전트 추가 호출:**
- "DB 마이그레이션 필요", "테이블 추가/변경", "컬럼 추가/수정/삭제"
- "스키마 변경", "인덱스 추가/변경", "외래키 변경", "제약조건 변경"
- 또는 응답에 "database", "schema", "migration", "table", "column" 키워드 포함

```
Task C — Schema Design Review (subagent_type: general-purpose) — 선택적
prompt: "다음 구현 플랜의 DB 스키마 설계를 검토해줘: {plan 내용}
프로젝트 경로: {project_path}
기존 스키마 파일을 읽고, 다음을 검토해줘:
체크 항목:
- 데이터 모델링: 엔티티 구조, 관계 설정 (1:1, 1:N, N:M)
- 정규화: 중복 제거, 적절한 정규화 수준
- 타입 선택: 컬럼 타입, nullable, default 값
- 제약조건: PK, FK, unique, check 제약
- 인덱스 계획: 쿼리 패턴에 맞는 인덱스
- 네이밍 컨벤션: 테이블/컬럼명 일관성
문제가 있으면 구체적으로 알려줘."
```

#### [Full] Full 모드 — 4개 병렬

Standard의 Task A(Feasibility), B(Impact)에 **C(Architecture) + D(Schema)를 항상 추가**하여 4개를 병렬 호출합니다.
Standard에서 Schema가 Task C였지만, Full에서는 Architecture가 Task C, Schema가 Task D로 재배정됩니다.

```
Task A — Feasibility Review (subagent_type: general-purpose) — 필수
prompt: "다음 구현 플랜을 검토해줘: {plan 내용}
프로젝트 경로: {project_path}
기존 코드베이스를 읽고, 이 플랜이 기술적으로 타당한지 점검해줘.
체크 항목:
- 기존 코드와 충돌하는 설계가 있는지
- 누락된 의존성이나 선행 작업이 있는지
- 기술적으로 불가능하거나 비효율적인 접근이 있는지
- DB 스키마 변경이 필요한지 (마이그레이션)
- 더 나은 대안이 있는지

반드시 아래 형식으로 응답해줘:
## Verdict: PASS | PASS_WITH_WARNINGS | FAIL
## Risks
### [Critical/High/Medium/Low] {리스크 제목}
- **Impact**: {영향}
- **Mitigation**: {해결 방법}
## DB Migration Required: YES | NO
- {필요 시 마이그레이션 내용}
## Recommendations
- {권장 사항}"

Task B — Impact Analysis (subagent_type: general-purpose) — 필수
prompt: "다음 구현 플랜이 기존 코드에 미치는 영향을 분석해줘: {plan 내용}
프로젝트 경로: {project_path}
체크 항목:
- 변경이 필요한 기존 파일 목록과 신규 생성 파일
- 영향받는 기존 API 엔드포인트
- 영향받는 기존 모듈/서비스/Use Case
- DB 영향 (테이블 변경, 마이그레이션, 인덱스)
- 사이드 이펙트 가능성 (E2E 테스트, 프론트엔드 영향)

반드시 아래 형식으로 응답해줘:
## Impact Score: LOW | MEDIUM | HIGH
## Files
### New Files
- `src/path/file.ts` — {레이어} — {역할}
### Modified Files
- `src/path/existing.ts` — {변경 내용과 이유}
## DB Impact
- {테이블/컬럼/인덱스 변경 사항}
## Side Effects
- {사이드 이펙트 설명}
## Dependencies
- {선행 작업이 필요한 항목}"

Task C — Architecture Review (subagent_type: general-purpose) — Full 전용
prompt: "다음 설계 문서를 아키텍처 관점에서 검토해줘: {plan 내용}
프로젝트 경로: {project_path}
코드베이스 스캔 결과: {Phase 0 scan_result}

체크 항목:
- **레이어 분리**: Domain이 Infrastructure에 의존하지 않는지, Use Case가 Controller에 의존하지 않는지
- **DI 설계**: Symbol token 사용, 순환 참조, Module provider 구조
- **트랜잭션 경계**: @Transactional 범위, 데드락 가능성
- **확장성**: 유사 기능 추가 시 수정 범위
- **기존 일관성**: Phase 0에서 파악한 패턴과 설계가 일치하는지

반드시 아래 형식으로 응답해줘:
## Verdict: PASS | PASS_WITH_WARNINGS | FAIL
## Layer Violations
- {레이어 분리 위반과 해결 방안}
## DI Issues
- {DI 설계 문제와 해결 방안}
## Transaction Issues
- {트랜잭션 경계 문제와 해결 방안}
## Consistency Issues
- {기존 패턴과 불일치하는 부분과 수정 방안}
## Recommendations
- {개선 권장사항}"

Task D — Schema Design Review — (Standard의 Task C와 동일, Full에서는 항상 실행)
```

**검증 결과 → 플랜 반영:**
- Critical 이슈 → 플랜 수정 후 재검증
- Warning/Recommendation → 플랜 하단에 `## Agent Review Notes` 섹션 추가:

```markdown
## Agent Review Notes
### Feasibility — {PASS|PASS_WITH_WARNINGS|FAIL}
- {주요 리스크 또는 권장사항 요약}
- DB Migration: {YES|NO} — {내용}

### Impact — {LOW|MEDIUM|HIGH}
- New files: {N}개, Modified: {N}개
- {주요 사이드 이펙트 요약}

### [Full] Architecture — {PASS|PASS_WITH_WARNINGS|FAIL}
- {레이어/DI/트랜잭션 이슈 요약}

### Schema Design (Standard: 조건부 / Full: 항상)
- {스키마 리뷰 요약 — 해당 없으면 이 섹션 생략}
```

이 섹션은 Phase 3 구현 시 참고 자료로 활용됩니다.

### 1-6. 사용자 승인

**검증된 플랜을 보여주고 반드시 승인을 받습니다.** 에이전트 검증 결과도 함께 공유합니다.
수정 요청 시 반영 후 재승인.

### 1-7. 상태 저장 → Phase 2로 자동 연결

`.orchestrate/{slug}.json` 생성:

```bash
# 변수 설정 (placeholder를 실제 값으로 치환)
feature_name="1:1 문의 기능"
slug="inquiry"  # feature_name의 kebab-case 버전
jira_key="GIFCA-123"  # 또는 standalone이면 "null"
identifier="${jira_key}-${slug}"  # 또는 standalone이면 "${slug}"
mode="standard"  # 또는 "full" (--full 플래그 사용 시)

mkdir -p .orchestrate
cat > ".orchestrate/${slug}.json" <<EOF
{
  "feature": "${feature_name}",
  "jira_key": ${jira_key:+\"$jira_key\"}${jira_key:-null},
  "branch": "${identifier}",
  "plan_file": "plans/${identifier}.md",
  "worktree": ".worktrees/${slug}",
  "phase": "branch",
  "mode": "${mode}",
  "started_at": "$(date -Iseconds)"
}
EOF
```

```
Phase 1 완료. 플랜이 승인되었습니다. Phase 2→3→4를 자동으로 진행합니다.
```

**멈추지 않고 바로 Phase 2를 실행합니다.**

---

## Phase 2: Branch

워크트리와 브랜치를 생성합니다.

### 2-1. Feature 브랜치 + 워크트리 생성

```bash
# 브랜치 생성 + 워크트리로 체크아웃
git worktree add .worktrees/{slug} -b {branch-name}
```

### 2-2. 의존성 설치

```bash
cd .worktrees/{slug}

# 패키지 매니저 감지
if [ -f pnpm-lock.yaml ]; then pm="pnpm"
elif [ -f yarn.lock ]; then pm="yarn"
elif [ -f package-lock.json ]; then pm="npm"
elif [ -f bun.lockb ]; then pm="bun"
else pm="pnpm"; fi

# .env 파일 복사 (없으면 .env.example 사용)
if [ -f ../.env ]; then
  cp ../.env .env
elif [ -f ../.claude/.env.example ]; then
  cp ../.claude/.env.example .env
  echo "⚠️  .env.example을 복사했습니다. 토큰을 입력하세요."
fi

${pm} install
```

### 2-3. 플랜 파일 복사

```bash
cp -r plans/ .worktrees/{slug}/plans/
```

### 2-4. 상태 업데이트 → Phase 3로 자동 연결

```bash
# state 파일의 phase 값을 "develop"으로 업데이트
jq '.phase = "develop"' .orchestrate/{slug}.json > .orchestrate/{slug}.json.tmp && mv .orchestrate/{slug}.json.tmp .orchestrate/{slug}.json
```

**멈추지 않고 바로 Phase 3를 실행합니다.**

---

## Phase 3: Develop

**워크트리 디렉토리에서** 플랜에 따라 구현합니다.

### 3-0. 프로젝트 패턴 탐지

코드를 쓰기 전에 프로젝트 구조를 파악합니다. **Standard 모드에서도 반드시 실행.**

```bash
# 1. ORM 감지
Grep("typeorm|@prisma/client|prisma|drizzle-orm", path="package.json")

# 2. 테스트 러너 감지
Grep("jest|vitest|@nestjs/testing", path="package.json")

# 3. DB 타입 감지
Grep("pg|mysql2|better-sqlite3|mongodb|@nestjs/typeorm|@nestjs/mongoose", path="package.json")

# 4. 기존 모듈 구조 파악
Glob("**/src/**/*.module.ts")
Glob("**/src/**/*.entity.ts")
Glob("**/src/**/*.schema.ts")

# 5. DI 패턴 감지 (Symbol token vs class token)
Grep("Symbol\\(|InjectionToken", glob="**/*.ts")
```

결과를 state 파일의 `"detected"` 필드에 저장:
```json
{
  "detected": {
    "orm": "drizzle",
    "testRunner": "jest",
    "dbType": "postgresql",
    "modulePattern": "src/{domain}/infrastructure",
    "diPattern": "symbol-token"
  }
}
```

### 3-1. 작업 디렉토리 확인

state 파일에서 `worktree` 경로를 읽어 해당 디렉토리에서 작업합니다.

### 3-1a. 인터페이스 계약 파일 생성

> **모드 분기**: `mode == "standard"` → **이 단계를 건너뛰고 3-2로 직행합니다.** / `mode == "full"` → 아래 실행.

Architect 산출물의 Interface Contracts 섹션에서 TypeScript 타입을 실제 파일로 작성합니다:

```
1. Entity 파일 생성 (private constructor + create/reconstitute 스텁)
2. Repository Interface 파일 생성 (Symbol token + 메서드 시그니처)
3. Domain Error 파일 생성
4. DTO 파일 생성 (class-validator 데코레이터)
5. Use Case 타입 파일 생성 (입력/출력 타입)
```

```bash
git add {type files}
git commit -m "chore({scope}): add interface contracts for {feature}"
```

이 파일들이 이후 구현의 **공유 계약**이 됩니다. 구현 중 이 인터페이스를 변경하지 않습니다.

### 3-2. 구현

> **모드 분기**: `mode` 값에 따라 아래 **해당 모드 섹션만** 실행합니다.

#### Standard 모드

플랜의 Implementation Order에 따라:

1. **Domain Layer** — Entity (private constructor + create/reconstitute), Repository Interface (Symbol token), Domain Error
2. **Infrastructure Layer** — Mapper (toDomain/toPersistence), Repository Impl (Drizzle)
3. **Application Layer** — Use Case (@Transactional), Controller + DTOs, Module registration
4. **Test** — E2E test (success + error cases: 400, 401, 404, 409)

> Domain + Infra는 독립적이므로 Task tool로 병렬 실행 가능.
> Application은 Domain/Infra 완료 후 진행.

#### [Full] Full 모드 — TDD + Incremental Commit

Architect 산출물의 Implementation Groups와 TDD Anchors에 따라 구현합니다.

**각 Task Group마다 TDD 순서를 따릅니다:**

```
Group N의 각 Task에 대해:

1. 테스트 먼저 작성
   - Architect의 TDD Anchor를 기반으로 테스트 파일 작성
   - 성공 케이스 + 에러 케이스 + 엣지 케이스
   - Domain: 단위 테스트 (Entity 생성, 도메인 규칙 검증)
   - Application: E2E 테스트 (supertest, HTTP 상태코드별)
   - ${pm} test → RED 확인 (테스트 실패 = 정상)

2. 최소 구현
   - 인터페이스 계약(3-1a에서 생성한 타입)을 import하여 사용
   - Phase 0 스캔에서 파악한 기존 패턴을 따라 구현
   - ${pm} test → GREEN 확인

3. 리팩토링
   - 중복 제거, 네이밍 개선, 불필요한 코드 정리
   - 테스트 여전히 GREEN 확인

Group 완료 후:
  → 검증 루프 실행 (3-3)
  → git commit -m "feat({scope}): implement {group description}"
  → 다음 Group 진행
```

> Group 1 (Domain + Infra)은 병렬 실행 가능.
> Group 2 (Application)는 Group 1 완료 후 순차.
> Group 3 (E2E Test)는 Group 2 완료 후 순차.

### 3-3. 워크트리 내 검증

```bash
cd .worktrees/{slug}
```

> **모드 분기**: `mode` 값에 따라 아래 **해당 모드 섹션만** 실행합니다.

#### Standard 모드 — 검증 루프 (최대 3회)

```
# 스크립트 존재 여부 확인 (package.json에 정의된 스크립트만 실행)
scripts=$(node -e "const p=require('./package.json');console.log(Object.keys(p.scripts||{}).join(','))")
# 모노레포 감지 시: ${pm} --filter {package-name} {script} 또는 해당 패키지 디렉토리에서 직접 실행

attempt = 0

while attempt < 3:
  attempt++

  1. if "biome" in scripts: ${pm} biome check --write .
     else: echo "biome 스크립트 없음 — 건너뜀"
     → 실패 시: 에러 수정 → 처음부터 재시작 (continue)

  2. if "build" in scripts: ${pm} build
     else: echo "build 스크립트 없음 — 건너뜀"
     → 실패 시: 에러 수정 → 처음부터 재시작 (continue)

  3. if "test:e2e:gifca" in scripts: ${pm} test:e2e:gifca
     elif "test:e2e" in scripts: ${pm} test:e2e
     elif "test" in scripts: ${pm} test
     else: echo "테스트 스크립트 없음 — 건너뜀"
     → 실패 시: 에러 수정 → 처음부터 재시작 (continue)

  4. 모두 성공 → 루프 종료 (break)

스크립트가 하나도 없으면 "⚠️ 검증 스크립트 없음 — 타입체크만 시도" 후 `npx tsc --noEmit`만 실행.
tsc 자체도 실패하면 (tsconfig 없음, 의존성 미설치 등) "⚠️ 타입체크 불가 — 코드 구조 수동 확인 후 진행" 출력 후 다음 단계로.

if attempt == 3:
  에러 내용을 사용자에게 보여주고 선택 요청:
  1. 계속 시도 (추가 3회)
  2. 이 Step 스킵하고 다음 진행
  3. 파이프라인 중단
```

#### [Full] Full 모드 — 강화된 검증 루프 (최대 3회)

```
# 스크립트 존재 여부 확인 (package.json에 정의된 스크립트만 실행)
scripts=$(node -e "const p=require('./package.json');console.log(Object.keys(p.scripts||{}).join(','))")
# 모노레포 감지 시: ${pm} --filter {package-name} {script} 또는 해당 패키지 디렉토리에서 직접 실행

attempt = 0
prev_errors = []

while attempt < 3:
  attempt++

  1. if "biome" in scripts: ${pm} biome check --write .
     else: echo "biome 스크립트 없음 — 건너뜀"
     → 실패 시: 에러 수정 → 처음부터 재시작 (continue)

  2. if script_exists "tsc" || has_tsconfig; then ${pm} tsc --noEmit; fi
     → tsc 자체 실패 (tsconfig 없음, 의존성 미설치 등): "⚠️ 타입체크 불가" 경고 후 다음 단계로
     → 타입 에러 실패 시: 에러 수정 → 처음부터 재시작 (continue)

  3. if "build" in scripts: ${pm} build
     else: echo "build 스크립트 없음 — 건너뜀"
     → 실패 시: 에러 수정 → 처음부터 재시작 (continue)

  4. if "test:e2e:gifca" in scripts: ${pm} test:e2e:gifca
     elif "test:e2e" in scripts: ${pm} test:e2e
     elif "test" in scripts: ${pm} test
     else: echo "테스트 스크립트 없음 — 건너뜀"
     → 실패 시: 에러 수정 → 처음부터 재시작 (continue)

  5. if "test:e2e" in scripts: ${pm} test:e2e (전체)
     else: echo "test:e2e 스크립트 없음 — 건너뜀"
     → 실패 시: 기존 테스트 깨짐 확인 → 수정 → 처음부터 재시작 (continue)

  6. 모두 성공 → 루프 종료 (break)

  # attempt 3 설계 회귀 판단
  if attempt == 3:
    current_errors = [현재 에러 목록]
    if current_errors와 prev_errors가 같은 패턴:
      → "동일 에러 반복 — 설계 문제 가능성"
      → 에러와 관련된 Architect 설계 부분을 식별
      → "다음 설계를 재검토하세요: {관련 섹션}"
      → 사용자에게 선택지 제공:
        1. 설계 수정 후 `/orchestrate`로 Phase 3 재개
        2. 수동으로 에러 수정 후 `/orchestrate`로 Phase 3 재개
    else:
      → 구현 문제 → 상세 실패 보고서 출력 (3-3a)

  prev_errors = current_errors
```

### 3-3a. 검증 실패 보고 절차

검증 루프 3회 소진 시, 사용자에게 **구조화된 실패 보고서**를 제공합니다:

```
ORCHESTRATE BLOCKED — Phase 3 검증 실패

Feature: {feature_name}
Branch:  {branch}
Worktree: {worktree_path}
Mode: {standard|full}

## 실패 단계
- [x] Biome    — {PASS 또는 에러 수}
- [x] tsc      — {PASS 또는 에러 수} (full 모드)
- [ ] Build    — FAIL (attempt 3/3)
- [ ] E2E Test — NOT REACHED

## 마지막 에러 (최대 5개)
1. `src/path/file.ts:42` — Type 'X' is not assignable to type 'Y'
...

## 시도한 수정
- attempt 1: {어떤 에러를 어떻게 수정했는지}
- attempt 2: {어떤 에러를 어떻게 수정했는지}
- attempt 3: {어떤 에러를 어떻게 수정했는지}

## [Full] 설계 회귀 분석
- 반복 패턴: {동일 에러가 반복됐는지 여부}
- 관련 설계 섹션: {Architect 산출물의 어느 부분이 문제인지}

## 권장 조치
- [ ] {에러 유형별 구체적 해결 방법}
- [ ] 수동 확인 후 `/orchestrate`로 Phase 3 재개 가능

## 복구 명령어
cd {worktree_path}
${pm} build  # 수동 확인 후 에러 수정
# 수정 완료 후:
/orchestrate  # Phase 3부터 재개
```

이 보고서를 출력한 후 **반드시 정지**합니다. Phase 4로 넘어가지 않습니다.
state 파일의 phase는 `"develop"` 상태를 유지하므로, `/orchestrate` 재실행 시 Phase 3부터 재개됩니다.

### 3-4. 상태 업데이트 → Phase 4로 자동 연결

```bash
# 메인 프로젝트 루트로 이동 후 state 파일 업데이트
cd ../..
jq '.phase = "done"' .orchestrate/{slug}.json > .orchestrate/{slug}.json.tmp && mv .orchestrate/{slug}.json.tmp .orchestrate/{slug}.json
```

**멈추지 않고 바로 Phase 4를 실행합니다.**

---

## Phase 4: PR

검증 후 PR을 생성합니다.

### 4-1. 최종 검증

```bash
cd .worktrees/{slug}
```

Phase 3에서 검증 루프를 통과했지만, 에이전트 리뷰 후 코드 수정이 발생할 수 있습니다.
**4-2 리뷰 결과 반영 후에만** 검증 루프(Phase 3-3과 동일)를 재실행합니다.
수정 사항이 없으면 이 단계를 skip합니다.

### 4-2. 에이전트 리뷰

커밋 전 변경 파일을 분석하고 에이전트 리뷰를 실행합니다.

**Step 1: 변경 파일 확인**

```bash
git diff --name-only HEAD
```

**Step 2: 에이전트 투입 결정**

#### 에이전트 호출 방법

각 에이전트는 `.claude/agents/{agent-name}.md` 파일에 정의되어 있습니다.

```typescript
// 에이전트별로 독립 서브에이전트 실행:
const diff = Bash("git diff main...HEAD")

// 방법 1: Agent 도구로 서브에이전트 위임
Agent("code-reviewer", `다음 diff를 리뷰해주세요:\n${diff}`)
Agent("security-reviewer", `다음 diff를 보안 관점에서 리뷰해주세요:\n${diff}`)

// 방법 2: 수동 실행 (Agent 도구 없을 때)
// .claude/agents/code-reviewer.md를 Read → 지시에 따라 리뷰 수행
```

각 에이전트의 출력을 수집하여 통합 리포트로 합칩니다.

**에이전트 파일이 없으면**: 해당 에이전트 스킵하고 "⚠️ {agent-name} 에이전트 파일 없음 — 스킵" 출력. 나머지 에이전트는 정상 실행.

**컨텍스트 윈도우 초과 시**: 에이전트 수를 줄이거나, `/compact` 후 남은 에이전트 실행. Full 모드 2라운드 중 컨텍스트 부족하면 1라운드로 축소하고 경고.

> **모드 분기**: `mode` 값에 따라 아래 **해당 모드 섹션만** 실행합니다.

#### Standard 모드 — 선별적 투입

변경된 파일 목록을 보고 아래 기준에 따라 투입할 에이전트를 결정합니다:

| 에이전트 | 구분 | 투입 조건 | 전담 영역 (다른 에이전트와 겹치지 않음) |
|---------|------|----------|--------------------------------------|
| **Code Review** | 필수 | 항상 | 가독성, 중복 코드, 함수/파일 크기, 에러 처리 |
| **Convention** | 필수 | 항상 | 네이밍, 레이어/폴더 구조, import 패턴, 프로젝트 규칙 (CLAUDE.md + rules/) |
| **Security** | 선택 | guard, auth, controller, 사용자 입력 처리 파일 변경 시 | injection, 인증/인가 우회, 민감정보 노출, API 보안, 의존성 취약점 (DTO 검증 제외) |
| **Database** | 선택 | repository, schema, migration, query 파일 변경 시 | N+1 쿼리, 인덱스, 트랜잭션, 데드락, 쿼리 최적화 |
| **NestJS Pattern** | 선택 | module, controller, service, dto, use-case 파일 변경 시 | DI 패턴, 모듈 구조, DTO 검증, Guard/Filter/Interceptor, 레이어 분리 |

#### [Full] Full 모드 — 전원 투입

**5개 에이전트 전부 항상 실행합니다.** 파일 기반 선별 없음.

**Step 3: 에이전트를 하나의 응답에서 병렬 호출**

> **중요: 선별된 모든 Task를 한 번의 응답에 모두 포함해서 병렬 실행하세요.**

**❌ 잘못된 예시 (순차 실행):**
```
1. Code Review Task 호출 → 결과 대기
2. 결과 확인 후 Convention Task 호출 → 결과 대기
3. 결과 확인 후 Security Task 호출
```

**✅ 올바른 예시 (병렬 실행):**
```
# Standard: 선별된 에이전트만 (예: 3개)
한 번의 응답에 3개 Task tool을 모두 포함:
- Task: Code Review
- Task: Convention Review
- Task: Database Review
(선별된 에이전트가 동시에 실행되고, 모든 결과를 한 번에 수집)

# Full: 항상 5개 전부
한 번의 응답에 5개 Task tool을 모두 포함:
- Task: Code Review
- Task: Convention Review
- Task: Security Review
- Task: Database Review
- Task: NestJS Pattern Review
(5개가 동시에 실행되고, 모든 결과를 한 번에 수집)
```

각 에이전트의 Task tool 호출 형식:

> **공통 출력 형식**: 모든 에이전트에 아래 형식을 프롬프트 끝에 포함하세요.

```
반드시 아래 형식으로 응답해줘:

## Summary
- Total: {N}건 | Critical: {N} | High: {N} | Medium: {N} | Low: {N}

## Issues

### [CRITICAL] {제목}
- **File**: `src/path/file.ts:42`
- **Problem**: {구체적 문제}
- **Fix**: {수정 방법}

### [HIGH] {제목}
...

이슈가 없으면 "## Summary\n- Total: 0건 — No issues found" 로 응답해줘.
```

```
Code Review (subagent_type: general-purpose) — 필수
prompt: "워크트리 {worktree_path}의 다음 변경 파일들을 리뷰해줘: {file_list}
전담 영역: 가독성, 중복 코드, 함수/파일 크기, 에러 처리.
제외 (다른 에이전트 담당): 네이밍 컨벤션, 보안, DB, NestJS 패턴.
{공통 출력 형식}"

Convention Review (subagent_type: general-purpose) — 필수
prompt: "워크트리 {worktree_path}의 다음 변경 파일들을 프로젝트 컨벤션 점검해줘: {file_list}
CLAUDE.md와 .claude/rules/ 에 정의된 프로젝트 규칙을 읽고 준수 여부를 확인해줘.
전담 영역: 네이밍, 레이어/폴더 구조, import 패턴, 프로젝트 특화 규칙.
{공통 출력 형식}"

Security Review (subagent_type: general-purpose)
prompt: "워크트리 {worktree_path}의 다음 변경 파일들을 보안 점검해줘: {file_list}
전담 영역: injection(SQL, NoSQL, command), 인증/인가 우회, 민감정보 노출, API 보안, 의존성 취약점.
제외 (NestJS Pattern 담당): DTO 검증 로직.
{공통 출력 형식}"

Database Review (subagent_type: general-purpose)
prompt: "워크트리 {worktree_path}의 다음 변경 파일들을 DB 관점에서 점검해줘: {file_list}
전담 영역: N+1 쿼리, 인덱스 누락, 트랜잭션 범위, 데드락 가능성, 쿼리 최적화.
{공통 출력 형식}"

NestJS Pattern Review (subagent_type: general-purpose)
prompt: "워크트리 {worktree_path}의 다음 변경 파일들을 NestJS 패턴 점검해줘: {file_list}
전담 영역: DI 패턴(Symbol token), 모듈 구조, DTO 검증(class-validator), Guard/Filter/Interceptor 사용, 레이어 분리(Domain/Infra/Application).
제외 (Convention 담당): 네이밍, 파일 구조 컨벤션.
{공통 출력 형식}"
```

**결과 처리:**

> **모드 분기**: `mode` 값에 따라 아래 **해당 모드 섹션만** 실행합니다.

#### Standard 모드
- **Critical/High** → 즉시 수정 후 4-1 재실행
- **Medium** → 수정 후 진행
- **Low/Info** → PR description의 "에이전트 리뷰 결과" 섹션에 기록, 진행

#### [Full] Full 모드
- **Critical/High/Medium** → 즉시 수정
- **Low** → 수정 (비용 여유 있으므로 전부 처리)
- 수정 후 → **Round 2 재검증** (4-2a)

### 4-2a. Round 2 재검증

> **모드 분기**: `mode == "standard"` → **이 단계를 건너뛰고 4-3으로 직행합니다.** / `mode == "full"` → 아래 실행.

Round 1에서 수정한 파일만 대상으로 재검증합니다.

```
재검증 대상:
- Round 1에서 수정된 파일 목록

투입 에이전트 (3개, 병렬):
1. Code Review — 수정이 새 문제를 만들지 않았는지
2. Convention — 수정이 컨벤션을 깨지 않았는지
3. Round 1에서 가장 많은 이슈를 제기한 에이전트 — 이슈가 실제로 해결됐는지
```

Round 2 결과:
- 새 이슈 → 수정 (Round 3는 없음, 여기서 종료)
- 이슈 없음 → 4-3 진행

### 4-3. 커밋

```bash
git add {specific files}
git commit -m "{type}({scope}): {description}"
```

### 4-4. PR 생성

```bash
# 리모트 존재 여부 확인
if ! git remote | grep -q origin; then
  echo "⚠️  git remote 'origin'이 없습니다. PR 생성을 건너뜁니다."
  echo "수동으로 remote를 추가한 후 /orchestrate를 재실행하세요:"
  echo "  git remote add origin <repo-url>"
  exit 1
fi

git push -u origin {branch}

gh pr create --title "{type}({scope}): {description}" --body "$(cat <<'EOF'
<!-- 작성 규칙:
- 모든 {placeholder}를 실제 값으로 치환
- 해당 없는 선택 섹션은 제거 (빈 섹션 남기지 말 것)
-->

## 개요
{이 PR이 왜 필요한지 1-2문장}

## 주요 변경사항

### 신규 파일
| 파일 | 레이어 | 역할 |
|------|--------|------|
| `src/path/to/entity.ts` | Domain | {역할 설명} |
| `src/path/to/use-case.ts` | Application | {역할 설명} |

### 수정 파일
| 파일 | 변경 내용 |
|------|----------|
| `src/path/to/module.ts` | {무엇을 왜 변경했는지} |

## 핵심 구현
{가장 중요한 구현 결정 2-3가지를 코드 스니펫과 함께 설명.
Entity 설계, Use Case 흐름, DB 스키마 중 핵심만.}

## API 스펙

| Method | Path | 성공 | 에러 |
|--------|------|------|------|
| `{METHOD}` | `/api/v1/{resource}` | `{status}` | 400, 401, 404, 409 |

## DB 변경사항 (해당 시)
{신규 테이블/컬럼, 인덱스 전략, 마이그레이션 주의사항을 간결하게}

## 에이전트 리뷰 결과
| 에이전트 | 결과 | 주요 지적 |
|---------|------|----------|
| Code Review | {PASS/이슈 N건} | {요약} |
| Convention | {PASS/이슈 N건} | {요약} |
| Security | {PASS/이슈 N건 또는 N/A} | {요약} |
| Database | {PASS/이슈 N건 또는 N/A} | {요약} |
| NestJS Pattern | {PASS/이슈 N건 또는 N/A} | {요약} |

<!-- Full 모드에서만 포함 — Standard 모드이면 이 섹션 제거 -->
## [Full] Round 2 재검증 결과
| 에이전트 | 결과 | 비고 |
|---------|------|------|
| Code Review | {PASS/이슈 N건} | 수정이 새 문제를 만들지 않았는지 |
| Convention | {PASS/이슈 N건} | 수정이 컨벤션을 깨지 않았는지 |
| {Round 1 최다 이슈 에이전트} | {PASS/이슈 N건} | 이슈가 실제로 해결됐는지 |

## 테스트
- [x] `${pm} biome check` 통과
- [x] `${pm} build` 통과
- [x] E2E 테스트 ({N}개 케이스: 성공 + 400/401/404/409)
- [x] 기존 테스트 통과

## 참고사항
- {리뷰어가 알아야 할 컨텍스트, 트레이드오프, 후속 작업}
EOF
)"
```

### 4-5. Jira 상태 변경 (Jira 모드)

```typescript
mcp__jira__jira_transition_issue({ issue_key: "{JIRA-KEY}", transition: "In Review" })
```

### 4-6. 상태 업데이트

```bash
# 프로젝트 루트로 이동
cd ../..

# PR URL 추출 후 state 파일 업데이트
PR_URL=$(gh pr view {branch} --json url -q .url)
jq --arg url "$PR_URL" '.phase = "pr" | .pr_url = $url' .orchestrate/{slug}.json > .orchestrate/{slug}.json.tmp && mv .orchestrate/{slug}.json.tmp .orchestrate/{slug}.json
```

```bash
# 시스템 알림
node .claude/scripts/notify.cjs "orchestrate" "PR 생성 완료: {branch}"
```

```
Phase 4 완료. PR이 생성되었습니다.
- PR: {URL}
- Branch: {branch} → main

→ 리뷰 코멘트가 달리면 /orchestrate 를 호출하세요.
```

---

## Phase 5: Feedback

PR 리뷰 코멘트를 확인하고 반영합니다. **이 phase는 반복됩니다.**

### 5-1. PR 상태 확인

```bash
gh pr view {branch} --json state,reviews,comments,reviewRequests
```

| 상태 | 행동 |
|------|------|
| `MERGED` | → Phase 6 (Clean)으로 자동 전환 |
| `OPEN` + 코멘트 없음 | → "리뷰 대기 중. 코멘트가 달리면 다시 호출하세요." |
| `OPEN` + 코멘트 있음 | → 아래 5-2~5-5 실행 |
| `CLOSED` | → "PR이 닫혔습니다. 상태를 확인하세요." |

### 5-2. 리뷰 코멘트 읽기

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --jq '.[] | {path, line, body, user: .user.login}'
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --jq '.[] | {state, body, user: .user.login}'
```

코멘트를 분류:
- **변경 요청** (request changes) → 반드시 반영
- **제안** (suggestion) → 타당하면 반영
- **질문** (question) → 코드에 주석 또는 PR 답글

### 5-3. 워크트리에서 수정

```bash
cd .worktrees/{slug}
# 코멘트 내용에 따라 수정
```

### 5-4. 검증 + push

> **모드 분기**: state 파일의 `mode` 값에 따라 검증 범위가 달라집니다.

#### Standard 모드
```bash
${pm} biome check --write . && ${pm} build && ${pm} test:e2e:gifca
git add {modified files}
git commit -m "fix({scope}): address review feedback"
git push
```

#### Full 모드
```bash
${pm} biome check --write . && ${pm} tsc --noEmit && ${pm} build && ${pm} test:e2e:gifca && ${pm} test:e2e
git add {modified files}
git commit -m "fix({scope}): address review feedback"
git push
```

### 5-5. 상태 유지

phase는 `"pr"` 그대로 유지. (다음 리뷰까지 반복 가능)

```
리뷰 피드백 반영 완료. push 했습니다.
- 수정 항목: {N}건
- 리뷰어에게 re-review 요청하세요.

→ 추가 코멘트가 달리면 /orchestrate 를 다시 호출하세요.
→ PR이 병합되면 /orchestrate 로 정리합니다.
```

---

## Phase 6: Clean

PR 병합 확인 후 워크트리와 브랜치를 정리합니다.

> Phase 5에서 PR이 MERGED로 감지되면 자동으로 이 phase를 실행합니다.

### 6-1. 정리 스크립트 실행

**Bash 한 번으로 전부 처리합니다:**

```bash
# .claude 디렉토리에서 정리 스크립트 실행
bash .claude/scripts/orchestrate-clean.sh $(pwd) {slug} {branch}
```

이 스크립트가 자동으로:
0. **PR merge 확인** (안전 장치)
   - PR이 merge 안 됐으면 종료 (작업 내용 보호)
   - merge 됐으면 안전하게 정리 진행
1. main checkout + pull
2. 워크트리 제거 (force + 디렉토리 정리)
3. 로컬 브랜치 삭제
4. 리모트 브랜치 삭제
5. `.orchestrate/{slug}.json` 삭제

**PR이 merge 안 됐을 때:**
- 스크립트가 종료되고 안내 메시지 출력
- PR을 merge하거나, 강제 삭제 명령어 사용

### 6-2. Jira 상태 변경 (Jira 모드)

> standalone이면 스킵

```typescript
mcp__jira__jira_transition_issue({ issue_key: "{JIRA-KEY}", transition: "Done" })
```

### 6-3. 완료

```
정리 완료.
- 워크트리: .worktrees/{slug} 삭제됨
- 브랜치: {branch} 삭제됨 (local + remote)
- Jira: {JIRA-KEY} → Done
- main: 최신 상태로 업데이트됨
```

---

## Examples

```
/orchestrate 1:1 문의 기능 추가. 카테고리 분류, 답변, 상태 관리.
```
→ Standard: Phase 1 (플랜) → 승인 후 Phase 2→3→4 자동 실행 → PR 생성 후 정지

```
/orchestrate --full 1:1 문의 기능 추가. 카테고리 분류, 답변, 상태 관리.
```
→ Full: Phase 0 (스캔) → Phase 1 (architect 설계) → 승인 후 Phase 2→3→4 자동 실행 → PR 생성 후 정지

```
/orchestrate
```
→ 세션 복구: 중단된 phase부터 이어서 자동 진행 (모드 자동 감지)

```
/orchestrate GIFCA-123
```
→ Jira 이슈 기반으로 Phase 1 시작

```
/orchestrate --full GIFCA-123
```
→ Full 모드 + Jira 이슈 기반

---

## Mode Comparison

| | Standard | Full |
|---|---|---|
| **Phase 0** | - | Codebase Scan (1 agent) |
| **Phase 1 설계** | 수동 플랜 작성 | Architect(opus) 심층 설계 + 인터페이스 계약 |
| **Phase 1 검증** | 2-3 agents (feasibility + impact + schema 조건부) | 4 agents always (feasibility + impact + architecture + schema) |
| **Phase 3 순서** | 구현 → 테스트 | TDD (테스트 → 구현) + incremental commit |
| **Phase 3 검증** | biome → build → e2e | biome → tsc → build → e2e(feature) → e2e(full) + 설계 회귀 판단 |
| **Phase 4 리뷰** | 2 필수 + 3 선택 (1 round) | 5 전원 (2 rounds) |
| **Phase 4 수정** | Critical/High 수정, Low 기록만 | 전부 수정 |
| **에이전트 총합** | 4-7 | 10-12 |
| **토큰 비용** | 1x | ~2x |

---

## Troubleshooting

### Phase 3: 빌드 실패

**증상**: `${pm} build` 실패, worktree에 갇힘

**복구**:
```bash
# 1. worktree로 이동
cd .worktrees/{slug}

# 2. 에러 수정 후 다시 빌드
${pm} biome check --write .
${pm} build

# 3. 성공하면 /orchestrate 재실행
```

### Phase 4: PR 생성 실패

**증상**: `gh pr create` 실패 (네트워크, 권한 등)

**복구**:
```bash
# 1. 수동으로 PR 생성 가능한지 확인
cd .worktrees/{slug}
gh pr create --title "..." --body "..."

# 2. 또는 /orchestrate 재실행 (자동 재시도)
```

### Worktree 충돌

**증상**: "worktree already exists" 에러

**복구**:
```bash
# 1. worktree 목록 확인
git worktree list

# 2. 문제 worktree 제거
git worktree remove .worktrees/{slug} --force
rm -rf .worktrees/{slug}

# 3. state 파일 삭제
rm .orchestrate/{slug}.json

# 4. 처음부터 다시 시작
/orchestrate {description}
```

### MCP 연결 실패

**증상**: Jira/GitHub MCP 오류

**복구**:
```bash
# 1. .env 토큰 확인
cat .claude/.env

# 2. 토큰 재발급 및 입력
# - GITHUB_PAT: https://github.com/settings/tokens/new
# - JIRA_TOKEN: https://id.atlassian.com/manage-profile/security/api-tokens

# 3. /orchestrate 재실행 (MCP 재연결)
```

### State 파일 손상

**증상**: JSON parse 에러, state 불일치

**복구**:
```bash
# 1. state 파일 확인
cat .orchestrate/{slug}.json

# 2. 수동 수정 또는 삭제
rm .orchestrate/{slug}.json

# 3. 워크트리 수동 정리 후 재시작
git worktree remove .worktrees/{slug}
/orchestrate {description}
```
