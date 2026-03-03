# 📋 TRELLO CARDS - SPRINT 3: EMERGENCY & NOTIFICATION

> **Sprint 3**: [Ngày bắt đầu] - [Ngày kết thúc]  
> **Mục tiêu**: Flow té ngã + SOS hoạt động end-to-end  
> **BE chính**: Mobile BE Dev (FastAPI) — Toàn bộ sprint phục vụ Mobile App

---

## 🎯 CARD 1: [Notification] UC030 - Configure Emergency Contacts

**TITLE**: `[Notification] UC030 - Configure Emergency Contacts`

**LABELS**: Module: `Notification`, Role: `Mobile Backend`, `Mobile`, Priority: `High`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement CRUD APIs:
  - `GET /api/mobile/emergency-contacts`
  - `POST /api/mobile/emergency-contacts`
  - `PUT /api/mobile/emergency-contacts/{id}`
  - `DELETE /api/mobile/emergency-contacts/{id}`
- [ ] Validate phone format
- [ ] Priority: 1-5 (1 = gọi đầu tiên)
- [ ] Store vào `emergency_contacts` table

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design "Emergency Contacts" screen (Settings)
- [ ] List contacts với priority, Add/Edit/Delete forms
- [ ] Notification preferences (SMS, Call checkboxes)

✅ **Tester ([Tester Name])**
- [ ] Test CRUD operations, priority ordering, phone validation

---

## 🎯 CARD 2: [Emergency] UC010 - Confirm After Fall Alert

**TITLE**: `[Emergency] UC010 - Confirm After Fall Alert`

**LABELS**: Module: `Emergency`, Role: `Mobile Backend`, `AI`, `Mobile`, Priority: `High`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review UC010, UC014
- [ ] Verify: confidence > 85%, countdown 30s

✅ **AI Dev ([AI Dev])**
- [ ] Implement Fall Detection AI service
- [ ] Input: motion_data window (6 seconds, 50Hz = 300 samples)
- [ ] Output: fall probability (0-1), confidence
- [ ] Threshold: > 0.85 → trigger alert
- [ ] Store fall event vào `fall_events` table
- [ ] XAI: Generate explanation (timeline)

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Integrate AI service vào data pipeline:
  - Khi nhận motion_data → trigger AI inference
  - Nếu fall detected → create `fall_events` record
- [ ] Implement API: `POST /api/mobile/fall-events/{id}/confirm` (user confirm an toàn)
- [ ] Implement API: `POST /api/mobile/fall-events/{id}/trigger-sos` (auto trigger sau 30s)
- [ ] Update `fall_events.user_responded_at`, `user_cancelled`
- [ ] If not cancelled → trigger SOS flow
- [ ] Create alert: `alert_type='fall_detected'`
- [ ] Send push notification (FCM) khi fall detected

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design fall alert screen (full-screen overlay): countdown 30s, "TÔI KHÔNG SAO" button, "GỌI CỨU HỘ" button
- [ ] Listen to push notification: `fall_detected` event
- [ ] Vibrate + sound alert
- [ ] Call confirm/trigger-sos APIs

✅ **Tester ([Tester Name])**
- [ ] Test: Fall detected → Alert → User confirm → Cancel
- [ ] Test: Không phản hồi 30s → Auto trigger SOS
- [ ] Test AI confidence threshold, push notification delivery

---

## 🎯 CARD 3: [Emergency] UC014 - Send Manual SOS

**TITLE**: `[Emergency] UC014 - Send Manual SOS`

**LABELS**: Module: `Emergency`, Role: `Mobile Backend`, `Mobile`, Priority: `High`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Verify: giữ nút 3s, hủy trong 5 phút

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `POST /api/mobile/sos/manual-trigger`
  - Request: `{device_id, latitude, longitude}`
  - Response: `{sos_event_id, status}`
- [ ] Create `sos_events` record: `trigger_type='manual'`
- [ ] Get Emergency Contacts (sort by priority)
- [ ] Send notifications: Push (FCM) + SMS (nếu `notify_via_sms=true`)
- [ ] Create `alerts` records cho mỗi contact
- [ ] Implement API: `POST /api/mobile/sos/{id}/cancel` (cancel trong 5 phút)
- [ ] Send cancel notification

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design SOS button (big, red) + long press 3s → confirmation
- [ ] Get GPS location
- [ ] Design Emergency Mode screen + cancel countdown

✅ **Tester ([Tester Name])**
- [ ] Test full SOS flow, cancel within 5 minutes
- [ ] Test push + SMS delivery

---

## 🎯 CARD 4: [Emergency] UC015 - Receive SOS Notification

**TITLE**: `[Emergency] UC015 - Receive SOS Notification`

**LABELS**: Module: `Emergency`, Role: `Mobile Backend`, `Mobile`, Priority: `High`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/mobile/sos/active` (list active SOS for caregiver)
- [ ] Implement API: `GET /api/mobile/sos/{id}` (SOS detail)
- [ ] Implement API: `POST /api/mobile/sos/{id}/respond`
  - Request: `{action: "acknowledged"|"resolved", notes}`
- [ ] Send notification đến patient khi caregiver respond

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design SOS notification + detail screen (patient info, GPS map, timeline)
- [ ] "Đã nhận được" + "Đã giải quyết" buttons

✅ **Tester ([Tester Name])**
- [ ] Test receive SOS, acknowledge, resolve
- [ ] Test với multiple caregivers

---

## 🎯 CARD 5: [Emergency] UC011 - Confirm Safety Resolution

**TITLE**: `[Emergency] UC011 - Confirm Safety Resolution`

**LABELS**: Module: `Emergency`, Role: `Mobile Backend`, `Mobile`, Priority: `Medium`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `POST /api/mobile/sos/{id}/resolve`
- [ ] Update `sos_events.status='resolved'`, `resolved_at`, `resolved_by_user_id`
- [ ] Send notification to all parties

✅ **Mobile FE Dev** + **Tester**: [Tương tự phiên bản trước]

---

## 🎯 CARD 6: [Notification] UC031 - Manage Notifications

**TITLE**: `[Notification] UC031 - Manage Notifications`

**LABELS**: Module: `Notification`, Role: `Mobile Backend`, `Mobile`, Priority: `Medium`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement APIs:
  - `GET /api/mobile/alerts` (list, filter by type/severity/unread)
  - `POST /api/mobile/alerts/{id}/read`
  - `POST /api/mobile/alerts/{id}/acknowledge`
  - `GET /api/mobile/notification-settings`
  - `PUT /api/mobile/notification-settings`

✅ **Mobile FE Dev** + **Tester**: [UI + test notification center + settings]

---

## 📊 SPRINT 3 SUMMARY

**Total Cards**: 6  
**BE Ownership**: 100% Mobile BE Dev (FastAPI)  
**Admin BE Dev**: Không có task → nên làm trước Sprint 4 Admin cards (Cards 5-8) hoặc hỗ trợ Mobile BE

**Estimated Effort (Mobile BE Dev)**: ~10-15 days

---

**Cập nhật lần cuối**: 02/03/2026  
**Version**: 2.0 — Restructured for 2-BE architecture
