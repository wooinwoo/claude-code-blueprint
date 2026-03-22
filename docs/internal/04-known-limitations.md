# CCB 알려진 한계와 향후 개선 후보

---

## 구조적 한계

### 1. Pseudocode 기반 커맨드

커맨드 파일 안의 TypeScript/Bash 코드는 **실행 코드가 아니라 행동 지시**입니다.
Claude가 읽고 "이 순서로 하면 되는구나"라고 이해하고 따르는 방식입니다.

**한계**: 같은 커맨드를 실행해도 Claude가 매번 약간 다르게 해석할 수 있습니다.
100% 동일한 출력을 보장하지 않습니다.

**완화**: BAD/GOOD 예시를 많이 넣으면 일관성이 올라갑니다.

### 2. settings.json 기존 파일 보존

setup.ps1이 기존 settings.json을 안 건드리므로, 템플릿에서 allow 목록을 확장해도 기존 프로젝트에는 반영 안 됩니다.

**개선 후보**:
- `setup.ps1 --force-settings`: settings.json 강제 덮어쓰기 옵션
- `setup.ps1 --merge-settings`: 기존 allow + 신규 allow 합치기

### 3. Fullstack 에이전트 동기화

fullstack/agents/는 react-next + nestjs에서 복사한 것.
원본을 수정해도 fullstack에 자동 반영 안 됩니다.

**개선 후보**:
- fullstack이 원본을 참조하도록 setup.ps1에서 동적 합성
- 또는 fullstack을 "가상 프로필"로 만들어 react-next + nestjs를 실시간 합침

### 4. 토큰 비용 관리

Rules가 많아지면 매 세션마다 토큰을 많이 소비합니다.
현재는 수동으로 관리 (paths로 조건부 로드, 불필요한 룰 제거).

**개선 후보**:
- 각 룰 파일의 토큰 수 자동 계산 → 총 비용 리포트
- 임계값 초과 시 경고

---

## 기능적 한계

### 5. MCP 서버 의존성

designer 커맨드 중 Figma MCP, Playwright MCP 의존하는 것들:
- `/figma-to-code`: Figma Desktop + Dev Mode MCP 필수
- `/design-qa`: Figma MCP + Playwright MCP 동시 필요
- `/publish-check` Phase 2: Playwright MCP 필요

없으면 폴백이 있지만 기능이 크게 제한됩니다.

### 6. Windows 전용

setup.ps1이 PowerShell 스크립트라 macOS/Linux에서는 안 됩니다.

**개선 후보**:
- setup.sh (Bash 버전) 추가
- 또는 Node.js 기반 setup.js로 크로스 플랫폼

### 7. Planner 커맨드의 Jira 의존

모든 planner 커맨드에 Jira 폴백이 있어서 Jira 없이도 동작하지만,
Jira가 있을 때 훨씬 유용합니다 (이슈 자동 조회, 스프린트 데이터 등).

---

## 향후 개선 후보 (우선순위순)

| 우선순위 | 항목 | 설명 |
|----------|------|------|
| 1 | setup.sh 크로스 플랫폼 | macOS/Linux 지원 |
| 2 | settings.json merge 로직 | 기존 파일에 새 allow 항목 자동 합치기 |
| 3 | fullstack 동적 합성 | react-next + nestjs 원본에서 자동 합침 |
| 4 | 토큰 비용 리포트 | Rules/Skills 총 토큰 수 계산 |
| 5 | Plugin 형태로 배포 | CCB 자체를 Claude Code Plugin으로 패키징 |
| 6 | CI에서 자동 설치 | GitHub Actions에서 setup.ps1 자동 실행 |
