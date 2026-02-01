# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Mono-repo with two sub-projects and shared tooling docs:

- **`flutter/`** — Flutter multi-platform app ("The Electrification Index OS")
- **`flutter/automated-email-sender/`** — Python bulk email sender with anti-spam protection
- **`Tools/`** — Development protocols and deployment guides

## Development Protocols (tools/)

**Always read and follow `Tools/P.md` when implementing features.** Key rules:

- **Confirmation Protocol**: Present a plan for every change step. Wait for explicit "Approved" before writing any code.
- **Bare minimum only**: Reduce scope until it breaks, add back only what's strictly necessary.
- **MVVM, simplest possible**: Follow existing patterns. No extra layers, abstractions, or unnecessary dependencies.
- **Reuse before adding**: Check if existing logic can be reused before creating new methods.
- **Don't Touch Rule**: Never modify unrelated code without explicit approval.
- **Simplify after implementing**: Ask "can this be done simpler?" — if yes, simplify it.

**`Tools/R.md`** — Refactoring guide. Only refactor when repetitive logic exists. Simplify aggressively. Never modify public API.

**`Tools/D.md`** — Deployment to GitHub Pages. Uses `deployment_7` branch, serves from `docs/`. Must manually remove `flutter_service_worker.js` after build. Must set `--base-href` to `/bas/`.

## Flutter App (flutter/)

### Commands

All commands run from `flutter/` directory:

```bash
# Run the app (requires connected device/emulator or use -d chrome for web)
flutter run

# Build for web (deployment)
flutter build web --pwa-strategy=none --base-href /bas/

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Get dependencies
flutter pub get
```

### Architecture

MVVM with Provider for state management:

- `lib/views/` — UI widgets (StatelessWidget consuming ViewModels via `context.watch`)
- `lib/view_models/` — ChangeNotifier classes holding UI state
- `lib/models/` — Data classes (e.g. `Contributor`)
- `lib/main.dart` — App entry point, wires ChangeNotifierProviders to MaterialApp

### Dependencies

- `firebase_core` — Firebase initialization
- `cloud_firestore` — Firestore database access
- `google_fonts` — Typography (Inter font family)
- `provider` — State management
- Dart SDK: `^3.9.2`

### Firebase

Project: `the-electrification-index` (ID: `162583006610`). Configured for Web, Android, iOS, macOS, and Windows in `lib/firebase_options.dart`. Platform-specific config files: `google-services.json` (Android), `GoogleService-Info.plist` (iOS/macOS).

Firebase is initialized in `main.dart` before `runApp()`.

### Data

Contributor data is stored in Firestore using subcollections under a `contributors` collection:

```
contributors/
  ├── EPCs (document) → { initialEmail, followUpEmail } + items/ (subcollection, ~docs)
  ├── OEMs (document) → { initialEmail, followUpEmail } + items/ (subcollection, ~docs)
  └── Utilities (document) → { initialEmail, followUpEmail } + items/ (subcollection, ~docs)
```

Each contributor document has fields: `firstName`, `lastName`, `title`, `company`, `email`, `linkedinUrl`. The `Contributor` model also stores a `docId` (the Firestore document ID) used for deletion. ~2,350 total records across 3 categories.

Each category document also stores `initialEmail` and `followUpEmail` fields for per-category email templates.

`HomeViewModel.loadContributors()` iterates over the 3 category subcollections and groups results. `HomeViewModel.loadTemplates()` reads email templates from each category document.

### Current State

The app displays a title ("THE ELECTRIFICATION INDEX OS") and a 3-tab bar (CONTRIBUTORS, ADVISORS, PROGRESS). Default selected tab is ADVISORS (index 1). The CONTRIBUTORS tab reads contributor data from Firestore and displays it in stacked tables grouped by category (EPCs, OEMs, Utilities), showing Name, Title, Company, Email, LinkedIn, and a narrow action column. The action column shows an `x` icon on data rows (deletes the contributor after a confirmation dialog) and a `+` icon on the input row (adds a new contributor). Below each category table is an "EMAIL TEMPLATES" section with two collapsible cards (Initial Email and Follow-Up Email). Each card has a text area for pasting/editing, a Save button, and a lock/collapse toggle. Templates are stored per category and automatically switch when the user navigates between categories. ADVISORS and PROGRESS tabs are not yet implemented.

## Python Email Sender (flutter/automated-email-sender/)

```bash
# Install dependencies
pip install -r requirements.txt

# Run
python mailer.py
```

Requires configuration in `mailer.py`: SMTP credentials, Excel file path, delay settings. Uses `pandas` and `openpyxl`.
