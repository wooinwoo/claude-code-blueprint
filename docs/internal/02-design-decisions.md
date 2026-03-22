# CCB 설계 결정 기록

설계 과정에서 갈림길이었던 것들과 왜 현재 방향을 선택했는지 기록합니다.
수정할 때 이 맥락을 알아야 부작용 없이 변경할 수 있습니다.

---

## 1. Junction(symlink) vs 파일 복사

### 선택지
- **A. Junction**: 템플릿 git pull하면 모든 프로젝트에 자동 반영. 편함.
- **B. 파일 복사**: setup.ps1 재실행해야 반영. 번거로움.

### 선택: B (파일 복사)

### 이유
- Junction은 **로컬에서만 동작**. Git에 안 올라가서 팀원이 clone해도 링크가 안 걸림
- 프로젝트별로 커맨드를 커스터마이징하고 싶을 때 Junction이면 원본을 건드려서 다른 프로젝트까지 영향
- Windows에서 Junction 생성에 관리자 권한이 필요한 경우가 있음

### 수정 시 주의
- 현재 **모든 항목이 복사**. Junction으로 바꾸면 팀 공유 불가 문제 재발
- "자동 반영이 안 돼서 불편하다" → setup.ps1을 다시 돌리는 습관이 필요. 또는 update.ps1 사용

---

## 2. Commands vs Skills 통합

### 선택지
- **A. 기존 commands/ 유지**: 이미 30개 커맨드가 commands/에 있음
- **B. 전부 skills/로 마이그레이션**: 공식이 Skills 권장

### 선택: A (commands/ 유지)

### 이유
- 하위호환이 공식적으로 보장됨. commands/ 파일이 언제 deprecated될지 모르지만 현재는 동작
- 30개 일괄 변환은 **리스크만 크고 이득이 없음** (보조 파일, context:fork, !command 등 Skills 전용 기능을 현재 커맨드들이 안 쓰고 있음)
- 나중에 특정 커맨드에서 Skills 전용 기능이 필요할 때 **그때 그 커맨드만** 옮기면 됨

### 수정 시 주의
- 새 커맨드를 만들 때는 Skills(`.claude/skills/name/SKILL.md`) 형식 권장
- 기존 commands/ 파일을 skills/로 옮길 때 같은 이름이면 Skills가 우선함
- `disable-model-invocation: true` 넣어야 Claude가 마음대로 실행 안 함

---

## 3. Non-dev 프로필의 Base 필터링

### 선택지
- **A. Base 전체 포함**: 디자이너/기획자에게도 coding-style, testing 룰 적용
- **B. Base 완전 제외**: 디자이너/기획자에게 Base 아무것도 안 줌
- **C. 선별 포함**: 필요한 것만 허용 목록으로

### 선택: C (선별 포함)

### 현재 허용 목록
- **Rules**: `git-workflow.md`, `agents.md` (2개만)
- **Skills**: `strategic-compact`, `iterative-retrieval`, `search-first` (3개만)

### 이유
- A: 디자이너한테 `coding-style.md`, `testing.md`가 들어가면 불필요한 토큰 소비 + 혼란
- B: `git-workflow`는 디자이너도 필요 (커밋은 누구나 함)
- C: 필요한 것만 화이트리스트. 추가가 필요하면 `setup.ps1`의 `$nonDevBaseRulesAllow`, `$nonDevBaseSkillsAllow` 배열에 넣으면 됨

### 수정 시 주의
- 허용 목록은 `setup.ps1` 119번 줄(`$nonDevBaseRulesAllow`)과 202번 줄(`$nonDevBaseSkillsAllow`)
- Base에 새 룰/스킬이 추가되면 non-dev에도 필요한지 확인 후 허용 목록에 추가
- 임시 디렉토리(`$env:TEMP/ccb-base-*-filtered-XXXX`)를 사용하므로 동시 실행 충돌은 없음 (Get-Random 접미사)

---

## 4. Hooks 배치: hooks.json vs settings.json

### 선택지
- **A. hooks/hooks.json**: 프로필별 독립 hooks 파일
- **B. settings.json 내부**: 권한과 hooks를 한 파일에

### 선택: 둘 다 사용 (용도에 따라)

### 현재 구조
- **settings.json의 hooks**: dev 프로필에서 continuous-learning-v2 관찰 훅 (모든 도구 사용 추적)
- **hooks/hooks.json**: 프로필별 전용 훅 (designer: a11y 체크, planner: 문서 포맷 체크)

### 주의
- **non-dev settings.json에는 hooks를 비워야 함**. continuous-learning 스킬이 non-dev에 설치 안 되기 때문 (이전에 버그 있었음 — 매 도구 사용마다 에러)
- hooks/hooks.json은 setup.ps1이 프로필별로 복사
- settings.json은 최초 1회만 복사 (이미 있으면 SKIP). 나중에 hooks를 추가하려면 수동 편집 필요

---

## 5. Orchestrate 모드 분기: --full 플래그 vs 별도 커맨드

### 선택지
- **A. --full 플래그**: 한 파일에서 모드 분기
- **B. orchestrate-full.md 별도 파일**: Standard와 Full을 분리

### 선택: A (--full 플래그)

### 이유
- Phase 구조가 동일한데 파일을 나누면 **양쪽에 같은 코드가 중복**
- 하나를 수정하면 다른 것도 수정해야 함 — 코드 중복의 전형적 문제
- 한 파일 안에서 `> **모드 분기**` 주석으로 분기하면 유지보수 1곳

### 수정 시 주의
- 모든 모드 분기는 `mode` 변수를 체크해서 처리
- State 파일에 `"mode"` 저장되므로 세션 복구 시 자동 유지
- fullstack 프로필은 `mode`(standard/full) + `scope`(fullstack/frontend/backend) 두 축으로 분기

---

## 6. Fullstack orchestrate: 구현 순서

### 선택지
- **A. 프론트 먼저**: UI 만들고 Mock API → 나중에 실제 API 연결
- **B. 백엔드 먼저**: API 먼저 만들고 → 프론트에서 실제 연동
- **C. 동시**: 프론트/백 병렬 구현

### 선택: B (백엔드 먼저)

### 이유
- A: Mock API와 실제 API 사이 불일치가 나중에 대규모 수정 필요
- B: 실제 API가 있으면 프론트에서 바로 연동 테스트 가능. Mock 불필요
- C: 한 세션에서 프론트/백 동시 작업은 컨텍스트 스위칭 과다. Claude가 혼란

### 구현 순서
```
1. 공유 타입 정의 (API Contract)
2. 백엔드: Entity → Service → Controller → E2E 테스트
3. 백엔드 검증 루프 (lint→type→build→test)
4. 프론트: API 서비스 → Hooks → 컴포넌트 → 페이지
5. 프론트 검증 루프
6. 통합 확인
```

### 수정 시 주의
- 공유 타입을 먼저 정의하는 게 핵심. 이게 프론트/백의 계약
- 모노레포면 공유 타입 패키지 (`packages/shared` 등)에 넣을 수 있음
- 단일 레포면 `src/types/` 같은 곳에 공유

---

## 7. Co-Authored-By 정책

### 선택지
- **A. 완전 금지**: 커밋에 Co-Authored-By 절대 안 넣음
- **B. 자동 금지, 수동 허용**: Claude가 알아서 넣지는 않되 사용자가 요청하면 허용

### 선택: A (완전 금지)

### 이유
- 팀 정책으로 AI 생성 코드에 co-author 크레딧을 넣지 않기로 결정
- Claude가 관성적으로 넣는 걸 방지

---

## 8. Lighthouse 체크 위치

### 선택지
- **A. 독립 커맨드만**: `/lighthouse`로 필요할 때 수동 실행
- **B. orchestrate에 내장**: Phase 4(PR 전)에 자동 실행
- **C. 둘 다**

### 선택: C (둘 다)

### 이유
- `/lighthouse`는 개발 중 아무 때나 성능 체크하고 싶을 때
- orchestrate Phase 4는 PR 올리기 전 자동 게이트
- 둘 다 있어야 유연함

### 구현
- `common/commands/lighthouse.md`: 독립 커맨드 (페이지별 상세 분석)
- `react-next/commands/orchestrate.md` Phase 4-0: 간단 체크 (점수만)
- `fullstack/commands/orchestrate.md` Phase 4-0: scope가 backend만이면 스킵

---

## 9. settings.json 기존 파일 보존 정책

### 선택지
- **A. 항상 덮어쓰기**: setup.ps1 돌리면 최신 settings.json으로 교체
- **B. 없을 때만 생성**: 기존 파일이 있으면 건드리지 않음

### 선택: B (없을 때만 생성)

### 이유
- 사용자가 permissions를 커스터마이징했을 수 있음. 덮어쓰면 작업 날아감
- 새 allow 항목이 추가돼도 기존 프로젝트에는 자동 반영 안 됨

### 문제점
- 템플릿에서 allow 목록을 확장해도 **기존 프로젝트에는 반영 안 됨**
- 사용자가 수동으로 settings.json을 업데이트하거나, 기존 파일 삭제 후 setup.ps1 재실행

### 수정 시 고려
- `--force` 플래그로 settings.json 강제 덮어쓰기 옵션 추가 가능
- 또는 settings.json merge 로직 (기존 allow + 신규 allow 합치기) 구현 가능
