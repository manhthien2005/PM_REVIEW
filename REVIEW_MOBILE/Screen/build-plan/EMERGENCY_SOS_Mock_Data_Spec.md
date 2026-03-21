# EMERGENCY SOS — Mock Data Spec (Gửi Dev)

> **Mục đích**: Tài liệu mô tả các API mock cần implement để Mobile app (EmergencySOSReceivedListScreen, EmergencySOSDetailScreen) hoạt động khi chưa có backend thật.  
> **Đối tượng**: Dev Backend / Dev Mock Server.

---

## 1. Tổng Quan API Cần Mock

| # | Method | Path | Mô tả |
|---|--------|------|-------|
| 1 | GET | `/api/v1/mobile/emergency/caregiver/sos-alerts` | Danh sách SOS nhận được (Caregiver) |
| 2 | GET | `/api/v1/mobile/emergency/sos/{sosId}` | Chi tiết 1 SOS |
| 3 | POST | `/api/v1/mobile/emergency/sos/trigger` | Gửi SOS thủ công (Patient) |
| 4 | POST | `/api/v1/mobile/emergency/sos/{sosId}/resolve` | Xác nhận đã xử lý SOS (Caregiver) |

---

## 2. API 1 — Danh Sách SOS Nhận Được

### Request

```
GET /api/v1/mobile/emergency/caregiver/sos-alerts?status={status}
```

**Query params:**

| Param | Type | Values | Mô tả |
|-------|------|--------|-------|
| status | string | `all` \| `active` \| `resolved` | Filter theo trạng thái |

**Headers:** `Authorization: Bearer {token}` (required)

### Response 200

```json
{
  "sos_alerts": [
    {
      "sos_id": "sos-001",
      "patient": {
        "user_id": 101,
        "full_name": "Trần Thị B",
        "avatar_url": null,
        "phone": "0901234567"
      },
      "trigger_type": "manual",
      "trigger_time": "2026-03-19T08:30:00.000Z",
      "status": "active",
      "location": {
        "latitude": 10.762622,
        "longitude": 106.660172,
        "accuracy": 15.5,
        "address": "123 Nguyễn Huệ, Quận 1, TP.HCM",
        "last_updated": "2026-03-19T08:30:05.000Z"
      },
      "fall_detection_xai": null,
      "resolution": null
    },
    {
      "sos_id": "sos-002",
      "patient": {
        "user_id": 102,
        "full_name": "Nguyễn Văn A",
        "avatar_url": null,
        "phone": "0912345678"
      },
      "trigger_type": "fall_detected",
      "trigger_time": "2026-03-18T14:20:00.000Z",
      "status": "resolved",
      "location": {
        "latitude": 10.775689,
        "longitude": 106.701234,
        "accuracy": 20.0,
        "address": "456 Lê Lợi, Quận 3, TP.HCM",
        "last_updated": "2026-03-18T14:20:10.000Z"
      },
      "fall_detection_xai": {
        "confidence": 92.5,
        "timeline": [
          {
            "time": "14:19:58",
            "description": "Phát hiện chuyển động bất thường"
          },
          {
            "time": "14:20:00",
            "description": "Xác nhận té ngã"
          }
        ]
      },
      "resolution": {
        "resolved_by_name": "Chị Lan",
        "resolved_at": "2026-03-18T14:35:00.000Z",
        "notes": "Đã đến hiện trường, bệnh nhân ổn định"
      }
    }
  ]
}
```

### Schema Chi Tiết

**sos_alerts[] (mỗi item):**

| Field | Type | Required | Mô tả |
|-------|------|----------|-------|
| sos_id | string | ✅ | ID duy nhất của SOS (dùng cho route, resolve) |
| patient | object | ✅ | Thông tin người gửi SOS |
| patient.user_id | number | ✅ | ID user (convert sang string ở client) |
| patient.full_name | string | ✅ | Tên đầy đủ |
| patient.avatar_url | string \| null | ❌ | URL avatar |
| patient.phone | string | ✅ | SĐT (dùng cho nút gọi) |
| trigger_type | string | ✅ | `manual` \| `fall_detected` \| `vital_critical` |
| trigger_time | string | ✅ | ISO 8601 datetime |
| status | string | ✅ | `active` \| `resolved` |
| location | object | ✅ | Vị trí GPS |
| location.latitude | number \| null | ❌ | Vĩ độ |
| location.longitude | number \| null | ❌ | Kinh độ |
| location.accuracy | number \| null | ❌ | Độ chính xác (mét) |
| location.address | string \| null | ❌ | Địa chỉ text |
| location.last_updated | string | ✅ | ISO 8601 datetime |
| fall_detection_xai | object \| null | ❌ | Chỉ có khi trigger_type = fall_detected |
| fall_detection_xai.confidence | number | ✅ | 0–100 |
| fall_detection_xai.timeline | array | ✅ | [{ time, description }] |
| resolution | object \| null | ❌ | Chỉ có khi status = resolved |
| resolution.resolved_by_name | string | ✅ | Tên người xử lý |
| resolution.resolved_at | string | ✅ | ISO 8601 datetime |
| resolution.notes | string \| null | ❌ | Ghi chú |

### Mock Data Gợi Ý (3 items)

```json
{
  "sos_alerts": [
    {
      "sos_id": "sos-mock-2-001",
      "patient": {
        "user_id": 2,
        "full_name": "Trần Thị B",
        "avatar_url": null,
        "phone": "0901234567"
      },
      "trigger_type": "manual",
      "trigger_time": "2026-03-19T08:30:00.000Z",
      "status": "active",
      "location": {
        "latitude": 10.762622,
        "longitude": 106.660172,
        "accuracy": 15.5,
        "address": "123 Nguyễn Huệ, Quận 1, TP.HCM",
        "last_updated": "2026-03-19T08:30:05.000Z"
      },
      "fall_detection_xai": null,
      "resolution": null
    },
    {
      "sos_id": "sos-mock-1-002",
      "patient": {
        "user_id": 1,
        "full_name": "Nguyễn Văn A",
        "avatar_url": null,
        "phone": "0912345678"
      },
      "trigger_type": "manual",
      "trigger_time": "2026-03-19T07:15:00.000Z",
      "status": "active",
      "location": {
        "latitude": 10.775689,
        "longitude": 106.701234,
        "accuracy": 20.0,
        "address": "456 Lê Lợi, Quận 3, TP.HCM",
        "last_updated": "2026-03-19T07:15:10.000Z"
      },
      "fall_detection_xai": null,
      "resolution": null
    },
    {
      "sos_id": "sos-mock-3-003",
      "patient": {
        "user_id": 3,
        "full_name": "Phạm Văn C",
        "avatar_url": null,
        "phone": "0987654321"
      },
      "trigger_type": "fall_detected",
      "trigger_time": "2026-03-18T14:20:00.000Z",
      "status": "resolved",
      "location": {
        "latitude": 10.801234,
        "longitude": 106.712345,
        "accuracy": 12.0,
        "address": "789 Hai Bà Trưng, Quận 3, TP.HCM",
        "last_updated": "2026-03-18T14:20:10.000Z"
      },
      "fall_detection_xai": {
        "confidence": 92.5,
        "timeline": [
          { "time": "14:19:58", "description": "Phát hiện chuyển động bất thường" },
          { "time": "14:20:00", "description": "Xác nhận té ngã" }
        ]
      },
      "resolution": {
        "resolved_by_name": "Chị Lan",
        "resolved_at": "2026-03-18T14:35:00.000Z",
        "notes": "Đã đến hiện trường, bệnh nhân ổn định"
      }
    }
  ]
}
```

**Lưu ý filter `status`:**
- `all` → trả về cả 3 item
- `active` → chỉ item có `status: "active"` (2 item đầu)
- `resolved` → chỉ item có `status: "resolved"` (1 item cuối)

---

## 3. API 2 — Chi Tiết SOS

### Request

```
GET /api/v1/mobile/emergency/sos/{sosId}
```

**Path params:** `sosId` — ID SOS (vd: `sos-mock-2-001`)

**Headers:** `Authorization: Bearer {token}`

### Response 200

Cùng schema với 1 item trong `sos_alerts` (không bọc trong array):

```json
{
  "sos_id": "sos-mock-2-001",
  "patient": {
    "user_id": 2,
    "full_name": "Trần Thị B",
    "avatar_url": null,
    "phone": "0901234567"
  },
  "trigger_type": "manual",
  "trigger_time": "2026-03-19T08:30:00.000Z",
  "status": "active",
  "location": {
    "latitude": 10.762622,
    "longitude": 106.660172,
    "accuracy": 15.5,
    "address": "123 Nguyễn Huệ, Quận 1, TP.HCM",
    "last_updated": "2026-03-19T08:30:05.000Z"
  },
  "fall_detection_xai": null,
  "resolution": null
}
```

**Response 404:** Khi `sosId` không tồn tại.

---

## 4. API 3 — Gửi SOS Thủ Công

### Request

```
POST /api/v1/mobile/emergency/sos/trigger
Content-Type: application/json
```

**Body:**

```json
{
  "trigger_type": "manual",
  "latitude": 10.762622,
  "longitude": 106.660172,
  "address": "123 Nguyễn Huệ, Quận 1, TP.HCM"
}
```

| Field | Type | Required | Mô tả |
|-------|------|----------|-------|
| trigger_type | string | ✅ | Luôn `manual` |
| latitude | number | ❌ | Vĩ độ (nếu có GPS) |
| longitude | number | ❌ | Kinh độ |
| address | string | ❌ | Địa chỉ text |

### Response 200/201

```json
{
  "sos_id": "sos-new-001",
  "recipients_notified": 2,
  "message": "Đã gửi tín hiệu khẩn cấp thành công"
}
```

**Mock:** Có thể trả về `recipients_notified: 1` hoặc `2` — Mobile dùng cho SosConfirmScreen.

---

## 5. API 4 — Xác Nhận Đã Xử Lý SOS

### Request

```
POST /api/v1/mobile/emergency/sos/{sosId}/resolve
Content-Type: application/json
```

**Body:**

```json
{
  "resolution_status": "safe_confirmed",
  "notes": "Đã đến hiện trường, bệnh nhân ổn định"
}
```

| Field | Type | Required | Mô tả |
|-------|------|----------|-------|
| resolution_status | string | ✅ | `safe_confirmed` \| `false_alarm` \| ... |
| notes | string | ❌ | Ghi chú |

### Response 200

```json
{
  "success": true,
  "message": "Đã xác nhận xử lý SOS"
}
```

**Mock:** Luôn trả 200. Sau khi resolve, GET detail cùng `sosId` nên trả `status: "resolved"` và có `resolution`.

---

## 6. Base URL & Auth

| Môi trường | Base URL |
|------------|----------|
| Dev (Android emulator) | `http://10.0.2.2:8080/api/v1/mobile` |
| Dev (iOS simulator) | `http://localhost:8080/api/v1/mobile` |
| Dev (device) | `http://{IP máy dev}:8080/api/v1/mobile` |

**Auth:** Tất cả API cần header `Authorization: Bearer {access_token}`. Mock có thể:
- Bỏ qua token (chấp nhận mọi request)
- Hoặc validate token đơn giản

---

## 7. Mapping Với Family Mock

Để **Family Dashboard overlay** và **Tab SOS** đồng bộ:

- `FamilyProfileSnapshot.sosId` khi `isSosActive` = `sos-mock-2-001` (Mẹ - id=2)
- API GET `/emergency/sos/sos-mock-2-001` phải trả về đúng item tương ứng

**Khuyến nghị:** Dùng `sos-mock-{profileId}-001` làm convention để dễ map.

---

## 8. Checklist Cho Dev Mock

- [ ] GET `/api/v1/mobile/emergency/caregiver/sos-alerts?status=all|active|resolved` → trả 3 item mock
- [ ] GET `/api/v1/mobile/emergency/sos/{sosId}` → trả 1 item tương ứng (sos-mock-2-001, sos-mock-1-002, sos-mock-3-003)
- [ ] POST `/api/v1/mobile/emergency/sos/trigger` → trả 200, `recipients_notified`
- [ ] POST `/api/v1/mobile/emergency/sos/{sosId}/resolve` → trả 200
- [ ] Filter `status=active` chỉ trả item `status: "active"`
- [ ] Filter `status=resolved` chỉ trả item `status: "resolved"`

---

*Mock Spec v1.0 — 2026-03-19*
