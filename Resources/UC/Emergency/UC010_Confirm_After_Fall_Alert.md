# UC010 - XÁC NHẬN AN TOÀN SAU CẢNH BÁO TÉ NGÃ

## Bảng đặc tả Use Case

| Thuộc tính         | Nội dung                                                                                       |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| **Mã UC**          | UC010                                                                                          |
| **Tên UC**         | Xác nhận an toàn sau cảnh báo té ngã                                                           |
| **Tác nhân chính** | Bệnh nhân                                                                                      |
| **Mô tả**          | Bệnh nhân xác nhận tình trạng an toàn hoặc không phản hồi sau khi hệ thống phát hiện té ngã    |
| **Trigger**        | Hệ thống AI phát hiện mẫu hình té ngã (độ tin cậy > 85%)                                       |
| **Tiền điều kiện** | - Thiết bị IoT đang hoạt động<br>- AI đã phát hiện té ngã<br>- Có cấu hình người giám sát      |
| **Hậu điều kiện**  | - Cảnh báo được hủy (nếu xác nhận an toàn)<br>- Hoặc SOS được gửi tự động (nếu không phản hồi) |

---

## Luồng chính (Main Flow) - Xác nhận an toàn

| Bước | Người thực hiện | Hành động                                                                                                                                                               |
| ---- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Hệ thống        | Phát hiện té ngã (từ AI service - xem Technical Spec)                                                                                                                   |
| 2    | Mobile App      | Rung + phát âm thanh cảnh báo                                                                                                                                           |
| 3    | Mobile App      | Hiển thị cảnh báo với:<br>- Countdown 30 giây<br>- Nút "TÔI KHÔNG SAO" (to, nổi bật)<br>- Lý do phát hiện (VD: "Va đập mạnh + Thay đổi hướng đột ngột")<br>- Vị trí GPS |
| 4    | Bệnh nhân       | Nhấn "TÔI KHÔNG SAO"                                                                                                                                                    |
| 5    | Hệ thống        | Hủy cảnh báo và ghi log "False alarm"                                                                                                                                   |
| 6    | Hệ thống        | Hiển thị "Cảm ơn bạn đã xác nhận"                                                                                                                                       |

---

## Luồng thay thế (Alternative Flows)

### 4.a - Không phản hồi trong 30 giây
| Bước  | Người thực hiện | Hành động                                                                                              |
| ----- | --------------- | ------------------------------------------------------------------------------------------------------ |
| 4.a.1 | Hệ thống        | Countdown hết thời gian                                                                                |
| 4.a.2 | Hệ thống        | Xác nhận sự kiện té ngã có thật                                                                        |
| 4.a.3 | Hệ thống        | Kích hoạt **UC014 - Gửi SOS khẩn cấp**                                                                 |
| 4.a.4 | Hệ thống        | Gửi thông báo đến người giám sát:<br>"🚨 [Tên] có dấu hiệu té ngã. Không phản hồi. Vị trí: [Maps link]" |

### 4.b - Bấm nút SOS thay vì "Không sao"
| Bước  | Người thực hiện | Hành động                                           |
| ----- | --------------- | --------------------------------------------------- |
| 4.b.1 | Bệnh nhân       | Nhấn nút "GỌI CỨU HỘ" (nếu cần giúp đỡ)             |
| 4.b.2 | Hệ thống        | Kích hoạt **UC014 - Gửi SOS khẩn cấp** ngay lập tức |

---

## Giải thích phát hiện té ngã (XAI)

Khi hiển thị cảnh báo, ứng dụng giải thích tại sao:

**Ví dụ hiển thị:**
```
⚠️ Phát hiện té ngã (Độ tin cậy: 92%)

Timeline:
━━━━━━━━━━━━━━━━━
0.0s: Đang đi bộ bình thường
0.5s: Gia tốc tăng đột ngột (15 m/s²) ← Va đập
0.8s: Phát hiện va đập mạnh
1.2s: Thay đổi hướng 90° ← Ngã
1.5s: Không chuyển động ← Nằm yên

→ Đây là dấu hiệu té ngã
```

---

## Business Rules

- **BR-010-01**: Chỉ kích hoạt cảnh báo nếu AI confidence > 85%
- **BR-010-02**: Thời gian countdown: 30 giây
- **BR-010-03**: Nếu không phản hồi → Tự động gửi SOS
- **BR-010-04**: Cho phép người dùng feedback "False alarm" để cải thiện AI
- **BR-010-05**: Khi user xác nhận "TÔI KHÔNG SAO", cho phép chọn/nhập lý do hủy (VD: "Vấp nhẹ", "Ngồi xuống nhanh", "Khác") để cải thiện mô hình AI

---

## Yêu cầu phi chức năng

- **Accuracy**: 
  - Sensitivity (phát hiện được té ngã) > 90% (HG-FUNC-05)
  - Specificity (không báo nhầm) > 85%
- **Performance**: Thời gian từ té ngã đến cảnh báo < 5 giây
- **Safety**: Ưu tiên Sensitivity > Specificity (tránh bỏ sót)
- **Usability**: 
  - Countdown timer rõ ràng
  - Nút "TÔI KHÔNG SAO" to, dễ bấm khi hoảng loạn
