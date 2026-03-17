# PROFILE (Mobile)

> Sprint 1-2 | JIRA: EP04-Login, EP05-Register | UC: UC009

## Purpose & Technique
- Retrieve the current user profile metadata
- Self-editing, preferences, avatar management 
- Secure cleanup for logouts

## API Index
| Endpoint | Method | Note |
|---|---|---|
| /api/mobile/profile/me | GET | View self Profile |
| /api/mobile/profile/edit | POST | Update self Profile |

## File Index
| Path | Role |
|---|---|
| lib/features/profile/ | Form/Inputs logic (1472 LOC) |
| backend/app/api/routes/profile.py | Routing mapping (39 LOC) |
| backend/app/services/profile_service.py | Processing logic (99 LOC) |

## Cross-References
| Type | Ref |
|---|---|
| DB Tables | users |

