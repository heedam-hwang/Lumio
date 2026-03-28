# Lumio spec conventions

These conventions are derived from the current documents in `/Users/heedam/develop/Lumio/docs/specs`.

## Current source documents

- `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`
- `/Users/heedam/develop/Lumio/docs/specs/spec-improvement-20260302.md`
- `/Users/heedam/develop/Lumio/docs/specs/spec-improvement-20260307.md`
- `/Users/heedam/develop/Lumio/docs/specs/spec-improvement-20260308.md`

## Naming

- Base spec uses a descriptive filename such as `reading-app-spec.md`.
- Incremental improvement specs use `spec-improvement-YYYYMMDD.md`.
- Improvement spec `Title` matches the filename stem and is wrapped in backticks.

## Heading patterns

- Base spec title: `# Reading App Spec`
- Improvement spec title: `# Lumio Spec Improvement` or `# Lumio Spec Improvement Proposal`
- Common numbered sections:
  - `## 1. Document Info`
  - `## 2. Detailed Improvements` or `## 2. Feature Improvements`
  - `## 3. UI Improvements` or `## 3. UI / UX Updates`
  - `## 4. Validation Plan`
  - optional `## 5. Change Log`

## Document Info fields

Common fields:

- `Title`
- `Related Spec`
- `Previous Spec` when continuing an existing improvement series
- `Version`
- `Author`
- `Date`

Formatting:

- `Title`, paths, version, author, and date values are commonly wrapped in backticks in improvement specs.
- Dates in the body use `YYYY.MM.DD`.

## Requirement writing style

- Favor short bullets over paragraphs.
- Use subsections like `### 2.1 ...`, `### 2.2 ...`.
- When changing current behavior, use:
  - `As-is`
  - `To-be`
- Be explicit about:
  - when behavior is allowed or blocked
  - where buttons appear
  - what persists after save/edit/reorder
  - what updates other screens as a side effect

## Validation style

- Keep validation short.
- Typical items:
  - build succeeds
  - unit tests pass
  - targeted interaction scope such as reorder, persistence, numbering
- Do not claim a check already passed unless it was actually run.

## Change log style

- One bullet per date.
- Format: ``- `2026.03.08`: description``

## Preferred assumptions for new daily specs

- Related spec defaults to `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md`.
- If today's spec extends a recent improvement, include the latest matching improvement doc as `Previous Spec`.
- Default version can start at `v0.1.0` unless the user gives a different versioning scheme.
