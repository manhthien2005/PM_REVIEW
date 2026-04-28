# MỞ ĐẦU

## 1. Lý do chọn đề tài

Nhu cầu theo dõi sức khỏe liên tục ngày càng cấp thiết, đặc biệt với người cao tuổi và người mắc bệnh mạn tính. Việc khám định kỳ không đủ để phát hiện sớm các bất thường như té ngã, rối loạn nhịp tim hay suy giảm chất lượng giấc ngủ.

Với sự phát triển của IoT, AI và công nghệ di động, việc xây dựng hệ thống thu thập dữ liệu liên tục, phân tích tự động và cảnh báo kịp thời đã trở nên khả thi. Đề tài HealthGuard ra đời nhằm hiện thực hóa một hệ sinh thái giám sát sức khỏe toàn diện — từ mô phỏng thiết bị, phân tích dữ liệu, đến ứng dụng quản trị và ứng dụng di động.

## 2. Mục tiêu đề tài

Xây dựng hệ thống HealthGuard có khả năng thu thập sinh hiệu, phân tích rủi ro, cảnh báo sự cố và quản trị tập trung. Cụ thể:

- Xây dựng nền tảng quản trị web quản lý người dùng, thiết bị, cấu hình, nhật ký và vận hành hệ thống.
- Xây dựng backend API tích hợp mô hình AI phục vụ dự đoán và phân tích sức khỏe.
- Xây dựng hệ thống mô phỏng thiết bị IoT tạo dữ liệu kiểm thử, thay thế thiết bị phần cứng thật.
- Xây dựng ứng dụng di động cho người dùng cuối theo dõi sức khỏe, nhận cảnh báo và thao tác khẩn cấp.
- Đối chiếu triển khai với đặc tả yêu cầu để đánh giá mức độ đáp ứng.

## 3. Đối tượng và phạm vi

### 3.1. Đối tượng

Hệ thống HealthGuard gồm bốn khối chính:

- **Web Admin Dashboard**: giao diện quản trị viên điều hành hệ thống.
- **API Backend tích hợp AI**: xử lý nghiệp vụ, cung cấp API và suy luận mô hình dự đoán.
- **IoT Simulator**: mô phỏng thiết bị và tạo dữ liệu kiểm thử.
- **Mobile App**: ứng dụng người dùng cuối theo dõi sức khỏe và nhận thông báo.

### 3.2. Phạm vi

- Xây dựng các chức năng cốt lõi: xác thực, quản lý người dùng/thiết bị, giám sát sức khỏe, xử lý khẩn cấp, phân tích rủi ro và giấc ngủ.
- Triển khai luồng dữ liệu từ mô phỏng thiết bị đến backend và hiển thị trên giao diện quản trị/di động.
- Dữ liệu đầu vào sử dụng chức năng giả lập từ dataset đã thu thập, thay cho thiết bị đeo thật.

### 3.3. Giới hạn

Trong phạm vi đồ án, hệ thống chưa triển khai trên hạ tầng quy mô lớn và chưa tích hợp thiết bị phần cứng thương mại hay hệ thống bệnh viện bên ngoài. Dữ liệu đầu vào được cung cấp thông qua mô phỏng từ dataset đã thu thập thay vì thiết bị đeo thật, nhằm đảm bảo kiểm thử có kiểm soát và lặp lại được. Một số chức năng nâng cao hiện ở mức nguyên mẫu, cần hoàn thiện thêm nếu hướng đến sản phẩm thực tế.

## 4. Phương pháp nghiên cứu

### 4.1. Phương pháp nghiên cứu lý thuyết

Tìm hiểu cơ sở lý thuyết về kiến trúc phần mềm phân tán, thiết kế API RESTful, cơ sở dữ liệu quan hệ, lưu trữ chuỗi thời gian và học máy ứng dụng trong phân tích sức khỏe. Tham khảo tài liệu yêu cầu, use case và thiết kế hệ thống hiện có để xác định khung triển khai.

### 4.2. Phương pháp thực nghiệm

Triển khai từng thành phần theo mô-đun, sử dụng dữ liệu mô phỏng từ dataset đã thu thập để kiểm tra luồng thu thập, phân tích và cảnh báo. Các ca kiểm thử được thực hiện lặp lại với nhiều kịch bản nhằm đánh giá tính ổn định của hệ thống.

### 4.3. Phương pháp đánh giá

- Định tính: đánh giá trải nghiệm sử dụng, mức phù hợp nghiệp vụ và khả năng đáp ứng use case.
- Định lượng: đo tỷ lệ kiểm thử đạt, độ trễ API và mức bao phủ chức năng.

## 5. Cấu trúc báo cáo

- **Mở đầu**: lý do, mục tiêu, đối tượng, phạm vi, phương pháp.
- **Chương 1**: Cơ sở lý thuyết.
- **Chương 2**: Phân tích yêu cầu hệ thống.
- **Chương 3**: Kiến trúc và thiết kế tổng thể.
- **Chương 4**: Thiết kế cơ sở dữ liệu và API.
- **Chương 5**: Xây dựng các module ứng dụng.
- **Chương 6**: Tích hợp AI, IoT Simulator và luồng dữ liệu thời gian thực.
- **Chương 7**: Kiểm thử, đánh giá và đối chiếu yêu cầu.
- **Kết luận**: kết quả đạt được và hướng phát triển.