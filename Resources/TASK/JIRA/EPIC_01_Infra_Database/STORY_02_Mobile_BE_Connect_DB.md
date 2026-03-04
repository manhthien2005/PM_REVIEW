# 💳 STORY: [Mobile BE] Kết nối DB & Chuẩn bị SQLAlchemy Models

## Thông tin Story

| Thuộc tính       | Giá trị                                             |
| :--------------- | :-------------------------------------------------- |
| **Issue Type**   | Story                                               |
| **Epic Link**    | EPIC-01: [Infra] Thiết lập Database & TimescaleDB   |
| **Summary**      | [Mobile BE] Kết nối DB & Chuẩn bị SQLAlchemy Models |
| **Assignee**     | Mobile BE Dev                                       |
| **Story Points** | 2                                                   |
| **Priority**     | 🟠 High                                              |
| **Labels**       | `Backend`, `Infra`, `Sprint-1`                      |
| **Component**    | `Mobile-BE`                                         |

## Mô tả

Review database schema đã được Admin BE tạo, test kết nối từ FastAPI (SQLAlchemy) tới PostgreSQL, và chuẩn bị SQLAlchemy models reflect từ DB.

## Acceptance Criteria

- [ ] Review database schema để hiểu structure (tất cả 11 tables)
- [ ] Test kết nối PostgreSQL từ FastAPI (SQLAlchemy engine)
- [ ] Chuẩn bị SQLAlchemy models reflect từ DB (automap hoặc viết tay)
- [ ] Verify có thể query data thành công từ FastAPI

## Linked Issues

- **Blocked by:** STORY_01 (Admin BE setup DB trước)
