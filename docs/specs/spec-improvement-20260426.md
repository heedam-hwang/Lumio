# Lumio Spec Improvement

## 1. Document Info
- Title: `spec-improvement-20260426`
- Related Spec: `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`
- Previous Spec: `/Users/heedam/develop/Lumio/docs/specs/spec-improvement-20260329.md`
- Version: `v0.1.0`
- Author: `heedam-hwang`
- Date: `2026.04.26`

## 2. Detailed Improvements
### 2.1 Add a Dedicated Word Search Tab
- As-is
  - Users can currently look up a word only after opening a page detail screen and tapping a detected word from a screenshot.
  - When a page contains only one or two unfamiliar words, taking a screenshot and entering the OCR flow is unnecessarily heavy.
- To-be
  - Add a new `Word Search` tab to the main tab bar.
  - Users can type an English word directly and request the same lookup result currently provided from screenshot-based word lookup.
  - The result must show Korean meaning and pronunciation access consistent with the existing word lookup flow.

### 2.2 Keep the Latest 30 Recent Word Lookups
- As-is
  - The app does not preserve a dedicated history for manual word lookups.
- To-be
  - Persist the latest 30 manual word lookups with SwiftData.
  - If the same word is searched again, update the existing record and move it to the top instead of creating a duplicate.
  - Provide a `clear` action to remove the recent lookup list.
  - Provide an item-level delete action for each recent lookup row.
  - Provide an item-level `Edit Meaning` action for each recent lookup row.

### 2.3 Support Vocabulary Save and Cross-Screen Highlight Consistency
- As-is
  - Screenshot-based word lookup can save words to the vocabulary list, and saved words are highlighted in page detail.
  - Manual word search does not yet exist, so it cannot participate in the same saved-word flow.
- To-be
  - The current manual lookup result can be saved to the vocabulary list using the existing `SavedVocabulary` model.
  - Once saved, the same word must continue to appear highlighted in screenshot/page-detail word lookup using the existing yellow saved-word highlight.

### 2.4 Provide an External Web Dictionary Link
- As-is
  - Users only see the in-app translation result, even when they want to cross-check the meaning against an external source.
- To-be
  - Add an action that opens the searched word in the NAVER English Dictionary search page.
  - The link must be generated from the current word and opened with the system URL handling flow.

### 2.5 Allow Users to Correct Meanings Manually
- As-is
  - If the translated meaning feels incorrect, users cannot adjust it inside the app.
- To-be
  - Add an `Edit Meaning` action to the current manual lookup result.
  - Add an `Edit Meaning` action to each recent lookup row.
  - Add an `Edit Meaning` action to each saved vocabulary row.
  - The alert shown from current result, recent lookup, and vocabulary must use the same title, copy, input field, and save/cancel actions.
  - The edited meaning is treated as a user override and must be reflected immediately in:
    - the current lookup result
    - the recent lookup history entry
    - the saved vocabulary entry for the same word, if it exists
  - On future lookups of the same word, the user-edited meaning should be shown instead of the raw machine-translated value.

## 3. UI / UX Updates
### 3.1 Main Tab Layout
- The app should expose three primary tabs: `Home`, `Word Search`, and `Vocabulary`.
- `Word Search` should be reachable without navigating through a book or page flow.

### 3.2 Word Search Screen Structure
- The screen should contain:
  - a text field for English word input
  - a search action
  - a current result card
  - a recent lookup section with a `clear` button
- The current result card should show `Listen`, `Save to Vocabulary`, `Open Web Dictionary`, and `Edit Meaning` actions with clear labels.

### 3.3 Recent Lookup Behavior
- Recent lookup items should show the word, the currently stored meaning, and the last viewed time.
- Tapping a recent lookup item should reopen it as the current result without creating duplicate history rows.
- Saved words should remain visually distinguishable in the recent lookup list.
- Each recent lookup item should expose separate actions for save, edit meaning, and delete.

### 3.4 Shared Meaning Edit Experience
- The meaning edit interaction should be visually and behaviorally identical across current result, recent lookup, and vocabulary.
- Vocabulary rows should allow direct meaning correction without leaving the vocabulary screen.

## 4. Validation Plan
- Build checks: iOS app build succeeds
- Test scope:
  - `Word Search` tab appears in the tab bar and opens correctly
  - entering a word shows meaning and pronunciation actions
  - recent lookup history persists and keeps at most 30 items
  - repeated lookup of the same word moves the existing record to the top
  - `clear` removes the recent lookup list
  - item-level delete removes only the selected recent lookup row
  - `Open Web Dictionary` opens the NAVER English Dictionary search URL for the current word
  - `Edit Meaning` from current result, recent lookup, and vocabulary uses the same alert UI
  - `Edit Meaning` updates the current result, the recent lookup record, and the saved vocabulary record when present
  - saved words still appear highlighted in page detail lookup

## 5. Change Log
- `2026.04.26`: Added the dedicated `Word Search` tab, recent manual lookup history, NAVER dictionary link, and user-editable meaning override requirements
