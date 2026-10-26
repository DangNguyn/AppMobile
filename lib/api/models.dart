class ApiUser {
  const ApiUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.avatar,
    this.createdAt,
    this.isPrivate = false,
  });

  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String? avatar;
  final DateTime? createdAt;
  final bool isPrivate;

  factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
        id: '${json['id'] ?? ''}',
        email: '${json['email'] ?? ''}',
        fullName: '${json['full_name'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
        avatar: json['avatar'] as String?,
        createdAt: _date(json['created_at']),
        isPrivate: json['is_private'] == true,
      );
}

class ApiUserSearchResult {
  const ApiUserSearchResult({
    required this.id,
    required this.fullName,
    this.avatar,
    this.username,
    this.isPrivate,
    this.bio,
  });

  final String id;
  final String fullName;
  final String? avatar;
  final String? username;
  final bool? isPrivate;
  final String? bio;

  factory ApiUserSearchResult.fromJson(Map<String, dynamic> json) =>
      ApiUserSearchResult(
        id: '${json['id'] ?? ''}',
        fullName: '${json['full_name'] ?? ''}',
        avatar: json['avatar'] as String?,
        username: json['username'] as String?,
        isPrivate: json['is_private'] is bool
            ? json['is_private'] as bool
            : null,
        bio: json['bio'] as String?,
      );
}

class ApiPost {
  const ApiPost({
    required this.id,
    required this.title,
    required this.location,
    required this.rating,
    required this.content,
    this.status = 'published',
    this.authorName,
    this.authorAvatar,
    this.createdAt,
  });

  final String id;
  final String title;
  final String location;
  final int rating;
  final String content;
  final String status;
  final String? authorName;
  final String? authorAvatar;
  final DateTime? createdAt;

  factory ApiPost.fromJson(Map<String, dynamic> json) => ApiPost(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        location: '${json['location'] ?? ''}',
        rating: _integer(json['rating']),
        content: '${json['content'] ?? ''}',
        status: '${json['status'] ?? 'published'}',
        authorName: json['author_name'] as String?,
        authorAvatar: json['author_avatar'] as String?,
        createdAt: _date(json['created_at']),
      );
}

class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    this.description = '',
    this.address = '',
    this.city = '',
    this.latitude,
    this.longitude,
    this.starRating,
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final double? starRating;

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? 'Khách sạn'}',
        description: '${json['description'] ?? ''}',
        address: '${json['address'] ?? ''}',
        city: '${json['city'] ?? ''}',
        latitude: _number(json['latitude']),
        longitude: _number(json['longitude']),
        starRating: _number(json['star_rating']),
      );
}

class HotelAmenity {
  const HotelAmenity({
    required this.id,
    required this.name,
    this.description = '',
  });

  final String id;
  final String name;
  final String description;

  factory HotelAmenity.fromJson(Map<String, dynamic> json) => HotelAmenity(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
      );
}

class RoomType {
  const RoomType({
    required this.id,
    required this.hotelId,
    required this.name,
    this.description = '',
    this.maxGuests = 0,
    this.basePrice = 0,
  });

  final String id;
  final String hotelId;
  final String name;
  final String description;
  final int maxGuests;
  final double basePrice;

  factory RoomType.fromJson(Map<String, dynamic> json) => RoomType(
        id: '${json['id'] ?? ''}',
        hotelId: '${json['hotel_id'] ?? ''}',
        name: '${json['name'] ?? 'Loại phòng'}',
        description: '${json['description'] ?? ''}',
        maxGuests: _integer(json['max_guests']),
        basePrice: _number(json['base_price']) ?? 0,
      );
}

class Room {
  const Room({
    required this.id,
    required this.hotelId,
    required this.roomTypeId,
    required this.roomNumber,
    this.status = '',
    this.roomTypeName,
    this.maxGuests,
    this.basePrice,
  });

  final String id;
  final String hotelId;
  final String roomTypeId;
  final String roomNumber;
  final String status;
  final String? roomTypeName;
  final int? maxGuests;
  final double? basePrice;

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: '${json['id'] ?? ''}',
        hotelId: '${json['hotel_id'] ?? ''}',
        roomTypeId: '${json['room_type_id'] ?? ''}',
        roomNumber: '${json['room_number'] ?? ''}',
        status: '${json['status'] ?? ''}',
        roomTypeName: json['room_type_name'] as String?,
        maxGuests:
            json['max_guests'] == null ? null : _integer(json['max_guests']),
        basePrice: _number(json['base_price']),
      );
}

class Booking {
  const Booking({
    required this.id,
    required this.hotelId,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.status,
    this.bookingCode,
    this.totalAmount,
    this.qrToken,
    this.createdAt,
    this.rooms = const [],
    this.hotelName,
    this.roomTypeName,
    this.guest,
    this.paymentStatus,
    this.paymentMethod,
    this.bookingEmail,
  });

  final String id;
  final String hotelId;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final String status;
  final String? bookingCode;
  final double? totalAmount;
  final String? qrToken;
  final DateTime? createdAt;
  final List<BookingRoom> rooms;
  final String? hotelName;
  final String? roomTypeName;
  final BookingGuest? guest;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? bookingEmail;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: '${json['id'] ?? ''}',
        hotelId: '${json['hotel_id'] ?? ''}',
        checkIn: '${json['check_in'] ?? ''}',
        checkOut: '${json['check_out'] ?? ''}',
        adults: _integer(json['adults']),
        children: _integer(json['children']),
        status: '${json['status'] ?? 'unknown'}',
        bookingCode: json['booking_code'] as String?,
        totalAmount: _number(json['total_amount']),
        qrToken: json['qr_token'] as String?,
        createdAt: _date(json['created_at']),
        rooms: _list(json['rooms']).map(BookingRoom.fromJson).toList(),
        hotelName: json['hotel_name'] as String?,
        roomTypeName: json['room_type_name'] as String?,
        guest: json['guest'] is Map
            ? BookingGuest.fromJson(
                (json['guest'] as Map).cast<String, dynamic>())
            : null,
        paymentStatus: json['payment_status'] as String?,
        paymentMethod: json['payment_method'] as String?,
        bookingEmail: json['booking_email'] as String?,
      );

  Booking copyWith({
    List<BookingRoom>? rooms,
    String? hotelName,
    String? roomTypeName,
    BookingGuest? guest,
    String? paymentStatus,
    String? paymentMethod,
    String? bookingEmail,
  }) =>
      Booking(
        id: id,
        hotelId: hotelId,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        children: children,
        status: status,
        bookingCode: bookingCode,
        totalAmount: totalAmount,
        qrToken: qrToken,
        createdAt: createdAt,
        rooms: rooms ?? this.rooms,
        hotelName: hotelName ?? this.hotelName,
        roomTypeName: roomTypeName ?? this.roomTypeName,
        guest: guest ?? this.guest,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        bookingEmail: bookingEmail ?? this.bookingEmail,
      );
}

class BookingGuest {
  const BookingGuest({
    required this.fullName,
    this.phone,
    this.email,
  });

  final String fullName;
  final String? phone;
  final String? email;

  factory BookingGuest.fromJson(Map<String, dynamic> json) => BookingGuest(
        fullName: '${json['full_name'] ?? ''}',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );
}

class BookingRoom {
  const BookingRoom({
    required this.roomId,
    this.roomNumber,
    this.roomTypeId,
    this.roomType,
    this.subtotal,
  });

  final String roomId;
  final String? roomNumber;
  final String? roomTypeId;
  final String? roomType;
  final double? subtotal;

  factory BookingRoom.fromJson(Map<String, dynamic> json) => BookingRoom(
        roomId: '${json['room_id'] ?? ''}',
        roomNumber: json['room_number'] as String?,
        roomTypeId: json['room_type_id'] as String?,
        roomType: json['room_type'] as String?,
        subtotal: _number(json['subtotal']),
      );
}

class FavoriteHotel extends Hotel {
  const FavoriteHotel({
    required super.id,
    required super.name,
    super.description,
    super.address,
    super.city,
    super.starRating,
  });

  factory FavoriteHotel.fromJson(Map<String, dynamic> json) => FavoriteHotel(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? 'Khách sạn'}',
        description: '${json['description'] ?? ''}',
        address: '${json['address'] ?? ''}',
        city: '${json['city'] ?? ''}',
        starRating: _number(json['star_rating']),
      );
}

class Review {
  const Review({
    required this.id,
    required this.hotelId,
    required this.rating,
    this.comment,
    this.fullName,
    this.createdAt,
  });

  final String id;
  final String hotelId;
  final int rating;
  final String? comment;
  final String? fullName;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: '${json['id'] ?? ''}',
        hotelId: '${json['hotel_id'] ?? ''}',
        rating: _integer(json['rating']),
        comment: json['comment'] as String?,
        fullName: json['full_name'] as String?,
        createdAt: _date(json['created_at']),
      );
}

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    this.paidAt,
    this.emailStatus,
  });

  final String id;
  final String bookingId;
  final double amount;
  final String status;
  final String paymentMethod;
  final String? transactionId;
  final DateTime? paidAt;
  final String? emailStatus;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: '${json['id'] ?? ''}',
        bookingId: '${json['booking_id'] ?? ''}',
        amount: _number(json['amount']) ?? 0,
        status: '${json['status'] ?? 'unknown'}',
        paymentMethod: '${json['payment_method'] ?? ''}',
        transactionId: json['transaction_id'] as String?,
        paidAt: _date(json['paid_at']),
        emailStatus: json['email_status'] as String?,
      );
}

class Voucher {
  const Voucher({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrder,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        id: '${json['id'] ?? ''}',
        code: '${json['code'] ?? ''}',
        discountType: '${json['discount_type'] ?? ''}',
        discountValue: _number(json['discount_value']) ?? 0,
        minOrder: _number(json['min_order']) ?? 0,
        startDate: _date(json['start_date']),
        endDate: _date(json['end_date']),
        status: '${json['status'] ?? ''}',
      );
}

class VoucherValidation {
  const VoucherValidation({
    required this.voucher,
    required this.discountAmount,
    required this.totalAmount,
  });

  final Voucher voucher;
  final double discountAmount;
  final double totalAmount;

  factory VoucherValidation.fromJson(Map<String, dynamic> json) =>
      VoucherValidation(
        voucher: Voucher.fromJson(
          (json['voucher'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
        discountAmount: _number(json['discount_amount']) ?? 0,
        totalAmount: _number(json['total_amount']) ?? 0,
      );
}

double? _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value');
int _integer(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse('$value');
List<Map<String, dynamic>> _list(dynamic value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];
