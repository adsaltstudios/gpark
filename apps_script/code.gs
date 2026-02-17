/**
 * gPark Apps Script Backend
 *
 * Deployed as: Web App
 * Execute as: me
 * Access: Anyone within google.com
 *
 * Script Properties (set in Project Settings > Script Properties):
 *   SPREADSHEET_ID   - Active quarterly spreadsheet ID
 *   ACTIVE_QUARTER   - e.g., "Q1 2026"
 *   SHEET_TAB_NAME   - e.g., "Form Responses" (defaults to "Form Responses")
 */

/**
 * Health check endpoint.
 */
function doGet(e) {
  var props = PropertiesService.getScriptProperties();
  var activeQuarter = props.getProperty('ACTIVE_QUARTER');
  return jsonResponse({
    status: 'ok',
    quarter: activeQuarter,
    currentQuarter: getCalendarQuarter()
  });
}

/**
 * Main submission endpoint.
 * Receives parking validation data from the gPark app.
 */
function doPost(e) {
  try {
    // 1. Parse request body
    var data = JSON.parse(e.postData.contents);

    // 2. Validate required fields
    if (!data.ticket_number || !data.user_email || !data.validation_type) {
      return jsonResponse({
        status: 'error',
        message: 'Missing required fields: ticket_number, user_email, validation_type'
      });
    }

    // Validate ticket number format (exactly 7 digits)
    if (!/^\d{7}$/.test(data.ticket_number)) {
      return jsonResponse({
        status: 'error',
        message: 'Invalid ticket number format. Must be exactly 7 digits.'
      });
    }

    // 3. Read Script Properties
    var props = PropertiesService.getScriptProperties();
    var sheetId = props.getProperty('SPREADSHEET_ID');
    var activeQuarter = props.getProperty('ACTIVE_QUARTER');
    var tabName = props.getProperty('SHEET_TAB_NAME') || 'Form Responses';

    if (!sheetId) {
      return jsonResponse({
        status: 'error',
        message: 'SPREADSHEET_ID not configured in Script Properties.'
      });
    }

    // 4. Staleness check
    var currentQuarter = getCalendarQuarter();
    var isStale = (activeQuarter !== currentQuarter);

    // 5. Open spreadsheet and get Form Responses tab
    var ss = SpreadsheetApp.openById(sheetId);
    var sheet = ss.getSheetByName(tabName);

    if (!sheet) {
      return jsonResponse({
        status: 'error',
        message: 'Sheet tab "' + tabName + '" not found in spreadsheet.'
      });
    }

    // 6. Duplicate check: scan Column D for matching ticket on same date (Column A)
    var today = getTodayString();
    var dataRange = sheet.getDataRange().getValues();

    for (var i = 1; i < dataRange.length; i++) {
      var rowTimestamp = dataRange[i][0];
      if (!rowTimestamp) continue;

      var rowDate = formatDateToString(new Date(rowTimestamp));
      var rowTicket = String(dataRange[i][3]).trim();

      if (rowDate === today && rowTicket === data.ticket_number) {
        return jsonResponse({
          status: 'duplicate',
          message: 'Ticket ' + data.ticket_number + ' already submitted on ' + today
        });
      }
    }

    // 7. Append row to Form Responses tab (Columns A-D)
    var serverTimestamp = new Date();
    sheet.appendRow([
      serverTimestamp,           // Column A: Timestamp
      data.user_email,           // Column B: Email Address
      'For myself',              // Column C: Validation Type
      data.ticket_number         // Column D: Validation Ticket Number
    ]);
    var newRow = sheet.getLastRow();

    // 8. Log extended metadata to "gPark Metadata" tab
    logMetadata(ss, data, serverTimestamp);

    // 9. Build response
    var response = { status: 'success', row: newRow };
    if (isStale) {
      response.warning = 'stale_quarter';
      response.message = 'Submitted, but system may need quarterly update.';
    }

    return jsonResponse(response);

  } catch (err) {
    return jsonResponse({
      status: 'error',
      message: err.toString()
    });
  }
}

/**
 * Log extended metadata fields to a separate "gPark Metadata" tab.
 * Creates the tab with headers if it does not exist (Option A per PRD).
 */
function logMetadata(ss, data, timestamp) {
  var metaSheet = ss.getSheetByName('gPark Metadata');

  if (!metaSheet) {
    metaSheet = ss.insertSheet('gPark Metadata');
    metaSheet.appendRow([
      'Timestamp',
      'Email',
      'Ticket Number',
      'Source',
      'OCR Confidence',
      'User Name',
      'LDAP',
      'Office Location'
    ]);
  }

  metaSheet.appendRow([
    timestamp,
    data.user_email || '',
    data.ticket_number || '',
    data.submission_source || '',
    data.ocr_confidence || '',
    data.user_name || '',
    data.user_ldap || '',
    data.office_location || ''
  ]);
}

/**
 * Calculate the current calendar quarter string (e.g., "Q1 2026").
 */
function getCalendarQuarter() {
  var now = new Date();
  var q = Math.ceil((now.getMonth() + 1) / 3);
  return 'Q' + q + ' ' + now.getFullYear();
}

/**
 * Get today's date as a comparable string (M/d/yyyy).
 */
function getTodayString() {
  return Utilities.formatDate(
    new Date(),
    Session.getScriptTimeZone(),
    'M/d/yyyy'
  );
}

/**
 * Format a Date object to the same comparable string format.
 */
function formatDateToString(date) {
  return Utilities.formatDate(
    date,
    Session.getScriptTimeZone(),
    'M/d/yyyy'
  );
}

/**
 * Create a JSON response for ContentService.
 */
function jsonResponse(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
