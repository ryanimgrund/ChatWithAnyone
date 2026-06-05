# Release Checklist

1. Build the app:

   ```sh
   xcodebuild -project ChatWithAnyone.xcodeproj \
     -scheme ChatWithAnyone \
     -destination 'generic/platform=iOS Simulator' \
     CODE_SIGNING_ALLOWED=NO \
     build
   ```

2. Run tests in Xcode or with a simulator destination when available.
3. Check that prompt text, chat history, and persona content are not logged.
4. Review `PRIVACY.md` and `SECURITY.md`.
5. Update `CHANGELOG.md`.
6. Create a git tag, for example `v0.1.0`.
7. Publish a GitHub release with:
   - supported Xcode/iOS versions
   - user-facing changes
   - testing notes
   - privacy/security notes
   - known limitations
8. Open follow-up issues for known gaps.
