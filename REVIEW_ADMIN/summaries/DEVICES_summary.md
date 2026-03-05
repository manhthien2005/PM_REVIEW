# DEVICES (Admin)

> Sprint 4 | JIRA: EP15-AdminManage | UC: UC025

## Purpose & Technique
- Admin can view, update, assign, and lock/unlock all IoT devices in the system
- Device online status derived from `last_seen_at` (online if < 5 min ago)
- ADMIN role required for all operations

## API Index
| Endpoint                          | Method | Note                  |
| --------------------------------- | ------ | --------------------- |
| /api/admin/devices                | GET    | List all devices      |
| /api/admin/devices/{id}           | GET    | Device detail         |
| /api/admin/devices/{id}           | PUT    | Update device metadata|
| /api/admin/devices/{id}/assign    | POST   | Assign device to user |
| /api/admin/devices/{id}/lock      | POST   | Lock/unlock device    |

## File Index
| Path                                        | Role               |
| ------------------------------------------ | ------------------ |
| backend/src/controllers/device.controller.ts | ⬜ Not built yet  |
| backend/src/services/device.service.ts       | ⬜ Not built yet  |
| frontend/src/pages/ManageDevices.tsx         | ⬜ Not built yet  |

## Known Issues
- 🔴 No source code exists — controller, service, route, and frontend page all unbuilt

## Cross-References
| Type           | Ref                                                         |
| -------------- | ----------------------------------------------------------- |
| DB Tables      | devices                                                     |
| UC Files       | BA/UC/Admin/UC025_ManageDevices.md                          |
| Related Module | REVIEW_MOBILE/summaries/DEVICE_summary.md                   |
