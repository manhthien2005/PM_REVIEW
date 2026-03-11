# CONFIG (Admin)

> Sprint 4 | JIRA: EP16-AdminConfig | UC: UC024

## Purpose & Technique
- Admin can view and update system-wide global settings (vital thresholds, AI config, etc.)
- Update requires admin password confirmation in request body
- ADMIN role JWT required; settings validated via custom middleware

## API Index
| Endpoint             | Method | Note                                    |
| -------------------- | ------ | --------------------------------------- |
| /api/v1/settings     | GET    | Get all global settings                 |
| /api/v1/settings     | PUT    | Update settings (password + body req.)  |

## File Index
| Path                                                       | Role                                  |
| ---------------------------------------------------------- | ------------------------------------- |
| backend/src/controllers/settings.controller.js             | Settings route handlers (920B)        |
| backend/src/services/settings.service.js                   | Settings CRUD logic (3750B)           |
| backend/src/routes/settings.routes.js                      | Route definitions + validation (849B) |
| backend/src/__tests__/services/settings.service.test.js    | Service tests (4950B)                 |
| frontend/src/pages/admin/SystemSettingsPage.jsx            | Settings UI page (5155B)              |
| frontend/src/components/settings/PasswordConfirmModal.jsx  | Password confirm modal (3504B)        |
| frontend/src/components/settings/SettingsConstants.js      | Settings constants (2641B)            |
| frontend/src/components/settings/SettingsForm.jsx          | Settings form component (9454B)       |

## Cross-References
| Type      | Ref                                          |
| --------- | -------------------------------------------- |
| DB Tables | system_settings, audit_logs                  |
| UC Files  | BA/UC/Admin/UC024_ConfigureSystem.md         |
