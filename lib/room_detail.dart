part of 'booking_app.dart';

class RoomDetailPage extends StatefulWidget {
  final String hotelName;
  final HotelSearchSelection selection;

  const RoomDetailPage({
    super.key,
    required this.hotelName,
    required this.selection,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  static const _roomImages = [
    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=1200&q=85',
    'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=85',
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=85',
  ];

  final PageController _imageController = PageController();
  int _selectedImageIndex = 0;

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _showImage(int index) {
    _imageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = widget.selection.dateRange;
    final guestCount =
        widget.selection.adultCount + widget.selection.childCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF19232D),
        elevation: 0,
        title: const Text(
          'Chi tiết phòng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 230,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _imageController,
                    itemCount: _roomImages.length,
                    onPageChanged: (index) {
                      setState(() => _selectedImageIndex = index);
                    },
                    itemBuilder: (context, index) => Image.network(
                      _roomImages[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const ColoredBox(
                          color: Color(0xFFE8EEF3),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1674C5),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: Color(0xFFE8EEF3),
                            child: Center(
                              child: Icon(
                                Icons.bed_rounded,
                                color: Color(0xFF7896AA),
                                size: 76,
                              ),
                            ),
                          ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x99000000)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _RoomImageNavigationButton(
                        tooltip: 'Ảnh trước',
                        icon: Icons.chevron_left_rounded,
                        onPressed: _selectedImageIndex == 0
                            ? null
                            : () => _showImage(_selectedImageIndex - 1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _RoomImageNavigationButton(
                        tooltip: 'Ảnh tiếp theo',
                        icon: Icons.chevron_right_rounded,
                        onPressed: _selectedImageIndex == _roomImages.length - 1
                            ? null
                            : () => _showImage(_selectedImageIndex + 1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        for (var index = 0; index < _roomImages.length; index++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 5),
                            width: index == _selectedImageIndex ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: index == _selectedImageIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedImageIndex + 1}/${_roomImages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotelName,
                  style: const TextStyle(
                    color: Color(0xFF6D747B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Phòng Deluxe giường đôi',
                  style: TextStyle(
                    color: Color(0xFF19232D),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoomDetailTag(
                      icon: Icons.people_alt_outlined,
                      label: 'Tối đa 2 khách',
                    ),
                    _RoomDetailTag(
                      icon: Icons.bed_outlined,
                      label: '1 giường đôi',
                    ),
                    _RoomDetailTag(
                      icon: Icons.square_foot_rounded,
                      label: '32 m²',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin lưu trú',
                  style: TextStyle(
                    color: Color(0xFF19232D),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _RoomDetailInfoRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Ngày lưu trú',
                  value:
                      '${dateRange.start.day}/${dateRange.start.month} - ${dateRange.end.day}/${dateRange.end.month} (${dateRange.duration.inDays} đêm)',
                ),
                const SizedBox(height: 12),
                _RoomDetailInfoRow(
                  icon: Icons.people_alt_outlined,
                  label: 'Số khách',
                  value:
                      '${widget.selection.roomCount} phòng · $guestCount khách',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiện ích phòng',
                  style: TextStyle(
                    color: Color(0xFF19232D),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoomAmenityItem(
                      icon: Icons.wifi_rounded,
                      label: 'WiFi miễn phí',
                    ),
                    _RoomAmenityItem(
                      icon: Icons.ac_unit_rounded,
                      label: 'Máy lạnh',
                    ),
                    _RoomAmenityItem(
                      icon: Icons.shower_outlined,
                      label: 'Phòng tắm riêng',
                    ),
                    _RoomAmenityItem(
                      icon: Icons.tv_rounded,
                      label: 'TV màn hình phẳng',
                    ),
                    _RoomAmenityItem(
                      icon: Icons.desk_outlined,
                      label: 'Bàn làm việc',
                    ),
                    _RoomAmenityItem(
                      icon: Icons.coffee_maker_outlined,
                      label: 'Ấm đun nước',
                    ),
                    _RoomAmenityItem(
                      icon: Icons.dry_cleaning_outlined,
                      label: 'Máy sấy tóc',
                    ),
                    _RoomAmenityItem(
                      icon: Icons.kitchen_outlined,
                      label: 'Tủ lạnh mini',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF1674C5)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Giá và tình trạng phòng sẽ hiển thị tại đây.',
                    style: TextStyle(
                      color: Color(0xFF59636D),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng Deluxe giường đôi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF19232D),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2 khách · 1 giường đôi',
                      style: TextStyle(color: Color(0xFF6D747B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RoomBookingPage(
                      hotelName: widget.hotelName,
                      selection: widget.selection,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1674C5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Chọn phòng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingCoupon {
  final String code;
  final String title;
  final String description;
  final int? percentOff;
  final int? amountOff;

  const _BookingCoupon({
    required this.code,
    required this.title,
    required this.description,
    this.percentOff,
    this.amountOff,
  });

  int discountFor(int subtotal) {
    final discount = amountOff ?? subtotal * (percentOff ?? 0) ~/ 100;
    return discount.clamp(0, subtotal);
  }
}
