# DEVICE (Mobile)

> Sprint 2 | JIRA: EP07-Device | UC: UC040-UC042

## Purpose & Technique
- IoT Device Management (Connect, List, unbind devices)
- BLE/MQTT integration abstractions via Clean Architecture
- Devices registered and tracked for continuous motion data mapping

## API Index
| Endpoint | Method | Note |
|---|---|---|
| /api/mobile/devices | GET | List bound devices |
| /api/mobile/devices/register | POST | Bound new device |
| /api/mobile/devices/{id}/unbind | POST | Unbind device |
| /api/mobile/devices/{id}/status | GET | Quick check status |

## File Index
| Path | Role |
|---|---|
| lib/features/device/ | Frontend UI & Store (1026 LOC) |
| backend/app/api/routes/device.py | Backend router (102 LOC) |
| backend/app/services/device_service.py | DB business logic (334 LOC) |

## Cross-References
| Type | Ref |
|---|---|
| DB Tables | devices |

