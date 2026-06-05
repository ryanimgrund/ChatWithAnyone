# ChatWithAnyone

ChatWithAnyone is an experimental iOS app for creating on-device conversational personas. It is built with SwiftUI, StoreKit 2, AVFoundation speech voices, and Apple's Foundation Models framework.

The project goal is simple: give people a private, local-first space to practice conversation, explore language and tone, and save persona-based chats without sending prompts or chat history to a server.

## Current Status

This repository is early-stage open source. The app is usable as a prototype, but it needs more testing, accessibility review, privacy review, and contributor feedback before it should be treated as production-ready.

## Features

- Generates age, location, backstory, personality sliders, and response styles for a saved persona.
- Streams responses through `LanguageModelSession` on supported iOS versions.
- Keeps saved personas and chat history in local app storage.
- Supports enhanced and premium Apple speech voices through `AVSpeechSynthesizer`.
- Includes a StoreKit 2 unlock flow for additional local customization.
- Requires iOS 26 or newer because it uses Apple's Foundation Models APIs.

## Privacy Model

ChatWithAnyone is designed as a local-first app:

- Persona and chat data are stored locally on the device.
- The app does not include a custom backend.
- The app does not include analytics, telemetry, or remote logging.
- Debug logging of prompt contents should not be added because chats may be personal.

See [PRIVACY.md](PRIVACY.md) for the current privacy notes.

## Requirements

- macOS with Xcode that supports iOS 26 SDKs.
- iOS 26 simulator or device.
- An Apple developer setup if you want to test StoreKit purchase flows on device.

## Build

1. Open `ChatWithAnyone.xcodeproj` in Xcode.
2. Select the `ChatWithAnyone` scheme.
3. Select an iOS 26 simulator or device.
4. Build and run.

From the command line:

```sh
xcodebuild -project ChatWithAnyone.xcodeproj -scheme ChatWithAnyone -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Simulator names vary by installed Xcode version. If the command fails, run `xcrun simctl list devices available` and use an available iOS simulator name.

## Continuous Integration

GitHub Actions validates that the Xcode project can be listed on hosted macOS runners. The full app build runs only when the runner includes the iOS 26 simulator SDK and `FoundationModels.framework`; otherwise CI records a notice because older hosted Xcode images cannot compile this app honestly.

## Contributing

Good first contributions include:

- Accessibility review for VoiceOver, Dynamic Type, and color contrast.
- Safer prompt construction and persona boundaries.
- Tests for model, persistence, and paywall state behavior.
- StoreKit test configuration.
- Documentation for setup, privacy, and supported devices.
- UI cleanup for smaller screens.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Maintainer Docs

- [Privacy notes](PRIVACY.md)
- [Security policy](SECURITY.md)
- [Release checklist](RELEASE.md)
- [Maintainer playbook](docs/maintainer-playbook.md)
- [OpenAI Codex OSS readiness notes](docs/openai-codex-oss-readiness.md)

## Roadmap

- Add a StoreKit test plan and documented product identifiers.
- Split the large `ContentView.swift` file into smaller model, view, persistence, and prompt-building components.
- Add unit tests for persona generation, prompt construction, and local persistence.
- Add privacy threat modeling for saved conversations.
- Improve accessibility and localization coverage.
- Add screenshots and a short demo video.
- Publish a GitHub Release once the StoreKit test plan and first privacy review are complete.

## License

MIT. See [LICENSE](LICENSE).
