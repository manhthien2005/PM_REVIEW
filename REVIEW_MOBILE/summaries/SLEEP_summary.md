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

| Path                                                  | Role                               | LOC |
| ----------------------------------------------------- | ---------------------------------- | --- |
| lib/features/sleep_analysis/screens/sleep_screen.dart | Placeholder screen (centered text) | 25  |
| lib/features/sleep_analysis/models/                   | Empty (only .gitkeep)              | —   |
| lib/features/sleep_analysis/providers/                | Empty (only .gitkeep)              | —   |
| lib/features/sleep_analysis/repositories/             | Empty (only .gitkeep)              | —   |
| lib/features/sleep_analysis/widgets/                  | Empty (only .gitkeep)              | —   |
| backend/app/api/routes/                               | No sleep route file exists         | —   |
| backend/app/services/                                 | No sleep_service.py exists         | —   |

## Known Issues

- 🔴 Placeholder screen only — no logic implemented
- 🔴 Backend routes/services not yet created
- 🟡 Clean Architecture folders created but empty (only .gitkeep files)
- 🟡 No sleep analysis algorithm
- 🟡 No sleep report visualization
- 🟡 No sleep_sessions table created yet

## Cross-References

| Type      | Ref                                                     |
| --------- | ------------------------------------------------------- |
| DB Tables | sleep_sessions (may need creation), vitals, motion_data |
| UC Files  | BA/UC/Sleep/UC020-UC021                                 |
