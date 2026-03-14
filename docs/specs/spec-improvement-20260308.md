# Lumio Spec Improvement

## 1. Document Info
- Title: `spec-improvement-20260308`
- Related Spec: `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`
- Previous Spec: `/Users/heedam/develop/Lumio/docs/specs/spec-improvement-20260307.md`
- Version: `v0.1.0`
- Author: `heedam-hwang`
- Date: `2026.03.08`

## 2. Detailed Improvements
### 2.1 Add Page List Reordering
- Reordering through a drag handle must be available only in edit mode
- Drag interactions must be disabled when edit mode is not active
- The changed page order must persist when the user re-enters the page list later

### 2.2 Add Sentence Reordering on the Page Detail Screen
- Reordering through a drag handle must be available only in edit mode
- Drag interactions must be disabled when edit mode is not active
- Sentence numbering must be recalculated after reordering
- The changed sentence order must persist when the user re-enters the page
- If the first sentence changes, the page list screen must show the new first sentence

### 2.3 Keep the input text while saving edited sentences text
- as-is: input text disappears once the save button is clicked
- to-be: keep the input text until the save is complete and modal is closed

## 3. Validation Plan
- Build checks: build succeeds
- Test scope: drag reorder interaction, persistence, numbering

## 4. Change Log
- `2026.03.08`: Split reorder-related requirements out of `spec-improvement-20260307.md`
