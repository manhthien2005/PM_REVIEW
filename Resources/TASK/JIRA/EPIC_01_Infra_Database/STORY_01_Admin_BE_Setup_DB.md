# 💳 STORY: [Admin BE] Setup PostgreSQL & Chạy SQL Scripts

## Thông tin Story

| Thuộc tính       | Giá trị                                           |
| :--------------- | :------------------------------------------------ |
| **Issue Type**   | Story                                             |
| **Epic Link**    | EPIC-01: [Infra] Thiết lập Database & TimescaleDB |
| **Summary**      | [Admin BE] Setup PostgreSQL & Chạy SQL Scripts    |
| **Assignee**     | Admin BE Dev                                      |
| **Story Points** | 3                                                 |
| **Priority**     | 🔴 Highest                                         |
| **Labels**       | `Backend`, `Infra`, `Sprint-1`                    |
| **Component**    | `Admin-BE`                                        |

## Mô tả

Cài đặt PostgreSQL + TimescaleDB extension trên môi trường phát triển (Dev) và chạy toàn bộ 9 file SQL scripts theo đúng thứ tự.

## Acceptance Criteria

- [ ] Setup PostgreSQL + TimescaleDB extension trên dev environment
- [ ] Chạy tuần tự các file SQL scripts (01 → 09):
  - `01_init_timescaledb.sql`
  - `02_create_tables_user_management.sql`
  - `03_create_tables_devices.sql`
  - `04_create_tables_timeseries.sql`
  - `05_create_tables_events_alerts.sql`
  - `06_create_tables_ai_analytics.sql`
  - `07_create_tables_system.sql`
  - `08_create_indexes.sql`
  - `09_create_policies.sql`
- [ ] Verify tất cả tables đã tạo: `users`, `devices`, `vitals`, `motion_data`, `fall_events`, `sos_events`, `alerts`, `risk_scores`, `risk_explanations`, `audit_logs`, `system_metrics`
- [ ] Verify 44 indexes đã được tạo
- [ ] Verify compression/retention policies đã active
- [ ] Test insert sample data vào mỗi table
- [ ] Document connection string, credentials (chia sẻ cho team)

## Linked Issues

- **Blocks:** STORY_02 (Mobile BE kết nối DB), STORY_03 (AI review schema), STORY_04 (QA test)
