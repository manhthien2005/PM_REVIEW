# BASIC RULES - BÁO CÁO MÔN HỌC (HEALTHGUARD)

## 1) Phạm vi source và vai trò từng folder

- [HealthGuard](HealthGuard): source Web Admin Dashboard.
- [model_be](model_be): source API backend, chứa các API đã nạp model (dự đoán, phân tích...), được xem là CORE.
- [Iot_Simulator](Iot_Simulator): source giả lập thiết bị IoT, được xem là CORE.
- [health_system](health_system): source app mobile, được xem là CORE.
- [PM_REVIEW](PM_REVIEW): source tài liệu đối chiếu để hiểu nghiệp vụ, kiến trúc, use case, sprint, và tiến độ review.

## 2) Thứ tự đọc tài liệu bắt buộc (để lấy đúng context)

1. Đọc [PM_REVIEW/MASTER_INDEX.md](PM_REVIEW/MASTER_INDEX.md) trước.
2. Đọc [PM_REVIEW/Resources/SRS_INDEX.md](PM_REVIEW/Resources/SRS_INDEX.md) để nắm tổng quan yêu cầu.
3. Nếu cần review Admin: đọc [PM_REVIEW/REVIEW_ADMIN/Project_Structure.md](PM_REVIEW/REVIEW_ADMIN/Project_Structure.md).
4. Nếu cần review Mobile: đọc [PM_REVIEW/REVIEW_MOBILE/Project_Structure.md](PM_REVIEW/REVIEW_MOBILE/Project_Structure.md).
5. Cần đối chiếu DB: đọc [PM_REVIEW/SQL SCRIPTS/README.md](PM_REVIEW/SQL%20SCRIPTS/README.md).
6. Cần đối chiếu UC chi tiết: đọc [PM_REVIEW/Resources/UC](PM_REVIEW/Resources/UC).

## 3) Rule cơ bản khi làm báo cáo

- Luôn xác định module đang đánh giá thuộc hệ nào: Admin, Mobile, API core, hoặc Simulator core.
- Luôn đối chiếu 3 lớp: UC/SRS -> Source code -> Database/API.
- Không kết luận theo cảm tính; mọi nhận định phải có bằng chứng từ file/endpoint/table cụ thể.
- Ưu tiên phát hiện: sai yêu cầu UC, thiếu API, sai phân quyền, sai mapping dữ liệu, thiếu test.
- Phân tích rủi ro theo mức độ: P0 (blocker), P1 (nghiêm trọng), P2 (cần cải tiến).
- Nếu có xung đột tài liệu và code: ghi rõ "Doc là nguồn tham chiếu, code là trạng thái thực tế".

## 4) Các nhóm nội dung báo cáo nên có

- Mục tiêu và phạm vi.
- Hiện trạng implementation theo module.
- Đối chiếu với UC/SRS (đạt/chưa đạt/một phần).
- Vấn đề tồn đọng + mức độ ưu tiên.
- Đề xuất hướng xử lý và thứ tự thực hiện.

## 5) Rule truy vết nhanh theo module

- Admin Dashboard: bắt đầu từ [HealthGuard](HealthGuard) + [PM_REVIEW/REVIEW_ADMIN/summaries](PM_REVIEW/REVIEW_ADMIN/summaries).
- Mobile App: bắt đầu từ [health_system](health_system) + [PM_REVIEW/REVIEW_MOBILE/summaries](PM_REVIEW/REVIEW_MOBILE/summaries).
- API core model: bắt đầu từ [model_be](model_be) và đối chiếu với UC Analysis/Sleep/Monitoring trong [PM_REVIEW/Resources/UC](PM_REVIEW/Resources/UC).
- Device simulation core: bắt đầu từ [Iot_Simulator](Iot_Simulator), đối chiếu luồng dữ liệu ingestion và event với [PM_REVIEW/Resources/UC/Device](PM_REVIEW/Resources/UC/Device) và [PM_REVIEW/SQL SCRIPTS](PM_REVIEW/SQL%20SCRIPTS).

## 6) Checklist trước khi chốt mỗi phần báo cáo

1. Đã xác định đúng module và đúng source folder chưa?
2. Đã có bằng chứng từ code/tài liệu/DB chưa?
3. Đã đối chiếu với UC liên quan chưa?
4. Đã đánh mục ưu tiên P0/P1/P2 chưa?
5. Đã nêu đề xuất hành động cụ thể cho team chưa?
