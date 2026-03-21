# Phase 7 — Thông báo & Cấu hình (Polishing)

> **Screens:** 10 màn hình — Tất cả ⬜ Missing
> **Status:** Spec ✅ 10/10 | Built ⬜ 0/10

---

## Phase Goal

Phase 7 là **polishing** — thêm cuối cùng. AUTH_Onboarding không blocking (có thể skip). Các màn còn lại: Notification Center, Settings, Emergency Contacts, Sleep History/Settings, Risk History, Device Configure.

**Unlock:** App hoàn chỉnh. User có thể quản lý thông báo, SĐT khẩn cấp gọi ngoài app khi SOS, và cài đặt nâng cao.

**Lưu ý sau cross-check:** Phase 7 không chỉ phụ thuộc vào self flow. Notification deep-link và các history screen phải tôn trọng luôn cả `linked profile context`.

---

## Dependency Matrix

| Prerequisite | Source | Hard Stop? |
| --- | --- | --- |
| Phase 3 (Sleep, Risk) | Phase 3 | Yes — Sleep History, Risk History |
| Phase 5 (Family linked flow) | Phase 5 | Partial — notification deep-link cho linked profile |
| Phase 2 (Device) | Phase 2 | Yes — DEVICE_Configure |
| Phase 4 (SOS) | Phase 4 | Partial — Emergency Contacts gọi khi SOS |
| FCM | App config | Yes — Notification Settings |

---

## Multi-Agent Brainstorming Block

### Skeptic / Challenger
- **SLEEP_History:** Không fetch 30 đêm cùng lúc. Cần lazy load / pagination. Ghi rõ trong spec.
- NOTIFICATION_Settings: Toggle "Nhận thông báo SOS" OFF → sync với FCM unsubscribe. Có delay không?
- Emergency Contacts: SĐT gọi ngoài app khi SOS — format validation (VN: 10 số). Có giới hạn số lượng không?

### Constraint Guardian
- **NOTIFICATION_Settings phải sync FCM topic subscription** — không chỉ là UI toggle. Mỗi toggle OFF → unsubscribe. ON → subscribe.
- SLEEP_TrackingSettings: Giờ đi ngủ dự kiến, nhắc nhở — cần local notification permission.
- ANALYSIS_RiskHistory: Lazy load. Không load toàn bộ lịch sử 1 lần.
- NOTIFICATION_Detail deep-link tới `SLEEP_Report` / `ANALYSIS_RiskReport` phải truyền tiếp `profileId` nếu notification thuộc linked profile.

### User Advocate
- Notification Center: Mỗi item có icon theo loại (SOS, Sleep, Risk, System). Tap → deep-link vào màn tương ứng.
- Emergency Contacts: "SĐT gọi khi SOS" — giải thích rõ: "Đây là số sẽ được gọi tự động khi bạn phát SOS".

---

## TASK Prompt (Copy-paste)

```
@mobile-agent mode TASK

TASK generate Phase 7 — 10 màn hình còn thiếu. Chạy từng nhóm:

---

Nhóm 1 — NOTIFICATION (5 màn):
1. NOTIFICATION_Center — Inbox tập trung tất cả thông báo. UC031
2. NOTIFICATION_Detail — Deep-link từng loại thông báo (SOS, Sleep, Risk, System). UC031
3. NOTIFICATION_EmergencyContacts — Danh sách SĐT gọi ngoài app khi SOS. UC030
4. NOTIFICATION_AddEditContact — Thêm/sửa SĐT khẩn cấp. UC030
5. NOTIFICATION_Settings — Tắt/bật từng loại thông báo. UC031
   - QUAN TRỌNG: Mỗi toggle phải sync FCM subscribe/unsubscribe. Không chỉ lưu DB.

---

Nhóm 2 — SLEEP (2 màn):
6. SLEEP_History — Xu hướng giấc ngủ nhiều đêm. UC021
   - Lazy load / pagination. Không fetch 30 đêm cùng lúc.
7. SLEEP_TrackingSettings — Giờ đi ngủ dự kiến, nhắc nhở. UC020

---

Nhóm 3 — ANALYSIS, DEVICE, AUTH (3 màn):
8. ANALYSIS_RiskHistory — Lịch sử điểm rủi ro AI. UC016. Lazy load.
9. DEVICE_Configure — Cài đặt nâng cao của đồng hồ. UC041
10. AUTH_Onboarding — Hướng dẫn lần đầu. Không blocking. Thêm cuối.

---

Context: Architecture Hybrid v3.0. Link từ PROFILE_Overview, HOME_Dashboard. Notification Center có icon theo loại. Emergency Contacts: SĐT format VN 10 số. Nếu notification thuộc linked profile, payload phải giữ được `profileId`.
```

---

## Screens to Generate

| Screen | File | UC Ref | Key Flow |
| --- | --- | --- | --- |
| NOTIFICATION_Center | `NOTIFICATION_Center.md` | UC031 | List notifications, icon theo type, deep-link |
| NOTIFICATION_Detail | `NOTIFICATION_Detail.md` | UC031 | Deep-link → SOS/Sleep/Risk/System screen |
| NOTIFICATION_EmergencyContacts | `NOTIFICATION_EmergencyContacts.md` | UC030 | List SĐT, add/edit |
| NOTIFICATION_AddEditContact | `NOTIFICATION_AddEditContact.md` | UC030 | Form SĐT, validation VN |
| NOTIFICATION_Settings | `NOTIFICATION_Settings.md` | UC031 | Toggles + FCM sync |
| SLEEP_History | `SLEEP_History.md` | UC021 | List nhiều đêm, lazy load |
| SLEEP_TrackingSettings | `SLEEP_TrackingSettings.md` | UC020 | Giờ ngủ, nhắc nhở |
| ANALYSIS_RiskHistory | `ANALYSIS_RiskHistory.md` | UC016 | List lịch sử, lazy load |
| DEVICE_Configure | `DEVICE_Configure.md` | UC041 | Cài đặt nâng cao đồng hồ |
| AUTH_Onboarding | `AUTH_Onboarding.md` | — | Hướng dẫn lần đầu, skip được |

---

## Acceptance Gate

- [x] 10 file spec tồn tại *(2026-03-17)*
- [x] NOTIFICATION_Settings có ghi chú FCM sync
- [x] SLEEP_History, ANALYSIS_RiskHistory có ghi chú lazy load
- [x] Emergency Contacts có validation SĐT VN
- [x] Cross-links từ PROFILE_Overview, HOME_Dashboard
- [ ] Notification deep-link self/linked đều truyền đúng context (`profileId`, `reportId`, `date` khi cần)
- [ ] `TASK sync` không báo broken link

> **health_system**: Phase 7 chưa implement. Tất cả spec-only.
