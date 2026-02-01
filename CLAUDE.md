# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Mono-repo with two independent sub-projects and shared tooling docs:

- **`ui/`** — Flutter multi-platform app ("The Electrification Index OS")
- **`automated-email-sender-logic/`** — Python bulk email sender with anti-spam protection
- **`tools/`** — Development protocols and deployment guides

## Development Protocols (tools/)

**Always read and follow `tools/P.md` when implementing features.** Key rules:

- **Confirmation Protocol**: Present a plan for every change step. Wait for explicit "Approved" before writing any code.
- **Bare minimum only**: Reduce scope until it breaks, add back only what's strictly necessary.
- **MVVM, simplest possible**: Follow existing patterns. No extra layers, abstractions, or unnecessary dependencies.
- **Reuse before adding**: Check if existing logic can be reused before creating new methods.
- **Don't Touch Rule**: Never modify unrelated code without explicit approval.
- **Simplify after implementing**: Ask "can this be done simpler?" — if yes, simplify it.

**`tools/R.md`** — Refactoring guide. Only refactor when repetitive logic exists. Simplify aggressively. Never modify public API.

**`tools/D.md`** — Deployment to GitHub Pages. Uses `deployment_7` branch, serves from `docs/`. Must manually remove `flutter_service_worker.js` after build. Must set `--base-href` to `/bas/`.

## Flutter App (ui/)

### Commands

All commands run from `ui/` directory:

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
- `lib/main.dart` — App entry point, wires ChangeNotifierProviders to MaterialApp

### Dependencies

- `google_fonts` — Typography (Inter font family)
- `provider` — State management
- Dart SDK: `^3.9.2`

### Current State

The app displays a title ("THE ELECTRIFICATION INDEX OS") and a 3-tab bar (CONTRIBUTORS, ADVISORS, PROGRESS). Tab content is not yet implemented. Default selected tab is ADVISORS (index 1).

## Python Email Sender (automated-email-sender-logic/)

```bash
# Install dependencies
pip install -r requirements.txt

# Run
python mailer.py
```

Requires configuration in `mailer.py`: SMTP credentials, Excel file path, delay settings. Uses `pandas` and `openpyxl`.
