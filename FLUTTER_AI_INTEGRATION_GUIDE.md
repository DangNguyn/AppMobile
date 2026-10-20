# Flutter Integration Guide — Hotel Booking API

Tài liệu này hướng dẫn AI và lập trình viên Flutter tích hợp backend hiện có. Nguồn xác minh là `src/app.js`, các router trong `src/routes/`, `src/middleware/auth.js`, `src/config/db.js`, `openapi.yaml` và metadata PostgreSQL đọc từ database cấu hình trong môi trường phát triển. Không có request production nào được chạy khi soạn tài liệu.

## 1. Kiến trúc và trách nhiệm

```text
Flutter screen → Flutter API client/service → HTTPS JSON API → Express routes → PostgreSQL
```

- Flutter quản lý UI, điều hướng, form và trạng thái loading/error/empty/success.
- Express xác thực JWT, kiểm tra quyền sở hữu, kiểm tra input, tính giá đặt phòng và thực hiện cập nhật nghiệp vụ.
- PostgreSQL là nguồn có thẩm quyền cho booking, giá, payment và dữ liệu khách sạn. Flutter không tự đánh dấu booking/payment thành công và không gửi giá cần thu làm nguồn tin.
- Backend hiện có trả ID dưới dạng chuỗi cho các entity booking/hotel/room/payment; `users.id` là UUID. Không ép tất cả ID thành UUID trong Dart.
- Mọi giá trị `numeric` của PostgreSQL có thể được serialize thành JSON number hoặc chuỗi tùy driver/value. Các model nên parse cả `num` lẫn chuỗi số.

## 2. Cấu hình client

Production base URL được cung cấp: `https://hotel-booking-backend-fz9h.onrender.com`. Tài liệu này không xác nhận URL đang hoạt động. Development base URL lấy từ môi trường local của nhóm; không hardcode secret hoặc URL production vào logic domain.

Dùng một HTTP client (Dio hoặc `package:http`) với:

- `Content-Type: application/json` cho JSON body.
- Timeout kết nối/nhận dữ liệu có giới hạn; hiển thị lỗi mạng và cho phép thử lại ở thao tác an toàn.
- JSON decode có kiểm tra kiểu/null; giữ ID ở dạng `String`.
- Gắn `Authorization: Bearer <JWT>` chỉ cho endpoint cần đăng nhập. GET khách sạn, phòng, room type và voucher là public; `GET /api/hotels/{id}/reviews` cho phép gọi không token, nhưng nếu gửi token thì token phải hợp lệ.
- Lưu JWT bằng secure storage. JWT sống 7 ngày. `/api/auth/logout` chỉ trả lời client xóa token, không thu hồi token phía server; xóa token local khi logout và chuyển sang màn hình đăng nhập khi protected API trả `401`.
- Không log password, JWT, PII khách hoặc nội dung nhạy cảm thẻ. Không gửi PAN/CVV/OTP: backend mock payment không cần chúng.

Response thông thường có dạng `{ "success": true, "data": ... }`; một số endpoint auth dùng `{success, token, data}` hoặc `{success, user}`, còn lỗi thường `{success:false,message}`. Đăng ký conflict có thêm `errors`. Không giả định envelope hoàn toàn đồng nhất.

## 3. Endpoint đã xác minh trong source

| Nhóm | API và auth | Service nên có / nơi dùng |
|---|---|---|
| Auth | `POST /api/auth/register` public; `POST /api/auth/login` public; `POST /api/auth/logout` JWT; `GET /api/auth/me` JWT | `AuthService`; form đăng ký/đăng nhập và khởi tạo phiên |
| Profile | `GET /api/users/me`, `PUT /api/users/me` JWT | `ProfileService`; hồ sơ và cập nhật hồ sơ |
| Hotel | `GET /api/hotels`, `GET /api/hotels/{id}`, `GET /api/hotels/{id}/images`, `/amenities`, `/vibes`, `/room-types` public | `HotelService`; danh sách/chi tiết. Ảnh là URL từ endpoint images |
| Hotel review | `GET /api/hotels/{id}/reviews` public hoặc optional JWT; `POST /api/hotels/{id}/reviews` JWT | danh sách/viết đánh giá; review mới yêu cầu booking `completed` hoặc `checked_in` của chính user |
| Room type | `GET /api/room-types/{id}`, `/{id}/images`, `/{id}/rooms` public | chi tiết loại phòng, ảnh, phòng vật lý |
| Room | `GET /api/rooms`, `GET /api/rooms/{id}`, `GET /api/rooms/available` public | tìm phòng theo hotel, loại, status hoặc khoảng ngày |
| Booking | `POST /api/bookings`, `GET /api/bookings`, `GET /api/bookings/{id}`, cancel, check-in, QR, guest/payment subroutes — tất cả JWT | `BookingService`; danh sách và chi tiết chỉ của user hiện tại |
| Guest | `PUT /api/guests/{id}`, `DELETE /api/guests/{id}` JWT; tạo/đọc qua booking subroutes | quản lý khách gắn booking thuộc user |
| Payment | `POST /api/payments`, `GET /api/payments/{id}`, `GET /api/payments/{id}/qr`, `POST /api/payments/{id}/simulate`; và `GET /api/bookings/{id}/payments` — JWT | mock flow; xem phần 6, có blocker schema notification |
| Notification | `GET /api/notifications` JWT trong source | **Có route nhưng chưa tích hợp được đáng tin cậy:** bảng chưa có trong schema đang đọc và tên cột route/migration không khớp |
| Voucher | `GET /api/vouchers`, `GET /api/vouchers/{code}`, `POST /api/vouchers/validate` public | danh sách, chi tiết, xem trước mức giảm |
| Favorite | `GET /api/favorites`, `POST /api/favorites/{hotel_id}`, `DELETE /api/favorites/{hotel_id}` JWT | danh sách/thêm/xóa khách sạn yêu thích |
| Review | `POST /api/reviews`, `PUT /api/reviews/{id}`, `DELETE /api/reviews/{id}` JWT | tạo/sửa/xóa review của user |

Các method, field, validation và HTTP status cụ thể nằm trong [HOTEL_BOOKING_API_DOCUMENT.md](HOTEL_BOOKING_API_DOCUMENT.md). Không có API search/pagination khách sạn; `GET /api/hotels` trả toàn bộ theo `id`.

## 4. Tích hợp màn hình

### Đăng nhập/đăng ký

Gọi auth API. Đăng ký yêu cầu `full_name`, `email`, `phone`, `password`; password tối thiểu 8 ký tự. Đăng nhập dùng email/password. **Cần xử lý blockers trước khi dựa vào auth:** đăng ký bỏ qua `users.id`, nhưng cột UUID này không có default và bảng không có trigger tự tạo ID; login cập nhật `users.last_login_at`, cột này cũng không tồn tại. Cả hai handler có thể trả `500` trên database hiện đang cấu hình; test auth hiện có dùng DB stub và không chứng minh SQL chạy trên database thật.

### Khám phá khách sạn và phòng

`GET /api/hotels` trả thông tin khách sạn cơ bản, không kèm ảnh, tiện nghi, vibe, loại phòng hoặc review. Gọi các endpoint con riêng. `GET /api/rooms/available` cần `hotel_id`, `check_in`, `check_out`, tùy chọn `room_type_id`; kết quả chỉ gồm phòng `active` không overlap booking chưa bị hủy. `check_out` phải sau `check_in`.

Availability dùng quy tắc khoảng ngày nửa mở: phòng bị coi là xung đột khi `existing.check_in < requested.check_out AND existing.check_out > requested.check_in`; vì vậy booking checkout cùng ngày booking mới check-in không overlap. Cả pending, confirmed, checked_in, completed và no_show đều bị loại khỏi availability; chỉ `cancelled` được bỏ qua. Payment failed vẫn để booking pending, do đó booking vẫn chặn phòng. Không có expiry/hold timeout.

API booking kiểm tra overlap lại trong transaction và khóa các row phòng trước khi tạo booking. UI vẫn phải xử lý `409` vì kết quả availability có thể cũ trước lúc submit.

### Tạo booking, danh sách và chi tiết

`POST /api/bookings` gửi hotel, danh sách **room ID vật lý**, ngày và số khách. Backend tính giá từ `room_types.base_price` × số đêm, áp voucher nếu hợp lệ, lưu booking và từng phòng trong `booking_rooms`. Response hiện lưu tổng khách `number_of_guests`; input adults/children không được lưu thành hai trường tách biệt. Thuế được lưu 0 trong route hiện tại.

`GET /api/bookings` chỉ trả booking user hiện tại, có hotel name, rooms (room number/type, giá/đêm, số đêm, subtotal), tiền và payment status/method gần nhất. `GET /api/bookings/{id}` trả booking của user đó cùng phòng; gọi `GET /api/bookings/{id}/guests` và `/payments` nếu cần danh sách riêng. Không có cancellation policy, hotel image hoặc guest name nhúng vào booking history response.

### Mock payment

1. Tạo booking rồi `POST /api/payments` với `booking_id` và `payment_method: card|qr`. Amount lấy từ DB.
2. Với QR, gọi `GET /api/payments/{payment_id}/qr`; Flutter có thể encode `qr_content`. Đây chỉ là chuỗi demo, không phải chuyển khoản.
3. Chỉ backend simulate mới đổi trạng thái. `POST /api/payments/{id}/simulate` nhận `{"result":"success"}` hoặc `{"result":"failed"}` và chỉ hoạt động khi `PAYMENT_MODE=mock`.
4. Success đặt payment `paid`, booking pending thành `confirmed`; failure đặt payment `failed`, booking giữ `pending`. Không gửi thẻ/CVV/OTP.

**Blocker schema:** route thành công còn insert `notifications.message`; migration trong repo tạo `notifications.content`; database đã đọc chưa có bảng `notifications`. Khi route cố insert notification, transaction success rollback và trả 500 cho tới khi backend/schema được đồng bộ. Vì task hiện tại chỉ cho sửa tài liệu, không gọi notification hoặc xác nhận success UI dựa trên response cũ trước khi blocker được xử lý.

### Check-in và QR

`GET /api/bookings/{id}/qr` trả `qr_token`; `POST /api/bookings/{id}/check-in` chỉ thành công nếu booking thuộc user, đã confirmed và ngày check-in bằng ngày hiện tại theo PostgreSQL. QR token không phải bằng chứng payment. API trả 409 khi trạng thái/ngày không đủ điều kiện.

## 5. Model Dart và trạng thái UI

- Parse `success`, envelope theo endpoint, và kiểm tra `data` trước khi map.
- Model `Booking`: `id`, `booking_code`, `hotel_id`, `hotel_name` (history), `check_in/out`, `number_of_guests`, `subtotal`, `tax`, `discount`, `total_amount`, `status`, `rooms`, `payment_status?`, `payment_method?`.
- Model `BookingRoom`: `room_id`, có thể có `room_number`, `room_type` hoặc `room_type_id` tùy endpoint, `price_per_night`, `number_of_nights`, `subtotal`.
- Model `Payment`: `id`, `booking_id`, `payment_method`, `transaction_id`, `amount`, `status`, `paid_at` nullable.
- Trạng thái booking được DB constraint cho phép: `pending`, `confirmed`, `cancelled`, `completed`, `checked_in`, `no_show`. Payment: `pending`, `paid`, `failed`, `refunded`.
- Dùng `DateTime`/ISO date `YYYY-MM-DD`; API không trả timezone cho date-only. Tiền là numeric, không làm tròn bằng floating point nếu dùng cho hiển thị hoặc tính toán tài chính.
- Khi nhận `400`, hiển thị lỗi input; `401`, xóa token và yêu cầu đăng nhập lại; `404`, báo resource không còn/không thuộc user; `409`, thông báo conflict và tải lại trạng thái; `500`/network, hiển thị lỗi chung, không tự suy ra giao dịch thành công.

## 6. Giới hạn và việc cần backend xác nhận

| Hạng mục | Hiện trạng theo source/schema | Ảnh hưởng Flutter |
|---|---|---|
| Login | Source dùng `last_login_at`; cột không có trong metadata DB đang cấu hình | Login thật có khả năng trả 500; cần sửa source hoặc schema rồi kiểm tra integration |
| Register | Source bỏ qua `users.id`; DB không có default/trigger sinh UUID | Insert user có khả năng lỗi NOT NULL và trả 500; cần sửa source hoặc schema rồi kiểm tra |
| Notifications/mock success | Không thấy bảng trong DB; migration tạo `content`, route dùng `message`; migration chưa được chứng minh đã chạy | Transaction success hiện không thể được coi là usable end-to-end |
| API availability | Có `GET /api/rooms/available` và kiểm tra overlap trong tạo booking | Có thể tích hợp; không có hold expiry, pending/failed vẫn chiếm lịch |
| Booking history/detail | Có, auth và lọc theo `req.user.id` | Tích hợp được theo response thực tế đã nêu |
| Token revocation/refresh | Không có; logout chỉ hướng dẫn xóa local JWT | Không có refresh token; token còn hiệu lực tới expiry |
| Push notification | Không có cấu hình/service FCM trong source được kiểm tra | Chỉ có ý tưởng lưu notification; push chưa triển khai |
| Production | Chưa gọi production URL trong lần rà soát này | Kiểm thử mutation bằng staging/test account trước khi phát hành |

Backend PostgreSQL config đọc tên biến `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` và bật SSL với `rejectUnauthorized:false`; JWT middleware cần `JWT_SECRET`. Giá trị secret không được ghi trong tài liệu. Mock simulate cần `PAYMENT_MODE=mock`.

## 7. Tài liệu nguồn

- [API reference](HOTEL_BOOKING_API_DOCUMENT.md)
- [Flutter implementation prompt](IMPLEMENT_FLUTTER_API_PROMPT.md)
- [OpenAPI](openapi.yaml)
- Source: `src/app.js`, `src/routes/`, `src/middleware/auth.js`, `src/config/db.js`
- SQL migration đang có: `migrations/001_create_notifications.sql` (chưa áp dụng/xác minh trong database)
