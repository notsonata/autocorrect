# Compatibility Matrix

This matrix is the manual release gate for a packaged Autocorrect candidate. CI cannot exercise InputMethodKit against arbitrary foreground applications, so these rows are verified on the actual app build.

A row passes only when normal typing remains immediate, intended misspellings correct after a word boundary, the insertion point remains logical during continued typing, and secure text entry remains pass-through.

| Application | Surface | Required check | Status |
| --- | --- | --- | --- |
| TextEdit | AppKit text view | English + Taglish correction and continuous typing | Pending manual RC |
| Notes | Native editor | Correction and cursor stability across multi-line notes | Pending manual RC |
| Messages | Native composer | Casual Taglish and abbreviations preserved | Pending manual RC |
| Mail | Native compose window | Paragraph typing without focus loss | Pending manual RC |
| Safari | Web inputs/contenteditable | Plain input and contenteditable correction | Pending manual RC |
| Google Chrome | Chromium web fields | Plain input and contenteditable correction | Pending manual RC |
| Slack | Electron editor | Composer correction and cursor stability | Pending manual RC |
| Microsoft Word | Rich text editor | Paragraph typing and cursor stability | Pending manual RC |
| Visual Studio Code | Monaco | Exclusion produces pass-through typing | Pending manual RC |
| Terminal | Terminal input | Exclusion produces pass-through typing | Pending manual RC |
| macOS password field | Secure field | No surrounding-text inspection or correction | Pending manual RC |

## Single-app installation check

1. Extract the release ZIP and confirm its only top-level item is `Autocorrect.app`.
2. Drag `Autocorrect.app` to `/Applications`.
3. Open it once and confirm `~/Library/Input Methods/Autocorrect.app` is installed automatically.
4. Confirm the Autocorrect window contains settings and provider configuration. No separate settings or installer app should exist.
5. Enable the input source and verify normal correction behavior.

## Cross-process credential check

1. In the main Autocorrect app, save a temporary provider API key.
2. Enable the Autocorrect input source and correction.
3. Type a known corpus typo such as `wrld ` in TextEdit.
4. Confirm the installed input-method process can use the stored provider credential.
5. Remove the temporary key from Autocorrect.

## Release rule

Do not claim compatibility for a row until it has been manually verified on the actual packaged build.
