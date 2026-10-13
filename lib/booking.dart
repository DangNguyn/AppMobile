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
    _bookings = apiRepository.bookings();
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
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${snapshot.error}'),
                      TextButton(
                        onPressed: () => setState(() => _bookings = apiRepository.bookings()),
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
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.hotel_outlined),
                      title: Text(booking.bookingCode ?? booking.id),
                      subtitle: Text('${booking.checkIn} - ${booking.checkOut}'),
                      trailing: Text(booking.status),
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
