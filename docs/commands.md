# 커맨드 상세 가이드

---

## Common (전 프로필)

### /orchestrate

개발 파이프라인. 설계부터 PR까지 한 번에.

```
/orchestrate 상품 검색 페이지
/orchestrate --full 상품 검색 페이지     ← 고품질 모드
/orchestrate                            ← 진행 중인 파이프라인 이어서
```

| Phase | 내용 | Standard | Full |
|-------|------|----------|------|
| 0. Scan | 코드베이스 패턴 스캔 | 스킵 | O |
| 1. Plan | Q&A → 플랜 작성 → 사용자 승인 | 간단 플랜 | Opus architect 심층 설계 |
| 2. Branch | git worktree + 브랜치 생성 | O | O |
| 3. Develop | 구현 + 검증 루프 (최대 3회) | 구현만 | TDD 강제 |
| 4. PR | Lighthouse + 에이전트 리뷰 → PR | 에이전트 2-4개 | 전원 2라운드 |
| 5. Feedback | PR 코멘트 반영 | O | O |
| 6. Clean | worktree/브랜치 삭제 | O | O |

인수 없이 실행 시 → "뭘 만들까요?" → "Standard/Full?" 가이드 질문.
`.orchestrate/{slug}.json`에 상태 저장. 세션 끊겨도 이어서 진행.

**fullstack 프로필 추가 옵션:**
```
/orchestrate --front 검색 UI            ← 프론트만
/orchestrate --back 검색 API            ← 백엔드만
/orchestrate 검색 + API                 ← 풀스택 (기본)
```

풀스택: API 계약 먼저 정의 → 백엔드 구현 → 프론트 연동 순서.

---

### /code-review

현재 브랜치의 변경사항을 5개 관점에서 리뷰.

```
/code-review                ← main...HEAD diff 리뷰
/code-review --diff HEAD~3  ← 특정 범위
```

| 에이전트 | 관점 |
|---------|------|
| code-reviewer | 가독성, 중복, 네이밍, 에러 처리 |
| convention-reviewer | 프로젝트 컨벤션 준수 |
| security-reviewer | XSS, 시크릿, 인증, 의존성 |
| performance-reviewer | 렌더링, N+1, 번들, 메모리 |
| feasibility-reviewer | 요구사항 충족, 엣지케이스 |

출력: CRITICAL / HIGH / MEDIUM / LOW 심각도 테이블.

---

### /build-fix

빌드 에러 자동 수정.

```
/build-fix          ← lint → type → build 순서로 수정
```

1. `pnpm lint --fix` → 실패하면 수정 후 재실행
2. `pnpm tsc --noEmit` → 타입 에러 수정
3. `pnpm build` → 빌드 에러 수정
4. 최대 5회 루프

---

### /lighthouse

페이지별 Lighthouse 성능/접근성/SEO 분석.

```
/lighthouse                              ← 라우트 자동 탐지 + 전체 분석
/lighthouse --pages /,/login,/dashboard  ← 특정 페이지만
/lighthouse --threshold 90               ← 기준 점수 변경 (기본 80)
/lighthouse --url http://localhost:3000   ← dev 서버 URL 지정
```

라우트 자동 탐지: Next.js App/Pages Router, TanStack Router, React Router, Vite.
동적 라우트(`[id]`, `$id`)는 자동 제외. `--pages`로 직접 지정.

출력:
- 페이지별 4개 점수 (Performance, Accessibility, Best Practices, SEO)
- Core Web Vitals (LCP, FCP, TBT, CLS)
- 기준 미달 페이지별 원인 + 개선 제안

Chrome 없으면 Playwright 기본 측정으로 폴백.

---

### /refactor-clean

knip 기반 데드코드 분석 + 안전 제거.

```
/refactor-clean              ← 전체 분석 리포트
/refactor-clean exports      ← 미사용 export만
/refactor-clean deps         ← 미사용 의존성만
/refactor-clean files        ← 미사용 파일만
/refactor-clean fix          ← 분석 후 안전 항목 자동 제거
```

분류:
- **SAFE**: import 0건, 동적 import 없음 → 자동 제거 가능
- **REVIEW**: 동적 import 가능성, 테스트에서만 사용 → 사용자 확인
- **SKIP**: entry point, config, 타입 선언 → 제거 금지

NestJS: `@Injectable`, `@Controller`, `@Module` 등 데코레이터가 있는 파일은 자동 SKIP.
제거 후 lint + type + build + test 검증.

---

### /commit

Conventional commit 메시지 자동 생성.

```
/commit              ← staged 변경 분석 → 커밋 메시지 생성 → 확인 → 커밋
```

- type 자동 선택 (feat/fix/refactor/docs/chore)
- scope 자동 감지 (변경 파일 최상위 디렉토리)
- Co-Authored-By 추가 금지

---

### /jira

Jira 이슈 생성/관리.

```
/jira bug 로그인 실패        ← Bug 이슈 생성
/jira task API 연동          ← Task 이슈 생성
/jira story 검색 기능        ← Story 이슈 생성
```

MCP (mcp-atlassian) 연동. `.claude/.env`에 JIRA_TOKEN 필요.

---

### /fix

경량 버그 수정 (1-3 파일).

```
/fix 로그인 시 500 에러
/fix PROJ-123
```

Jira 연동 → Q&A → 수정 → 검증 → 커밋. orchestrate보다 가벼움.

---

### /guide

현재 상황에 맞는 커맨드 추천.

```
/guide               ← "뭘 하고 싶으세요?" → 적합한 커맨드 안내
```

---

### /learn

학습 시스템. 세션 중 발견한 패턴/인사이트 저장.

```
/learn               ← 현재 세션에서 학습한 것 정리
```

---

## React-Next 전용

### /test-coverage

커버리지 분석 + 미커버 테스트 자동 생성.

```
/test-coverage              ← 커버리지 리포트
/test-coverage fill         ← 미커버 파일에 테스트 자동 생성
```

Vitest/Jest 기반. 커버리지 수집 → 미커버 함수/브랜치 식별 → 테스트 생성.

### /verify

lint + type + build + test 일괄 검증.

```
/verify              ← 전체 검증
```

---

## NestJS 전용

### /wt

Git worktree 관리.

```
/wt new 기능명       ← 새 worktree + 브랜치 생성
/wt list            ← 현재 worktree 목록
/wt sync            ← main 변경사항 동기화
/wt rm 기능명       ← worktree + 브랜치 삭제
```

---

## Fullstack 전용

### /orchestrate (풀스택 버전)

프론트 + 백엔드 동시 구현.

```
/orchestrate 상품 관리 CRUD + API       ← 풀스택 (기본)
/orchestrate --front 검색 UI           ← 프론트만
/orchestrate --back 검색 API           ← 백엔드만
/orchestrate --full 상품 관리          ← 풀스택 Full 모드
```

풀스택 구현 순서:
1. 공유 타입 정의 (API Contract)
2. 백엔드: Entity → Service → Controller → E2E
3. 프론트: API 서비스 → Hooks → 컴포넌트 → 페이지
4. 통합 확인

리뷰: react-reviewer + nestjs-pattern-reviewer + database-reviewer + security-reviewer 전부 투입.

---

## Designer 전용

### /design-system

디자인 토큰 관리.

```
/design-system tokens              ← 현재 토큰 목록 + 사용 빈도
/design-system audit               ← 하드코딩/미사용/중복 토큰 감사
/design-system component Button    ← 컴포넌트 사용처 + props + variants
/design-system suggest             ← 반복 패턴 → 토큰화/컴포넌트화 제안
```

Tailwind v3 (JS config) + v4 (@theme CSS) 모두 지원.

### /publish-check

배포 전 점검.

```
/publish-check                    ← 소스 정적 분석
/publish-check --url <url>        ← Lighthouse + Playwright
/publish-check --url <url> --full ← 전체
```

Phase 1: Lighthouse (Performance, Accessibility, Best Practices, SEO)
Phase 2: Playwright (3 뷰포트 반응형, 터치 타겟, 오버플로우)
Phase 3: Grep 패턴 (img alt, onClick a11y, 하드코딩 색상, SEO 메타)

### /figma-to-code

Figma 시안 → 코드 변환.

```
/figma-to-code                  ← 현재 Figma 선택 노드 → 코드
/figma-to-code --component      ← 단일 컴포넌트
/figma-to-code --page           ← 전체 페이지 레이아웃
/figma-to-code --tokens         ← 디자인 토큰만 추출
```

Figma Desktop + Dev Mode MCP 필요. 미연결 시 스크린샷 기반 폴백.

### /design-review

3개 에이전트 병렬 리뷰.

```
/design-review              ← 전체 리뷰
/design-review --diff       ← 변경 파일만
/design-review --a11y-only  ← 접근성만
```

| 에이전트 | 관점 |
|---------|------|
| design-reviewer | 시각 일관성, 레이아웃, 토큰 |
| a11y-reviewer | WCAG AA, 대비, 키보드, ARIA |
| markup-reviewer | 시맨틱 HTML, CSS 구조 |

### /design-qa

Figma 시안 vs 구현물 비교.

```
/design-qa                       ← Figma 선택 노드 vs 구현
/design-qa --url <url>           ← 배포 URL과 비교
/design-qa --component Button    ← 특정 컴포넌트
```

허용 오차: 색상 ±0, 폰트 ±1px, 패딩 ±2px, 크기 ±4px.

### /discover

컴포넌트 인벤토리.

```
/discover                       ← 전체 컴포넌트 탐색
/discover --unused              ← 미사용 컴포넌트
/discover --similar             ← 유사/중복 컴포넌트
/discover --deps Button         ← 의존성 트리
```

---

## Planner 전용

### /research

리서치 플랜 수립 → WebSearch 실행.

```
/research 공공조달 시장               ← 플래그 없으면 리서치 플랜 먼저 수립
/research --market 공공조달           ← 시장 리서치 직행
/research --user 중소기업 입찰담당자   ← 사용자 리서치
/research --tech Playwright           ← 기술 리서치
/research --competitor 비드프로       ← /competitive-analysis로 안내
```

플래그 없이 실행 시:
1. 기존 plans/ 문서 + CLAUDE.md 맥락 수집
2. researcher-strategist가 리서치 플랜 초안 (핵심 질문, 검색 전략, 예상 소스)
3. 사용자 확인 후 실행

### /prd

10섹션 PRD 생성.

```
/prd 사용자 인증 v2              ← 새 PRD 생성
/prd 사용자 인증 v2 --review     ← 기존 PRD 리뷰
/prd 사용자 인증 v2 --update     ← 기존 PRD 업데이트
/prd PROJ-123                   ← Jira 이슈 기반
```

10섹션: 개요, 배경, 목표, 사용자 스토리, 기능 명세, 디자인, 기술 고려, 릴리스 계획, 리스크, 참고.
누락 섹션 자동 감지 → content-writer가 보충.
TBD 항목 기한/담당자 필수.

### /competitive-analysis

경쟁사 분석.

```
/competitive-analysis 공공조달 입찰정보 서비스
/competitive-analysis --feature AI 추천 기능
```

WebSearch 기반 (경쟁사당 3회). 기능 매트릭스 + SWOT + 차별화 기회.

### /story-map

스토리맵 + Walking Skeleton MVP 검증.

```
/story-map 사용자 인증              ← PRD 기반 스토리맵 생성
/story-map 사용자 인증 --update     ← 기존 스토리맵 업데이트
```

Activity → Task → Story 계층. Walking Skeleton: 모든 Activity에 최소 1개 MVP 스토리 + 흐름 연결성 검증.

### /okr

OKR 생성/검토.

```
/okr 2026-Q2                    ← 새 OKR 생성
/okr 2026-Q2 --review           ← 진척 검토
/okr 2026-Q2 --align            ← 상위 OKR과 정렬
```

품질 게이트: O는 정성적, KR은 정량적 자동 검증. Jira 연동 시 진척률 자동 계산.

### /spec

경량 기능 명세 (PRD보다 가벼움).

```
/spec AI 입찰 추천
/spec AI 입찰 추천 --jira PROJ-123
```

5섹션. 수용기준(AC) 테스트 가능성 자동 체크 — 주관적 표현 감지.
AC 7개 초과 시 → /prd 리다이렉트.

### /sprint-plan

스프린트 계획.

```
/sprint-plan                    ← 다음 스프린트 계획
/sprint-plan --current          ← 현재 스프린트 상태 + 번다운
```

용량 기반. 캐리오버 자동 감지. Jira 또는 수동 입력.

### /retro

회고.

```
/retro                          ← 직전 스프린트 회고
/retro --project                ← 프로젝트 전체 회고
```

프레임워크: 4L / Starfish / Sailboat 선택. 이전 액션 아이템 추적.

### /launch

런치 체크리스트.

```
/launch 상품 검색                ← 체크리스트 생성
/launch 상품 검색 --status       ← 진행 상태 업데이트
/launch 상품 검색 --notes        ← 릴리스 노트 생성
```

카테고리: 제품, 커뮤니케이션, 모니터링, 사후관리.
롤백 계획 + Feature flag 4단계 롤아웃.

### /weekly-update

주간 리포트.

```
/weekly-update                   ← 기본 모드
/weekly-update --team            ← 팀원별 상세
/weekly-update --exec            ← 1페이지 경영진용
```

Jira 또는 수동 입력. 완료/진행중/블로커/계획 섹션.

### /roadmap

로드맵.

```
/roadmap                        ← 새 로드맵 생성
/roadmap --review               ← 기존 로드맵 vs Jira 동기화
```

RICE 스코어링 + OKR 연계. 분기별 배치.
