# 🔬 MODULE SUMMARY: DEVICES (Admin)

> **Module**: DEVICES — Device Management (Admin Side)  
> **Project**: Admin Website (HealthGuard/)  
> **Sprint**: Sprint 4  
> **Trello Cards**: Sprint 4, Card 6  
> **UC References**: UC025

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- Admin can view all devices in the system
- Admin can view device details (status, assigned user, battery, etc.)
- Admin can update device metadata
- Admin can assign/reassign devices to users
- Admin can lock/unlock devices

### Non-Functional Requirements
- **Security**: ADMIN role-only access
- **Data**: Device status derived from `last_seen_at` (online if < 5min)

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 6 — Manage Devices (Admin BE Dev)
- [ ] `GET /api/admin/devices` — list all devices
- [ ] `GET /api/admin/devices/{id}` — device detail
- [ ] `PUT /api/admin/devices/{id}` — update device
- [ ] `POST /api/admin/devices/{id}/assign` — assign to user
- [ ] `POST /api/admin/devices/{id}/lock` — lock/unlock
- [ ] Permission: ADMIN only

### Card 6 — Manage Devices (Admin FE Dev)
- [ ] Device management page with table
- [ ] Device detail view
- [ ] Assign to user flow
- [ ] Lock/unlock toggle

### Acceptance Criteria
- [ ] Device CRUD works
- [ ] Assign/lock/unlock functional
- [ ] Permission enforced

---

## 📂 Source Code Files

### Backend (`HealthGuard/backend/src/`)
| File Path | Role |
|-----------|------|
| `controllers/device.controller.ts` | Route handlers for device management |
| `services/device.service.ts` | Business logic |

### Frontend (`HealthGuard/frontend/src/`)
| File Path | Role |
|-----------|------|
| `pages/ManageDevices.tsx` | Device management page |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| Use Case Files | `BA/UC/Admin/UC025_ManageDevices.md` |
| DB Tables | `devices` |
| Related Mobile Module | `REVIEW_MOBILE/summaries/DEVICE_summary.md` (patient-side device mgmt) |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
