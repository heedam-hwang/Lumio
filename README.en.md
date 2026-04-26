# Lumio

[한국어 README](./README.ko.md)

## Overview

Lumio is an iOS app for readers of English books who want to capture pages, extract text, review translations, look up words directly from a dedicated search tab, and save useful vocabulary while reading. It turns page photos into study material that can be organized by book and reviewed later.

## Features

- Capture or import English book pages from the camera or photo library.
- Run OCR on uploaded page images and split the detected text into sentences.
- Open sentences and words to view Korean translations.
- Look up words directly from the `Word Search` tab and keep a recent lookup history.
- Listen to English sentence and word pronunciation with text-to-speech.
- Save important words into a personal vocabulary notebook.
- Edit meanings from the current lookup result, recent lookups, and vocabulary with a shared correction flow.
- Organize pages by book and manage saved page order.

## Tech Stack

- SwiftUI for the app interface
- SwiftData for local persistence
- Vision for OCR text recognition
- NaturalLanguage for sentence tokenization
- Translation framework for English-to-Korean translation
- AVSpeechSynthesizer for speech playback

## App Structure

- `Home`: book library and upload entry point
- `Word Search`: direct word lookup, recent history, web dictionary link, and meaning edits
- `Book Detail`: page list and page-level management
- `Page Detail`: OCR result review, translation, and word lookup
- `Vocabulary`: saved word review

## Screenshots

- `Word Search`: screenshot placeholder
- `Recent Lookups`: screenshot placeholder
- `Meaning Edit`: screenshot placeholder

## Requirements

- Xcode project: `Lumio.xcodeproj`
- Swift 6
- iOS deployment target: 26.2
