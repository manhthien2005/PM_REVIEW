# 🔬 MODULE SUMMARY: MONITORING (Mobile)

> **Module**: MONITORING — Health Metrics Monitoring  
> **Project**: Mobile App (health_system/)  
> **Sprint**: Sprint 2  
> **Trello Cards**: Sprint 2 Card 4 (View Metrics), Card 5 (Metrics Detail), Card 6 (Health History)  
> **UC References**: UC006, UC007, UC008

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- HG-FUNC-02: Display vital data on Mobile App with latency ≤ **5 seconds**
- HG-FUNC-03: Generate alerts if: SpO2 < 92%, Temp > 37.8°C, HR > 100 or < 60 bpm, BP > 140 or < 90 mmHg
- Patient views their own vitals; Caregiver views patient's vitals (requires `can_view_vitals` permission)
- Real-time dashboard with auto-refresh every **5 seconds**
- Stale data detection: data > 5min → `is_stale=true` → "Device offline" warning
- History via TimescaleDB continuous aggregates: `vitals_5min`, `vitals_hourly`, `vitals_daily`
- Detail view: min/max/avg/std statistics per metric, time range selectors (1h, 6h, 24h, 7d)

### Non-Functional Requirements
- Color coding: normal (green), warning (yellow), danger (red)
- Large fonts + high contrast for elderly users

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 4 — View Health Metrics (Mobile BE Dev)
- [ ] `GET /api/mobile/patients/{id}/vital-signs/latest`
  - Res: `{patient_id, timestamp, vital_signs: {...}, is_stale, alerts: [...]}`
- [ ] Query latest record from `vitals` table
- [ ] Apply threshold rules (HR, SpO2, BP, Temp) → color coding
- [ ] Check `is_stale`: data > 5min → true
- [ ] Generate alerts if abnormal
- [ ] Permission: patient views self, caregiver needs `can_view_vitals`
- [ ] `GET /api/mobile/patients/{id}/vital-signs/history?from=&to=&interval=`
  - Query from continuous aggregates

### Card 5 — Metrics Detail (Mobile BE Dev)
- [ ] `GET /api/mobile/patients/{id}/vital-signs/{metric}/detail?from=&to=`
  - Res: `{metric, period, stats: {min, max, avg, std}, data_points: [...]}`
- [ ] Calculate statistics

### Card 6 — Health History (Mobile BE Dev)
- [ ] `GET /api/mobile/patients/{id}/vital-signs/history?period=day|week|month`
- [ ] Query from `vitals_daily` continuous aggregate

### Mobile FE
- [ ] Dashboard: metric cards (HR/SpO2/BP/Temp) with color coding
- [ ] Line chart (1 hour), auto-refresh 5s
- [ ] Detail screen: stats + time range selector
- [ ] History: calendar/date picker + charts

---

## 📂 Source Code Files

### Backend (`health_system/backend/app/`)
| File Path | Role |
|-----------|------|
| `api/vitals/` | Vital signs API routes |
| `services/vitals_service.py` | Monitoring business logic |

### Mobile (`health_system/lib/features/health_monitoring/`)
| File Path | Role |
|-----------|------|
| `features/health_monitoring/` | Health monitoring feature module |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §4.2 HG-FUNC-01 to HG-FUNC-03 |
| Use Case Files | `BA/UC/Monitoring/UC006-UC008` |
| DB Tables | `vitals`, `vitals_5min`, `vitals_hourly`, `vitals_daily` (aggregates) |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
