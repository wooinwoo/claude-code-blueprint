# 반응형 디자인 규칙

모바일 퍼스트 접근. 모든 UI는 375px~1920px에서 정상 동작해야 함.

## 1. 모바일 퍼스트 [CRITICAL]

기본 스타일은 모바일, 큰 화면으로 확장.

```tsx
// BAD - 데스크톱 퍼스트
className="flex-row md:flex-col"      // 모바일에서 가로? 이상함
className="w-[1200px] md:w-full"      // 모바일 오버플로우

// GOOD - 모바일 퍼스트
className="flex-col md:flex-row"      // 모바일: 세로, 태블릿+: 가로
className="w-full max-w-[1200px]"     // 항상 화면 내
```

## 2. 고정 크기 금지 [HIGH]

```tsx
// BAD
className="w-[500px] h-[300px]"       // 작은 화면에서 잘림
style={{ width: '800px' }}

// GOOD
className="w-full max-w-lg"           // 유연한 크기
className="aspect-video w-full"       // 비율 유지
```

## 3. 터치 타겟 [HIGH]

모바일 터치 타겟 최소 44x44px (WCAG 2.5.5).

```tsx
// BAD
className="p-1 text-xs"              // 터치하기 너무 작음

// GOOD
className="min-h-[44px] min-w-[44px] p-3"  // 충분한 터치 영역
```

## 4. 폰트 크기 [MEDIUM]

모바일에서 최소 16px (body). 입력 필드 16px 미만 시 iOS 자동 확대.

```tsx
// BAD
<input className="text-sm" />         // 14px → iOS 자동 줌

// GOOD
<input className="text-base" />       // 16px → 줌 방지
```

## 5. 이미지/미디어 [MEDIUM]

```tsx
// BAD
<img src="hero.jpg" width="1920" />   // 모바일에서 불필요한 대용량

// GOOD
<img
  src="hero.jpg"
  srcSet="hero-400.jpg 400w, hero-800.jpg 800w, hero-1920.jpg 1920w"
  sizes="100vw"
  className="w-full h-auto"
  loading="lazy"
/>
```
