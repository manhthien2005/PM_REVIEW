# CHƯƠNG 4. THIẾT KẾ CƠ SỞ DỮ LIỆU VÀ GIAO TIẾP API

**Mục tiêu chương**: Trình bày thiết kế cơ sở dữ liệu, tổ chức các bảng nghiệp vụ, các nhóm giao diện API và hợp đồng dữ liệu giữa các module. Nội dung chương này là cơ sở để hiện thực hóa các yêu cầu chức năng đã phân tích ở Chương 2 dựa trên kiến trúc tổng thể đã trình bày ở Chương 3.

## 4.1. Tổng quan thiết kế cơ sở dữ liệu

Hệ thống sử dụng PostgreSQL kết hợp extension TimescaleDB để vừa đáp ứng yêu cầu của dữ liệu nghiệp vụ (quan hệ chặt chẽ, ràng buộc toàn vẹn) vừa tối ưu cho dữ liệu chuỗi thời gian (ghi tần suất cao, truy vấn theo cửa sổ thời gian). Cách tiếp cận hybrid này đã được trình bày trong cơ sở lý thuyết ở §1.8.

Theo nguyên tắc kiến trúc đã nêu ở §3.3.2, cả Mobile Backend và Admin Backend cùng truy cập một cơ sở dữ liệu chung. Mô hình "shared database" giúp đồng bộ tự nhiên các thực thể chung giữa hai module mà không cần lớp message queue trung gian, đổi lại đặt ra yêu cầu cao về quản lý lược đồ thống nhất.

Cơ sở dữ liệu được tổ chức thành 6 nhóm logic gồm tổng cộng 20 bảng:

| Nhóm | Số bảng | Bảng tiêu biểu | Mục đích |
| --- | --- | --- | --- |
| Quản lý người dùng | 6 | `users`, `user_relationships`, `emergency_contacts` | Tài khoản, quan hệ chăm sóc, liên hệ khẩn cấp |
| Quản lý thiết bị | 1 | `devices` | Thiết bị IoT đeo trên người |
| Dữ liệu chuỗi thời gian | 3 | `vitals` ★, `motion_data` ★, `sleep_sessions` | Sinh hiệu, chuyển động, phiên ngủ |
| Sự kiện và cảnh báo | 3 | `fall_events`, `sos_events`, `alerts` | Sự kiện té ngã, SOS, thông báo |
| Phân tích AI | 4 | `risk_scores`, `risk_explanations`, `ai_models`, `ai_model_versions` | Kết quả AI và quản lý mô hình |
| Hệ thống và kiểm toán | 3 | `audit_logs` ★, `system_settings`, `system_metrics` ★ | Cấu hình, nhật ký, chỉ số vận hành |

> ★ = Hypertable (TimescaleDB) — bảng được phân vùng tự động theo thời gian, hỗ trợ nén dữ liệu, retention và continuous aggregate.

Sơ đồ quan hệ tổng quan giữa các thực thể chính:

TODO:HINHANH:4.1

## 4.2. Thiết kế các bảng nghiệp vụ chính

### 4.2.1. Nhóm quản lý người dùng

Bảng `users` lưu thông tin chung cho cả người dùng cuối và quản trị viên (phân biệt qua trường `role`), bao gồm các trường định danh (email, mật khẩu đã hash, họ tên), thông tin y tế (chiều cao, cân nặng, bệnh nền, dị ứng) và các trường bảo mật (số phiên bản token, mã xác minh, lockout). Bảng `user_relationships` quản lý quan hệ bệnh nhân – người chăm sóc với phân quyền chi tiết (xem sinh hiệu, nhận cảnh báo, xem vị trí), kèm vòng đời yêu cầu liên kết. Các bảng phụ trợ gồm `password_reset_tokens`, `user_fcm_tokens` (token Firebase phục vụ thông báo đẩy), `users_archive` (dữ liệu sau khi xóa mềm, phục vụ tuân thủ pháp lý) và `emergency_contacts` (danh bạ liên hệ khi khẩn cấp).

### 4.2.2. Nhóm quản lý thiết bị

Bảng `devices` lưu thông tin thiết bị IoT đeo, gồm các trường định danh (UUID công khai, địa chỉ MAC, số serial), trạng thái vận hành (mức pin, cường độ tín hiệu, lần kết nối cuối) và liên kết với hệ thống mô phỏng. Khi quản trị viên gán thiết bị cho người dùng, toàn bộ dữ liệu sinh hiệu phát sinh sau đó được tự động liên kết với người dùng đó.

### 4.2.3. Nhóm dữ liệu chuỗi thời gian

`vitals` (hypertable) lưu các chỉ số sinh hiệu (nhịp tim, SpO2, nhiệt độ, huyết áp, biến thiên nhịp tim, nhịp thở) với tần suất xấp xỉ 1 bản ghi mỗi giây cho mỗi thiết bị. `motion_data` (hypertable) lưu dữ liệu cảm biến chuyển động (gia tốc kế và con quay hồi chuyển ba trục) với tần suất 50–100 bản ghi mỗi giây phục vụ thuật toán phát hiện té ngã. `sleep_sessions` lưu kết quả phân tích phiên ngủ ở mức ngày, gồm điểm chất lượng và thời lượng các giai đoạn (thức, ngủ nông, ngủ sâu, REM); bảng có ràng buộc duy nhất theo `(user_id, device_id, sleep_date)` để chống trùng lặp khi dữ liệu được đồng bộ nhiều lần trong ngày.

Mỗi hypertable được cấu hình theo đặc thù khối lượng dữ liệu: `vitals` chia chunk theo tuần với retention 1 năm, `motion_data` chia chunk theo ngày với retention 3 tháng, để cân đối giữa khả năng truy hồi và chi phí lưu trữ. Hệ thống còn duy trì ba continuous aggregate (`vitals_5min`, `vitals_hourly`, `vitals_daily`) nhằm tăng tốc các truy vấn dạng biểu đồ và xu hướng dài hạn.

### 4.2.4. Nhóm sự kiện và cảnh báo

`fall_events` lưu sự kiện té ngã do mô hình AI phát hiện, kèm xác suất và chuỗi mốc thời gian (phát hiện, thông báo người dùng, người dùng phản hồi, kích hoạt SOS). Theo luật nghiệp vụ ở §2.5.2 và §2.5.3, nếu sau khoảng thời gian quy định người dùng không xác nhận an toàn, hệ thống tự động tạo bản ghi `sos_events` với loại trigger là tự động.

`sos_events` quản lý vòng đời sự cố theo trạng thái `active → responded → resolved`, hỗ trợ cả SOS thủ công lẫn tự động sinh từ té ngã. Liên kết tới `fall_events` qua khóa ngoại có thể NULL, cho phép biểu diễn cả SOS thủ công độc lập với té ngã.

`alerts` lưu các thông báo cảnh báo theo nhiều loại (vượt ngưỡng sinh hiệu, té ngã, SOS) kèm mức độ severity và snapshot dữ liệu tại thời điểm phát, phục vụ tra cứu lịch sử và phân tích xu hướng cảnh báo.

### 4.2.5. Nhóm phân tích AI

`risk_scores` lưu điểm rủi ro (0–100) theo loại (sức khỏe, té ngã, giấc ngủ) và mức độ (thấp, trung bình, cao, nguy kịch), kèm vector đặc trưng đầu vào và phiên bản mô hình. Trường `algorithm` cho biết kết quả đến từ mô hình AI hay logic dự phòng rule-based — đây là cơ sở để theo dõi độ phủ thực tế của AI.

`risk_explanations` lưu giải thích AI cho từng điểm rủi ro, gồm văn bản giải thích, trọng số đặc trưng và khuyến nghị hành động. Bảng được tách riêng vì không phải mọi điểm rủi ro đều cần giải thích chi tiết.

`ai_models` và `ai_model_versions` quản lý vòng đời mô hình AI: mỗi mô hình có nhiều phiên bản với artifact lưu trên kho lưu trữ đối tượng (Cloudflare R2). Trường `active_version_id` xác định phiên bản đang sử dụng và có thể chuyển đổi mà không cần triển khai lại mã nguồn.

### 4.2.6. Nhóm hệ thống và kiểm toán

`audit_logs` (hypertable) ghi lại các hành động quan trọng (đăng nhập, gửi cảnh báo, xuất dữ liệu) phục vụ kiểm toán và truy vết sự cố theo nguyên tắc bảo mật ở §1.9. `system_settings` lưu cấu hình toàn cục dạng key–value JSON (ngưỡng cảnh báo mặc định, tham số mô hình AI), cho phép quản trị viên cập nhật mà không cần triển khai lại. `system_metrics` (hypertable) lưu chỉ số vận hành hệ thống theo dạng time-series với tags JSON linh hoạt, phục vụ giám sát độ trễ API, số lượng message và thời gian suy luận AI.

## 4.3. Thiết kế giao tiếp API

Hệ thống có các nhóm API tương ứng với từng module backend. Mỗi nhóm có tiền tố URL riêng và cơ chế xác thực phù hợp với đối tượng sử dụng:

| Module | Tiền tố URL | Cơ chế xác thực |
| --- | --- | --- |
| Admin Backend | `/api/v1/admin` | JWT Bearer + middleware kiểm tra vai trò admin |
| Admin Backend nội bộ | `/api/v1/internal` | Header shared secret |
| Mobile Backend | `/api/v1/mobile` | JWT Bearer + scope theo quan hệ chăm sóc |
| Mobile Backend nội bộ | `/api/v1/mobile/admin` | Header shared secret |
| Dịch vụ mô hình AI | `/api/v1/{fall,health,sleep}` | Chưa áp dụng (xem §4.5) |
| Dịch vụ mô phỏng | `/api/sim` | Public; sub-router quản trị yêu cầu API key |

### 4.3.1. API Admin Backend

API Admin Backend phục vụ Admin Web (UC001, UC009, UC022, UC024–UC029), được tổ chức theo các nhóm chức năng:

- **Auth**: đăng nhập, đặt lại và đổi mật khẩu cho quản trị viên.
- **Users**: quản lý người dùng và quan hệ chăm sóc (UC022).
- **Devices**: liệt kê, gán/bỏ gán, khóa thiết bị (UC025).
- **Dashboard và Health**: KPI tổng quan, biểu đồ cảnh báo, danh sách bệnh nhân rủi ro cao, xu hướng sinh hiệu (UC027–UC028).
- **Emergencies**: tổng quan và xử lý sự cố khẩn cấp (UC029).
- **Logs và Settings**: tra cứu nhật ký, cấu hình hệ thống (UC024, UC026).
- **AI Models**: quản lý mô hình AI và phiên bản, lưu artifact trên kho lưu trữ đối tượng.

Toàn bộ route quản trị áp dụng các middleware xác thực, kiểm tra quyền và rate limiter. Các thao tác nhạy cảm (xóa, khóa, đổi mật khẩu) đều ghi nhận vào `audit_logs`.

### 4.3.2. API Mobile Backend

API Mobile Backend phục vụ ứng dụng di động (22 UC trên Mobile App), tổ chức thành các nhóm:

- **Auth và Profile**: đăng ký, xác minh email, đăng nhập, refresh token, quản lý hồ sơ (UC001–UC005).
- **Devices và Telemetry**: ghép thiết bị, nhận dữ liệu sinh hiệu, chuyển động và giấc ngủ từ thiết bị hoặc dịch vụ mô phỏng (UC040–UC042).
- **Monitoring**: truy vấn sinh hiệu hiện tại, lịch sử và báo cáo sức khỏe (UC006–UC008).
- **Risk**: tính và truy vấn điểm rủi ro kèm giải thích đặc trưng (UC016–UC017).
- **Emergency và Fall Events**: SOS thủ công, danh sách và xử lý sự cố, xác nhận an toàn sau cảnh báo té ngã (UC010, UC011, UC014–UC015).
- **Notifications và Relationships**: trung tâm thông báo, đăng ký push token, quản lý liên kết người chăm sóc (UC030–UC031).
- **Settings**: cài đặt cá nhân của người dùng.

Mobile Backend dùng cặp JWT access token (ngắn hạn) và refresh token (dài hạn). Mọi route truy cập dữ liệu cá nhân đều đi qua tầng kiểm tra phạm vi quan hệ chăm sóc theo `user_relationships`, đảm bảo người chăm sóc chỉ truy cập được dữ liệu của bệnh nhân đã liên kết.

### 4.3.3. API Dịch vụ mô hình AI

Dịch vụ mô hình AI cung cấp ba nhóm endpoint suy luận:

- **Phát hiện té ngã** (`/api/v1/fall`): nhận cửa sổ dữ liệu chuyển động, trả về xác suất té ngã (UC010).
- **Rủi ro sức khỏe** (`/api/v1/health`): nhận vector đặc trưng sinh hiệu, trả về xác suất rủi ro và phân loại mức độ (UC016).
- **Chấm điểm giấc ngủ** (`/api/v1/sleep`): nhận đặc trưng phiên ngủ, trả về điểm 0–100 và nhãn chất lượng (UC020).

Mỗi miền cung cấp tập endpoint thống nhất gồm `POST /predict` (suy luận đơn lẻ hoặc batch), `GET /model-info` (thông tin mô hình hiện hành), `GET /sample-input` và `GET /sample-cases` (dữ liệu mẫu phục vụ kiểm thử). Ngoài ra có endpoint hệ thống `GET /health` (kiểm tra trạng thái mô hình) và `GET /api/v1/models` (liệt kê các mô hình đã nạp).

### 4.3.4. API Dịch vụ mô phỏng

Dịch vụ mô phỏng cung cấp các nhóm router phục vụ vận hành: tổng quan runtime, quản lý thiết bị mô phỏng và liên kết với cơ sở dữ liệu, kịch bản (giấc ngủ, hoạt động, bệnh lý), phiên mô phỏng, truy vấn sinh hiệu và sự kiện, phân tích chất lượng dữ liệu và cấu hình runtime. Sub-router quản trị thiết bị trong cơ sở dữ liệu sản phẩm được bảo vệ bằng header API key riêng. Ngoài REST API, dịch vụ cung cấp WebSocket `/ws/logs/{session_id}` để truyền log thời gian thực phục vụ giao diện vận hành.

## 4.4. Hợp đồng dữ liệu giữa các module

### 4.4.1. Luồng telemetry: Dịch vụ mô phỏng → Mobile Backend

Dịch vụ mô phỏng gửi dữ liệu sinh hiệu về Mobile Backend qua endpoint dạng batch. Mỗi item chứa định danh thiết bị trong cơ sở dữ liệu chung, mốc thời gian phát (UTC) và đối tượng chứa các chỉ số đo. Mobile Backend kiểm tra hợp lệ giá trị và chiều dài batch, ánh xạ định danh và mốc thời gian trước khi ghi vào hypertable `vitals`. Tương tự, các luồng cảnh báo vượt ngưỡng và phiên giấc ngủ có endpoint riêng với schema nhất quán; phiên ngủ được upsert theo khóa duy nhất để tránh trùng lặp khi đồng bộ nhiều lần.

### 4.4.2. Luồng suy luận AI: Mobile Backend → Dịch vụ mô hình AI

Khi cần suy luận, Mobile Backend gọi HTTP đến Dịch vụ mô hình AI với vector đặc trưng đã tiền xử lý và nhận về xác suất, phân loại và (tùy mô hình) trọng số đặc trưng. Theo nguyên tắc độ tin cậy ở §2.4.2, khi Dịch vụ mô hình AI không khả dụng (lỗi mạng, mô hình chưa nạp, timeout), Mobile Backend chuyển sang logic dự phòng dựa trên luật ngưỡng tĩnh và đánh dấu `algorithm = 'rule_based'` trong bảng `risk_scores`. Cách thiết kế này đảm bảo hệ thống vẫn cung cấp được kết quả rủi ro ngay cả khi mô hình AI gặp sự cố.

### 4.4.3. Quy ước dữ liệu chung

Vì hai backend chia sẻ một cơ sở dữ liệu, các quy ước sau được tuân thủ thống nhất:

- `user.id` và `device.id` là khóa ngoại trong mọi bảng và đồng thời là định danh thiết bị trong telemetry payload.
- Trường `user.role` chỉ nhận hai giá trị `user` và `admin` (kiểu enum trong PostgreSQL).
- Mọi mốc thời gian dùng kiểu timestamp có múi giờ (UTC) để tránh sai lệch theo múi giờ.
- Xóa mềm được thực hiện qua cột `deleted_at`; mọi truy vấn nghiệp vụ phải lọc các bản ghi chưa xóa.
- UUID công khai (xuất ra qua API) được sinh tự động để tránh lộ ID nội bộ.

## 4.5. Vấn đề tồn đọng

Bên cạnh các vấn đề kiến trúc đã ghi nhận ở §3.11, quá trình đối chiếu thiết kế cơ sở dữ liệu và giao tiếp API với mã nguồn thực tế đã ghi nhận thêm một số vấn đề ở mức triển khai:

| # | Vấn đề | Mức độ | Đề xuất |
| --- | --- | --- | --- |
| 1 | Quản lý migration cơ sở dữ liệu chưa thống nhất giữa hai backend (Prisma sinh migration tự động, SQLAlchemy tạo bảng từ metadata), dễ dẫn đến lệch lược đồ khi cập nhật | Cao | Chọn một bộ SQL script làm nguồn migration chính; cả hai ORM chỉ thực hiện introspect lược đồ |
| 2 | Một số cột tham chiếu trong index SQL chưa khớp với schema ORM (ví dụ điển hình: `alerts.read_at` xuất hiện trong index nhưng thiếu trong schema), gây lỗi khi áp dụng migration | Trung bình | Đồng bộ schema ORM với migration SQL và bổ sung kiểm thử lược đồ |
| 3 | Tên header shared secret giữa các luồng nội bộ chưa thống nhất (`X-Internal-Service` cho Mobile Backend và `X-Internal-Secret` cho Admin Backend), dễ nhầm lẫn khi cấu hình giữa các service | Thấp | Thống nhất tên header chung hoặc lập tài liệu rõ ràng cho từng cặp service |

## 4.6. Kết luận chương

Chương 4 đã trình bày thiết kế cơ sở dữ liệu của hệ thống với 20 bảng được phân thành 6 nhóm logic, tận dụng PostgreSQL kết hợp TimescaleDB cho dữ liệu chuỗi thời gian và ba continuous aggregate cho tối ưu hóa truy vấn dài hạn. Các bảng nghiệp vụ được chuẩn hóa và liên kết qua khóa ngoại; các bảng time-series được tổ chức thành hypertable để hỗ trợ ghi tần suất cao và truy vấn theo cửa sổ thời gian.

Về giao tiếp API, hệ thống tách thành các nhóm endpoint với tiền tố URL phân biệt rõ theo từng module, áp dụng nhiều cơ chế xác thực phù hợp với đối tượng sử dụng: JWT cho người dùng cuối, shared secret cho luồng nội bộ giữa các service và API key cho sub-router quản trị của Dịch vụ mô phỏng. Các luồng dữ liệu liên module (telemetry, suy luận AI) được chuẩn hóa qua hợp đồng cụ thể về schema và quy ước dữ liệu chung, đảm bảo tính nhất quán xuyên suốt.

Bên cạnh các thiết kế đã được hiện thực hóa, chương cũng chỉ ra một số vấn đề tồn đọng ở mức cơ sở dữ liệu và giao tiếp API, bổ sung cho các vấn đề kiến trúc đã trình bày ở §3.11. Đây là cơ sở để các chương tiếp theo bàn về kiểm thử, triển khai và lộ trình cải thiện hệ thống.
