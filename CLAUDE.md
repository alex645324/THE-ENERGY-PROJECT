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

# Seed test data into contributors_test collection
flutter run -t lib/seed.dart -d chrome
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
- `http` — HTTP client for calling the Python email server
- Dart SDK: `^3.9.2`

### Firebase

Project: `the-electrification-index` (ID: `162583006610`). Configured for Web, Android, iOS, macOS, and Windows in `lib/firebase_options.dart`. Platform-specific config files: `google-services.json` (Android), `GoogleService-Info.plist` (iOS/macOS).

Firebase is initialized in `main.dart` before `runApp()`.

### Data

Contributor data is stored in Firestore using subcollections. The collection name is controlled by `_collectionName` in `HomeViewModel` (line 31 of `lib/view_models/home_view_model.dart`) and `COLLECTION` in `mailer.py` (line 20). Both are currently set to `contributors_test` for testing.

**WARNING: Both the Flutter app and the Python email sender must point to the same collection. When switching to production, update BOTH `_collectionName` in `home_view_model.dart` AND `COLLECTION` in `mailer.py` to `contributors`. Do NOT change only one — this will cause data mismatches or emails sent to the wrong collection.**

**Production collection** (`contributors`): ~2,350 real records across 3 categories. NOT currently in use. No reads, writes, or emails are sent to this collection.

**Test collection** (`contributors_test`): 2 dummy contributors per category seeded via `lib/seed.dart`. Test emails: `alieelpozo3@gmail.com`, `alieelswork@gmail.com`. This is the only collection the app and email sender interact with right now.

Both collections share the same structure:

```
<collection_name>/
  ├── EPCs (document) → { initialEmailSubject, initialEmailBody, initialEmailFooter,
  │                        followUpEmailSubject, followUpEmailBody, followUpEmailFooter }
  │   └── items/ (subcollection of contributor documents)
  ├── OEMs (document) → (same fields) └── items/
  └── Utilities (document) → (same fields) └── items/
```

Each contributor document has fields: `firstName`, `lastName`, `title`, `company`, `email`, `linkedinUrl`, `outboundEmail`, `status`. The `Contributor` model also stores a `docId` (the Firestore document ID) used for deletion.

Each category document stores 6 template fields: `initialEmailSubject`, `initialEmailBody`, `initialEmailFooter`, `followUpEmailSubject`, `followUpEmailBody`, `followUpEmailFooter`. Body is stored as HTML (rich text from contenteditable editor). Footer is plain text.

`HomeViewModel.loadContributors()` iterates over the 3 category subcollections and groups results. `HomeViewModel.loadTemplates()` reads the 6 template fields from each category document.

### Current State

The app displays a title ("THE ELECTRIFICATION INDEX OS") and a 3-tab bar (CONTRIBUTORS, ADVISORS, PROGRESS). Default selected tab is ADVISORS (index 1). The CONTRIBUTORS tab reads contributor data from Firestore and displays it in stacked tables grouped by category (EPCs, OEMs, Utilities), showing Name, Title, Company, Email, LinkedIn, Outbound Email, Status, and a narrow action column. The action column shows an `x` icon on data rows (deletes the contributor after a confirmation dialog) and a `+` icon on the input row (adds a new contributor).

Below each category table is an "EMAIL TEMPLATES" section with two collapsible cards (Initial Email and Follow-Up Email). Each card has separate Subject (text field), Body (rich text editor), and Footer (text field) sections, a Save button, and a lock/collapse toggle. The lock icon auto-saves content when locking. The Body editor uses a `contenteditable` div on web (`body_editor_web.dart`) that preserves formatting pasted from Google Docs (bold, italics, links, line breaks). Non-web platforms use a plain TextField fallback (`body_editor.dart`). These are wired via conditional import: `import 'body_editor.dart' if (dart.library.html) 'body_editor_web.dart'`.

Templates support `{{Name}}` placeholder — replaced with each recipient's `firstName` when sending.

Below the template cards is a row of action buttons: "Send Initial Emails", "Send Follow-Up Emails", and "Check Replies". The Check Replies button scans all 8 outbound inboxes for replies and updates matched contributors' status to "Responded". Below the buttons is a send dashboard (always visible) showing overall progress (sent/total) with a progress bar, and all 8 outbound accounts with live status badges (Sending, Cooldown, 5-min Break, Idle, Error, Done) and countdown timers. The Flutter app polls the email server every 2 seconds during active sends.

ADVISORS and PROGRESS tabs are not yet implemented.

## Python Email Sender (flutter/automated-email-sender/)

Flask API backend that sends emails via Gmail SMTP. Started automatically by `run.sh` alongside the Flutter app.

```bash
# Run both Flutter app and email server together (from flutter/ directory)
./run.sh

# Or run the email server standalone
pip install -r automated-email-sender/requirements.txt
python3 automated-email-sender/mailer.py
```

### How It Works

- Flask server on port 5001 with three endpoints:
  - `POST /send-emails` — accepts `{"category": "EPCs", "type": "initial"}` or `{"type": "followUp"}`, starts a send job, returns `{"jobId": "..."}` immediately
  - `GET /send-status/<job_id>` — returns per-account status, sent/total counts, and whether the job is done (used by Flutter polling)
  - `POST /check-replies` — checks all 8 outbound Gmail inboxes via IMAP for unseen replies, matches senders to contributors in Firebase, sets their status to "Responded", returns `{"found": N}`
- Reads recipients and email templates (Subject/Body/Footer) from Firebase (`COLLECTION` in `mailer.py`)
- **Send Initial**: targets recipients with empty status → sets status to "Initial Email Sent"
- **Send Follow-Up**: targets recipients with "No Response" status → sets status to "Follow-Up Sent"
- **Reply tracking**: "Check Replies" button triggers IMAP scan of all 8 inboxes. If a recipient's email matches an unseen reply sender, their status is set to "Responded" and all further automated emails are skipped (both in new jobs via status filter and in-flight jobs via `RESPONDED_EMAILS` in-memory set)
- **Parallel sending**: splits recipients across all 8 outbound accounts using Python `threading.Thread`, one thread per account. Each account follows its own anti-spam rules independently
- `{{Name}}` in subject and body is replaced with each recipient's `firstName`
- Body is sent as HTML (from the rich text editor). Footer is converted from plain text to HTML and appended with `<br><br>`
- Auto-assigns an outbound Gmail account to each recipient (round-robin, immutable once set)
- Each recipient always receives emails from their assigned outbound account
- Job state is stored in-memory (`JOBS` dict) — lost on server restart

### Outbound Accounts

8 Gmail accounts with per-account App Passwords stored in `OUTBOUND_ACCOUNTS` dict in `mailer.py`. All use Gmail SMTP (port 465, SSL). If an account's App Password is regenerated, update the corresponding entry in `mailer.py`.

### Anti-Spam

Per-account (each of the 8 threads independently):

- 45–90 second random wait between each email
- 5-minute cooldown every 10 emails
- Stops immediately on SMTP 550 spam block detection
- 15-second pause on other SMTP errors before continuing

### Dependencies

- `flask` — HTTP API
- `firebase-admin` — Firestore access via service account key
- `certifi` — SSL certificate bundle (fixes macOS certificate issues)

Service account key path: `Tools/the-electrification-index-firebase-adminsdk-fbsvc-1facd5a75d.json`
