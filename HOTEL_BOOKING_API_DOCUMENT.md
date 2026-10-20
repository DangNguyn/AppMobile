# Hotel Booking REST API

> Reference assembled from the handlers mounted by `src/app.js`, route SQL, auth middleware, OpenAPI and read-only metadata from the configured PostgreSQL database. Production was not called. “Route exists” describes source code, not a guarantee that a route currently succeeds against the database.

## 1. Common details

- Production base URL provided by the project: `https://hotel-booking-backend-fz9h.onrender.com` (availability not verified).
- JSON API. Send `Content-Type: application/json` for JSON bodies. Express JSON body limit is 1 MB.
- Protected routes use `Authorization: Bearer <JWT>`. JWT is signed with `JWT_SECRET`, contains `id`, and expires in 7 days.
- IDs are generally opaque strings (`varchar` in PostgreSQL); `users.id` is UUID. Do not assume every ID is UUID.
- Date fields are date-only strings `YYYY-MM-DD`. Booking overlap uses half-open intervals: `existing.check_in < requested.check_out AND existing.check_out > requested.check_in`.
- PostgreSQL `numeric` values are commonly serialized by `pg` as strings; parse numeric strings safely in Flutter. No currency code is returned by these handlers.
- Common response is `{ "success": true, "data": ... }`; auth responses vary. Errors generally use `{ "success": false, "message": "..." }`; no stable application error code is defined.

## 2. Endpoint catalog from source

| Method | Endpoint | Auth | Request | Successful response |
|---|---|---|---|---|
| GET | `/` | Public | — | `{success,message}` health text |
| GET | `/api/test-db` | Public | — | `{success,data:{current_time}}` |
| POST | `/api/auth/register` | Public | `full_name,email,phone,password` | 201 `{success,message,user}` |
| POST | `/api/auth/login` | Public | `email,password` | 200 `{success,token,data:user}`; see schema warning below |
| POST | `/api/auth/logout` | JWT | — | 200 `{success,message}`; token is not revoked server-side |
| GET | `/api/auth/me` | JWT | — | 200 `{success,data:user}` |
| GET | `/api/users/me` | JWT | — | 200 `{success,data:user}` |
| PUT | `/api/users/me` | JWT | `full_name?`, `phone?`, `avatar?` | 200 `{success,data:user}` |
| GET | `/api/hotels` | Public | — | 200 `{success,data:[hotel]}` ordered by id |
| GET | `/api/hotels/{id}` | Public | path `id` | 200 hotel; 404 if absent |
| GET | `/api/hotels/{id}/images` | Public | path `id` | 200 `[{id,hotel_id,image_url,ordering}]` |
| GET | `/api/hotels/{id}/amenities` | Public | path `id` | 200 `[{id,name,description}]` |
| GET | `/api/hotels/{id}/vibes` | Public | path `id` | 200 `[{id,name,description}]` |
| GET | `/api/hotels/{id}/room-types` | Public | path `id` | 200 room types with price/capacity |
| GET | `/api/hotels/{id}/reviews` | Optional JWT | path `id` | 200 reviews with reviewer name/avatar |
| POST | `/api/hotels/{id}/reviews` | JWT | `booking_id,rating,comment?` | 201 review |
| GET | `/api/room-types/{id}` | Public | path `id` | 200 room type; 404 if absent |
| GET | `/api/room-types/{id}/images` | Public | path `id` | 200 `[{id,room_type_id,image_url,ordering}]` |
| GET | `/api/room-types/{id}/rooms` | Public | path `id` | 200 physical rooms |
| GET | `/api/rooms` | Public | filters `hotel_id?`, `room_type_id?`, `status?` | 200 physical rooms |
| GET | `/api/rooms/{id}` | Public | path `id` | 200 room; 404 if absent |
| GET | `/api/rooms/available` | Public | `hotel_id,check_in,check_out,room_type_id?` | 200 available rooms with type, capacity and base price |
| POST | `/api/bookings` | JWT | booking body below | 201 booking plus selected rooms |
| GET | `/api/bookings` | JWT | — | 200 owned booking history with rooms/payment summary |
| GET | `/api/bookings/{id}` | JWT | path `id` | 200 owned booking with rooms |
| PATCH | `/api/bookings/{id}/cancel` | JWT | — | 200 `{data:{id,status:"cancelled"}}` |
| POST | `/api/bookings/{id}/check-in` | JWT | — | 200 `{data:{id,status,checked_in_at}}` |
| GET | `/api/bookings/{id}/qr` | JWT | path `id` | 200 `{booking_id,booking_code,status,qr_token}` |
| GET | `/api/bookings/{id}/guests` | JWT | path `id` | 200 guest array |
| POST | `/api/bookings/{id}/guests` | JWT | `full_name,phone?,email?,identification_info?` | 201 guest |
| GET | `/api/bookings/{id}/payments` | JWT | path `id` | 200 payment array |
| PUT | `/api/guests/{id}` | JWT | guest fields optional | 200 `{success,message,data}` |
| DELETE | `/api/guests/{id}` | JWT | path `id` | 200 `{success,message}` |
| POST | `/api/payments` | JWT | `booking_id,payment_method` (`card` or `qr`) | 201 pending payment; amount from DB |
| GET | `/api/payments/{id}` | JWT | path `id` | 200 owned payment |
| GET | `/api/payments/{id}/qr` | JWT | path `id` | 200 mock QR text, QR payments only |
| POST | `/api/payments/{id}/simulate` | JWT + `PAYMENT_MODE=mock` | `result: success|failed` | 200 updated payment; schema blocker below |
| GET | `/api/notifications` | JWT | — | 200 notification array in source; schema blocker below |
| GET | `/api/vouchers` | Public | — | 200 active in-date vouchers |
| GET | `/api/vouchers/{code}` | Public | path `code` | 200 voucher; 404 if absent |
| POST | `/api/vouchers/validate` | Public | `code,subtotal` | 200 voucher and computed discount/total |
| GET | `/api/favorites` | JWT | — | 200 current user’s hotel favorites |
| POST | `/api/favorites/{hotel_id}` | JWT | path `hotel_id` | 201 `{user_id,hotel_id}` |
| DELETE | `/api/favorites/{hotel_id}` | JWT | path `hotel_id` | 200 removal message |
| POST | `/api/reviews` | JWT | `hotel_id,booking_id,rating,comment?` | 201 review |
| PUT | `/api/reviews/{id}` | JWT | `rating?`, `comment?` | 200 updated review |
| DELETE | `/api/reviews/{id}` | JWT | path `id` | 200 deletion message |

The source and `openapi.yaml` each contain 47 method/path operations including root and DB health. Their paths and methods match when Express `:id` placeholders are normalized to OpenAPI `{id}` placeholders. Route SQL and schema blockers described below still take precedence over a documented success shape. Unknown paths return 404 `{success:false,message:"API endpoint not found"}`.

## 3. Request and response details

### Authentication and profile

#### `POST /api/auth/register`

Request (all required):

```json
{"full_name":"Example User","email":"user@example.test","phone":"0900000000","password":"example-password"}
```

Email is trimmed/lowercased and format checked; password must be at least 8 characters. Password is bcrypt hashed and is not returned. Success is `201 {success:true,message,user:{id,email,full_name,phone,avatar,created_at}}`; invalid input `400`; duplicate email/phone `409` (may include an `errors` object); database error `500`.

**Runtime schema blocker:** source omits `id` in its `INSERT INTO users`; inspected schema declares `users.id uuid NOT NULL` with no default, and no users trigger was found. A valid registration is therefore expected to fail with a database error until source or schema supplies the UUID. Auth tests use a DB stub and do not validate this insert against PostgreSQL.

#### `POST /api/auth/login`

Request `{ "email":"user@example.test", "password":"example-password" }`. Success intended by source is `200 {success:true,token,data:{id,email,full_name,phone,avatar,created_at}}`; invalid/missing body `400`; wrong credentials `401`; server/database error `500`.

**Runtime schema blocker:** login executes `UPDATE users SET last_login_at=CURRENT_TIMESTAMP`, but the current configured database metadata has no `users.last_login_at` column. The handler catches this and returns `500`; therefore successful login is **not verified against this database** (the checked-in auth tests use a DB stub). Do not treat the intended response as confirmed live behavior until backend/schema is aligned.

#### `POST /api/auth/logout`, `GET /api/auth/me`, `GET /api/users/me`, `PUT /api/users/me`

Logout requires JWT and returns a message telling the client to delete its token. JWT is stateless and remains valid until expiry. Both profile GET routes return `id,email,full_name,phone,avatar,created_at`; missing user `404`. Profile PUT accepts only `full_name`, `phone`, `avatar`; unknown body keys return `400`; supplied null keeps the existing value due to `COALESCE`; success returns updated profile.

### Hotels, room types and rooms

Hotel response fields: `id,name,description,address,city,latitude,longitude,star_rating,created_at`. Hotel list has no query filters, search or pagination. Hotel image fields are `id,hotel_id,image_url,ordering`. Hotel amenities/vibes have `id,name,description`. Room type fields: `id,hotel_id,name,description,max_guests,base_price`. Physical room fields: `id,hotel_id,room_type_id,room_number,status`.

List/details handlers return 500 on query error; single hotel/room/room type returns 404 if no matching row. Image and association routes return empty arrays when no rows match (and 500 on database error).

`GET /api/rooms` accepts optional `hotel_id`, `room_type_id`, and `status`; filters are combined with AND. No pagination. `GET /api/rooms/available` requires `hotel_id`, `check_in`, `check_out`, accepts optional `room_type_id`; date values must match `YYYY-MM-DD`, checkout later than check-in. It returns active physical rooms and excludes rooms with a booking whose status is anything other than `cancelled` when dates overlap. Response room adds `room_type_name,max_guests,base_price`. Input error `400`; query error `500`.

### Booking, guests, payment history, QR and check-in

#### `POST /api/bookings`

JWT required. Example:

```json
{"hotel_id":"<hotel-id>","room_ids":["<room-id>"],"check_in":"2030-05-10","check_out":"2030-05-12","adults":2,"children":0,"voucher_code":"<optional-code>"}
```

`hotel_id`, nonempty unique `room_ids`, dates, and `adults >= 1` are required. `children` defaults to 0. Each room must belong to that hotel and have status `active`; summed `max_guests` must cover adults + children. Price is room base price × nights. Voucher, when supplied, must be active/in validity dates and meet `min_order`; discount is capped at subtotal. The route locks room rows and checks overlap again inside a transaction. Success `201 {success:true,data:{id,booking_code,user_id,hotel_id,voucher_id,check_in,check_out,number_of_guests,subtotal,tax,discount,total_amount,status,qr_token,created_at,rooms:[{room_id,price_per_night,number_of_nights,subtotal}]}}`; initial status `pending`, tax currently set to 0. Errors: `400` invalid request/room mismatch/capacity/voucher, `401`, `404` foreign key target missing, `409` inactive or overlapping room, `500` other DB error.

#### `GET /api/bookings`

Returns only rows with `bookings.user_id` equal to JWT user. Each item contains `id,booking_code,hotel_id,hotel_name,check_in,check_out,number_of_guests,subtotal,tax,discount,total_amount,status,created_at,rooms,payment_status,payment_method`. `rooms` entries contain `room_id,room_number,room_type,price_per_night,number_of_nights,subtotal`. Payment summary is the most recent paid payment if one exists, otherwise selected by `paid_at`/ID ordering. No hotel image, guest names, policy, or full payment list is embedded. `401`, `500`.

#### `GET /api/bookings/{id}`

Only an owned booking is returned; response includes booking fields plus `rooms:[{room_id,price_per_night,number_of_nights,subtotal,room_number,room_type_id}]`. Unknown or another user’s ID both return `404`; DB error `500`.

#### Guest routes

- `GET /api/bookings/{id}/guests`: first checks booking ownership; returns `{success:true,data:[{id,booking_id,full_name,phone,email,identification_info}]}`. 404 if not owned/found.
- `POST /api/bookings/{id}/guests`: body requires truthy `full_name`, optional `phone,email,identification_info`; 201 with same fields plus generated `id,booking_id`; 400 missing name, 404 booking missing/not owned, 500 DB error.
- `PUT /api/guests/{id}`: optional `full_name,phone,email,identification_info`; updates only guest attached to a booking owned by user. Null/omitted values keep existing values. Returns `{success:true,message,data}` using `RETURNING *`; 404 if not owned/found, 500 DB error. No explicit field validation.
- `DELETE /api/guests/{id}`: removes only guest attached to an owned booking; 200 message, 404 not found/not owned, 500 DB error.

#### Booking payment list and booking QR

- `GET /api/bookings/{id}/payments`: returns `{success:true,data:[{id,booking_id,payment_method,transaction_id,amount,status,paid_at}]}` for an owned booking. 404 if booking not owned/found, 500 on DB error.
- `GET /api/bookings/{id}/qr`: returns `{success:true,data:{booking_id,booking_code,status,qr_token}}` for an owned booking; 404 otherwise. This token is a booking/check-in value, not evidence of payment.
- `PATCH /api/bookings/{id}/cancel`: no body. Only `pending` or `confirmed` can become `cancelled`; 200 result, 404 unknown/not owned, 409 existing booking in an ineligible state, 500.
- `POST /api/bookings/{id}/check-in`: no body. Requires owned booking with `status=confirmed` and `check_in=CURRENT_DATE`; success returns `{id,status:"checked_in",checked_in_at}`; 404 unknown/not owned; 409 ineligible status/date; 500.

### Payment routes

#### `POST /api/payments`

JWT required. Body only needs `booking_id` and `payment_method` (`card` or `qr`). Client amount, if present, is ignored. Server locks the owned booking and uses `bookings.total_amount`; rejects terminal booking states and an already-paid booking. Success `201 {success:true,data:{id,booking_id,payment_method,transaction_id,amount,status:"pending",paid_at:null}}`; invalid body `400`, missing/not-owned booking `404`, ineligible/already-paid booking `409`, DB error `500`. This is a pending mock record, not a charge.

#### `GET /api/payments/{id}`

JWT required; only payment on owned booking is exposed. 200 data `{id,booking_id,payment_method,transaction_id,amount,status,paid_at}`; 404 not found/not owned; 500 DB error.

#### `GET /api/payments/{id}/qr`

JWT required; only an owned payment using `qr` can retrieve QR data. Response:

```json
{"success":true,"data":{"payment_id":"<payment-id>","booking_id":"<booking-id>","booking_code":"<booking-code>","amount":"2500.00","payment_status":"pending","qr_content":"THANH TOAN BOOKING <booking-id>"}}
```

404 payment not found/not owned; 409 if method is not `qr`; 500 DB error. The string is demo text, not bank transfer instructions.

#### `POST /api/payments/{id}/simulate`

JWT required and server must have `PAYMENT_MODE=mock`; otherwise `403`. Body `{"result":"success"}` or `{"result":"failed"}`; invalid input `400`; payment missing/not owned `404`; already finished or booking ineligible/already paid `409`. Success is intended to set payment `paid`, set pending booking to `confirmed`, and create notification in the same transaction. Failure sets payment `failed`, leaves booking status unchanged (`pending` for normal pending booking). Response on transaction success is `{success:true,data:<updated payment>}`.

**Current schema blocker:** the connected database has no `notifications` table. The checked-in migration defines `content`, while the route inserts `message` (and GET notifications also selects `message`). Consequently the success branch cannot complete against the currently inspected database/migration pair; its transaction rolls back and returns 500. Do not rely on mock success until backend/schema are aligned and integration-tested. Failure branch does not insert notification.

#### `GET /api/notifications`

JWT required in source, returns rows `{id,user_id,booking_id,title,message,type,created_at,is_read}` scoped to current user. It is a route but **not verified as operational**: there is no notifications table in the configured DB metadata and the migration/source column mismatch above. Runtime DB error maps to 500.

### Vouchers, favorites and reviews

- `GET /api/vouchers`: public; returns vouchers `id,code,discount_type,discount_value,min_order,start_date,end_date,status` filtered to active and current date within validity. `500` on DB error.
- `GET /api/vouchers/{code}`: case-insensitive lookup; may return inactive/expired voucher. `200` data as above, `404` absent, `500` DB error.
- `POST /api/vouchers/validate`: public body `{ "code":"<code>", "subtotal":2500 }`. Returns `{success:true,data:{voucher,discount_amount,total_amount}}`. Discount uses percentage for type `percent`, otherwise fixed; capped at subtotal. `400` invalid/inactive/outside validity/below minimum, `404` missing code, `500` DB error. This endpoint previews a discount; booking creation validates again.
- `GET /api/favorites`: JWT; returns current user’s hotels as `id,name,description,address,city,star_rating`.
- `POST /api/favorites/{hotel_id}`: JWT, no body; 201 `{user_id,hotel_id}`, 404 hotel not found, 409 already favorite.
- `DELETE /api/favorites/{hotel_id}`: JWT; 200 message, 404 if absent.
- `GET /api/hotels/{id}/reviews`: public without token; optional bearer must still be valid. Returns newest-first `id,user_id,hotel_id,booking_id,rating,comment,created_at,full_name,avatar`; 500 DB error.
- `POST /api/hotels/{id}/reviews`: JWT body `{booking_id,rating,comment?}`. Rating integer 1–5 (route converts with `Number`). Booking must belong to user and hotel and have status `completed` or `checked_in`; success 201 review; 400 invalid fields, 403 booking not eligible, 409 one review already exists, 500 DB error.
- `POST /api/reviews`: same rules, but body also requires `hotel_id`; FK failure 404; duplicate 409.
- `PUT /api/reviews/{id}`: JWT, requires `rating` or `comment`; rating 1–5 if supplied. Updates only own review. 200 review, 400 invalid/empty request, 404 missing/not owned, 500 DB error. Null comment is coalesced to existing value, so this route cannot clear comment to SQL NULL.
- `DELETE /api/reviews/{id}`: JWT; deletes only own review. 200 message, 404 missing/not owned, 500 DB error.

## 4. Booking and availability model from SQL

The configured schema metadata confirms `bookings.id` and room/hotel IDs are `varchar`, `bookings.user_id` is `uuid`; `booking_rooms` links a booking to one or more physical `rooms` through `room_id`. A room has `room_type_id`, and `room_types` supplies `max_guests` and `base_price`. A booking can contain multiple physical rooms. `payments.booking_id` references booking ID; `payments.amount` is numeric and `paid_at` nullable.

Availability checks room-level overlaps, not inventory counts by room type. SQL treats every booking except `cancelled` as occupying dates. Thus `pending` bookings (including one whose payment failed) block dates; there is no expiry. Creation locks the selected room rows and rechecks overlap in a transaction. Date intervals use `[check_in,check_out)` semantics. `GET /api/rooms/available` exists; there is no hotel search/filter/pagination endpoint.

## 5. Schema and runtime verification notes

The configured PostgreSQL schema was read without changing data. Relevant observed columns include:

- `bookings`: `id varchar`, `booking_code varchar`, `user_id uuid`, `hotel_id varchar`, `voucher_id varchar nullable`, `check_in/out date`, `number_of_guests integer`, `subtotal/tax/discount/total_amount numeric`, `status varchar`, `qr_token text nullable`, `checked_in_at`, `created_at`.
- `booking_rooms`: `booking_id varchar`, `room_id varchar`, `price_per_night numeric`, `number_of_nights integer`, `subtotal numeric`.
- `payments`: `id varchar`, `booking_id varchar`, `payment_method varchar nullable`, `transaction_id varchar nullable`, `amount numeric`, `status varchar`, `paid_at timestamp nullable`; DB check permits `pending,paid,failed,refunded`.
- `users`: `id uuid`, `email`, `full_name`, `phone`, `avatar`, `created_at`, `password_hash`. No `last_login_at` column was present.
- No `notifications` table was present.

SQL/runtime mismatches that affect integration:

1. Register omits `users.id`; database metadata shows no UUID default and no users trigger. Login updates absent `users.last_login_at`. Both auth writes need source/schema alignment.
2. Notifications route expects `message`; `migrations/001_create_notifications.sql` defines `content`; schema has no table. Mock payment success performs notification insert in the same transaction and therefore fails until aligned/applied.
3. The notification migration is a source file, not evidence it has been applied. Do not treat the notification endpoints as verified operational APIs.

Other endpoints are documented as implemented source handlers, but they have not all been exercised end-to-end against production. `npm test` only covers auth using test doubles, not production database behavior.

## 6. Errors and Postman

Common known codes: `400` request/body validation; `401` missing/invalid/expired JWT (or bad login credentials); `403` review booking eligibility or mock mode disabled; `404` resource absent/not owned; `409` duplicate/state conflict/availability conflict; `500` DB or unhandled server error. `requireAuth` also returns 500 if `JWT_SECRET` is unset. Malformed JSON gets global `400 {success:false,message:"Invalid JSON request body"}`. Error message text is not uniform, and no stable error code field exists.

Postman setup: collection variable `baseUrl` set to the provided URL; set JSON content type for bodies; use Bearer Token only on routes marked JWT. Login/register mutate user data; booking/payment/favorite/review routes mutate records. Use disposable test accounts and a non-production environment for mutation flows. Do not send real payment data. No Postman collection has been inspected, and no production request was made.

Safe smoke flow on a test environment after addressing blockers: register/login; list hotels and room types; query availability; create booking; verify booking detail/history; create QR payment; get QR text; simulate failure and check pending booking; then, only after notifications schema/source are corrected, simulate success and inspect payment, booking, notification. Check ownership with a second test user and expect 404.

## 7. Configuration names (values omitted)

`src/config/db.js` reads `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` and enables SSL with `rejectUnauthorized:false`. JWT middleware reads `JWT_SECRET`. Mock simulate checks `PAYMENT_MODE=mock`. No values from `.env` are included here. FCM configuration was not found in inspected source.

## 8. Related files

- [OpenAPI description](openapi.yaml)
- [Flutter integration guide](FLUTTER_AI_INTEGRATION_GUIDE.md)
- [Implementation prompt](IMPLEMENT_FLUTTER_API_PROMPT.md)
- Routes: `src/routes/*.js`; mounting/auth: `src/app.js`, `src/middleware/auth.js`; DB connection: `src/config/db.js`; notification migration: `migrations/001_create_notifications.sql`.
