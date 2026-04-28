# CHƯƠNG 2. PHÂN TÍCH YÊU CẦU HỆ THỐNG

## 2.1. Khảo sát hiện trạng và phát biểu bài toán

Hiện nay, việc theo dõi sức khỏe người cao tuổi và người có bệnh nền chủ yếu dựa vào quan sát trực tiếp, khám định kỳ, hoặc các thiết bị đo riêng lẻ không kết nối với nhau. Cách làm này có ba hạn chế lớn:

- Không theo dõi liên tục, nên khó phát hiện sớm các dấu hiệu bất thường giữa hai lần khám.
- Dữ liệu nằm rải rác ở nhiều nơi, khó tổng hợp để đánh giá xu hướng sức khỏe theo thời gian.
- Khi xảy ra sự cố khẩn cấp (ví dụ: té ngã), việc liên lạc giữa người bệnh, người thân và bộ phận hỗ trợ còn chậm và thiếu phối hợp.

Từ thực trạng đó, dự án HealthGuard đặt ra mục tiêu: xây dựng hệ thống giám sát sức khỏe có khả năng thu thập dữ liệu liên tục, tự động phân tích rủi ro, cảnh báo sớm và cung cấp công cụ quản trị tập trung.

Về mặt kỹ thuật, hệ thống gồm bốn tầng chính:

- **Tầng thiết bị/mô phỏng**: tạo ra dữ liệu sinh hiệu (nhịp tim, SpO2...) và dữ liệu vận động (gia tốc, con quay).
- **Tầng xử lý nghiệp vụ**: nhận dữ liệu, lưu trữ, kiểm tra ngưỡng và điều phối các luồng xử lý.
- **Tầng AI**: phân tích dữ liệu để phát hiện té ngã, đánh giá nguy cơ sức khỏe, phân tích giấc ngủ.
- **Tầng ứng dụng**: giao diện cho người dùng (ứng dụng di động) và quản trị viên (trang quản trị web).

TODO:HINHANH:2.1

Do nhóm chưa có điều kiện sử dụng thiết bị đeo thật, hệ thống sử dụng khối mô phỏng để phát dữ liệu từ dataset đã thu thập. Cách tiếp cận này giúp có nguồn dữ liệu ổn định, lặp lại được và thuận tiện cho việc kiểm thử.

## 2.2. Phân tích tác nhân và nhu cầu

### 2.2.1. Nhóm tác nhân chính

Hệ thống có ba tác nhân người và một tác nhân hệ thống:

- **Bệnh nhân** (Patient): người được theo dõi sức khỏe — xem chỉ số sinh hiệu, nhận cảnh báo, gửi SOS khi cần.
- **Người chăm sóc** (Caregiver): người thân hoặc người được ủy quyền — theo dõi tình trạng người được liên kết, nhận thông báo rủi ro và hỗ trợ xử lý sự cố.
- **Quản trị viên** (Admin): vận hành hệ thống — quản lý người dùng, cấu hình hệ thống, giám sát thiết bị, xem nhật ký và trạng thái cảnh báo.
- **Hệ thống** (System): tác nhân tự động — kích hoạt các luồng xử lý nền như phát hiện té ngã, đánh giá rủi ro, phân tích giấc ngủ và phát dữ liệu mô phỏng từ Simulator.

### 2.2.2. Nhu cầu theo tác nhân

- **Bệnh nhân** cần giao diện dễ dùng, dữ liệu cập nhật nhanh, cảnh báo rõ ràng và thao tác khẩn cấp thuận tiện.
- **Người chăm sóc** cần nhận thông tin đúng thời điểm, đúng đối tượng, giảm báo động giả.
- **Quản trị viên** cần công cụ vận hành tập trung và khả năng truy vết sự kiện.

Ngoài ra, về mặt kiến trúc, hệ thống cần tách biệt các khối (ứng dụng, nghiệp vụ, AI, mô phỏng) để có thể nâng cấp độc lập từng phần mà không ảnh hưởng toàn bộ.

## 2.3. Yêu cầu chức năng

Phần này mô tả các nhóm chức năng cốt lõi của hệ thống theo phạm vi đồ án. Mỗi nhóm gắn với một tập use case (UC) đã được đặc tả chi tiết trong tài liệu yêu cầu, kèm mô tả ngắn về đầu vào, đầu ra và đặc điểm xử lý.

### 2.3.1. Nhóm xác thực và quản lý tài khoản (6 UC)

| Mã UC | Tên | Actor | Platform |
| --- | --- | --- | --- |
| UC001 | Đăng nhập | Bệnh nhân, Người chăm sóc, Admin | Mobile + Admin Web |
| UC002 | Đăng ký tài khoản | Bệnh nhân, Người chăm sóc | Mobile |
| UC003 | Khôi phục mật khẩu | Bệnh nhân, Người chăm sóc | Mobile |
| UC004 | Thay đổi mật khẩu | Bệnh nhân, Người chăm sóc | Mobile |
| UC005 | Quản lý hồ sơ cá nhân | Bệnh nhân, Người chăm sóc | Mobile |
| UC009 | Đăng xuất | Bệnh nhân, Người chăm sóc, Admin | Mobile + Admin Web |

Mô tả chi tiết:

- **Đăng ký/đăng nhập**: hệ thống yêu cầu email và mật khẩu hợp lệ, gửi mã xác thực email cho tài khoản mới, trả về JWT access token (và refresh token cho Mobile) khi đăng nhập thành công.
- **Khôi phục/đổi mật khẩu**: gửi mã reset qua email, kiểm tra mã hợp lệ trong thời gian giới hạn, ràng buộc độ mạnh mật khẩu mới và thu hồi token cũ sau khi đổi.
- **Quản lý hồ sơ cá nhân**: xem/sửa thông tin định danh, thông tin y tế (chiều cao, cân nặng, bệnh nền, dị ứng), quản lý quan hệ bệnh nhân–người chăm sóc.
- **Đăng xuất**: vô hiệu hóa token hiện tại; tài khoản admin có cơ chế version token để thu hồi đồng loạt khi cần.

### 2.3.2. Nhóm giám sát sức khỏe (3 UC)

| Mã UC | Tên | Actor | Platform |
| --- | --- | --- | --- |
| UC006 | Xem chỉ số sức khỏe real-time | Bệnh nhân, Người chăm sóc | Mobile |
| UC007 | Xem chi tiết chỉ số sức khỏe | Bệnh nhân, Người chăm sóc | Mobile |
| UC008 | Xem lịch sử chỉ số sức khỏe | Bệnh nhân, Người chăm sóc | Mobile |

Mô tả chi tiết:

- **Tiếp nhận dữ liệu sinh hiệu**: hệ thống nhận telemetry từ thiết bị/Simulator gồm nhịp tim, SpO2, nhiệt độ và dữ liệu vận động, kiểm tra hợp lệ và lưu vào kho dữ liệu chuỗi thời gian.
- **Xem chỉ số real-time (UC006)**: hiển thị chỉ số mới nhất với cập nhật liên tục qua kết nối thời gian thực; có fallback sang HTTP polling khi mất kết nối.
- **Xem chi tiết (UC007)**: hiển thị giá trị, ngưỡng cảnh báo và đánh giá trạng thái cho từng chỉ số đơn lẻ.
- **Xem lịch sử (UC008)**: truy vấn dữ liệu theo khoảng thời gian, hiển thị biểu đồ và thống kê tổng hợp; sử dụng aggregate view để tối ưu hiệu năng.

### 2.3.3. Nhóm khẩn cấp (4 UC)

| Mã UC | Tên | Actor | Platform |
| --- | --- | --- | --- |
| UC010 | Xác nhận an toàn sau cảnh báo té ngã | Bệnh nhân | Mobile |
| UC011 | Xác nhận an toàn và kết thúc sự cố | Bệnh nhân, Người chăm sóc | Mobile |
| UC014 | Gửi SOS khẩn cấp thủ công | Bệnh nhân | Mobile |
| UC015 | Nhận và xử lý thông báo SOS | Người chăm sóc | Mobile |

Mô tả chi tiết:

- **Cảnh báo té ngã (UC010)**: khi mô-đun AI phát hiện sự kiện té ngã, hệ thống hiển thị thông báo kèm bộ đếm ngược; nếu bệnh nhân xác nhận an toàn trong thời gian quy định, sự kiện được đóng và chỉ ghi log; nếu không phản hồi, hệ thống tự động kích hoạt SOS.
- **SOS thủ công (UC014)**: bệnh nhân chủ động gửi tín hiệu khẩn cấp; hệ thống tạo SOS event, đính kèm vị trí (nếu có) và phát thông báo đẩy đến tất cả người chăm sóc liên kết.
- **Tiếp nhận SOS (UC015)**: người chăm sóc nhận thông báo, xem chi tiết sự cố và liên hệ trực tiếp với bệnh nhân.
- **Kết thúc sự cố (UC011)**: bệnh nhân hoặc người chăm sóc cập nhật trạng thái sự cố thành đã giải quyết; hệ thống ghi nhận thời điểm và người xử lý.

### 2.3.4. Nhóm phân tích rủi ro (2 UC)

| Mã UC | Tên | Actor | Platform |
| --- | --- | --- | --- |
| UC016 | Xem báo cáo đánh giá rủi ro | Bệnh nhân, Người chăm sóc | Mobile |
| UC017 | Xem chi tiết báo cáo rủi ro | Bệnh nhân, Người chăm sóc | Mobile |

Mô tả chi tiết:

- **Tính điểm rủi ro**: dựa trên dữ liệu sinh hiệu mới nhất và thông tin y tế cá nhân, hệ thống gọi mô-đun AI để dự đoán điểm rủi ro sức khỏe theo nhiều mức (thấp/trung bình/cao).
- **Báo cáo rủi ro (UC016)**: hiển thị điểm rủi ro hiện tại, xu hướng theo thời gian và các yếu tố ảnh hưởng chính.
- **Chi tiết rủi ro (UC017)**: hiển thị giải thích từ mô hình (feature contribution), dữ liệu đầu vào và khuyến nghị tương ứng.

### 2.3.5. Nhóm phân tích giấc ngủ (2 UC)

| Mã UC | Tên | Actor | Platform |
| --- | --- | --- | --- |
| UC020 | Phân tích giấc ngủ | Bệnh nhân | Mobile |
| UC021 | Xem báo cáo giấc ngủ | Bệnh nhân, Người chăm sóc | Mobile |

Mô tả chi tiết:

- **Phân tích giấc ngủ (UC020)**: khi kết thúc một phiên ngủ, hệ thống gửi dữ liệu cảm biến của phiên đó đến mô-đun AI để tính điểm chất lượng giấc ngủ và phân loại các giai đoạn ngủ.
- **Báo cáo giấc ngủ (UC021)**: hiển thị thời lượng, điểm chất lượng, biểu đồ giai đoạn ngủ và so sánh với các phiên trước đó.

### 2.3.6. Nhóm thiết bị (3 UC)

| Mã UC | Tên | Actor | Platform |
| --- | --- | --- | --- |
| UC040 | Kết nối thiết bị IoT | Bệnh nhân | Mobile |
| UC041 | Cấu hình thiết bị IoT | Bệnh nhân | Mobile |
| UC042 | Xem trạng thái thiết bị | Bệnh nhân, Người chăm sóc | Mobile |

Mô tả chi tiết:

- **Kết nối thiết bị (UC040)**: bệnh nhân quét mã QR hoặc nhập mã ghép nối; hệ thống xác thực mã, gắn thiết bị vào tài khoản và bắt đầu nhận dữ liệu.
- **Cấu hình thiết bị (UC041)**: thiết lập tần suất gửi dữ liệu, ngưỡng cảnh báo cá nhân, bật/tắt theo dõi từng chỉ số.
- **Xem trạng thái (UC042)**: hiển thị trạng thái kết nối, mức pin, lần đồng bộ gần nhất và các cảnh báo phần cứng (nếu có).

### 2.3.7. Nhóm thông báo (2 UC)

| Mã UC | Tên | Actor | Platform |
| --- | --- | --- | --- |
| UC030 | Cấu hình danh bạ khẩn cấp | Bệnh nhân | Mobile |
| UC031 | Quản lý thông báo | Bệnh nhân, Người chăm sóc | Mobile |

Mô tả chi tiết:

- **Danh bạ khẩn cấp (UC030)**: thêm/sửa/xóa các liên hệ khẩn cấp, chọn liên hệ ưu tiên gọi đầu tiên khi xảy ra SOS.
- **Trung tâm thông báo (UC031)**: liệt kê toàn bộ thông báo (cảnh báo y tế, sự cố, thông tin hệ thống) theo trạng thái đã đọc/chưa đọc, hỗ trợ đăng ký push token để nhận thông báo đẩy.

### 2.3.8. Nhóm quản trị vận hành (7 UC)

| Mã UC | Tên | Actor | Platform |
| --- | --- | --- | --- |
| UC022 | Quản lý người dùng | Quản trị viên | Admin Web |
| UC024 | Cấu hình hệ thống | Quản trị viên | Admin Web |
| UC025 | Quản lý thiết bị IoT | Quản trị viên | Admin Web |
| UC026 | Xem nhật ký hệ thống | Quản trị viên | Admin Web |
| UC027 | Dashboard tổng quan hệ thống | Quản trị viên | Admin Web |
| UC028 | Giám sát sức khỏe tổng quan | Quản trị viên | Admin Web |
| UC029 | Quản lý sự cố khẩn cấp | Quản trị viên | Admin Web |

Mô tả chi tiết:

- **Quản lý người dùng (UC022)**: tìm kiếm, lọc, khóa/mở khóa và phân quyền tài khoản; xem lịch sử đăng nhập của từng người dùng.
- **Cấu hình hệ thống (UC024)**: quản lý các tham số toàn cục như ngưỡng cảnh báo mặc định, thời gian timeout xác nhận sự cố, quản lý mô hình AI và phiên bản đang hoạt động.
- **Quản lý thiết bị IoT (UC025)**: gán/bỏ gán/khóa thiết bị, xem trạng thái và lịch sử kết nối của toàn bộ thiết bị trong hệ thống.
- **Nhật ký hệ thống (UC026)**: xem audit log với bộ lọc theo người dùng, hành động, thời gian; hỗ trợ xuất file phục vụ kiểm toán.
- **Dashboard tổng quan (UC027)**: hiển thị các chỉ số KPI vận hành như số người dùng hoạt động, số cảnh báo, biểu đồ xu hướng.
- **Giám sát sức khỏe tổng quan (UC028)**: cho phép admin xem nhanh trạng thái sức khỏe của toàn bộ bệnh nhân, lọc theo mức rủi ro.
- **Quản lý sự cố khẩn cấp (UC029)**: theo dõi danh sách sự cố đang mở, gán xử lý và cập nhật trạng thái.

### 2.3.9. Nhóm dịch vụ nội bộ

Ngoài các UC trực tiếp do người dùng kích hoạt, hệ thống còn có hai dịch vụ nội bộ phục vụ vận hành chung:

- **Dịch vụ mô phỏng (Simulator)**: tạo thiết bị/phiên/kịch bản mô phỏng, sinh dữ liệu sinh hiệu, vận động, giấc ngủ và sự kiện té ngã từ dataset thực; phát dữ liệu qua HTTP/WebSocket; hỗ trợ kiểm tra và phân tích chất lượng dữ liệu.
- **Dịch vụ mô hình AI (Model API)**: cung cấp các endpoint suy luận cho phát hiện té ngã, đánh giá rủi ro sức khỏe và chấm điểm giấc ngủ; kèm các endpoint thông tin mô hình, dữ liệu mẫu và các tình huống mẫu để kiểm thử.

Tổng cộng hệ thống có **29 use case** đã hoàn thành, phân bố trên 2 nền tảng: Mobile App (22 UC) và Admin Web (9 UC), trong đó UC001 và UC009 phục vụ cả hai nền tảng.

## 2.4. Yêu cầu phi chức năng

### 2.4.1. Hiệu năng

- Dữ liệu sinh hiệu (vitals) cần được truyền và hiển thị gần thời gian thực với tần suất 1Hz.
- Dữ liệu vận động (motion) sử dụng cửa sổ tần suất cao hơn để phát hiện sự kiện té ngã.
- API truy vấn biểu đồ và lịch sử nên sử dụng aggregate view để giảm tải.
- Luồng xử lý cảnh báo phải ưu tiên thời gian phản hồi trước các tác vụ không khẩn cấp.

### 2.4.2. Độ tin cậy và sẵn sàng

- Dịch vụ mô phỏng cần có cơ chế dự phòng giữa dataset thật và dữ liệu tổng hợp khi dataset gốc không khả dụng.
- Khi kết nối thời gian thực (WebSocket) gián đoạn, hệ thống cần chuyển sang giao thức HTTP để bảo đảm dữ liệu không bị mất.
- Dịch vụ mô hình AI cần cung cấp endpoint kiểm tra trạng thái và thông tin phiên bản mô hình để theo dõi tình trạng sẵn sàng.
- Cần ghi nhận nhật ký đầy đủ để hỗ trợ khôi phục và phân tích sự cố.

### 2.4.3. Bảo mật và quyền riêng tư

- Xác thực bằng JWT, phân quyền theo vai trò (admin, bệnh nhân, người chăm sóc).
- Quan hệ giữa bệnh nhân và người chăm sóc dùng để giới hạn phạm vi truy cập dữ liệu sức khỏe theo người được liên kết.
- Mật khẩu được hash, có cơ chế chống brute-force (rate limiting) và thu hồi token khi đổi mật khẩu.
- Ghi vết truy cập và thao tác quan trọng qua audit log để phục vụ kiểm toán.
- Hỗ trợ xóa mềm dữ liệu cá nhân và phân quyền chi tiết theo loại dữ liệu (xem chỉ số sinh hiệu, nhận cảnh báo, xem vị trí) để tuân thủ nguyên tắc GDPR.

### 2.4.4. Khả năng mở rộng và bảo trì

- Kiến trúc tách thành các module độc lập (Admin Web, Mobile App, dịch vụ mô hình AI, dịch vụ mô phỏng) giúp nâng cấp riêng từng phần.
- Các API có đặc tả đầu vào–đầu ra rõ ràng để giảm rủi ro tích hợp chéo giữa các module.
- Có thể bổ sung thêm mô hình AI hoặc kịch bản mô phỏng mà không ảnh hưởng toàn bộ hệ thống.
- Mã nguồn cần được tổ chức theo các lớp trách nhiệm rõ ràng và có kiểm thử theo mô-đun để dễ bảo trì.

## 2.5. Phân tích use case và luật nghiệp vụ

### 2.5.1. Mối quan hệ giữa các use case

Một số UC có quan hệ include hoặc extend:

- UC006 (Xem chỉ số sức khỏe) **includes** UC007 (Xem chi tiết chỉ số).
- UC016 (Xem báo cáo rủi ro) **includes** UC017 (Xem chi tiết rủi ro).
- UC011 (Xác nhận an toàn và kết thúc sự cố) là bước đóng sự cố sau UC010, UC014 hoặc UC015.

Chuỗi kích hoạt nghiệp vụ quan trọng nhất (kịch bản té ngã):

```
Hệ thống phát hiện té ngã
  → UC010 (Hiển thị cảnh báo + bộ đếm ngược xác nhận an toàn)
     ├─ [Bệnh nhân xác nhận an toàn] → Đóng sự kiện, ghi log
     └─ [Không phản hồi sau timeout]
          → Hệ thống tự động tạo SOS event
            → UC015 (Người chăm sóc nhận SOS)
              → UC011 (Xác nhận an toàn và kết thúc sự cố)
```

Lưu ý: SOS tự động do Hệ thống tạo ra là một flow nội bộ của UC010, không phải UC014. UC014 là SOS thủ công do bệnh nhân chủ động gửi.

Phân biệt UC025 và UC040: UC025 là quản trị viên gán/bỏ gán/khóa thiết bị trên Admin Web (quản trị tập trung), còn UC040 là bệnh nhân tự kết nối thiết bị bằng mã/QR trên Mobile App (self-service).

### 2.5.2. Luật nghiệp vụ cốt lõi

- Cảnh báo chỉ được phát khi chỉ số vượt ngưỡng hoặc mô hình phát hiện rủi ro đủ điều kiện.
- Tác vụ khẩn cấp phải ưu tiên thời gian xử lý và thông báo đúng đối tượng liên quan.
- Mỗi truy cập dữ liệu phải đi qua lớp xác thực và kiểm tra phạm vi quyền.
- Dữ liệu đầu vào cho AI phải qua bước kiểm tra hợp lệ trước khi suy luận.
- Logic xác thực của Admin Web và Mobile App tách biệt (khóa bí mật và thời hạn token khác nhau).

### 2.5.3. Chuỗi xử lý nghiệp vụ điển hình

- **Giám sát thường nhật**: thiết bị/mô phỏng phát dữ liệu sinh hiệu → module nghiệp vụ kiểm tra hợp lệ → lưu trữ → kiểm tra ngưỡng cảnh báo → hiển thị trên ứng dụng người dùng và trang quản trị.
- **Đánh giá rủi ro**: dữ liệu sinh hiệu mới → gọi dịch vụ mô hình AI suy luận → trả điểm rủi ro và giải thích → lưu kết quả → thông báo nếu mức rủi ro cao.
- **Phân tích giấc ngủ**: kết thúc phiên ngủ → gọi dịch vụ mô hình AI phân tích → trả điểm chất lượng → lưu kết quả phiên → hiển thị báo cáo.
- **Khẩn cấp**: phát hiện sự cố (té ngã hoặc SOS thủ công) → đếm ngược xác nhận (nếu là té ngã) → tạo sự kiện SOS → thông báo đẩy cho người chăm sóc và quản trị viên → xử lý và kết thúc sự cố.
- **Cấu hình ngưỡng**: quản trị viên cập nhật ngưỡng cảnh báo → bộ xử lý cảnh báo áp dụng ngưỡng mới → ảnh hưởng toàn bộ luồng giám sát.

## 2.6. Phân tích dữ liệu và luồng tích hợp

### 2.6.1. Nhóm dữ liệu chính

| Nhóm dữ liệu | Bảng/thực thể tiêu biểu | Đặc điểm |
| --- | --- | --- |
| Định danh và tài khoản | users, user_relationships, emergency_contacts | Dữ liệu quan hệ, ít thay đổi |
| Thiết bị | devices, device_bindings | Trạng thái kết nối, gán/bỏ gán |
| Sinh hiệu chuỗi thời gian | vitals, motion_data | Ghi liên tục, khối lượng lớn |
| Sự kiện và cảnh báo | fall_events, sos_events, alerts | Phát sinh theo sự kiện |
| Kết quả phân tích AI | risk_scores, risk_explanations, sleep_sessions | Kết quả suy luận, gắn với user và timestamp |
| Hệ thống | system_settings, audit_logs, system_metrics | Cấu hình, nhật ký, chỉ số vận hành |
| Mô hình AI | ai_models, ai_model_versions | Quản lý phiên bản mô hình |

### 2.6.2. Luồng dữ liệu liên module

1. **Dịch vụ mô phỏng** phát dữ liệu sinh hiệu, vận động và giấc ngủ theo kịch bản từ dataset thực.
2. **Module nghiệp vụ** tiếp nhận dữ liệu qua MQTT (kênh chính) và HTTP (kênh dự phòng), kiểm tra hợp lệ và lưu trữ: dữ liệu nghiệp vụ vào cơ sở dữ liệu quan hệ, dữ liệu sinh hiệu vào kho dữ liệu chuỗi thời gian.
3. **Dịch vụ mô hình AI** nhận dữ liệu cần suy luận từ module nghiệp vụ, trả kết quả dự đoán (phát hiện té ngã, đánh giá rủi ro, chấm điểm giấc ngủ).
4. Module nghiệp vụ tổng hợp kết quả AI thành trạng thái cảnh báo, cập nhật bản ghi rủi ro và phát thông báo khi cần.
5. **Mobile App** và **Admin Web** hiển thị dữ liệu theo vai trò truy cập tương ứng.

### 2.6.3. Điểm cần kiểm soát khi tích hợp

- Thống nhất định dạng dữ liệu đầu vào–đầu ra giữa các module.
- Thống nhất định danh người dùng, thiết bị và mốc thời gian (theo múi giờ chuẩn).
- Tránh trùng lặp bản ghi khi có nhiều luồng cập nhật đồng thời.
- Xác định rõ nguồn dữ liệu chuẩn cho mỗi miền dữ liệu.

## 2.7. Ma trận truy vết yêu cầu

Để bảo đảm yêu cầu được triển khai và kiểm thử đầy đủ, ma trận truy vết dưới đây ánh xạ từng nhóm UC với module chịu trách nhiệm và nhóm dữ liệu liên quan.

| Nhóm | Use case | Module chính | Dữ liệu liên quan | Kết quả mong đợi |
| --- | --- | --- | --- | --- |
| Xác thực | UC001–UC005, UC009 | Mobile App + Admin Web | Tài khoản, hồ sơ người dùng | Đăng nhập/đăng ký/đổi mật khẩu đúng luồng, phân quyền chính xác |
| Giám sát | UC006–UC008 | Mobile App | Dữ liệu sinh hiệu, vận động | Dữ liệu hiển thị thời gian thực và truy vấn lịch sử đúng |
| Khẩn cấp | UC010, UC011, UC014, UC015 | Mobile App | Sự kiện té ngã, SOS, cảnh báo | Chuỗi SOS kích hoạt đúng, thông báo đẩy đến người chăm sóc |
| Phân tích rủi ro | UC016, UC017 | Mobile App + dịch vụ mô hình AI | Điểm rủi ro, giải thích | Điểm rủi ro và giải thích hiển thị đúng mức độ |
| Giấc ngủ | UC020, UC021 | Mobile App + dịch vụ mô hình AI | Phiên và điểm giấc ngủ | Báo cáo giấc ngủ chính xác theo phiên |
| Thiết bị | UC040–UC042 | Mobile App | Thiết bị và liên kết thiết bị | Kết nối/cấu hình/xem trạng thái thiết bị thành công |
| Thông báo | UC030, UC031 | Mobile App | Danh bạ khẩn cấp, thông báo | Danh bạ và trung tâm thông báo hoạt động đúng |
| Quản trị | UC022, UC024–UC029 | Admin Web | Người dùng, thiết bị, cấu hình, nhật ký, mô hình AI | Các thao tác quản trị thực hiện đúng quyền và đúng luồng |

## 2.8. Phạm vi triển khai và mức độ hoàn thành

### 2.8.1. Phạm vi triển khai trong đồ án

- Tập trung vào các chức năng cốt lõi phục vụ giám sát, cảnh báo và quản trị.
- Ưu tiên hoàn thiện luồng liên thông giữa mô phỏng dữ liệu, xử lý nghiệp vụ, phân tích AI và hiển thị người dùng.
- Bám sát hệ thống use case hiện có để đánh giá mức độ đáp ứng.

### 2.8.2. Ranh giới và giới hạn

- Chưa đặt trọng tâm vào tối ưu hạ tầng ở quy mô sản phẩm thương mại lớn.
- Một số mở rộng nâng cao có thể đang ở mức nguyên mẫu hoặc giai đoạn hoàn thiện.
- Các tích hợp ngoài hệ sinh thái lõi chỉ được xem xét ở mức định hướng.
- Chưa thu nhận dữ liệu trực tiếp từ thiết bị đeo thật trong môi trường thực tế; dữ liệu đầu vào hiện được giả lập từ dataset đã thu thập để phục vụ thực nghiệm có kiểm soát.
