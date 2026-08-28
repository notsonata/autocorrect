# Autocorrect

A native macOS autocorrection utility designed for seamless English, Filipino, and Taglish correction.

## Project principles

- Corrections must never block normal typing.
- Corrections must not move the user's logical insertion point.
- Completed words are evaluated when a word boundary is typed, beginning with Space.
- Typed text is transient and is never intentionally persisted to disk, UserDefaults, logs, analytics, or correction history.
- Secure text fields and password entry are never processed.
- AI providers are isolated behind a provider interface. Google Gemini is the first target, authenticated with OAuth.

Development is tracked through pull requests against `main`.
