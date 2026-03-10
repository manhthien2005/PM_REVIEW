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

| Path                                                                 | Role                               | LOC |
| -------------------------------------------------------------------- | ---------------------------------- | --- |
| lib/features/health_monitoring/screens/health_monitoring_screen.dart | Placeholder screen (centered text) | 25  |
| lib/features/health_monitoring/models/                               | Empty (only .gitkeep)              | —   |
| lib/features/health_monitoring/providers/                            | Empty (only .gitkeep)              | —   |
| lib/features/health_monitoring/repositories/                         | Empty (only .gitkeep)              | —   |
| lib/features/health_monitoring/widgets/                              | Empty (only .gitkeep)              | —   |
| backend/app/api/routes/                                              | No vitals route file exists        | —   |
| backend/app/services/                                                | No vitals_service.py exists        | —   |

## Known Issues

- 🔴 Placeholder screen only — no logic implemented
- 🔴 Backend routes/services not yet created
- 🟡 Clean Architecture folders created but empty (only .gitkeep files)
- 🟡 No real-time vitals display
- 🟡 No chart/graph library integration
- 🟡 No TimescaleDB aggregates query

## Cross-References

| Type      | Ref                                                           |
| --------- | ------------------------------------------------------------- |
| DB Tables | vitals, vitals_5min, vitals_hourly, vitals_daily (aggregates) |
| UC Files  | BA/UC/Monitoring/UC006-UC008                                  |
