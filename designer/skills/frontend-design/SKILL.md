---
name: frontend-design
description: Use this skill when building frontend UI components, pages, or layouts. Provides design patterns, component composition guidelines, and CSS/Tailwind best practices.
---

# Frontend Design Skill

프론트엔드 UI 구축 시 디자인 패턴과 컴포넌트 구성 가이드.

## When to Activate

- 새로운 UI 컴포넌트 생성
- 페이지 레이아웃 설계
- CSS/Tailwind 스타일링 작업
- 컴포넌트 리팩토링

## Component Design Patterns

### Compound Components
```tsx
<Select>
  <Select.Trigger>선택하세요</Select.Trigger>
  <Select.Content>
    <Select.Item value="1">옵션 1</Select.Item>
    <Select.Item value="2">옵션 2</Select.Item>
  </Select.Content>
</Select>
```

### Variant Pattern (cva/class-variance-authority)
```tsx
const button = cva("inline-flex items-center rounded-md font-medium", {
  variants: {
    intent: {
      primary: "bg-primary text-white hover:bg-primary/90",
      secondary: "bg-secondary text-secondary-foreground",
      ghost: "hover:bg-accent hover:text-accent-foreground",
    },
    size: {
      sm: "h-8 px-3 text-sm",
      md: "h-10 px-4 text-base",
      lg: "h-12 px-6 text-lg",
    },
  },
  defaultVariants: { intent: "primary", size: "md" },
});
```

### Layout Composition
```tsx
// 페이지 레벨 레이아웃
<div className="min-h-screen flex flex-col">
  <Header />
  <main className="flex-1 container mx-auto px-4 py-8">
    <Outlet />
  </main>
  <Footer />
</div>
```

## Tailwind Best Practices

1. **유틸리티 순서**: layout → sizing → spacing → typography → colors → effects
2. **@apply 최소화**: 컴포넌트 추상화는 React 컴포넌트로
3. **임의값 최소화**: `text-[15px]` 대신 `text-sm` 또는 디자인 토큰 확장
4. **다크 모드**: `dark:` 접두사로 일관된 다크 모드 지원
