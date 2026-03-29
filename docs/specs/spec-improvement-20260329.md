# Lumio Spec Improvement

## 1. Document Info
- Title: `spec-improvement-20260329`
- Related Spec: `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`
- Previous Spec: `/Users/heedam/develop/Lumio/docs/specs/spec-improvement-20260328.md`
- Version: `v0.1.0`
- Author: `heedam-hwang`
- Date: `2026.03.29`

## 2. Detailed Improvements
### 2.1 Provide Book Deletion on the Book List Screen
- As-is
  - The book list screen does not provide a book deletion action.
  - The expected handling of related data during deletion is not defined.
- To-be
  - Add a `"Delete Book"` action to the option menu on each book card in the book list screen.
  - Present `"Delete Book"` as a destructive action and show a confirmation alert that includes the book title when tapped.
  - When deletion is confirmed, delete the selected book together with its related page, sentence, and word data.
  - After deletion, the book list should refresh immediately, and canceling should leave all data unchanged.

## 3. UI / UX Updates
### 3.1 Book Card More Menu and Delete Confirmation
- `"Delete Book"` should appear as a destructive action that is clearly separated from other book options.
- The confirmation alert should clearly distinguish between cancel and delete actions.
- After deleting the last remaining book, the home empty state should appear again.

## 4. Validation Plan
- Build checks: iOS app build succeeds
- Test scope: delete menu visibility, delete confirmation alert, cancel behavior, related data deletion on confirm, empty state after deleting the last book

## 5. Change Log
- `2026.03.29`: Added the requirement for book deletion support
