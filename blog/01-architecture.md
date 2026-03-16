# Claude Code 셋업 가이드 (1) — 아키텍처: 왜 설정 시스템이 필요한가

> 시리즈: Claude Code 셋업 가이드
> 1편: 아키텍처 | 2편: Rules | 3편: Commands | 4편: Skills | 5편: Agents | 6편: Hooks | 7편: MCP | 8편: 프로필

---

## 1단계: CLAUDE.md 하나로 시작

Claude Code를 처음 쓰면 대부분 이렇게 시작합니다.

```markdown
# My Project
React 19 + TanStack Router + Tailwind v4
컴포넌트는 함수형, API는 /api/v1/ prefix
```

이거면 충분합니다. Claude가 프로젝트 맥락을 이해하고, 코드도 나름 잘 짜줍니다.

저도 처음에는 이랬습니다. 한동안은 문제없었고요.

---

## 2단계: .claude/ 폴더를 알게 됨

쓰다 보니 CLAUDE.md만으로는 부족한 순간이 옵니다.

- Claude가 `console.log`를 남발합니다 → 매번 "console.log 쓰지 마"라고 말해야 합니다
- 커밋 메시지를 제멋대로 씁니다 → "conventional commit 써"를 반복합니다
- 코드 리뷰를 시키면 관점이 매번 다릅니다 → 체계가 없습니다

이때 `.claude/` 폴더의 존재를 알게 됩니다.

```
.claude/
├── rules/        ← 매 세션마다 자동으로 읽히는 규칙
├── agents/       ← "이 역할로 일해" 서브에이전트
├── commands/     ← /슬래시커맨드
├── skills/       ← 상황별 전문지식
├── hooks/        ← 도구 사용 전후 자동 트리거
└── contexts/     ← 모드 전환
```

`rules/no-console-log.md`를 만들어두면 더 이상 말 안 해도 됩니다. `commands/commit.md`를 만들면 `/commit` 한 번에 컨벤셔널 커밋이 나옵니다.

이게 편해지면서 `.claude/` 안에 파일이 점점 쌓입니다. 리뷰 에이전트, 빌드 에러 해결 에이전트, 테스트 커버리지 커맨드... 한 프로젝트에서 꽤 잘 돌아가는 세팅이 만들어집니다.

그리고 두 번째 프로젝트를 시작합니다.

---

## 3단계: 복붙 지옥

두 번째 프로젝트에서 첫 번째 프로젝트의 `.claude/` 폴더를 통째로 복사합니다. 잘 됩니다.

세 번째, 네 번째 프로젝트에도 복사합니다. 여전히 잘 됩니다.

그러다 첫 번째 프로젝트에서 리뷰 에이전트를 개선합니다. 리뷰 관점을 5개로 나누고, 병렬 실행하도록 바꿨습니다. 확실히 좋아졌습니다.

나머지 프로젝트에도 반영해야 합니다. 수동으로요. 하나씩요.

이 시점에서 깨닫습니다:

> **이거 코드 중복이랑 똑같은 문제다.**

코드에서는 공통 로직을 라이브러리로 뺍니다. Claude Code 설정도 똑같이 해야 합니다.

---

## 4단계: 중앙 저장소로 분리

`.claude/` 안의 파일들을 별도 저장소로 빼고, 각 프로젝트에는 설치만 하는 방식으로 바꿨습니다.

그런데 단순히 한 폴더를 공유하면 안 됩니다. 프로젝트마다 기술 스택이 다르니까요. React 프로젝트에 NestJS E2E 테스트 룰이 들어가면 의미가 없습니다.

그래서 **3개 계층**으로 나눴습니다.

| 계층 | 역할 | 내용 |
|:----:|------|------|
| **Base** | 교체 가능한 베이스 | 커뮤니티 에이전트, 룰, 스킬. 어떤 소스든 갈아끼울 수 있음 |
| ↓ | | |
| **Common** | 우리 팀 공통 | /commit, /jira, /code-review, PR 규칙, MCP 래퍼 |
| ↓ | | |
| **Stack** | 역할별 | react-next \| nestjs \| designer \| planner |
| ↓ `setup.ps1` | | |
| **프로젝트/.claude/** | 설치 결과 | 위 3개 계층이 합쳐져서 들어감 |

### Base — 바닥은 갈아끼울 수 있어야 합니다

처음에는 전부 직접 만들려고 했습니다. 그러다 [everything-claude-code(ECC)](https://github.com/affaan-m/everything-claude-code)를 발견했습니다. Claude Code용 에이전트, 룰, 스킬을 모아놓은 오픈소스인데, 잘 만들어진 게 꽤 있었습니다.

그래서 ECC를 Base로 쓰되, **직접 수정하지 않는 규칙**을 세웠습니다. 동기화 스크립트로 가져오고, 쓸모없는 건 exclude하고, 수정이 필요하면 Common이나 Stack에서 override합니다.

```powershell
.\sync.ps1    # ECC → base/ 동기화
```

```jsonc
// exclude.json — Python, Go 관련은 제외
{
  "rules": ["golang", "python"],
  "agents": ["go-reviewer.md", "python-reviewer.md"],
  "skills": ["django-patterns", "springboot-tdd"]
}
```

중요한 건, **Base가 ECC에 종속된 게 아니라는 점**입니다. 나중에 더 좋은 보일러플레이트가 나오면 `sync.ps1`만 수정해서 통째로 갈아끼우면 됩니다. Common과 Stack은 전혀 영향 없습니다. 직접 처음부터 만들어도 되고요.

### Common — 프로젝트 불문 공통

어떤 프로젝트든 동일한 것들입니다. 커밋 메시지 포맷, PR 작성 규칙, Jira 연동 같은 것들이요.

```
common/
├── rules/
│   ├── pull-request.md
│   └── jira.md
├── commands/
│   ├── commit.md
│   ├── jira.md
│   └── code-review.md
└── scripts/
    ├── run-github-mcp.cjs
    └── run-jira-mcp.cjs
```

### Stack / Profile — 역할에 따라 다른 세트

설치할 때 역할을 선택합니다.

```powershell
.\setup.ps1 react-next C:\path\to\project    # React 개발자
.\setup.ps1 nestjs C:\path\to\project        # NestJS 개발자
.\setup.ps1 designer C:\path\to\project      # 디자이너
.\setup.ps1 planner C:\path\to\project       # PM / 기획자
```

React 개발자는 react-reviewer, performance-reviewer 같은 에이전트와 `/orchestrate`, `/test-coverage` 같은 커맨드를 받습니다. 기획자는 `/prd`, `/research`, `/competitive-analysis` 같은 문서 작성 도구를 받고요.

| | react-next | nestjs | designer | planner |
|--|-----------|--------|----------|---------|
| 에이전트 | 15개 | 15개 | 3개 | 3개 |
| 커맨드 | 11개 | 10개 | 6개 | 11개 |
| 룰 | 18개 | 15개 | 4개 | 3개 |
| MCP 서버 | 9개 | 9개 | 6개 | 4개 |

---

## 5단계: 업데이트를 어떻게 반영할 것인가

여기서 하나 더 결정해야 할 게 있었습니다.

템플릿을 수정했을 때, 이미 설치된 프로젝트에 어떻게 반영할 것인가?

setup.ps1은 두 가지 방식으로 파일을 넣습니다:

- **심볼릭 링크(Junction)** — rules, hooks, contexts
- **파일 복사** — agents, commands, skills

Junction으로 건 파일은 템플릿 원본을 직접 가리킵니다. 템플릿에서 `git pull`하면 **내 로컬의 모든 프로젝트에 즉시 반영**됩니다. 룰 하나 수정하면 6개 프로젝트 전부 바로 적용이죠.

복사한 파일은 프로젝트에 독립적으로 존재합니다. 템플릿을 수정해도 `setup.ps1`을 다시 돌려야 반영됩니다. 대신 프로젝트별로 커스터마이징할 수 있습니다. "이 프로젝트에서는 /orchestrate를 좀 다르게 쓰고 싶다"는 경우가 생기거든요.

```powershell
# 템플릿 수정 후
cd claude-code-blueprint && git pull
# rules, hooks → 이미 반영됨 (Junction)
# agents, commands → 재설치 필요
.\setup.ps1 react-next C:\my-project
```

한 가지 유의할 점은, **Junction은 로컬에서만 동작한다는 점**입니다. `.claude/`는 보통 `.gitignore`에 들어가 있어서 팀원의 Git에는 올라가지 않습니다. 팀으로 쓸 때는 각 팀원이 자기 로컬에서 `setup.ps1`을 돌려야 합니다. 템플릿 저장소 자체를 팀이 공유하고, 각자 설치하는 구조입니다.

---

## 현재 상태

지금은 이 구조로 실제 프로젝트들을 운영하고 있습니다. 리뷰 에이전트를 개선하면 `setup.ps1` 한 번 돌리면 되고, 룰을 추가하면 `git pull`만 하면 됩니다. 새 프로젝트를 시작할 때는 `setup.ps1` 한 줄이면 세팅이 끝납니다.

다음 편부터는 이 시스템을 구성하는 각 요소를 하나씩 다루겠습니다. 2편은 **Rules** — Claude가 자기 맘대로 코드 쓰는 걸 어떻게 교정하는지에 대한 이야기입니다.

---

> 템플릿: [claude-code-blueprint](https://github.com/wooinwoo/claude-code)
> 참고: [everything-claude-code](https://github.com/affaan-m/everything-claude-code), [CLAUDE.md 가이드](https://velog.io/@surim014/claude-md-guide)
