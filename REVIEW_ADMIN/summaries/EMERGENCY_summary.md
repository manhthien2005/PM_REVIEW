# EMERGENCY (Admin)

> Sprint 3-4 | JIRA: EP09-FallDetect, EP10-SOS | UC: UC010-UC015

## Purpose & Technique
- Admin dashboard for real-time monitoring and response to falls and SOS events.
- Features: active/history event tracking, date range filters, CSV/JSON export, and contact logging.
- Tech: Express with Prisma ORM, React for UI, rate limiting, and audit logging for sensitive actions.

## API Index
| Endpoint | Method | Note |
| -------- | ------ | ---- |
| /api/v1/emergencies/summary | GET | Dashboard summary data |
| /api/v1/emergencies/active | GET | Currently active emergencies |
| /api/v1/emergencies/history | GET | Past events + date range filter |
| /api/v1/emergencies/export/csv | GET | Export with filters (BR-029-05) |
| /api/v1/emergencies/export/json | GET | Export with filters (BR-029-05) |
| /api/v1/emergencies/:id | GET | Refactored with timeline & vitals |
| /api/v1/emergencies/:id/status | PATCH | PATCH per REST conventions |
| /api/v1/emergencies/:id/contact | POST | Log notification to contacts |
## File Index
| Path | Role |
| ---- | ---- |
| backend/src/controllers/emergency.controller.js | Component (3509 bytes) |
| backend/src/services/emergency.service.js | Component (11732 bytes) |
| backend/src/routes/emergency.routes.js | Component (3501 bytes) |
| backend/src/__tests__/services/emergency.service.test.js | Component (8528 bytes) |
| frontend/src/pages/admin/EmergencyPage.jsx | Component (11671 bytes) |
| frontend/src/components/emergency/EmergencyConstants.js | Component (781 bytes) |
| EmergencyDetailModal.jsx | Component (12324 bytes) |
| EmergencyPagination.jsx | Component (1964 bytes) |
| EmergencyStatusPrompt.jsx | Component (3460 bytes) |
| EmergencySummaryBar.jsx | Component (2496 bytes) |
| EmergencyTable.jsx | Component (5673 bytes) |
| EmergencyToolbar.jsx | Component (5383 bytes) |
| frontend/src/services/emergencyService.js | Component (2977 bytes) |
## Cross-References
| Type           | Ref                                           |
| -------------- | --------------------------------------------- |
| DB Tables      | sos_events, fall_events, emergency_contacts   |
| UC Files       | BA/UC/Emergency/UC010-UC015                   |
| Related Module | REVIEW_MOBILE/summaries/EMERGENCY_summary.md  |

## Review
| Date       | Score  | Detail                                                     |
| ---------- | ------ | ---------------------------------------------------------- |
| 2026-03-11 | 74/100 | [View](REVIEW_ADMIN/EMERGENCY_MANAGEMENT_EMERGENCY_review.md) |
