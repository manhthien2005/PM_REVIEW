# 🔬 MODULE SUMMARY: LOGS (Admin)

> **Module**: LOGS — System Logs Viewer  
> **Project**: Admin Website (HealthGuard/)  
> **Sprint**: Sprint 4  
> **Trello Cards**: Sprint 4, Card 8  
> **UC References**: UC026

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- Admin can view system logs (audit trail of all admin actions)
- Filter logs by: date range, user, action type, severity
- Paginate results
- Export logs to CSV

### Data Source
- `audit_logs` table — records all admin actions (login, CRUD, config changes)
- `system_metrics` table — system health metrics (optional display)

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 8 — View System Logs (Admin BE Dev)
- [ ] `GET /api/admin/logs` — list logs with filter + paginate
- [ ] `GET /api/admin/logs/export` — export CSV
- [ ] Permission: ADMIN only

### Card 8 — Admin FE Dev
- [ ] Logs page with table
- [ ] Filters: date range, user, action type
- [ ] Pagination
- [ ] Export CSV button

### Acceptance Criteria
- [ ] Logs display correctly with filters
- [ ] Export CSV works
- [ ] Permission enforced

---

## 📂 Source Code Files

### Backend (`HealthGuard/backend/src/`)
| File Path | Role |
|-----------|------|
| `controllers/logs.controller.ts` | Log query + export endpoints |
| `services/logs.service.ts` | Log querying + CSV generation |

### Frontend (`HealthGuard/frontend/src/`)
| File Path | Role |
|-----------|------|
| `pages/SystemLogs.tsx` | Logs viewer UI |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| Use Case Files | `BA/UC/Admin/UC026_ViewSystemLogs.md` |
| DB Tables | `audit_logs`, `system_metrics` |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
