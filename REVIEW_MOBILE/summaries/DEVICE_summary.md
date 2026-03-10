# DEVICE (Mobile)

> Sprint 2 | JIRA: EP07-Device | UC: UC040, UC041, UC042

## Purpose & Technique

- Patient registers/connects IoT device (QR scan or manual code), lists devices, unbinds
- Device status: online/offline based on `last_seen_at` threshold (< 5min = online)
- Display battery level, signal strength, last seen; auto-refresh every 30s

## API Index

| Endpoint                        | Method | Note                            |
| ------------------------------- | ------ | ------------------------------- |
| /api/mobile/devices/register    | POST   | QR scan or manual input         |
| /api/mobile/devices             | GET    | List devices of user (from JWT) |
| /api/mobile/devices/{id}/unbind | POST   | Unbind device                   |
| /api/mobile/devices/{id}/status | GET    | Online/offline (5min threshold) |

## File Index

| Path                                           | Role                               | LOC |
| ---------------------------------------------- | ---------------------------------- | --- |
| lib/features/device/screens/device_screen.dart | Placeholder screen (centered text) | 25  |
| lib/features/device/models/                    | Empty (only .gitkeep)              | —   |
| lib/features/device/providers/                 | Empty (only .gitkeep)              | —   |
| lib/features/device/repositories/              | Empty (only .gitkeep)              | —   |
| lib/features/device/widgets/                   | Empty (only .gitkeep)              | —   |
| backend/app/api/routes/                        | No device route file exists        | —   |
| backend/app/services/                          | No device_service.py exists        | —   |

## Known Issues

- 🔴 Placeholder screen only — no logic implemented
- 🔴 Backend routes/services not yet created
- 🟡 Clean Architecture folders created but empty (only .gitkeep files)
- 🟡 No QR code scanner integration yet
- 🟡 No device registration flow

## Cross-References

| Type           | Ref                                          |
| -------------- | -------------------------------------------- |
| DB Tables      | devices                                      |
| UC Files       | BA/UC/Device/UC040, UC041, UC042             |
| Related Module | REVIEW_ADMIN/summaries/DEVICES_summary.md    |
| Data Flow      | Device → MQTT/HTTP → Data Ingestion → vitals |
