# Lumio Spec Improvement

## 1. Document Info
- Title: `spec-improvement-20260307`
- Related Spec: `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`
- Version: `v0.1.0`
- Author: `heedam-hwang`
- Date: `2026.03.07`

## 2. Detailed Improvements
### 2.1 Edit Mode Behavior
- Provide a top `Edit` button on both the page list screen and the page detail screen
- When edit mode is not active, the screens should behave in browse/view-only mode
- Page rename, page delete, sentence edit, and sentence delete features are available only in edit mode
- Changes made in edit mode must persist after exiting edit mode

### 2.2 Add Page Delete Feature
- As-is
  - The page list screen currently provides a rename option through swipe actions
- To-be
  - Add an `Edit` button to the page list screen
  - Page deletion must be available only in edit mode
  - In edit mode, show the rename button next to the title
  - In edit mode, show the delete button next to the rename button
  - When the delete button is tapped, show a confirmation alert to verify user intent

### 2.3 Add Subtitle to the Page List
- As-is
  - The page list screen currently shows only the page title and created time
- To-be
  - Show the user-entered page title (or default title), the first text from the page, and the created time in three lines
  - The first text line should use the same font style as the date/time line

### 2.4 Add Sentence Editing on the Page Detail Screen
- As-is
  - Once sentence analysis is complete, there is no way to fix typos or truncated sentences
- To-be
  - Add an `Edit` button to the page detail screen
  - In edit mode, show an "Edit" button at the end of each sentence so the user can modify the sentence text
  - Apply sentence updates immediately after saving
  - If the first sentence changes, reflect that change on the page list screen as well
  - Allow saving an empty string, and treat blank-only input as deleting that sentence

### 2.5 Add Sentence Deletion on the Page Detail Screen
- In edit mode, show a delete button next to the edit button
- When the delete button is tapped, show a confirmation alert to verify user intent
- When a sentence is deleted, recalculate numbering automatically (e.g. if sentence 2 is deleted, sentence 3 becomes sentence 2)
- If the deleted sentence was the first sentence, the new first sentence must appear on the page list screen

## 3. UI / UX Updates
### 3.1 Screen Changes
- Screen: `Book list screen (home screen)`
- Update:
  - Change the layout from a list to a 2-column grid
  - Each grid item should show a book cover (user-uploaded if available, otherwise a default image), book title, and page count
  - Tapping a grid item should navigate to the page list
- Rationale:
  - The screen should feel closer to a real "book" experience by centering the layout around book covers

## 4. Validation Plan
- Build checks: iOS app build succeeds
  - [Example: ]
- Test scope: unit tests


## 5. Change Log
- `2026.03.07`: Initial draft created
- `2026.03.08`: Moved reorder-related requirements to `spec-improvement-20260308.md`
