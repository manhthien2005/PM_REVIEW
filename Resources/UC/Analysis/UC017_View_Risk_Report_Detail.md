# UC017 - XEM CHI TIẾT BÁO CÁO RỦI RO SỨC KHỎE

## Bảng đặc tả Use Case

| Thuộc tính | Nội dung |
|------------|----------|
| **Mã UC** | UC017 |
| **Tên UC** | Xem chi tiết báo cáo đánh giá rủi ro |
| **Tác nhân chính** | Bệnh nhân, Người chăm sóc |
| **Mô tả** | Người dùng xem chi tiết một lần đánh giá rủi ro cụ thể (đã được tạo trong UC016), bao gồm các yếu tố đóng góp, lịch sử và khuyến nghị chi tiết. |
| **Trigger** | Người dùng từ màn hình UC016 chọn "Xem chi tiết" tại một bản ghi đánh giá cụ thể. |
| **Tiền điều kiện** | - Đã tồn tại ít nhất một bản ghi `risk_scores` cho bệnh nhân.<br>- Người dùng có quyền xem dữ liệu của bệnh nhân tương ứng. |
| **Hậu điều kiện** | Người dùng nắm rõ nguyên nhân dẫn đến mức rủi ro hiện tại và hành động khuyến nghị. |

---

## Luồng chính (Main Flow)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 1 | Người dùng | Từ màn hình UC016, chọn một đánh giá rủi ro (VD: bản mới nhất hoặc 1 bản cũ trong lịch sử). |
| 2 | Hệ thống | Lấy chi tiết từ bảng `risk_scores` và `risk_explanations` tương ứng (`risk_explanations.risk_score_id`). |
| 3 | Hệ thống | Hiển thị:<br>- Điểm rủi ro và mức độ (LOW/MEDIUM/HIGH/CRITICAL).<br>- Thời gian đánh giá, loại rủi ro (`risk_type`).<br>- Top các yếu tố ảnh hưởng (feature importance) dưới dạng danh sách/bars. |
| 4 | Hệ thống | Hiển thị phần "Giải thích" (explanation_text) dưới dạng đoạn văn dễ hiểu. |
| 5 | Hệ thống | Hiển thị danh sách "Khuyến nghị hành động" (`recommendations`). |
| 6 | Người dùng | (Tuỳ chọn) Chọn "Xem lịch sử rủi ro tương tự" để xem các lần rủi ro cao trước đó. |

---

## Luồng thay thế (Alternative Flows)

### 2.a - Không tìm thấy bản ghi giải thích (XAI)

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 2.a.1 | Hệ thống | Không có bản ghi trong `risk_explanations` tương ứng với `risk_score_id`. |
| 2.a.2 | Hệ thống | Hiển thị thông báo "Chưa có dữ liệu giải thích chi tiết, chỉ hiển thị điểm rủi ro". |

### 3.a - Người chăm sóc xem báo cáo cho nhiều bệnh nhân

| Bước | Người thực hiện | Hành động |
|------|----------------|-----------|
| 3.a.1 | Người chăm sóc | Từ danh sách bệnh nhân, chọn 1 bệnh nhân rồi vào UC016/UC017. |
| 3.a.2 | Hệ thống | Chỉ hiển thị báo cáo cho những bệnh nhân mà caregiver có quyền (`can_view_vitals = true`). |

---

## Business Rules

- **BR-017-01**: Dữ liệu hiển thị trong UC017 phải là snapshot đúng thời điểm đánh giá (dựa vào `features` lưu trong `risk_scores`), không tính toán lại theo dữ liệu hiện tại. 
- **BR-017-02**: Nếu `risk_level` là `high` hoặc `critical`, màn hình chi tiết phải hiển thị cảnh báo nổi bật (màu cam/đỏ, icon cảnh báo). 
- **BR-017-03**: Nội dung giải thích (`explanation_text`) phải ở dạng ngôn ngữ tự nhiên, tránh thuật ngữ kỹ thuật khó hiểu. 
- **BR-017-04**: Khuyến nghị (`recommendations`) phải là danh sách gạch đầu dòng, tối đa 5 mục để tránh quá tải thông tin. 

---

## Yêu cầu phi chức năng

- **Transparency**: 
  - Luôn hiển thị rõ "Đây là công cụ hỗ trợ, không thay thế chẩn đoán y khoa". 
- **Performance**: 
  - Thời gian tải chi tiết báo cáo < 1 giây (vì dữ liệu đã có sẵn trong DB). 
- **Privacy**: 
  - Chỉ cho phép chia sẻ/export báo cáo khi bệnh nhân đồng ý (tuỳ chọn bật/tắt trong phần cài đặt quyền riêng tư). 

