# MONITORING (Mobile)

> Sprint 2 | JIRA: EP08-Monitoring | UC: UC006, UC007, UC008

## Purpose & Technique
- Real-time vital signs dashboard (HR, SpO2, BP, Temp) with auto-refresh 5s
- Detail view: min/max/avg/std per metric, time range selectors (1h, 6h, 24h, 7d)
- Health history via TimescaleDB continuous aggregates (5min, hourly, daily)

## API Index
| Endpoint                                              | Method | Note                       |
| ----------------------------------------------------- | ------ | -------------------------- |
| /api/mobile/patients/{id}/vital-signs/latest          | GET    | Real-time, auto-refresh 5s |
| /api/mobile/patients/{id}/vital-signs/{metric}/detail | GET    | Stats: min/max/avg/std     |
| /api/mobile/patients/{id}/vital-signs/history         | GET    | Continuous aggregates      |

## File Index
| Path                            | Role                                  |
| ------------------------------- | ------------------------------------- |
| lib/features/health_monitoring/ | Empty directory — not yet implemented |
| backend/app/api/routes/         | No vitals route file exists           |
| backend/app/services/           | No vitals_service.py exists           |

## Known Issues
- 🔴 Module NOT implemented — both Flutter and backend dirs are empty

## Cross-References
| Type      | Ref                                                           |
| --------- | ------------------------------------------------------------- |
| DB Tables | vitals, vitals_5min, vitals_hourly, vitals_daily (aggregates) |
| UC Files  | BA/UC/Monitoring/UC006-UC008                                  |
