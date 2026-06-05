# Contributing

Thanks for considering a contribution to ChatWithAnyone. This project is intended to be useful, private, and approachable for people who want local-first conversational practice.

## Development Principles

- Protect user privacy. Do not log prompt text, chat history, persona data, or other personal content.
- Keep the app local-first. Avoid adding network services unless there is a clear privacy review and an explicit user-facing reason.
- Prefer small pull requests. Changes are easier to review when they are focused.
- Add tests when changing model behavior, persistence, prompt construction, purchase state, or data handling.
- Keep accessibility in view. Dynamic Type, VoiceOver labels, color contrast, and touch targets matter.

## Local Setup

1. Clone the repository.
2. Open `ChatWithAnyone.xcodeproj` in Xcode.
3. Select the `ChatWithAnyone` scheme.
4. Build with an iOS 26 simulator or device.

## Pull Request Checklist

- The change has a clear purpose.
- The app still builds locally.
- New or changed behavior is covered by tests where practical.
- User data is not logged or sent to a new service.
- Documentation is updated when setup, privacy, or behavior changes.

## Good First Issues

- Add screenshots to the README.
- Add a StoreKit test configuration.
- Split `ContentView.swift` into smaller files.
- Add tests for `Persona`, `ChatMessage`, and prompt-building behavior.
- Improve unsupported-iOS messaging.
- Review VoiceOver labels and Dynamic Type behavior.

## Reporting Bugs

Use the bug report issue template and include:

- Xcode version.
- iOS simulator or device version.
- Reproduction steps.
- Expected behavior.
- Actual behavior.

Do not include private chat transcripts unless they are required and anonymized.
