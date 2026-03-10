# EMERGENCY (Mobile)

> Sprint 3 | JIRA: EP09-FallDetect, EP10-SOS | UC: UC010, UC011, UC014, UC015

## Purpose & Technique

- Fall detection via AI (accelerometer + HR/BP, threshold > 0.85), 30s countdown → auto-SOS
- Manual SOS: long-press 3s, cancel within 5 minutes
- Caregiver receives SOS with GPS, responds Acknowledged/Resolved

## API Index

| Endpoint                                 | Method | Note                          |
| ---------------------------------------- | ------ | ----------------------------- |
| /api/mobile/fall-events/{id}/confirm     | POST   | User confirms safe            |
| /api/mobile/fall-events/{id}/trigger-sos | POST   | Auto after 30s countdown      |
| /api/mobile/sos/manual-trigger           | POST   | Manual SOS with GPS           |
| /api/mobile/sos/{id}/cancel              | POST   | Cancel within 5min            |
| /api/mobile/sos/active                   | GET    | Active SOS list for caregiver |
| /api/mobile/sos/{id}                     | GET    | SOS detail                    |
| /api/mobile/sos/{id}/respond             | POST   | Acknowledged/Resolved         |
| /api/mobile/sos/{id}/resolve             | POST   | Final resolution              |

## File Index

| Path                                               | Role                               | LOC |
| -------------------------------------------------- | ---------------------------------- | --- |
| lib/features/emergency/screens/warning_screen.dart | Placeholder screen (centered text) | 25  |
| lib/features/emergency/models/                     | Empty (only .gitkeep)              | —   |
| lib/features/emergency/providers/                  | Empty (only .gitkeep)              | —   |
| lib/features/emergency/repositories/               | Empty (only .gitkeep)              | —   |
| lib/features/emergency/widgets/                    | Empty (only .gitkeep)              | —   |
| backend/app/api/routes/                            | No emergency route file exists     | —   |
| backend/app/services/                              | No sos_service.py exists           | —   |

## Known Issues

- 🔴 Placeholder screen only — no logic implemented
- 🔴 Backend routes/services not yet created
- 🟡 Clean Architecture folders created but empty (only .gitkeep files)
- 🟡 No fall detection algorithm yet
- 🟡 No SOS trigger flow
- 🟡 No GPS integration

## Cross-References

| Type           | Ref                                                 |
| -------------- | --------------------------------------------------- |
| DB Tables      | fall_events, sos_events, alerts, emergency_contacts |
| UC Files       | BA/UC/Emergency/UC010-UC015                         |
| Related Module | REVIEW_MOBILE/summaries/NOTIFICATION_summary.md     |
