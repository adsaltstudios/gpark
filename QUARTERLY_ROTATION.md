# gPark Quarterly Spreadsheet Rotation Runbook

Perform these steps at the start of each quarter. Steps 1-2 are part of the existing admin process. Steps 3-7 are new for gPark.

| Step | Action | Who | Time |
|------|--------|-----|------|
| 1 | Create new spreadsheet from quarterly template | Admin (existing process) | Already done |
| 2 | Repoint Google Form to new spreadsheet | Admin (existing process) | Already done |
| 3 | Copy the new spreadsheet ID from the browser URL bar | Admin | 10 seconds |
| 4 | Open Apps Script editor > Project Settings > Script Properties | Admin | 20 seconds |
| 5 | Update `SPREADSHEET_ID` to the new ID | Admin | 10 seconds |
| 6 | Update `ACTIVE_QUARTER` to the current quarter (e.g., "Q2 2026") | Admin | 10 seconds |
| 7 | Test: open gPark, scan a test ticket, verify the row appears in the new spreadsheet | Admin | 1 minute |

**Total added effort:** Under 2 minutes per quarter.

## What happens if this is missed

If `ACTIVE_QUARTER` is not updated, gPark will still write submissions (they will go to the old spreadsheet). Users will see a yellow warning banner: "Your submission was saved, but the system may need a quarterly update." This is a safety net, not a blocker.

## Script Properties Reference

| Property | Example Value | Updated When |
|----------|--------------|--------------|
| `SPREADSHEET_ID` | `1Jwb-H_mc0v01Qh1Yakn72uhU_0lxg0EPV9gg0VKyWeU` | Every quarter (mandatory) |
| `ACTIVE_QUARTER` | `Q1 2026` | Every quarter (mandatory) |
| `SHEET_TAB_NAME` | `Form Responses` | Only if template changes tab name |
