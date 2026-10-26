import 'api_client.dart';
import 'models.dart';

class ApiRepository {
  ApiRepository({ApiClient? client}) : client = client ?? ApiClient();
  final ApiClient client;

  Map<String, dynamic> _data(dynamic response) =>
      response is Map<String, dynamic> &&
              response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
  List<Map<String, dynamic>> _items(dynamic response) {
    final value = response is Map ? response['data'] : null;
    return value is List
        ? value.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  Future<ApiUser> login(String email, String password) async {
    final response = await client
        .post('/api/auth/login', body: {'email': email, 'password': password});
    final map = response as Map<String, dynamic>;
    final token = map['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException(
          500, 'Phản hồi đăng nhập không có token hợp lệ.');
    }
    await client.saveToken(token);
    return ApiUser.fromJson(
        (map['data'] as Map?)?.cast<String, dynamic>() ?? {});
  }

  Future<ApiUser> register(
      {required String email,
      required String password,
      required String fullName,
      required String phone}) async {
    final response = await client.post('/api/auth/register', body: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
    });
    return ApiUser.fromJson(
        (response['user'] as Map?)?.cast<String, dynamic>() ?? {});
  }

  Future<ApiUser> me() async =>
      ApiUser.fromJson(_data(await client.get('/api/auth/me', auth: true)));

  Future<ApiUser> currentUserProfile() async => ApiUser.fromJson(
        _data(await client.get('/api/users/me', auth: true)),
      );

  Future<ApiUser> updatePrivateProfile(bool isPrivate) async =>
      ApiUser.fromJson(
        _data(
          await client.put(
            '/api/users/me',
            auth: true,
            body: {'is_private': isPrivate},
          ),
        ),
      );

  Future<List<ApiUserSearchResult>> searchUsers(String query) async {
    final response = await client.get('/api/users/search', auth: true, query: {
      'q': query.trim(),
    });
    return _items(response).map(ApiUserSearchResult.fromJson).toList();
  }

  Future<List<ApiPost>> myPosts({int page = 1, int limit = 20}) async {
    final response = await client.get('/api/posts/mine', auth: true, query: {
      'page': '$page',
      'limit': '$limit',
    });
    return _items(response)
        .map(ApiPost.fromJson)
        .where((post) => post.status == 'published')
        .toList();
  }

  Future<List<ApiPost>> postsByUser(String userId,
      {int page = 1, int limit = 20}) async {
    final response = await client.get('/api/posts/users/$userId', query: {
      'page': '$page',
      'limit': '$limit',
    });
    return _items(response).map(ApiPost.fromJson).toList();
  }

  Future<ApiPost> createPost({
    required String title,
    required String location,
    required int rating,
    required String content,
  }) async =>
      ApiPost.fromJson(_data(await client.post('/api/posts', auth: true, body: {
        'title': title,
        'location': location,
        'rating': rating,
        'content': content,
      })));

  Future<void> deletePost(String postId) async {
    await client.delete('/api/posts/$postId', auth: true);
  }

  Future<ApiUser> updateCurrentUser({
    required String fullName,
    required String phone,
    String? email,
  }) async =>
      ApiUser.fromJson(
          _data(await client.put('/api/users/me', auth: true, body: {
        'full_name': fullName,
        'phone': phone,
        if (email != null) 'email': email,
      })));
  Future<void> logout() async {
    try {
      await client.post('/api/auth/logout', auth: true);
    } finally {
      await client.clearToken();
    }
  }

  Future<List<Hotel>> hotels() async =>
      _items(await client.get('/api/hotels')).map(Hotel.fromJson).toList();
  Future<Hotel> hotel(String id) async =>
      Hotel.fromJson(_data(await client.get('/api/hotels/$id')));
  Future<List<RoomType>> roomTypes(String hotelId) async =>
      _items(await client.get('/api/hotels/$hotelId/room-types'))
          .map(RoomType.fromJson)
          .toList();
  Future<RoomType> roomType(String id) async =>
      RoomType.fromJson(_data(await client.get('/api/room-types/$id')));
  Future<List<String>> roomTypeImages(String id) async =>
      _items(await client.get('/api/room-types/$id/images'))
          .map((e) => '${e['image_url'] ?? ''}')
          .where((e) => e.isNotEmpty)
          .toList();
  Future<List<HotelAmenity>> hotelAmenities(String hotelId) async =>
      _items(await client.get('/api/hotels/$hotelId/amenities'))
          .map(HotelAmenity.fromJson)
          .toList();
  Future<List<HotelAmenity>> hotelVibes(String hotelId) async =>
      _items(await client.get('/api/hotels/$hotelId/vibes'))
          .map(HotelAmenity.fromJson)
          .toList();
  Future<List<Room>> availableRooms(
          {required String hotelId,
          required String checkIn,
          required String checkOut,
          String? roomTypeId}) async =>
      _items(await client.get('/api/rooms/available', query: {
        'hotel_id': hotelId,
        'check_in': checkIn,
        'check_out': checkOut,
        if (roomTypeId != null) 'room_type_id': roomTypeId,
      }))
          .map(Room.fromJson)
          .toList();
  Future<List<Room>> roomsForType(String id) async =>
      _items(await client.get('/api/room-types/$id/rooms'))
          .map(Room.fromJson)
          .toList();
  Future<List<String>> hotelImages(String id) async =>
      _items(await client.get('/api/hotels/$id/images'))
          .map((e) => '${e['image_url'] ?? ''}'.trim())
          .where((e) => e.isNotEmpty)
          .toList();
  Future<List<Review>> reviews(String hotelId) async =>
      _items(await client.get('/api/hotels/$hotelId/reviews'))
          .map(Review.fromJson)
          .toList();

  Future<Booking> createBooking(
          {required String hotelId,
          required List<String> roomIds,
          required String checkIn,
          required String checkOut,
          required int adults,
          int children = 0,
          required String bookingEmail,
          String? voucherCode}) async =>
      Booking.fromJson(
          _data(await client.post('/api/bookings', auth: true, body: {
        'hotel_id': hotelId,
        'room_ids': roomIds,
        'check_in': checkIn,
        'check_out': checkOut,
        'adults': adults,
        'children': children,
        'booking_email': bookingEmail,
        if (voucherCode != null) 'voucher_code': voucherCode,
      })));
  Future<List<Booking>> bookings() async =>
      _items(await client.get('/api/bookings', auth: true))
          .map(Booking.fromJson)
          .toList();
  Future<List<BookingGuest>> bookingGuests(String bookingId) async =>
      _items(await client.get('/api/bookings/$bookingId/guests', auth: true))
          .map(BookingGuest.fromJson)
          .toList();
  Future<BookingGuest> addBookingGuest({
    required String bookingId,
    required String fullName,
    required String phone,
    required String email,
  }) async =>
      BookingGuest.fromJson(_data(await client.post(
        '/api/bookings/$bookingId/guests',
        auth: true,
        body: {
          'full_name': fullName,
          'phone': phone,
          'email': email,
        },
      )));
  Future<Booking> booking(String id) async => Booking.fromJson(
      _data(await client.get('/api/bookings/$id', auth: true)));
  Future<Map<String, dynamic>> bookingQr(String id) async =>
      _data(await client.get('/api/bookings/$id/qr', auth: true));
  Future<Booking> cancelBooking(String id) async => Booking.fromJson(
      _data(await client.patch('/api/bookings/$id/cancel', auth: true)));
  Future<List<FavoriteHotel>> favorites() async =>
      _items(await client.get('/api/favorites', auth: true))
          .map(FavoriteHotel.fromJson)
          .toList();
  Future<void> addFavorite(String hotelId) async {
    await client.post('/api/favorites/$hotelId', auth: true);
  }

  Future<void> removeFavorite(String hotelId) async {
    await client.delete('/api/favorites/$hotelId', auth: true);
  }

  Future<Review> addReview(
          {required String hotelId,
          required String bookingId,
          required int rating,
          String? comment}) async =>
      Review.fromJson(_data(
          await client.post('/api/hotels/$hotelId/reviews', auth: true, body: {
        'booking_id': bookingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      })));
  Future<List<Payment>> payments(String bookingId) async =>
      _items(await client.get('/api/bookings/$bookingId/payments', auth: true))
          .map(Payment.fromJson)
          .toList();
  Future<Payment> createPayment(
          {required String bookingId, required String method}) async =>
      Payment.fromJson(
          _data(await client.post('/api/payments', auth: true, body: {
        'booking_id': bookingId,
        'payment_method': method,
      })));
  Future<Map<String, dynamic>> paymentQr(String paymentId) async =>
      _data(await client.get('/api/payments/$paymentId/qr', auth: true));
  Future<Payment> payment(String paymentId) async {
    final response = await client.get('/api/payments/$paymentId', auth: true);
    final data = _data(response);
    if (response is Map && response['email'] is Map) {
      data['email_status'] = (response['email'] as Map)['status'];
    }
    return Payment.fromJson(data);
  }

  Future<Payment> simulatePayment({
    required String paymentId,
    required String result,
  }) async {
    final response = await client.post(
      '/api/payments/$paymentId/simulate',
      auth: true,
      body: {'result': result},
    );
    final data = _data(response);
    if (response is Map && response['email'] is Map) {
      final email = (response['email'] as Map).cast<String, dynamic>();
      data['email_status'] = email['status'];
    }
    return Payment.fromJson(data);
  }

  Future<List<Voucher>> vouchers() async =>
      _items(await client.get('/api/vouchers')).map(Voucher.fromJson).toList();

  Future<Voucher> voucher(String code) async => Voucher.fromJson(
        _data(await client.get('/api/vouchers/${Uri.encodeComponent(code)}')),
      );

  Future<VoucherValidation> validateVoucher({
    required String code,
    required double subtotal,
  }) async =>
      VoucherValidation.fromJson(
        _data(
          await client.post(
            '/api/vouchers/validate',
            body: {'code': code, 'subtotal': subtotal},
          ),
        ),
      );
}

final apiRepository = ApiRepository();
