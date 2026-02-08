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

**Test collection** (`contributors_test`): 10 dummy contributors per category (30 total) seeded via `lib/seed.dart` with fake emails (`@faketestemail.com`). This is the only collection the app and email sender interact with right now.

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

`HomeViewModel._listenContributors()` uses real-time Firestore snapshots (`.snapshots()`) across the 3 category subcollections and groups results — the UI updates automatically when data changes. `HomeViewModel.loadTemplates()` reads the 6 template fields from each category document.

### Current State

The app displays a 3-tab bar (CONTRIBUTORS, ADVISORS, PROGRESS). Default selected tab is ADVISORS (index 1). The CONTRIBUTORS tab uses a PageView to show one category at a time (EPCs, OEMs, Utilities) with left/right chevron navigation. Each page shows a contributor table with Name, Title, Company, Email, Outbound Email, Status, and a narrow action column. The LinkedIn column is hidden by default and can be toggled visible via a chevron icon next to the Email header (`showLinkedIn` in `HomeViewModel`). The action column shows an `x` icon on data rows (deletes the contributor after a confirmation dialog) and a `+` icon on the input row (adds a new contributor). Rows are color-coded by status: Initial Email Sent (light blue), No Response (light orange), Follow-Up Sent (light yellow), Responded (light green), No Response After Follow-Up (light red). Search-matched rows are highlighted in light purple (`0xFFE1BEE7`).

Next to each category title is a "Check Duplicates" button that scans the current category for duplicate email addresses (case-insensitive). If duplicates are found, a dialog shows radio buttons per duplicate group to select which record to keep — unchosen records are deleted. If no duplicates, shows a "No duplicates found" message.

Name search (top of each page) filters within the current category only and does not auto-switch to other categories. Match count is scoped to the current category.

Below each category table is an "EMAIL TEMPLATES" section with two collapsible cards (Initial Email and Follow-Up Email). Each card has separate Subject (text field), Body (rich text editor), and Footer (text field) sections, a Save button, and a lock/collapse toggle. The lock icon auto-saves content when locking. The Body editor uses a `contenteditable` div on web (`body_editor_web.dart`) that preserves formatting pasted from Google Docs (bold, italics, links, line breaks). Non-web platforms use a plain TextField fallback (`body_editor.dart`). These are wired via conditional import: `import 'body_editor.dart' if (dart.library.html) 'body_editor_web.dart'`.

Templates support `{{Name}}` placeholder — replaced with each recipient's `firstName` when sending.

Below the template cards is a row of action buttons: "Send Initial Emails", "Send Follow-Up Emails", and "Check Replies". All send actions require a confirmation dialog before executing (same style as delete-user popup). The Check Replies button can be clicked at any time and performs three actions in order: (1) scans all 8 outbound inboxes for replies and marks matched contributors as "Responded", (2) marks "Initial Email Sent" contributors with no reply as "No Response", (3) marks "Follow-Up Sent" contributors with no reply as "No Response After Follow-Up". Contributors who replied are always protected from being overwritten by the no-reply checks.

During active sends, Pause and Stop buttons appear. Pause requires confirmation and suspends all threads (resumable without confirmation). Stop requires confirmation and terminates the job permanently. The dashboard shows status badges including Paused (purple) and Stopped (red).

Below the buttons is a Responded section showing contributors who replied (name, email, outbound account). Below that is a send dashboard (always visible) showing overall progress (sent/total) with a progress bar, and all 8 outbound accounts with live status badges (Sending, Cooldown, 5-min Break, Idle, Error, Paused, Stopped, Done) and countdown timers. The Flutter app polls the email server every 2 seconds during active sends.

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

- Flask server on port 5001 with six endpoints:
  - `POST /send-emails` — accepts `{"category": "EPCs", "type": "initial"}` or `{"type": "followUp"}`, starts a send job, returns `{"jobId": "..."}` immediately
  - `GET /send-status/<job_id>` — returns per-account status, sent/total counts, job state, and whether the job is done (used by Flutter polling)
  - `POST /pause-job/<job_id>` — pauses the job (threads sleep until resumed)
  - `POST /resume-job/<job_id>` — resumes a paused job
  - `POST /stop-job/<job_id>` — stops the job permanently (threads exit)
  - `POST /check-replies` — checks all 8 outbound Gmail inboxes via IMAP for unseen replies. Marks matched senders as "Responded", then marks "Initial Email Sent" with no reply as "No Response", then marks "Follow-Up Sent" with no reply as "No Response After Follow-Up". Returns `{"found": N}` (count of new replies)
- Reads recipients and email templates (Subject/Body/Footer) from Firebase (`COLLECTION` in `mailer.py`)
- **Send Initial**: targets recipients with empty status → sets status to "Initial Email Sent"
- **Send Follow-Up**: targets recipients with "No Response" status → sets status to "Follow-Up Sent"
- **Status lifecycle**: `""` → `"Initial Email Sent"` → (check replies) → `"Responded"` or `"No Response"` → `"Follow-Up Sent"` → (check replies) → `"Responded"` or `"No Response After Follow-Up"` (dead end). "Responded" is terminal at any stage. "No Response After Follow-Up" is a dead end — no further automated emails are sent.
- **Reply tracking**: "Check Replies" triggers IMAP scan of all 8 inboxes. Marks matched senders as "Responded", then marks "Initial Email Sent" with no reply as "No Response", then marks "Follow-Up Sent" with no reply as "No Response After Follow-Up". "Responded" is a terminal status — no automated emails are ever sent to responded users (enforced by status filters in send logic and `RESPONDED_EMAILS` in-memory set for in-flight jobs)
- **Parallel sending**: splits recipients across all 8 outbound accounts using Python `threading.Thread`, one thread per account. Each account follows its own anti-spam rules independently
- `{{Name}}` in subject and body is replaced with each recipient's `firstName`
- Emails are sent as `multipart/alternative` with both plain text and HTML parts (anti-spam best practice). Footer is converted from plain text to HTML and appended with `<br><br>`
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
- `multipart/alternative` format (plain text + HTML) — single-part HTML is a spam signal
- `List-Unsubscribe` mailto header on every email — Gmail checks for this
- Per-email HTML content variation via `_vary_html()` — wraps body in a `<div>` with a unique `id` and inserts a unique HTML comment so no two emails have identical fingerprints
- Debug prints: `[VARY]` logs unique uid per email, `[ANTI-SPAM]` logs format/header details per send

### Dependencies

- `flask` — HTTP API
- `firebase-admin` — Firestore access via service account key
- `certifi` — SSL certificate bundle (fixes macOS certificate issues)

Service account key path: `Tools/the-electrification-index-firebase-adminsdk-fbsvc-1facd5a75d.json`
