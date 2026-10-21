# Hướng dẫn từng bước cho người làm Backend/API

## Mục tiêu cuối cùng

Khi thanh toán đã được backend xác nhận thành công (`payment.status = paid`), hệ thống gửi email đến:

```text
nguyenly.31241023382@st.ueh.edu.vn
```

Luồng cần đạt:

```text
Ứng dụng Flutter
    ↓
Backend tạo payment
    ↓
Backend xác nhận payment = paid
    ↓
Backend gửi email qua Gmail SMTP
    ↓
nguyenly.31241023382@st.ueh.edu.vn nhận email
```

**Không gửi email khi người dùng chỉ bấm nút thanh toán.** Chỉ gửi sau khi server xác nhận `paid`.

---

## Bước 1: Mở đúng dịch vụ backend trên Render

1. Mở trình duyệt và truy cập:

   ```text
   https://dashboard.render.com/
   ```

2. Đăng nhập tài khoản Render đang sở hữu backend.
3. Tìm service có URL:

   ```text
   https://hotel-booking-backend-fz9h.onrender.com
   ```

4. Bấm vào service đó.
5. Kiểm tra service là **Web Service**, không phải Static Site.
6. Vào mục **Settings** để xem:
   - Repository đang kết nối.
   - Branch đang deploy.
   - Build Command.
   - Start Command.

Nếu không tìm thấy service này, cần hỏi chủ tài khoản Render hoặc người quản lý GitHub repository. Không tạo service mới trước khi xác định backend hiện tại, vì Flutter đang gọi URL trên.

---

## Bước 2: Kiểm tra backend đang dùng công nghệ gì

Mở repository backend được ghi trong Render và kiểm tra file:

| File | Công nghệ |
|---|---|
| `package.json` | Node.js |
| `requirements.txt` hoặc `pyproject.toml` | Python |
| `pom.xml` | Java |
| `go.mod` | Go |

Hướng dẫn bên dưới dùng **Node.js + Express**. Nếu backend không phải Node.js, giữ nguyên API contract và nhờ người phụ trách chuyển phần SMTP sang thư viện tương ứng.

---

## Bước 3: Khai báo biến môi trường trên Render

Trong service Render:

```text
Environment
→ Add Environment Variable
```

Thêm từng dòng sau:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=nguyenly.31241023382@st.ueh.edu.vn
SMTP_APP_PASSWORD=<App Password Gmail>
PAYMENT_NOTIFICATION_EMAIL=nguyenly.31241023382@st.ueh.edu.vn
```

Giải thích:

| Tên biến | Giá trị |
|---|---|
| `SMTP_HOST` | `smtp.gmail.com` |
| `SMTP_PORT` | `587` |
| `SMTP_USER` | Email Gmail dùng để gửi |
| `SMTP_APP_PASSWORD` | App Password vừa tạo, không phải mật khẩu Gmail thường |
| `PAYMENT_NOTIFICATION_EMAIL` | Email cố định nhận thông báo |

Không gửi hoặc commit App Password vào:

- Flutter.
- GitHub/GitLab.
- Tài liệu.
- File `.env` đã commit.
- Chat.

Sau khi nhập xong, bấm **Save Changes**. Render thường tự deploy lại. Nếu chưa deploy, vào **Manual Deploy → Deploy latest commit**.

---

## Bước 4: Cài thư viện SMTP cho Node.js

Mở terminal tại thư mục backend, chạy:

```bash
npm install nodemailer dotenv
```

Nếu API public, nên cài thêm:

```bash
npm install helmet express-rate-limit
```

Ở file khởi động server, đặt dòng này ở đầu:

```js
require('dotenv').config();
```

Trên Render, biến môi trường đã có sẵn nên không cần upload file `.env`.

---

## Bước 5: Tạo module gửi email

Tạo file:

```text
src/services/paymentEmailService.js
```

Nội dung:

```js
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 587),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_APP_PASSWORD,
  },
});

async function sendPaymentSuccessEmail({
  bookingId,
  paymentId,
  amount,
  hotelName,
  checkIn,
  checkOut,
}) {
  const money = new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(Number(amount));

  await transporter.sendMail({
    from: `"FomoGo" <${process.env.SMTP_USER}>`,
    to: process.env.PAYMENT_NOTIFICATION_EMAIL,
    subject: `Thanh toán thành công - Đơn ${bookingId}`,
    text: [
      'Thanh toán FomoGo đã được xác nhận thành công.',
      '',
      `Mã đặt phòng: ${bookingId}`,
      `Mã thanh toán: ${paymentId}`,
      `Khách sạn: ${hotelName}`,
      `Nhận phòng: ${checkIn}`,
      `Trả phòng: ${checkOut}`,
      `Tổng tiền: ${money}`,
    ].join('\n'),
  });
}

module.exports = { sendPaymentSuccessEmail };
```

---

## Bước 6: Tạo các API cần thiết

### API 1: Kiểm tra server

```http
GET /health
```

Response:

```json
{
  "success": true,
  "service": "hotel-booking-api"
}
```

API này dùng để kiểm tra Render có chạy hay không.

### API 2: Tạo payment

API hiện có của dự án:

```http
POST /api/payments
Authorization: Bearer <JWT>
Content-Type: application/json
```

Body:

```json
{
  "booking_id": "booking-id",
  "payment_method": "card"
}
```

`payment_method` chỉ được là:

```text
card
qr
```

Response cần trả về payment có tối thiểu:

```json
{
  "success": true,
  "data": {
    "id": "payment-id",
    "booking_id": "booking-id",
    "amount": 1500000,
    "status": "pending",
    "payment_method": "card"
  }
}
```

### API 3: Xác nhận thanh toán

Nếu đang dùng mock payment:

```http
POST /api/payments/{paymentId}/simulate
Authorization: Bearer <JWT>
Content-Type: application/json
```

Body thành công:

```json
{
  "result": "success"
}
```

Backend phải:

1. Tìm payment theo `paymentId`.
2. Kiểm tra payment thuộc user hiện tại.
3. Cập nhật status thành `paid`.
4. Lấy booking liên quan.
5. Gửi email sau khi đã xác nhận `paid`.
6. Trả response payment đã cập nhật.

Response thành công:

```json
{
  "success": true,
  "data": {
    "id": "payment-id",
    "booking_id": "booking-id",
    "amount": 1500000,
    "status": "paid",
    "payment_method": "card"
  }
}
```

### API 4: Endpoint gửi email riêng

Chỉ tạo endpoint này nếu muốn một service email riêng:

```http
POST /api/notifications/payment-success
Content-Type: application/json
X-Notification-Key: <secret>
```

Body:

```json
{
  "bookingId": "booking-id",
  "paymentId": "payment-id",
  "amount": 1500000,
  "hotelName": "FomoGo Hotel",
  "checkIn": "2026-10-25",
  "checkOut": "2026-10-27"
}
```

Quy tắc bắt buộc:

1. Kiểm tra `X-Notification-Key`.
2. Không nhận `recipient` từ body client.
3. Luôn gửi đến `PAYMENT_NOTIFICATION_EMAIL`.
4. Kiểm tra payment thật trong database.
5. Chỉ gửi nếu payment là `paid`.
6. Không log App Password, JWT hoặc số thẻ.
7. Trả lỗi `400` nếu body thiếu hoặc sai kiểu dữ liệu.
8. Trả lỗi `401` nếu API key sai.
9. Trả lỗi `502` nếu Gmail SMTP không gửi được.

Response:

```json
{
  "success": true,
  "duplicate": false
}
```

---

## Bước 7: Gắn gửi email vào đúng chỗ

Trong handler xác nhận payment, gọi module email **sau khi cập nhật thành công `paid`**:

```js
const { sendPaymentSuccessEmail } =
  require('../services/paymentEmailService');

async function confirmPayment(paymentId) {
  const payment = await paymentRepository.findById(paymentId);

  if (!payment) {
    throw new Error('Payment not found');
  }

  const updatedPayment = await paymentRepository.markAsPaid(paymentId);
  const booking = await bookingRepository.findById(updatedPayment.booking_id);

  await sendPaymentSuccessEmail({
    bookingId: booking.id,
    paymentId: updatedPayment.id,
    amount: Number(updatedPayment.amount),
    hotelName: booking.hotel_name,
    checkIn: booking.check_in,
    checkOut: booking.check_out,
  });

  return updatedPayment;
}
```

Không dùng số tiền do Flutter gửi làm nguồn chính. Backend phải lấy amount từ database.

---

## Bước 8: Chống gửi email trùng

Nếu server retry hoặc người dùng bấm lại, cùng một payment không được gửi nhiều email.

Tạo bảng:

```sql
CREATE TABLE payment_email_notifications (
  id BIGSERIAL PRIMARY KEY,
  payment_id VARCHAR(255) NOT NULL UNIQUE,
  booking_id VARCHAR(255) NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Trước khi gửi:

1. Tìm `payment_id` trong bảng.
2. Nếu đã có, trả `duplicate: true`.
3. Nếu chưa có và payment là `paid`, gửi email.
4. Ghi `payment_id` vào bảng.

Với production, nên dùng transaction hoặc outbox/queue. Không chỉ dùng biến `Set` trong RAM vì Render có thể restart service.

---

## Bước 9: Kiểm thử local

Tạo file `.env` trong backend, chỉ dùng trên máy local:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=nguyenly.31241023382@st.ueh.edu.vn
SMTP_APP_PASSWORD=<App Password Gmail>
PAYMENT_NOTIFICATION_EMAIL=nguyenly.31241023382@st.ueh.edu.vn
```

Chạy server:

```bash
npm install
npm start
```

Kiểm tra health:

```bash
curl http://localhost:8080/health
```

Kiểm tra email bằng payment test:

```bash
curl -X POST http://localhost:8080/api/notifications/payment-success ^
  -H "Content-Type: application/json" ^
  -d "{\"bookingId\":\"test-booking\",\"paymentId\":\"test-payment-001\",\"amount\":1500000,\"hotelName\":\"FomoGo Hotel\",\"checkIn\":\"2026-10-25\",\"checkOut\":\"2026-10-27\"}"
```

Kiểm tra đủ các trường hợp:

- Đúng dữ liệu: trả `200`, email đến hộp thư.
- Gọi lại cùng `paymentId`: không gửi email thứ hai.
- Thiếu `bookingId`: trả `400`.
- App Password sai: không trả thành công giả.
- Payment chưa `paid`: không gửi email.

---

## Bước 10: Deploy và kiểm tra trên Render

1. Commit code backend lên repository.
2. Push đúng branch Render đang theo dõi.
3. Vào Render service.
4. Mở **Deploys** để xem deploy.
5. Mở **Logs** để xem lỗi.
6. Kiểm tra:

   ```text
   https://hotel-booking-backend-fz9h.onrender.com/health
   ```

7. Thực hiện một payment test.
8. Kiểm tra email:

   ```text
   nguyenly.31241023382@st.ueh.edu.vn
   ```

9. Nếu không thấy email, kiểm tra cả thư mục Spam.

---

## Bước 11: Flutter cần thay đổi gì

Flutter hiện gọi:

```text
https://hotel-booking-backend-fz9h.onrender.com
```

Nếu backend tự gửi email trong API xác nhận payment, Flutter **không cần biết SMTP** và không cần chứa App Password.

Flutter chỉ cần:

1. Gọi `POST /api/payments`.
2. Gọi API xác nhận payment.
3. Chỉ hiển thị thành công nếu response trả `status = paid`.

Đây là cách khuyến nghị:

```text
Flutter → Backend payment API → Gmail SMTP
```

Không nên làm:

```text
Flutter → Gmail SMTP
```

vì App Password trong APK có thể bị lấy cắp.

---

## Bước 12: Checklist bàn giao

- [ ] Đã xác định đúng Render service.
- [ ] Đã thêm Environment Variables trên Render.
- [ ] App Password không nằm trong source code.
- [ ] Đã cài `nodemailer`.
- [ ] Có `GET /health`.
- [ ] `POST /api/payments` tạo payment `pending`.
- [ ] API xác nhận cập nhật payment thành `paid`.
- [ ] Email chỉ gửi sau khi `paid`.
- [ ] Recipient lấy từ server, không lấy từ client.
- [ ] Có chống gửi trùng theo `paymentId`.
- [ ] Có xử lý SMTP timeout/lỗi.
- [ ] Không log secret, JWT hoặc dữ liệu thẻ.
- [ ] Đã test local.
- [ ] Đã deploy Render và xem Logs.
- [ ] Đã kiểm tra email chính và Spam.

## Các thông tin cần hỏi backend developer nếu bị lỗi

Gửi cho người làm backend các câu hỏi sau:

1. Backend đang dùng Node.js, Python hay công nghệ nào?
2. Repository backend nào đang deploy lên Render?
3. API nào thực sự cập nhật payment thành `paid`?
4. Database có bảng payment và cột `status` chưa?
5. Có webhook thanh toán thật hay chỉ đang dùng `simulate`?
6. Email được gửi trong payment API hay endpoint riêng?
7. Đã có cơ chế chống gửi trùng chưa?
8. Render Logs báo lỗi SMTP gì?
9. Có blocker database ở notification/payment hiện tại không?
