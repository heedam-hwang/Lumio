---
name: lumio-spec-writer
description: Create or update Lumio spec documents in this repository, especially daily spec improvement docs under docs/specs. Use this when the user wants today's Lumio spec template, a new spec-improvement-YYYYMMDD document, or a repo-aligned rewrite of an existing spec based on the established docs/specs structure.
---

# Lumio Spec Writer

Write spec documents for this repository using the conventions already established in `docs/specs`.

## When to use

- The user wants "today's" Lumio spec document.
- The user wants a new spec template or improvement proposal under `docs/specs`.
- The user wants an existing Lumio spec rewritten to match repository style.

## Source of truth

1. Read [`references/spec-conventions.md`](references/spec-conventions.md) first.
2. If the request depends on a related spec, open the referenced file in `docs/specs`.
3. Keep the new document aligned with the repository's current naming and section patterns.

## Output rules

- Default output path: `docs/specs/spec-improvement-YYYYMMDD.md`
- Use the user's local date when "today" is requested.
- Prefer concise, implementation-ready bullets over narrative prose.
- Preserve absolute repository paths when linking related spec files inside the document.
- If there is a prior spec in the same thread of changes, include `Previous Spec`.
- Do not invent validation results. Write planned checks only.

## Standard workflow

1. Inspect the latest related files in `docs/specs`.
2. Determine whether the document is:
   - a base product spec
   - an improvement spec
   - a follow-up improvement spec referencing a previous one
3. Start from the matching template in [`assets/spec-improvement-template.md`](assets/spec-improvement-template.md) when creating an improvement spec.
4. Fill placeholders with:
   - today's date in `YYYY.MM.DD`
   - filename-style title in backticks
   - related spec absolute path
   - concrete requirement bullets
   - validation plan that matches the requested work
5. Before finishing, verify:
   - title and filename date match
   - section numbering is consistent
   - headings and bullet style match existing Lumio docs
   - referenced file paths exist in the repo

## Document shape for improvement specs

Use this structure unless the user asks otherwise:

1. `# Lumio Spec Improvement`
2. `## 1. Document Info`
3. `## 2. Detailed Improvements` or `## 2. Feature Improvements`
4. `## 3. UI Improvements` or `## 3. UI / UX Updates` when needed
5. `## 4. Validation Plan`
6. `## 5. Change Log` when the document is meant to evolve across dates

Pick the narrower heading names that best fit the request, but stay close to existing examples.

## What good Lumio specs look like

- Requirements are framed as clear `As-is` / `To-be` bullets when describing a delta.
- UI behavior is explicit about edit mode, tap targets, persistence, and modal behavior.
- Validation is short and concrete: build, tests, and the most relevant interaction scope.
- Dates, filenames, and references are internally consistent.

## If the request is ambiguous

- Assume the user wants an improvement spec, not a brand-new product spec.
- Assume the main related spec is `/Users/heedam/develop/Lumio/docs/specs/reading-app-spec.md` unless a newer related spec is explicitly provided.
- If there are multiple recent improvement specs on the same topic, use the newest one as `Previous Spec`.
