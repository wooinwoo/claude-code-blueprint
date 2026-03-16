---
description: 변경사항 분석 후 conventional commit 메시지 생성 및 커밋.
---

# Commit

## Usage

```
/commit                → 전체 변경사항 분석 후 커밋
/commit feat 로그인    → 타입/힌트 지정
```

## 절차

### 1. 변경사항 수집 (병렬 실행)

```bash
git diff --cached          # staged
git diff                   # unstaged
git status                 # 전체 상태
git log --oneline -10      # 최근 커밋 스타일 참고
```

### 2. 분석 및 판단

- 변경 없음 → 사용자에게 알리고 중단
- 변경이 여러 관심사에 걸침 → 분리 커밋 제안 (AskUserQuestion)
- 비밀 파일 포함 (.env, credentials, tokens) → 해당 파일 제외하고 경고

### 3. 스테이징

**개별 파일만 추가** — `git add -A`, `git add .` 절대 금지

```bash
git add src/auth/login.ts src/auth/login.test.ts
```

### 4. 커밋

```
<type>(<scope>): <description>
```

| type | 용도 |
|------|------|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변경 없는 구조 개선 |
| `test` | 테스트 추가/수정 |
| `chore` | 의존성, 설정 등 유지보수 |
| `docs` | 문서만 변경 |
| `perf` | 성능 개선 |
| `ci` | CI/CD 변경 |

**규칙:**
- 72자 이내, 소문자, 마침표 없음
- 명령형 ("add" not "added")
- scope = 영향받는 모듈/영역
- 영어로 작성

**예시:**
- `feat(auth): add JWT refresh token rotation`
- `fix(order): resolve race condition in payment callback`
- `refactor(user): extract email validation to value object`

## Few-shot Example

**git diff 출력:**
```diff
--- a/src/auth/jwt.strategy.ts
+++ b/src/auth/jwt.strategy.ts
@@ -12,6 +12,10 @@ export class JwtStrategy {
   async validate(payload: JwtPayload): Promise<UserContext> {
-    return { userId: payload.sub };
+    const user = await this.userRepo.findById(payload.sub);
+    if (!user || user.isDeleted) {
+      throw new UnauthorizedException('User not found or deactivated');
+    }
+    return { userId: user.id, role: user.role };
   }
```

**분석 과정:**
1. `src/auth/` 경로 → scope: `auth`
2. 기존 동작을 수정 (validate 로직 보강) → 버그 수정인가? 기능 추가인가?
3. 삭제된 유저/비활성 유저 체크 추가 → 보안 취약점 수정 = `fix`
4. 변경 목적: "삭제/비활성 유저의 JWT 토큰이 여전히 유효했던 문제"

**결과:**
```bash
git add src/auth/jwt.strategy.ts
git commit -m "fix(auth): reject JWT tokens for deleted or deactivated users"
```

## 금지사항

- `git add -A` / `git add .` 사용 금지
- 비밀 파일 커밋 금지
- `Co-Authored-By` 추가 금지
