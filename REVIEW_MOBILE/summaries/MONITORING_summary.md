# MONITORING (Mobile)

> Sprint 2 | JIRA: EP08-Monitoring | UC: UC006-UC008

## Purpose & Technique
- Load continuous Time-Series Metrics (HR, SpO2)
- Visualize historical telemetry chunks

## API Index
| Endpoint | Method | Note |
|---|---|---|
| /api/mobile/monitoring | GET | View historical metric subsets via params |

## File Index
| Path | Role |
|---|---|
| lib/features/health_monitoring/ | Graph rendering & stores (2420 LOC) |
| backend/app/api/routes/monitoring.py | Backend definitions (35 LOC) |
| backend/app/services/monitoring_service.py | Query aggregations (134 LOC) |

## Cross-References
| Type | Ref |
|---|---|
| DB Tables | vitals |

