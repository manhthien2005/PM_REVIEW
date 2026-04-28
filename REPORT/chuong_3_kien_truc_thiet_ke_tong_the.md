# CHƯƠNG 3. KIẾN TRÚC VÀ THIẾT KẾ TỔNG THỂ HỆ THỐNG

**Mục tiêu chương**: Mô tả kiến trúc tổng thể của hệ thống HealthGuard, vai trò từng module, luồng giao tiếp và đối chiếu với tài liệu thiết kế (SDD v1.0) cùng danh sách use case (29 UC). Mọi nhận định đều dựa trên bằng chứng từ source code thực tế và tài liệu trong `PM_REVIEW`.

**Phạm vi**: Chương này bao quát cả sáu module phần mềm — thuộc bốn hệ theo `NOTE.md`: **Admin** (`HealthGuard`), **Mobile** (`health_system`), **API core** (`model_be`) và **Simulator core** (`Iot_Simulator`) — cùng cơ sở dữ liệu dùng chung.

**Nguồn đối chiếu chính**:
- `PM_REVIEW/Resources/SOFTWARE DESIGN DOCUMENT (SDD) v1.0.md` — tài liệu thiết kế kiến trúc.
- `PM_REVIEW/Resources/UC/00_DANH_SACH_USE_CASE.md` — danh sách 29 UC.
- Source code thực tế trong từng repository.

## 3.1. Tổng quan kiến trúc

Hệ thống HealthGuard được chia thành nhiều **module**. Mỗi module là một ứng dụng độc lập, chỉ đảm nhận một nhóm chức năng cụ thể — ví dụ: ứng dụng di động dành cho người dùng cuối, trang quản trị dành cho admin, hay dịch vụ chuyên xử lý các bài toán AI. Các module trao đổi dữ liệu với nhau theo hai cách: gọi sang nhau qua API (giao thức HTTP), hoặc cùng đọc và ghi trên một cơ sở dữ liệu dùng chung.

TODO:HINHANH

Cách tổ chức này mang lại ba lợi ích thực tế: thứ nhất, các nhóm phát triển có thể làm song song trên từng module mà không "đụng" mã của nhau; thứ hai, khi cần sửa lỗi hoặc nâng cấp một module, các module còn lại vẫn hoạt động bình thường; thứ ba, việc triển khai cũng linh hoạt hơn vì có thể chỉ cập nhật một phần thay vì cả hệ thống.

Các module chính của hệ thống gồm:

- **Mobile App**: giao diện dành cho bệnh nhân và người chăm sóc, cung cấp các chức năng xem sinh hiệu, quản lý thiết bị, nhận cảnh báo, gửi SOS và xem phân tích sức khỏe.
- **Mobile Backend**: dịch vụ API phục vụ Mobile App, xử lý xác thực, nhận dữ liệu telemetry, quản lý sự cố khẩn cấp, suy luận rủi ro và gửi thông báo đẩy.
- **Admin Web**: giao diện web dành cho quản trị viên, cung cấp tổng quan hệ thống, quản lý người dùng, thiết bị, nhật ký, cấu hình, sự cố khẩn cấp và mô hình AI.
- **Admin Backend**: dịch vụ API phục vụ Admin Web, tích hợp WebSocket để cập nhật thời gian thực.
- **Dịch vụ mô hình AI**: dịch vụ suy luận chuyên biệt cho ba miền: phát hiện té ngã, đánh giá rủi ro sức khỏe và chấm điểm giấc ngủ.
- **Dịch vụ mô phỏng**: module giả lập thiết bị IoT, tạo dữ liệu sinh hiệu và chuyển động từ dataset y sinh thật, truyền dữ liệu về backend qua MQTT hoặc HTTP.
- **Cơ sở dữ liệu dùng chung**: PostgreSQL kết hợp TimescaleDB, lưu trữ dữ liệu người dùng, thiết bị, sinh hiệu, sự kiện, rủi ro, giấc ngủ và nhật ký hệ thống.

Về mô hình lưu trữ, cả Mobile Backend và Admin Backend cùng truy cập một cơ sở dữ liệu duy nhất. Nhờ đó, dữ liệu phát sinh từ phía người dùng cuối (chỉ số sinh hiệu, sự kiện té ngã, yêu cầu kết nối thiết bị…) được đồng bộ ngay lập tức với giao diện quản trị, không cần cơ chế đồng bộ trung gian.

## 3.2. Sơ đồ kiến trúc tổng quan


TODO:HINHANH:3.2

Dịch vụ mô phỏng truyền dữ liệu về Mobile Backend qua MQTT (kênh chính) hoặc HTTP (kênh dự phòng). Mobile Backend gửi thông báo đẩy đến thiết bị di động qua FCM; Admin Backend đẩy cập nhật thời gian thực đến giao diện quản trị qua Socket.IO.

## 3.3. Nguyên tắc kiến trúc

Kiến trúc hệ thống được thiết kế dựa trên các nguyên tắc sau:

### 3.3.1. Tách module theo vai trò

- Giao diện và API phục vụ quản trị viên (Admin Backend, Admin Web) được tách riêng khỏi phần phục vụ người dùng cuối (Mobile Backend, Mobile App). Điều này cho phép mỗi nhóm phát triển có thể triển khai và cập nhật độc lập.
- Dịch vụ mô hình AI chạy như một dịch vụ riêng, không phụ thuộc vào logic nghiệp vụ của các backend giao dịch. Nhờ đó, việc nâng cấp mô hình không ảnh hưởng đến hoạt động của hệ thống chính.
- Dịch vụ mô phỏng tách biệt hoàn toàn khỏi backend sản phẩm, phục vụ mục đích kiểm thử và demo mà không gây nhiễu dữ liệu vận hành.

### 3.3.2. Cơ sở dữ liệu dùng chung

Mobile Backend và Admin Backend cùng truy cập một cơ sở dữ liệu PostgreSQL/TimescaleDB. Cách tiếp cận này giúp đồng bộ tự nhiên các thực thể chung (người dùng, thiết bị, sinh hiệu, sự kiện, cảnh báo) mà không cần message queue hay cơ chế đồng bộ phức tạp.

### 3.3.3. Quy ước định tuyến API

Mỗi module sử dụng tiền tố URL riêng biệt, giúp phân biệt rõ nguồn gốc yêu cầu:

| Module | Tiền tố URL | Ghi chú |
| --- | --- | --- |
| Admin Backend | `/api/v1/admin/*` | API quản trị chính |
| Admin nội bộ | `/api/v1/internal/*` | API dành cho script nội bộ |
| Mobile Backend | `/api/v1/mobile/*` | API phục vụ Mobile App |
| Dịch vụ mô hình AI | `/api/v1/fall/*`, `/api/v1/health/*`, `/api/v1/sleep/*` | Mỗi miền suy luận có tiền tố riêng |
| Dịch vụ mô phỏng | `/api/sim/*` | API quản lý và điều khiển mô phỏng |

### 3.3.4. Phân tầng xử lý

Các backend đều tuân thủ nguyên tắc phân tầng để tách biệt logic nghiệp vụ khỏi tầng định tuyến và tầng truy cập dữ liệu:

- **Admin Backend (Express)**: routes → controllers → services → Prisma (ORM) → database.
TODO:HINHANH:3.3.1
- **Mobile Backend (FastAPI)**: routes → services → (repositories hoặc raw SQL) → SQLAlchemy → database. Tầng repository chỉ dùng cho một số miền (xác thực, quan hệ người dùng); các service còn lại truy vấn trực tiếp bằng raw SQL.
TODO:HINHANH:3.3.2
- **Dịch vụ mô hình AI (FastAPI)**: routers → services (load model + predict) → model artifacts.
TODO:HINHANH:3.3.3

### 3.3.5. Tài liệu API tự động

- Admin Backend: Swagger UI tại `/admin-docs`.
- Mobile Backend: Swagger UI tại `/mobile-docs`, ReDoc tại `/mobile-redoc`.
- Dịch vụ mô hình AI: Swagger UI mặc định tại `/docs`.

## 3.4. Kiến trúc Admin Web

> **UC liên quan**: UC001, UC009, UC022, UC024–UC029.
> **Đối chiếu SDD**: mục 3.2 (Admin Backend) và mục 3.4 (Admin Frontend).

### 3.4.1. Frontend

Admin Web được xây dựng bằng React + Vite, sử dụng TanStack React Query để quản lý trạng thái server và cache dữ liệu API, Tailwind CSS cho giao diện và Socket.IO Client cho cập nhật thời gian thực. Các trang quản trị (overview, người dùng, thiết bị, nhật ký, cấu hình, sự cố khẩn cấp, AI models) được bọc trong `AdminLayout` và bảo vệ bởi `ProtectedRoute` — chỉ truy cập được khi đã xác thực.

### 3.4.2. Backend

Admin Backend chạy trên Express + Prisma (PostgreSQL) + Socket.IO. Xác thực dùng JWT (cookie hoặc Authorization header), kết hợp middleware `authenticate` và `requireAdmin` ở tầng route. Toàn bộ route mount tại `/api/v1/admin/*` với các nhóm: auth, users, devices, logs, settings, emergencies, health, dashboard, vital-alerts, ai-models. Đường dẫn `/api/v1/internal/*` phục vụ các script nội bộ.

**Giao tiếp thời gian thực**: WebSocket Service phát các sự kiện như `health:new-alert`, `emergency:new-event`, `dashboard:kpi-update` đến Admin Web. Kết nối được xác thực qua JWT và phân chia theo phòng (`admin-room` cho quản trị viên, `user-{id}` cho từng người dùng cụ thể).

## 3.5. Kiến trúc Mobile App

> **UC liên quan**: 22 UC trên mobile (UC001–UC011, UC014–UC017, UC020–UC021, UC030–UC031, UC040–UC042).
> **Đối chiếu SDD**: mục 3.3 (Mobile App — Flutter).

Mobile App được xây dựng bằng Flutter/Dart theo kiến trúc **feature-first**: mỗi nhóm chức năng nằm trong một thư mục riêng (`lib/features/<feature>`), chứa đầy đủ giao diện, logic nghiệp vụ và lớp gọi API của nhóm đó. Cách tổ chức này giúp tách biệt các tính năng và dễ phát triển song song.

**Stack chính**: `provider` (state), `http` (REST), `flutter_secure_storage` (lưu token), `firebase_messaging` (thông báo đẩy qua FCM), `web_socket_channel` (WebSocket), `fl_chart` (biểu đồ sinh hiệu), `mobile_scanner` + `qr_flutter` (ghép thiết bị qua mã QR), `geolocator` + `flutter_map` (định vị và bản đồ cho SOS), `slide_to_act` (trượt kích hoạt SOS).

**Các nhóm tính năng**: xác thực, trang chủ, hồ sơ, gia đình (liên kết người chăm sóc), thiết bị, giám sát sức khỏe, cấp cứu (SOS), phân tích rủi ro, giấc ngủ, thông báo.

## 3.6. Kiến trúc Mobile Backend

> **UC liên quan**: phục vụ toàn bộ 22 UC của Mobile App.
> **Đối chiếu SDD**: mục 3.1 (Mobile Backend — FastAPI).

Mobile Backend xây dựng bằng FastAPI + Uvicorn, kết nối PostgreSQL/TimescaleDB qua SQLAlchemy. Xác thực sử dụng JWT hai token (access ngắn hạn, refresh dài hạn) với python-jose; mật khẩu được băm bằng bcrypt; thông báo đẩy phát qua Firebase Admin SDK.

Toàn bộ route mount với tiền tố `/api/v1/mobile/*`, gồm các nhóm: `auth`, `profile`, `device`, `monitoring`, `telemetry`, `emergency`, `risk`, `health`, `notifications`, `settings`, `relationships`, `fall_events` và `admin` (API nội bộ phục vụ đồng bộ thiết bị từ dịch vụ mô phỏng — bảo vệ bằng header `X-Internal-Service`).

**Chức năng nổi bật**:

- **Tiếp nhận telemetry**: nhận dữ liệu sinh hiệu, chuyển động và giấc ngủ từ thiết bị hoặc dịch vụ mô phỏng, lưu vào cơ sở dữ liệu time-series.
- **Suy luận rủi ro**: `risk_inference_service` gọi Dịch vụ mô hình AI để chấm điểm rủi ro; nếu mô hình không khả dụng, tự động chuyển sang logic dự phòng dạng rule-based để duy trì hoạt động.
- **Thông báo đẩy**: gửi push notification đến Mobile App qua FCM khi có cảnh báo hoặc sự kiện khẩn cấp.

## 3.7. Kiến trúc Dịch vụ mô hình AI

> **UC liên quan**: UC010 (té ngã), UC016–UC017 (rủi ro sức khỏe), UC020–UC021 (giấc ngủ).
> **Đối chiếu SDD**: SDD v1.0 không tách dịch vụ AI thành một thành phần riêng — trên thực tế đã được tách thành ứng dụng FastAPI độc lập.

Dịch vụ mô hình AI là ứng dụng FastAPI chuyên phục vụ suy luận cho ba miền: phát hiện té ngã, đánh giá rủi ro sức khỏe và chấm điểm giấc ngủ. Mô hình được huấn luyện sẵn và đóng gói thành bundle `joblib` (sử dụng scikit-learn, LightGBM, XGBoost hoặc CatBoost tùy miền).

**Cơ chế nạp mô hình**: ba bundle (fall, health, sleep) được nạp một lần vào bộ nhớ khi ứng dụng khởi động thông qua cơ chế `lifespan` của FastAPI. Sau đó các request `/predict` sử dụng lại artifact trong bộ nhớ, không phải đọc lại từ đĩa — giúp giảm độ trễ suy luận.

**Cấu trúc API**: mỗi miền `{domain}` (fall/health/sleep) cung cấp bộ endpoint thống nhất gồm `POST /api/v1/{domain}/predict` (suy luận đơn lẻ hoặc batch), `GET /api/v1/{domain}/model-info` (thông tin mô hình) và `GET /api/v1/{domain}/sample-input`, `/sample-cases` (dữ liệu mẫu phục vụ kiểm thử). Endpoint hệ thống `GET /health` trả về trạng thái từng mô hình (`healthy`/`degraded`/`unhealthy`); `GET /api/v1/models` liệt kê toàn bộ mô hình đang nạp.

**Ngưỡng phân loại** được cấu hình qua biến môi trường — mỗi miền có ngưỡng riêng để chuyển kết quả số sang nhãn cảnh báo (warning/critical), cho phép điều chỉnh độ nhạy mà không cần huấn luyện lại mô hình.

## 3.8. Kiến trúc Dịch vụ mô phỏng

> **UC liên quan**: cung cấp dữ liệu đầu vào cho UC006–UC008 (telemetry), UC010 (cửa sổ chuyển động cho fall detection), UC020 (kịch bản giấc ngủ).
> **Đối chiếu SDD**: SDD v1.0 mô tả sơ ở Device Layer; trên thực tế đã phát triển phức tạp hơn nhiều.

Dịch vụ mô phỏng giả lập thiết bị đeo IoT, sinh dữ liệu sinh hiệu và chuyển động từ dataset y sinh thật, truyền về Mobile Backend như thiết bị thật. Module này gồm ba thành phần chính.

### 3.8.1. API Server

API Server xây dựng bằng FastAPI, quản lý một singleton `SimulatorRuntime` qua cơ chế `lifespan`. Toàn bộ route mount tại `/api/sim/*`, gồm các nhóm: `devices`, `dashboard`, `registry`, `scenarios`, `sessions`, `vitals`, `events`, `verification`, `analytics`, `settings`. Ngoài REST, API Server còn cung cấp WebSocket `/ws/logs/{session_id}` để truyền nhật ký mô phỏng theo thời gian thực.

### 3.8.2. Simulator Core

Simulator Core chứa logic sinh dữ liệu, gồm các thành phần chính:

- **`DatasetRegistry`**: nạp và lập chỉ mục artifact từ dataset y sinh.
- **`PersonaEngine`**: quản lý trạng thái nhân vật mô phỏng (hoạt động, pin, stress); hỗ trợ inject sự kiện như té ngã.
- **`VitalsGenerator` / `MotionGenerator`**: sinh dữ liệu sinh hiệu và chuyển động theo trạng thái persona và dataset thực.
- **`SimulatorSession`**: điều phối phiên mô phỏng, gọi tick định kỳ và đẩy dữ liệu xuống tầng truyền tải.

Dịch vụ mô phỏng hỗ trợ tám bộ dataset y sinh thật (BIDMC, PAMAP2, PIF v3, PPG-DaLiA, Sleep-EDF, UP-Fall, VitalDB, WESAD) thông qua các adapter chuyên biệt — mỗi adapter chuyển đổi dữ liệu thô thành định dạng artifact chuẩn để `DatasetRegistry` lập chỉ mục.

### 3.8.3. Tầng truyền tải

Tầng truyền tải có hai kênh: **MQTT** (chính, phù hợp telemetry liên tục) và **HTTP POST** (dự phòng). `TransportRouter` điều phối giữa hai kênh: nếu MQTT thất bại, tự động chuyển sang HTTP fallback để đảm bảo tính liên tục của dòng dữ liệu.

### 3.8.4. Simulator Web

Giao diện web (React + Vite + TanStack React Query) cung cấp các chức năng quản lý thiết bị mô phỏng, cấu hình kịch bản, chạy phiên mô phỏng, xem phân tích và xác minh dữ liệu.

## 3.9. Luồng dữ liệu tổng thể

### 3.9.1. Luồng giám sát sức khỏe thời gian thực

```
Dịch vụ mô phỏng
  → [MQTT/HTTP] telemetry ingest
  → Mobile Backend
  → Lưu vào bảng `vitals` (TimescaleDB)
  → Kiểm tra ngưỡng → Tạo `alerts` nếu vượt ngưỡng
  → Gửi thông báo đẩy đến Mobile App (FCM)
  → Đẩy sự kiện qua Socket.IO đến Admin Web
```

Đây là luồng cốt lõi: dữ liệu sinh hiệu từ thiết bị (hoặc mô phỏng) được nhận liên tục, lưu trữ time-series, kiểm tra ngưỡng và phát cảnh báo đến cả người dùng di động lẫn quản trị viên.

### 3.9.2. Luồng phát hiện té ngã

```
Dịch vụ mô phỏng
  → Sinh dữ liệu cửa sổ chuyển động (motion window)
  → Mobile Backend nhận telemetry
  → Gọi Dịch vụ mô hình AI (POST /api/v1/fall/predict)
  → Nếu phát hiện té ngã → Tạo `fall_events`
  → Đếm ngược chờ xác nhận từ người dùng
  → Nếu không hủy → Tạo `sos_events` (auto)
  → Gửi thông báo đến người chăm sóc + quản trị viên
```

### 3.9.3. Luồng phân tích giấc ngủ

```
Dịch vụ mô phỏng (kịch bản sleep)
  → Sinh dữ liệu phiên giấc ngủ
  → Mobile Backend nhận dữ liệu
  → Gọi Dịch vụ mô hình AI (POST /api/v1/sleep/predict)
  → Lưu kết quả vào `sleep_sessions`
  → Hiển thị báo cáo giấc ngủ trên Mobile App
  → Tích hợp vào đánh giá rủi ro tổng hợp
```

### 3.9.4. Luồng quản trị

```
Quản trị viên đăng nhập
  → Admin Web gọi Admin Backend
  → Admin Backend truy vấn cơ sở dữ liệu
  → Trả về KPI, danh sách người dùng, thiết bị, sự cố, nhật ký
  → Quản trị viên thực hiện hành động (cấu hình, xử lý sự cố, quản lý AI model)
  → Admin Backend ghi nhật ký hành động (audit log)
```

### 3.9.5. Luồng quản lý mô hình AI

```
Quản trị viên tạo mô hình/phiên bản mới trên Admin Web
  → Admin Backend nhận file artifact
  → Upload lên Cloudflare R2 (qua AWS S3 SDK)
  → Lưu metadata vào cơ sở dữ liệu
  → Kích hoạt phiên bản → Ghi audit log
```

Luồng này cho phép quản trị viên quản lý vòng đời mô hình AI mà không cần truy cập trực tiếp vào server, đảm bảo tính truy vết thông qua audit log.

