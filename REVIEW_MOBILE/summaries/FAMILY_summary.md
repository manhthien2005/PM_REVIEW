# FAMILY (Mobile)

> Sprint 3 | JIRA: N/A | UC: N/A

## Purpose & Technique
- Manage caregiver-patient relationships and profiles
- Search, view, add, and switch target profiles
- Built with Clean Architecture on Flutter + FastAPI backend

## API Index
| Endpoint | Method | Note |
|---|---|---|
| /api/mobile/relationships/search | GET | Search for users by email |
| /api/mobile/relationships/request | POST | Send family link request |
| /api/mobile/relationships/caregiver-requests | GET | List pending requests |
| /api/mobile/relationships/respond | POST | Accept/reject relationship |

## File Index
| Path | Role |
|---|---|
| lib/features/family/                | Flutter Frontend (1990 LOC) |
| backend/app/api/routes/relationships.py | FastAPI Routes (106 LOC) |
| backend/app/services/relationship_service.py | FastAPI Services (171 LOC) |

## Cross-References
| Type | Ref |
|---|---|
| DB Tables | user_relationships |
