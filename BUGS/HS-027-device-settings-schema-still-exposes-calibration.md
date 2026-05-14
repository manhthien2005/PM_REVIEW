# Bug HS-027: DeviceSettingsRequest schema van expose 3 calibration field

**Status:** Open
**Repo(s):** health_system (backend)
**Module:** backend/app/schemas/device.py
**Severity:** Medium (Phase 4 gap)
**Reporter:** ThienPDM (via Phase 4 reverify 2026-05-14)
**Created:** 2026-05-14

## Symptom

Test fail: test_device_service.py::test_hs003_settings_request_rejects_dropped_calibration_keys
AssertionError: assert 'heart_rate_offset' not in fields set

## Root cause

Phase 4 Session B BLOCK 4 (HS-003) chi drop:
- DB column (migration 20260514_drop_calibration_offsets.sql)
- ORM attribute trong device_model.py

Nhung MISS:
- Pydantic schema field trong backend/app/schemas/device.py DeviceSettingsRequest van con 3 field:
  - heart_rate_offset
  - spo2_calibration
  - temperature_offset

Per ADR-012 va HS-003 sub-task 1, schema PHAI drop cung.

## Impact

- Mobile app set 3 field qua PUT /mobile/devices/id/settings -> Pydantic accept (validation pass) nhung BE service khong persist (column khong ton tai DB) -> silent data loss
- Hoac service code con reference -> SQL error "column does not exist" -> 500
- Schema-level drift: spec ADR-012 noi drop, code partial

## Fix

Branch: fix/hs-027-drop-calibration-schema-fields tu develop.

File: backend/app/schemas/device.py - class DeviceSettingsRequest

Action:
1. Remove 3 field declaration: heart_rate_offset, spo2_calibration, temperature_offset
2. Verify service code khong reference 3 field nay (grep + remove neu con)
3. Verify mobile parser khong fail (FE chi expose 3 notify toggle, KHONG gui calibration)

## Verification

```
pytest backend/tests/test_device_service.py::test_hs003_settings_request_rejects_dropped_calibration_keys
# Expect pass
```

## Related

- ADR-012 drop-calibration-offset-fields (Accepted)
- HS-003 (resolved Phase 4 BLOCK 4 partial - ORM + DB only)
- HS-015 (resolved) - extra=forbid added. Combined HS-027 fix reject calibration field at Pydantic boundary
- BE_M05 schemas audit da flag truoc Phase 4 line 43-44

## Effort

~30 min: 3 line removal + verify test pass.
