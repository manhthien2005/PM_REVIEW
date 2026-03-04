# 💳 STORY: [AI] Review Schema cho AI/ML Pipeline

## Thông tin Story

| Thuộc tính       | Giá trị                                           |
| :--------------- | :------------------------------------------------ |
| **Issue Type**   | Story                                             |
| **Epic Link**    | EPIC-01: [Infra] Thiết lập Database & TimescaleDB |
| **Summary**      | [AI] Review Schema cho AI/ML Pipeline             |
| **Assignee**     | AI Dev                                            |
| **Story Points** | 1                                                 |
| **Priority**     | 🟠 High                                            |
| **Labels**       | `AI`, `Infra`, `Sprint-1`                         |
| **Component**    | `AI-Models`                                       |

## Mô tả

Review các bảng dữ liệu liên quan trực tiếp đến AI/ML pipeline để đảm bảo schema phù hợp cho việc trích xuất features và lưu trữ kết quả.

## Acceptance Criteria

- [ ] Review schema cho bảng `vitals` (dữ liệu sinh tồn — input chính cho AI)
- [ ] Review schema cho bảng `motion_data` (dữ liệu gia tốc — input cho Fall Detection)
- [ ] Review schema cho bảng `risk_scores` + `risk_explanations` (output của Risk Scoring)
- [ ] Verify TimescaleDB hypertables hoạt động đúng (compression, chunking)
- [ ] Xác nhận data format phù hợp cho feature extraction (window queries)

## Linked Issues

- **Blocked by:** STORY_01 (Admin BE setup DB trước)
