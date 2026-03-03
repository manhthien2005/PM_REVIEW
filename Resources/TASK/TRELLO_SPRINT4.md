# 📋 TRELLO CARDS - SPRINT 4: RISK & AI + ADMIN + SLEEP

> **Sprint 4**: [Ngày bắt đầu] - [Ngày kết thúc]  
> **Mục tiêu**: Risk scoring, Admin dashboard, Sleep analysis  
> **BE phân chia rõ**: Cards 1-4 → Mobile BE Dev | Cards 5-8 → Admin BE Dev

---

## 🎯 CARD 1: [Analysis] UC016 - View Risk Report

**TITLE**: `[Analysis] UC016 - View Risk Report`

**LABELS**: Module: `Analysis`, Role: `Mobile Backend`, `AI`, `Mobile`, Priority: `High`

**CHECKLIST**:

✅ **PM/BA ([PM/BA Name])**
- [ ] Review UC016, UC017
- [ ] Verify: cần 24h data, đánh giá lại sau 1h

✅ **AI Dev ([AI Dev])**
- [ ] Implement Risk Scoring Model (XGBoost):
  - Input: 22 features (HRV, HR, BP, SpO2, demographics)
  - Output: Risk score (0-100), Level (LOW/MEDIUM/HIGH/CRITICAL)
- [ ] Feature extraction từ vitals (24h window)
- [ ] Implement internal API: `POST /ai/risk-scoring`
- [ ] XAI: Implement SHAP explainer (top 5 factors)
- [ ] Store vào `risk_scores` + `risk_explanations` tables
- [ ] Schedule job: risk score mỗi 6 giờ

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/mobile/patients/{id}/risk-score/latest`
  - Response: `{score, level, calculated_at, explanation: {top_factors, text}}`
- [ ] Cache logic: có score < 1h → return cached, else → trigger AI
- [ ] Implement API: `GET /api/mobile/patients/{id}/risk-score/history?from=&to=`
- [ ] Permission check (patient/caregiver)
- [ ] If HIGH/CRITICAL → Create alert (`alert_type='high_risk_score'`)

✅ **Mobile FE Dev ([Mobile FE Dev])**
- [ ] Design Risk Report screen: score (0-100), color, XAI section, trend chart

✅ **Tester ([Tester Name])**
- [ ] Test risk score calculation, caching, alerts

---

## 🎯 CARD 2: [Analysis] UC017 - View Risk Report Detail

**LABELS**: Module: `Analysis`, Role: `Mobile Backend`, `Mobile`, Priority: `Medium`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/mobile/risk-scores/{id}`
- [ ] Query `risk_scores` + `risk_explanations` tables

✅ **Mobile FE Dev** + **Tester**: [Detail screen, feature importance visualization]

---

## 🎯 CARD 3: [Sleep] UC020 - Analyze Sleep

**TITLE**: `[Sleep] UC020 - Analyze Sleep`

**LABELS**: Module: `Sleep`, Role: `Mobile Backend`, `AI`, Priority: `Medium`

**CHECKLIST**:

✅ **AI Dev ([AI Dev])**
- [ ] Implement Sleep Analysis algorithm (heuristics hoặc ML):
  - Input: HR, HRV, motion_data (8-10h night window)
  - Detect stages: Awake, Light, Deep, REM
  - Calculate: duration, efficiency, quality score

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Tạo bảng `sleep_sessions` nếu chưa có (via SQL SCRIPTS/)
- [ ] Implement sleep analysis service (gọi AI algorithm)
- [ ] Schedule job: phân tích sleep mỗi sáng

✅ **Tester**: Test sleep analysis output

**NOTES**: Cần thêm file vào `SQL SCRIPTS/` cho bảng `sleep_sessions`

---

## 🎯 CARD 4: [Sleep] UC021 - View Sleep Report

**LABELS**: Module: `Sleep`, Role: `Mobile Backend`, `Mobile`, Priority: `Medium`

**CHECKLIST**:

✅ **Mobile BE Dev ([Mobile BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/mobile/patients/{id}/sleep/latest`
- [ ] Implement API: `GET /api/mobile/patients/{id}/sleep/history?from=&to=`

✅ **Mobile FE Dev** + **Tester**: [Sleep report UI, charts]

---

## 🎯 CARD 5: [Admin] UC022 - Manage Users

**TITLE**: `[Admin] UC022 - Manage Users`

**LABELS**: Module: `Admin`, Role: `Admin Backend`, `Frontend`, Priority: `High`

**CHECKLIST**:

✅ **Admin BE Dev ([Admin BE Dev])** ⭐ Owner
- [ ] Implement APIs (prefix `/api/admin/`):
  - `GET /api/admin/users` (list, search, filter, paginate)
  - `POST /api/admin/users` (create user)
  - `GET /api/admin/users/{id}` (detail)
  - `PUT /api/admin/users/{id}` (update)
  - `DELETE /api/admin/users/{id}` (soft delete)
  - `POST /api/admin/users/{id}/lock` (lock/unlock)
- [ ] Permission check: ADMIN role only
- [ ] Audit log: ghi mọi action

✅ **Admin FE Dev ([Admin FE Dev])**
- [ ] Design "Manage Users" page: table, search, filters, pagination
- [ ] Add/Edit user modals, Delete confirmation, Lock/Unlock

✅ **Tester ([Tester Name])**
- [ ] Test CRUD, search, filters, pagination, permission, audit logs

---

## 🎯 CARD 6: [Admin] UC025 - Manage Devices

**TITLE**: `[Admin] UC025 - Manage Devices`

**LABELS**: Module: `Admin`, Role: `Admin Backend`, `Frontend`, Priority: `Medium`

**CHECKLIST**:

✅ **Admin BE Dev ([Admin BE Dev])** ⭐ Owner
- [ ] Implement APIs:
  - `GET /api/admin/devices` (list all)
  - `GET /api/admin/devices/{id}` (detail)
  - `PUT /api/admin/devices/{id}` (update)
  - `POST /api/admin/devices/{id}/assign` (assign to user)
  - `POST /api/admin/devices/{id}/lock` (lock/unlock)
- [ ] Permission: ADMIN only

✅ **Admin FE Dev**: Device management page  
✅ **Tester**: Test device CRUD, assign, lock/unlock

---

## 🎯 CARD 7: [Admin] UC024 - Configure System

**TITLE**: `[Admin] UC024 - Configure System`

**LABELS**: Module: `Admin`, Role: `Admin Backend`, `Frontend`, Priority: `Medium`

**CHECKLIST**:

✅ **Admin BE Dev ([Admin BE Dev])** ⭐ Owner
- [ ] Implement APIs:
  - `GET /api/admin/settings`
  - `PUT /api/admin/settings`
- [ ] Settings: Vital thresholds, AI config, notification settings, retention policies
- [ ] Load settings vào memory/cache khi start

✅ **Admin FE Dev**: System Settings page  
✅ **Tester**: Test settings update & apply

---

## 🎯 CARD 8: [Admin] UC026 - View System Logs

**TITLE**: `[Admin] UC026 - View System Logs`

**LABELS**: Module: `Admin`, Role: `Admin Backend`, `Frontend`, Priority: `Low`

**CHECKLIST**:

✅ **Admin BE Dev ([Admin BE Dev])** ⭐ Owner
- [ ] Implement API: `GET /api/admin/logs` (filter, paginate)
- [ ] Export CSV

✅ **Admin FE Dev**: Logs page + filters + export  
✅ **Tester**: Test logs display, filters, export

---

## 📊 SPRINT 4 SUMMARY

**Total Cards**: 8

| Card Group | Owner | Cards | Effort |
|-----------|-------|-------|--------|
| Risk & AI (1-2) | Mobile BE Dev + AI Dev | 2 | 4-6 days |
| Sleep (3-4) | Mobile BE Dev + AI Dev | 2 | 3-5 days |
| Admin (5-8) | Admin BE Dev | 4 | 5-8 days |

**Workload cân bằng**: Sprint 4 là sprint admin BE Dev làm nhiều nhất, bù lại cho Sprint 2-3 rảnh.

---

**Cập nhật lần cuối**: 02/03/2026  
**Version**: 2.0 — Restructured for 2-BE architecture
