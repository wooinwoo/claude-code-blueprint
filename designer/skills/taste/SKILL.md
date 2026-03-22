---
name: taste
description: Use this skill to ensure high design quality and avoid generic AI aesthetics. Provides opinionated design guidance for distinctive, memorable interfaces.
---

# Taste Skill — 디자인 판단 기준

> 안티패턴 목록은 `rules/anti-ai-slop.md` 참조. 이 스킬은 "왜 나쁜지"가 아닌 "어떻게 좋게 만드는지"에 집중.

## 시각적 위계 체크리스트

생성한 UI를 이 순서로 점검:

1. **1초 테스트** — 페이지를 1초만 보고 가장 중요한 요소가 무엇인지 즉시 파악 가능한가?
   - 방법: 하나의 primary CTA, 하나의 메인 heading, 나머지는 서브
   - BAD: 모든 요소가 동일 크기/색상 → 시선이 분산됨
   - GOOD: heading (`text-4xl font-bold`) → subheading (`text-lg text-on-surface-variant`) → body (`text-base`) 명확한 단계

2. **squint 테스트** — 눈을 반쯤 감고 봐도 레이아웃 구조가 보이는가?
   - 큰 색상 블록, 여백, 그룹핑이 명확해야 함
   - 모든 카드가 같은 크기/색이면 정보 위계가 없는 것 → 실패

3. **브랜드 테스트** — 로고를 가려도 우리 제품인지 알 수 있는가?
   - 색상 팔레트, 타이포, spacing 리듬이 일관적인지
   - 어떤 SaaS에든 붙여넣을 수 있는 느낌이면 실패

## 색상 판단

### 규칙
- 악센트 컬러: **최대 2개**. primary + secondary(또는 error). 3개 이상이면 산만함
- 배경에 pure white(`#fff`) 대신 미세한 톤 부여: `oklch(0.985 0.005 hue)` 또는 `gray-50`
- 텍스트에 pure black(`#000`) 대신: `oklch(0.15 0.01 hue)` 또는 `gray-900`. 대비가 너무 강하면 눈이 피로
- 그라데이션: 같은 hue 계열에서 명도/채도만 변경. 보라→파랑 "AI 그라데이션" 금지
- 의미 색상: error=red 계열, success=green 계열, warning=amber 계열. 관습을 깨지 말 것
- 색상 수 자가 진단: UI에서 사용한 고유 색상이 8개 초과면 줄여라 (gray 스케일 제외)

### 다크 모드 주의
- 라이트 모드 색상을 단순 반전하지 말 것. 채도를 낮추고 명도를 조정
- 다크 배경에 pure white 텍스트 금지 → `gray-100` 또는 `oklch(0.93 0.005 hue)`
- elevation을 그림자 대신 surface 밝기로 표현 (Material Design 3 방식)

## 타이포그래피 판단

### 규칙
- 폰트: **최대 2종** (heading + body). 1종으로 weight만 구분하는 것 추천
- heading과 body의 시각적 대비: weight 차이(`bold` vs `regular`) 또는 size 차이(1.5배 이상). 둘 다 없으면 위계 실패
- line-height: 본문 `1.5`-`1.75`, heading `1.1`-`1.3`. heading에 본문 line-height 쓰면 허전함
- 문단 최대 너비: `60`-`75ch` (`max-w-prose`). 한 줄이 80자 이상이면 가독성 급락
- letter-spacing: heading에만 미세 음수(`-0.01em` ~ `-0.02em`), 본문은 기본값 유지
- 한글 폰트 주의: `Pretendard`, `Noto Sans KR` 등 본문용 고딕 추천. 세리프는 heading 한정

### 크기 스케일
- 일관된 스케일 사용: Tailwind 기본(`text-sm/base/lg/xl/2xl/3xl/4xl`) 또는 커스텀 modular scale
- 본문 `text-base`(16px) 미만 금지 (caption/label 제외)
- heading 4단계 이상 구분 금지: `h1`-`h3`면 충분. `h4`-`h6`까지 스타일링하면 과잉

## 여백 판단

### 규칙
- **근접 법칙**: 인접 요소 간 여백 < 그룹 간 여백. 이 규칙을 어기면 관계가 모호해짐
  - 같은 그룹 내: `gap-2` ~ `gap-4`
  - 그룹 간: `gap-8` ~ `gap-16`
  - 섹션 간: `py-16` ~ `py-24`
- 요소 내부 padding은 외부 gap보다 작거나 같아야 함. 카드 내부 `p-8`인데 카드 간 `gap-4`면 어색
- 여백은 4px 단위 배수로 통일 (`gap-1`=4px, `gap-2`=8px...). 임의 값(`gap-[7px]`) 자제
- 빈 공간을 두려워하지 말 것. 여백이 넉넉한 게 빽빽한 것보다 항상 나음

### 컨테이너
- 최대 너비: `max-w-7xl`(1280px) 또는 `max-w-6xl`(1152px). 전체 너비 레이아웃은 대시보드에서만
- 좌우 패딩: 모바일 `px-4`, 태블릿 `px-6`, 데스크톱 `px-8`
- 콘텐츠 중앙 정렬: `mx-auto` 필수

## 레이아웃 판단

### 규칙
- 카드 그리드: 한 행에 최대 4개. 5개 이상이면 스캔이 어려움
- 카드 높이: 같은 행의 카드는 동일 높이 (`items-stretch` 또는 `grid`). 들쭉날쭉 금지
- hero 섹션: 화면 높이의 70-100vh. 스크롤 유도 요소(화살표 또는 다음 섹션 미리보기) 포함
- sidebar: 너비 고정 (`w-64` ~ `w-80`). 콘텐츠 영역이 sidebar보다 좁아지면 안 됨
- z-index 관리: `z-10`(드롭다운) < `z-20`(sticky header) < `z-30`(모달 오버레이) < `z-40`(모달) < `z-50`(토스트)

## 아이콘/이미지

### 규칙
- 아이콘 세트: 하나의 라이브러리에서 통일. Lucide + Heroicons 혼용 금지
- 아이콘 크기: `w-4 h-4`(인라인), `w-5 h-5`(버튼 내부), `w-6 h-6`(네비게이션), `w-8 h-8`(feature)
- 장식용 아이콘: `aria-hidden="true"`. 의미 있는 아이콘: `aria-label` 또는 `sr-only` 텍스트
- 이미지: `aspect-ratio` 고정으로 로딩 시 레이아웃 시프트 방지. `object-cover` 기본
- placeholder 이미지: 단색 배경 + 아이콘 조합. 외부 placeholder 서비스 URL 금지

## "AI스러움" 자가 진단

Claude가 생성한 UI를 스스로 점검하는 질문:

1. 이 컴포넌트를 3번 다시 생성하면 매번 비슷하게 나오는가? → 비슷하면 generic, 변형을 시도
2. 이 레이아웃이 Tailwind UI / shadcn 예시와 거의 동일한가? → 동일하면 복사 수준, 차별화 필요
3. 모든 카드/섹션이 동일한 패턴(아이콘 + 제목 + 설명)인가? → 단조로움, 크기/배치 변화 필요
4. "Unlock", "Seamlessly", "Elevate", "Empower" 같은 단어를 쓰고 있는가? → AI slop, 구체적 동사로 교체
5. 히어로 섹션이 좌측 텍스트 + 우측 이미지 2컬럼인가? → 가장 흔한 AI 패턴, 대안 고려
6. 모든 섹션에 `py-24`가 동일하게 적용되어 있는가? → 리듬감 없음, 중요도에 따라 여백 차등
7. 버튼이 모두 `rounded-full`에 그라데이션인가? → AI 기본값, `rounded-lg` + 단색이 더 세련됨
8. feature 섹션이 3열 × 2행 6개 카드 그리드인가? → AI가 가장 좋아하는 패턴, 다른 레이아웃 시도

→ **3개 이상 해당하면 다시 만들어라.**

## 판단이 애매할 때 기본값

결정을 못 내릴 때 이 쪽으로 기울여라:
- 화려함 vs 단순함 → **단순함**
- 애니메이션 많이 vs 적게 → **적게**
- 색상 다양 vs 제한 → **제한**
- 여백 좁게 vs 넓게 → **넓게**
- 장식 요소 추가 vs 생략 → **생략**
- 커스텀 컴포넌트 vs 네이티브 HTML → **네이티브 우선**
- 트렌디 vs 클래식 → **클래식**
