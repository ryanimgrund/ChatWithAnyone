# Security Policy

## Supported Versions

ChatWithAnyone is early-stage. Security fixes are applied to the `main` branch until the project starts publishing tagged releases.

## Reporting a Vulnerability

Please do not open a public issue for a vulnerability.

Use GitHub's private vulnerability reporting if it is enabled for this repository. If it is not enabled, contact the maintainer through GitHub and share only the minimum information needed to start a private conversation.

Useful reports include:

- A short summary of the issue.
- Affected files or features.
- Steps to reproduce.
- Impact to user privacy, purchase state, local data, or app integrity.
- Suggested fix, if known.

## Security Priorities

- No logging of private chat or persona content.
- No unexpected network transmission of user content.
- Safe handling of saved local data.
- Clear behavior around StoreKit purchase state.
- Safe prompt construction that avoids leaking internal instructions into chat output.
