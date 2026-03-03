# 📋 TRELLO CARDS - SPRINT 2: MONITORING CORE

> **Sprint 2**: [Ngày bắt đầu] - [Ngày kết thúc]  
> **Mục tiêu**: Patient/Caregiver xem được chỉ số sức khỏe real-time + history  
> **BE chính**: Mobile BE Dev (FastAPI) — Toàn bộ sprint này phục vụ Mobile App

---

## 🎯 CARD 1: [Device] UC040 - Connect Device

**TITLE**: `[Device] UC040 - Connect Device`

**DESCRIPTION**:
```
UC: BA/UC/Device/UC040_Connect_Device.md
Mục tiêu: Bệnh nhân kết nối thiết bị IoT với tài khoản.
Actor: Bệnh nhân
→ Owner: Mobile BE Dev (API phục vụ Mobile App)
```

**LABELS**:
- Module: `Device`
- Role: `Mobile Backend`, `Mobile`
- Priority: `High`
- Sprint: `Sprint 2`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review UC040

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `POST /api/mobile/devices/register`
  - Request: `{device_code, device_name, device_type}`
  - Response: `{device_id, uuid}`
- [ ] Validate device_code uniqueness
- [ ] Create device trong `devices` table với `user_id` (từ JWT)
- [ ] Generate MQTT client_id cho device
- [ ] Implement API: `GET /api/mobile/devices` (list devices của user)
- [ ] Implement API: `POST /api/mobile/devices/{id}/unbind` (unbind device)

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design "Connect Device" screen
- [ ] Form: device code input (QR scan hoặc manual)
- [ ] Call API, show success + device list
- [ ] Design device list screen
- [ ] Unbind device option

✅ **Tester ([Tester Name])**
- [ ] Test device registration flow
- [ ] Test device list, unbind
- [ ] Test với multiple devices

**ACCEPTANCE CRITERIA**:
- [ ] Device được register và bind với user
- [ ] Device list hiển thị đúng
- [ ] Unbind hoạt động

---

## 🎯 CARD 2: [Device] UC042 - View Device Status

**TITLE**: `[Device] UC042 - View Device Status`

**DESCRIPTION**:
```
UC: BA/UC/Device/UC042_View_Device_Status.md
Mục tiêu: Xem trạng thái thiết bị (online/offline, pin, last_seen).
→ Owner: Mobile BE Dev
```

**LABELS**:
- Module: `Device`
- Role: `Mobile Backend`, `Mobile`
- Priority: `High`
- Sprint: `Sprint 2`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/mobile/devices/{id}/status`
  - Response: `{device_id, is_active, battery_level, signal_strength, last_seen_at, status: "online"|"offline"}`
- [ ] Logic: `last_seen_at < 5 phút` → online, else offline
- [ ] Update `last_seen_at` khi nhận data từ device (MQTT listener)

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design device status card/screen
- [ ] Hiển thị: battery icon, signal icon, online/offline badge
- [ ] Auto-refresh mỗi 30 giây
- [ ] Show "Device offline" warning nếu offline > 10 phút

✅ **Tester ([Tester Name])**
- [ ] Test device status hiển thị đúng
- [ ] Test offline detection

**ACCEPTANCE CRITERIA**:
- [ ] Device status hiển thị real-time
- [ ] Offline detection chính xác

---

## 🎯 CARD 3: [Infra] Data Ingestion Service (MQTT/HTTP)

**TITLE**: `[Infra] Data Ingestion Service (MQTT/HTTP)`

**DESCRIPTION**:
```
Setup service nhận dữ liệu từ simulator/device qua MQTT hoặc HTTP.
→ Owner: Mobile BE Dev (FastAPI — cùng runtime với AI inference)
```

**LABELS**:
- Module: `Infra`
- Role: `Mobile Backend`, `AI`
- Priority: `High`
- Sprint: `Sprint 2`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Setup MQTT broker (Eclipse Mosquitto) hoặc dùng cloud MQTT
- [ ] Implement MQTT subscriber/listener service
- [ ] Implement HTTP endpoint: `POST /api/mobile/telemetry/ingest`
  - Request: `{device_id, vital_signs: {heart_rate, spo2, ...}, motion_data: {...}, timestamp}`
- [ ] Validate data:
  - heart_rate: 40-200 BPM
  - spo2: 70-100%
  - temperature: 35.0-42.0°C
  - accelerometer: -20.0 to 20.0 m/s²
- [ ] Authenticate device (JWT hoặc device token)
- [ ] Write to `vitals` và `motion_data` tables (TimescaleDB)
- [ ] Update `devices.last_seen_at`
- [ ] Error handling: invalid data, device not found, validation failed
- [ ] Log ingestion rate vào `system_metrics`

✅ **AI Dev ([AI Dev])**
- [ ] Review data format
- [ ] Test với sample data từ simulator
- [ ] Verify data quality (signal_quality, motion_artifact flags)

✅ **Tester ([Tester Name])**
- [ ] Test MQTT ingestion với simulator
- [ ] Test HTTP ingestion
- [ ] Test validation (invalid ranges)

**ACCEPTANCE CRITERIA**:
- [ ] Data được ingest thành công từ simulator
- [ ] Validation hoạt động đúng
- [ ] Data được lưu vào TimescaleDB
- [ ] Device status được update

---

## 🎯 CARD 4: [Monitoring] UC006 - View Health Metrics

**TITLE**: `[Monitoring] UC006 - View Health Metrics`

**DESCRIPTION**:
```
UC: BA/UC/Monitoring/UC006_View_Health_Metrics.md
Mục tiêu: Hiển thị chỉ số sức khỏe real-time (HR, SpO2, BP, Temp).
→ Owner: Mobile BE Dev
```

**LABELS**:
- Module: `Monitoring`
- Role: `Mobile Backend`, `Mobile`
- Priority: `High`
- Sprint: `Sprint 2`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review UC006, UC007, UC008
- [ ] Verify business rules: ngưỡng cảnh báo

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/mobile/patients/{id}/vital-signs/latest`
  - Response: `{patient_id, timestamp, vital_signs: {...}, is_stale, alerts: [...]}`
- [ ] Query từ `vitals` table (latest record per device)
- [ ] Apply threshold rules (HR, SpO2, BP, Temp color coding)
- [ ] Check `is_stale`: data > 5 phút → `is_stale=true`
- [ ] Generate alerts nếu abnormal
- [ ] Permission check: patient xem mình, caregiver xem nếu có `can_view_vitals`
- [ ] Implement API: `GET /api/mobile/patients/{id}/vital-signs/history?from=&to=&interval=`
  - Query từ `vitals_5min` hoặc `vitals_hourly` (continuous aggregates)

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design Dashboard screen: Cards HR/SpO2/BP/Temp with colors
- [ ] Line chart (1 giờ gần nhất)
- [ ] Auto-refresh mỗi 5 giây
- [ ] Handle `is_stale` → show "Device offline" warning
- [ ] Handle alerts → show notification badge

✅ **Tester ([Tester Name])**
- [ ] Test metrics real-time
- [ ] Test thresholds: normal (green), warning (yellow), danger (red)
- [ ] Test permission: patient vs caregiver
- [ ] Test auto-refresh

**ACCEPTANCE CRITERIA**:
- [ ] Metrics hiển thị real-time với màu sắc đúng
- [ ] Chart hiển thị 1 giờ gần nhất
- [ ] Device offline được detect
- [ ] Alerts được generate khi abnormal

---

## 🎯 CARD 5: [Monitoring] UC007 - View Health Metrics Detail

**TITLE**: `[Monitoring] UC007 - View Health Metrics Detail`

**LABELS**: Module: `Monitoring`, Role: `Mobile Backend`, `Mobile`, Priority: `Medium`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/mobile/patients/{id}/vital-signs/{metric}/detail?from=&to=`
  - Response: `{metric, period, stats: {min, max, avg, std}, data_points: [...]}`
- [ ] Calculate statistics (min, max, avg, std)

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design detail screen, stats, time range selector (1h, 6h, 24h, 7d)

✅ **Tester ([Tester Name])**
- [ ] Test detail screen, statistics calculation

---

## 🎯 CARD 6: [Monitoring] UC008 - View Health History

**TITLE**: `[Monitoring] UC008 - View Health History`

**LABELS**: Module: `Monitoring`, Role: `Mobile Backend`, `Mobile`, Priority: `Medium`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/mobile/patients/{id}/vital-signs/history?period=day|week|month`
- [ ] Query từ `vitals_daily` (continuous aggregate)

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design history screen + calendar/date picker + charts

✅ **Tester ([Tester Name])**
- [ ] Test history với các periods, date range filter

---

## 📊 SPRINT 2 SUMMARY

**Total Cards**: 6  
**BE Ownership**: 100% Mobile BE Dev (FastAPI)  
**Admin BE Dev**: Không có task trong sprint này → có thể hỗ trợ Mobile BE hoặc làm trước Sprint 4 Admin cards

**Estimated Effort (Mobile BE Dev)**: ~9-14 days

---

**Cập nhật lần cuối**: 02/03/2026  
**Version**: 2.0 — Restructured for 2-BE architecture
