# Java Web Conventions

Spring Boot + JSP + MyBatis 프로젝트 규칙.

## 아키텍처 계층

```
Controller (@Controller)  → 요청 매핑, 유효성 검사, Model 전달
    ↓
Service (@Service)        → 비즈니스 로직, 트랜잭션 관리
    ↓
Mapper (@Mapper)          → MyBatis SQL, DB 접근
```

- JSP에 비즈니스 로직 금지. 뷰 렌더링만.
- Controller에 DB 접근 금지. Service를 통해서만.
- Service 간 순환 의존 금지.

## MyBatis

### 파라미터 바인딩

```xml
<!-- GOOD: PreparedStatement 바인딩 -->
WHERE member_id = #{memberId}

<!-- BAD: SQL 인젝션 위험 -->
WHERE member_id = '${memberId}'
```

`${}` 허용 예외: ORDER BY 절 컬럼명 (서버에서 화이트리스트 검증 필수)

### 매퍼 작성

- `SELECT *` 금지 — 필요한 컬럼만 명시
- 목록 조회에 반드시 페이지네이션 (OFFSET/FETCH 또는 ROW_NUMBER)
- resultMap 사용 시 컬럼-필드 매핑 명시

## Spring Boot

### Controller

- `@GetMapping` / `@PostMapping` 명확히 구분
- POST 요청에 CSRF 토큰 검증
- 사용자 입력은 DTO로 받고 `@Valid`로 검증
- 민감한 데이터는 Model에 최소한만 전달

### 에러 처리

- `@ExceptionHandler`로 전역 예외 처리
- 사용자에게 내부 에러 상세 노출 금지
- 빈 catch 블록 금지 — 최소한 로그 기록

## Gradle

```bash
./gradlew classes       # 컴파일 확인
./gradlew bootRun       # 개발 서버 실행
./gradlew bootWar       # WAR 빌드
```
