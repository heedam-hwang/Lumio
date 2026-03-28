# Lumio Spec Improvement

## 1. Document Info
- Title: `spec-improvement-20260321`
- Related Spec: `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`
- Previous Spec: `/Users/heedam/develop/Lumio/docs/specs/spec-improvement-20260308.md`
- Version: `v0.1.0`
- Author: `heedam-hwang`
- Date: `2026.03.21`

## 2. Detailed Improvements
### 2.1 Add Page Upload Button on the Page List Screen
- As-is
  - 페이지 추가는 홈 화면에서만 가능해서, 특정 책의 페이지 리스트에 들어간 뒤에는 다시 홈으로 나가야 합니다.
- To-be
  - 페이지 리스트 화면에서도 업로드 버튼을 제공하고, 여기서 추가한 페이지는 현재 보고 있는 책에 바로 저장되도록 합니다.

### 2.2 Show Guidance When Device Sound Is Off
- As-is
  - `듣기` 버튼을 눌렀을 때 기기 소리가 꺼져 있으면 소리가 나지 않지만, 앱에서는 이유를 안내하지 않습니다.
- To-be
  - 소리를 들을 수 없는 상태라면 사용자에게 무음 모드나 볼륨을 확인하라는 안내를 보여주고, 재생 가능한 상태에서는 기존처럼 바로 재생합니다.

### 2.3 Separate Highlight States for Word Lookup Actions
- As-is
  - 단어 조회 화면에서 `듣기` 버튼과 저장 버튼이 너무 붙어 있어, 어느 버튼을 눌렀는지 구분되지 않고 둘 다 함께 하이라이트되는 것처럼 보입니다.
- To-be
  - 두 버튼의 간격과 탭 영역을 분리해서 각 버튼이 독립적으로 하이라이트되도록 수정합니다.

## 3. UI / UX Updates
### 3.1 Page List Screen Upload Flow
- 페이지 리스트에서도 업로드 버튼을 바로 찾을 수 있어야 하고, 기존 편집 버튼과 충돌하지 않아야 합니다.

### 3.2 Audio Guidance and Word Lookup Toolbar
- 소리 안내는 필요한 경우에만 보여주고, 단어 조회 툴바 버튼은 서로 명확히 구분되도록 배치합니다.

## 4. Validation Plan
- Build checks: iOS app build succeeds
- Test scope: 페이지 리스트에서 현재 책으로 페이지 추가, `듣기` 안내 노출, 단어 조회 버튼별 독립 하이라이트

## 5. Change Log
- `2026.03.21`: 문서 간결화 및 오늘 개선 항목 반영
