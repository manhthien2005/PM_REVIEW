# UC042 - XEM TRẠNG THÁI THIẾT BỊ (v2 — Phase 0.5)

> **v2 rationale (2026-05-13):** BR-042-01 explicit ngưỡng online = 5 phút (match code hardcode). Add BR-042-03 cho attention zone (battery + offline heuristic) để align với FE `_deviceNeedsAttention()` behavior. Self-correct `last_sync_at` status: KHÔNG phải dead column (verified `telemetry.py:287-291` có update path), bug thực là FE heuristic edge case — xem **HS-003 sub-task 3**.

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                                                                      |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC042                                                                                                                                         |
| **Tên UC**         | Xem trạng thái thiết bị                                                                                                                       |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc                                                                                                                     |
| **Mô tả**          | Người dùng xem danh sách + chi tiết thiết bị đã pair: online/offline, mức pin, tín hiệu, thời điểm gần nhất thiết bị gửi heartbeat.            |
| **Trigger**        | Mở màn `DeviceScreen` hoặc `DeviceStatusDetailScreen`.                                                                                         |
| **Tiền điều kiện** | Người dùng đã đăng nhập.                                                                                                                      |
| **Hậu điều kiện**  | Người dùng nắm được tình trạng thiết bị để xử lý khi offline/hết pin.                                                                         |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động                                                                                                                                                                                                    |
| ---- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1    | Người dùng      | Mở màn "Thiết bị".                                                                                                                                                                                           |
| 2    | Client          | Gọi `GET /mobile/devices?status=all&limit=100&offset=0`.                                                                                                                                                     |
| 3    | Hệ thống (BE)   | Query `devices` WHERE `user_id = :user_id AND deleted_at IS NULL`. Compute `is_online` per row: `is_active && last_seen_at >= (now - 5 phút)`.                                                               |
| 4    | Client          | Render list: priority cards, attention zone (**BR-042-03**), filter toolbar (type / status), rename/toggle/delete action.                                                                                    |
| 5    | Người dùng      | Chọn 1 device thì mở `DeviceStatusDetailScreen` (hoặc dùng data từ list nếu đã có).                                                                                                                          |
| 6    | Hệ thống        | Hiển thị hero card (tên, type, pin, online/offline), insight banner nếu attention (**Alt 5.a**), info sections (firmware, MAC, serial, last_seen_at), CTA "Cài đặt" gọi UC041.                              |

---

## Luồng thay thế (Alternative Flows)

### 3.a - Không có thiết bị nào pair

| Bước  | Người thực hiện | Hành động                                                                                                                                   |
| ----- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.a.1 | Hệ thống (BE)   | Query trả empty list (total = 0).                                                                                                            |
| 3.a.2 | Client          | Render empty state: icon + "Bạn chưa kết nối thiết bị nào" + CTA "Kết nối thiết bị mới" (chạy UC040).                                       |

### 5.a - Device trong attention zone (offline / low battery)

| Bước  | Người thực hiện | Hành động                                                                                                                                                                |
| ----- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 5.a.1 | Client          | `_deviceNeedsAttention(device)` = TRUE theo **BR-042-03**.                                                                                                               |
| 5.a.2 | Client          | Insight banner hiển thị message cụ thể: "Pin thiết bị dưới 20%, vui lòng sạc" hoặc "Thiết bị đã mất kết nối X giờ. Vui lòng kiểm tra".                                    |

### 3.b - Query fail (DB missing devices table edge case)

| Bước  | Người thực hiện | Hành động                                                                                                                  |
| ----- | --------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 3.b.1 | Hệ thống (BE)   | `ProgrammingError` "relation devices does not exist" (DB chưa migrate).                                                    |
| 3.b.2 | Hệ thống (BE)   | Return empty list thay vì 500 (defensive pattern trong `get_user_devices`). Client treat as empty, trigger empty state (Alt 3.a). |

---

## Business Rules

- **BR-042-01** (code canonical): Trạng thái online được tính: `is_active = TRUE AND last_seen_at >= (now - 5 phút)`. Ngưỡng 5 phút hardcode trong `device_service.py` (`timedelta(minutes=5)`). Phù hợp với interval IoT sim gửi heartbeat (30-60s), 2 phút từ UC cũ quá aggressive gây false offline khi network jitter.
- **BR-042-02** (low battery alert): `battery_level <= 20` thì đưa device vào attention zone (FE tự render warning, không push notification separate — đồ án 2 scope).
- **BR-042-03** (FE attention zone heuristic): Device cần attention nếu:
  - `battery_level <= 20`, HOẶC
  - `is_active = TRUE AND last_sync_at IS NULL AND now - registered_at >= 1 giờ` (grace period), HOẶC
  - `last_sync_at != NULL AND now - last_sync_at >= 24 giờ`.
  - **Self-correction note (2026-05-13):** `last_sync_at` KHÔNG phải dead column. Verified trong `telemetry.py:287-291` (vitals ingest path) + IoT sim `dependencies.py:1046-1050` (ADR-013 direct-DB path). Cả 2 flow đều UPDATE `devices.last_sync_at = NOW()`. Bug thực là FE heuristic edge case: device vừa pair xong chưa có vitals telemetry đầu tiên thì `last_sync_at = NULL` trigger attention sai. Fix Phase 4 (HS-003 sub-task 3): thêm grace period 1h sau `registered_at` trước khi enforce rule sync.
- **BR-042-04**: Người chăm sóc (caregiver theo UC linked contacts) KHÔNG được list device của patient qua endpoint này. UC042 actor "Người chăm sóc" thực hiện qua family dashboard (out of scope UC042 v2 — defer cross-UC).

---

## State rendering rules

| State                      | Indicator                                                 |
| -------------------------- | --------------------------------------------------------- |
| `is_active && is_online`   | Icon xanh, status "Đang hoạt động"                        |
| `is_active && !is_online`  | Icon xám, status "Offline"                                |
| `!is_active`               | Icon mờ, status "Đã tắt"                                  |
| `battery_level <= 20`      | Warning banner nhỏ "Pin yếu"                              |
| Attention (**BR-042-03**)  | Device được sort lên top list, insight banner khi mở detail |

---

## Yêu cầu phi chức năng

- **Usability**: State thể hiện bằng icon + màu (xanh online, xám offline, đỏ critical). Touch target >= 48dp (medical app accessibility).
- **Performance**: GET devices < 1s cho user có 1-5 device. Tránh N+1: endpoint không join thêm table khác.
- **Reliability**: `get_user_devices` defensive với missing table error, trả empty, không crash route.

---

## Implementation references

- Route: `health_system/backend/app/api/routes/device.py` (`get_devices`, `get_device`)
- Service: `health_system/backend/app/services/device_service.py` (`get_user_devices`, `get_device_by_id`, `_map_device_row`)
- Schema: `health_system/backend/app/schemas/device.py` (`DeviceItemResponse`, `DeviceListResponse`)
- FE list screen: `health_system/lib/features/device/screens/device_screen.dart`
- FE detail screen: `health_system/lib/features/device/screens/device_status_detail_screen.dart`
- FE attention logic: `health_system/lib/features/device/providers/device_provider.dart` (`_deviceNeedsAttention`)
- Related bugs: **HS-003** sub-task 3 (FE attention heuristic grace period, self-corrected Low severity)
