---
name: excalidraw-diagram
description: Use this skill to create architectural diagrams, user flows, and wireframes using Excalidraw JSON format.
---

# Excalidraw Diagram Skill

Excalidraw JSON 포맷으로 아키텍처 다이어그램, 사용자 흐름, 와이어프레임 생성.

## When to Activate

- 아키텍처/시스템 다이어그램 필요 시
- 사용자 흐름(user flow) 시각화
- 간단한 와이어프레임 작성
- 팀 소통을 위한 다이어그램

## Excalidraw Element Structure

```json
{
  "type": "excalidraw",
  "version": 2,
  "elements": [
    {
      "type": "rectangle",
      "x": 100, "y": 100,
      "width": 200, "height": 80,
      "strokeColor": "#1e1e1e",
      "backgroundColor": "#a5d8ff",
      "fillStyle": "solid",
      "roundness": { "type": 3, "value": 8 }
    },
    {
      "type": "text",
      "x": 130, "y": 130,
      "text": "Component",
      "fontSize": 16,
      "fontFamily": 1
    },
    {
      "type": "arrow",
      "x": 300, "y": 140,
      "width": 100, "height": 0,
      "strokeColor": "#1e1e1e"
    }
  ]
}
```

## Diagram Types

### User Flow
- 시작(원) → 화면(사각형) → 분기(다이아몬드) → 끝(원)
- 좌→우 또는 상→하 방향
- 각 화면에 주요 액션 표시

### Architecture Diagram
- 계층별 배치 (Client → API → Service → DB)
- 색상으로 도메인 구분
- 화살표로 데이터 흐름 표시

### Wireframe
- 낮은 충실도 (low-fi): 사각형 + 텍스트만
- 실제 비율 유지 (375x812 모바일, 1280x800 데스크톱)

## Output
- `.excalidraw` 파일로 저장 (JSON 포맷)
- Excalidraw 앱에서 바로 열기 가능
