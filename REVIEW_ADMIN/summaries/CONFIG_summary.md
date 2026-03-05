# CONFIG (Admin)

> Sprint 4 | JIRA: EP16-AdminConfig | UC: UC024

## Purpose & Technique
- Admin can view and update system-wide configuration: vital thresholds, AI config, notification settings, retention policies
- Settings loaded into memory/cache on server startup; changes take effect immediately after cache refresh
- ADMIN role required

## API Index
| Endpoint              | Method | Note                              |
| --------------------- | ------ | --------------------------------- |
| /api/admin/settings   | GET    | Get all settings                  |
| /api/admin/settings   | PUT    | Update settings (ADMIN only)      |

## File Index
| Path                                           | Role               |
| ---------------------------------------------- | ------------------ |
| backend/src/controllers/settings.controller.ts | ⬜ Not built yet  |
| backend/src/services/settings.service.ts       | ⬜ Not built yet  |
| frontend/src/pages/SystemSettings.tsx          | ⬜ Not built yet  |

## Known Issues
- 🔴 No source code exists — controller, service, route, and frontend page all unbuilt

## Cross-References
| Type     | Ref                                      |
| -------- | ---------------------------------------- |
| DB Tables| system_settings (or equivalent config table) |
| UC Files | BA/UC/Admin/UC024_ConfigureSystem.md     |
