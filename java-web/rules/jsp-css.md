# JSP & CSS Rules

## JSP

### 필수 규칙

- **스크립틀릿 금지** — `<% %>`, `<%= %>` 사용 금지. JSTL + EL로 대체.
- **XSS 방지** — 모든 동적 출력에 `<c:out>` 또는 `fn:escapeXml()` 사용.
- **인클루드** — 공통 레이아웃은 `inc/` 디렉토리의 컴포넌트 재사용.

```jsp
<%-- BAD --%>
<%= memberName %>
<% if (list.size() > 0) { %>

<%-- GOOD --%>
<c:out value="${memberName}" />
<c:if test="${not empty list}">
```

### 레이아웃 구조

```jsp
<%@ include file="/inc/inc_layout_header.jsp" %>

<div class="content-area">
  <%-- 페이지 콘텐츠 --%>
</div>

<%@ include file="/inc/inc_layout_footer.jsp" %>
```

### EL (Expression Language)

- `${requestScope.xxx}` 또는 `${xxx}` — Controller에서 전달한 Model 속성
- `${param.xxx}` — 쿼리 파라미터 (반드시 이스케이프)
- `${sessionScope.xxx}` — 세션 속성

### JSTL 태그

```jsp
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
```

## CSS

### 파일 구조 (PMS 프로젝트)

| 파일 | 역할 |
|------|------|
| `css/pms/ui.css` | 핵심 UI 컴포넌트 (헤더, 테이블, 폼, 버튼) |
| `css/pms/style.css` | 레이아웃, 카드, 배지, 브레드크럼 |
| `css/pms/table-sticky.css` | 테이블 고정 헤더/컬럼 |
| `css/pms/shadcn.css` | shadcn/ui 컴포넌트 |
| `css/pms/tailwind-popup.css` | 팝업 Tailwind 보정 |

### Tailwind + 커스텀 CSS 공존 규칙

- **Tailwind 우선**: 가능하면 Tailwind 유틸리티 클래스 사용
- **커스텀 CSS**: Tailwind로 표현 불가능한 복잡한 스타일만 `css/pms/` 파일에 작성
- **충돌 방지**: 같은 속성을 Tailwind 클래스와 커스텀 CSS 양쪽에서 정의하지 않기
- **인라인 스타일 금지**: JSP 내 `style=""` 대신 클래스 사용

### 네이밍

- CSS 클래스: kebab-case (`pms-table-header`, `card-body`)
- Tailwind: 공식 유틸리티 (`flex`, `gap-4`, `text-sm`)
- BEM 불필요 — Tailwind가 주도, 커스텀은 컴포넌트 단위 접두사 (`pms-`)

### 테이블 스타일링

기존 패턴 준수:
```html
<div class="pms-table-wrap">
  <table class="pms-table">
    <thead>
      <tr><th>컬럼</th></tr>
    </thead>
    <tbody>
      <c:forEach items="${list}" var="item">
        <tr><td><c:out value="${item.name}" /></td></tr>
      </c:forEach>
    </tbody>
  </table>
</div>
```
