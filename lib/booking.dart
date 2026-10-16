part of 'booking_app.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late Future<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = _loadBookings();
  }

  Future<List<Booking>> _loadBookings() async {
    final bookings = await apiRepository.bookings();
    return Future.wait(bookings.map((booking) async {
      final results = await Future.wait([
        apiRepository.booking(booking.id),
        apiRepository.hotel(booking.hotelId),
        apiRepository.bookingGuests(booking.id),
      ]);
      final detail = results[0] as Booking;
      final hotel = results[1] as Hotel;
      final guests = results[2] as List<BookingGuest>;
      String? roomTypeName;
      final roomTypeId =
          detail.rooms.isEmpty ? null : detail.rooms.first.roomTypeId;
      if (roomTypeId != null) {
        roomTypeName = (await apiRepository.roomType(roomTypeId)).name;
      }
      return booking.copyWith(
        rooms: detail.rooms,
        hotelName: hotel.name,
        roomTypeName: roomTypeName,
        guest: guests.isEmpty ? null : guests.first,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            18,
            MediaQuery.of(context).padding.top + 12,
            18,
            16,
          ),
          color: const Color(0xFF0E1F38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Color(0xFF7F8790),
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tìm kiếm mặt hàng, điểm đến...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF858B91),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  const DiscountIconButton(),
                  const SizedBox(width: 18),
                  const CustomerSupportIconButton(),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Đặt chỗ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_outlined,
                      color: Color(0xFF2A6EEB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Tất cả giao dịch',
                          style: TextStyle(
                            color: Color(0xFF2A6EEB),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFF2A6EEB),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Booking>>(
            future: _bookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AppLoadingIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${snapshot.error}'),
                      TextButton(
                        onPressed: () =>
                            setState(() => _bookings = _loadBookings()),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              final bookings = snapshot.data ?? const <Booking>[];
              if (bookings.isEmpty) {
                return const Center(child: Text('Bạn chưa có đặt chỗ nào.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                itemCount: bookings.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _BookingCard(
                    booking: booking,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BookingDetailPage(booking: booking),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _bookingStatus(booking.status);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hotel_outlined, color: Color(0xFF1674C5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      booking.hotelName ?? 'Khách sạn',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 10),
              Text(booking.roomTypeName ?? 'Phòng đã đặt'),
              const SizedBox(height: 6),
              Text('${booking.checkIn} - ${booking.checkOut}'),
              const SizedBox(height: 6),
              Text(
                'Tổng thanh toán: ${_formatBookingMoney(booking.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (booking.guest != null) ...[
                const SizedBox(height: 6),
                Text(
                    '${booking.guest!.fullName} · ${booking.guest!.phone ?? ''}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final status = _bookingStatus(booking.status);
    final guest = booking.guest;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn đặt phòng')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(booking.hotelName ?? 'Khách sạn',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(booking.roomTypeName ?? 'Phòng đã đặt'),
          const Divider(height: 28),
          _detailLine('Mã đặt phòng', booking.bookingCode ?? booking.id),
          _detailLine('Lịch trình', '${booking.checkIn} - ${booking.checkOut}'),
          _detailLine(
              'Tổng thanh toán', _formatBookingMoney(booking.totalAmount)),
          _detailLine('Trạng thái', '${status.icon} ${status.label}'),
          if (guest != null) ...[
            const Divider(height: 28),
            const Text('Thông tin người đặt',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            _detailLine('Họ tên', guest.fullName),
            _detailLine('Số điện thoại', guest.phone ?? 'Chưa cập nhật'),
            _detailLine('Email', guest.email ?? 'Chưa cập nhật'),
          ],
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 135,
                child:
                    Text(label, style: const TextStyle(color: Colors.black54))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _BookingStatus {
  const _BookingStatus(this.label, this.icon, this.color);
  final String label;
  final String icon;
  final Color color;
}

_BookingStatus _bookingStatus(String value) {
  switch (value.toLowerCase()) {
    case 'confirmed':
      return const _BookingStatus('Đã xác nhận', '✓', Color(0xFF168A55));
    case 'cancelled':
      return const _BookingStatus('Đã hủy', '×', Color(0xFFC0392B));
    case 'completed':
      return const _BookingStatus('Hoàn tất', '✓', Color(0xFF1674C5));
    default:
      return const _BookingStatus('Chờ xác nhận', '⏳', Color(0xFFE08A00));
  }
}

String _formatBookingMoney(double? value) {
  final digits = (value ?? 0).round().toString();
  final formatted = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) formatted.write('.');
    formatted.write(digits[i]);
  }
  return '$formatted ₫';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _BookingStatus status;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text('${status.icon} ${status.label}',
              style: TextStyle(
                  color: status.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

class _BookingSectionHeading extends StatelessWidget {
  final String title;

  const _BookingSectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF202833),
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            18,
            MediaQuery.of(context).padding.top + 12,
            18,
            16,
          ),
          color: const Color(0xFF0E1F38),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Color(0xFF7F8790), size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tìm kiếm mặt hàng, điểm đến...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF858B91),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              const DiscountIconButton(),
              const SizedBox(width: 18),
              const CustomerSupportIconButton(),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF7F8FA),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
              children: const [
                _SavedProductsCard(),
                SizedBox(height: 18),
                _SavedCollectionsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedProductsCard extends StatelessWidget {
  const _SavedProductsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Xem tất cả sản phẩm đã lưu  →',
              style: TextStyle(
                color: Color(0xFF2A6EEB),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 145,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EDF2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EDF2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCollectionsCard extends StatelessWidget {
  const _SavedCollectionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 110,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.collections_bookmark_rounded,
                  color: Color(0xFF2A6EEB),
                  size: 64,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hãy sắp xếp các sản phẩm đã lưu!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF19232D),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tạo danh sách yêu thích và lên kế hoạch dễ dàng khi sắp xếp các sản phẩm đã lưu với Bộ sưu tập!',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF7D858D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Divider(height: 1, color: Color(0xFFD9DDE1)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Tạo bộ sưu tập mới',
              style: TextStyle(
                color: Color(0xFF2A6EEB),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
