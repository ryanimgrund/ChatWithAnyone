# Maintainer Playbook

ChatWithAnyone should earn trust through visible maintenance and careful privacy choices.

## Weekly

- Triage new issues.
- Reproduce bug reports.
- Label issues as `bug`, `enhancement`, `question`, `documentation`, `privacy`, `security`, or `good first issue`.
- Keep roadmap issues small and reviewable.

## Before Each Release

- Build the app.
- Run tests.
- Check for prompt/chat/persona logging.
- Review StoreKit behavior.
- Review `PRIVACY.md` and `SECURITY.md`.
- Update `CHANGELOG.md`.

## Codex/API Credit Use

Good uses:

- Summarize issue reports.
- Draft test cases from user feedback.
- Review PRs for privacy regressions.
- Draft release notes.
- Help split `ContentView.swift` into smaller, reviewable pieces.

Avoid:

- Auto-merging unreviewed code.
- Generating fake user testimonials or adoption claims.
- Adding analytics or cloud sync without explicit privacy review.
