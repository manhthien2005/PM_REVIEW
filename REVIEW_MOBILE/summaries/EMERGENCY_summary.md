# EMERGENCY (Mobile)

> Sprint 3 | JIRA: EP09-FallDetect, EP10-SOS | UC: UC010-UC015

## Purpose & Technique
- Manage Fall Detection, Automatic/Manual SOS handling
- Handles the dispatch algorithm for caregiver notification tracking
- Relies on TimescaleDB schemas for real-time alerting queries

## API Index
| Endpoint | Method | Note |
|---|---|---|
| /api/mobile/sos | GET | Active SOS events (Caregiver View) |
| /api/mobile/sos/manual-trigger | POST | Manually broadcast SOS |
| /api/mobile/sos/{id}/resolve | POST | Resolve the alert |
| /api/mobile/fall-events/{id}/confirm | POST | Acknowledge fall event |

## File Index
| Path | Role |
|---|---|
| lib/features/emergency/ | Flutter UI/Screens (2540 LOC) |
| backend/app/api/routes/emergency.py | Backend definitions (149 LOC) |
| backend/app/services/emergency_service.py | Processing logic (191 LOC) |

## Cross-References
| Type | Ref |
|---|---|
| DB Tables | fall_events, sos_events, user_relationships |

