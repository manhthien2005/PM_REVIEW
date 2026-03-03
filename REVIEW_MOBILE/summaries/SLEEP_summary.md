# 🔬 MODULE SUMMARY: SLEEP (Mobile)

> **Module**: SLEEP — Sleep Analysis  
> **Project**: Mobile App (health_system/)  
> **Sprint**: Sprint 4  
> **Trello Cards**: Sprint 4 Card 3 (Analyze Sleep), Card 4 (Sleep Report)  
> **UC References**: UC020, UC021

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- Analyze sleep data from overnight sensor readings (8-10h window)
- Detect sleep stages: Awake, Light, Deep, REM
- Calculate: total duration, sleep efficiency, quality score
- Scheduled job: run every morning (analyze previous night)
- Patient views latest sleep report and sleep history
- May need new `sleep_sessions` table (via SQL SCRIPTS/)

### AI Component
- Input: HR, HRV, motion_data (overnight window)
- Method: Heuristic-based or ML model
- Output: Sleep stages timeline, duration, efficiency, quality score

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 3 — Analyze Sleep (AI Dev + Mobile BE Dev)
- [ ] Sleep analysis algorithm (heuristics or ML):
  - Input: HR, HRV, motion_data (8-10h night window)
  - Detect stages: Awake/Light/Deep/REM
  - Calculate: duration, efficiency, quality score
- [ ] Create `sleep_sessions` table if needed (via SQL SCRIPTS/)
- [ ] Sleep analysis service (call AI algorithm)
- [ ] Schedule job: analyze every morning

### Card 4 — Sleep Report (Mobile BE Dev)
- [ ] `GET /api/mobile/patients/{id}/sleep/latest` — latest sleep report
- [ ] `GET /api/mobile/patients/{id}/sleep/history?from=&to=` — sleep history

### Mobile FE
- [ ] Sleep report screen: stages chart, duration, efficiency, quality score
- [ ] Sleep history with charts

---

## 📂 Source Code Files

### Backend (`health_system/backend/app/`)
| File Path | Role |
|-----------|------|
| `api/sleep/` | Sleep API routes |
| `services/sleep_service.py` | Sleep analysis business logic |

### Mobile (`health_system/lib/features/sleep_analysis/`)
| File Path | Role |
|-----------|------|
| `features/sleep_analysis/` | Sleep analysis feature module |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §2.2 (Main features — sleep analysis) |
| Use Case Files | `BA/UC/Sleep/UC020-UC021` |
| DB Tables | `sleep_sessions` (may need creation), `vitals`, `motion_data` |
| Note | May need new SQL script for `sleep_sessions` table |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
