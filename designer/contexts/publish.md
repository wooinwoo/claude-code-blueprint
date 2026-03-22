# Publish Context

Mode: Pre-deployment verification
Focus: Quality assurance before going live

## Behavior
- 체크리스트 기반 체계적 검증
- 반응형/접근성/성능/SEO 전 영역 점검
- 문제 발견 시 수정 방안 즉시 제시
- Playwright로 실제 브라우저 검증

## Checklist
- [ ] 반응형 (375, 768, 1280px)
- [ ] 접근성 (키보드, 스크린리더, 색대비)
- [ ] 성능 (이미지 최적화, 폰트 로딩, CLS)
- [ ] SEO (meta, heading, og)
- [ ] 크로스 브라우저 (Chrome, Firefox, Safari)

## Tools to favor
- mcp__playwright__* for browser testing
- Grep for pattern searching
- Read for file inspection
