# gPark

**Park. Scan. Done.**

A Flutter mobile app for Google employees to validate parking at leased offices via OCR ticket scanning. Replaces the manual Google Form submission process.

## Architecture

- **Flutter App** (iOS + Android): Camera capture, on-device OCR (ML Kit), Google Sign-In, offline queue
- **Apps Script Backend**: Receives submissions via POST, writes to the legacy Google Spreadsheet
- **Google Sheet**: System of record (unchanged). Admin reviews, approves/rejects.
- **Google Form**: Fallback (unchanged). Always available.

## Setup

### Prerequisites
- Flutter SDK 3.27+
- Dart SDK 3.6+
- Android Studio / Xcode for device builds

### Install
```bash
flutter pub get
```

### Run
```bash
flutter run
```

### Test
```bash
flutter test
```

### Deploy Apps Script
1. Open [script.google.com](https://script.google.com)
2. Create a new project
3. Copy contents of `apps_script/code.gs` into `Code.gs`
4. Set Script Properties:
   - `SPREADSHEET_ID`: The active quarterly spreadsheet ID
   - `ACTIVE_QUARTER`: e.g., `Q1 2026`
   - `SHEET_TAB_NAME`: `Form Responses`
5. Deploy as Web App: Execute as "me", Access "Anyone within google.com"
6. Copy the deployment URL into `lib/utils/constants.dart`

### Configuration
Update `lib/utils/constants.dart` with:
- `appsScriptUrl`: Your Apps Script deployment URL
- `googleFormUrl`: The fallback Google Form URL

## Project Structure
```
lib/
  main.dart              # Entry point
  app.dart               # MaterialApp + auth-driven navigation
  screens/               # 7 UI screens
  services/              # Auth, OCR, submission, queue, connectivity
  models/                # Data classes
  providers/             # Riverpod state management
  utils/                 # Constants + ticket parser
apps_script/
  code.gs                # Apps Script backend
```

## Quarterly Rotation
See [QUARTERLY_ROTATION.md](QUARTERLY_ROTATION.md) for the admin runbook.
