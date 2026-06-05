# Privacy Notes

ChatWithAnyone is designed as a local-first app. The current repository does not include a backend service, analytics SDK, telemetry SDK, or custom remote logging.

## Data Stored Locally

The app stores saved personas and chat history in local app storage using `@AppStorage`.

Stored data may include:

- Persona age, gender, language, city, and country.
- Persona personality slider values.
- Persona backstory.
- User and persona chat messages.

## Data Sent Remotely

The project currently does not include code that sends persona or chat history to a custom server.

The app uses Apple's Foundation Models framework and StoreKit. Contributors should review Apple's platform behavior and documentation when changing those integrations.

## Logging Rule

Do not log prompt text, chat history, saved persona data, or generated responses. Debug statements that include user content should be removed before merging.

## Privacy Review Checklist

Before merging a change, ask:

- Does this add a new network request?
- Does this add analytics, crash reporting, telemetry, or remote logging?
- Does this expose saved chat or persona content?
- Does this change how long local data is kept?
- Does this change purchase-state behavior?

If the answer to any of these is yes, update this file and explain the privacy impact in the pull request.
