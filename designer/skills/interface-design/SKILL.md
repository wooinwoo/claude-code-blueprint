---
name: interface-design
description: Use this skill when designing complete interfaces or screens. Covers information architecture, user flow design, and interaction patterns.
---

# Interface Design Skill

UI 코드를 생성할 때 직접 적용하는 구현 규칙과 코드 패턴.

## 네비게이션

### 규칙
- 주 네비게이션: 최대 7±2 항목. 초과 시 "더보기" 드롭다운으로 그룹핑
- 모바일: bottom nav (max 5 아이콘) 또는 hamburger. 둘 다 쓰지 말 것
- breadcrumb: 3단계 이상 depth에서만 표시. 2단계는 뒤로가기 버튼으로 충분
- 현재 위치 표시: `aria-current="page"` + 시각적 강조 (font-semibold + text-primary)
- 로고 클릭: 항상 홈으로 이동. 현재 페이지가 홈이면 클릭 비활성화

### 코드 패턴
```tsx
// 모바일 bottom nav — 48px 최소 터치 영역 준수
<nav className="fixed bottom-0 inset-x-0 bg-surface border-t border-outline flex justify-around py-2 md:hidden">
  {items.slice(0, 5).map(item => (
    <a key={item.href} href={item.href}
       className={cn("flex flex-col items-center gap-1 min-w-[48px] min-h-[48px] justify-center",
         item.active ? "text-primary" : "text-on-surface-variant")}
       aria-current={item.active ? "page" : undefined}>
      <item.icon className="w-6 h-6" />
      <span className="text-xs">{item.label}</span>
    </a>
  ))}
</nav>
```

## 폼 디자인

### 규칙
- 레이블: 입력 필드 **위** (왼쪽 아님). `font-medium`, `margin-bottom` 4-8px
- placeholder: 입력 예시만 표시. 레이블 대체 금지 (접근성 위반)
- 에러 메시지: 필드 아래, `text-error`, `role="alert"`. 기술 용어 금지 ("유효하지 않은 형식" → "이메일 주소를 확인해주세요")
- 필수 표시: 별표(*) + `aria-required="true"`. 별표는 `aria-hidden="true"`
- submit 버튼: 폼 끝에 우측 정렬 (LTR) 또는 전체 너비 (모바일)
- 비밀번호: 표시/숨김 토글 필수. `autocomplete="current-password"` 또는 `"new-password"`
- input `type="email"`, `type="tel"`: 모바일 키보드 최적화 위해 반드시 올바른 type 사용
- 모바일 input font-size: **최소 16px** (iOS 자동 줌 방지)
- 실시간 유효성 검사: blur 시 실행. 타이핑 중 에러 표시 금지 (사용자 짜증)

### 코드 패턴
```tsx
<div className="flex flex-col gap-1.5">
  <label htmlFor="email" className="text-sm font-medium text-on-surface">
    이메일 <span className="text-error" aria-hidden="true">*</span>
  </label>
  <input
    id="email" type="email" required aria-required="true"
    aria-describedby={error ? "email-error" : undefined}
    aria-invalid={error ? "true" : undefined}
    placeholder="name@example.com"
    className={cn("px-3 py-2 rounded-lg border text-base", // 16px — iOS 줌 방지
      error ? "border-error focus:ring-error" : "border-outline focus:ring-primary")}
  />
  {error && (
    <p id="email-error" role="alert" className="text-sm text-error">{error}</p>
  )}
</div>
```

## 상태 표시

### 규칙
- **Loading**: skeleton > spinner. skeleton은 실제 콘텐츠 레이아웃과 동일한 형태로 (레이아웃 시프트 방지)
- **Empty state**: 일러스트(또는 아이콘) + 설명 문구 + CTA 버튼. "데이터가 없습니다"만 표시 금지
- **Error state**: 사용자가 이해할 수 있는 원인 설명 + 재시도 버튼. "500 Internal Server Error" 금지
- **Success**: 토스트 3-5초 자동 닫힘. 중요한 성공(결제 완료 등)은 전체 페이지 확인 화면
- **Partial loading**: 이미 로드된 콘텐츠는 유지하고 추가 영역만 skeleton 표시

### 코드 패턴
```tsx
// Skeleton — 실제 콘텐츠 구조 반영
<div className="animate-pulse flex flex-col gap-4">
  <div className="h-4 bg-surface-variant rounded w-3/4" />
  <div className="h-4 bg-surface-variant rounded w-1/2" />
  <div className="h-32 bg-surface-variant rounded" />
</div>

// Empty state — 항상 다음 행동을 안내
<div className="flex flex-col items-center justify-center py-16 text-center">
  <EmptyIcon className="w-16 h-16 text-on-surface-variant mb-4" />
  <h3 className="text-lg font-semibold text-on-surface mb-2">아직 항목이 없습니다</h3>
  <p className="text-sm text-on-surface-variant mb-6 max-w-sm">첫 번째 항목을 추가해 시작하세요.</p>
  <button className="px-4 py-2 bg-primary text-on-primary rounded-lg font-medium">항목 추가</button>
</div>
```

## 인터랙션 피드백

### 규칙
- 버튼: `hover` + `active` + `focus-visible` + `disabled` 4가지 상태 필수. 하나라도 빠지면 미완성
- 클릭 후 응답 지연 > 100ms: loading indicator 표시. 버튼 내부 spinner 또는 disabled+로딩 텍스트
- disabled 요소: `opacity-50` + `cursor-not-allowed` + `title`로 비활성 이유 설명
- `focus-visible`: `outline-2 outline-offset-2 outline-primary`. 브라우저 기본 outline 제거 금지
- 중복 클릭 방지: submit 버튼은 요청 중 disabled 처리. 낙관적 UI에서도 동일
- transition: `duration-150` 기본. 300ms 이상은 느리게 느껴짐

### 코드 패턴
```tsx
<button className={cn(
  "px-4 py-2 rounded-lg font-medium transition-colors duration-150",
  "bg-primary text-on-primary",
  "hover:bg-primary/90",
  "active:bg-primary/80",
  "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
  "disabled:opacity-50 disabled:cursor-not-allowed"
)} />
```

## 모달/다이얼로그

### 규칙
- 모달 열릴 때: 배경 스크롤 잠금 (`overflow: hidden` on body), focus trap, Escape로 닫기
- 닫기: 우상단 X 버튼 + Escape 키 + 배경 오버레이 클릭 (파괴적 액션 모달은 배경 클릭 닫기 금지)
- 확인/취소 버튼 순서: 확인(primary) 우측, 취소(secondary) 좌측
- 파괴적 액션: 빨간 버튼 + "정말 삭제하시겠습니까?" 확인. 되돌릴 수 없으면 명시
- 모바일: bottom sheet 패턴 권장 (전체 화면 모달 대신). 드래그로 닫기 지원
- 모달 안에 모달 금지. 2단계 확인이 필요하면 인라인 확인 UI 사용
- `aria-modal="true"` + `role="dialog"` + `aria-labelledby`로 제목 연결

## 리스트/테이블

### 규칙
- 테이블: 데스크톱 전용. 모바일에서는 카드 리스트로 전환
- 테이블 헤더: sticky, 정렬 가능 컬럼은 정렬 아이콘 + `aria-sort` 속성
- 긴 리스트(50+): 가상 스크롤 또는 페이지네이션. 무한 스크롤 시 "맨 위로" 버튼 필수
- 리스트 항목: 전체 행 클릭 가능하게. 작은 텍스트 링크만 있으면 터치 불편
- 빈 검색 결과: "검색어를 변경해 보세요" + 초기화 버튼

## 정보 구조

### 규칙
- 고급 옵션: accordion 또는 `<details>`. 기본 닫힘 상태
- 단계별 프로세스: stepper로 현재 위치 + 남은 단계 표시. 3-5단계 적정
- 긴 폼: fieldset + legend로 그룹 분리. 한 화면 15개 이상 필드 금지
