---
description: 런치 체크리스트 생성/관리 + 릴리스 노트 생성. 기능 출시 전 점검과 커뮤니케이션.
---

# Launch — 런치 체크리스트 & 릴리스 노트

## Usage

```
/launch <feature>                   → 런치 체크리스트 생성
/launch <feature> --status          → 체크리스트 진행 상황 업데이트
/launch <feature> --notes           → 릴리스 노트 생성
```

## 용도

**기능/제품 출시 관리**
- 출시 전 체크리스트 생성 및 추적
- PRD/Jira 기반 맞춤형 체크리스트
- 진행 상황 관리 (done / skip / blocked)
- 릴리스 노트 자동 생성 (사용자용 + 내부용)

---

## 기본 모드: 체크리스트 생성

### Phase 1: 컨텍스트 수집

#### 1-1. 관련 PRD 탐색

```typescript
const prd_files = Glob("plans/prd-*{feature}*.md")

if (prd_files.length > 0) {
  const prd_content = Read(prd_files[0])
  console.log(`
  📄 관련 PRD 발견: ${prd_files[0]}
  → PRD의 범위, 릴리스 계획, 리스크를 체크리스트에 반영합니다.
  `)
}
```

#### 1-2. Jira Epic 탐색

```typescript
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
try {
  const epic = mcp__jira__jira_search({
    jql: "project = PROJ AND type = Epic AND summary ~ '{feature}'",
    limit: 5
  })

  if (epic.issues.length > 0) {
    // Epic 하위 이슈 상태 확인
    // ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
    const epic_issues = mcp__jira__jira_search({
      jql: `project = PROJ AND "Epic Link" = ${epic.issues[0].key} ORDER BY status ASC`,
      limit: 50
    })

    console.log(`
    🎯 관련 Epic: ${epic.issues[0].key} — ${epic.issues[0].summary}
    하위 이슈: ${epic_issues.total}건
    - Done: ${done_count}건
    - In Progress: ${in_progress_count}건
    - To Do: ${todo_count}건
    `)
  } else {
    console.log("⚠️ 관련 Epic을 찾을 수 없습니다. 일반 런치 체크리스트를 생성합니다.")
  }
} catch (error) {
  console.log("⚠️ Jira 접근 불가. PRD와 사용자 입력 기반으로 체크리스트를 생성합니다.")
}
```

#### 1-3. 기존 런치 체크리스트 확인

```typescript
const existing = Glob("plans/launch-*{feature}*.md")

if (existing.length > 0) {
  AskUserQuestion([
    {
      question: `기존 런치 체크리스트가 있습니다: ${existing[0]}`,
      header: "기존 체크리스트 발견",
      options: [
        { label: "새로 생성", description: "기존 파일을 덮어씁니다" },
        { label: "업데이트", description: "--status 모드로 전환" },
        { label: "취소", description: "작업 취소" }
      ]
    }
  ])
}
```

### Phase 2: 체크리스트 생성

PRD 범위와 Jira Epic 상태를 기반으로 체크리스트를 생성합니다.

#### 2-1. 기본 체크리스트 템플릿

```markdown
# Launch Checklist: {기능명}

## 메타 정보
- **기능**: {feature}
- **관련 PRD**: {prd_file 또는 '없음'}
- **관련 Epic**: {epic_key 또는 '없음'}
- **목표 출시일**: {TBD}
- **생성일**: {date}
- **진행률**: 0%

---

## 제품 (Product)
- [ ] PRD 최종 승인 완료
- [ ] 모든 개발 이슈 Done 상태 확인
- [ ] QA 테스트 완료 (기능 테스트 + 회귀 테스트)
- [ ] 엣지 케이스/예외 상황 테스트
- [ ] 크로스 브라우저/디바이스 테스트
- [ ] 롤백 계획 문서화
  - 롤백 트리거 조건:
  - 롤백 절차:
  - 롤백 담당자:

## 커뮤니케이션 (Communication)
- [ ] 릴리스 노트 작성 (사용자용)
- [ ] 릴리스 노트 작성 (내부/기술용)
- [ ] 내부 공지 (Slack/이메일)
- [ ] 고객 안내 (필요 시)
  - 대상: {사전 고지 필요 고객군}
  - 채널: {이메일/인앱/공지}
- [ ] 헬프센터/FAQ 문서 업데이트

## 모니터링 (Monitoring)
- [ ] 핵심 지표 대시보드 설정
  - 지표 1: {PRD 성공 지표에서 가져옴}
  - 지표 2:
- [ ] 에러율 알림 설정 (임계값: %)
- [ ] 성능 알림 설정 (응답시간 임계값: ms)
- [ ] Feature flag 설정
  - 플래그명:
  - 초기 노출: %
- [ ] 점진적 롤아웃 계획
  - D+0: 내부 사용자 ({n}%)
  - D+1: 베타 사용자 ({n}%)
  - D+3: 전체 ({n}%)

## 사후 관리 (Post-launch)
- [ ] D+1: 에러율/성능 모니터링
- [ ] D+1: 사용자 피드백 채널 모니터링
- [ ] D+7: 핵심 지표 리뷰
  - 목표 대비 달성률:
- [ ] D+14: 회고 일정 잡기
  - /retro 명령어로 회고 진행
```

#### 2-2. PRD 기반 맞춤화

```
PRD에서 추출하여 체크리스트에 반영하는 항목:
- 성공 지표 → 모니터링 섹션의 핵심 지표로
- 리스크 → 롤백 트리거 조건으로
- 릴리스 계획 → 점진적 롤아웃 단계로
- Out of Scope → "이번 출시에 포함되지 않음" 주의사항으로
```

### Phase 3: 사용자 검토

```typescript
AskUserQuestion([
  {
    question: "체크리스트를 검토하세요. 추가/삭제/수정할 항목이 있나요?",
    header: "체크리스트 검토",
    description: `${generated_checklist}

수정 방법:
- 항목 추가: "+ 새 항목 내용"
- 항목 삭제: "- 삭제할 항목 번호"
- 항목 수정: "= 번호: 수정 내용"
- 목표 출시일 설정: "출시일: YYYY-MM-DD"`,
    options: [
      { label: "확인", description: "이대로 저장" },
      { label: "수정", description: "항목 추가/삭제/변경" }
    ]
  }
])
```

### Phase 4: 저장

```typescript
Bash("mkdir -p plans")
// content-writer가 Write 도구로 저장
// plans/launch-{feature}.md
```

**완료 메시지:**
```
✅ 런치 체크리스트 생성 완료!

📄 문서: plans/launch-{feature}.md
🎯 기능: {feature}
📋 항목: {total_items}개

카테고리별:
- 제품: {n}개
- 커뮤니케이션: {n}개
- 모니터링: {n}개
- 사후 관리: {n}개

→ 진행 상황 업데이트: /launch {feature} --status
→ 릴리스 노트 생성: /launch {feature} --notes
```

---

## `--status` 모드: 진행 상황 업데이트

### Phase 1: 기존 체크리스트 읽기

```typescript
const launch_file = Glob("plans/launch-*{feature}*.md")

if (launch_file.length === 0) {
  console.log("런치 체크리스트가 없습니다. /launch {feature}로 먼저 생성하세요.")
  return
}

const content = Read(launch_file[0])
// 체크리스트 파싱: checked [ ], [x], 블록된 항목 식별
```

**현재 상태 출력:**
```
📊 런치 체크리스트 현황: {feature}

진행률: {completion}% ({done}/{total})

완료:   ✅ {done_count}건
미완료: ⬜ {pending_count}건
블록:   🚫 {blocked_count}건
스킵:   ⏭️ {skipped_count}건

미완료 항목:
1. [ ] PRD 최종 승인 완료
2. [ ] QA 테스트 완료
3. [ ] 릴리스 노트 작성 (사용자용)
...
```

### Phase 2: 항목별 상태 업데이트

```typescript
// 미완료 항목을 하나씩 확인
for (const item of pending_items) {
  AskUserQuestion([
    {
      question: `"${item.text}" — 상태를 업데이트하세요`,
      header: `항목 ${item.index}/${total}`,
      options: [
        { label: "완료 ✅", description: "이 항목을 완료 처리" },
        { label: "진행 중", description: "아직 진행 중, 다음에 다시 확인" },
        { label: "블록됨 🚫", description: "다른 이유로 진행 불가 (사유 입력)" },
        { label: "스킵 ⏭️", description: "이 기능에 해당 없음" },
        { label: "나머지 전부 스킵", description: "이후 항목은 건너뛰기" }
      ]
    }
  ])

  // "블록됨" 선택 시 추가 질문
  if (answer === "블록됨") {
    AskUserQuestion([
      {
        question: "블록 사유를 입력하세요",
        header: "블록 사유",
        options: []  // 자유 입력
      }
    ])
  }
}
```

### Phase 3: 파일 업데이트

```typescript
// 체크리스트 파일의 체크박스 상태 업데이트
// - [ ] → - [x] (완료)
// - [ ] → - [x] ~~항목~~ (스킵)
// - [ ] → - [ ] 🚫 항목 — 블록: {사유} (블록됨)

// 메타 정보의 진행률 업데이트
// 진행률: {new_completion}%

// Edit 도구로 파일 수정
```

### Phase 4: 진행 상황 요약

```
📊 업데이트 완료!

진행률: {prev}% → {new}% ({diff})

이번 업데이트:
- 완료: +{n}건
- 블록: +{n}건
- 스킵: +{n}건

남은 항목: {remaining}건

{completion >= 100 ? "🎉 모든 항목이 완료됐습니다! 출시 준비 완료!" : ""}
{blocked_count > 0 ? "⚠️ 블록된 항목이 있습니다. 해결이 필요합니다." : ""}
```

---

## `--notes` 모드: 릴리스 노트 생성

### Phase 1: 변경 사항 수집

#### 1-1. Git 커밋 히스토리

```bash
# 최근 태그 이후 커밋 또는 날짜 기준
git log --oneline --since="{since_date}" --no-merges
# 또는
git log --oneline {last_tag}..HEAD --no-merges
```

**태그/날짜 확인:**
```typescript
AskUserQuestion([
  {
    question: "릴리스 노트의 범위를 지정하세요",
    header: "변경 범위",
    options: [
      { label: "최근 태그 이후", description: "마지막 릴리스 태그부터 현재까지" },
      { label: "날짜 지정", description: "특정 날짜 이후 변경사항" },
      { label: "수동 입력", description: "변경사항을 직접 입력" }
    ]
  }
])
```

#### 1-2. Jira Epic 이슈

```typescript
// ⚠️ PROJ → 실제 Jira 프로젝트 키로 대체 (CLAUDE.md 또는 사용자 입력에서 확인)
const epic_issues = mcp__jira__jira_search({
  jql: `project = PROJ AND "Epic Link" = ${epic_key} AND status = Done ORDER BY updated DESC`,
  limit: 50
})

// 이슈를 카테고리별로 분류
// - 기능 (type = Story/Task)
// - 버그 수정 (type = Bug)
// - 개선 (type = Improvement)
```

**수집 결과 출력:**
```
📝 변경사항 수집 결과

Git 커밋: {commit_count}건
Jira 이슈: {issue_count}건

카테고리:
- 신규 기능: {n}건
- 버그 수정: {n}건
- 개선: {n}건
- 기타: {n}건
```

**예외 처리:**
```
Git 히스토리 없음:
→ "커밋 히스토리를 찾을 수 없습니다. Jira 데이터만으로 생성하거나 수동 입력하세요."

Jira + Git 모두 없음:
→ AskUserQuestion: "변경사항을 직접 입력하세요"
```

### Phase 2: content-writer 에이전트로 릴리스 노트 생성

**두 가지 버전을 동시에 생성합니다:**

```typescript
const release_notes = Agent("content-writer", `다음 변경사항을 바탕으로 릴리스 노트를 두 가지 버전으로 작성해줘.

기능: {feature}
변경 범위: {since} ~ {until}

Git 커밋:
{commit_log}

Jira 이슈:
{issue_list}

관련 PRD: {prd_summary 또는 '없음'}

---

## 버전 1: 사용자용 릴리스 노트
- 비기술적 언어 사용
- 사용자 입장에서의 변화/혜택 중심
- 기능 이름은 사용자가 이해할 수 있는 용어로
- 이모지 활용 OK
- 길이: 간결하게 (핵심만)

형식:
# {기능명} 업데이트

## 새로운 기능
- {사용자가 이해할 수 있는 기능 설명}

## 개선 사항
- {개선 내용}

## 버그 수정
- {수정된 문제 설명}

---

## 버전 2: 내부/기술용 릴리스 노트
- 기술 용어 사용 OK
- 변경된 API, 데이터 구조, 설정 변경 포함
- 마이그레이션 필요 사항 명시
- Known Issues 포함

형식:
# Release Notes: {기능명} {version}

## Changes
### Features
- {JIRA-KEY}: {기술적 변경 설명}

### Bug Fixes
- {JIRA-KEY}: {수정 내용}

### Improvements
- {변경 내용}

## Migration Guide
{마이그레이션 필요 시}

## Known Issues
- {알려진 이슈와 우회 방법}

## Configuration Changes
- {환경변수, 설정 파일 변경사항}

---

두 버전을 하나의 파일에 구분선으로 나눠서 작성해줘.
파일 경로: plans/release-notes-{feature}.md`)
```

### Phase 3: 저장

```typescript
// content-writer가 Write 도구로 저장
// plans/release-notes-{feature}.md
```

**완료 메시지:**
```
✅ 릴리스 노트 생성 완료!

📄 문서: plans/release-notes-{feature}.md

포함된 버전:
1. 사용자용 — 비기술적, 혜택 중심
2. 내부/기술용 — 기술 상세, 마이그레이션, Known Issues

변경사항 요약:
- 신규 기능: {n}건
- 버그 수정: {n}건
- 개선: {n}건

→ 내용 검토 후 필요하면 직접 수정하세요.
```

---

## 예외 처리

### Jira 접근 불가 (전체 모드 공통)

```
Jira에 접근할 수 없습니다.

영향:
- 체크리스트: Epic 기반 항목 커스터마이징 불가 → 일반 템플릿 사용
- --status: Jira 연동 없이 체크리스트만 업데이트
- --notes: Git 커밋 + 수동 입력으로 생성

계속 진행하시겠습니까?
→ AskUserQuestion: [진행 / 취소]
```

### PRD 없음 + Epic 없음

```
관련 PRD와 Jira Epic을 모두 찾을 수 없습니다.
일반 런치 체크리스트 템플릿으로 생성합니다.

→ Phase 3에서 항목을 직접 추가/수정하세요.
```

### 기존 체크리스트 없음 (`--status`)

```
런치 체크리스트가 없습니다 (plans/launch-*{feature}*.md).
/launch {feature}로 먼저 체크리스트를 생성하세요.
```

### Git 히스토리 없음 (`--notes`)

```
Git 커밋 히스토리를 찾을 수 없습니다.

선택하세요:
1. Jira 데이터만으로 생성
2. 변경사항 수동 입력
3. 취소
```

---

## 주의사항

### 금지사항
- ❌ 체크리스트 항목을 자동으로 완료 처리하지 않음
- ❌ 릴리스 노트에 미확인 정보 포함 금지
- ❌ 사용자용 릴리스 노트에 기술 용어/코드 사용 금지
- ❌ 롤백 계획 없이 출시 체크리스트 완료 처리 금지

### 권장사항
- ✅ PRD 성공 지표를 모니터링 항목에 반영
- ✅ 롤백 계획은 트리거 조건 + 절차 + 담당자 필수
- ✅ 릴리스 노트는 사용자용/내부용 두 버전 모두 생성
- ✅ 점진적 롤아웃 단계를 명시 (한 번에 100% 배포 지양)
- ✅ D+1, D+7 모니터링 일정 반드시 포함

---

## Examples

### 예시 1: 체크리스트 생성
```
/launch 상품-검색
```
→ PRD/Epic 탐색 → 맞춤형 체크리스트 생성 → 사용자 검토 → plans/launch-상품-검색.md 저장

### 예시 2: 진행 상황 업데이트
```
/launch 상품-검색 --status
```
→ 기존 체크리스트 읽기 → 미완료 항목 하나씩 확인 → 상태 업데이트 → 진행률 출력
```
📊 진행률: 45% → 72% (+27%)
남은 항목: 7건
블록: 1건 (에러율 알림 설정 — 인프라팀 대기 중)
```

### 예시 3: 릴리스 노트 생성
```
/launch 상품-검색 --notes
```
→ Git 커밋 + Jira 이슈 수집 → 사용자용/내부용 릴리스 노트 생성 → plans/release-notes-상품-검색.md 저장

### 예시 4: 전체 플로우
```
/launch 결제-리뉴얼              → 체크리스트 생성
(2주 후)
/launch 결제-리뉴얼 --status     → 진행 상황 업데이트 (72%)
(출시 1일 전)
/launch 결제-리뉴얼 --status     → 최종 확인 (95%)
/launch 결제-리뉴얼 --notes      → 릴리스 노트 생성
(출시 후)
/retro                          → 출시 회고
```
