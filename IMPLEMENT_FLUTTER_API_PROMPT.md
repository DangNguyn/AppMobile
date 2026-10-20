# Prompt: Integrate the existing Hotel Booking API into this Flutter project

Copy the prompt below into an AI coding assistant while the Flutter repository is open.

---

## Role and scope

You are a senior Flutter engineer integrating an existing hotel-booking backend. Work inside the Flutter project that is currently open. Do not modify backend source, database schema, or the API documentation as part of Flutter integration unless the user separately authorizes backend work.

Production API base URL supplied by the backend project: `https://hotel-booking-backend-fz9h.onrender.com`. Treat the URL as configuration, not proof the production service is reachable. Do not call production mutation endpoints as tests.

## Required discovery before editing

1. Read `pubspec.yaml`, inspect `lib/`, app routing, current state management, theme, models, repositories/services, and existing tests.
2. Find and read the backend references `FLUTTER_AI_INTEGRATION_GUIDE.md` and `HOTEL_BOOKING_API_DOCUMENT.md` if available. If they are absent, inspect the backend source/OpenAPI when that repository is available; do not infer an endpoint from a screen design.
3. Check whether the Flutter project already has an API client or auth/token storage and extend it instead of creating a parallel architecture.
4. Summarize the project structure and the concrete integration plan before broad edits. Keep the current design and navigation unless asked to redesign them.

## Backend API contract to follow

Use only the routes and fields documented in the API reference and verified in backend source. Base URL path prefix is `/api` except root health.

- Public data: hotels and their images/amenities/vibes/room types/reviews, room types and their images/rooms, rooms and availability, vouchers.
- Authentication: register requires `full_name,email,phone,password`; login takes `email,password` and intends to return JWT plus public user data. The backend JWT lasts 7 days. `POST /api/auth/logout` does not revoke it; client must delete secure local token. **Known backend blockers:** registration omits `users.id`, but inspected schema has no UUID default or trigger; login updates `users.last_login_at`, which is absent from the schema. Confirm both are fixed in server/schema before relying on registration/login in a real integration.
- Profile: `GET /api/users/me`, `PUT /api/users/me` with only `full_name`, `phone`, `avatar`.
- Availability: `GET /api/rooms/available?hotel_id=...&check_in=YYYY-MM-DD&check_out=YYYY-MM-DD&room_type_id=...`; checkout must follow check-in. The result is physical rooms. Booking creation rechecks overlap. Pending bookings, including those with failed payment, remain room blockers because only cancelled bookings are excluded and no expiry exists.
- Booking create: `POST /api/bookings` requires `hotel_id,room_ids,check_in,check_out,adults`; optional `children` (default 0), `voucher_code`. `room_ids` are physical room IDs. Server calculates price. Database stores aggregate `number_of_guests`; it does not persist an adult/child split. Current route writes tax as zero.
- Booking history/detail: `GET /api/bookings` and `GET /api/bookings/{id}` are scoped to the JWT user. History includes hotel name, room list, booking totals/status, latest payment status/method. Hotel images, guest names and cancellation policy are not in that response. Use guest/payment subroutes when needed.
- Booking actions: `PATCH /api/bookings/{id}/cancel`; `POST /api/bookings/{id}/check-in` only on a confirmed booking on its check-in date. `GET /api/bookings/{id}/qr` returns a booking `qr_token`; do not treat it as payment confirmation.
- Payments are mock-only: `POST /api/payments` body `{booking_id,payment_method}` where method is `card` or `qr`; amount is read by the backend. For QR, `GET /api/payments/{id}/qr` provides plain text to encode. Scanning does not mark paid. `POST /api/payments/{id}/simulate` body `{result:"success"|"failed"}` is gated by server `PAYMENT_MODE=mock`.
- **Known payment/notification blocker:** no notifications table appeared in inspected DB schema. The route uses `notifications.message`, but the checked-in migration creates `content`. The payment success route inserts a notification inside the same transaction, so its success branch fails/rolls back until backend/database are aligned. Do not claim payment success or build UI that assumes a successful response until this is resolved and verified. Payment failure sets the payment `failed` and normally leaves the booking `pending`.
- Reviews can be written only for the user’s booking at the same hotel when its status is `completed` or `checked_in`; rating is 1–5.
- Notification listing has a route but is not operationally verified due to the blocker above. FCM push is not implemented.

Statuses from inspected DB constraints: booking `pending,confirmed,cancelled,completed,checked_in,no_show`; payment `pending,paid,failed,refunded`. Never invent a status or mark success locally before backend confirmation.

## Implementation requirements

- Reuse the project’s existing architecture. Add/adjust API client, DTO/model, repository/service, and UI state only as needed.
- Keep base URL environment-configurable for development/staging/production. Do not hardcode passwords, API keys or JWTs.
- Attach Bearer token only to protected APIs; handle invalid optional bearer correctly (the hotel review list is public but a supplied token must be valid).
- Store JWT securely. Do not log credentials, token, identification info or payment-card data.
- Parse JSON defensively: nullable values, IDs as strings, PostgreSQL numeric fields as number-or-numeric-string, and dates as `YYYY-MM-DD`.
- Implement loading, empty, success and recoverable error states. Handle `400`, `401`, `403`, `404`, `409`, `500` without claiming an operation succeeded when it did not.
- Do not add fake hotel/room/booking/payment data as production fallback. If an endpoint is blocked or unavailable, display a truthful error/state and report the backend dependency.
- Do not implement card collection for this backend mock flow. Never send PAN, CVV/CVC or OTP.
- Do not invent hotel search, pagination, refresh-token, FCM, availability hold/expiry, cancellation policy, or fields absent from the API.
- Add or update focused tests using the project’s existing conventions. Do not make unrelated app-wide rewrites.

## Suggested user flows

1. Explore: load hotels, then load hotel images/amenities/vibes/room types as needed.
2. Choose dates and guests: query physical availability; show the returned room/type/capacity/base price. Treat this as a snapshot.
3. Book: send selected physical room IDs and dates; use the returned booking as canonical. If response is 409, refresh availability and explain conflict.
4. Pay demo: initiate card/QR method without sensitive card fields. For QR, render the returned plain text locally. Poll/get payment only if the app already has a deliberate refresh flow; do not treat QR scan as payment. Simulate only if the backend explicitly reports mock mode available and the environment is a demo. Respect the notification schema blocker; do not show a false successful state.
5. My bookings: load `/api/bookings`, show exactly fields provided, and load booking detail/guests/payments where needed. Do not derive hotel image or guest names from unrelated data.
6. Check-in: display the backend booking QR/token only if appropriate; call check-in and trust its response, including 409 if date/status is ineligible.

## Completion checklist

- List every Flutter file changed and what it does.
- List each integrated endpoint with HTTP method, auth behavior and screen/service using it.
- List unresolved backend blockers: register’s missing generated `users.id`, login’s `last_login_at` schema mismatch, payment notification table/column mismatch, and any others discovered in source.
- State which flows were tested locally, the exact commands and outcomes. Run `flutter pub get`, `flutter analyze`, and relevant tests only when Flutter tooling/dependencies are available; report skipped checks honestly.
- Do not claim production connectivity or successful real payment unless directly verified in an authorized non-mutating way.

---

## Backend documentation sources

- `FLUTTER_AI_INTEGRATION_GUIDE.md`
- `HOTEL_BOOKING_API_DOCUMENT.md`
- Backend OpenAPI: `openapi.yaml`

