# CLAUDE.md

This file provides guidance for AI assistants working on the gPark codebase.

## Project Overview

gPark is a Flutter mobile app for Google employees to validate parking at leased offices via OCR ticket scanning. It replaces a manual Google Form submission process. Users scan their parking ticket with their phone camera, the app extracts the 7-digit ticket number via on-device OCR, and submits it to a Google Apps Script backend that writes to a Google Spreadsheet.

**Target:** Google FTEs/interns at leased offices (MVP pilot: ~50 users, Atlanta).

## Tech Stack

- **Frontend:** Flutter 3.27+ / Dart 3.6+
- **State management:** Riverpod (`flutter_riverpod`)
- **Authentication:** Google Sign-In (restricted to `@google.com` accounts)
- **OCR:** Google ML Kit Text Recognition (on-device)
- **Camera:** `camera` package
- **Backend:** Google Apps Script (`apps_script/code.gs`)
- **Data store:** Google Spreadsheet (system of record, unchanged from legacy process)
- **Offline persistence:** `shared_preferences` (JSON-serialized queue)
- **HTTP:** `http` package
- **Testing:** `flutter_test` + `mocktail`
- **Linting:** `flutter_lints` (analysis_options.yaml)

## Build & Run Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter test             # Run all tests
flutter analyze          # Run static analysis (Dart analyzer + lints)
flutter clean            # Clean build artifacts
```

Tests are in `test/` and can be run individually:
```bash
flutter test test/utils/ticket_parser_test.dart
flutter test test/models/submission_test.dart
```

## Project Structure

```
lib/
  main.dart                    # Entry point, wraps app in ProviderScope
  app.dart                     # MaterialApp + AuthGate (auth-driven navigation)
  models/
    ocr_result.dart            # OcrResult + OcrConfidence enum
    submission.dart            # Submission, QueueEntry, SubmissionResponse
    user_profile.dart          # UserProfile (from GoogleSignInAccount)
  providers/
    auth_provider.dart         # AuthNotifier (StateNotifier) + AuthState sealed class
    connectivity_provider.dart # Stream/Future providers for online status
    submission_provider.dart   # SubmissionNotifier + SubmissionState sealed class
  screens/
    sign_in_screen.dart        # Google Sign-In screen with animated background
    home_screen.dart           # Main screen, FAB to launch scanner, queue banner
    camera_screen.dart         # Camera preview + capture + OCR processing
    confirmation_screen.dart   # Auto-submit countdown (5s) with edit/cancel options
    manual_review_screen.dart  # Manual ticket entry for low/ambiguous OCR results
    success_screen.dart        # Animated checkmark, confetti, stale quarter warning
    error_screen.dart          # Retry + Google Form fallback
  services/
    auth_service.dart          # Google Sign-In wrapper, @google.com domain check
    ocr_service.dart           # ML Kit text recognition, delegates to TicketParser
    submission_service.dart    # HTTP POST to Apps Script endpoint
    queue_service.dart         # Offline queue (SharedPreferences), retry with backoff
    connectivity_service.dart  # connectivity_plus wrapper
  theme/
    app_theme.dart             # Material 3 light/dark ThemeData builder
    app_colors.dart            # Full light/dark color palettes + Spacing constants
    app_typography.dart        # Google Fonts (Space Mono for numbers, DM Sans for body)
  utils/
    constants.dart             # All configuration: URLs, timeouts, queue limits
    ticket_parser.dart         # Regex-based 7-digit ticket extraction + confidence logic
  widgets/
    animated_checkmark.dart    # Path-animated checkmark with circle draw
    ticket_card.dart           # Ticket-stub styled card with perforated edge clipper
    scan_overlay.dart          # Corner-bracket camera overlay with pulse animation

apps_script/
  code.gs                      # Apps Script backend (doGet/doPost, duplicate check, metadata logging)
  appsscript.json              # Apps Script manifest
  .clasp.json                  # clasp deployment config

test/
  utils/ticket_parser_test.dart  # Comprehensive TicketParser unit tests (13 cases)
  models/submission_test.dart    # Submission/QueueEntry/SubmissionResponse tests
  widget_test.dart               # Placeholder smoke test
```

## Architecture & Design Rules

The codebase follows rules documented in the PRD (`gpark_prd.md`). Key rules referenced in code comments:

1. **Never write directly to Google Sheets** - All writes go through the Apps Script endpoint (`submission_service.dart`)
2. **OCR runs entirely on-device** - No images or text are sent to any server (`ocr_service.dart`)
3. **URLs are constants** - All endpoint URLs live in `constants.dart`, never hardcoded elsewhere
4. **Ticket parsing is isolated** - `TicketParser` is a pure static class with no dependencies beyond models
5. **Auth drives navigation** - `_AuthGate` in `app.dart` switches between SignIn and Home based on auth state

### State Management Pattern

- **Riverpod** with `StateNotifier` pattern
- Auth, submission, and connectivity each have their own provider
- State classes use Dart 3 **sealed classes** with pattern matching (`when` method on `AuthState`, `switch` on `SubmissionState`)
- Providers are defined at the top of their respective files

### Navigation Pattern

- **Imperative navigation** using `Navigator.push/pushReplacement/popUntil`
- No named routes or router package
- Screen flow: SignIn -> Home -> Camera -> Confirmation/ManualReview -> Success/Error -> Home

### Theme System

- **Material 3** with both light and dark theme support (`ThemeMode.system`)
- Colors defined as static constants in `AppColors` with semantic helpers that resolve via `BuildContext`
- Spacing scale: `Spacing.xs` (4) through `Spacing.xxxl` (64)
- Typography: Space Mono for brand/ticket numbers, DM Sans for body text

## Key Conventions

### Dart Style

- Private constructors on utility classes (`Constants._()`, `TicketParser._()`)
- `const` constructors used extensively on widgets and data classes
- `super.key` syntax for widget constructors
- snake_case for JSON keys in serialization (`toPayload`, `toJson`, `fromJson`)
- camelCase for Dart properties
- File naming: lowercase_with_underscores matching class names
- Underscore-prefixed private classes for screen-local widgets (e.g., `_AuthGate`, `_StatusBadge`, `_EmptyState`)

### Widget Conventions

- Screens are `ConsumerStatefulWidget` (Riverpod) when they need providers
- `ConsumerWidget` for simpler reactive widgets
- Plain `StatelessWidget`/`StatefulWidget` for pure UI components
- `WidgetsBindingObserver` mixed in where app lifecycle matters (camera, queue retry)
- Animation controllers disposed in `dispose()`, observers removed

### Error Handling

- Services return result objects rather than throwing (e.g., `SubmissionResponse` with status field)
- `AuthException` is the one domain exception (thrown by `AuthService`)
- Offline submissions are queued automatically, not treated as errors
- Google Form is always available as fallback (linked from ErrorScreen)

### Testing

- Unit tests for pure logic: `TicketParser`, `Submission` model serialization
- `mocktail` available for mocking in tests
- Widget tests require mocking Google Sign-In and camera (placeholder exists)
- Test file structure mirrors `lib/` structure under `test/`

## Backend (Apps Script)

The Apps Script backend (`apps_script/code.gs`) is deployed as a Google Web App:

- **doGet**: Health check, returns current quarter
- **doPost**: Main submission endpoint
  - Validates required fields and 7-digit ticket format
  - Reads config from Script Properties (`SPREADSHEET_ID`, `ACTIVE_QUARTER`, `SHEET_TAB_NAME`)
  - Checks for duplicate submissions (same ticket + same date)
  - Appends row to "Form Responses" tab (Columns A-D: Timestamp, Email, Validation Type, Ticket Number)
  - Logs extended metadata to "gPark Metadata" tab
  - Detects stale quarter configuration and returns warning

### Quarterly Rotation

Every quarter, an admin must update Script Properties with the new spreadsheet ID and quarter label. See `QUARTERLY_ROTATION.md` for the runbook. If missed, submissions still work but go to the old spreadsheet with a `stale_quarter` warning.

## Configuration

All configurable values are in `lib/utils/constants.dart`:

| Constant | Purpose |
|----------|---------|
| `appsScriptUrl` | Apps Script deployment URL |
| `googleFormUrl` | Fallback Google Form URL |
| `officeLocation` | Default office ("Atlanta") |
| `submissionTimeout` | HTTP timeout (30s) |
| `maxQueueSize` | Offline queue limit (10) |
| `maxRetries` | Queue retry limit (3) |
| `retryBackoffs` | Backoff durations [30s, 2m, 10m] |
| `autoSubmitCountdown` | Confirmation countdown (5s) |
| `successAutoDismiss` | Success screen auto-dismiss (5s) |

## Ticket Number Format

- Exactly 7 digits, matched by regex `\b\d{7}\b`
- Leading zeros are significant and preserved as strings (never parsed as int)
- Printed twice on physical parking stubs (enables high-confidence OCR matching)

### OCR Confidence Levels

| Level | Condition | App Behavior |
|-------|-----------|--------------|
| `high` | 2+ identical 7-digit matches | Auto-confirm with 5s countdown |
| `medium` | 1 unique 7-digit match | Auto-confirm with 5s countdown |
| `low` | No 7-digit matches found | Manual review screen |
| `ambiguous` | Multiple different 7-digit numbers | Manual review with candidate chips |
