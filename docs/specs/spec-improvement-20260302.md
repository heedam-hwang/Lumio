# Lumio Spec Improvement Proposal

## 1. Document Info
- Title: `spec-improvement-20260302`
- Related Spec: `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`
- Version: `v0.1.0`
- Author: `heedam-hwang`
- Date: `2026.03.02`

## 2. Feature Improvements
### 2.1 Sentence/Word Extraction
- As-is
  - Sentences and words are extracted separately when a page is uploaded.
  - Sentence extraction is split by line breaks.
  - All words on the page are extracted at once.
  - The original image is displayed at full size after upload.
- To-be
  - After upload, generate sentence-based text from the full page text, ordered by sentence number, and show each row as `number button + sentence text`.
  - Do not split by line breaks. Use natural sentence boundaries, mainly by period (`.`).
  - Tapping a sentence number button opens a "Sentence View" modal.
  - Tapping a specific word inside a sentence opens a "Word View" modal (remove the previous full-word extraction button list).
  - If a word is saved to vocabulary, keep that word highlighted with a yellow background.
  - Keep the original image small so it fits on the same row as title/time, and show an enlarged preview when tapped.
  
### 2.2 Word Half Modal
- As-is: Pronunciation and example sentence are shown.
- To-be: Remove pronunciation and example sentence, and show meaning only.

### 2.3 Word Half Modal Bookmarking
- Keep only meaning (same rationale: pronunciation/example are not meaningful in this flow).
- When save via bookmark button succeeds, switch to the filled bookmark icon.
- When the modal opens for an already saved word, show the filled bookmark icon by default.

### 2.4 Other Page Detail Screen Updates
- Add a pencil button next to the page title so users can edit the page name.
- After renaming, show the updated page name when returning to the home screen.

### 2.5 Vocabulary Screen
- Remove pronunciation display.
- Change the listen button to an icon button placed next to the word.
- Add a remove-bookmark button in place of the previous listen button position.

## 3. UI Improvements
### 3.1 Floating Button Action
- Make the Camera/Photo Library menu anchored to the floating button.
- Fix the camera permission error by adding the `NSCameraUsageDescription` key in `Info.plist`.

### 3.2 Save Page Modal
- Provide a text field so users can enter a page name immediately, and explicitly mark it as optional.

## 4. Validation Plan
- Build checks: Build succeeds.
- Test scope: Unit tests pass.
