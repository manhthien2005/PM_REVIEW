# EMERGENCY (Admin)

> Sprint 3-4 | JIRA: EP09-FallDetect, EP10-SOS | UC: UC010-UC015

## Purpose & Technique
- Admin dashboard for real-time monitoring and response to falls and SOS events.
- Features: active/history event tracking, date range filters, CSV/JSON export, and contact logging.
- Tech: Express with Prisma ORM, React for UI, rate limiting, and audit logging for sensitive actions.

## API Index
| Endpoint                             | Method | Note                               |
| ------------------------------------ | ------ | ---------------------------------- |
| /api/v1/emergencies/summary          | GET    | Dashboard summary data             |
| /api/v1/emergencies/active           | GET    | Active emergency events            |
| /api/v1/emergencies/history          | GET    | Past events + date range filter    |
| /api/v1/emergencies/export/csv       | GET    | Export history to CSV              |
| /api/v1/emergencies/export/json      | GET    | Export history to JSON             |
| /api/v1/emergencies/:id              | GET    | Event detail with timeline/vitals  |
| /api/v1/emergencies/:id/status       | PATCH  | Update status (responded/resolved) |
| /api/v1/emergencies/:id/contact      | POST   | Log contact notification           |

## File Index
| Path                                                     | Role                                 |
| -------------------------------------------------------- | ------------------------------------ |
| backend/src/controllers/emergency.controller.js          | Route handlers (3509 bytes)          |
| backend/src/services/emergency.service.js                | Business logic (11732 bytes)         |
| backend/src/routes/emergency.routes.js                   | Route definitions (3501 bytes)       |
| backend/src/__tests__/services/emergency.service.test.js | Service tests (8528 bytes)           |
| frontend/src/pages/admin/EmergencyPage.jsx               | Main management page (11671 bytes)   |
| frontend/src/components/emergency/EmergencyConstants.js  | Constants (781 bytes)                |
| frontend/src/components/emergency/EmergencyDetailModal.jsx| Detail view modal (12329 bytes)      |
| frontend/src/components/emergency/EmergencyPagination.jsx | Pagination control (1964 bytes)      |
| frontend/src/components/emergency/EmergencyStatusPrompt.jsx| Status change prompt (3460 bytes)    |
| frontend/src/components/emergency/EmergencySummaryBar.jsx | Summary stats bar (2496 bytes)       |
| frontend/src/components/emergency/EmergencyTable.jsx      | Events list table (5673 bytes)       |
| frontend/src/components/emergency/EmergencyToolbar.jsx    | Search and filters (5383 bytes)      |
| frontend/src/services/emergencyService.js                  | API client (2977 bytes)              |

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
