# Plan — HOME_Dashboard Visual Refinement V2

> **Target**: `HOME_Dashboard`
> **Type**: Visual/UI content refinement plan sau khi đã có bản build đầu tiên
> **Reason**: Bản build hiện tại đã đi đúng hướng nhưng vẫn còn vài điểm gây hiểu nhầm và chưa đủ nổi bật về mặt thị giác, đặc biệt ở banner `Sức khoẻ hôm nay`, màu tổng quan, và CTA `SOS`.

## Approach

Giữ nguyên khung layout tổng thể của bản build hiện tại vì nền tảng đã ổn: header, hero, section chỉ số, insight cards, sticky SOS, bottom nav. Vòng chỉnh này tập trung vào **ngôn ngữ thị giác**, **cách gọi tên**, **mức độ dễ hiểu với người già**, và **độ sinh động** để màn hình vừa hợp người trẻ, vừa không gây rối với người lớn tuổi.

Trọng tâm lớn nhất là: **không để user phải tự diễn giải điểm số trừu tượng**. Thông tin cần được chuyển từ kiểu "dữ liệu hệ thống" sang kiểu "người dùng nhìn là hiểu".

## Scope

- In:
  - Refine banner `Sức khoẻ hôm nay`
  - Refine banner `Giấc ngủ`
  - Refine banner đang đại diện cho `AI risk`
  - Refine màu sắc tổng thể giữa các section
  - Refine copywriting và visual của nút `SOS`
  - Refine cách tóm tắt phần `Chỉ số hôm nay`

- Out:
  - Không thay đổi flow business
  - Không thay đổi API hoặc route
  - Không đổi kiến trúc `Hybrid Tabs`
  - Không refactor lại toàn bộ `Bottom Navigation`
  - Không build code trong plan này

## Decision Summary

### 1. Không dùng raw score kiểu `32 = tốt`

Đây là điểm cần sửa **ưu tiên cao nhất**.

`32 = tốt` là cách hiển thị rất dễ gây hiểu nhầm với người lớn tuổi, vì họ thường hiểu trực giác rằng:

- điểm thấp = xấu
- điểm cao = tốt

Vì vậy:

- **Không show raw score low-is-good** như một giá trị chính
- Nếu backend hiện đang trả `risk score` theo logic thấp = tốt, thì UI phải **ẩn logic đó đi**
- UI chỉ nên show:
  - trạng thái bằng lời
  - mô tả ngắn
  - nếu cần số, phải là số theo thang **cao = tốt**

### 2. Chuyển từ “card text” sang “card có chủ đề rõ”

Mỗi banner insight phải có:

- một mood màu riêng
- một hình ảnh/illustration rõ chủ đề
- ít text hơn
- 1 thông điệp chính, 1 thông điệp phụ

### 3. Giữ `Chỉ số hôm nay` theo dạng scan nhanh

Không gom 4 chỉ số thành 1 banner duy nhất.  
Giải pháp tốt hơn là:

- thêm **summary header/banner nhỏ** cho section
- vẫn giữ các card chỉ số riêng bên dưới

## Section-by-section Adjustment Plan

## A. Banner `Sức khoẻ hôm nay`

### Vấn đề hiện tại

- Tên mới đã dễ hiểu hơn `Điểm rủi ro AI`, nhưng card hiện tại còn hơi trống.
- Cách hiển thị số `32` làm người dùng dễ hiểu sai.
- Chưa tạo cảm giác đây là “kết luận quan trọng nhất hôm nay”.

### Hướng chỉnh

#### A1. Đổi mô hình hiển thị

Ưu tiên 1:

- dùng **status-first UI**
- ví dụ:
  - `Sức khoẻ hôm nay`
  - `Ổn định`
  - `Hiện chưa có dấu hiệu đáng lo ngại`

Ưu tiên 2:

- nếu vẫn muốn có số, đổi sang thang **cao = tốt**
- ví dụ:
  - `Mức ổn định hôm nay: 82/100`
  - không dùng `32/100` nếu `32` thực chất là nguy cơ thấp

#### A2. Đổi tên nội dung

Đề xuất thay thế:

- Không dùng: `Điểm sức khoẻ`
- Có thể dùng:
  - `Sức khoẻ hôm nay`
  - `Mức ổn định hôm nay`
  - `Tình trạng hôm nay`

Khuyến nghị mạnh nhất:

- **Tiêu đề card**: `Sức khoẻ hôm nay`
- **Nhãn trạng thái chính**: `Ổn định` / `Cần theo dõi` / `Cần nghỉ ngơi`

#### A3. Thiết kế lại theo hướng “health insight card”

Card này nên đi cùng công thức giống banner ngủ:

- icon / illustration lớn bên trái
- phần phải chỉ có:
  - trạng thái chính
  - một chỉ số phụ nếu cần
  - 1 câu ngắn dễ hiểu

Ví dụ:

```text
Sức khoẻ hôm nay
Ổn định
Cơ thể bạn đang ở trạng thái an toàn
```

hoặc

```text
Sức khoẻ hôm nay
82/100 mức ổn định
Hôm nay chưa có dấu hiệu đáng lo ngại
```

#### A4. Mood màu

Không dùng xanh teal phẳng như hiện tại.  
Đề xuất:

- nền xanh trời đậm vừa phải hoặc xanh ngọc sâu
- có texture nhẹ hoặc gradient mềm
- icon/illustration sáng để nổi lên

Mục tiêu:

- phân biệt rõ với banner `Giấc ngủ`
- vẫn tạo cảm giác khỏe khoắn, tích cực

---

## B. Banner `Giấc ngủ`

### Điểm tốt hiện tại

- Đã đi đúng hướng hơn hẳn
- Nhìn phát hiểu chủ đề
- Có mood rõ hơn các section khác

### Cần chỉnh tiếp

#### B1. Giảm text

Hiện card ngủ đã ổn hơn, nhưng vẫn có thể tinh hơn:

- chỉ giữ 3 tầng thông tin:
  - `Bạn đã ngủ`
  - `7 giờ 20 phút`
  - `Ngủ sâu và ổn định`

Không cần nhiều text giải thích hơn trong card.

#### B2. Tăng chất “đêm”

Đề xuất visual:

- dark navy / tím đêm
- sao nhỏ hoặc glow mềm
- illustration mặt ngủ / trăng / mây nhẹ
- motion nhẹ nếu sau này có animation

#### B3. Thể hiện chất lượng bằng màu

Ví dụ:

- ngủ tốt: vàng ấm / xanh tím cân bằng
- ngủ trung bình: xanh tím nhẹ + amber accent
- ngủ kém: tím tối + cam/đỏ nhỏ

Mục tiêu:

- user nhìn card là cảm được “đêm qua ngủ tốt hay không”, không cần đọc hết text

---

## C. Section `Chỉ số hôm nay`

### Nhận định

Đây là section hiện đang ổn nhất về công năng.  
Không nên thay nó bằng một banner lớn duy nhất.

### Hướng chỉnh

#### C1. Thêm summary banner nhỏ phía trên

Ví dụ:

```text
Chỉ số hôm nay
3 chỉ số ổn định, 1 chỉ số cần theo dõi
```

Banner này có thể là một strip nhỏ hoặc sub-card nằm ngay trên grid.

#### C2. Giữ các card riêng

Vẫn giữ 4 card vì:

- dễ scan
- dễ so sánh
- dễ chạm để đi vào chi tiết

#### C3. Cho phép một card nổi bật hơn khi có warning

Ví dụ:

- huyết áp đang warning thì card huyết áp có thể:
  - border đậm hơn
  - icon warning rõ hơn
  - hoặc tăng kích thước nhẹ nếu muốn future refinement

### Kết luận section này

- **Không gộp hoàn toàn**
- **Có thể thêm một summary banner nhỏ ở trên**

---

## D. Nút `SOS`

### Vấn đề hiện tại

- Text quá dài
- Cảm giác giống cảnh báo in trên form hơn là CTA khẩn cấp
- Outline đỏ đọc được nhưng chưa đủ “hành động”

### Hướng chỉnh

#### D1. Đổi text

Ưu tiên ngắn, rõ, 1 giây là hiểu:

- `Gọi SOS khẩn cấp`
- `Kích hoạt SOS`
- `Cần trợ giúp khẩn cấp`

Khuyến nghị mạnh nhất:

- **Primary text**: `Gọi SOS khẩn cấp`

#### D2. Thêm dòng phụ nếu cần

Để giảm sợ bấm nhầm:

- `Có xác nhận trước khi gửi`

Dòng phụ này nên nhỏ hơn, không tranh sự chú ý với dòng chính.

#### D3. Đổi visual

Thay vì chỉ outline đỏ:

Option khuyến nghị:

- nền đỏ rất nhạt
- viền đỏ rõ
- icon SOS ở trái
- text đỏ đậm

Hoặc:

- solid red button
- text trắng
- icon trắng

Nếu app đang theo hướng nhẹ và tinh hơn, em nghiêng về:

- **soft red background + red border + icon**

#### D4. Cảm giác hành động

Nút này phải cho user cảm giác:

- dễ thấy
- dễ bấm
- đáng tin
- nhưng không làm cả màn bị “panic”

---

## E. Màu sắc tổng thể

### Vấn đề hiện tại

- Mỗi section đang nói một “giọng màu” khác nhau
- Chưa tạo thành một visual system thống nhất

### Hướng chỉnh

#### E1. Chuẩn hóa theo 3 lớp màu

- **Base app**: sáng, sạch, trung tính
- **Functional cards**: trắng hoặc near-white
- **Insight banners**: mỗi banner có một mood riêng nhưng vẫn cùng một hệ

#### E2. Mood đề xuất cho từng section

- `Hero tổng quan`: mint / xanh nhạt bình tĩnh
- `Giấc ngủ`: navy / tím đêm
- `Sức khoẻ hôm nay`: xanh ngọc sâu / xanh trời đậm tích cực
- `SOS`: semantic red

#### E3. Giảm cảm giác “basic”

Không cần đổ thêm quá nhiều màu.  
Cần thêm:

- gradient nhẹ
- illustration/icon có cá tính hơn
- tương phản rõ giữa section utilitarian và section insight

---

## F. Copywriting refinement

### Mục tiêu

Giảm text, tăng độ hiểu.

### Rule

- 1 card = 1 ý chính
- hạn chế câu dài
- ưu tiên từ đời thường thay vì từ quá trừu tượng

### Thay đổi khuyến nghị

- Không dùng: `Điểm sức khoẻ 32`
- Dùng:
  - `Ổn định`
  - `Hôm nay cơ thể bạn đang ở trạng thái an toàn`
  - `Ngủ sâu và ổn định`
  - `1 chỉ số cần theo dõi thêm`
  - `Gọi SOS khẩn cấp`

---

## Action Items

- [ ] Chốt nguyên tắc mới cho banner `Sức khoẻ hôm nay`: không show raw score low-is-good.
- [ ] Đổi content model của card `Sức khoẻ hôm nay` sang `status-first` hoặc thang điểm `cao = tốt`.
- [ ] Thiết kế lại visual cho card `Sức khoẻ hôm nay` theo hướng illustration-led, ít text, mood tích cực rõ hơn.
- [ ] Tinh gọn card `Giấc ngủ` thành 3 tầng thông tin chính và tăng chất “đêm” bằng màu/ảnh/hiệu ứng nhẹ.
- [ ] Thêm `summary banner` nhỏ cho section `Chỉ số hôm nay` nhưng giữ nguyên 4 card chỉ số riêng.
- [ ] Refine visual state cho card warning trong `Chỉ số hôm nay` để card bất thường nổi bật hơn card bình thường.
- [ ] Đổi copy của nút `SOS` sang câu ngắn, rõ, dễ hiểu với người lớn tuổi.
- [ ] Thiết kế lại nút `SOS` với icon + hierarchy rõ hơn, ưu tiên soft red background hoặc solid red có kiểm soát.
- [ ] Chuẩn hóa lại palette giữa `hero`, `sleep`, `health insight`, và `SOS` để các section khác nhau nhưng vẫn cùng một hệ.
- [ ] Review lại toàn màn bằng 3 tiêu chí: người già có hiểu đúng, người trẻ có thấy hấp dẫn, và màn có còn rối text hay không.

## Validation

- [ ] Verify với 3 câu hỏi usability:
  - User có hiểu ngay `hôm nay sức khoẻ ổn hay không` trong 3 giây không?
  - User có bị hiểu sai `điểm thấp = xấu` không?
  - User có hiểu nút `SOS` là hành động khẩn cấp nhưng có bước xác nhận không?
- [ ] Verify visual hierarchy: `Hero` → `Chỉ số` → `Insight banners` → `SOS`.
- [ ] Verify banner `Giấc ngủ` và `Sức khoẻ hôm nay` nhìn vào là phân biệt được ngay chủ đề.
- [ ] Verify toàn màn giảm text nhưng không mất ý nghĩa.

## Open Questions

- Có muốn bỏ hẳn số ở card `Sức khoẻ hôm nay`, chỉ dùng trạng thái bằng lời không?
- Nút `SOS` muốn thiên về `solid red` hay `soft red + outline`?
- Banner `Sức khoẻ hôm nay` muốn mang mood năng lượng buổi sáng hay mood y tế đáng tin cậy?
