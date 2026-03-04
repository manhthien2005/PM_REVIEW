# SLEEP (Mobile)

> Sprint 4 | JIRA: EP14-Sleep | UC: UC020, UC021

## Purpose & Technique
- Analyze overnight sensor readings (8-10h window) for sleep stages: Awake/Light/Deep/REM
- Calculate: total duration, sleep efficiency, quality score
- Scheduled job: analyze every morning (previous night data)

## API Index
| Endpoint                                | Method | Note                |
| --------------------------------------- | ------ | ------------------- |
| /api/mobile/patients/{id}/sleep/latest  | GET    | Latest sleep report |
| /api/mobile/patients/{id}/sleep/history | GET    | Sleep history       |

## File Index
| Path                         | Role                                  |
| ---------------------------- | ------------------------------------- |
| lib/features/sleep_analysis/ | Empty directory — not yet implemented |
| backend/app/api/routes/      | No sleep route file exists            |
| backend/app/services/        | No sleep_service.py exists            |

## Known Issues
- 🔴 Module NOT implemented — both Flutter and backend dirs are empty

## Cross-References
| Type      | Ref                                                     |
| --------- | ------------------------------------------------------- |
| DB Tables | sleep_sessions (may need creation), vitals, motion_data |
| UC Files  | BA/UC/Sleep/UC020-UC021                                 |
