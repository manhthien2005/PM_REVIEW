# DEVICES (Admin)

> Sprint 4 | JIRA: EP15-AdminManage | UC: UC025

## Purpose & Technique
- Admin can manage all IoT devices: create, list (paginated), view detail, update metadata, assign/unassign to user, lock/unlock
- All routes require ADMIN role JWT + rate limit 100 req/min
- Validation via `sanitize-html` based custom middleware on create/update/assign

## API Index
| Endpoint                         | Method | Note                              |
| -------------------------------- | ------ | --------------------------------- |
| /api/v1/devices                  | POST   | Create device (validated)         |
| /api/v1/devices                  | GET    | List devices (paginated)          |
| /api/v1/devices/:id              | GET    | Device detail                     |
| /api/v1/devices/:id              | PATCH  | Update device metadata            |
| /api/v1/devices/:id/assign       | PATCH  | Assign device to user (userId)    |
| /api/v1/devices/:id/unassign     | PATCH  | Unassign device from user         |
| /api/v1/devices/:id/lock         | PATCH  | Toggle lock/unlock                |

## File Index
| Path                                                        | Role                                |
| ----------------------------------------------------------- | ----------------------------------- |
| backend/src/controllers/device.controller.js                | All device route handlers (3101B)   |
| backend/src/services/device.service.js                      | Device CRUD + assign logic (7781B)  |
| backend/src/routes/device.routes.js                         | Route definitions + validation (3174B) |
| backend/src/__tests__/controllers/device.controller.test.js | Controller tests (4258B)            |
| backend/src/__tests__/services/device.service.test.js       | Service tests (9806B)               |
| frontend/src/pages/admin/DeviceManagementPage.jsx           | Device management page (10887B)     |
| frontend/src/components/devices/AssignDeviceModal.jsx       | Assign device modal (6841B)         |
| frontend/src/components/devices/DeviceFormModal.jsx         | Create/Edit device modal (9403B)    |
| frontend/src/components/devices/DevicesConstants.js         | Device module constants (1483B)     |
| frontend/src/components/devices/DevicesPagination.jsx       | Pagination component (3450B)        |
| frontend/src/components/devices/DevicesTable.jsx            | Devices data table (11054B)         |
| frontend/src/components/devices/DevicesToolbar.jsx          | Toolbar and search (3699B)          |
| frontend/src/components/devices/LockDeviceModal.jsx         | Lock confirmation (845B)            |
| frontend/src/components/devices/UnassignDeviceModal.jsx     | Unassign confirmation (685B)        |
| frontend/src/services/deviceService.js                      | Frontend device API calls (2374B)   |

## Cross-References
| Type           | Ref                                       |
| -------------- | ----------------------------------------- |
| DB Tables      | devices, users, audit_logs                |
| UC Files       | BA/UC/Admin/UC025_ManageDevices.md        |
| Related Module | REVIEW_MOBILE/summaries/DEVICE_summary.md |
