# 🔬 MODULE SUMMARY: CONFIG (Admin)

> **Module**: CONFIG — System Configuration  
> **Project**: Admin Website (HealthGuard/)  
> **Sprint**: Sprint 4  
> **Trello Cards**: Sprint 4, Card 7  
> **UC References**: UC024

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- Admin can view current system settings
- Admin can update settings: vital thresholds, AI config, notification settings, retention policies
- Settings loaded into memory/cache on server startup
- Changes take effect immediately (or after cache refresh)

### Key Settings (from SRS §4.2)
- **Vital Thresholds**: HR > 100 or < 60 bpm, SpO2 < 92%, Temp > 37.8°C, BP > 140 or < 90 mmHg
- **AI Config**: Fall detection confidence threshold (default 0.85), risk scoring interval
- **Retention**: TimescaleDB compression/retention policies

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 7 — Configure System (Admin BE Dev)
- [ ] `GET /api/admin/settings` — get all settings
- [ ] `PUT /api/admin/settings` — update settings
- [ ] Settings categories: vital thresholds, AI config, notification settings, retention policies
- [ ] Load settings into memory/cache on startup
- [ ] Permission: ADMIN only

### Card 7 — Admin FE Dev
- [ ] System Settings page with sections/tabs
- [ ] Form for each setting category
- [ ] Save confirmation

### Acceptance Criteria
- [ ] Settings CRUD works
- [ ] Settings apply correctly after update

---

## 📂 Source Code Files

### Backend (`HealthGuard/backend/src/`)
| File Path | Role |
|-----------|------|
| `controllers/settings.controller.ts` | GET/PUT settings endpoints |
| `services/settings.service.ts` | Settings logic + caching |

### Frontend (`HealthGuard/frontend/src/`)
| File Path | Role |
|-----------|------|
| `pages/SystemSettings.tsx` | Settings UI |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §4.2 HG-FUNC-03 (alert thresholds), §5.1 (performance requirements) |
| Use Case Files | `BA/UC/Admin/UC024_ConfigureSystem.md` |
| DB Tables | `system_settings` or similar config table |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
