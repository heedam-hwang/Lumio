# Lumio Spec Improvement

## 1. Document Info
- Title: `spec-improvement-20260328`
- Related Spec: `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`
- Previous Spec: `/Users/heedam/develop/Lumio/docs/specs/spec-improvement-20260321.md`
- Version: `v0.1.0`
- Author: `heedam-hwang`
- Date: `2026.03.28`

## 2. Detailed Improvements
### 2.1 Refine the More Menu Button on the Book List Screen
- As-is
  - 책 목록 화면의 more menu 버튼이 원형 버튼 스타일로 표시되어 주변 UI 대비 강조가 과합니다.
  - plain 버튼으로 바꾸면 터치 영역이 줄어들 수 있어, 패딩 기준이 함께 정의되어 있지 않습니다.
- To-be
  - more menu 버튼은 원형 강조 스타일 대신 plain 버튼 스타일을 사용합니다.
  - 버튼의 탭 영역이 충분히 유지되도록 내부 패딩을 명시적으로 적용합니다.

### 2.2 Clean Up the Top Area of the Page List Screen
- As-is
  - 페이지 리스트 화면에서 첫 번째 페이지 위에도 divider가 노출되어 리스트 시작 지점이 불필요하게 구분됩니다.
  - 각 페이지 행의 시간 텍스트가 accent color로 강조되어 다른 정보보다 시각적 우선순위가 높습니다.
- To-be
  - 첫 번째 페이지 항목 위 divider는 제거하고, 두 번째 항목부터만 구분선이 보이도록 합니다.
  - 시간 텍스트는 accent color를 제거하고 일반 보조 정보 톤으로 표시합니다.

### 2.3 Align Page List Edit Actions with the Page Detail Screen
- As-is
  - 페이지 리스트 화면에서 edit 버튼을 누르면 pencil / trash bin 아이콘 버튼이 표시되어 의미를 해석해야 합니다.
  - 페이지 상세 화면과 액션 표현 방식이 달라 같은 작업이라도 화면마다 경험이 달라집니다.
- To-be
  - 페이지 리스트 화면의 edit 상태 액션은 페이지 상세 화면과 동일하게 `"이름 수정"` / `"삭제"` 텍스트 버튼으로 제공합니다.
  - 같은 작업은 두 화면에서 동일한 명칭과 우선순위로 보여주어 편집 경험을 통일합니다.

### 2.4 Simplify the Page Detail Screen Header Actions
- As-is
  - 페이지 상세 화면의 `"문장"` 섹션 헤더가 별도 정보 가치 없이 공간만 차지합니다.
  - 페이지 이름 수정 액션이 pencil 아이콘만으로 제공되어 기능을 바로 이해하기 어렵습니다.
- To-be
  - 페이지 상세 화면에서 `"문장"` 섹션 헤더는 제거하고 본문 콘텐츠에 바로 집중할 수 있게 합니다.
  - pencil 아이콘 대신 `"이름 수정"` 텍스트 버튼을 사용해 액션 의미를 명확히 드러냅니다.

### 2.5 Improve the Vocabulary Screen Header and Button Interaction
- As-is
  - 단어장 화면에 navigation title이 없어 현재 화면 맥락이 약합니다.
  - 북마크 버튼과 sound 버튼이 인접해 있어 한 번의 터치에서 동시에 눌린 것처럼 동작하는 문제가 있습니다.
- To-be
  - 단어장 화면에 navigationTitle을 추가해 화면 제목을 항상 표시합니다.
  - 북마크 버튼과 sound 버튼은 독립적으로 눌리도록 탭 영역과 제스처 충돌을 정리합니다.

### 2.6 Defer Vocabulary Deletion Until the User Leaves the Screen
- As-is
  - 단어장 화면에서 북마크를 해제하면 데이터가 즉시 삭제되어 사용자가 바로 되돌리기 어렵습니다.
  - 앱 종료나 백그라운드 이동 같은 화면 이탈 시점과 관계없이 즉시 저장이 반영됩니다.
- To-be
  - 북마크 해제 시에는 즉시 데이터 삭제를 수행하지 않고, 버튼의 선택 상태만 먼저 업데이트합니다.
  - 실제 삭제 반영은 사용자가 단어장 화면을 이탈할 때 수행합니다.
  - 화면 이탈에는 뒤로 가기, 다른 화면 이동, 앱 백그라운드 전환, 앱 종료 상황을 포함합니다.
  - 사용자가 화면을 떠나기 전 다시 북마크를 활성화하면 삭제 예정 상태를 취소할 수 있어야 합니다.

## 3. UI / UX Updates
### 3.1 Book List and Page List Controls
- 책 목록 화면의 more menu 버튼은 시각적 강조를 줄이되 탭 가능 영역은 유지해야 합니다.
- 페이지 리스트 화면은 첫 행 상단이 깔끔하게 시작되어야 하며, 편집 액션은 아이콘 해석 없이 바로 이해할 수 있어야 합니다.

### 3.2 Page Detail Readability
- 페이지 상세 화면은 불필요한 섹션 헤더를 제거하고, 이름 수정 액션을 텍스트로 명확히 노출해야 합니다.

### 3.3 Vocabulary Interaction and Persistence
- 단어장 화면은 navigation title로 현재 위치를 알려야 합니다.
- 북마크와 sound 버튼은 동시에 눌리지 않도록 독립적인 터치 피드백과 동작을 보장해야 합니다.
- 북마크 해제는 즉시 삭제가 아닌 지연 반영 방식으로 처리해 사용자가 화면을 떠나기 전 상태를 다시 바꿀 수 있어야 합니다.

## 4. Validation Plan
- Build checks: iOS app build succeeds
- Test scope: 책 목록 more menu 버튼 스타일 및 패딩, 페이지 리스트 divider 및 시간 텍스트 표시, 페이지 리스트/상세 편집 버튼 문구 통일, 단어장 navigation title 및 버튼 독립 탭, 단어장 북마크 해제 후 화면 이탈 시 삭제 반영

## 5. Change Log
- `2026.03.28`: 책 목록, 페이지 리스트, 페이지 상세, 단어장 화면 개선 요구사항 추가
