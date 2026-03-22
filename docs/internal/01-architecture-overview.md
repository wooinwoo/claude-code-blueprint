# CCB 아키텍처 전체 구조

## 한 줄 요약

프로젝트에 `setup.ps1 <프로필> <경로>` 한 줄 치면, 해당 역할에 맞는 에이전트/커맨드/룰/스킬/훅/MCP 설정이 `.claude/` 폴더에 설치됩니다.

---

## 3계층 시스템

```
┌─────────────────────────────────┐
│  Base (교체 가능)                │
│  ECC 커뮤니티에서 가져온 것      │
│  sync.ps1로 동기화               │
│  직접 수정 금지                  │
├─────────────────────────────────┤
│  Common (팀 공통)                │
│  /commit, /jira, /lighthouse    │
│  PR 규칙, MCP 래퍼 스크립트      │
├─────────────────────────────────┤
│  Stack / Profile (역할별)        │
│  6개 프로필 중 택 1              │
└─────────────────────────────────┘
          │
          │ setup.ps1
          ▼
    프로젝트/.claude/
```

### Base

- 출처: [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (ECC)
- `sync.ps1`로 ECC → `base/` 동기화
- `exclude.json`에서 불필요한 항목 제외 (Python, Go 등)
- **핵심 원칙: base/는 절대 직접 수정하지 않음**. 수정이 필요하면 common/ 또는 stack/에서 override
- 나중에 ECC가 아닌 다른 소스로 교체 가능 (sync.ps1만 수정)

### Common

- 모든 프로필에 공통 적용
- dev 프로필에는 전체 복사, non-dev에는 유틸 커맨드만 선별 복사 (commit, jira, guide)

### Stack / Profile

- 역할별로 다른 세트 제공
- dev 프로필: base 전체 + common + stack
- non-dev 프로필: base 일부(git-workflow, agents 룰만) + common 유틸 + profile

---

## 6개 프로필

| 프로필 | 대상 | Agents | Commands | Rules | Skills | MCP |
|--------|------|--------|----------|-------|--------|-----|
| `react-next` | React/Next.js 개발자 | 16 | 15 | 21 | 19 | 9 |
| `nestjs` | NestJS 백엔드 개발자 | 16 | 13 | 18 | 17 | 9 |
| `fullstack` | 프론트+백 풀스택 | 19 | 15 | 23 | 20 | 9 |
| `java-web` | Java 개발자 | - | - | - | - | - |
| `designer` | 퍼블리싱 디자이너 | 3 | 9 | 8 | 7 | 6 |
| `planner` | PM / 기획자 | 3 | 14 | 7 | 5 | 4 |

---

## 파일 전달 방식

모든 항목은 **파일 복사**입니다. (과거에는 Junction/symlink를 썼으나 현재는 전부 복사)

| 항목 | 전달 | 업데이트 |
|------|------|----------|
| rules, agents, commands, skills, hooks, scripts | 파일 복사 | setup.ps1 재실행 |
| settings.json, .mcp.json, .env | 최초 1회 복사 (있으면 SKIP) | 수동 편집 |

---

## setup.ps1 동작 순서

```
1. .claude/ 폴더 생성
2. .ccb-stack 파일에 프로필명 저장
3. rules/ 복사 (dev: base-common + base-typescript + ccb-common + ccb-stack)
                (non-dev: base-common 중 2개만 + ccb-common + ccb-stack)
4. agents/ 복사 (dev: base + common + stack)
                (non-dev: stack만)
5. commands/ 복사 (dev: base + common + stack)
                  (non-dev: common 유틸 3개 + stack)
6. skills/ 복사 (dev: base + stack)
               (non-dev: base 3개만 + stack)
7. hooks/ 복사
8. contexts/ 복사
9. scripts/ 복사
10. scripts-ccb/ 복사 (MCP 래퍼)
11. settings.json 생성 (없을 때만)
12. .mcp.json 생성 (없을 때만)
13. .env 생성 (없을 때만)
14. homunculus/ 생성 (학습 인스턴스)
15. CLAUDE.md 초안 생성 (없을 때만)
16. .gitignore 업데이트
```

---

## 핵심 커맨드

| 커맨드 | 프로필 | 역할 |
|--------|--------|------|
| `/orchestrate` | dev, fullstack | 6-Phase 개발 파이프라인 (Plan→Branch→Develop→Review→PR→Clean) |
| `/code-review` | dev | 5개 에이전트 병렬 코드 리뷰 |
| `/commit` | 전체 | Conventional commit 생성 |
| `/lighthouse` | dev, designer | 페이지별 Lighthouse 성능/접근성 체크 |
| `/refactor-clean` | dev | knip 기반 데드코드 분석 + 자동 제거 |
| `/design-system` | designer | 디자인 토큰 관리 (tokens/audit/component/suggest) |
| `/publish-check` | designer | 배포 전 점검 (Lighthouse+Playwright+정적분석) |
| `/prd` | planner | 10섹션 PRD 생성 |
| `/research` | planner | 리서치 플랜 수립 → WebSearch 실행 |
| `/story-map` | planner | Walking Skeleton MVP 검증 |
