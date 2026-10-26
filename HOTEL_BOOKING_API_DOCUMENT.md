# Hotel Booking REST API

> API contract tổng hợp trực tiếp từ `src/app.js`, `src/routes/`, middleware và email service. Route có trong source không đồng nghĩa route đã chạy thành công với database. Không có request production nào được thực hiện.

## 1. Quy ước chung

- Base URL production do dự án cung cấp: `https://hotel-booking-backend-fz9h.onrender.com`; chưa xác minh khả dụng. Các route API dùng prefix `/api`, trừ `GET /`.
- Body JSON dùng `Content-Type: application/json`. Express nhận JSON tối đa 1 MB và cũng bật URL encoded.
- JWT gửi bằng `Authorization: Bearer <JWT>`. `requireAuth` lấy `req.user.id` từ JWT; token được ký bằng `JWT_SECRET`, thời hạn 7 ngày. Logout không thu hồi token; ứng dụng cần xóa token cục bộ. `optionalAuth` cho phép thiếu token, nhưng nếu gửi token không hợp lệ thì trả 401.
- ID user là UUID; nhiều ID nghiệp vụ khác là chuỗi. PostgreSQL `numeric` thường được `pg` trả về dạng chuỗi.
- Lỗi thường có dạng `{ "success": false, "message": "..." }`. Không có mã lỗi ứng dụng thống nhất.

## 2. Endpoint catalog theo source

| Method | Endpoint | Auth | Request | Response / lỗi chính |
|---|---|---|---|---|
| GET | `/` | Public | — | 200 `{success,message}` |
| GET | `/api/test-db` | Public | — | 200 `{success,data:{current_time}}`; 500 DB |
| POST | `/api/auth/register` | Public | `full_name,email,phone,password` | 201 `{success,message,user}`; 400 validation; 409 email/phone trùng; 500 DB |
| POST | `/api/auth/login` | Public | `email,password` | 200 `{success,token,data:user}`; 400 body; 401 sai credentials; 500 DB/config |
| POST | `/api/auth/logout` | JWT | — | 200 message; không revoke JWT |
| GET | `/api/auth/me` | JWT | — | 200 profile; 404 user; 500 DB |
| GET | `/api/users/me` | JWT | — | 200 profile; 404 user; 500 DB |
| GET | `/api/users/search` | JWT | query `q` | 200 `{success:true,data:[{id,full_name,avatar}]}` (tối đa 20, không gồm user hiện tại); 400 thiếu từ khóa; 401; 500 DB |
| PUT | `/api/users/me` | JWT | `full_name?`, `phone?`, `avatar?`, `is_private?` | 200 profile; 400 field lạ/kiểu sai; 404 user; 500 DB |
| GET | `/api/posts` | Optional JWT | `page?`, `limit?` | 200 published posts + pagination; không gồm bài của tài khoản private khác; 400 phân trang; 500 DB |
| GET | `/api/posts/search` | Optional JWT | `q,page?,limit?` | 200 bài khớp title/location/content, lọc tài khoản private; 400 từ khóa/phân trang; 500 DB |
| GET | `/api/posts/{id}` | Optional JWT | path UUID | 200 bài published nếu tác giả public hoặc là chính user; 400 UUID sai; 404; 500 DB |
| GET | `/api/posts/users/{userId}` | Optional JWT | path UUID; `page?,limit?` | 200 bài published; tài khoản private chỉ thấy chính chủ; 400; 404 user; 500 DB |
| GET | `/api/posts/mine` | JWT | `page?,limit?` | 200 bài của user hiện tại (kể cả đã xóa mềm); 400; 401; 500 DB |
| POST | `/api/posts` | JWT | `title,location,rating,content` | 201 bài mới; 400 validation; 401; 404 user; 500 DB |
| PUT | `/api/posts/{id}` | JWT | một hoặc nhiều `title,location,rating,content` | 200 bài cập nhật; 400; 401; 404 không tồn tại/không thuộc user; 500 DB |
| DELETE | `/api/posts/{id}` | JWT | path UUID | 200 xóa mềm (`status=deleted`); 400 UUID sai; 401; 404 không thuộc user/không có; 500 DB |
| GET | `/api/posts/{id}/comments` | Optional JWT | `page?`, `limit?` | 200 bình luận nếu xem được bài; 400; 404 bài không tồn tại/không published/riêng tư; 500 DB |
| POST | `/api/posts/{id}/comments` | JWT | `content` | 201 bình luận; 400 validation; 401; 404 bài; 500 DB |
| DELETE | `/api/posts/{id}/comments/{commentId}` | JWT | UUIDs | 200; 400 UUID sai; 401; 404 không thuộc user/không có; 500 DB |
| GET | `/api/hotels` | Public | — | 200 hotel array; 500 DB |
| GET | `/api/hotels/{id}` | Public | path `id` | 200 hotel; 404; 500 DB |
| GET | `/api/hotels/{id}/images` | Public | path `id` | 200 image array; 500 DB |
| GET | `/api/hotels/{id}/amenities` | Public | path `id` | 200 array; 500 DB |
| GET | `/api/hotels/{id}/vibes` | Public | path `id` | 200 array; 500 DB |
| GET | `/api/hotels/{id}/room-types` | Public | path `id` | 200 room type array; 500 DB |
| GET | `/api/hotels/{id}/reviews` | Optional JWT | path `id` | 200 review array; 401 invalid supplied token; 500 DB |
| POST | `/api/hotels/{id}/reviews` | JWT | `booking_id,rating,comment?` | 201 review; 400 input; 403 booking không đủ điều kiện; 409 review trùng booking; 500 DB |
| GET | `/api/room-types/{id}` | Public | path `id` | 200 room type; 404; 500 DB |
| GET | `/api/room-types/{id}/images` | Public | path `id` | 200 image array; 500 DB |
| GET | `/api/room-types/{id}/rooms` | Public | path `id` | 200 physical room array; 500 DB |
| GET | `/api/rooms` | Public | query `hotel_id?`, `room_type_id?`, `status?` | 200 room array; 500 DB |
| GET | `/api/rooms/{id}` | Public | path `id` | 200 room; 404; 500 DB |
| GET | `/api/rooms/available` | Public | `hotel_id,check_in,check_out,room_type_id?` | 200 `{success:true,data:[...]}` (có thể là mảng rỗng); 400 thiếu hotel/ngày sai; 500 DB |
| POST | `/api/bookings` | JWT | booking body ở mục 3 | 201 booking; 400 validation/phòng/voucher; 401; 404 FK; 409 phòng đã được đặt hoặc trạng thái conflict; 500 DB |
| GET | `/api/bookings` | JWT | — | 200 owned booking history; 500 DB |
| GET | `/api/bookings/{id}` | JWT | path `id` | 200 owned booking; 404; 500 DB |
| PATCH | `/api/bookings/{id}/cancel` | JWT | — | 200 `{id,status}`; 404; 409 trạng thái không cho hủy; 500 DB |
| POST | `/api/bookings/{id}/check-in` | JWT | — | 200 `{id,status,checked_in_at}`; 404; 409 trạng thái/ngày không hợp lệ; 500 DB |
| GET | `/api/bookings/{id}/qr` | JWT | path `id` | 200 booking QR data; 404; 500 DB |
| GET | `/api/bookings/{id}/guests` | JWT | path `id` | 200 guest array; 404 booking không thuộc user; 500 DB |
| POST | `/api/bookings/{id}/guests` | JWT | `full_name,phone?,email?,identification_info?` | 201 guest; 400 thiếu tên; 404 booking không thuộc user; 500 DB |
| GET | `/api/bookings/{id}/payments` | JWT | path `id` | 200 payment array; 404 booking không thuộc user; 500 DB |
| PUT | `/api/guests/{id}` | JWT | guest fields tùy chọn | 200 `{success,message,data}`; 404 guest không thuộc booking của user; 500 DB |
| DELETE | `/api/guests/{id}` | JWT | path `id` | 200 message; 404 guest không thuộc booking của user; 500 DB |
| POST | `/api/payments` | JWT | `booking_id,payment_method` (`card`/`qr`) | 201 pending payment mới; 200 trả lại payment pending hiện có (`reused:true`); 400 input; 404 booking; 409 booking đã trả/không hợp lệ; 500 DB |
| GET | `/api/payments/{id}` | JWT | path `id` | 200 owned payment; 404; 500 DB |
| GET | `/api/payments/{id}/qr` | JWT | path `id` | 200 QR text, chỉ payment method `qr`; 404; 409 method khác; 500 DB |
| POST | `/api/payments/{id}/simulate` | JWT + `PAYMENT_MODE=mock` | `result: "success"\|"failed"` | 200 payment + `email.status`; gọi lại payment `paid` với `success` chỉ retry email nếu lần trước `failed`; 400 input; 403 mock disabled; 404 payment; 409 already completed/ineligible; 500 transaction/DB |
| GET | `/api/notifications` | JWT | — | Source trả notification array; 500 DB/schema mismatch có thể xảy ra |
| GET | `/api/vouchers` | Public | — | 200 voucher active và còn hạn; 500 DB |
| GET | `/api/vouchers/{code}` | Public | path `code` | 200 voucher kể cả inactive/expired; 404; 500 DB |
| POST | `/api/vouchers/validate` | Public | `code,subtotal` | 200 voucher/discount/total; 400 invalid/inactive/minimum; 404; 500 DB |
| GET | `/api/favorites` | JWT | — | 200 current user's hotel favorites; 500 DB |
| POST | `/api/favorites/{hotel_id}` | JWT | path `hotel_id` | 201 favorite; 404 hotel; 409 đã favorite; 500 DB |
| DELETE | `/api/favorites/{hotel_id}` | JWT | path `hotel_id` | 200 message; 404; 500 DB |
| POST | `/api/reviews` | JWT | `hotel_id,booking_id,rating,comment?` | 201 review; 400 input; 403 booking không đủ điều kiện; 404 FK; 409 trùng booking; 500 DB |
| PUT | `/api/reviews/{id}` | JWT | `rating?`, `comment?` (ít nhất một) | 200 review; 400 input; 404 không thuộc user/không có; 500 DB |
| DELETE | `/api/reviews/{id}` | JWT | path `id` | 200 message; 404 không thuộc user/không có; 500 DB |

Các route bài viết được mount tại `/api/posts`. Chưa có upload ảnh; API chỉ trả metadata hiện có trong `post_images` (`storage_key`, MIME, dung lượng, thứ tự). Không có profile người khác, refresh token, hay FCM trong source được mount.

## 3. Chi tiết request/response

### Đăng ký, đăng nhập và profile

`POST /api/auth/register` yêu cầu cả bốn trường chuỗi `full_name,email,phone,password`; email chuẩn hóa lowercase/trim, password tối thiểu 8 ký tự. Trả `201 {success:true,message,user:{id,email,full_name,phone,avatar,created_at}}`. Email hoặc phone đã dùng trả 409 và có thể kèm `errors` theo field. Source insert không truyền `users.id`; metadata DB đã kiểm tra trước đây cho thấy cột này không có default. Vì vậy response 201 là response dự kiến theo source, không phải đảm bảo đăng ký chạy với mọi DB.

`POST /api/auth/login` nhận `{email,password}` và dự kiến trả `200 {success:true,token,data:user}` với JWT 7 ngày. Sai credentials `401`; body thiếu/không hợp lệ `400`. Handler cập nhật `users.last_login_at`; metadata DB đã kiểm tra trước đây không có cột này, nên login có thể trả 500 cho database đó.

`GET /api/auth/me` trả profile xác thực; `GET /api/users/me` bao gồm `is_private`. `PUT /api/users/me` nhận `full_name`, `phone`, `avatar`, `is_private`; `is_private` phải là boolean. Giá trị null/thiếu được giữ nguyên bởi `COALESCE`, không dùng để xóa giá trị hiện tại. Cột `is_private` yêu cầu chạy migration `005_add_user_privacy.sql` thủ công trước khi dùng phiên bản API mới.

`GET /api/users/search?q=nam` yêu cầu JWT và tìm theo `full_name` không phân biệt hoa thường (`ILIKE`). Từ khóa được trim; thiếu hoặc rỗng trả `400 {success:false,message:"Vui lòng nhập từ khóa tìm kiếm."}`. Thành công trả `200 {success:true,data:[{id,full_name,avatar}]}` với tối đa 20 kết quả, không gồm tài khoản hiện tại. Kết quả chỉ chứa `id`, `full_name`, `avatar`; không trả email, phone, password hash hoặc dữ liệu booking.

### Bài viết và bình luận

Các bài viết dùng bảng `posts` hiện có (`id/user_id` UUID). `POST /api/posts` yêu cầu JWT và body `{title,location,rating,content}`; title/location tối đa 200 ký tự, content tối đa 10.000 ký tự, rating là số nguyên 1–5. `PUT /api/posts/{id}` cập nhật một hoặc nhiều field này. Chỉ tác giả sửa/xóa được bài; bài đã xóa không thể sửa lại qua API. `DELETE` là xóa mềm bằng `status='deleted'`, khớp enum/check constraint hiện hữu và không xóa dữ liệu.

Feed, tìm kiếm, chi tiết, bình luận và danh sách theo user chỉ trả nội dung `published` của tài khoản `active`. Với tài khoản có `is_private=true`, chỉ chính chủ (gửi JWT hợp lệ) xem được bài và bình luận; quyền được kiểm tra ở backend. GET public hỗ trợ JWT tùy chọn để chủ tài khoản vẫn xem nội dung của mình. Kết quả mặc định sắp xếp mới nhất trước. Danh sách hỗ trợ `page` mặc định 1 và `limit` mặc định 20 (tối đa 50), trả `pagination:{page,limit,total,pages}`. Chi tiết bài và danh sách kèm `author_name`, `author_avatar` và `images`; `images` là metadata từ `post_images`, không phải URL tải ảnh.

Migration `004_create_post_comments.sql` thêm `post_comments` liên kết UUID tới `posts` và `users`, với cascade khi bản ghi cha bị xóa vật lý. Chạy migration này trên database trước khi dùng API bình luận; migration không tự chạy khi khởi động server. `POST /api/posts/{id}/comments` yêu cầu JWT và `{content}` (1–2.000 ký tự). Danh sách bình luận công khai, phân trang mới nhất trước. `DELETE /api/posts/{id}/comments/{commentId}` chỉ xóa bình luận của user hiện tại. Trả 404 nếu bình luận không tồn tại hoặc không thuộc user để tránh tiết lộ quyền sở hữu.

### Khách sạn, phòng và ảnh catalog

Hotel fields: `id,name,description,address,city,latitude,longitude,star_rating,created_at`. Hotel image: `id,hotel_id,image_url,ordering`. Amenities/vibes trả các trường `id,name,description`. Room type: `id,hotel_id,name,description,max_guests,base_price`. Room: `id,hotel_id,room_type_id,room_number,status`. Các API ảnh chỉ đọc URL ảnh catalog; không có API upload.

`GET /api/rooms/available` là endpoint availability được mount tại `/api/rooms` trong `src/app.js`. Gọi bằng query `hotel_id`, `check_in`, `check_out`; `room_type_id` là tùy chọn. Ví dụ:

```http
GET /api/rooms/available?hotel_id=<hotel-id>&check_in=2030-05-10&check_out=2030-05-12&room_type_id=<room-type-id>
```

Ngày dùng `YYYY-MM-DD`; checkout phải sau checkin. Thành công trả HTTP 200 với `{ "success": true, "data": [...] }`; `data` là danh sách phòng vật lý có `status='active'` và không bị booking trùng ngày chiếm. Mảng rỗng cũng là HTTP 200 và hiện không có `message` bổ sung. Endpoint lọc theo loại phòng, không nhận `room_id` và không trả số lượng inventory theo loại phòng. Lỗi input trả HTTP 400 `{success:false,message}`; lỗi DB trả HTTP 500. Không có endpoint `/api/rooms/availability` trong source hiện tại.

### Đặt phòng

`POST /api/bookings` yêu cầu JWT và body:

```json
{
  "hotel_id": "<hotel-id>",
  "room_ids": ["<room-id>"],
  "check_in": "2030-05-10",
  "check_out": "2030-05-12",
  "adults": 2,
  "children": 0,
  "voucher_code": "<optional-code>",
  "booking_email": "guest@example.com"
}
```

`booking_email` là bắt buộc, được trim/lowercase, kiểm tra định dạng và lưu riêng trên booking. Đây là email nhận xác nhận, độc lập với `user_id` và email tài khoản. Server kiểm tra phòng thuộc hotel, active, capacity, overlap và voucher; tính giá, tax hiện là 0. Success trả `201 {success:true,data:{id,booking_code,user_id,hotel_id,voucher_id,check_in,check_out,number_of_guests,subtotal,tax,discount,total_amount,status,qr_token,booking_email,created_at,rooms:[{room_id,price_per_night,number_of_nights,subtotal}]}}`; trạng thái đầu `pending`.

Route ghi `booking_email`; migration `migrations/002_add_booking_email.sql` đã thêm cột này trước đây. `migrations/003_payment_email_deliveries.sql` cũng bảo đảm cột tồn tại khi nâng cấp.

Phòng được kiểm tra lại trong transaction tạo booking: backend khóa các dòng `rooms` được chọn theo thứ tự ID (`FOR UPDATE`), rồi kiểm tra booking giao nhau trước khi insert. Nếu phòng đã được đặt, API trả HTTP 409 với `{success:false,message:"One or more rooms are already booked for these dates"}`. Vì vậy client cần xử lý cả trường hợp phòng vừa hết chỗ sau lần truy vấn availability.

`GET /api/bookings` trả lịch sử của user hiện tại gồm hotel name, dates, totals/status, rooms và `payment_status/payment_method` mới nhất. `GET /api/bookings/{id}` trả chi tiết owned booking cùng room list. Các route con guests/payments cũng giới hạn theo owner.

Availability dùng khoảng `[check_in, check_out)`: booking giao nhau khi `existing.check_in < requested.check_out` và `existing.check_out > requested.check_in`. Source hiện loại trừ `cancelled`; các trạng thái khác, gồm `pending` (kể cả payment failed), vẫn được tính là đang chiếm phòng và không có expiry tự động. Đây là danh sách phòng vật lý, không phải tồn kho theo loại phòng.

### Thanh toán, email và notification

`POST /api/payments` nhận `{booking_id,payment_method}` (`card` hoặc `qr`); amount lấy từ booking, client amount bị bỏ qua. Tạo payment `pending`, không phải charge thật. Nếu booking đã có payment pending, API trả payment đó với HTTP 200 và `reused:true` để client tiếp tục bằng đúng payment ID. Từ chối nếu booking đã paid.

`GET /api/payments/{id}/qr` trả `payment_id,booking_id,booking_code,amount,payment_status,qr_content`. Đây là text demo, không phải hướng dẫn chuyển khoản thật. QR scan không cập nhật payment.

`POST /api/payments/{id}/simulate` chỉ hoạt động khi `PAYMENT_MODE=mock`. Với `result="success"`, source cập nhật payment thành `paid` và booking pending thành `confirmed`, rồi COMMIT. Sau commit, hệ thống tạo email tracking và gửi độc lập; lỗi tracking/email không rollback payment. Người nhận chỉ lấy từ `bookings.booking_email` đã lưu, không dùng email tài khoản hoặc dữ liệu gửi lại trong request; tên phòng được lấy từ `booking_rooms`/`rooms`/`room_types`. Response có dạng:

```json
{
  "success": true,
  "data": { "id": "<payment-id>", "booking_id": "<booking-id>", "payment_method": "card", "transaction_id": "<transaction-id>", "amount": "2500.00", "status": "paid", "paid_at": "<timestamp>", "email_status": "sent" },
  "email": { "status": "sent", "delivery_status": "unconfirmed", "message": "Brevo accepted the email request; delivery is not confirmed" },
  "email_status": "sent"
}
```

`GET /api/payments/{id}` cũng trả `email.status` và `email_status` để client vẫn hiển thị kết quả sau khi tải lại chi tiết payment. `email_status` có thể là `not_applicable` khi chưa paid hoặc `not_tracked` nếu thiếu dữ liệu tracking.

Email tiếng Việt có tiêu đề `Xác nhận thanh toán - <mã booking>`, lời chào tên khách lấy từ `users.full_name`, khách sạn, loại phòng, ngày nhận/trả phòng, tổng tiền và trạng thái. `email.status` có thể là `sent`, `failed`, `sending`, `not_tracked`, hoặc `not_applicable`. `sent` nghĩa Brevo API đã chấp nhận yêu cầu gửi; chưa xác nhận email đã được giao. Response có `delivery_status: "unconfirmed"`; webhook theo dõi giao thư chưa được triển khai. Lỗi gửi không rollback payment; mã lỗi được lưu và ghi log. Gọi lại endpoint với `result="success"` chỉ thử gửi lại khi trạng thái hiện tại là `failed`; trạng thái `sent` không gửi lặp. Với `result="failed"`, payment thành `failed` và không gửi email. Hiện source chỉ có mock simulate flow, không thấy webhook/callback của cổng thanh toán thật.

Migration `003_payment_email_deliveries.sql` thêm `bookings.booking_email` nếu còn thiếu và bảng theo dõi trạng thái gửi email. Người dùng đã xác nhận chạy migration thành công trên database được chọn trong SQL client; chưa xác minh database đó có phải database Render mà backend đang dùng hay không.

Email dùng Brevo Transactional Email API qua HTTPS. Cấu hình backend bằng `EMAIL_PROVIDER=brevo`, `BREVO_API_KEY`, `BREVO_SENDER_EMAIL`, `BREVO_SENDER_NAME`; `BREVO_TIMEOUT_MS` tùy chọn, mặc định 10000 ms. Sender phải được xác minh trong Brevo. Không đưa API key vào Flutter.

**Schema cần lưu ý:** catalog PostgreSQL từ môi trường làm việc không truy cập được. Người dùng xác nhận migration `003` chạy thành công trong SQL client; cần xác minh đó là cùng database mà backend đang dùng. Nếu bảng tracking chưa có ở database backend, payment vẫn được commit thành `paid`, nhưng response báo `email.status: "not_tracked"` và email chưa được xử lý. Migration `001_create_notifications.sql` định nghĩa `content`; route GET giữ response field `message` bằng cách select `content AS message`.

### Guests, favorites, vouchers, reviews

Guest create body `full_name` bắt buộc, các trường còn lại tùy chọn; sửa guest nhận các trường tùy chọn và `COALESCE` giữ giá trị cũ khi null. Chỉ thao tác guest gắn với booking hiện tại của JWT user.

Voucher validate nhận `{code,subtotal}`; discount phần trăm nếu `discount_type="percent"`, ngược lại là giá trị cố định, không vượt subtotal. Endpoint này chỉ preview; booking validate lại.

Review là đánh giá hotel có chứng minh booking. `rating` từ 1–5; booking phải thuộc user và đúng hotel, đồng thời đã `checked_in`/`completed`, hoặc đang `confirmed` nhưng ngày checkout đã qua. DB có unique review theo `booking_id`. `comment` có thể null. `PUT /api/reviews/{id}` không xóa comment bằng null vì dùng `COALESCE`.

## 4. Các lỗi và giới hạn đã biết

- `400`: validation/body, ngày, phòng/voucher không hợp lệ; JSON parse lỗi toàn app trả `Invalid JSON request body`.
- `401`: thiếu/sai/hết hạn JWT; login sai credentials. `requireAuth` trả 500 nếu thiếu `JWT_SECRET`.
- `403`: mock mode tắt hoặc booking không đủ điều kiện review/payment.
- `404`: tài nguyên không có/không thuộc user/FK target không tồn tại.
- `409`: booking/payment state conflict, trùng favorite/review, phòng bị đặt.
- `500`: lỗi DB hoặc handler; không có error code ứng dụng ổn định.
- Availability trả `200` với `data: []` khi không còn phòng phù hợp; đây không phải lỗi mạng/server. Booking có thể trả `409` nếu phòng bị đặt sau lần availability trước đó.

Database metadata được đọc ở local trước đây, không phải production. Route source và migration không chứng minh production schema đã áp dụng. Không có production request hoặc end-to-end test trong lần cập nhật tài liệu này.

## 5. Cấu hình và file liên quan

- DB: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.
- Auth: `JWT_SECRET`.
- Demo payment: `PAYMENT_MODE=mock`.
- Email: `EMAIL_PROVIDER=brevo`, `BREVO_API_KEY`, `BREVO_SENDER_EMAIL`, `BREVO_SENDER_NAME`, `BREVO_TIMEOUT_MS` (optional).
- Source: `src/app.js`, `src/routes/*.js`, `src/middleware/auth.js`, `src/services/paymentEmailService.js`.
- Migrations liên quan: `migrations/001_create_notifications.sql`, `migrations/002_add_booking_email.sql`, `migrations/003_payment_email_deliveries.sql`.
- Related docs: `FLUTTER_AI_INTEGRATION_GUIDE.md`, `IMPLEMENT_FLUTTER_API_PROMPT.md`, `openapi.yaml`.
