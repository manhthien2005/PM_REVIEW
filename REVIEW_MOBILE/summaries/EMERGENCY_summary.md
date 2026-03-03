# 🔬 MODULE SUMMARY: EMERGENCY (Mobile)

> **Module**: EMERGENCY — Fall Detection & SOS  
> **Project**: Mobile App (health_system/)  
> **Sprint**: Sprint 3  
> **Trello Cards**: Sprint 3 Card 2 (Fall Alert), Card 3 (Manual SOS), Card 4 (Receive SOS), Card 5 (Safety Resolution)  
> **UC References**: UC010, UC011, UC014, UC015

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- HG-FUNC-04: Combine accelerometer + sudden HR/BP changes for fall confirmation
- HG-FUNC-05: AI detects fall pattern (probability > threshold) → trigger "Fall Alert" on server
- HG-FUNC-06: Mobile App vibrates, plays sound, shows **30-second countdown** on fall alert
- HG-FUNC-07: If user doesn't press "Cancel" → auto-send SOS with GPS coordinates to caregiver
- Manual SOS: Long-press 3 seconds → confirmation → send SOS
- Cancel SOS: Within **5 minutes** of trigger
- Caregiver receives SOS: view patient info, GPS location, timeline; respond with "Acknowledged" or "Resolved"

### AI Component
- Fall Detection Model: Input = motion_data window (6s, 50Hz = 300 samples)
- Output: fall probability (0-1), confidence
- Threshold: > **0.85** → trigger alert
- XAI: Generate timeline explanation

### Non-Functional Requirements
- SRS §5.1: Fall alert delivered to caregiver App within **5 seconds**
- SRS §5.1: Fall detection sensitivity > **90%**
- Push notification via FCM (Firebase Cloud Messaging)
- GPS coordinates (simulated)

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 2 — Fall Alert (Mobile BE Dev)
- [ ] Integrate AI service into data pipeline: motion_data → AI inference → fall event
- [ ] `POST /api/mobile/fall-events/{id}/confirm` — user confirms safe
- [ ] `POST /api/mobile/fall-events/{id}/trigger-sos` — auto trigger after 30s
- [ ] Update `fall_events.user_responded_at`, `user_cancelled`
- [ ] If not cancelled → trigger SOS flow
- [ ] Create alert: `alert_type='fall_detected'`
- [ ] Send FCM push notification

### Card 3 — Manual SOS (Mobile BE Dev)
- [ ] `POST /api/mobile/sos/manual-trigger` — Req: `{device_id, latitude, longitude}`
- [ ] Create `sos_events` record: `trigger_type='manual'`
- [ ] Get emergency contacts (sorted by priority)
- [ ] Send: Push (FCM) + SMS (if `notify_via_sms=true`)
- [ ] Create `alerts` for each contact
- [ ] `POST /api/mobile/sos/{id}/cancel` — cancel within 5min

### Card 4 — Receive SOS (Mobile BE Dev)
- [ ] `GET /api/mobile/sos/active` — list active SOS for caregiver
- [ ] `GET /api/mobile/sos/{id}` — SOS detail
- [ ] `POST /api/mobile/sos/{id}/respond` — Req: `{action: "acknowledged"|"resolved", notes}`

### Card 5 — Safety Resolution (Mobile BE Dev)
- [ ] `POST /api/mobile/sos/{id}/resolve` — update status, notify all parties

---

## 📂 Source Code Files

### Backend (`health_system/backend/app/`)
| File Path | Role |
|-----------|------|
| `api/emergency/` | Emergency API routes |
| `services/sos_service.py` | SOS business logic |
| `services/telemetry_service.py` | Data pipeline (triggers AI) |

### Mobile (`health_system/lib/features/emergency/`)
| File Path | Role |
|-----------|------|
| `features/emergency/` | Emergency feature module |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §4.2 HG-FUNC-04 to HG-FUNC-07, §5.1 (5s latency, 90% sensitivity) |
| Use Case Files | `BA/UC/Emergency/UC010-UC015` |
| DB Tables | `fall_events`, `sos_events`, `alerts`, `emergency_contacts` |
| Related NOTIFICATION | `REVIEW_MOBILE/summaries/NOTIFICATION_summary.md` |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
