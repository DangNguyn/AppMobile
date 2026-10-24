# Flutter Integration Guide — Hotel Booking API

Tài liệu này mô tả contract theo router được mount ở `src/app.js`, handler hiện có, JWT middleware và email service. Không phải xác nhận production đang hoạt động. Base URL production do dự án cung cấp là `https://hotel-booking-backend-fz9h.onrender.com`; cần kiểm tra cấu hình môi trường trước khi dùng.

## Quy tắc tích hợp

- JSON request dùng `Content-Type: application/json`; Express JSON limit 1 MB.
- JWT gửi `Authorization: Bearer <token>` cho route bảo vệ. Token chứa `id`, hết hạn sau 7 ngày. Logout chỉ trả lời client xóa token; không thu hồi token ở server.
- `optionalAuth` cho phép gọi không token; nếu gửi token hỏng thì nhận 401.
- Giữ ID user ở dạng UUID và các ID hotel/room/booking/payment dưới dạng chuỗi. Giá PostgreSQL `numeric` có thể về JSON dưới dạng chuỗi; ngày dùng `YYYY-MM-DD`.
- API bài viết có pagination; chưa có API upload ảnh. `post_images` chỉ cung cấp metadata `storage_key`, không phải URL tải ảnh.

## Endpoint theo nhóm

| Nhóm | API thực tế và auth |
|---|---|
| Health | `GET /`, `GET /api/test-db` (public) |
| Auth | `POST /api/auth/register`, `POST /api/auth/login` (public); `POST /api/auth/logout`, `GET /api/auth/me` (JWT) |
| Profile | `GET /api/users/me`, `PUT /api/users/me` (JWT; PUT chỉ `full_name`, `phone`, `avatar`) |
| Hotels | `GET /api/hotels`, `GET /api/hotels/{id}`, `/images`, `/amenities`, `/vibes`, `/room-types` (public); `GET /api/hotels/{id}/reviews` optional JWT; `POST /api/hotels/{id}/reviews` JWT |
| Room types | `GET /api/room-types/{id}`, `/{id}/images`, `/{id}/rooms` (public) |
| Rooms | `GET /api/rooms`, `GET /api/rooms/{id}`, `GET /api/rooms/available` (public) |
| Bookings | `POST /api/bookings`, `GET /api/bookings`, `GET /api/bookings/{id}`, `PATCH /api/bookings/{id}/cancel`, `POST /api/bookings/{id}/check-in`, `GET /api/bookings/{id}/qr`, `GET/POST /api/bookings/{id}/guests`, `GET /api/bookings/{id}/payments` (JWT) |
| Guests | `PUT /api/guests/{id}`, `DELETE /api/guests/{id}` (JWT) |
| Payments | `POST /api/payments`, `GET /api/payments/{id}`, `GET /api/payments/{id}/qr`, `POST /api/payments/{id}/simulate` (JWT; simulate ayrıca `PAYMENT_MODE=mock`) |
| Notifications | `GET /api/notifications` (JWT) |
| Vouchers | `GET /api/vouchers`, `GET /api/vouchers/{code}`, `POST /api/vouchers/validate` (public) |
| Favorites | `GET /api/favorites`, `POST /api/favorites/{hotel_id}`, `DELETE /api/favorites/{hotel_id}` (JWT) |
| Reviews | `POST /api/reviews`, `PUT /api/reviews/{id}`, `DELETE /api/reviews/{id}` (JWT) |
| Posts | `GET /api/posts`, `GET /api/posts/search`, `GET /api/posts/{id}`, `GET /api/posts/users/{userId}`, `GET /api/posts/{id}/comments` (public); `GET /api/posts/mine`, `POST/PUT/DELETE /api/posts`, `POST /api/posts/{id}/comments`, `DELETE /api/posts/{id}/comments/{commentId}` (JWT; mutation chỉ trên nội dung của user hiện tại) |

Chi tiết field/response của mọi route nằm trong [API reference](HOTEL_BOOKING_API_DOCUMENT.md). Route catalog phản ánh source; schema có thể làm route trả lỗi runtime.

## Bài viết và bình luận

- Tạo bài: `POST /api/posts` với `{ "title": "Một chuyến đi", "location": "Đà Lạt", "rating": 5, "content": "..." }`. Gửi JWT. Sửa dùng `PUT /api/posts/{id}` với ít nhất một field. Xóa dùng `DELETE`; đây là xóa mềm.
- Khám phá: `GET /api/posts?page=1&limit=20`; tìm: `GET /api/posts/search?q=Đà%20Lạt&page=1&limit=20`; chi tiết: `GET /api/posts/{id}`; bài của user khác: `GET /api/posts/users/{userId}`. Các route này chỉ hiện bài published.
- Đọc bình luận: `GET /api/posts/{id}/comments?page=1&limit=20`. Tạo bình luận: `POST /api/posts/{id}/comments` với `{ "content": "..." }` và JWT. Xóa bình luận của chính mình: `DELETE /api/posts/{id}/comments/{commentId}` và JWT.
- `page` bắt đầu từ 1; `limit` tối đa 50. Response danh sách có `data` và `pagination` (`page`, `limit`, `total`, `pages`). Tác vụ sửa/xóa sai chủ sở hữu trả 404. Bình luận yêu cầu migration `004_create_post_comments.sql` đã được áp dụng thủ công trước khi dùng.

## Luồng sử dụng

1. **Đăng ký/đăng nhập:** register body gồm `full_name,email,phone,password`; password tối thiểu 8 ký tự. Login nhận `email,password`. JWT có thời hạn 7 ngày.
2. **Khám phá và availability:** gọi đúng endpoint `GET /api/rooms/available?hotel_id=...&check_in=YYYY-MM-DD&check_out=YYYY-MM-DD&room_type_id=...`; `room_type_id` có thể bỏ. Đọc danh sách từ `response.data`. `data: []` với HTTP 200 nghĩa là hiện không có phòng phù hợp; endpoint trả các phòng vật lý, không phải số lượng tồn theo room type.
3. **Tạo booking:** `POST /api/bookings` cần `hotel_id,room_ids,check_in,check_out,adults,booking_email`; `children` mặc định 0, `voucher_code` tùy chọn. `room_ids` là ID phòng vật lý. Backend kiểm tra định dạng email và lưu riêng trong `bookings.booking_email`, không thay `user_id`; tax hiện bằng 0.
4. **Thanh toán demo:** `POST /api/payments` nhận `booking_id,payment_method` (`card`/`qr`); không gửi dữ liệu thẻ. Nếu đã có payment pending, API trả lại payment đó với HTTP 200 và `reused:true`; client cần tiếp tục bằng `data.id` này. QR endpoint chỉ trả text demo, scan QR không xác nhận thanh toán. Simulate chỉ dùng trên môi trường demo khi server bật `PAYMENT_MODE=mock`.
5. **Email thanh toán:** khi `POST /api/payments/{id}/simulate` với `result:"success"` payment và booking được commit lần lượt thành `paid`/`confirmed`; sau commit backend gửi email FomoGO đến email đã lưu trên booking. Không fallback sang `users.email` và không nhận recipient từ request thanh toán. Email lỗi không rollback payment. Response có `email.status`: `sent`, `failed`, `sending`, `not_tracked`, hoặc `not_applicable`. `sent` nghĩa SMTP đã chấp nhận người nhận. Gọi lại sau khi đã paid chỉ thử gửi lại nếu lần trước thất bại; email đã `sent` không gửi lặp. Source hiện không có callback từ cổng thanh toán thật.
6. **Booking của tôi:** `/api/bookings` chỉ trả booking của JWT user. History có hotel name, room list, totals/status và payment summary; không nhúng guest names hoặc hotel image. Dùng subroutes guest/payment khi cần.
7. **Check-in:** booking QR/token không phải xác nhận payment. Check-in chỉ thành công với booking confirmed đúng ngày nhận phòng.

## Trạng thái và lỗi cần xử lý

- Availability dùng khoảng `[check_in,check_out)`: hai khoảng giao nhau nếu ngày nhận hiện có trước ngày trả khách chọn và ngày trả hiện có sau ngày nhận khách chọn. Booking `cancelled` không chiếm phòng; các trạng thái khác, gồm `pending` hoặc payment `failed`, vẫn chiếm phòng theo source hiện tại.
- Availability trả `400` nếu thiếu `hotel_id` hoặc khoảng ngày không hợp lệ, `200` với `data: []` nếu không có phòng, và `500` khi truy vấn DB lỗi. Khi gửi tạo booking, server kiểm tra lại trong transaction và khóa các phòng đã chọn; nếu vừa có khách khác đặt trước, API trả `409` với message phòng đã được đặt. Hãy đọc `message` từ body lỗi và cung cấp thông báo kết nối riêng khi không nhận được HTTP response. Error body hiện không có `code` chuẩn hóa.
- Ngày phải ở dạng `YYYY-MM-DD`, checkout sau checkin. Booking không kiểm tra DNS email; email chỉ được kiểm tra định dạng.
- Review chỉ tạo được cho booking thuộc user, cùng hotel, trạng thái `completed` hoặc `checked_in`; rating 1–5. Review này khác bài viết trải nghiệm.

## Blocker và điều chưa xác minh

- Metadata local đã đọc trước đây cho thấy `users.id` UUID không có default, nhưng register source không truyền `id`; login source cập nhật `users.last_login_at` trong khi metadata đó không có cột này. Hai luồng auth chưa được xác nhận chạy với schema local đó.
- `POST /api/bookings` ghi `bookings.booking_email`; migration `002_add_booking_email.sql` tạo cột. Email payment cần migration `003_payment_email_deliveries.sql` để theo dõi trạng thái gửi và retry lỗi. Các migration này chưa được xác nhận áp dụng ở production.
- Payment success ghi `notifications.content` sau commit; migration `001_create_notifications.sql` tạo bảng/cột này. Metadata local đọc gần nhất không có bảng notifications; khi chưa tạo, notification bị bỏ qua sau log nhưng payment vẫn paid và email vẫn được thử gửi.
- `GET /api/notifications` trả key `message` bằng alias từ cột database `content`, khớp migration hiện tại. Route vẫn cần bảng notifications tồn tại để hoạt động.
- Kết nối PostgreSQL cấu hình trong môi trường làm việc không thành công khi đọc catalog; production schema và SMTP chưa được xác minh. SMTP credentials không đưa vào Flutter.

Các blockers trên dựa trên source và metadata local đã đọc; không khẳng định schema production giống local. Xem [API reference](HOTEL_BOOKING_API_DOCUMENT.md) để biết response và lỗi chi tiết. Không tự thêm endpoint hoặc field không có trong backend.
