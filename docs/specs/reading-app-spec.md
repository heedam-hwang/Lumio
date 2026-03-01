# Reading App Spec

## 1. Document Info
- Project Name: Lumio
- Version: v1.0.0
- Author: heedam-hwang
- Last Updated: 2026.03.01

## 2. Goal
- Core problem this app solves: When non-native English readers encounter unfamiliar words while reading English books, they have to leave the reading flow to search a dictionary. That lookup breaks concentration. Users need a fast and easy way to understand words without disrupting reading.
- Target users: Anyone reading books written in English.
- Core value for users: Users can stay focused on the book, understand words in context, and improve the overall reading experience.

## 3. Functional Requirements
### 3.1 Book Page Management
- [ ] Capture or upload photos of original book pages (page title can be edited by user)
- [ ] Group and organize uploaded pages by book (book title can be entered by user)
- [ ] View book list and pages registered under each book

### 3.2 Reader Experience
- [ ] Tap-to-select each sentence
- [ ] Display sentence number (order within the page) before each sentence
- [ ] Tap-to-select each word

### 3.3 Vocabulary & Learning
- [ ] On sentence tap, provide sentence translation and sentence TTS playback
- [ ] On word tap, provide meaning/example, pronunciation notation, and word TTS playback
- [ ] Provide word save feature and saved vocabulary list view

## 4. Non-Functional Requirements
### 4.1 Accessibility
- Dynamic Type support: Y
- VoiceOver support: Y

### 4.2 Reliability
- Offline behavior scope: View uploaded book pages; if sentence/word data has already been looked up, provide translation/meaning on tap; provide saved vocabulary list.
- Recovery strategy on errors: Show an alert and ask user to retry.

### 4.3 Security & Privacy
- Collected data: User-captured book photos and sentence/word translation/meaning data
- Storage location: On-device
- Privacy policy considerations: TBU

## 5. SwiftData Model Draft
### 5.1 Entities
- Book
- Page
- SentenceItem
- VocabularyItem
- SavedVocabularies

### 5.2 Entity Fields (Example)
```txt
Book
- id: UUID
- title: String
- language: String
- pages: [Page]

Page
- id: UUID
- book: Book
- title: String?
- sentences: [SentenceItem]
- vocabularies: [VocabularyItem]

SentenceItem
- book: Book
- page: Page
- meaning: String?

VocabularyItem
- word: String
- meaning: String?
- pronunciation: String?
```

## 6. UX Notes
- Core screens: Book list / Page list / Vocabulary list / Camera capture / Captured page data view
- Interaction notes:
  - Tab 1: Home (book list), floating button opens page capture/upload
    - Selecting a book opens its page list
    - Selecting a page opens page detail view
    - In page detail, users tap sentence/word to see learning info
  - Tab 2: Vocabulary
    - Shows word meaning and pronunciation

## 7. Implementation Phases (for Codex execution)
### Phase 1 - Foundation
- Goal: Implement the app's basic structure.
- Tasks:
  - [ ] Implement basic navigation/screen skeleton and tab bar
  - [ ] Define SwiftData models
  - [ ] Implement home screen: show book list and an empty state encouraging upload when there are no books
  - [ ] Implement floating upload button on home screen
- Done Criteria:
  - [ ] Core screen navigation works on app launch
  - [ ] Book page upload button is visible

### Phase 2 - Book Page Update
- Goal: Implement page capture and save flow.
- Tasks:
  - [ ] Support camera capture of book page photos
  - [ ] Support photo picker upload of book page photos
  - [ ] Assign default page title based on current timestamp when saving
  - [ ] On save, allow selecting existing book or creating new category (if not selected, map to 'Unclassified')
  - [ ] Allow editing book names from book list screen (home)
  - [ ] Allow editing page title from page list screen (entered via home -> selected book)
- Done Criteria:
  - [ ] Upload dummy page image data via photo picker
  - [ ] Uploaded page can be saved and viewed
  - [ ] Book/page names can be edited

### Phase 3 - Book Page word detection
- Goal: Distinguish sentences and words on page and provide learning-ready data.
- Tasks:
  - [ ] Detect sentences and words from uploaded page
  - [ ] Display sentence numbers starting from 1; tapping number highlights full sentence
  - [ ] Tapping a word highlights the word
- Done Criteria:
  - [ ] Sentence numbers displayed
  - [ ] Sentence and word selection works

### Phase 4 - Learning Features
- Goal: Provide meaning/pronunciation when sentence or word is selected.
- Tasks:
  - [ ] On sentence selection, open sentence sheet modal (50% height) with translation and TTS
  - [ ] On word selection, open word sheet modal (50% height) with meaning and TTS
  - [ ] Use Apple-provided translation and TTS features
  - [ ] Provide bookmark action in word sheet to save into vocabulary
- Done Criteria:
  - [ ] Sentence/word meaning and pronunciation are available
  - [ ] Saved word appears in vocabulary screen

### Phase 5 - Vocabulary Storage
- Goal: Enable viewing saved vocabulary entries.
- Tasks:
  - [ ] Implement vocabulary screen
  - [ ] Show word meaning and pronunciation
- Done Criteria:
  - [ ] Vocabulary list can be viewed

### Phase 6 - Polish & Test
- Goal: Improve usability, fix issues, and add tests.
- Tasks:
  - [ ] Improve accessibility
  - [ ] Support light/dark mode
  - [ ] Improve error/empty-state handling
  - [ ] Write test code
- Done Criteria:
  - [ ] Build succeeds
  - [ ] Tests pass

## 8. Change Log
- 2026-03-01: v0.1 draft created

---

## Codex Execution Prompt Example
Use the following sentence as-is when requesting execution in Codex:

```txt
Implement based on `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`.
Start from Phase 1, and for each phase provide a short report with:
1) files changed
2) core implementation details
3) validation run (build/test)
4) checks before moving to the next phase
```
