# Phase 2 — Thiết bị + Dashboard cơ bản

> **Screens:** DEVICE_List, DEVICE_Connect, DEVICE_StatusDetail, HOME_Dashboard
> **Status:** Spec ✅ 4/4 | Built: DEVICE_List ✅, HOME_Dashboard ✅ | Connect (Dialog), StatusDetail (spec only)

---

## Phase Goal

Không có thiết bị = không có data. Phase 2 unlock luồng kết nối đồng hồ và màn hình Dashboard mặc định sau login. HOME_Dashboard phải handle state `No_Device` khi user chưa ghép cặp đồng hồ.

**Unlock cho phase sau:** Device connected → vitals data → Phase 3 (Monitoring, Sleep, Risk).

---

## Dependency Matrix

| Prerequisite | Source | Hard Stop? |
| --- | --- | --- |
| Phase 1 (Auth + Bottom Nav) | Phase 1 | Yes |
| DEVICE_List spec | Screen/ | Yes — đã có |
| BLE / pairing API | Backend | Yes |
| HOME_Dashboard spec | Screen/ | Yes — đã có |

---

## Multi-Agent Brainstorming Block

### Skeptic / Challenger
- **No device = no data:** HOME_Dashboard khi chưa có đồng hồ phải hiển thị rõ "Kết nối đồng hồ để đo chỉ số" + CTA "Kết nối thiết bị". Không được crash, không hiển thị "`--`" trống không.
- BLE pairing timeout: Đồng hồ không phản hồi trong 30s → có thông báo "Không tìm thấy thiết bị. Thử lại?" không?
- User đang ở DEVICE_Connect, đồng hồ đã pair từ app khác → có conflict không?

### Constraint Guardian
- **BLE pairing flow** có latency cao (5–15s). Cần loading state rõ ràng, không block UI.
- Timeout handling bắt buộc: Không để user chờ vô hạn.
- DEVICE_StatusDetail: Battery %, connection status, last sync time — API phải có.

### User Advocate
- Người già: Màn Connect cần hướng dẫn từng bước (1. Bật Bluetooth, 2. Đeo đồng hồ, 3. Bấm "Tìm kiếm").
- DEVICE_StatusDetail: Pin yếu (< 20%) cần cảnh báo rõ, không chỉ số nhỏ.

---

## TASK Prompt (Copy-paste)

```
@mobile-agent mode TASK

TASK generate DEVICE — Tạo spec cho 2 màn hình còn thiếu:
1. DEVICE_Connect — Ghép cặp đồng hồ lần đầu (BLE scan, pairing, timeout)
2. DEVICE_StatusDetail — Xem pin, trạng thái kết nối, last sync

Context:
- DEVICE_List đã có spec. Connect và StatusDetail link từ List.
- HOME_Dashboard đã có spec. Verify state No_Device có CTA "Kết nối thiết bị" → DEVICE_Connect.
- Architecture: Hybrid v3.0. Không Profile Switcher. Device management chỉ cho Self.
- UC Ref: UC040 (Connect), UC041 (Configure), UC042 (List, StatusDetail)

Sau khi generate, chạy TASK sync để validate cross-links.
```

---

## Screens to Generate

| Screen | File | UC Ref | Key Flow |
| --- | --- | --- | --- |
| DEVICE_Connect | `DEVICE_Connect.md` | UC040 | Scan BLE → Select device → Pair → Success/Timeout |
| DEVICE_StatusDetail | `DEVICE_StatusDetail.md` | UC042 | Battery, connection status, last sync, link to Configure |

---

## Acceptance Gate

- [x] DEVICE_Connect.md tồn tại *(2026-03-17)*
- [x] DEVICE_StatusDetail.md tồn tại với link đến DEVICE_Configure
- [x] DEVICE_List.md tồn tại với cross-link Connect, StatusDetail
- [ ] HOME_Dashboard No_Device state có CTA → DEVICE_Connect *(verify trong code)*
- [ ] `TASK sync` không báo broken link

> **health_system**: DeviceScreen dùng Dialog "Đăng ký thiết bị" (form thủ công) thay vì BLE Connect. Xem [PROGRESS_REPORT.md](../PROGRESS_REPORT.md).
