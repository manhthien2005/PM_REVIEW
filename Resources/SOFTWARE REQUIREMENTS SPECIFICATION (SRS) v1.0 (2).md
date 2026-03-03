

| Dự án | Hệ thống theo dõi và cảnh báo sức khỏe cá nhân qua thiết bị Iot |
| :---- | :---- |
| **Ngày tạo** | 30/01/2026 |
| **Phiên bản** | v1.1 |
| **Ngày chỉnh sửa** | 05/02/2026 |

**[1\. GIỚI THIỆU	4](#1.-giới-thiệu)**

[1.1 Mục đích	4](#1.1-mục-đích)

[1.2 Phạm vi sản phẩm	4](#1.2-phạm-vi-sản-phẩm)

[1.3. Tổng quát	5](#1.3.-tổng-quát)

[**2\. MÔ TẢ TỔNG QUAN	7**](#2.-mô-tả-tổng-quan)

[2.1 Bối cảnh sản phẩm	7](#2.1-bối-cảnh-sản-phẩm)

[2.2 Các chức năng chính	8](#2.2-các-chức-năng-chính)

[2.3 Đặc điểm người dùng	8](#2.3-đặc-điểm-người-dùng)

[2.4 Môi trường vận hành	8](#2.4-môi-trường-vận-hành)

[2.5 Giả định và Phụ thuộc	9](#2.5-giả-định-và-phụ-thuộc)

[**3\. CÁC YÊU CẦU GIAO DIỆN NGOÀI	10**](#3.-các-yêu-cầu-giao-diện-ngoài)

[3.1 Giao diện người dùng (UI)	10](#3.1-giao-diện-người-dùng-\(ui\))

[3.2 Giao diện phần cứng (HI)	10](#3.2-giao-diện-phần-cứng-\(hi\))

[3.3 Giao diện truyền thông (CI)	10](#3.3-giao-diện-truyền-thông-\(ci\))

[**4\. CÁC YÊU CẦU CHỨC NĂNG	10**](#4.-các-yêu-cầu-chức-năng)

[4.1. Các tác nhân chính	10](#4.1.-các-tác-nhân-chính)

[4.2. Các chức năng của hệ thống	11](#4.2.-các-chức-năng-của-hệ-thống)

[4.3. Biểu đồ use case	12](#4.3.-biểu-đồ-use-case)

[4.4. Chi tiết biểu đồ use case	12](#4.4.-chi-tiết-biểu-đồ-use-case)

[4.4.1 Chi tiết use case “Quản trị viên”	12](#4.4.1-chi-tiết-use-case-“quản-trị-viên”)

[4.4.2 Chi tiết use case “Người chăm sóc/ Người thân”	12](#4.4.2-chi-tiết-use-case-“người-chăm-sóc/-người-thân”)

[4.4.3 Chi tiết use case “Bệnh nhân	12](#4.4.3-chi-tiết-use-case-“bệnh-nhân)

[4.5 Quy trình nghiệp vụ	12](#heading)

[4.6 Đặc tả use case	12](#4.6-đặc-tả-use-case)

[4.6.1 Đăng nhập	12](#4.6.1-đăng-nhập)

[**5\. CÁC YÊU CẦU PHI CHỨC NĂNG	13**](#5.-các-yêu-cầu-phi-chức-năng)

[5.1 Yêu cầu Hiệu năng	13](#5.1-yêu-cầu-hiệu-năng)

[5.2 Yêu cầu An toàn	13](#5.2-yêu-cầu-an-toàn)

[5.3 Yêu cầu Bảo mật	13](#5.3-yêu-cầu-bảo-mật)

[5.4 Thuộc tính chất lượng phần mềm	13](#5.4-thuộc-tính-chất-lượng-phần-mềm)

[**6\. CÁC YÊU CẦU KHÁC	14**](#6.-các-yêu-cầu-khác)

[6.1 Yêu cầu về Dữ liệu (Dataset)	14](#6.1-yêu-cầu-về-dữ-liệu-\(dataset\))

[6.2 Yêu cầu về Công cụ phát triển	14](#6.2-yêu-cầu-về-công-cụ-phát-triển)

[**PHỤ LỤC (APPENDIX)	15**](#phụ-lục-\(appendix\))

[A. Thuật ngữ viết tắt	15](#a.-thuật-ngữ-viết-tắt)

[B. Mô hình phân tích	16](#b.-mô-hình-phân-tích)

# 

# 

# 

# **1\. GIỚI THIỆU** {#1.-giới-thiệu}

## **1.1 Mục đích**  {#1.1-mục-đích}

Tài liệu này nhằm mục đích xác định các yêu cầu phần mềm cho dự án **Hệ thống theo dõi và cảnh báo sức khoẻ cá nhân qua thiết bị Iot**. Tài liệu mô tả chi tiết các yêu cầu chức năng và phi chức năng để phát triển một hệ thống trọn vẹn (End-to-End Product) bao gồm: Thiết bị giả lập (Simulator), Server xử lý dữ liệu lớn/AI và Ứng dụng di động. Tài liệu này là cơ sở để đội ngũ phát triển (Dev), kiểm thử (Tester) và giảng viên hướng dẫn thống nhất về phạm vi sản phẩm.

## **1.2 Phạm vi sản phẩm** {#1.2-phạm-vi-sản-phẩm}

Hệ thống **HealthGuard** là giải pháp IoT y tế hỗ trợ giám sát người cao tuổi và bệnh nhân có tiền sử tim mạch tại nhà hoặc trong môi trường bệnh viện. Phạm vi của hệ thống tập trung vào **theo dõi, phân tích và cảnh báo sớm rủi ro sức khỏe**, không thay thế chẩn đoán y khoa chuyên môn. Các tính năng chính bao gồm:

Phạm vi chức năng của hệ thống bao gồm:

* **Thu thập dữ liệu sinh tồn:**  
  Nhận luồng dữ liệu sinh lý theo thời gian thực từ thiết bị đeo thông minh (giả lập), bao gồm nhịp tim (HR), nồng độ oxy trong máu (SpO₂), gia tốc chuyển động và huyết áp (nếu có).  
* **Giám sát và phát hiện bất thường dựa trên ngưỡng y khoa:**  
  Phát hiện sớm các tình trạng bất thường của từng chỉ số sinh lý riêng lẻ như SpO₂ thấp, nhịp tim quá cao hoặc quá thấp trong trạng thái nghỉ, thân nhiệt vượt ngưỡng sốt và huyết áp bất thường, bằng cơ chế xử lý dựa trên ngưỡng y khoa.  
* **Phân tích nâng cao bằng Trí tuệ Nhân tạo (AI):**  
  Ứng dụng các mô hình Machine Learning/Deep Learning để xử lý các bài toán phức tạp và chuỗi thời gian, bao gồm phát hiện té ngã (Fall Detection) và chấm điểm nguy cơ đột quỵ (Stroke Risk Scoring) dựa trên sự kết hợp của nhiều chỉ số sinh lý.  
* **Cảnh báo và hỗ trợ khẩn cấp:**  
  Tự động kích hoạt quy trình SOS và gửi thông báo cảnh báo kèm thông tin vị trí GPS đến người giám sát khi phát hiện sự cố hoặc rủi ro cao.  
* **Minh bạch hóa quyết định AI (Explainable AI – XAI):**  
  Cung cấp thông tin giải thích cho các cảnh báo được tạo ra bởi mô hình AI, giúp người dùng và người giám sát hiểu được các yếu tố dữ liệu ảnh hưởng đến quyết định cảnh báo.

## **1.3. Tổng quát** {#1.3.-tổng-quát}

Tài liệu này được xây dựng theo chuẩn **Software Requirements Specification (SRS)**, tuân thủ các hướng dẫn trong *IEEE Recommended Practice for Software Requirements Specifications* và *IEEE Guide for Developing System Requirements Specifications*. Tài liệu đóng vai trò là cơ sở thống nhất giữa các bên liên quan trong quá trình phân tích, thiết kế, phát triển và kiểm thử hệ thống **HealthGuard – Hệ thống theo dõi và cảnh báo sức khỏe cá nhân qua thiết bị IoT**.

Nội dung tài liệu được tổ chức thành các phần chính như sau:

* **Chương 1 – Giới thiệu**: Trình bày mục đích của tài liệu, phạm vi sản phẩm và định hướng tổng thể của hệ thống HealthGuard.  
* **Chương 2 – Mô tả tổng quan**: Cung cấp bối cảnh sản phẩm, các chức năng chính, đặc điểm người dùng mục tiêu, môi trường vận hành, cũng như các giả định và phụ thuộc ảnh hưởng đến hệ thống.  
* **Chương 3 – Yêu cầu giao diện ngoài**: Mô tả các giao diện tương tác của hệ thống, bao gồm giao diện người dùng (UI), giao diện phần cứng (HI) và giao diện truyền thông (CI) giữa các thành phần như thiết bị giả lập, máy chủ và ứng dụng di động.  
* **Chương 4 – Các yêu cầu chức năng**: Đặc tả chi tiết các chức năng cốt lõi của hệ thống, bao gồm giám sát chỉ số sinh tồn, phát hiện té ngã, đánh giá rủi ro sức khỏe kết hợp Explainable AI (XAI), cũng như cơ chế xử lý dữ liệu và lưu trữ.  
* **Chương 5 – Các yêu cầu phi chức năng**: Xác định các yêu cầu về hiệu năng, an toàn, bảo mật và các thuộc tính chất lượng phần mềm nhằm đảm bảo hệ thống hoạt động ổn định, an toàn và phù hợp với bối cảnh ứng dụng y tế.  
* **Chương 6 – Các yêu cầu khác**: Trình bày các yêu cầu bổ sung liên quan đến dữ liệu huấn luyện mô hình AI và các công cụ, nền tảng hỗ trợ quá trình phát triển hệ thống.  
* **Phụ lục**: Bao gồm danh sách các thuật ngữ, từ viết tắt và mô hình phân tích nhằm hỗ trợ việc hiểu và tra cứu tài liệu.

Tài liệu SRS này là nền tảng quan trọng để đảm bảo hệ thống HealthGuard được phát triển đúng phạm vi, đáp ứng đầy đủ các yêu cầu đã đề ra và có khả năng mở rộng trong tương lai.

# 

# **2\. MÔ TẢ TỔNG QUAN** {#2.-mô-tả-tổng-quan}

## **2.1 Bối cảnh sản phẩm** {#2.1-bối-cảnh-sản-phẩm}

Sản phẩm là một hệ thống IoT y tế mới, độc lập, được thiết kế như một End-to-End System theo kiến trúc Layered Architecture kết hợp Multi-Backend, nhằm đảm bảo tính mở rộng, linh hoạt và dễ bảo trì trong tương lai.  
Ở mức tổng thể, hệ thống được chia thành các lớp logic chính như sau:  
**Device Layer**

* Bao gồm thiết bị đeo thông minh (được mô phỏng bằng Python Script), có nhiệm vụ thu thập dữ liệu sinh trắc học (nhịp tim, SpO₂, gia tốc, con quay hồi chuyển) và gửi dữ liệu theo thời gian thực lên hệ thống trung tâm.  
  **Connectivity Layer**  
* Đóng vai trò trung gian truyền thông, sử dụng các giao thức MQTT/HTTP để truyền dữ liệu dạng streaming từ thiết bị đeo đến backend server với độ trễ thấp và độ tin cậy cao.  
  **Data & Logic Layer (Multi-Backend Architecture)**  
* Lớp này được tách thành **2 Backend Server độc lập**, mỗi bên tối ưu cho client riêng và cùng chia sẻ chung 1 cơ sở dữ liệu PostgreSQL. Schema database được quản lý tập trung qua thư mục `SQL SCRIPTS/`.

  **Admin Backend (Node.js/Express + Prisma + TypeScript)**:  
  * User & Authentication Service (Admin): Quản lý người dùng, phân quyền Admin, xác thực bằng email/password.  
  * Dashboard & Analytics Service: Dashboard tổng hợp, báo cáo cho quản trị viên.  
  * System Configuration Service: Cấu hình ngưỡng cảnh báo, quản lý thiết bị, xem log hệ thống.

  **Mobile Backend (Python/FastAPI + SQLAlchemy)**:  
  * User & Authentication Service (Patient/Caregiver): Đăng nhập, đăng ký, quản lý profile bệnh nhân.  
  * Data Ingestion Service: Tiếp nhận và xử lý luồng dữ liệu cảm biến từ thiết bị (MQTT/HTTP).  
  * Health Monitoring Service: Giám sát chỉ số sinh tồn real-time, lịch sử sức khỏe.  
  * Health Analysis & AI Inference Service: Thực hiện suy luận AI (phát hiện té ngã, chấm điểm rủi ro sức khỏe), cung cấp giải thích XAI.  
  * Notification & Alert Service: Xử lý logic cảnh báo và gửi thông báo khẩn cấp (SOS, push notification).  
  * Sleep Analysis Service: Phân tích giấc ngủ dựa trên dữ liệu cảm biến.  
  * Device Management Service: Kết nối, quản lý trạng thái thiết bị IoT cho bệnh nhân.

**Application Layer**

* Bao gồm Mobile Application dành cho người dùng cuối (bệnh nhân, người thân) và Web Admin Dashboard dành cho quản trị viên, cho phép:  
  * Theo dõi chỉ số sức khỏe theo thời gian thực  
  * Nhận cảnh báo và thông báo khẩn cấp  
  * Quản lý người dùng và xem dữ liệu tổng hợp

## **2.2 Các chức năng chính** {#2.2-các-chức-năng-chính}

* Đăng nhập, đăng ký  
* Giám sát chỉ số sinh tồn.  
* Phát hiện té ngã.  
* Đánh giá rủi ro tim mạch/đột quỵ.  
* Cảnh báo và liên lạc khẩn cấp.  
* Phân tích giấc ngủ.  
* Quản trị người dùng.

## **2.3 Đặc điểm người dùng** {#2.3-đặc-điểm-người-dùng}

* Người dùng chính (Patient/Elderly): Người cao tuổi hoặc người bệnh. Đặc điểm: Thường không rành công nghệ, cần giao diện đơn giản, phông chữ lớn, thao tác ít.  
* Người giám sát (Caregiver/Family): Người thân của bệnh nhân. Đặc điểm: Cần nhận thông báo tức thời, xem được vị trí và lịch sử sức khỏe chi tiết.  
* Quản trị viên (System Admin): Quản lý danh sách người dùng, xem dashboard tổng hợp trên Web Admin.

## **2.4 Môi trường vận hành** {#2.4-môi-trường-vận-hành}

* Mobile App: Android (API level 28+) phát triển bằng Flutter.  
* Admin Web Application: ReactJS \+ TailwindCSS (Frontend), Node.js/Express \+ Prisma \+ TypeScript (Backend).  
* Mobile Backend Server: Python (FastAPI \+ SQLAlchemy), chạy trên môi trường Linux/Docker.  
* Admin Backend Server: Node.js (Express \+ Prisma), chạy trên môi trường Linux/Docker.  
* Database: PostgreSQL \+ TimescaleDB (lưu trữ Time-series data), dùng chung cho cả 2 Backend.  
* Database Schema Management: Quản lý tập trung qua thư mục `SQL SCRIPTS/`, cả 2 Backend introspect từ DB.  
* Simulator: Script Python chạy trên PC để giả lập dữ liệu cảm biến.

## **2.5 Giả định và Phụ thuộc** {#2.5-giả-định-và-phụ-thuộc}

* Hệ thống được giả định hoạt động trong môi trường có kết nối Internet ổn định. Thiết bị người dùng cũng như các thiết bị giả lập phải duy trì kết nối Internet liên tục để đảm bảo quá trình trao đổi dữ liệu và vận hành hệ thống không bị gián đoạn.  
* Trong phạm vi của phiên bản hiện tại, dữ liệu đầu vào được thu thập từ môi trường giả lập (Simulator). Dữ liệu này được giả định là phản ánh chính xác hành vi và đặc tính của dữ liệu thu thập từ các cảm biến trên thiết bị thực, nhằm phục vụ cho quá trình huấn luyện, kiểm thử và đánh giá mô hình AI.

# 

# **3\. CÁC YÊU CẦU GIAO DIỆN NGOÀI**  {#3.-các-yêu-cầu-giao-diện-ngoài}

## **3.1 Giao diện người dùng (UI)** {#3.1-giao-diện-người-dùng-(ui)}

* Dashboard: Hiển thị trực quan các chỉ số (Nhịp tim, SpO2, huyết áp ước tính) dạng đồng hồ số và biểu đồ đường (Line chart).  
* Màn hình SOS: Nút bấm khẩn cấp kích thước lớn, đồng hồ đếm ngược khi phát hiện té ngã.  
* Màn hình XAI: Hiển thị văn bản giải thích tự nhiên (Natural Language) cho các cảnh báo AI.

## **3.2 Giao diện phần cứng (HI)** {#3.2-giao-diện-phần-cứng-(hi)}

* Hệ thống giao tiếp với một mô-đun giả lập phần cứng được triển khai dưới dạng Python Client. Mô-đun này đóng vai trò mô phỏng các cảm biến trên thiết bị thực và truyền dữ liệu đến hệ thống thông qua giao thức mạng.

## **3.3 Giao diện truyền thông (CI)** {#3.3-giao-diện-truyền-thông-(ci)}

* MQTT/HTTP: Sử dụng để truyền luồng dữ liệu (Streaming Data) từ thiết bị về Server với độ trễ thấp.  
* Push Notification Service (FCM \- Firebase Cloud Messaging): Để gửi cảnh báo xuống Mobile App.  
* SMS/Call Service API (Giả lập): Để thực hiện chức năng gọi khẩn cấp.

# **4\. CÁC YÊU CẦU CHỨC NĂNG** {#4.-các-yêu-cầu-chức-năng}

## **4.1. Các tác nhân chính** {#4.1.-các-tác-nhân-chính}

Hệ thống HealthGuard gồm các tác nhân chính sau:

* **Bệnh nhân/Người cao tuổi**: Là đối tượng được hệ thống theo dõi sức khỏe. Người dùng này sử dụng ứng dụng di động để xem các chỉ số sinh tồn, nhận và phản hồi các cảnh báo khẩn cấp từ hệ thống.  
* **Người chăm sóc**: Là người thân hoặc nhân viên y tế có trách nhiệm theo dõi tình trạng sức khỏe của bệnh nhân. Tác nhân này nhận thông báo cảnh báo, xem vị trí và lịch sử sức khỏe của bệnh nhân thông qua ứng dụng.  
* **Mô-đun AI**: Có vai trò phân tích dữ liệu sinh tồn và dữ liệu chuyển động, thực hiện phát hiện té ngã, đánh giá rủi ro sức khỏe và cung cấp cơ chế giải thích (Explainable AI) cho các cảnh báo được tạo ra.  
* **Quản trị viên**: Có vai trò quản lý người dùng, cấu hình hệ thống, giám sát hoạt động tổng thể và đảm bảo hệ thống vận hành ổn định.

## **4.2. Các chức năng của hệ thống** {#4.2.-các-chức-năng-của-hệ-thống}

* **Tính năng Giám sát Chỉ Số Sinh tồn**  
  * HG-FUNC-01: Hệ thống phải thu thập dữ liệu nhịp tim, SpO2, huyết áp ước tính và thân nhiệt mỗi **1 phút** từ thiết bị giả lập.  
  * HG-FUNC-02: Hệ thống phải hiển thị dữ liệu này trên Mobile App với độ trễ không quá **5 giây**.  
  * HG-FUNC-03: Hệ thống phải gửi cảnh báo (Alert) nếu SpO2 \< 92% hoặc Thân nhiệt \> 37.8°C, nếu nhịp tim \> 100 bpm hoặc \< 60 bpm, nếu Huyết áp \> 140 mmHg hoặc \< 90 mmHg.  
* **Tính năng Phát hiện Té ngã**  
  * HG-FUNC-04: Hệ thống kết hợp dữ liệu gia tốc và sự thay đổi đột ngột của nhịp tim/huyết áp để xác nhận tình trạng té ngã chính xác hơn.  
  * HG-FUNC-05: Khi AI phát hiện mẫu hình té ngã (xác suất \> ngưỡng quy định), hệ thống phải kích hoạt trạng thái "Cảnh báo ngã" trên Server.  
  * HG-FUNC-06: Mobile App phải rung, phát âm thông báo và hiển thị đếm ngược 30 giây khi nhận trạng thái "Cảnh báo ngã".  
  * HG-FUNC-07: Nếu người dùng không nhấn "Hủy", hệ thống tự động gửi tin nhắn SOS kèm toạ độ GPS giả lập đến người giám sát.  
* **Tính năng Đánh giá Rủi ro & XAI**  
  * HG-FUNC-08: Hệ thống phải tính toán điểm rủi ro (Risk Score) dựa trên tổ hợp: HRV thấp \+ SpO2 thấp \+ Lịch sử huyết áp.  
  * HG-FUNC-09: Hệ thống phải cung cấp giải thích (Explainable AI) cho mức rủi ro cao. Ví dụ: "Nguy cơ cao do nhịp tim tăng vọt 120bpm khi đang nghỉ ngơi".  
* **Tính năng Data Pipeline & Lưu trữ**  
  * HG-FUNC-10: Hệ thống Backend phải có khả năng xử lý luồng dữ liệu (Stream Processing) từ nhiều thiết bị giả lập cùng lúc mà không bị tắc nghẽn.  
  * HG-FUNC-11: Dữ liệu lịch sử phải được lưu trữ vào PostgreSQL để phục vụ xem lại và huấn luyện lại mô hình (Retrain).

Để có thể hình dung rõ hơn về các tác nhân cũng như yêu cầu chức năng của hệ thống bằng cách mô hình hóa chúng dưới các sơ đồ use cases, các sơ đồ sẽ được trình bày phía sau.

## **4.3. Biểu đồ use case** {#4.3.-biểu-đồ-use-case}

![][image1]  
Hình 4.1 : Biểu đồ use case tổng quan

## **4.4. Chi tiết biểu đồ use case** {#4.4.-chi-tiết-biểu-đồ-use-case}

### **4.4.1 Chi tiết use case “Quản trị viên”** {#4.4.1-chi-tiết-use-case-“quản-trị-viên”}

![][image2]

### **4.4.2 Chi tiết use case “Người chăm sóc/ Người thân”** {#4.4.2-chi-tiết-use-case-“người-chăm-sóc/-người-thân”}

![][image3]  
![][image4]  
![][image5]  
![][image6]

### **4.4.3 Chi tiết use case “Bệnh nhân** {#4.4.3-chi-tiết-use-case-“bệnh-nhân}

## **![][image7]** {#heading}

## **![][image8]**

![][image9]

## **4.5 Quy trình nghiệp vụ**

Hệ thống HealthGuard vận hành dựa trên các quy trình nghiệp vụ chính sau:

### 4.5.1 Quy trình giám sát sức khỏe liên tục

1. Thiết bị IoT thu thập dữ liệu sinh trắc (nhịp tim, SpO₂, gia tốc, thân nhiệt) mỗi 1 phút.
2. Dữ liệu được truyền qua MQTT/HTTP đến Mobile Backend Server.
3. Server kiểm tra dữ liệu so với ngưỡng y khoa đã cấu hình.
4. Nếu chỉ số vượt ngưỡng cảnh báo → gửi thông báo đến người dùng và người chăm sóc.
5. Dữ liệu được lưu trữ vào PostgreSQL + TimescaleDB để phục vụ xem lịch sử và phân tích.

### 4.5.2 Quy trình phát hiện và xử lý té ngã

1. Mô-đun AI phân tích dữ liệu gia tốc và nhịp tim liên tục.
2. Khi phát hiện mẫu hình té ngã (confidence > 85%) → kích hoạt trạng thái "Cảnh báo ngã" trên Server.
3. Mobile App rung + phát âm thanh + hiển thị đếm ngược 30 giây để bệnh nhân xác nhận an toàn.
4. Nếu bệnh nhân nhấn "TÔI KHÔNG SAO" → hủy cảnh báo, ghi log false alarm.
5. Nếu không phản hồi trong 30 giây → tự động gửi SOS kèm vị trí GPS đến tất cả Emergency Contacts.
6. Người chăm sóc nhận SOS, xem vị trí trên bản đồ, và xử lý sự cố.
7. Sau khi xử lý → bệnh nhân hoặc người chăm sóc xác nhận an toàn để kết thúc Emergency Mode.

### 4.5.3 Quy trình đánh giá rủi ro sức khỏe

1. Hệ thống tự động đánh giá rủi ro mỗi 6 giờ hoặc khi người dùng yêu cầu.
2. Mô hình AI tính toán Risk Score (0-100) dựa trên tổ hợp: HRV, SpO₂, nhịp tim, lịch sử huyết áp, tiền sử bệnh lý.
3. Kết quả được phân loại: LOW (0-33) / MEDIUM (34-66) / HIGH (67-84) / CRITICAL (85-100).
4. Hệ thống cung cấp giải thích XAI (Explainable AI) cho các yếu tố ảnh hưởng chính.
5. Nếu rủi ro HIGH/CRITICAL → tự động gửi thông báo đến người chăm sóc.
6. Luôn hiển thị disclaimer: "Đây là công cụ hỗ trợ, không thay thế chẩn đoán y khoa".

### 4.5.4 Quy trình gửi SOS thủ công

1. Bệnh nhân bấm và giữ nút SOS trong 3 giây trên ứng dụng.
2. Popup xác nhận → bệnh nhân chọn "Có".
3. Hệ thống lấy vị trí GPS và gửi thông báo đến tất cả Emergency Contacts qua đa kênh (Push + SMS + Email).
4. App chuyển sang chế độ Emergency Mode cho đến khi bệnh nhân/người chăm sóc xác nhận an toàn.

## **4.6 Đặc tả use case** {#4.6-đặc-tả-use-case}

### [**4.6.1 Đăng nhập**](?tab=t.8ac5kkffr7ju) {#4.6.1-đăng-nhập}

### [**4.6.2 Đăng ký**](?tab=t.84mx5ejyz3vs)

### [**4.6.3 Quên mật khẩu**](?tab=t.6d1nmnlq37wc)

### [**4.6.4 Thay đổi mật khẩu**](?tab=t.1wczkuo6l0u)

# **5\. CÁC YÊU CẦU PHI CHỨC NĂNG** {#5.-các-yêu-cầu-phi-chức-năng}

## **5.1 Yêu cầu Hiệu năng**  {#5.1-yêu-cầu-hiệu-năng}

* Thời gian phản hồi: Cảnh báo té ngã phải được gửi đến App người thân trong vòng dưới 5 giây kể từ khi sự cố xảy ra \[Mục tiêu: Cấp cứu khẩn cấp\].  
* Độ chính xác AI: Mô hình phát hiện té ngã phải đạt độ nhạy (Sensitivity) \> 90% để tránh bỏ sót tai nạn.

## **5.2 Yêu cầu An toàn**  {#5.2-yêu-cầu-an-toàn}

* Cơ chế Fail-safe: Nếu App mất kết nối Internet, phải hiển thị cảnh báo "Mất kết nối" rõ ràng trên màn hình để người dùng biết hệ thống giám sát đang bị gián đoạn.

## **5.3 Yêu cầu Bảo mật**  {#5.3-yêu-cầu-bảo-mật}

* Mã hóa: Dữ liệu y tế truyền tải giữa Device và Server phải được mã hóa (TLS/SSL).  
* Xác thực: Sử dụng JWT (JSON Web Token) để xác thực người dùng và API.  
  * Admin Backend và Mobile Backend sử dụng JWT secret key riêng biệt, hoàn toàn độc lập.  
  * Admin token: issuer `iss="healthguard-admin"`, expiry 8 giờ, role: `ADMIN`.  
  * Mobile token: issuer `iss="healthguard-mobile"`, access token expiry 30 ngày, refresh token expiry 90 ngày (rotation — mỗi lần refresh tạo cặp token mới, invalidate token cũ), roles: `PATIENT`, `CAREGIVER`.  
* Mật khẩu: Hash bằng bcrypt (Admin BE) / passlib+bcrypt (Mobile BE), độ dài tối thiểu 8 ký tự.  
* Tuân thủ: Đảm bảo các nguyên tắc cơ bản về bảo vệ dữ liệu cá nhân (tương đương HIPAA ở mức độ học thuật).

## **5.4 Thuộc tính chất lượng phần mềm** {#5.4-thuộc-tính-chất-lượng-phần-mềm}

* Tính khả dụng (Usability): Giao diện Mobile App phải tuân thủ chuẩn thiết kế cho người khiếm thị/người già (tương phản cao, nút bấm lớn).  
* Tính mở rộng (Scalability): Backend thiết kế dạng Microservices để dễ dàng mở rộng thêm tính năng Telehealth sau này.

# 

# **6\. CÁC YÊU CẦU KHÁC**  {#6.-các-yêu-cầu-khác}

## **6.1 Yêu cầu về Dữ liệu (Dataset)** {#6.1-yêu-cầu-về-dữ-liệu-(dataset)}

Hệ thống sử dụng các bộ dữ liệu y khoa tiêu chuẩn và đã được cộng đồng nghiên cứu công nhận, bao gồm MIMIC-III, SisFall và MobiFall, nhằm phục vụ cho quá trình huấn luyện và đánh giá ban đầu các mô hình trí tuệ nhân tạo.

## **6.2 Yêu cầu về Công cụ phát triển** {#6.2-yêu-cầu-về-công-cụ-phát-triển}

* Quản lý mã nguồn: Git, GitHub.  
* Quản lý tiến độ & công việc: Trello.  
* Môi trường phát triển (IDE): Visual Studio Code  
* Thiết kế & quản lý giao diện người dùng (UI): Figma  
* Xây dựng và kiểm thử API: Postman  
* Admin Backend: Node.js, Express.js, Prisma ORM, TypeScript  
* Mobile Backend: Python, FastAPI, SQLAlchemy  
* Phát triển và huấn luyện mô hình AI: Python, TensorFlow/scikit-learn  
* Xử lý và phân tích dữ liệu: numpy, pandas  
* Lưu trữ dữ liệu: PostgreSQL + TimescaleDB  
* Quản lý Database Schema: SQL Scripts (tập trung, version-controlled)

# 

# **PHỤ LỤC (APPENDIX)** {#phụ-lục-(appendix)}

## **A. Thuật ngữ viết tắt** {#a.-thuật-ngữ-viết-tắt}

| Từ viết tắt | Giải thích |
| :---: | ----- |
| SRS | Software Requirements Specification |
| HRV | Heart Rate Variability (Biến thiên nhịp tim) |
| SpO2 | Peripheral Capillary Oxygen Saturation (Độ bão hòa oxy trong máu ngoại vi) |
| XAI | Explainable AI (AI có khả năng giải thích) |
| MQTT | Message Queuing Telemetry Transport |

## **B. Mô hình phân tích**  {#b.-mô-hình-phân-tích}
