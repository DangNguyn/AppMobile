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
          .map((e) => '${e['image_url'] ?? ''}')
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
          String? voucherCode}) async =>
      Booking.fromJson(
          _data(await client.post('/api/bookings', auth: true, body: {
        'hotel_id': hotelId,
        'room_ids': roomIds,
        'check_in': checkIn,
        'check_out': checkOut,
        'adults': adults,
        'children': children,
        if (voucherCode != null) 'voucher_code': voucherCode,
      })));
  Future<List<Booking>> bookings() async =>
      _items(await client.get('/api/bookings', auth: true))
          .map(Booking.fromJson)
          .toList();
  Future<Booking> booking(String id) async => Booking.fromJson(
      _data(await client.get('/api/bookings/$id', auth: true)));
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
          {required String bookingId,
          required String method,
          required double amount}) async =>
      Payment.fromJson(_data(await client.post('/api/payments',
          auth: true,
          body: {
            'booking_id': bookingId,
            'payment_method': method,
            'amount': amount
          })));

  Future<List<Voucher>> vouchers() async =>
      _items(await client.get('/api/vouchers'))
          .map(Voucher.fromJson)
          .toList();

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
