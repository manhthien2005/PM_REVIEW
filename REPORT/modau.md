# MỞ ĐẦU

## 1. Lý do chọn đề tài

Nhu cầu theo dõi sức khỏe liên tục ngày càng cấp thiết, đặc biệt với người cao tuổi, người mắc bệnh mạn tính và nhóm có nguy cơ té ngã. Mô hình khám định kỳ truyền thống chỉ ghi nhận trạng thái sinh lý tại thời điểm khám, không đủ để phát hiện sớm các biến cố như rối loạn nhịp tim, suy giảm SpO2, tăng huyết áp đột ngột, té ngã hay rối loạn giấc ngủ.

Sự phát triển của thiết bị đeo (smartwatch), kiến trúc backend phân tán, học máy có thể giải thích (XAI) và ứng dụng di động đa nền tảng đã cho phép xây dựng hệ sinh thái giám sát sức khỏe liên tục thay vì chỉ ghi nhận rời rạc. Đề tài **HealthGuard** ra đời nhằm hiện thực hóa hệ sinh thái này gồm bốn thành phần liên thông: nền tảng quản trị web, backend AI suy luận đa domain, hệ mô phỏng thiết bị IoT dựa trên dataset y sinh thật và ứng dụng di động cho người dùng cuối.

## 2. Mục tiêu đề tài

Xây dựng hệ sinh thái HealthGuard có khả năng thu thập sinh hiệu thời gian thực, phân tích rủi ro bằng AI, cảnh báo sự cố và quản trị tập trung. Cụ thể:

- Xây dựng nền tảng **Web Admin Dashboard** (Node.js + Express + Prisma + React) phục vụ quản lý người dùng, thiết bị, cấu hình hệ thống, xem nhật ký vận hành và xử lý sự cố khẩn cấp.
- Xây dựng **API backend tích hợp AI** (FastAPI) cung cấp suy luận trên ba domain: đánh giá rủi ro sức khỏe (XGBoost/LightGBM), phát hiện té ngã (CatBoost) và chấm điểm giấc ngủ (LightGBM); kèm giải thích SHAP và sinh diễn giải tiếng Việt qua Gemini.
- Xây dựng **IoT Simulator** mô phỏng thiết bị đeo dựa trên dataset y sinh thực (PPG-DaLiA, PAMAP2, Sleep-EDF, WESAD, VitalDB, BIDMC, UP-Fall, PIF_v3), thay thế phần cứng thật trong giai đoạn phát triển và kiểm thử.
- Xây dựng **ứng dụng di động Flutter** cho người dùng cuối/người giám hộ với chức năng theo dõi sinh hiệu, đánh giá lại rủi ro, lịch sử té ngã, phân tích giấc ngủ, SOS khẩn cấp và chuyển đổi hồ sơ liên kết.
- Đối chiếu triển khai thực tế với đặc tả yêu cầu (SRS/UC) để đánh giá mức độ đáp ứng.

## 3. Đối tượng và phạm vi

### 3.1. Đối tượng nghiên cứu

Đối tượng nghiên cứu của đồ án là hệ thống giám sát sức khỏe thông minh HealthGuard — một hệ sinh thái phần mềm gồm bốn thành phần chính:

- **Ứng dụng quản trị web**: cho phép quản trị viên quản lý người dùng, thiết bị, cấu hình hệ thống, theo dõi nhật ký vận hành và xử lý sự cố khẩn cấp.
- **Dịch vụ suy luận AI**: cung cấp khả năng đánh giá rủi ro sức khỏe, phát hiện té ngã và chấm điểm giấc ngủ dựa trên các mô hình học máy; đồng thời sinh giải thích kết quả dự đoán phục vụ người dùng và nhân viên y tế.
- **Hệ thống mô phỏng thiết bị IoT**: tạo dữ liệu sinh hiệu từ các tập dữ liệu y sinh thực tế, thay thế thiết bị phần cứng trong quá trình phát triển và kiểm thử.
- **Ứng dụng di động**: phục vụ người dùng cuối và người giám hộ theo dõi sức khỏe, nhận cảnh báo bất thường và thực hiện thao tác khẩn cấp.

Bốn thành phần trên hoạt động độc lập nhưng liên thông dữ liệu thông qua giao tiếp API thống nhất.

### 3.2. Phạm vi

Đồ án tập trung vào các nội dung sau:

- Xây dựng các chức năng cốt lõi: xác thực người dùng, quản lý người dùng và thiết bị, thu nhận dữ liệu sinh hiệu, đánh giá rủi ro sức khỏe, phát hiện té ngã, phân tích giấc ngủ, cảnh báo bất thường và xử lý tình huống khẩn cấp.
- Triển khai luồng dữ liệu đầu-cuối: từ mô phỏng thiết bị → thu nhận và lưu trữ dữ liệu → suy luận AI → hiển thị kết quả trên giao diện quản trị và ứng dụng di động.
- Sử dụng dữ liệu mô phỏng từ các tập dữ liệu y sinh thực tế thay cho thiết bị đeo thương mại; áp dụng ngưỡng cảnh báo sinh hiệu theo các hướng dẫn y khoa quốc tế.

### 3.3. Giới hạn

- Hệ thống chưa được triển khai trên hạ tầng vận hành quy mô lớn.
- Chưa tích hợp với thiết bị đeo thương mại hoặc hệ thống thông tin bệnh viện bên ngoài.
- Dữ liệu sinh hiệu được cung cấp hoàn toàn qua mô phỏng nhằm đảm bảo kiểm thử có kiểm soát và lặp lại được.
- Một số chức năng nâng cao (thông báo đẩy đa kênh, kết nối SOS với dịch vụ cấp cứu thực tế) hiện ở mức nguyên mẫu, cần hoàn thiện thêm nếu hướng đến sản phẩm thực tế.

## 4. Phương pháp nghiên cứu

### 4.1. Phương pháp nghiên cứu lý thuyết

- Nghiên cứu kiến trúc phần mềm phân tán và thiết kế giao tiếp API phục vụ hệ thống đa thành phần.
- Tìm hiểu lý thuyết về lưu trữ dữ liệu chuỗi thời gian, các thuật toán học máy ứng dụng trong phân tích sức khỏe và phương pháp giải thích mô hình dự đoán (Explainable AI).
- Tham khảo các tập dữ liệu y sinh chuẩn quốc tế và hướng dẫn lâm sàng của AHA, WHO, ACC/AHA, NEWS2 làm cơ sở thiết lập ngưỡng cảnh báo.
- Phân tích tài liệu đặc tả yêu cầu phần mềm và các use case để xác định phạm vi chức năng cần triển khai.

### 4.2. Phương pháp thực nghiệm

- Triển khai từng thành phần theo hướng mô-đun hóa, sau đó tích hợp đầu-cuối theo luồng dữ liệu: mô phỏng thiết bị → thu nhận và lưu trữ → suy luận AI → hiển thị kết quả.
- Xây dựng các kịch bản kiểm thử đa dạng: thu nhận sinh hiệu liên tục, mô phỏng sự kiện té ngã, tạo dữ liệu lịch sử giấc ngủ và kiểm tra khả năng xử lý đồng thời nhiều thiết bị.
- Thực hiện kiểm thử lặp lại với dữ liệu có kiểm soát nhằm đánh giá tính ổn định và đúng đắn của từng thành phần cũng như toàn hệ thống.

### 4.3. Phương pháp đánh giá

- **Định tính**: đánh giá trải nghiệm người dùng trên giao diện quản trị và ứng dụng di động; xem xét mức độ phù hợp nghiệp vụ và khả năng đáp ứng các use case theo đặc tả yêu cầu.
- **Định lượng**: đo tỷ lệ ca kiểm thử đạt, thời gian phản hồi API, độ chính xác của mô hình dự đoán và mức bao phủ chức năng so với danh sách use case đã đăng ký.

## 5. Cấu trúc báo cáo (không cần lits vào báo cáo)

- **Mở đầu**: lý do chọn đề tài, mục tiêu, đối tượng và phạm vi, phương pháp nghiên cứu.
- **Chương 1**: Cơ sở lý thuyết về IoT y tế, dữ liệu sinh hiệu, AI có thể giải thích và kiến trúc microservice.
- **Chương 2**: Phân tích yêu cầu hệ thống — actor, use case, yêu cầu chức năng và phi chức năng.
- **Chương 3**: Kiến trúc và thiết kế tổng thể — sơ đồ thành phần, luồng dữ liệu, phân tách trách nhiệm giữa bốn khối.
- **Chương 4**: Thiết kế cơ sở dữ liệu (PostgreSQL + TimescaleDB) và đặc tả API giữa các thành phần.
- **Chương 5**: Xây dựng các module ứng dụng — Web Admin, Mobile App, IoT Simulator và AI Model API.
- **Chương 6**: Tích hợp AI, IoT Simulator và luồng dữ liệu thời gian thực, bao gồm SHAP và sinh giải thích tiếng Việt qua Gemini.
- **Chương 7**: Kiểm thử, đánh giá kết quả và đối chiếu với yêu cầu trong SRS/UC.
- **Kết luận**: tổng kết kết quả đạt được, hạn chế và hướng phát triển.