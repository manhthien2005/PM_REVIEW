# AUTH (Mobile)

> Sprint 1 | JIRA: EP04-Login, EP05-Register, EP12-Password | UC: UC001-UC005, UC009

## Purpose & Technique
- Handles User and Caregiver login, registration, email verification, and tokens
- JWT issuer healthguard-mobile validation
- UI deep linking setup using AppLinks configuration

## API Index
| Endpoint | Method | Note |
|---|---|---|
| /api/auth/login | POST | User login |
| /api/auth/register | POST | Self-register |
| /api/auth/verify-email | POST | Deep link verify |
| /api/auth/reset-password | POST | Token Reset PW |

## File Index
| Path | Role |
|---|---|
| lib/features/auth/ | Frontend (3748 LOC) |
| backend/app/api/routes/auth.py | Router (366 LOC) |
| backend/app/services/auth_service.py | Service (1047 LOC) |

## Cross-References
| Type | Ref |
|---|---|
| DB Tables | users |
| Related Module | REVIEW_ADMIN/summaries/AUTH_summary.md |

## Review
| Date | Score | Detail |
|---|---|---|
| 2026-03-04 | 82/100 | AUTH_LOGIN_review_v2.md |
