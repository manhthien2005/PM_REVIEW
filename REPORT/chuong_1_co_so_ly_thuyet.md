# CHƯƠNG 1. CƠ SỞ LÝ THUYẾT

## 1.1. Tổng quan bài toán giám sát sức khỏe thông minh

Trong bối cảnh chuyển đổi số y tế, mô hình chăm sóc theo đợt khám định kỳ đang bộc lộ hạn chế khi không thể theo dõi liên tục trạng thái sinh lý của người dùng. Đối với người cao tuổi, người có bệnh nền tim mạch - hô hấp hoặc người có nguy cơ té ngã, việc thiếu dữ liệu thời gian thực có thể làm chậm phát hiện biến cố và tăng nguy cơ diễn tiến nặng.

Bài toán giám sát sức khỏe thông minh đặt ra yêu cầu: thu thập dữ liệu sinh hiệu theo dòng thời gian, phân tích tự động để nhận diện bất thường, và phát cảnh báo kịp thời đến đúng tác nhân (người dùng, người thân, quản trị viên).

Để giải quyết bài toán này, hệ thống cần kiến trúc đa thành phần gồm: tầng thu thập dữ liệu (thiết bị hoặc mô phỏng), tầng xử lý nghiệp vụ, tầng suy luận AI, và tầng giao diện cho người dùng cuối lẫn quản trị viên. Các tầng này phải liên thông dữ liệu thống nhất để bảo đảm tính mở rộng và kiểm soát nghiệp vụ.

## 1.2. Các khái niệm nền tảng

Để xây dựng hệ thống giám sát sức khỏe thông minh, cần làm rõ một số khái niệm cốt lõi:

- IoT (Internet of Things): là mạng lưới các thiết bị có khả năng cảm biến, kết nối và trao đổi dữ liệu qua Internet. Trong y tế, IoT cho phép thiết bị đeo hoặc thiết bị đầu cuối gửi dữ liệu sinh hiệu liên tục.
- Dữ liệu sinh hiệu: là các chỉ số phản ánh trạng thái sinh lý của cơ thể, ví dụ nhịp tim, SpO2, huyết áp, nhịp thở, chất lượng giấc ngủ, mức độ vận động.
- Cảnh báo sớm: là cơ chế phát hiện bất thường và gửi thông báo ngay khi chỉ số vượt ngưỡng hoặc xuất hiện mẫu hành vi nguy hiểm.
- AI dự đoán: là việc sử dụng mô hình học máy để ước lượng nguy cơ, phân loại trạng thái sức khỏe hoặc nhận diện sự kiện bất thường dựa trên dữ liệu lịch sử và dữ liệu thời gian thực.

Ngoài ra, hệ thống giám sát sức khỏe còn liên quan đến một số khái niệm kỹ thuật:

- Dữ liệu chuỗi thời gian (time-series): dữ liệu gắn với mốc thời gian, được ghi liên tục và truy vấn theo khoảng thời gian.
- Phân tách trách nhiệm: mỗi tầng trong hệ thống chỉ đảm nhận một nhiệm vụ riêng, giúp dễ bảo trì và mở rộng.
- Truy vết hệ thống (audit): ghi lại các thao tác quan trọng để phục vụ kiểm tra và xử lý sự cố.

## 1.3. Cơ sở lý thuyết về IoT trong y tế

IoT trong y tế thường được tổ chức theo 3 lớp:

- **Lớp cảm biến**: thu thập dữ liệu sinh hiệu từ thiết bị đeo hoặc cảm biến y tế. Khi chưa có thiết bị thật, có thể sử dụng phương pháp mô phỏng dựa trên dataset y sinh (data-driven simulation) để tạo dữ liệu gần thực tế, giảm sai lệch phân phối so với sinh số ngẫu nhiên.
- **Lớp truyền dẫn**: vận chuyển dữ liệu từ thiết bị đến hệ thống xử lý. Các giao thức phổ biến gồm MQTT (nhẹ, phù hợp telemetry liên tục), HTTP/REST (kiểm soát tốt, phù hợp truy vấn) và WebSocket (đồng bộ thời gian thực).
- **Lớp ứng dụng/phân tích**: xử lý, phân tích dữ liệu và đưa ra cảnh báo hoặc báo cáo.

Các tiêu chí quan trọng của IoT y tế:

- Tính liên tục của dòng dữ liệu theo nhịp lấy mẫu.
- Khả năng fallback khi gián đoạn kết nối.
- Truy xuất nguồn gốc dữ liệu (data provenance).
- Kiểm soát độ tin cậy tín hiệu trước khi đưa vào phân tích.

## 1.4. Cơ sở lý thuyết về dữ liệu sinh hiệu và tiền xử lý

Dữ liệu sinh hiệu có đặc điểm đa nguồn, đa tần suất và dễ nhiễu. Ví dụ: nhịp tim dao động theo hoạt động thể chất, SpO2 sai lệch khi cảm biến tiếp xúc kém, dữ liệu giấc ngủ chịu ảnh hưởng bởi thói quen sinh hoạt.

Tiền xử lý là bước bắt buộc để nâng cao chất lượng phân tích, thường gồm:

- Làm sạch dữ liệu: loại bỏ bản ghi lỗi, giá trị ngoài miền hợp lệ, dữ liệu trùng lặp.
- Xử lý giá trị thiếu: nội suy, thay thế theo ngữ cảnh hoặc đánh dấu không hợp lệ.
- Chuẩn hóa đơn vị đo: đưa dữ liệu về cùng thang đo phục vụ mô hình học máy.
- Trích xuất đặc trưng: tạo các đặc trưng thống kê theo cửa sổ thời gian (trung bình, độ lệch chuẩn, xu hướng).

Về nguyên tắc, tiền xử lý nên được phân tách theo tầng: tầng nguồn chuẩn hóa tín hiệu, tầng AI trích xuất đặc trưng, tầng nghiệp vụ kiểm tra ngưỡng và tổng hợp sự kiện. Chất lượng tiền xử lý ảnh hưởng trực tiếp đến độ chính xác dự đoán, độ tin cậy cảnh báo và tính nhất quán dữ liệu lịch sử.

## 1.5. Cơ sở lý thuyết về trí tuệ nhân tạo trong dự đoán sức khỏe

AI trong giám sát sức khỏe thường được áp dụng theo ba hướng chính:

- **Phân loại trạng thái**: mô hình học từ dữ liệu lịch sử để ước lượng mức độ rủi ro sức khỏe hiện tại.
- **Phát hiện sự kiện**: sử dụng dữ liệu vận động (gia tốc, con quay hồi chuyển) để phân biệt trạng thái bình thường và sự cố như té ngã.
- **Đánh giá chất lượng giấc ngủ**: phân tích nhịp tim, chuyển động và các chỉ số liên quan trong suốt giấc ngủ.

Quy trình AI điển hình gồm: chuẩn bị dữ liệu → trích xuất đặc trưng → suy luận mô hình → trả kết quả (điểm rủi ro, phân loại sự kiện) → tích hợp vào tầng ứng dụng để hiển thị và cảnh báo.

Về kiến trúc, mô hình AI nên được triển khai tách biệt khỏi backend nghiệp vụ (model serving riêng) để dễ thay thế, kiểm thử độc lập và theo dõi chất lượng dự đoán. Hệ thống cần cân bằng ba yếu tố: độ chính xác, độ trễ suy luận và khả năng giải thích kết quả — đặc biệt quan trọng trong lĩnh vực sức khỏe.

## 1.6. Cơ sở lý thuyết về kiến trúc hệ thống phần mềm

Kiến trúc phần mềm cho hệ thống giám sát sức khỏe cần đáp ứng: phân tách chức năng rõ ràng, giao tiếp qua API chuẩn, và khả năng mở rộng độc lập từng phần. Dự án HealthGuard áp dụng mô hình multi-service, gồm các module chính:

- **Web Admin Dashboard**: frontend React + Vite + TailwindCSS, backend Node.js + Express + Prisma + PostgreSQL. Phục vụ quản trị viên vận hành hệ thống.
- **API Core (Model Backend)**: FastAPI (Python), tích hợp scikit-learn, LightGBM, XGBoost, CatBoost. Cung cấp API suy luận AI cho các bài toán phát hiện té ngã, phân tích rủi ro sức khỏe và đánh giá giấc ngủ.
- **Simulator Core**: FastAPI + engine mô phỏng + dashboard React. Mô phỏng thiết bị đeo từ dataset y sinh thực, phát dữ liệu telemetry qua MQTT (kênh chính) và HTTP (kênh dự phòng); cung cấp WebSocket để stream log thời gian thực.
- **Mobile App**: frontend Flutter, backend FastAPI + SQLAlchemy, dùng chung PostgreSQL/TimescaleDB với Web Admin Dashboard, tích hợp Firebase cho thông báo đẩy. Ứng dụng người dùng cuối theo dõi sức khỏe và nhận cảnh báo.

Mỗi thành phần backend được tổ chức theo phân lớp: route → controller/handler → service → data access, giúp giảm phụ thuộc chéo và dễ bảo trì.

## 1.7. Cơ sở lý thuyết về API và giao thức tích hợp

REST API là giao thức tích hợp phổ biến nhất trong kiến trúc phân tán. Các nguyên tắc thiết kế API quan trọng:

- Chuẩn hóa schema request/response để giảm lỗi tích hợp giữa nhiều client.
- Xử lý lỗi thống nhất ở tầng middleware.
- Tách endpoint nghiệp vụ và endpoint nội bộ.
- Bảo đảm idempotency cho các thao tác cập nhật quan trọng.

Về giao thức truyền dữ liệu, mỗi loại phù hợp một mục tiêu khác nhau:

- **HTTP/REST**: phù hợp truy vấn, quản lý và cấu hình. Kiểm soát tốt, dễ debug.
- **WebSocket**: kênh hai chiều, độ trễ thấp, phù hợp truyền dữ liệu telemetry liên tục và đồng bộ thời gian thực giữa backend và giao diện.

Khi phối hợp nhiều giao thức, cần quy tắc chặt chẽ về định danh thiết bị, timestamp và xử lý trùng lặp để tránh sai lệch phân tích.

## 1.8. Cơ sở lý thuyết về cơ sở dữ liệu và lưu trữ chuỗi thời gian

Hệ thống giám sát sức khỏe thường có hai nhóm dữ liệu:

- **Dữ liệu nghiệp vụ**: người dùng, thiết bị, cấu hình, cảnh báo, nhật ký — yêu cầu tính toàn vẹn và quan hệ rõ ràng → phù hợp cơ sở dữ liệu quan hệ (RDBMS).
- **Dữ liệu chuỗi thời gian**: bản ghi sinh hiệu liên tục theo timestamp — yêu cầu tốc độ ghi cao và truy vấn theo cửa sổ thời gian → phù hợp time-series database hoặc extension chuyên dụng.

Cách tiếp cận hybrid storage (dùng chung RDBMS + extension time-series) cho phép kết hợp cả hai nhóm trong cùng hệ quản trị, giảm độ phức tạp vận hành.

Các nguyên tắc thiết kế dữ liệu quan trọng:

- Chuẩn hóa bảng nghiệp vụ để tránh dư thừa.
- Tối ưu chỉ mục theo khóa truy vấn thường dùng (device_id, user_id, timestamp).
- Phân vùng dữ liệu lớn theo thời gian.
- Cân bằng giữa tốc độ ghi liên tục và tốc độ đọc phân tích.
- Khi có nhiều service truy cập cùng miền dữ liệu, cần xác định rõ nguồn dữ liệu chuẩn (source of truth) và cơ chế đồng bộ schema.

## 1.9. Cơ sở lý thuyết về bảo mật và quyền riêng tư dữ liệu y tế

(TODO) Dữ liệu y tế là dữ liệu nhạy cảm, cần áp dụng bảo mật theo nguyên tắc phòng thủ nhiều lớp: bảo mật truy cập, bảo mật đường truyền, bảo mật lưu trữ và bảo mật vận hành. Các chuẩn quốc tế như HIPAA (Mỹ) và GDPR (EU) đặt ra yêu cầu nghiêm ngặt về bảo vệ thông tin sức khỏe cá nhân.

Các nguyên tắc bảo mật nền tảng:

- **Xác thực và phân quyền**: chỉ người dùng hợp lệ được truy cập đúng phạm vi dữ liệu.
- **Bảo vệ dữ liệu cá nhân**: mã hóa dữ liệu nhạy cảm khi truyền nhận và lưu trữ.
- **Nhật ký hệ thống (audit log)**: ghi nhận hành vi truy cập và thao tác quan trọng để truy vết sự cố.
- **Nguyên tắc tối thiểu quyền hạn (least privilege)**: mỗi tài khoản chỉ được cấp quyền đủ dùng.
- **Kiểm soát phiên và token**: giới hạn thời gian hiệu lực, cơ chế làm mới và thu hồi khi phát hiện rủi ro.
- **Giới hạn tần suất truy cập (rate limiting)**: ngăn chặn tấn công brute-force bằng cách giới hạn số lần gọi API trong khoảng thời gian nhất định.

Việc áp dụng đồng bộ các cơ chế trên là điều kiện tiên quyết để hệ thống giám sát sức khỏe vận hành ổn định, đáng tin cậy và có khả năng mở rộng.