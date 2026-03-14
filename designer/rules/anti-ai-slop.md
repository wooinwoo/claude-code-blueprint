# AI 슬롭 방지 규칙

AI가 생성하는 전형적인 "AI스러운" 디자인/코드를 방지. 독창적이고 의도적인 디자인 추구.

## 1. 컬러 [CRITICAL]

```tsx
// BAD - AI가 자주 쓰는 무난한 조합
className="bg-blue-500 text-white"           // 기본 파랑
className="bg-gradient-to-r from-blue-500 to-purple-500"  // 블루-퍼플 그라데이션

// GOOD - 브랜드/의도에 맞는 색상
className="bg-brand-primary text-brand-on-primary"
className="bg-[#1a1a2e] text-[#e0e0e0]"     // 프로젝트 팔레트에서 선택
```

## 2. 레이아웃 [HIGH]

```tsx
// BAD - AI 전형적 3-카드 레이아웃
<div className="grid grid-cols-3 gap-6">
  <Card icon="🚀" title="Fast" />
  <Card icon="🛡️" title="Secure" />
  <Card icon="⚡" title="Simple" />
</div>

// GOOD - 콘텐츠에 맞는 레이아웃
<div className="grid grid-cols-[2fr_1fr] gap-8">
  <FeatureShowcase />          {/* 핵심을 크게 */}
  <FeatureList items={rest} /> {/* 나머지는 리스트 */}
</div>
```

## 3. 타이포그래피 [HIGH]

```tsx
// BAD - AI 기본
className="text-4xl font-bold text-center mb-4"  // 항상 이 패턴

// GOOD - 계층적, 의도적
className="text-[2.5rem] font-medium tracking-tight leading-[1.1]"
```

## 4. 아이콘/이모지 [MEDIUM]

- 🚀⚡🛡️✨ 등 AI 전형 이모지 사용 자제
- 프로젝트 아이콘 시스템 사용 (Lucide, Heroicons 등)
- 이모지 대신 실제 아이콘 SVG 사용

## 5. 카피라이팅 [MEDIUM]

```
BAD:
"Revolutionize your workflow"
"Seamlessly integrate"
"Unlock the power of"

GOOD:
구체적이고 제품에 맞는 카피 작성
"3분 안에 첫 API 호출", "팀 전체의 디자인 리뷰 시간 50% 단축"
```
