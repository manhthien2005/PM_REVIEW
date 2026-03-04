# 🏗️ EPIC 01: [Infra] Thiết Lập Database & TimescaleDB

## Thông tin Epic

| Thuộc tính    | Giá trị                                  |
| :------------ | :--------------------------------------- |
| **Epic Key**  | EPIC-01                                  |
| **Epic Name** | [Infra] Thiết lập Database & TimescaleDB |
| **Priority**  | 🔴 Highest                                |
| **Sprint**    | Sprint 1                                 |
| **Nguồn**     | TRELLO_SPRINT1.md (Card 1)               |

## Mô tả

Setup PostgreSQL + TimescaleDB extension, chạy tất cả SQL scripts từ `SQL SCRIPTS/` để khởi tạo toàn bộ schema cho dự án HealthGuard.

**Đây là Epic nền tảng nhất** — mọi Epic khác đều phụ thuộc vào việc DB đã sẵn sàng.

## Acceptance Criteria (Cấp Epic)

- [ ] Tất cả 11 tables đã được tạo thành công
- [ ] 44 indexes đã được tạo
- [ ] Compression/retention policies đã active
- [ ] Sample data insert thành công
- [ ] Cả Admin BE (Node.js) và Mobile BE (FastAPI) đều connect và query được

## Danh sách Stories trong Epic này

| STT  | Story                                                 | Assignee      | Story Points | Component |
| :--- | :---------------------------------------------------- | :------------ | :----------- | :-------- |
| 1    | `[Admin BE] Setup PostgreSQL & Chạy SQL Scripts`      | Admin BE Dev  | 3            | Admin-BE  |
| 2    | `[Mobile BE] Kết nối DB & Chuẩn bị SQLAlchemy Models` | Mobile BE Dev | 2            | Mobile-BE |
| 3    | `[AI] Review Schema cho AI/ML Pipeline`               | AI Dev        | 1            | AI-Models |
| 4    | `[QA] Kiểm tra kết nối DB & CRUD cơ bản`              | Tester        | 2            | QA        |

## Dependencies

- **Blocks:** Epic 02, Epic 03, Epic 04 (tất cả các Epic còn lại)
- **Blocked by:** Không có (Epic đầu tiên)

## Ghi chú

- SQL SCRIPTS/ là **single source of truth** cho DB schema
- Cả 2 Backend KHÔNG tự tạo migration, chỉ dùng schema từ SQL scripts
- Cần setup trên cả local dev và staging environment
