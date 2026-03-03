# 🔬 MODULE SUMMARY: DEVICE (Mobile)

> **Module**: DEVICE — IoT Device Management (Patient Side)  
> **Project**: Mobile App (health_system/)  
> **Sprint**: Sprint 2  
> **Trello Cards**: Sprint 2, Card 1 (Connect Device), Card 2 (Device Status)  
> **UC References**: UC040, UC042

---

## 📋 SRS Requirements (Extracted)

### Functional Requirements
- Patient registers/connects IoT device to their account (QR scan or manual code input)
- Patient views list of their connected devices
- Patient can unbind a device
- Device status: online/offline based on `last_seen_at` threshold (< 5min = online)
- Display: battery level, signal strength, last seen timestamp

### Non-Functional Requirements
- MQTT client_id generated per device for telemetry
- Auto-refresh status every 30 seconds
- Show "Device offline" warning if offline > 10 minutes

---

## 📌 Trello Checklist (Pre-Extracted)

### Card 1 — Connect Device (Mobile BE Dev)
- [ ] `POST /api/mobile/devices/register` — Req: `{device_code, device_name, device_type}`, Res: `{device_id, uuid}`
- [ ] Validate device_code uniqueness
- [ ] Create device in `devices` table with `user_id` (from JWT)
- [ ] Generate MQTT client_id for device
- [ ] `GET /api/mobile/devices` — list devices of user
- [ ] `POST /api/mobile/devices/{id}/unbind` — unbind device

### Card 2 — Device Status (Mobile BE Dev)
- [ ] `GET /api/mobile/devices/{id}/status` — Res: `{device_id, is_active, battery_level, signal_strength, last_seen_at, status: "online"|"offline"}`
- [ ] Logic: `last_seen_at < 5min` → online, else offline
- [ ] Update `last_seen_at` when receiving data from device (MQTT listener)

### Mobile FE
- [ ] Connect Device screen (QR scan + manual input)
- [ ] Device list screen
- [ ] Device status card: battery icon, signal icon, online/offline badge
- [ ] Auto-refresh every 30s
- [ ] "Device offline" warning if offline > 10min

---

## 📂 Source Code Files

### Backend (`health_system/backend/app/`)
| File Path | Role |
|-----------|------|
| `api/devices/` | Device API routes |
| `services/device_service.py` | Device business logic |

### Mobile (`health_system/lib/features/device/`)
| File Path | Role |
|-----------|------|
| `features/device/` | Device feature module (Clean Architecture) |

---

## 🔗 Cross-References

| Type | Reference |
|------|-----------|
| Use Case Files | `BA/UC/Device/UC040_Connect_Device.md`, `UC042_View_Device_Status.md` |
| DB Tables | `devices` |
| Related Admin Module | `REVIEW_ADMIN/summaries/DEVICES_summary.md` |
| Data flow | Device → MQTT/HTTP → Data Ingestion → `vitals` + `motion_data` tables |

---

## 📊 Review Notes
| Key | Value |
|-----|-------|
| Review Date | — |
| Score | —/100 |
| Reviewer Notes | — |
