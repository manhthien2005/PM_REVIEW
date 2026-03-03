# 🔬 MODULE SUMMARY: NOTIFICATION (Mobile)

> **Module**: NOTIFICATION — Emergency Contacts & Alert Management  
> **Project**: Mobile App (health_system/)  
> **Sprint**: Sprint 3  
> **Trello Cards**: Sprint 3 Card 1 (Emergency Contacts), Card 6 (Manage Notifications)  
> **UC References**: UC030, UC031

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- Patient manages emergency contacts: CRUD with priority (1-5, 1 = called first)
- Phone format validation
- Contact preferences: notify via SMS, notify via call
- Alert center: list all alerts, filter by type/severity/unread
- Mark alerts as read, acknowledge alerts
- Notification settings: enable/disable per alert type
- Push notification via FCM

### Non-Functional Requirements
- SRS §3.3: Push via FCM, SMS/Call service API (simulated)
- Real-time delivery of critical alerts

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 1 — Emergency Contacts (Mobile BE Dev)
- [ ] `GET /api/mobile/emergency-contacts` — list contacts
- [ ] `POST /api/mobile/emergency-contacts` — add contact
- [ ] `PUT /api/mobile/emergency-contacts/{id}` — update
- [ ] `DELETE /api/mobile/emergency-contacts/{id}` — delete
- [ ] Validate phone format
- [ ] Priority: 1-5 (1 = first to call)
- [ ] Store in `emergency_contacts` table

### Card 6 — Manage Notifications (Mobile BE Dev)
- [ ] `GET /api/mobile/alerts` — list with filter (type/severity/unread)
- [ ] `POST /api/mobile/alerts/{id}/read` — mark as read
- [ ] `POST /api/mobile/alerts/{id}/acknowledge` — acknowledge
- [ ] `GET /api/mobile/notification-settings` — get settings
- [ ] `PUT /api/mobile/notification-settings` — update settings

### Mobile FE
- [ ] Emergency Contacts screen (Settings): list, add/edit/delete, priority ordering
- [ ] Notification center: alert list, filters, read/acknowledge
- [ ] Notification settings screen

---

## 📂 Source Code Files

### Backend (`health_system/backend/app/`)
| File Path | Role |
|-----------|------|
| `api/notifications/` | Notification API routes |
| `services/notification_service.py` | Notification business logic |

### Mobile (`health_system/lib/`)
| File Path | Role |
|-----------|------|
| `features/` (shared across modules) | Notification-related UI components |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| SRS Section | §3.3 (FCM, SMS/Call), §4.2 HG-FUNC-07 (SOS notifications) |
| Use Case Files | `BA/UC/Notification/UC030-UC031` |
| DB Tables | `emergency_contacts`, `alerts`, `notification_settings` |
| Related EMERGENCY | `REVIEW_MOBILE/summaries/EMERGENCY_summary.md` |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
