# gpark
**gPark**

*Park. Scan. Done.*

Implementation-Ready Product Requirements Document

v4.2 FINAL \| February 2026

Stakeholders: REWS, CorpEng, AAA Parking Vendor Mgmt

Target: Q1 2026 \| MVP Pilot: \~50 Users (Atlanta)

  ------------- ------------- ----------------------------------------------
  **Version**   **Date**      **Change**

  v3.0          Jan 2026      Original PRD (product strategy + UX design
                              spec)

  v4.0          Feb 2026      Implementation rewrite (assumed data model)

  v4.1          Feb 2026      Updated with actual spreadsheet schema + real
                              ticket format from production data

  v4.2          Feb 2026      All P0 items resolved. Quarterly spreadsheet
                              rotation handling + staleness detection added.
  ------------- ------------- ----------------------------------------------

gPark PRD

Implementation Specification

**Product Overview**

**1.1 Problem**

Googlers at leased offices (starting with Atlanta, 1105 West Peachtree)
must manually validate parking every day. The current process: fill out
a Google Form with your ticket number before 5:00 PM. Miss the window,
pay \$20 out of pocket. The physical act of parking and the
administrative act of validating are disconnected. This gap creates
cognitive drift. Users forget. Users pay.

**1.2 Users**

Google FTE and Interns at leased offices who do not have permanent
parking passes. Primarily Nooglers and waitlist employees. MVP pilot:
\~50 users at the Atlanta office.

**1.3 Value Proposition**

gPark shifts validation from departure-based to arrival-based. Park your
car. Scan your ticket. Done. The app captures ticket data via OCR the
moment you park, eliminating the 5 PM deadline panic entirely.

**1.4 Job to Be Done**

\"When I park at my leased office, I want to scan my ticket immediately
so I never have to think about validation again."

**1.5 How It Works**

The user opens gPark, taps Scan Ticket, and photographs their AAA
Parking stub. On-device OCR reads the 7-digit ticket number (which is
printed twice on the stub for redundancy). The app combines this with
the user\'s Google identity and the current timestamp, then sends it to
a Google Apps Script endpoint. That endpoint appends a row to the
existing Legacy Operations Spreadsheet, right alongside Google Form
submissions. The admin review process continues unchanged. The Google
Form remains operational as a fallback.

**2. Goals and Non-Goals**

**2.1 MVP Goals**

Enable Googlers to submit parking validation via OCR scan in under 10
seconds.

Write submissions to the existing Google Sheet without breaking the
legacy workflow.

Authenticate users via Google Sign-In and auto-attach identity to every
submission.

Provide clear submission confirmation so users trust the system.

Queue submissions offline so parking garages with poor signal do not
block the flow.

**2.2 Non-Goals (Explicitly Out of MVP Scope)**

  ------------------------ ------------------------------------ ----------
  **Feature**              **Why Not MVP**                      **When**

  Push notifications       Email notifications from admin       v2
                           workflow already exist               

  In-app                   Requires polling or push infra.      v2
  approval/rejection       Email covers it.                     
  status                                                        

  Multi-site support (RDU, Each site may have different ticket  v2
  Waterloo)                formats and sheets                   

  Guest/visitor validation Removed per v2.1 scope reduction.    v2
                           MVP is self-only.                    

  Barcode scanning         Ticket number is printed in plain    v2
                           text. OCR is sufficient.             

  Admin dashboard          Admins continue using the            v2
                           spreadsheet.                         

  Cloud Vision API         ML Kit on-device is sufficient. Keep v2
  fallback                 it simple.                           

  History screen with full MVP shows today\'s submission only.  v2
  log                                                           

  Second-entry business    v2 will require a reason for a 2nd   v2
  justification flow       daily validation                     

  Replacing the Google     It stays. It is the fallback.        Never
  Form                                                          
  ------------------------ ------------------------------------ ----------

**3. User Persona**

**\"Rushed Commuter Adam\"**

  ----------------- -----------------------------------------------------
  **Attribute**     **Detail**

  Role              Google Employee (Noogler / PM) at 1105 West
                    Peachtree, Atlanta

  Frequency         Parks daily. Validates daily.

  JTBD              Scan my ticket the moment I park so validation is
                    handled and I forget about it

  Core Pain         Forgetting the 5 PM cutoff. Manual data entry into
                    Google Form. \$20 penalty.

  Tech Comfort      High. Uses mobile apps daily. Comfortable with camera
                    permissions.

  Context of Use    Standing by their car in an underground parking
                    garage. Possibly poor lighting. Possibly weak cell
                    signal.

  Acceptance        \"If I scanned it and got the green check, I trust
  Criteria          it. I should never have to think about parking again
                    that day.\"
  ----------------- -----------------------------------------------------

**4. User Flows**

**4.1 First-Time User**

User downloads gPark via internal distribution (managed Play Store /
TestFlight).

App launches to a Google Sign-In screen with gPark logo and tagline:
\"Park. Scan. Done.\"

User taps \"Sign in with Google\" and authenticates with \@google.com
account.

App extracts: display name, email, LDAP (email prefix before
\@google.com).

App requests camera permission: \"gPark needs camera access to scan your
parking ticket.\"

If granted: Home screen loads. Empty state: illustration + \"Ready to
Scan.\"

If denied: Home screen loads with persistent banner: \"Camera access is
required to scan tickets. Tap to enable in Settings.\"

**4.2 Returning User**

App launches. Checks for valid auth token.

Valid token: Home screen loads immediately.

Expired token: Silent refresh. If fails: Sign-In screen.

If offline queued items exist: banner shows \"X submissions waiting to
sync.\"

**4.3 Ticket Scan (Happy Path)**

User taps FAB (\"Scan Ticket\").

Camera viewfinder opens. Overlay guide: \"Align your parking ticket in
the frame.\"

User captures image of their AAA Parking stub.

App runs ML Kit Text Recognition on the image (on-device, no network
needed).

App applies regex /\\b\\d{7}\\b/g to all extracted text.

Two identical 7-digit matches found (top and bottom of ticket): HIGH
confidence.

App shows confirmation card: ticket number (large, bold), user name,
timestamp, \"Atlanta\". 5-second auto-submit countdown. \"Edit\" and
\"Cancel\" buttons visible.

Haptic feedback: strong vibration on match lock.

Countdown completes. App sends POST to Apps Script endpoint.

HTTP 200 returned. App shows success screen: green checkmark,
\"Submitted. You are all set.\" Subtext: \"Approval status will be sent
to your email.\"

Auto-dismiss to Home after 5 seconds. Today\'s submission card visible.

**4.4 OCR Low Confidence / Failure**

Regex finds zero or conflicting 7-digit numbers.

App shows Manual Review screen: captured image at top. Editable text
field pre-filled with best guess (or empty). Helper text: \"We could not
read the ticket clearly. Please type or correct the ticket number
below.\"

Input validation: exactly 7 digits. Real-time feedback.

User types or corrects number. Taps \"Submit.\"

Flow continues from step 9 of Happy Path.

**4.5 Submission Failure**

Apps Script returns non-200 or request times out (30s).

App shows: \"Submission failed. Saved to your device. We will retry
automatically.\"

Submission stored in local queue.

Retry logic: max 3 attempts, backoff 30s / 2min / 10min.

If all retries fail: persistent banner with \"Retry\" button + \"Use
Google Form\" link.

**4.6 Offline Mode**

No network (common in parking garages).

User can still scan. OCR runs on-device.

On submit: app queues locally. Card shows: \"Saved to Device. Waiting
for Internet.\" (cloud_off icon).

Network returns: app auto-submits queued items.

Card updates to \"Submitted. You are all set.\" on success.

**5. Functional Requirements**

**FR-1: Google Sign-In Authentication**

  ----------------- -----------------------------------------------------
  **Attribute**     **Specification**

  Description       Authenticate via Google Sign-In. Restrict to
                    \@google.com.

  Inputs            Google account credentials (handled by SDK).

  Outputs           Display name, email, LDAP (email prefix), auth token.

  Behavior          First launch: Sign-In button. Subsequent: silent
                    sign-in. Expired: silent refresh, fallback to
                    Sign-In. Reject non-@google.com: \"Please sign in
                    with your Google corporate account.\"

  Edge Cases        Token expires mid-submit: queue locally, refresh,
                    retry. Sign out: clear local data and queue. Multiple
                    accounts on device: account chooser.

  OAuth Scopes      email, profile. No Sheets scope (Apps Script handles
                    sheet access).

  Flutter Package   google_sign_in
  ----------------- -----------------------------------------------------

**FR-2: Camera Capture**

  ----------------- -----------------------------------------------------
  **Attribute**     **Specification**

  Description       Capture image of AAA Parking ticket via device
                    camera.

  Inputs            Camera hardware.

  Outputs           JPEG image, max 1920x1080.

  Behavior          Viewfinder with alignment overlay. Tap to capture.
                    Auto-focus on. Flash toggle (default: auto). Image
                    stored in app memory only (not gallery).

  Edge Cases        Permission denied: explanation screen + link to
                    Settings. Hardware failure: manual entry fallback.
                    Poor lighting: flash toggle + downstream OCR handles
                    it.

  Flutter Package   camera or image_picker
  ----------------- -----------------------------------------------------

**FR-3: OCR Text Extraction (Ticket-Specific)**

  ----------------- -----------------------------------------------------
  **Attribute**     **Specification**

  Description       Extract 7-digit ticket number from captured image
                    using on-device OCR.

  Inputs            JPEG image of AAA Parking ticket.

  Outputs           Ticket number (String, 7 digits) + confidence level
                    (high/medium/low).

  OCR Engine        Google ML Kit Text Recognition (on-device). No cloud
                    calls.

  Parsing Logic     1\) Run ML Kit on image. 2) Collect all recognized
                    text. 3) Apply regex /\\b\\d{7}\\b/g. 4) Deduplicate
                    matches. 5) If 2+ identical matches: confidence =
                    high. If 1 match: confidence = medium. If 0 matches:
                    confidence = low. If 2+ different matches: confidence
                    = ambiguous.

  Auto-Submit Rules High confidence: 5-second auto-submit countdown.
                    Medium confidence: 5-second countdown (same UX,
                    slightly more cautious messaging). Low confidence:
                    route to Manual Review. Ambiguous: show candidates
                    for user selection.

  Edge Cases        No text at all: \"No text found. Try better lighting
                    or enter manually.\" Non-ticket scanned: regex finds
                    no 7-digit number, routes to manual. Partial number
                    (6 digits): no match, manual review. Date numbers
                    (121625): 6 digits, no match. Time (0739): 4 digits,
                    no match.

  Flutter Package   google_mlkit_text_recognition
  ----------------- -----------------------------------------------------

> WHY THIS WORKS: The AAA Parking ticket has the number printed twice in
> large monospace font with high contrast. The 7-digit length is unique
> on the ticket (dates are 6 digits, times are 4 digits). Two identical
> matches from top and bottom of the ticket provide built-in
> verification without relying on ML Kit\'s raw confidence score.

**FR-4: Submission to Google Sheet via Apps Script**

  ----------------- -----------------------------------------------------
  **Attribute**     **Specification**

  Description       Submit validation data to Legacy Operations
                    Spreadsheet via Apps Script Web App.

  Inputs            JSON payload: {ticket_number, user_email,
                    validation_type, timestamp, submission_source,
                    ocr_confidence, user_name, user_ldap,
                    office_location}

  Outputs           HTTP response: {status:
                    \"success\"\|\"duplicate\"\|\"error\", message:
                    \"\...\"}

  Behavior          App sends POST to Apps Script URL. Script validates
                    payload, checks for duplicate (same ticket_number +
                    same date in sheet), appends row to columns A-D
                    minimum (A: timestamp, B: email, C: \"For myself\",
                    D: ticket number). Returns response.

  Duplicate         Apps Script scans Column D for matching ticket number
  Detection         where Column A is same date. If found: {status:
                    \"duplicate\"}. Row is NOT appended.

  Retry Logic       Max 3 retries. Backoff: 30s, 2min, 10min. After final
                    failure: show Google Form fallback.

  Security          Apps Script deployed as \"Execute as: me\" with
                    access \"Anyone within google.com\". Spreadsheet ID
                    stored in Script Properties, not hardcoded. No sheet
                    credentials on device.

  Quarterly         Apps Script reads SPREADSHEET_ID from Script
  Rotation          Properties. On quarterly rotation, admin updates this
                    value. Staleness detection warns if ACTIVE_QUARTER
                    does not match calendar quarter.

  Timeout           30 seconds. After timeout, queue locally.
  ----------------- -----------------------------------------------------

**FR-5: Offline Queue**

  ----------------- -----------------------------------------------------
  **Attribute**     **Specification**

  Description       Store submissions locally when offline and sync when
                    network returns.

  Behavior          No network: serialize payload to SharedPreferences.
                    Show \"Saved to Device\" card. On network
                    restoration: auto-retry in FIFO order. On success:
                    update card to \"Submitted.\" On app open: check
                    queue, attempt sync.

  Edge Cases        App uninstalled with queue: data lost, user should
                    use Form. Queue \> 24 hours old: submit anyway, flag
                    late_submission. Device storage full: error + Google
                    Form link.

  Max Queue         10 items.

  Flutter Packages  connectivity_plus, shared_preferences
  ----------------- -----------------------------------------------------

**FR-6: Submission Confirmation**

  ----------------- -----------------------------------------------------
  **Attribute**     **Specification**

  Description       Provide clear visual confirmation of submission
                    status.

  Success           Green checkmark animation. Ticket number displayed.
                    \"Submitted. You are all set.\" Subtext: \"Approval
                    status will be sent to your email.\" Auto-dismiss to
                    Home after 5s.

  Success + Stale   Same green checkmark. PLUS yellow info banner below:
  Quarter           \"Your submission was saved, but the system may need
                    a quarterly update. If your validation is not
                    processed, contact your building admin.\" Triggered
                    when response includes warning: \"stale_quarter\".

  Duplicate         Yellow warning icon. \"This ticket was already
                    submitted today.\" No row appended.

  Error             Red error icon. \"Submission failed.\" Retry button +
                    Google Form fallback link.
  ----------------- -----------------------------------------------------

**FR-7: Manual Ticket Entry**

  ----------------- -----------------------------------------------------
  **Attribute**     **Specification**

  Description       Allow manual ticket number entry when OCR fails.

  Input Validation  Exactly 7 digits. Numeric only. Real-time validation
                    below field.

  Keyboard          Numeric keypad.

  Actions           \"Submit\" (enabled when valid), \"Rescan\" (back to
                    camera), \"Cancel\" (back to Home).

  Edge Cases        Paste from clipboard: accept and validate. Leading
                    zeros preserved (ticket numbers start with 0).
  ----------------- -----------------------------------------------------

**6. Data Model**

**6.1 Submission Payload (App to Apps Script)**

The app sends all fields. The Apps Script writes columns A-D to the Form
Responses tab and logs the extended fields to a separate \"gPark
Metadata\" sheet for analytics.

  ------------------- ---------- ---------- ------------ --------------------------------
  **Field**           **Type**   **Req?**   **Source**   **Destination**

  ticket_number       String (7  Yes        OCR or       Form Responses Col D
                      digits)               manual       

  user_email          String     Yes        Google       Form Responses Col B
                                            Sign-In      

  validation_type     String     Yes        Hardcoded    Form Responses Col C: \"For
                                                         myself\"

  timestamp           String     Yes        Device clock Form Responses Col A (server
                      (ISO 8601)                         override)

  submission_source   String     Yes        Hardcoded    gPark Metadata sheet: \"gPark
                                                         App\"

  ocr_confidence      String     Yes        OCR logic    gPark Metadata sheet:
                                                         \"high\"/\"medium\"/\"manual\"

  user_name           String     Yes        Google       gPark Metadata sheet
                                            Sign-In      

  user_ldap           String     Yes        Email prefix gPark Metadata sheet

  office_location     String     Yes        Hardcoded    gPark Metadata sheet:
                                                         \"Atlanta\"
  ------------------- ---------- ---------- ------------ --------------------------------

**6.2 Local Queue Entry Schema**

  ----------------- ----------------- -----------------------------------
  **Field**         **Type**          **Description**

  id                String (UUID)     Unique local ID for queue
                                      management

  payload           JSON String       Full submission payload (6.1)

  status            Enum: queued \|   Sync status
                    submitted \|      
                    failed            

  retry_count       Int (max 3)       Number of attempts

  created_at        String (ISO 8601) Creation time

  last_retry_at     String \| null    Last retry time
  ----------------- ----------------- -----------------------------------

**7. System Architecture**

**7.1 Three-Layer Model**

  ------------- ----------------------------------- -------------------------
  **Layer**     **Responsibilities**                **Does NOT Do**

  Flutter App   Camera capture, on-device OCR,      Direct sheet access,
                ticket number parsing, user auth,   admin logic, email, push
                local queue, UI, POST to Apps       notifications
                Script                              

  Apps Script   Receive POST, validate payload,     OCR, auth verification
  Web App       check duplicates, append row to     (trusts payload from
                sheet, return response              \@google.com-restricted
                                                    deployment), UI

  Google Sheet  System of record. Stores all        Nothing changes. Does not
                submissions. Admin reviews,         know gPark exists.
                approves, rejects. Existing         
                triggers send email.                

  Google Form   Fallback. Writes to same sheet.     Nothing changes.
                Always available.                   
  ------------- ----------------------------------- -------------------------

**7.2 Data Flow**

User parks at 1105 West Peachtree. Takes AAA Parking ticket.

Opens gPark. Taps \"Scan Ticket.\"

Captures photo of ticket.

ML Kit (on-device) extracts text. App regex finds 7-digit ticket
number(s).

If high/medium confidence: auto-submit countdown. If low: manual entry.

App POSTs to Apps Script: {ticket_number: \"0443044\", user_email:
\"adame@google.com\", validation_type: \"For myself\", \...}

Apps Script checks for duplicate in column D for today\'s date. Not
found: appends row. Returns {status: \"success\"}.

App shows green checkmark. Done.

Admin reviews sheet row (same as today). Marks Approved/Denied in Column
U.

Existing Apps Script trigger sends approval/rejection email to user.

**7.3 Authentication Model**

Flutter package: google_sign_in.

OAuth scopes: email, profile.

Identity fields (name, email, LDAP) are sent in the JSON payload. No
Google ID token sent to Apps Script.

Apps Script Web App restricted to \@google.com domain. Only
authenticated Googlers can reach it.

Token persistence handled by google_sign_in package. Users stay signed
in.

**8. UX Requirements**

**8.1 Design System**

Material 3, Google enterprise styling.

Primary: Google Blue #1A73E8. Success: #34A853. Error: #D93025. Warning:
#F9AB00.

Surface: #FFFFFF. On-surface: #202124. Secondary text: #5F6368.

Font: Google Sans or Roboto. Mono (ticket numbers): Roboto Mono.

**8.2 Screens**

**Screen 1: Sign-In**

  ----------------- -----------------------------------------------------
  **Element**       **Spec**

  Layout            Centered. gPark logo at top. \"Park. Scan. Done.\"
                    tagline.

  Action            Google Sign-In button (standard SDK button).

  Error             Non-@google.com: \"Please sign in with your Google
                    corporate account.\" Network: \"Check your
                    connection.\"

  Loading           Button shows spinner during auth.
  ----------------- -----------------------------------------------------

**Screen 2: Home Dashboard**

  ----------------- -----------------------------------------------------
  **Element**       **Spec**

  Top Bar           \"gPark\" title. User avatar with sign-out in
                    overflow menu.

  Empty State       Illustration + \"Ready to Scan\" (no submissions
                    today).

  Today Card        Ticket number, timestamp, status: \"Submitted\"
                    (hourglass) or \"Queued\" (cloud_off).

  Queue Banner      \"X submissions waiting to sync\" if offline items
                    exist.

  FAB               Extended FAB bottom-right: camera icon + \"Scan
                    Ticket\".

  Footer            \"By submitting, I attest this is for valid business
                    use.\"
  ----------------- -----------------------------------------------------

**Screen 3: Camera / Scan**

  ----------------- -----------------------------------------------------
  **Element**       **Spec**

  Viewfinder        Full-screen camera. Semi-transparent overlay with
                    rectangle guide: \"Align your parking ticket.\"

  Controls          Capture button (center-bottom). Flash toggle
                    (top-right). Close (top-left).

  Processing        After capture: \"Reading ticket\...\" spinner while
                    OCR runs.
  ----------------- -----------------------------------------------------

**Screen 4: Auto-Submit Confirmation**

  ----------------- -----------------------------------------------------
  **Element**       **Spec**

  Card              Ticket number in large Roboto Mono bold. User name.
                    Timestamp. \"Atlanta.\"

  Countdown         5-second animated progress bar. \"Submitting in
                    5\...\"

  Actions           \"Edit\" (goes to Manual Review). \"Cancel\" (back to
                    Home, discards).

  Haptic            Strong vibration on ticket number lock.

  Confidence Label  Small badge: \"Matched 2x\" (high) or \"Matched 1x\"
                    (medium).
  ----------------- -----------------------------------------------------

**Screen 5: Manual Review**

  ----------------- -----------------------------------------------------
  **Element**       **Spec**

  Image             Captured ticket photo at top, scrollable.

  Input             Text field, numeric keyboard, pre-filled with OCR
                    best guess. Validation: exactly 7 digits.

  Helper Text       \"We could not read the ticket clearly. Please type
                    or correct the number below.\"

  Actions           \"Submit\" (enabled when valid), \"Rescan\" (camera),
                    \"Cancel\" (Home).

  Ambiguous State   If multiple different 7-digit numbers found: show
                    them as tappable chips. User picks one or types
                    manually.
  ----------------- -----------------------------------------------------

**Screen 6: Success**

  ----------------- -----------------------------------------------------
  **Element**       **Spec**

  Animation         Green checkmark (animated).

  Copy              \"Submitted. You are all set.\" Ticket number
                    displayed. Subtext: \"Approval status will be sent to
                    your email.\"

  Stale Quarter     If response contains warning: \"stale_quarter\":
  Banner            yellow info banner below success copy: \"Your
                    submission was saved, but the system may need a
                    quarterly update. If your validation is not
                    processed, contact your building admin.\"

  Dismiss           Auto-return to Home in 5s. Tap anywhere to dismiss
                    early.
  ----------------- -----------------------------------------------------

**Screen 7: Error**

  ----------------- -----------------------------------------------------
  **Element**       **Spec**

  Icon              Red error icon.

  Copy              \"Submission failed. Saved to your device. We will
                    retry automatically.\"

  Actions           \"Retry Now\" button. \"Use Google Form\" link.
                    \"Back to Home.\"
  ----------------- -----------------------------------------------------

**8.3 Accessibility (WCAG 2.1 AA)**

48x48dp minimum touch targets.

Status via color + icon + text (color-blind safe).

Focus moves to error card on rejection.

Screen reader labels on all buttons and cards.

4.5:1 minimum contrast for text.

**9. Failure Modes and Edge Cases**

  -------------------- ---------------- ----------------------- ----------------------
  **Scenario**         **Detection**    **User Experience**     **System Behavior**

  OCR: no text found   ML Kit returns   \"No text found. Try    Log event.
                       empty            better lighting or      
                                        enter manually.\"       

  OCR: wrong number    User sees wrong  Tap \"Edit\" during     Manual review flow.
  captured             number on        countdown to correct.   
                       confirmation                             

  OCR: blurry image    Zero 7-digit     Routes to Manual        Log low-confidence
                       matches          Review.                 event.

  OCR: non-ticket      Regex: no        Routes to Manual Review Log event.
  scanned              7-digit match    (empty field).          

  OCR: multiple        Regex: 2+        Show candidates as      User selects correct
  different numbers    distinct 7-digit tappable chips.         one.
                       matches                                  

  Duplicate submission Apps Script      \"This ticket was       Row NOT appended.
                       checks sheet     already submitted       
                                        today.\"                

  Network failure      HTTP timeout     \"Saved to device. Will Queue locally. Retry
                       (30s) or error   retry.\"                3x.

  Apps Script quota    HTTP 429         Same as network         Queue + longer
  exceeded                              failure.                backoff.

  Sheet                Apps Script      \"System temporarily    Log alert.
  locked/protected     error response   unavailable. Use Google 
                                        Form.\"                 

  Camera permission    OS permission    Banner: \"Camera        FAB disabled.
  denied               check            required. Tap to        
                                        enable.\"               

  Auth token expired   401 or token     Silent refresh. If      Queue submission,
                       check            fails: Sign-In screen.  refresh, retry.

  App killed           Incomplete       On next launch: check   Queue persists.
  mid-submission       request          queue, retry.           

  Non-@google.com      Google Sign-In   \"Please sign in with   Block access.
  account              returns other    your corporate          
                       domain           account.\"              

  Multiple tickets in  User initiates   Normal flow. Each scan  Separate rows.
  one day              2nd scan         is independent.         

  Damaged/unreadable   OCR fails + user \"Unable to read? Use   Fallback links.
  ticket               cannot type      the Google Form or      
                                        contact reception.\"    

  Ticket number has    Ticket starts    Preserved as string. No Stored as string in
  leading zeros        with 0 (e.g.,    integer conversion.     sheet.
                       0443044)                                 

  Stale quarterly      Apps Script      Submission succeeds.    Row still written.
  spreadsheet          detects          Yellow banner: \"System Warning in response.
                       ACTIVE_QUARTER   may need a quarterly    
                       mismatch         update.\"               
  -------------------- ---------------- ----------------------- ----------------------

**10. Success Metrics**

  ------------------ -------------------- ------------- -----------------------
  **Metric**         **Definition**       **Target**    **Why It Matters**

  Submission Success (Successful gPark    \> 95%        Core reliability. If
  Rate               submissions / Total                this is low, the app is
                     attempts) x 100                    broken.

  Mean               Time between garage  \< 10 min     Confirms arrival-based
  Time-to-Validate   entry (ticket        (down from    behavioral shift.
                     timestamp, if        \~8 hrs)      
                     captured) and                      
                     submission                         

  OCR Auto-Submit    (Scans that          \> 80%        Measures OCR value. If
  Rate               auto-submitted                     low, users are
                     without manual                     constantly correcting.
                     correction / Total                 
                     scans) x 100                       

  Duplicate          (Duplicates flagged  \< 5%         High = users do not
  Submission Rate    / Total submissions)               trust the app.
                     x 100                              Double-submitting.

  Google Form        (Form submissions    \< 10% after  High = app is not
  Fallback Rate      from app users /     month 1       reliable enough.
                     Total from those                   
                     users) x 100                       

  Pilot Adoption     (Active gPark users  \> 60% in 2   Are people actually
                     / 50 eligible) x 100 weeks         using it?
  ------------------ -------------------- ------------- -----------------------

**10.1 Hypothesis**

IF we provide a mobile scanning interface that shifts validation from
departure to arrival, THEN missed validations (out-of-pocket payments +
emergency gate assists) will decrease by \>50%, BECAUSE we are removing
the cognitive load of \"remembering later\" and closing the time gap
between parking and validating.

**11. Implementation Guidance**

This section is written directly for the AI coding agent building this
app. Follow these rules.

**11.1 Stack**

  -------------- ------------------------------- ------------------------------------
  **Layer**      **Technology**                  **Package / Notes**

  Framework      Flutter (Dart)                  iOS + Android. Single codebase.

  State Mgmt     Riverpod                        Simple, testable. No Bloc for MVP.

  OCR            google_mlkit_text_recognition   On-device only.

  Camera         camera                          For viewfinder. image_picker as
                                                 simpler fallback.

  Auth           google_sign_in                  Standard Google Sign-In for Flutter.

  HTTP           http or dio                     POST to Apps Script.

  Storage        shared_preferences              Offline queue (JSON serialized
                                                 list).

  Connectivity   connectivity_plus               Detect online/offline.

  Backend        Google Apps Script              doPost(e) Web App.

  Database       Google Sheets                   Existing sheet. No structural
                                                 changes.
  -------------- ------------------------------- ------------------------------------

**11.2 Project Structure**

lib/

main.dart

app.dart

screens/

sign_in_screen.dart

home_screen.dart

camera_screen.dart

confirmation_screen.dart

manual_review_screen.dart

success_screen.dart

error_screen.dart

services/

auth_service.dart // Google Sign-In wrapper

ocr_service.dart // ML Kit + regex parsing

submission_service.dart // HTTP POST to Apps Script

queue_service.dart // Offline queue management

connectivity_service.dart // Network state listener

models/

submission.dart // Submission data class

user_profile.dart // Name, email, LDAP

ocr_result.dart // Ticket number + confidence

providers/

auth_provider.dart

submission_provider.dart

connectivity_provider.dart

utils/

ticket_parser.dart // Regex: /\\b\\d{7}\\b/g

constants.dart // URLs, config values

**11.3 Seven Rules**

Rule 1: Never write directly to Google Sheets.

All submissions go through the Apps Script endpoint. The app does not
import the Google Sheets API. The app does not know the spreadsheet ID.

Rule 2: OCR is on-device only.

google_mlkit_text_recognition. No Cloud Vision API calls. This ensures
scanning works in underground garages with no signal.

Rule 3: Every submission must have a fallback.

Network fail? Queue locally. Queue fail? Show Google Form link. User
must never be stuck with no way to validate.

Rule 4: URLs are constants.

Apps Script URL and Google Form URL live in utils/constants.dart. Not
hardcoded anywhere else.

Rule 5: Ticket parsing is isolated.

The regex /\\b\\d{7}\\b/g lives in utils/ticket_parser.dart. It takes a
raw OCR string and returns a TicketParseResult: {numbers:
List\<String\>, confidence: high\|medium\|low\|ambiguous}. This is
testable and adjustable without touching OCR or submission code.

Rule 6: The app never makes approval decisions.

Submit data. Show confirmation. Done. No \"Approved\" or \"Rejected\"
UI. That is email-delivered by the admin workflow.

Rule 7: Auth drives navigation.

Not authenticated? Sign-In screen. Authenticated? Home. That is the only
root-level routing logic.

**11.4 Apps Script Endpoint**

Claude Code must build this as part of the project. It is a standalone
.gs file deployable as a Web App.

doPost(e) Specification

Method: POST

Content-Type: application/json

Deploy as: Web App. Execute as: me. Access: Anyone within google.com.

Request Body

{

\"ticket_number\": \"0443044\",

\"user_email\": \"adame@google.com\",

\"validation_type\": \"For myself\",

\"timestamp\": \"2026-02-16T08:32:00-05:00\",

\"submission_source\": \"gPark App\",

\"ocr_confidence\": \"high\",

\"user_name\": \"Adam E\",

\"user_ldap\": \"adame\",

\"office_location\": \"Atlanta\"

}

Responses

Success: {\"status\": \"success\", \"row\": 142}

Success+Stale: {\"status\": \"success\", \"row\": 142, \"warning\":
\"stale_quarter\",

\"message\": \"Submitted, but system may need quarterly update.\"}

Duplicate: {\"status\": \"duplicate\", \"message\": \"Ticket 0443044
already submitted on 2026-02-16\"}

Error: {\"status\": \"error\", \"message\": \"Sheet write failed\"}

doPost Logic

Parse JSON from e.postData.contents.

Validate required fields: ticket_number, user_email, validation_type.

Read SPREADSHEET_ID and ACTIVE_QUARTER from Script Properties.

Run staleness check: compare ACTIVE_QUARTER to current calendar quarter.
If stale, continue but flag response with warning.

Open spreadsheet by ID. Get \"Form Responses\" tab (SHEET_TAB_NAME
property).

Scan Column D (Validation Ticket Number) for matching ticket_number
where Column A date matches today. If found: return {status:
\"duplicate\"}.

Append row: \[server_timestamp, user_email, \"For myself\",
ticket_number\].

Return {status: \"success\", row: new_row_number} (with optional warning
field if stale).

Wrap in try/catch. On error: return {status: \"error\", message:
e.toString()}.

> **SHEET TAB NAME:** The production spreadsheet tab is named \"Form
> Responses\" (visible at the bottom of the screenshot). The Apps Script
> must target this specific tab by name.

**11.5 Quarterly Spreadsheet Rotation**

A new Google Spreadsheet is created every quarter. The spreadsheet ID
changes. The tab structure and column schema remain the same. This is
the most operationally sensitive detail in the system.

**How It Works Today**

Admin creates a new spreadsheet from the standard template.

The new spreadsheet has a \"Form Responses\" tab with the same column
structure (A: Timestamp, B: Email Address, C: Validation Type, D: Ticket
Number, etc.).

The Google Form is repointed to the new spreadsheet.

The old spreadsheet is archived.

**What gPark Needs**

When the quarterly rotation happens, one additional step is required:
update the spreadsheet ID in Apps Script. Without this, gPark
submissions silently write to the old (archived) sheet. Users see
\"success\" but their validation is not in the active spreadsheet. That
is a \$20-per-person failure mode.

**Implementation: Script Properties**

The Apps Script stores the active spreadsheet ID as a Script Property,
not hardcoded in code.

// In Apps Script: doPost reads the ID from Script Properties

function doPost(e) {

const props = PropertiesService.getScriptProperties();

const sheetId = props.getProperty(\'SPREADSHEET_ID\');

const activeQuarter = props.getProperty(\'ACTIVE_QUARTER\');

const ss = SpreadsheetApp.openById(sheetId);

const sheet = ss.getSheetByName(\'Form Responses\');

// \... rest of logic

}

**Script Properties (Initial Configuration)**

  --------------------- ---------------------------------------------- -----------------
  **Property Key**      **Value**                                      **Updated When**

  SPREADSHEET_ID        1Jwb-H_mc0v01Qh1Yakn72uhU_0lxg0EPV9gg0VKyWeU   Every quarter
                                                                       (mandatory)

  ACTIVE_QUARTER        Q1 2026                                        Every quarter
                                                                       (mandatory)

  SHEET_TAB_NAME        Form Responses                                 Only if template
                                                                       changes tab name
  --------------------- ---------------------------------------------- -----------------

gPark Metadata Sheet

Extended fields (submission_source, ocr_confidence, user_name,
user_ldap, office_location) are logged to a separate \"gPark Metadata\"
tab. Two options for where this tab lives:

**Option A: In the rotating spreadsheet.** The Apps Script creates the
tab if it does not exist on first write. Pro: all data in one place.
Con: metadata rotates with the quarterly sheet.

**Option B: In a separate persistent spreadsheet.** A second
METADATA_SPREADSHEET_ID Script Property. Pro: analytics data persists
across quarters. Con: one more thing to manage.

> **RECOMMENDATION:** Option A for MVP. Keep it simple. The metadata tab
> is created automatically by the Apps Script. When the quarterly
> rotation happens, the old metadata tab stays with the archived
> spreadsheet. If persistent analytics become important in v2, migrate
> to Option B.

**Staleness Detection (Safety Net)**

To prevent the silent failure of writing to an archived sheet, the Apps
Script performs a staleness check on every request.

// Staleness check: verify ACTIVE_QUARTER matches current calendar
quarter

function getCalendarQuarter() {

const now = new Date();

const q = Math.ceil((now.getMonth() + 1) / 3);

return \'Q\' + q + \' \' + now.getFullYear();

}

// In doPost, BEFORE writing, set a flag (do NOT return early):

const activeQuarter = props.getProperty(\'ACTIVE_QUARTER\');

const currentQuarter = getCalendarQuarter();

const isStale = (activeQuarter !== currentQuarter);

// \... proceed with duplicate check and row append as normal \...

// AFTER successful write, include warning in response if stale:

const response = { status: \'success\', row: newRowNumber };

if (isStale) {

response.warning = \'stale_quarter\';

response.message = \'Submitted, but system may need quarterly update.\';

}

return ContentService.createTextOutput(JSON.stringify(response))

.setMimeType(ContentService.MimeType.JSON);

**App Behavior on Stale Quarter Warning**

If the Apps Script response includes \"warning\": \"stale_quarter\":

The app still shows the green success screen (the submission was
written).

Below the confirmation, show a yellow info banner: \"Your submission was
saved, but the system may need a quarterly update. If your validation is
not processed, contact your building admin.\"

This ensures the user is not blocked while also surfacing that something
may be off.

**Quarterly Rotation Runbook**

This procedure must be performed at the start of each quarter. Add it to
the admin\'s existing quarterly rotation checklist.

  ---------- ------------------------------- ---------------- ------------------
  **Step**   **Action**                      **Who**          **Time**

  1          Create new spreadsheet from     Admin (existing  Already done
             quarterly template              process)         

  2          Repoint Google Form to new      Admin (existing  Already done
             spreadsheet                     process)         

  3          Copy the new spreadsheet ID     Admin            10 seconds
             from the browser URL bar                         

  4          Open Apps Script editor \>      Admin            20 seconds
             Project Settings \> Script                       
             Properties                                       

  5          Update SPREADSHEET_ID to the    Admin            10 seconds
             new ID                                           

  6          Update ACTIVE_QUARTER to the    Admin            10 seconds
             current quarter (e.g., \"Q2                      
             2026\")                                          

  7          Test: open gPark, scan a test   Admin            1 minute
             ticket, verify the row appears                   
             in the new spreadsheet                           
  ---------- ------------------------------- ---------------- ------------------

> TOTAL ADDED EFFORT: Under 2 minutes per quarter. Steps 1-2 are already
> part of the existing process. Steps 3-7 are new.

**Future Improvement (v2): Auto-Detection**

In v2, this manual step could be eliminated. Options:

The Apps Script could look up the active spreadsheet from a master
config spreadsheet that the admin already updates.

The Apps Script could search Drive for the most recent spreadsheet
matching a naming convention.

For MVP, the manual Script Property update is sufficient and low-risk.

**12. Open Items (Pre-Build Checklist)**

Updated with confirmed answers. All P0 items are resolved.

  -------- ---------------------------------------------- -------------- ------------------
  **\#**   **Item**                                       **Priority**   **Status**

  1        Column B header is Email Address               P0             CONFIRMED

  2        Columns E, F, G, H are formula-driven (no app  P0             CONFIRMED
           input needed)                                                 

  3        No required columns between I and S            P0             CONFIRMED

  4        Spreadsheet ID:                                P0             CONFIRMED
           1Jwb-H_mc0v01Qh1Yakn72uhU_0lxg0EPV9gg0VKyWeU                  

  5        New spreadsheet created every quarter (new ID, P0             CONFIRMED. Handled
           same schema)                                                  via Script
                                                                         Properties +
                                                                         staleness
                                                                         detection.

  6        Confirm appending a row triggers existing      P1 (test       Pending. Test in
           formulas (T, H, etc.)                          early)         first sprint.

  7        Google Sign-In client ID and config for        P1 (test       Pending
           internal app                                   early)         

  8        TestFlight / managed Play Store provisioning   P2 (pre-pilot) Pending

  9        Add gPark Script Property update to admin\'s   P2 (pre-pilot) Pending
           quarterly rotation checklist                                  
  -------- ---------------------------------------------- -------------- ------------------

**13. MVP Scope Boundary**

  ------------------------------ -------------------- --------------------
  **Feature**                    **MVP**              **v2**

  OCR ticket scanning (7-digit   Yes                  
  AAA Parking tickets)                                

  Manual ticket number entry     Yes                  

  Google Sign-In (@google.com)   Yes                  

  Submit to Sheet via Apps       Yes                  
  Script                                              

  Offline queue + auto-retry     Yes                  

  Submission confirmation        Yes                  
  (success/duplicate/error)                           

  Duplicate detection (same      Yes                  
  ticket + same day)                                  

  Google Form fallback link      Yes                  

  Attestation footer             Yes                  

  In-app approval/rejection                           Yes
  status                                              

  Push notifications                                  Yes

  Full submission history                             Yes

  Multi-site (RDU, Waterloo)                          Yes

  Guest validation                                    Yes

  Barcode scanning                                    Yes

  Admin dashboard                                     Yes

  2nd daily entry justification                       Yes
  flow                                                

  Cloud Vision API fallback                           Yes
  ------------------------------ -------------------- --------------------

**Appendices 1: Ticket Reference (From Production)**

The following is documented from a real AAA Parking ticket used at the
Atlanta (1105 West Peachtree) location. This is the primary reference
for OCR extraction logic.

**1.1 Physical Ticket Description**

  ----------------- -----------------------------------------------------
  **Attribute**     **Value**

  Type              Thermal-printed paper stub (white, standard receipt
                    width)

  Operator          AAA Parking

  Location          1105 West Peachtree (printed twice on ticket)

  Ticket Number     0443044 (7-digit numeric, printed at top AND bottom
                    of ticket)

  Date/Time         12/16/25 07:39AM (printed at top AND bottom, format:
                    MM/DD/YY HH:MMAM/PM)

  Barcodes          Two barcodes present (top and bottom). Not used for
                    MVP (OCR text extraction only).

  Other Text        \"Welcome To 1105 West Peachtree\", \"Please take
                    ticket with you\", \"STICKER HERE\", \"Thank you Have
                    a Wonderful Day!\"
  ----------------- -----------------------------------------------------

**1.2 OCR Extraction Target**

The primary extraction target is the ticket number: a 7-digit numeric
string.

> KEY INSIGHT: The ticket number appears twice on the stub (top and
> bottom). This is useful. If OCR captures either instance, the
> extraction succeeds. The regex should find ALL 7-digit numbers in the
> extracted text and deduplicate.

**Ticket Number Pattern**

Regex: /\\b\\d{7}\\b/g

Match examples: 0443044, 0441346, 0166993, 0651072, 0167006

Known prefixes observed in production data: 044xxxx, 016xxxx, 065xxxx

Length: Exactly 7 digits. No letters. No hyphens.

Secondary Extraction (Optional, Not Required for Submission)

Date/time from ticket: pattern
/\\d{2}\\/\\d{2}\\/\\d{2}\\s+\\d{2}:\\d{2}\[AP\]M/

This could be used in v2 to auto-populate a \"Garage Entry Timestamp\"
field for the Mean Time-to-Validate metric.

For MVP: extract ticket number only. Date/time is bonus data logged for
analytics.

**2.3 OCR Confidence Logic (Updated)**

Because the ticket number appears twice and is printed in large,
high-contrast monospace font, OCR reliability should be high. The
confidence logic:

Run ML Kit text recognition on captured image.

Apply regex /\\b\\d{7}\\b/g to all recognized text blocks.

Collect all 7-digit matches.

If two or more identical matches found (top + bottom of ticket): HIGH
confidence. Auto-submit.

If exactly one match found: MEDIUM confidence. Auto-submit with slightly
longer review window (5 seconds).

If zero matches found: LOW confidence. Route to manual entry.

If two or more DIFFERENT 7-digit numbers found: AMBIGUOUS. Show all
candidates for user selection.

> **UPDATE FROM v4.0:** The v4.0 PRD used a generic 0.90 confidence
> threshold from ML Kit. This is replaced with a smarter,
> ticket-specific approach. Two matching numbers = high confidence. This
> is more reliable than a raw ML Kit score because it uses the ticket\'s
> built-in redundancy.

**Appendices 2: Spreadsheet Schema (From Production)**

The following is documented from the actual production Google Sheet
(\"Form Responses\" tab). Some column headers are redacted in the
screenshot. Redacted columns are flagged for validation.

**2.1 Visible Column Map**

  --------- ---------------- -------------------- --------------- ------------------
  **Col**   **Header**       **Sample Values**    **Populated     **gPark Writes?**
                                                  By**            

  A         Timestamp        12/1/2025 4:06:48,   Google Form     Yes (server-side)
                             1/15/2025 13:39:49   (auto) / Apps   
                                                  Script          

  B         Email Address    adame@google.com     Google Form /   Yes
                             (redacted in         Apps Script     
                             screenshot,                          
                             confirmed by owner)                  

  C         Is this          \"For myself\" (all  Google Form /   Yes (hardcode
            validation       visible rows)        Apps Script     \"For myself\" for
            request for you                                       MVP)
            or a business                                         
            guest?                                                

  D         Validation       0441346, 0166993,    Google Form /   Yes (from OCR or
            Ticket Number    0441352, 777777,     Apps Script     manual entry)
                             000000                               

  E         (Redacted        01 Dec 2025, 15 Jan  Formula         No
            header)          2025, 30 Dec 1899    (confirmed)     (formula-driven)

  F         (Redacted        0441346, 0166993     Formula         No
            header)          (mirrors col D?)     (confirmed)     (formula-driven)

  G         (Redacted        01 Dec 2025 (mirrors Formula         No
            header)          col E?)              (confirmed)     (formula-driven)

  H         Month            December 2025,       Formula         No
                             January 2025         (confirmed)     (formula-driven)

  I-S       (Not visible in  No required app      Various         No
            screenshot)      inputs (confirmed)                   

  T         Eligibility      \"Enter Email in     Formula         No
            Recommendation   Column B\" (all                      (formula-driven)
                             rows)                                

  U         Admin Decision   Approved, Denied,    Admin (manual)  No
                             TBD                                  

  V         Admin: Ticket    Yes, No Ticket Not   Admin (manual)  No
                             F\[ound\], Needs                     
                             processing                           

  W         Click to send    Checkbox             Admin (manual)  No
            email to checked (TRUE/FALSE)                         
            recipients                                            

  X         (No visible      Yes                  Unknown         No
            header)                                               

  Y         (Action/Status   Sent on 2025-12-01,  System/Admin    No
            column)          Test-do not delete,                  
                             New Manual Entry                     
                             (button)                             
  --------- ---------------- -------------------- --------------- ------------------

**3.2 What gPark Must Write (Minimum Viable Row)**

Based on the visible schema, the Apps Script endpoint must append a row
that populates at minimum columns A through D. Columns E through H may
be formula-driven and auto-populate.

> CONFIRMED: Column B is Email Address. Columns E, F, G, H are
> formula-driven. No required columns between I and S. Appending a row
> to columns A-D is sufficient. Formulas auto-populate downstream
> columns.

**Minimum Write Payload**

  ----------------- ----------------- -----------------------------------
  **Sheet Column**  **Field**         **Value From gPark**

  A: Timestamp      timestamp         Server-side timestamp from Apps
                                      Script (Utilities.formatDate)

  B: Email Address  user_email        User\'s \@google.com email from
                                      Google Sign-In

  C: Validation     validation_type   Hardcoded: \"For myself\" (MVP is
  Type                                self-only)

  D: Validation     ticket_number     7-digit number from OCR or manual
  Ticket Number                       entry
  ----------------- ----------------- -----------------------------------

**Extended Payload (Logged to gPark Metadata Sheet)**

These fields are sent in the app payload but are NOT written to the Form
Responses tab. The Apps Script logs them to a separate \"gPark
Metadata\" tab for analytics and audit.

  ------------------- -------------------- --------------------------------
  **Field**           **Value**            **Purpose**

  submission_source   \"gPark App\"        Distinguish from Google Form
                                           submissions

  ocr_confidence      \"high\" /           Track OCR performance over time
                      \"medium\" /         
                      \"manual\"           

  user_name           Display name from    Audit trail
                      Google Sign-In       

  user_ldap           Email prefix (e.g.,  Audit trail
                      adame)               

  office_location     \"Atlanta\"          Multi-site prep for v2
                      (hardcoded for MVP)  
  ------------------- -------------------- --------------------------------

> WRITE STRATEGY (CONFIRMED): Apps Script writes to columns A-D on the
> \"Form Responses\" tab. Extended metadata (submission_source,
> ocr_confidence, user_name, user_ldap, office_location) is logged to a
> separate \"gPark Metadata\" tab in the same spreadsheet. This
> preserves the legacy schema while capturing analytics data.