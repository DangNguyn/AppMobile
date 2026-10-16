part of 'booking_app.dart';

class RoomDetailPage extends StatefulWidget {
  final String hotelName;
  final String? hotelId;
  final RoomType? roomType;
  final HotelSearchSelection selection;

  const RoomDetailPage({
    super.key,
    required this.hotelName,
    required this.selection,
    this.hotelId,
    this.roomType,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final PageController _imageController = PageController();
  int _selectedImageIndex = 0;
  List<String> _apiImages = const [];
  List<Room> _availableRooms = const [];
  VoucherValidation? _priceVoucher;
  Future<List<HotelAmenity>>? _hotelAmenitiesRequest;
  bool _availabilityLoaded = false;
  bool _availabilityFailed = false;
  List<String> get _images => _apiImages;

  int get _nights => widget.selection.dateRange.duration.inDays.clamp(1, 365);
  double get _nightlyPrice => widget.roomType?.basePrice ?? 0;
  double get _subtotal => _nightlyPrice * _nights * widget.selection.roomCount;

  @override
  void initState() {
    super.initState();
    _loadRoomImages();
    _loadPriceDetails();
    final hotelId = widget.hotelId;
    if (hotelId != null && hotelId.isNotEmpty) {
      _hotelAmenitiesRequest = apiRepository.hotelAmenities(hotelId);
    }
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _loadPriceDetails() async {
    final hotelId = widget.hotelId;
    final roomTypeId = widget.roomType?.id;
    if (hotelId == null || hotelId.isEmpty || roomTypeId == null) return;

    try {
      final rooms = await apiRepository.availableRooms(
        hotelId: hotelId,
        checkIn: _dateOnly(widget.selection.dateRange.start),
        checkOut: _dateOnly(widget.selection.dateRange.end),
        roomTypeId: roomTypeId,
      );
      if (mounted) {
        setState(() {
          _availableRooms = rooms;
          _availabilityLoaded = true;
        });
      }
    } on ApiException {
      if (mounted) {
        setState(() {
          _availabilityLoaded = true;
          _availabilityFailed = true;
        });
      }
    }

    if (_subtotal <= 0) return;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final vouchers = await apiRepository.vouchers();
      for (final voucher in vouchers) {
        final starts = voucher.startDate;
        final ends = voucher.endDate;
        final validNow = voucher.status == 'active' &&
            starts != null &&
            ends != null &&
            !today.isBefore(DateTime(starts.year, starts.month, starts.day)) &&
            !today.isAfter(DateTime(ends.year, ends.month, ends.day)) &&
            _subtotal >= voucher.minOrder;
        if (!validNow) continue;
        try {
          final validation = await apiRepository.validateVoucher(
            code: voucher.code,
            subtotal: _subtotal,
          );
          if (mounted) setState(() => _priceVoucher = validation);
          break;
        } on ApiException {
          // The API decides whether each voucher can be used for this price.
        }
      }
    } on ApiException {
      // Keep the room price visible if the voucher service is unavailable.
    }
  }

  String _formatVnd(num amount) {
    final digits = amount.round().toString();
    final formatted = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write('.');
      }
      formatted.write(digits[index]);
    }
    return '${formatted.toString()} ₫';
  }

  Widget _buildRoomPriceCard() {
    final voucher = _priceVoucher;
    final discount = voucher?.discountAmount ?? 0;
    final total = voucher?.totalAmount ?? _subtotal;
    final availableCount = _availableRooms.length;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1674C5).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            if (_images.isNotEmpty)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 2.4, sigmaY: 2.4),
                  child: Opacity(
                    opacity: 0.56,
                    child: Image.network(
                      _images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            const Positioned.fill(
              child: ColoredBox(color: Color(0x4DFFFFFF)),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF).withValues(alpha: 0.48),
                border: Border.all(color: const Color(0xFFD3E4F2)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.sell_outlined,
                          color: Color(0xFF1674C5), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text('Giá phòng',
                              style: TextStyle(
                                  color: Color(0xFF19232D),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700))),
                      if (_availabilityLoaded)
                        Text(
                          _availabilityFailed
                              ? 'Chưa kiểm tra được'
                              : availableCount > 0
                                  ? 'Còn $availableCount phòng'
                                  : 'Hết phòng',
                          style: TextStyle(
                              color: _availabilityFailed
                                  ? const Color(0xFF6D747B)
                                  : availableCount > 0
                                      ? const Color(0xFFE55B5B)
                                      : const Color(0xFF6D747B),
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    if (_nightlyPrice > 0)
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('${_formatVnd(_nightlyPrice)}/đêm',
                                      style: const TextStyle(
                                          color: Color(0xFFF05A28),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(
                                      '$_nights đêm · ${widget.selection.roomCount} phòng',
                                      style: const TextStyle(
                                          color: Color(0xFF727B84),
                                          fontSize: 11)),
                                ])),
                          ])
                    else
                      const Text('Giá phòng chưa được cung cấp.',
                          style: TextStyle(
                              color: Color(0xFF6D747B), fontSize: 13)),
                    if (discount > 0 && voucher != null) ...[
                      const SizedBox(height: 7),
                      Text('Tạm tính: ${_formatVnd(_subtotal)}',
                          style: const TextStyle(
                              color: Color(0xFF727B84),
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFDDF2FF),
                            borderRadius: BorderRadius.circular(9)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.local_offer_rounded,
                              color: Color(0xFF1674C5), size: 15),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Voucher ${voucher.voucher.code} · Giảm ${_formatVnd(discount)}',
                              style: const TextStyle(
                                color: Color(0xFF145A91),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 5),
                      Text('Tổng sau giảm: ${_formatVnd(total)}',
                          style: const TextStyle(
                              color: Color(0xFFF05A28),
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text('Tạm tính: ${_formatVnd(_subtotal)}',
                          style: const TextStyle(
                              color: Color(0xFF19232D),
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenities() => FutureBuilder<List<HotelAmenity>>(
        future: _hotelAmenitiesRequest,
        builder: (context, snapshot) {
          final amenities = snapshot.data ?? const <HotelAmenity>[];
          if (amenities.isEmpty) {
            return Text(
              snapshot.hasError
                  ? 'Chưa tải được tiện ích từ khách sạn.'
                  : 'Tiện ích khách sạn chưa được cập nhật.',
              style: const TextStyle(color: Color(0xFF6D747B), fontSize: 12),
            );
          }
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final amenity in amenities)
                _RoomAmenityItem(
                  icon: _amenityIcon(amenity.name),
                  label: amenity.name,
                  dense: true,
                ),
            ],
          );
        },
      );

  IconData _amenityIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('wifi') || value.contains('wi-fi')) {
      return Icons.wifi_rounded;
    }
    if (value.contains('pool') || value.contains('hồ bơi')) {
      return Icons.pool_outlined;
    }
    if (value.contains('gym') || value.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }
    if (value.contains('parking') || value.contains('đậu xe')) {
      return Icons.local_parking_rounded;
    }
    if (value.contains('restaurant') || value.contains('nhà hàng')) {
      return Icons.restaurant_outlined;
    }
    if (value.contains('air') || value.contains('máy lạnh')) {
      return Icons.ac_unit_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  Future<void> _loadRoomImages() async {
    final id = widget.roomType?.id;
    if (id == null || id.isEmpty) return;
    try {
      final images = await apiRepository.roomTypeImages(id);
      if (mounted) setState(() => _apiImages = images);
    } on ApiException {
      // Room gallery only shows images linked to this room type.
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _showImage(int index) {
    _imageController.animateToPage(
      index,
      duration: AppMotion.interactionDuration,
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
                    itemCount: _images.isEmpty ? 1 : _images.length,
                    onPageChanged: (index) {
                      setState(() => _selectedImageIndex = index);
                    },
                    itemBuilder: (context, index) => _images.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFFE8EEF3),
                            child: Center(
                              child: Icon(
                                Icons.bed_rounded,
                                color: Color(0xFF7896AA),
                                size: 76,
                              ),
                            ),
                          )
                        : Image.network(
                            _images[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const ColoredBox(
                                color: Color(0xFFE8EEF3),
                                child: Center(
                                  child: AppLoadingIndicator(size: 24),
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
                        onPressed:
                            _images.length < 2 || _selectedImageIndex == 0
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
                        onPressed: _images.length < 2 ||
                                _selectedImageIndex == _images.length - 1
                            ? null
                            : () => _showImage(_selectedImageIndex + 1),
                      ),
                    ),
                  ),
                  if (_images.length > 1)
                    Positioned(
                      left: 14,
                      bottom: 12,
                      child: Row(
                        children: [
                          for (var index = 0; index < _images.length; index++)
                            AnimatedContainer(
                              duration: AppMotion.interactionDuration,
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
                  if (_images.isNotEmpty)
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
                          '${_selectedImageIndex + 1}/${_images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
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
                Text(
                  widget.roomType?.name ?? 'Chi tiết phòng',
                  style: TextStyle(
                    color: Color(0xFF19232D),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoomDetailTag(
                      icon: Icons.people_alt_outlined,
                      label: 'Tối đa ${widget.roomType?.maxGuests ?? 0} khách',
                    ),
                    _RoomDetailTag(
                      icon: Icons.square_foot_rounded,
                      label: widget.roomType?.description.isNotEmpty == true
                          ? widget.roomType!.description
                          : 'Hạng phòng tiêu chuẩn',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _RoomDetailInfoRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Ngày lưu trú',
                  value:
                      '${dateRange.start.day}/${dateRange.start.month} - ${dateRange.end.day}/${dateRange.end.month} (${dateRange.duration.inDays} đêm)',
                ),
                const SizedBox(height: 4),
                _RoomDetailInfoRow(
                  icon: Icons.people_alt_outlined,
                  label: 'Số khách',
                  value:
                      '${widget.selection.roomCount} phòng · $guestCount khách',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
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
                  'Tiện ích khách sạn',
                  style: TextStyle(
                    color: Color(0xFF19232D),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildAmenities(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildRoomPriceCard(),
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
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomType?.name ?? 'Chi tiết phòng',
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
                      '${widget.selection.adultCount + widget.selection.childCount} khách · ${widget.selection.roomCount} phòng',
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
                      hotelId: widget.hotelId,
                      roomType: widget.roomType,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0E1F38),
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
