# CONFIG (Admin)

> Sprint 4 | JIRA: EP16-AdminConfig | UC: UC024

## Purpose & Technique
- Admin can view and update system-wide global settings (vital thresholds, AI config, etc.)
- Update requires admin password confirmation in request body
- ADMIN role JWT required; settings validated via custom middleware

## API Index
| Endpoint | Method | Note |
| -------- | ------ | ---- |
| /api/v1/settings | GET | Vital thresholds, AI config |
| /api/v1/settings | PUT | Requires admin password + body |
## File Index
| Path | Role |
| ---- | ---- |
| backend/src/controllers/settings.controller.js | Component (920 bytes) |
| backend/src/services/settings.service.js | Component (3750 bytes) |
| backend/src/routes/settings.routes.js | Component (849 bytes) |
| backend/src/__tests__/services/settings.service.test.js | Component (4950 bytes) |
| frontend/src/pages/admin/SystemSettingsPage.jsx | Component (5155 bytes) |
| frontend/src/components/settings/PasswordConfirmModal.jsx | Component (3504 bytes) |
| SettingsConstants.js | Component (2641 bytes) |
| SettingsForm.jsx | Component (9454 bytes) |
## Cross-References
| Type      | Ref                                          |
| --------- | -------------------------------------------- |
| DB Tables | system_settings, audit_logs                  |
| UC Files  | BA/UC/Admin/UC024_ConfigureSystem.md         |
