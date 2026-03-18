---
description: 간단한 수정을 체계적으로 진행. Jira 연동, 자동 커밋/푸시.
---

# Fix — 체계적 수정 워크플로

## Usage

```
/fix PROJ-123 로그인 토큰 갱신 버그
/fix PROJ-123                      → 이슈에서 제목 가져옴
/fix 로그인 버그                    → Jira 없이 (standalone)
/fix continue                      → 테스트 완료 후 커밋/푸시
/fix cancel                        → 변경사항 취소
```

## 용도

**간단한 수정 작업** (1-3 파일, 리뷰 불필요)
- 버그 수정
- 기능 개선
- 리팩토링 (소규모)

**복잡한 작업은 `/orchestrate` 사용**

---

## Phase 1: 준비

### 1-0. 권한 사전 요청

**워크플로 시작 시 필요한 모든 권한을 한 번에 요청합니다:**

```typescript
// Phase 2-5에서 사용할 모든 명령어 권한 사전 요청
allowedPrompts: [
  { tool: "Bash", prompt: "git operations (add, commit, push, stash)" },
  { tool: "Bash", prompt: "validation (biome/lint check, build)" }
]
```

### 1-1. Jira 확인 (선택)

```typescript
// 인자에 Jira 키가 있으면
if (jira_key) {
  issue = mcp__jira__jira_get_issue({ issue_key })

  // 이슈 정보 출력
  console.log(`
  이슈: ${issue.key}
  제목: ${issue.summary}
  상태: ${issue.status}
  `)

  // In Progress로 전환
  mcp__jira__jira_transition_issue({
    issue_key,
    transition: "In Progress"
  })
}
```

### 1-2. 체계적 Q&A

**AskUserQuestion으로 정보 수집:**

```typescript
AskUserQuestion([
  {
    question: "어떤 파일을 수정해야 하나요?",
    header: "파일 선택",
    options: [
      {
        label: "검색해서 찾기",
        description: "파일명/키워드로 검색"
      },
      {
        label: "직접 지정",
        description: "경로를 알고 있음"
      }
    ]
  },
  {
    question: "어떤 종류의 수정인가요?",
    header: "타입",
    options: [
      { label: "fix", description: "버그 수정" },
      { label: "feat", description: "기능 개선" },
      { label: "refactor", description: "리팩토링" },
      { label: "chore", description: "설정/의존성" }
    ]
  },
  {
    question: "scope는 무엇인가요? (영향받는 모듈/영역)",
    header: "Scope",
    options: [
      // 파일 경로 기반 자동 추천
      { label: "auth", description: "인증/권한" },
      { label: "payment", description: "결제" },
      { label: "user", description: "사용자" },
      // ... 프로젝트별로 커스터마이징
    ]
  }
])
```

**답변 기반 파일 찾기:**
- "검색" 선택 → Grep/Glob로 파일 검색
- "직접" 선택 → 경로 입력 요청

---

## Phase 2: 수정

### 2-1. 파일 읽기 및 수정

```
1. 대상 파일 Read
2. 사용자 설명 기반 수정 (Edit)
3. 변경 내역 요약 출력
```

**변경 요약 예시:**
```
✏️  수정 완료

src/auth/login.ts
  - Line 42: JWT 갱신 로직 수정
    Before: const token = refresh()
    After:  const token = await refreshWithRetry()

  - Line 58: 에러 핸들링 추가
    + if (!token) throw new UnauthorizedError()
```

### 2-2. 사용자 확인

```
수정 내용이 맞나요?
- 맞음: 계속 진행
- 추가 수정 필요: 추가 요청 입력
```

**추가 수정 가능** (반복):
- "여기 로그 추가해줘"
- "이 부분 다시 수정"
- 수정 → 다시 확인

---

## Phase 3: 검증

### 3-1. 자동 검증

**NestJS:**
```bash
pnpm biome check --write .
pnpm build
```

**React-Next:**
```bash
pnpm lint --fix
pnpm build
```

**테스트는 스킵** (사용자가 수동 테스트)

### 3-2. 검증 결과

```
✅ 검증 완료

✅ pnpm biome check 통과
✅ pnpm build 성공 (3.2s)

변경 파일:
- src/auth/login.ts (42줄 → 45줄)
```

---

## Phase 4: 🛑 사용자 테스트

```
🧪 수동 테스트를 진행하세요

추천 테스트 시나리오:
1. 앱 실행: pnpm dev
2. 로그인 테스트
3. 토큰 갱신 시나리오 확인
4. 관련 기능 동작 확인

테스트 완료 후:
- 문제 없으면: /fix continue
- 추가 수정 필요: 수정 내용 입력
- 취소하려면: /fix cancel
```

**멈춤 — 사용자 액션 대기**

---

## Phase 5: 완료 (continue)

### 5-1. 커밋

**Conventional Commit 형식:**
```bash
git add {modified files}

git commit -m "{type}({scope}): {description}

{jira_key}"
```

**예시:**
```bash
git add src/auth/login.ts

git commit -m "fix(auth): resolve token refresh retry logic

PROJ-123"
```

### 5-2. 푸시

```bash
git push origin dev
```

### 5-3. Jira 완료 (선택)

```typescript
if (jira_key) {
  mcp__jira__jira_transition_issue({
    issue_key,
    transition: "Done"
  })
}
```

### 5-4. 시스템 알림

```bash
node .claude/scripts/notify.cjs "fix 완료" "{jira_key || title}: 커밋/푸시 완료"
```

### 5-5. 완료 메시지

```
✅ 수정 완료!

변경 내역:
- src/auth/login.ts (3줄 수정)

커밋: fix(auth): resolve token refresh retry logic
SHA: a1b2c3d

Jira: PROJ-123 → Done
브랜치: dev (pushed)
```

---

## Phase 6: 취소 (cancel)

### 6-1. 변경사항 되돌리기 (복구 가능)

```bash
# Stash에 저장 (복구 가능)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
git stash push -m "fix cancelled: $TIMESTAMP"

echo ""
echo "✅ 변경사항을 stash에 저장했습니다."
echo ""
echo "복구하려면:"
echo "  git stash list              # stash 목록 확인"
echo "  git stash apply stash@{0}   # 가장 최근 stash 복구"
echo "  git stash pop stash@{0}     # 복구 후 stash 삭제"
echo ""
```

### 6-2. Jira 상태 복원 (선택)

```typescript
if (jira_key) {
  // 원래 상태로 또는 Todo로
  mcp__jira__jira_transition_issue({
    issue_key,
    transition: "To Do"
  })
}
```

---

## 주의사항

### 금지사항
- ❌ `git add -A` / `git add .` 사용 금지
- ❌ 비밀 파일 커밋 금지 (.env, credentials)
- ❌ `Co-Authored-By` 자동 추가 금지 (사용자가 명시적으로 요청한 경우만 허용)

### 권장사항
- ✅ 간단한 수정만 (1-3 파일)
- ✅ dev 브랜치에서 직접 작업
- ✅ 리뷰 불필요한 작업만
- ✅ 복잡하면 `/orchestrate` 사용

---

## orchestrate vs fix 비교

| | orchestrate | /fix |
|---|---|---|
| **용도** | 새 기능 개발 | 간단한 수정 |
| **플랜** | ✅ 문서화 | ❌ Q&A만 |
| **워크트리** | ✅ 격리 | ❌ dev 직접 |
| **에이전트 리뷰** | ✅ 5개 | ❌ |
| **검증** | ✅ 3회 루프 | ✅ 1회만 |
| **사용자 테스트** | ❌ | ✅ 명시적 |
| **PR** | ✅ 자동 생성 | ❌ 직접 푸시 |
| **Jira** | ✅ 생성 가능 | ✅ 기존 이슈 |
| **시간** | 5-10분 | 2-3분 |

---

## Examples

### 예시 1: Jira 연동
```
/fix GIFCA-456 결제 금액 표시 오류
```
→ GIFCA-456 In Progress → 수정 → 테스트 → 커밋/푸시 → Done

### 예시 2: Standalone
```
/fix 로그인 페이지 타이포 수정
```
→ 수정 → 테스트 → 커밋/푸시

### 예시 3: 추가 수정
```
/fix PROJ-789 API 응답 포맷 변경
→ 수정 완료
→ "여기 타입도 추가해줘"
→ 추가 수정
→ /fix continue
```
