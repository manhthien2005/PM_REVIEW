# DEVICES (Admin)

> Sprint 4 | JIRA: EP15-AdminManage | UC: UC025

## Purpose & Technique
- Admin can manage all IoT devices: create, list (paginated), view detail, update metadata, assign/unassign to user, lock/unlock
- All routes require ADMIN role JWT + rate limit 100 req/min
- Validation via `sanitize-html` based custom middleware on create/update/assign

## API Index
| Endpoint | Method | Note |
| -------- | ------ | ---- |
| /api/v1/devices | POST | Auth+Admin, rate limit 100/min |
| /api/v1/devices | GET | Paginated, auth required |
| /api/v1/devices/:id | GET |  |
| /api/v1/devices/:id | PATCH | name, type, model, firmware, cal. |
| /api/v1/devices/:id/assign | PATCH | Requires userId in body |
| /api/v1/devices/:id/unassign | PATCH |  |
| /api/v1/devices/:id/lock | PATCH | Toggle lock |
## File Index
| Path | Role |
| ---- | ---- |
| backend/src/controllers/device.controller.js | Component (3101 bytes) |
| backend/src/services/device.service.js | Component (7781 bytes) |
| backend/src/routes/device.routes.js | Component (3174 bytes) |
| backend/src/__tests__/controllers/device.controller.test.js | Component (4258 bytes) |
| backend/src/__tests__/services/device.service.test.js | Component (9806 bytes) |
| frontend/src/pages/admin/DeviceManagementPage.jsx | Component (10887 bytes) |
| frontend/src/components/devices/AssignDeviceModal.jsx | Component (6841 bytes) |
| DeviceFormModal.jsx | Component (9403 bytes) |
| DevicesConstants.js | Component (1483 bytes) |
| DevicesPagination.jsx | Component (3450 bytes) |
| DevicesTable.jsx | Component (11054 bytes) |
| DevicesToolbar.jsx | Component (3699 bytes) |
| LockDeviceModal.jsx | Component (845 bytes) |
| UnassignDeviceModal.jsx | Component (685 bytes) |
| frontend/src/services/deviceService.js | Component (2374 bytes) |
## Cross-References
| Type           | Ref                                       |
| -------------- | ----------------------------------------- |
| DB Tables      | devices, users, audit_logs                |
| UC Files       | BA/UC/Admin/UC025_ManageDevices.md        |
| Related Module | REVIEW_MOBILE/summaries/DEVICE_summary.md |
