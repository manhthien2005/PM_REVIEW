# NOTIFICATION (Mobile)

> Sprint 3 | JIRA: EP11-Notification | UC: UC030, UC031

## Purpose & Technique
- CRUD emergency contacts with priority (1-5, 1 = called first)
- Alert center: list/filter by type/severity/unread, mark read, acknowledge
- Notification settings per alert type, push via FCM

## API Index
| Endpoint                            | Method     | Note                         |
| ----------------------------------- | ---------- | ---------------------------- |
| /api/mobile/emergency-contacts      | GET/POST   | List/add contacts            |
| /api/mobile/emergency-contacts/{id} | PUT/DELETE | Update/delete contact        |
| /api/mobile/alerts                  | GET        | Filter: type/severity/unread |
| /api/mobile/alerts/{id}/read        | POST       | Mark as read                 |
| /api/mobile/alerts/{id}/acknowledge | POST       | Acknowledge alert            |
| /api/mobile/notification-settings   | GET/PUT    | Get/update settings          |

## File Index
| Path                    | Role                                 |
| ----------------------- | ------------------------------------ |
| lib/features/           | No notification-specific feature dir |
| backend/app/api/routes/ | No notification route file exists    |
| backend/app/services/   | No notification_service.py exists    |

## Known Issues
- 🔴 Module NOT implemented — no Flutter or backend code exists

## Cross-References
| Type           | Ref                                               |
| -------------- | ------------------------------------------------- |
| DB Tables      | emergency_contacts, alerts, notification_settings |
| UC Files       | BA/UC/Notification/UC030-UC031                    |
| Related Module | REVIEW_MOBILE/summaries/EMERGENCY_summary.md      |
