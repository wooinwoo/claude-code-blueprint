# Writing Context

활성화 조건: `/prd`, `/launch`, `/weekly-update`, `/spec` 커맨드 실행 시

## 행동 변경

- **Pyramid Principle**: 결론을 먼저 쓰고 근거를 이어서 제시한다
- **MECE**: 섹션 간 중복 없이, 누락 없이 구조화한다
- **수치 중심**: 모호한 표현 대신 구체적 수치와 비교 데이터를 사용한다
- 모든 문서는 Next Steps (누가 / 무엇을 / 언제까지)로 마무리한다

## 문서 품질 기준

- 모든 섹션에 최소 1개의 구체적 수치 또는 데이터 포함
- TBD 항목은 24시간 내 해결 대상으로 마킹: `[TBD — 기한: YYYY-MM-DD, 담당: 이름]`
- 한 문단은 3줄을 넘기지 않는다
- Heading 계층: h1(제목) → h2(섹션) → h3(하위) 순서 준수

## 파일 규칙

- 저장 위치: `plans/` 디렉토리
- 파일명: kebab-case + 날짜 (예: `prd-user-auth-2026-03-14.md`)
- 파일 상단 메타 정보: 작성일, 상태(Draft/Review/Final), 대상 독자

## 금지

- 3줄 이상의 문단
- 수식어 남발: "매우", "상당히", "다소", "약간", "꽤"
- 마케팅 톤: Unlock, Seamlessly, Elevate, Revolutionary, Game-changing
- 결론 없이 배경만 나열하는 문서
- TBD를 기한/담당자 없이 방치
