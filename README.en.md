# Lumio

[한국어 README](./README.ko.md)

## Overview

Lumio is an iOS app for readers of English books who want to capture pages, extract text, review translations, and save useful vocabulary while reading. It turns page photos into study material that can be organized by book and reviewed later.

## Features

- Capture or import English book pages from the camera or photo library.
- Run OCR on uploaded page images and split the detected text into sentences.
- Open sentences and words to view Korean translations.
- Listen to English sentence and word pronunciation with text-to-speech.
- Save important words into a personal vocabulary notebook.
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
- `Book Detail`: page list and page-level management
- `Page Detail`: OCR result review, translation, and word lookup
- `Vocabulary`: saved word review

## Requirements

- Xcode project: `Lumio.xcodeproj`
- Swift 6
- iOS deployment target: 26.2
