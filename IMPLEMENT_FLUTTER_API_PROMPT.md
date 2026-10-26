# Prompt: Integrate the existing Hotel Booking API into this Flutter project

Copy the prompt below into an AI coding assistant while the Flutter repository is open.

---

## Role and scope

You are a senior Flutter engineer integrating the existing hotel-booking backend. Work only in the Flutter project. Do not modify backend source, database schema, email-provider/Render configuration, or backend documentation unless separately authorized. Do not deploy or call production mutation endpoints as tests.

Production base URL supplied by the project: `https://hotel-booking-backend-fz9h.onrender.com`. Treat this as configuration, not proof of availability.

## Required discovery before editing

1. Read `pubspec.yaml`, inspect `lib/`, navigation, state management, theme, models, repositories/services, and tests.
2. Read `FLUTTER_AI_INTEGRATION_GUIDE.md` and `HOTEL_BOOKING_API_DOCUMENT.md`. If unavailable, inspect `src/app.js`, mounted routes, middleware and services; never infer an endpoint from a screen.
3. Reuse the existing API client/auth/token storage and summarize the plan before broad changes.

## Backend contract

Use only APIs currently present in source:

- Health: `GET /`, `GET /api/test-db` public.
- Auth: public `POST /api/auth/register` (`full_name,email,phone,password`) and `POST /api/auth/login` (`email,password`); JWT `POST /api/auth/logout`, `GET /api/auth/me`. JWT has `id`, expires in 7 days. Logout does not revoke it; delete local token.
- Profile: JWT `GET /api/users/me` returns `is_private`; `PUT /api/users/me` accepts `full_name`, `phone`, `avatar`, and boolean `is_private`. The privacy field requires running `migrations/005_add_user_privacy.sql` in the target database.
- Catalog: public hotels (`GET /api/hotels`, `/{id}`, `/{id}/images`, `/{id}/amenities`, `/{id}/vibes`, `/{id}/room-types`), room types (`GET /api/room-types/{id}`, `/{id}/images`, `/{id}/rooms`), rooms (`GET /api/rooms`, `/{id}`, `/available`), vouchers (`GET /api/vouchers`, `/{code}`, `POST /validate`). The mounted availability route is exactly `GET /api/rooms/available?hotel_id=...&check_in=YYYY-MM-DD&check_out=YYYY-MM-DD&room_type_id=...`; `room_type_id` is optional. A successful response has `data` as the list of available physical rooms; an empty list is HTTP 200. Hotel reviews list is optional JWT; supplied invalid JWT still returns 401.
- Booking: JWT `POST /api/bookings` requires `hotel_id,room_ids,check_in,check_out,adults,booking_email`; optional `children` defaults to 0 and `voucher_code`. `room_ids` are physical room IDs. Booking email is checked for format only and stored per booking. Backend calculates totals; tax is currently zero. Before insert, the transaction locks selected room rows and checks for overlapping bookings; a room that became occupied returns HTTP 409. History/detail and cancel/check-in/booking QR routes are `/api/bookings`, `/{id}`, `/{id}/cancel` (PATCH), `/{id}/check-in` (POST), `/{id}/qr`; nested guest routes are `/{id}/guests` (GET/POST) and payments `/{id}/payments` (GET). Guest edit/delete: `/api/guests/{id}` (PUT/DELETE). All these require JWT and enforce ownership where source checks it.
- Payment: JWT `POST /api/payments` takes `booking_id,payment_method` (`card` or `qr`); amount comes from DB. `GET /api/payments/{id}` and `/{id}/qr`; QR data is demo text, not proof of transfer. `POST /api/payments/{id}/simulate` takes `{"result":"success"|"failed"}` and requires server `PAYMENT_MODE=mock`.
- `POST /api/payments` returns the existing pending payment with HTTP 200 and `reused:true` if one already exists, and returns 409 when the booking is already paid or otherwise ineligible. On mock success, backend commits payment `paid` and booking `confirmed` first; it then attempts notification and email independently. Notification failure does not roll back payment or prevent email. Email uses booking `booking_email` and customer name from `users.full_name`; response includes `email.status` (`sent`, `failed`, `sending`, `not_tracked`, `not_applicable`). Brevo API failure does not roll back paid status; `email.status="sent"` means Brevo accepted the request, while `email.delivery_status="unconfirmed"` means actual delivery is not confirmed. This is not a real payment-provider integration.
- Notifications: JWT `GET /api/notifications`.
- Favorites: JWT `GET /api/favorites`, `POST /api/favorites/{hotel_id}`, and `DELETE /api/favorites/{hotel_id}`.
- Reviews: JWT `POST /api/reviews` (`hotel_id,booking_id,rating,comment?`), `PUT/DELETE /api/reviews/{id}`; also hotel-scoped `POST /api/hotels/{id}/reviews`. Review requires the user's same-hotel booking in `completed`/`checked_in`, or `confirmed` with checkout date passed; rating 1–5. Reviews are hotel ratings, separate from experience posts.
- Posts: `POST /api/posts` (JWT; `title,location,rating,content`), `GET /api/posts`, `/search`, `/{id}`, `/users/{userId}`, `/{id}/comments` (optional JWT); `/mine` (JWT); post/comment create, update, delete require JWT. Setting `is_private=true` restricts posts and comments to the owner; optional-JWT read endpoints must include the owner's Bearer JWT to view their own private content. No image upload or user-profile-by-id endpoint is mounted.
- There are no refresh-token, hotel search/pagination, or FCM endpoints in mounted source.

## Known integration caveats

- Previously inspected local schema lacked `users.id` default while register source omits an ID; login writes `last_login_at`, absent from that local metadata. Do not assume those auth writes work until verified in the target environment.
- Booking source writes `bookings.booking_email`; migration `migrations/002_add_booking_email.sql` adds it. `migrations/003_payment_email_deliveries.sql` also ensures this column exists and adds email delivery tracking. The user reports migration 003 ran successfully in their SQL client; the target database has not been confirmed as the Render backend database.
- Payment success inserts `notifications.content` after commit; if the table is absent, payment remains paid and email is still attempted, while notification creation is logged as failed. `GET /api/notifications` selects `content AS message` to preserve its response shape. Previously inspected local DB had no notifications table.
- Schema observations were from configured local DB, not production. Render schema, Brevo credentials/configuration, and end-to-end payment/email have not been verified. The Flutter app must never receive email-provider credentials; configure `EMAIL_PROVIDER=brevo`, `BREVO_API_KEY`, `BREVO_SENDER_EMAIL`, and `BREVO_SENDER_NAME` only in backend environment settings. `BREVO_TIMEOUT_MS` is optional.

## Implementation requirements

- Follow existing Flutter architecture and keep visual design/navigation unless asked otherwise.
- Keep base URL environment-configurable. Store JWT securely; never log passwords, tokens, identity details or card data.
- Attach Bearer JWT only to protected APIs. Parse nullable values, string-or-number PostgreSQL numerics, opaque string IDs and `YYYY-MM-DD` dates safely.
- Handle loading, empty, success and recoverable error states. For availability, HTTP 200 with `data: []` means no rooms are available. Respect server `400/401/403/404/409/500`; booking `409` means availability changed before confirmation. Parse a JSON error body's `message`; show a connection error when the request receives no HTTP response, and a system error when the response cannot be parsed. Never claim success before a successful response.
- Do not invent backend fields or endpoints, fake production data, card entry, payment scanning confirmation, booking expiry, cancellation policy, refresh-token or push behavior.
- For private posts, send the Bearer JWT to optional-auth post read endpoints when the signed-in owner needs to see their content. Do not rely on Flutter-only hiding; the backend enforces visibility. Do not add follow-request behavior; it is not implemented by these APIs.
- Do not modify booking/review behavior or introduce experience posts/image uploads as part of this integration.
- Add focused tests following existing Flutter conventions; do not rewrite unrelated app areas.

## Suggested flow

1. Explore hotel/catalog data and query physical room availability for dates.
2. Create booking with the selected room IDs and a separately entered `booking_email`; use the server response as canonical.
3. Create a demo payment without card data. For QR, encode/display returned demo text only. Simulate only in a demo environment when mock mode is intentionally enabled.
4. Treat payment as paid only when the server response says `data.status="paid"`. Show email status from `email.status`; do not claim an email was delivered when status is `failed` or `not_tracked`.
5. Load booking history/detail and nested guests/payments as needed. For check-in, trust backend eligibility and response.

## Completion report

List changed Flutter files, integrated methods/routes and auth behavior, checks/tests run, and unresolved dependencies. Do not claim production connectivity, real payment, or email delivery unless directly verified in an authorized non-mutating way.

---

## Backend references

- `FLUTTER_AI_INTEGRATION_GUIDE.md`
- `HOTEL_BOOKING_API_DOCUMENT.md`
- `openapi.yaml` (verify against mounted source; it may not cover later changes)
