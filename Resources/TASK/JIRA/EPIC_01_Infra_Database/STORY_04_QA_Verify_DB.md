# 💳 STORY: [QA] Kiểm Tra Kết Nối DB & CRUD Cơ Bản

## Thông tin Story

| Thuộc tính       | Giá trị                                           |
| :--------------- | :------------------------------------------------ |
| **Issue Type**   | Story                                             |
| **Epic Link**    | EPIC-01: [Infra] Thiết lập Database & TimescaleDB |
| **Summary**      | [QA] Kiểm tra kết nối DB & CRUD cơ bản            |
| **Assignee**     | Tester                                            |
| **Story Points** | 2                                                 |
| **Priority**     | 🟠 High                                            |
| **Labels**       | `QA`, `Infra`, `Sprint-1`                         |
| **Component**    | `QA`                                              |

## Mô tả

Xác minh rằng Database đã được setup đúng, cả 2 backend đều kết nối được, và các thao tác CRUD cơ bản hoạt động ổn định.

## Test Cases

### TC-01: Kết nối Database
- [ ] Verify Admin Backend (Node.js/Prisma) connect thành công tới PostgreSQL
- [ ] Verify Mobile Backend (FastAPI/SQLAlchemy) connect thành công tới PostgreSQL
- [ ] Verify connection string & credentials đúng

### TC-02: CRUD Operations
- [ ] Test INSERT sample data vào các tables chính (`users`, `devices`, `vitals`)
- [ ] Test SELECT / query data vừa insert
- [ ] Test UPDATE data
- [ ] Test DELETE data

### TC-03: TimescaleDB Features
- [ ] Verify TimescaleDB continuous aggregates refresh đúng
- [ ] Verify compression policies đã active
- [ ] Verify retention policies hoạt động

## Linked Issues

- **Blocked by:** STORY_01 (DB phải setup xong), STORY_02 (Mobile BE phải connect được)
