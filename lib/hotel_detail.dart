part of 'booking_app.dart';

class HotelDetailPage extends StatefulWidget {
  final HotelSearchSelection selection;
  final String hotelName;
  final String? hotelId;

  const HotelDetailPage({
    super.key,
    required this.selection,
    this.hotelName = 'Tên khách sạn',
    this.hotelId,
  });

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _RoomTypePreviewImage extends StatelessWidget {
  const _RoomTypePreviewImage({required this.request});

  final Future<List<String>>? request;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: request,
      builder: (context, snapshot) {
        final images = snapshot.data ?? const <String>[];
        if (images.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              images.first,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallbackImage(),
            ),
          );
        }
        return _fallbackImage();
      },
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCEAF4), Color(0xFF9AB8CC)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.bed_rounded, color: Colors.white, size: 38),
    );
  }
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  bool _isSaved = false;
  bool _isSectionBarVisible = false;
  int _selectedSectionIndex = 0;
  Hotel? _hotel;
  List<RoomType> _roomTypes = const [];
  List<String> _hotelImages = const [];
  List<HotelAmenity> _amenities = const [];
  final Map<String, Future<List<String>>> _roomImageRequests = {};
  final GlobalKey<_HotelNearbyPlacesMapState> _hotelNearbyMapKey =
      GlobalKey<_HotelNearbyPlacesMapState>();
  final ScrollController _detailScrollController = ScrollController();
  final _overviewKey = GlobalKey();
  final _roomsKey = GlobalKey();
  final _locationKey = GlobalKey();
  final _policiesKey = GlobalKey();

  static const _sectionLabels = ['Tổng quan', 'Phòng', 'Vị trí', 'Chính sách'];

  static const _hotelAmenities = <(IconData, String)>[
    (Icons.support_agent_outlined, 'Lễ tân 24h'),
    (Icons.local_parking_rounded, 'Chỗ đậu xe'),
    (Icons.wifi_rounded, 'WiFi'),
    (Icons.elevator_outlined, 'Thang máy'),
    (Icons.pool_outlined, 'Hồ bơi'),
    (Icons.restaurant_outlined, 'Nhà hàng'),
    (Icons.ac_unit_rounded, 'Máy lạnh'),
    (Icons.fitness_center_rounded, 'Phòng gym'),
    (Icons.local_laundry_service_outlined, 'Giặt ủi'),
    (Icons.room_service_outlined, 'Dịch vụ phòng'),
    (Icons.luggage_outlined, 'Giữ hành lý'),
    (Icons.smoke_free_rounded, 'Phòng không hút thuốc'),
  ];

  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_handleSelectionChanged);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final hotelId = widget.hotelId;
    if (hotelId == null || hotelId.isEmpty) return;
    try {
      final results = await Future.wait<dynamic>([
        apiRepository.hotel(hotelId),
        apiRepository.roomTypes(hotelId),
        apiRepository.hotelImages(hotelId),
        apiRepository.hotelAmenities(hotelId),
      ]);
      if (!mounted) return;
      setState(() {
        _hotel = results[0] as Hotel;
        _roomTypes = results[1] as List<RoomType>;
        _hotelImages = results[2] as List<String>;
        _amenities = results[3] as List<HotelAmenity>;
        for (final roomType in _roomTypes) {
          _roomImageRequests[roomType.id] = apiRepository.roomTypeImages(
            roomType.id,
          );
        }
      });
    } on ApiException {
      // The fallback content remains visible when optional detail calls fail.
    }
  }

  @override
  void didUpdateWidget(covariant HotelDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      oldWidget.selection.removeListener(_handleSelectionChanged);
      widget.selection.addListener(_handleSelectionChanged);
    }
  }

  void _handleSelectionChanged() {
    if (mounted) setState(() {});
  }

  void _selectSection(int index) {
    final sectionKeys = [_overviewKey, _roomsKey, _locationKey, _policiesKey];
    final targetContext = sectionKeys[index].currentContext;
    if (targetContext == null) return;
    setState(() => _selectedSectionIndex = index);
    final renderObject = targetContext.findRenderObject();
    if (renderObject == null || !_detailScrollController.hasClients) return;
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return;
    final position = _detailScrollController.position;
    final sectionTop = viewport.getOffsetToReveal(renderObject, 0).offset;
    final targetOffset = (sectionTop - 52)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _detailScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }

    final shouldShowSectionBar = notification.metrics.pixels > 24;
    final sectionKeys = [_overviewKey, _roomsKey, _locationKey, _policiesKey];
    final activationY = MediaQuery.paddingOf(context).top + kToolbarHeight + 52;
    var visibleSectionIndex = 0;
    for (var index = 0; index < sectionKeys.length; index++) {
      final renderObject =
          sectionKeys[index].currentContext?.findRenderObject();
      if (renderObject is RenderBox &&
          renderObject.localToGlobal(Offset.zero).dy <= activationY) {
        visibleSectionIndex = index;
      }
    }

    if ((visibleSectionIndex != _selectedSectionIndex ||
            shouldShowSectionBar != _isSectionBarVisible) &&
        mounted) {
      setState(() {
        _selectedSectionIndex = visibleSectionIndex;
        _isSectionBarVisible = shouldShowSectionBar;
      });
    }
    return false;
  }

  Widget _buildHotelSection({
    required GlobalKey key,
    required String title,
    required Widget child,
    bool emphasize = false,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: emphasize
            ? Border.all(color: const Color(0xFFB8C0C8), width: 1)
            : null,
        boxShadow: emphasize
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF19232D),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildHotelSections() {
    const detailStyle = TextStyle(
      color: Color(0xFF59636D),
      fontSize: 14,
      height: 1.45,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHotelSection(
            key: _overviewKey,
            title: 'Tổng quan',
            emphasize: true,
            child: Text(
              _hotel?.description.isNotEmpty == true
                  ? _hotel!.description
                  : 'Khám phá không gian nghỉ dưỡng thoải mái với các tiện ích phù hợp cho chuyến đi của bạn.',
              style: detailStyle,
            ),
          ),
          _buildHotelSection(
            key: _roomsKey,
            title: 'Phòng',
            emphasize: true,
            child: _buildRoomPreview(),
          ),
          _buildHotelSection(
            key: _locationKey,
            title: 'Vị trí',
            emphasize: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hotel?.address.isNotEmpty == true
                      ? _hotel!.address
                      : 'Địa chỉ đang được cập nhật.',
                  style: detailStyle,
                ),
                const SizedBox(height: 12),
                _HotelNearbyPlacesMap(
                  key: _hotelNearbyMapKey,
                  hotelName: _hotel?.name ?? widget.hotelName,
                  address: _hotel?.address ?? '',
                  city: _hotel?.city ?? '',
                  latitude: _hotel?.latitude,
                  longitude: _hotel?.longitude,
                ),
              ],
            ),
          ),
          _buildHotelSection(
            key: _policiesKey,
            title: 'Chính sách',
            emphasize: true,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nhận phòng: từ 14:00', style: detailStyle),
                SizedBox(height: 8),
                Text('Trả phòng: trước 12:00', style: detailStyle),
                SizedBox(height: 8),
                Text(
                  'Vui lòng xuất trình giấy tờ tùy thân khi nhận phòng.',
                  style: detailStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomPreview() {
    if (_roomTypes.isEmpty) {
      return const Text(
        'Chưa có thông tin hạng phòng cho khách sạn này.',
        style: TextStyle(color: Color(0xFF6D747B)),
      );
    }
    return Column(
      children: [
        for (final roomType in _roomTypes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _openRoomType(roomType),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _RoomTypePreviewImage(
                        request: _roomImageRequests[roomType.id],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              roomType.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF19232D),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tối đa ${roomType.maxGuests} khách · ${_formatPrice(roomType.basePrice)}',
                              style: const TextStyle(
                                color: Color(0xFF6D747B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Xem chi tiết phòng',
                              style: TextStyle(
                                color: Color(0xFF1674C5),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF7D858D),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openRoomType(RoomType roomType) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomDetailPage(
          hotelName: _hotel?.name ?? widget.hotelName,
          selection: widget.selection,
          hotelId: widget.hotelId,
          roomType: roomType,
        ),
      ),
    );
  }

  String _formatPrice(double price) =>
      price > 0 ? '${price.toStringAsFixed(0)} đ/đêm' : 'Giá liên hệ';

  @override
  void dispose() {
    widget.selection.removeListener(_handleSelectionChanged);
    _detailScrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  Future<void> _showHotelAmenities() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sheetHeight = MediaQuery.sizeOf(context).height * 0.8;
        final amenities = _amenities.isEmpty
            ? _hotelAmenities
            : _amenities
                .map((amenity) => (
                      Icons.check_circle_outline,
                      amenity.name,
                    ))
                .toList();
        return SafeArea(
          top: false,
          child: Container(
            height: sheetHeight,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5D9DE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tiện ích khách sạn',
                  style: TextStyle(
                    color: Color(0xFF19232D),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Các dịch vụ và tiện nghi tại khách sạn',
                  style: TextStyle(color: Color(0xFF6D747B), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: amenities.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.8,
                    ),
                    itemBuilder: (context, index) {
                      final (icon, label) = amenities[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: const Color(0xFF2A8FC7),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF26323D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHotelAmenitiesPreview() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (icon, label) in (_amenities.isEmpty
                          ? _hotelAmenities
                          : _amenities.take(4).map((amenity) => (
                                Icons.check_circle_outline,
                                amenity.name,
                              )))
                      .take(4))
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: const Color(0xFF2A8FC7), size: 19),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Color(0xFF26323D),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Xem tất cả tiện ích',
            onPressed: _showHotelAmenities,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF2A8FC7),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final dateRange = widget.selection.dateRange;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: dateRange,
      helpText: 'Chọn ngày nhận phòng',
      saveText: 'Xác nhận',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2A6EEB),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      widget.selection.updateDateRange(picked);
    }
  }

  Future<void> _pickGuestOptions() async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int room = widget.selection.roomCount;
        int adult = widget.selection.adultCount;
        int child = widget.selection.childCount;

        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  _GuestPickerRow(
                    label: 'Phòng',
                    value: room,
                    minValue: 1,
                    maxValue: 10,
                    onChanged: (value) => setModalState(() => room = value),
                  ),
                  const SizedBox(height: 12),
                  _GuestPickerRow(
                    label: 'Người lớn',
                    value: adult,
                    minValue: 1,
                    maxValue: 10,
                    onChanged: (value) => setModalState(() => adult = value),
                  ),
                  const SizedBox(height: 12),
                  _GuestPickerRow(
                    label: 'Trẻ em',
                    value: child,
                    minValue: 0,
                    maxValue: 10,
                    onChanged: (value) => setModalState(() => child = value),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .pop({'room': room, 'adult': adult, 'child': child}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6EEB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Xác nhận'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      widget.selection.updateGuests(
        rooms: result['room'] ?? widget.selection.roomCount,
        adults: result['adult'] ?? widget.selection.adultCount,
        children: result['child'] ?? widget.selection.childCount,
      );
    }
  }

  Future<void> _showSearchOptions() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng tùy chọn tìm kiếm',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final panelHeight = MediaQuery.sizeOf(dialogContext).height * 0.4;
        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: double.infinity,
                height: panelHeight,
                child: AnimatedBuilder(
                  animation: widget.selection,
                  builder: (context, _) => Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6DAE0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Thời gian và khách',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: _SearchOptionBox(
                                  icon: Icons.calendar_month_outlined,
                                  label: 'Ngày nhận phòng - trả phòng',
                                  value:
                                      '${_formatDate(widget.selection.dateRange.start)} - ${_formatDate(widget.selection.dateRange.end)} (${widget.selection.dateRange.duration.inDays} đêm)',
                                  onTap: _pickDateRange,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _SearchOptionBox(
                                  icon: Icons.people_alt_outlined,
                                  label: 'Phòng và khách',
                                  value:
                                      '${widget.selection.roomCount} phòng · ${widget.selection.adultCount} người lớn · ${widget.selection.childCount} trẻ em',
                                  onTap: _pickGuestOptions,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildSearchSummary() {
    final selection = widget.selection;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '${_formatDate(selection.dateRange.start)}-${_formatDate(selection.dateRange.end)} · ${selection.roomCount} phòng · ${selection.adultCount + selection.childCount} khách',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Đổi ngày, phòng và khách',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          onPressed: _showSearchOptions,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        ),
      ],
    );
  }

  Widget _buildHotelHero() {
    final imageHeight = MediaQuery.sizeOf(context).width * 0.72 + 16;
    const cardHeight = 177.0;

    return SizedBox(
      height: imageHeight + cardHeight / 2,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: Image.network(
              _hotelImages.isNotEmpty
                  ? _hotelImages.first
                  : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=85',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFFE7E9EC),
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF7D858D),
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x52000000),
                    Color(0xD9000000),
                  ],
                  stops: [0.28, 0.62, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: imageHeight - 132,
            left: 0,
            right: 0,
            height: 64,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x50000000)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 177,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hotel?.name ?? widget.hotelName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0;
                        index < (_hotel?.starRating?.round() ?? 5);
                        index++)
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD21F),
                        size: 18,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      (_hotel?.starRating ?? 5).toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Khách sạn',
                        style: TextStyle(
                          color: Color(0xFF2674B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 104,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE7EBF0),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '8.7/10',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Color(0xFF1674C5),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Rất tốt',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFF1674C5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '36 đánh giá',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFF6D747B),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE7EBF0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _hotel?.city.isNotEmpty == true
                                            ? _hotel!.city
                                            : 'Địa điểm khách sạn',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF1674C5),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        _hotel?.address.isNotEmpty == true
                                            ? _hotel!.address
                                            : 'Địa chỉ đang được cập nhật.',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF6D747B),
                                          fontSize: 11,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Mở bản đồ lớn',
                                  onPressed: () => _hotelNearbyMapKey
                                      .currentState
                                      ?.openExpandedMap(),
                                  icon: const Icon(Icons.map_outlined,
                                      color: Color(0xFF1674C5), size: 26),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Divider(height: 1, color: Color(0xFFE9ECEF)),
                  ),
                  _buildHotelAmenitiesPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        toolbarHeight: 80,
        leadingWidth: 48,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(0, 11),
              child: Text(
                _hotel?.name ?? widget.hotelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _buildSearchSummary(),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mã giảm giá',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DiscountPage()),
            ),
            icon: const Icon(Icons.percent_rounded),
          ),
          IconButton(
            tooltip: _isSaved ? 'Bỏ lưu' : 'Lưu khách sạn',
            onPressed: () => setState(() => _isSaved = !_isSaved),
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Thư',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CustomerSupportPage(),
              ),
            ),
            icon: const Icon(Icons.mail_outline_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: CustomScrollView(
              controller: _detailScrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHotelHero()
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.06),
                ),
                SliverToBoxAdapter(
                  child: _buildHotelSections()
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 500.ms)
                      .slideY(begin: 0.05),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            top: _isSectionBarVisible ? 0 : -52,
            left: 0,
            right: 0,
            height: 52,
            child: IgnorePointer(
              ignoring: !_isSectionBarVisible,
              child: ExcludeSemantics(
                excluding: !_isSectionBarVisible,
                child: _HotelSectionNavigationBar(
                  labels: _sectionLabels,
                  selectedIndex: _selectedSectionIndex,
                  onSelect: _selectSection,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
