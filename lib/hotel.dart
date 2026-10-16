part of 'booking_app.dart';

class HotelSearchResultsPage extends StatefulWidget {
  final String location;
  final HotelSearchSelection selection;

  const HotelSearchResultsPage({
    super.key,
    required this.location,
    required this.selection,
  });

  @override
  State<HotelSearchResultsPage> createState() => _HotelSearchResultsPageState();
}

class _HotelSearchResultsPageState extends State<HotelSearchResultsPage> {
  late String _location;
  late Future<List<Hotel>> _hotels;

  @override
  void initState() {
    super.initState();
    _location = widget.location;
    _hotels = _loadHotels();
    widget.selection.addListener(_handleSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant HotelSearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      oldWidget.selection.removeListener(_handleSelectionChanged);
      widget.selection.addListener(_handleSelectionChanged);
    }
  }

  @override
  void dispose() {
    widget.selection.removeListener(_handleSelectionChanged);
    super.dispose();
  }

  void _handleSelectionChanged() {
    if (mounted) {
      setState(() {
        _hotels = _loadHotels();
      });
    }
  }

  Future<List<Hotel>> _loadHotels() async {
    final hotels = await apiRepository.hotels();
    final location = _normalizeLocation(_location);
    final matchingHotels = hotels
        .where((hotel) => _hotelMatchesLocation(hotel, location))
        .toList();

    final availability = await Future.wait(
      matchingHotels.map(_hasRequiredAvailability),
    );
    return [
      for (var index = 0; index < matchingHotels.length; index++)
        if (availability[index]) matchingHotels[index],
    ];
  }

  Future<bool> _hasRequiredAvailability(Hotel hotel) async {
    final dateRange = widget.selection.dateRange;
    final rooms = await apiRepository.availableRooms(
      hotelId: hotel.id,
      checkIn: _dateOnly(dateRange.start),
      checkOut: _dateOnly(dateRange.end),
    );
    final requestedRooms = widget.selection.roomCount;
    if (rooms.length < requestedRooms) return false;

    final requestedGuests =
        widget.selection.adultCount + widget.selection.childCount;
    final capacities = rooms
        .map((room) => room.maxGuests)
        .whereType<int>()
        .where((capacity) => capacity > 0)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (capacities.length < requestedRooms) return true;

    final totalCapacity = capacities
        .take(requestedRooms)
        .fold<int>(0, (total, capacity) => total + capacity);
    return totalCapacity >= requestedGuests;
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  bool _hotelMatchesLocation(Hotel hotel, String location) {
    final city = _normalizeLocation(hotel.city);
    if (city.isNotEmpty) return city == location;
    return _normalizeLocation(hotel.address).contains(location);
  }

  String _normalizeLocation(String value) {
    const replacements = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'đ': 'd',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
    };
    var normalized = value.trim().toLowerCase();
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}';

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: widget.selection.dateRange,
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

  Future<void> _pickGuests() async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetAnimationStyle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var rooms = widget.selection.roomCount;
        var adults = widget.selection.adultCount;
        var children = widget.selection.childCount;

        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GuestPickerRow(
                    label: 'Phòng',
                    value: rooms,
                    minValue: 1,
                    maxValue: 10,
                    onChanged: (value) => setModalState(() => rooms = value),
                  ),
                  const SizedBox(height: 12),
                  _GuestPickerRow(
                    label: 'Người lớn',
                    value: adults,
                    minValue: 1,
                    maxValue: 10,
                    onChanged: (value) => setModalState(() => adults = value),
                  ),
                  const SizedBox(height: 12),
                  _GuestPickerRow(
                    label: 'Trẻ em',
                    value: children,
                    minValue: 0,
                    maxValue: 10,
                    onChanged: (value) => setModalState(() => children = value),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop({
                        'rooms': rooms,
                        'adults': adults,
                        'children': children,
                      }),
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
        rooms: result['rooms']!,
        adults: result['adults']!,
        children: result['children']!,
      );
    }
  }

  Future<String?> _pickDestination(String selectedLocation) {
    return showModalBottomSheet<String>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetAnimationStyle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.65,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _availableDestinations.length,
            itemBuilder: (context, index) {
              final destination = _availableDestinations[index];
              return ListTile(
                title: Text(destination),
                trailing: destination == selectedLocation
                    ? const Icon(Icons.check, color: Color(0xFF2A6EEB))
                    : null,
                onTap: () => Navigator.of(context).pop(destination),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSearchOption({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2A6EEB), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D747B),
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF19232D),
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7D858D),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSearchOptions() {
    return showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetAnimationStyle,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var selectedLocation = _location;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
            return Container(
              height: MediaQuery.sizeOf(context).height * 0.4,
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 4),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5D9DE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Thay đổi tìm kiếm',
                      style: TextStyle(
                        color: Color(0xFF19232D),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactSearchOption(
                          icon: Icons.location_on_outlined,
                          label: 'Điểm đến',
                          value: selectedLocation,
                          onTap: () async {
                            final destination = await _pickDestination(
                              selectedLocation,
                            );
                            if (destination != null) {
                              setModalState(
                                () => selectedLocation = destination,
                              );
                            }
                          },
                        ),
                        _buildCompactSearchOption(
                          icon: Icons.calendar_month_outlined,
                          label: 'Ngày nhận - trả phòng',
                          value:
                              '${_formatDate(widget.selection.dateRange.start)} - ${_formatDate(widget.selection.dateRange.end)} (${widget.selection.dateRange.duration.inDays} đêm)',
                          onTap: () async {
                            await _pickDateRange();
                            if (context.mounted) setModalState(() {});
                          },
                        ),
                        _buildCompactSearchOption(
                          icon: Icons.people_alt_outlined,
                          label: 'Phòng và khách',
                          value:
                              '${widget.selection.roomCount} phòng · ${widget.selection.adultCount} người lớn · ${widget.selection.childCount} trẻ em',
                          onTap: () async {
                            await _pickGuests();
                            if (context.mounted) setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _location = selectedLocation;
                          _hotels = _loadHotels();
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6EEB),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Tìm kiếm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = widget.selection.dateRange;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            DestinationImage(
              location: _location,
              networkUrl:
                  'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=85',
            ),
            ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${dateRange.duration.inDays} đêm · ${widget.selection.roomCount} phòng · ${widget.selection.adultCount + widget.selection.childCount} khách',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Thay đổi tìm kiếm',
              onPressed: _showSearchOptions,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Hotel>>(
              future: _hotels,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _HotelSearchSkeleton();
                }
                if (snapshot.hasError) {
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const Text(
                        'Không thể tải danh sách khách sạn theo bộ lọc đã chọn. '
                        'Vui lòng thử lại.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  );
                }
                final hotels = snapshot.data ?? const <Hotel>[];
                if (hotels.isEmpty) {
                  return const _HotelSearchEmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: hotels.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final hotel = hotels[index];
                    return _HotelResultCard(
                      number: index + 1,
                      hotelId: hotel.id,
                      name: hotel.name,
                      location: hotel.city.isEmpty ? _location : hotel.city,
                      address: hotel.address,
                      description: hotel.description,
                      rating: hotel.starRating ?? 5,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HotelDetailPage(
                            selection: widget.selection,
                            hotelName: hotel.name,
                            hotelId: hotel.id,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelSearchSkeleton extends StatelessWidget {
  const _HotelSearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: const Color(0xFFE5EAF0),
        highlightColor: Colors.white,
        child: Container(
          height: 166,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 112,
                height: 142,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: double.infinity, height: 18),
                    const SizedBox(height: 10),
                    _SkeletonLine(width: 120, height: 14),
                    const SizedBox(height: 14),
                    _SkeletonLine(width: 90, height: 14),
                    const Spacer(),
                    _SkeletonLine(width: 150, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _HotelSearchEmptyState extends StatelessWidget {
  const _HotelSearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 150,
              child: Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_qp1q7mct.json',
                repeat: true,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.hotel_outlined,
                  size: 64,
                  color: Color(0xFF2A6EEB),
                ),
              ),
            ),
            const Text(
              'Chưa có khách sạn phù hợp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thử đổi điểm đến hoặc thời gian lưu trú nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelResultCard extends StatefulWidget {
  final int number;
  final String hotelId;
  final String name;
  final String location;
  final String address;
  final String description;
  final double rating;
  final VoidCallback onTap;

  const _HotelResultCard({
    required this.number,
    required this.hotelId,
    required this.name,
    required this.location,
    required this.address,
    required this.description,
    required this.rating,
    required this.onTap,
  });

  @override
  State<_HotelResultCard> createState() => _HotelResultCardState();
}

class _HotelResultCardState extends State<_HotelResultCard> {
  static const _sampleReviewCount = 4;

  late Future<List<HotelAmenity>> _amenities;
  late Future<List<Review>> _reviews;
  late Future<List<RoomType>> _roomTypes;

  @override
  void initState() {
    super.initState();
    _loadHotelDetails();
  }

  @override
  void didUpdateWidget(covariant _HotelResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hotelId != widget.hotelId) _loadHotelDetails();
  }

  void _loadHotelDetails() {
    _amenities = apiRepository.hotelAmenities(widget.hotelId);
    _reviews = apiRepository.reviews(widget.hotelId);
    _roomTypes = apiRepository.roomTypes(widget.hotelId);
  }

  String _formatPrice(num amount) {
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

  Widget _buildPrice() {
    return FutureBuilder<List<RoomType>>(
      future: _roomTypes,
      builder: (context, snapshot) {
        final prices = (snapshot.data ?? const <RoomType>[])
            .map((roomType) => roomType.basePrice)
            .where((price) => price > 0)
            .toList();
        if (prices.isEmpty) {
          return const Text(
            'Chưa có giá phòng',
            style: TextStyle(
              color: Color(0xFF7A838C),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          );
        }

        prices.sort();
        final price = Text(
          '${_formatPrice(prices.reduce((a, b) => a < b ? a : b))}/đêm',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 20,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        );
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return price;
        }
        return price
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.035, 1.035),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeInOut,
            );
      },
    );
  }

  Widget _buildAmenities() {
    return SizedBox(
      height: 26,
      child: FutureBuilder<List<HotelAmenity>>(
        future: _amenities,
        builder: (context, snapshot) {
          final amenities = snapshot.data ?? const <HotelAmenity>[];
          if (amenities.isEmpty) return const SizedBox.shrink();
          final visibleAmenities = amenities.take(3).toList();
          return ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            children: [
              for (final amenity in visibleAmenities)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF238A70),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        amenity.name,
                        style: const TextStyle(
                          color: Color(0xFF52616C),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              if (amenities.length > visibleAmenities.length)
                Text(
                  '+${amenities.length - visibleAmenities.length}',
                  style: const TextStyle(
                    color: Color(0xFF52616C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HotelResultImage(hotelId: widget.hotelId, number: widget.number),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF202A33),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF525D67),
                          fontSize: 14,
                        ),
                      ),
                      if (widget.address.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7A838C),
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          for (var index = 0;
                              index < widget.rating.round().clamp(0, 5);
                              index++)
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC928),
                              size: 17,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFF1688C7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildAmenities(),
                      const SizedBox(height: 6),
                      Text(
                        widget.description.trim().isNotEmpty
                            ? widget.description.trim()
                            : 'Khám phá không gian nghỉ dưỡng thoải mái với các tiện ích phù hợp cho chuyến đi của bạn.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF68737D),
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      FutureBuilder<List<Review>>(
                        future: _reviews,
                        builder: (context, snapshot) => Text(
                          '${_sampleReviewCount + (snapshot.data?.length ?? 0)} đánh giá',
                          style: const TextStyle(
                            color: Color(0xFF7A838C),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _buildPrice(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyPlace {
  final String id;
  final String name;
  final String category;
  final LatLng point;

  const _NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.point,
  });
}

class _HotelResultImage extends StatelessWidget {
  const _HotelResultImage({required this.hotelId, required this.number});

  final String hotelId;
  final int number;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: apiRepository.hotelImages(hotelId),
      builder: (context, snapshot) {
        final images = snapshot.data ?? const <String>[];
        final imageUrl = images.isEmpty ? null : images.first;
        final colors = number.isEven
            ? const [Color(0xFFB8D7E8), Color(0xFF557D91)]
            : const [Color(0xFFE9D9C2), Color(0xFF9D7856)];
        return Container(
          width: 142,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl == null || imageUrl.isEmpty
              ? const Icon(Icons.hotel_rounded, color: Colors.white, size: 42)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.hotel_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
        );
      },
    );
  }
}

class _HotelNearbyPlacesMap extends StatefulWidget {
  const _HotelNearbyPlacesMap();

  @override
  State<_HotelNearbyPlacesMap> createState() => _HotelNearbyPlacesMapState();
}

class _HotelNearbyPlacesMapState extends State<_HotelNearbyPlacesMap> {
  static const _hotelPoint = LatLng(10.8036, 106.7355);
  static const _hotelAddress =
      '19A Nguyễn Bá Huân, Thảo Điền, Thủ Đức, Hồ Chí Minh';
  static const _radiusMeters = 1800;

  final MapController _mapController = MapController();
  List<_NearbyPlace> _places = [];
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final latitude = _hotelPoint.latitude;
      final longitude = _hotelPoint.longitude;
      final query = '[out:json][timeout:20];'
          '('
          'nwr(around:$_radiusMeters,$latitude,$longitude)'
          '["tourism"~"^(attraction|museum|gallery|viewpoint)\$"];'
          'nwr(around:$_radiusMeters,$latitude,$longitude)'
          '["leisure"~"^(park|garden|nature_reserve)\$"];'
          'nwr(around:$_radiusMeters,$latitude,$longitude)'
          '["amenity"~"^(arts_centre|theatre|cinema|marketplace)\$"];'
          'nwr(around:$_radiusMeters,$latitude,$longitude)'
          '["historic"~"^(archaeological_site|castle|monument|memorial)\$"];'
          ');out center tags;';
      final response = await http.post(
        Uri.https('overpass-api.de', '/api/interpreter'),
        headers: const {
          'User-Agent': 'app_mobile/1.0 (nearby hotel places map)',
          'Accept': 'application/json',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw http.ClientException(
          'Không thể tải địa điểm gần đây (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
        throw const FormatException('Dữ liệu địa điểm không hợp lệ.');
      }

      final uniquePlaces = <String, _NearbyPlace>{};
      for (final item in decoded['elements'] as List) {
        if (item is! Map<String, dynamic>) continue;
        final rawTags = item['tags'];
        if (rawTags is! Map) continue;
        final tags = Map<String, dynamic>.from(rawTags);
        final rawId = item['id'];
        if (rawId == null) continue;

        final rawCenter = item['center'];
        final center = rawCenter is Map ? rawCenter : null;
        final rawLat = item['lat'] ?? center?['lat'];
        final rawLon = item['lon'] ?? center?['lon'];
        if (rawLat is! num || rawLon is! num) continue;

        final name = tags['name']?.toString().trim();
        if (name == null || name.isEmpty) continue;

        final category = tags['tourism']?.toString() ??
            tags['leisure']?.toString() ??
            tags['amenity']?.toString() ??
            tags['historic']?.toString() ??
            'Địa điểm tham quan';

        final place = _NearbyPlace(
          id: '${item['type'] ?? 'object'}/$rawId',
          name: name,
          category: _formatPlaceCategory(category),
          point: LatLng(rawLat.toDouble(), rawLon.toDouble()),
        );
        uniquePlaces[place.id] = place;
      }

      final places = uniquePlaces.values.toList()
        ..sort(
          (first, second) => const Distance()
              .as(LengthUnit.Meter, _hotelPoint, first.point)
              .compareTo(
                const Distance().as(
                  LengthUnit.Meter,
                  _hotelPoint,
                  second.point,
                ),
              ),
        );

      if (!mounted) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });
      _fitMapToPlaces();
    } on http.ClientException catch (error) {
      _showLoadError(error);
    } on SocketException catch (error) {
      _showLoadError(error);
    } on HttpException catch (error) {
      _showLoadError(error);
    } on TimeoutException catch (error) {
      _showLoadError(error);
    } on FormatException catch (error) {
      _showLoadError(error);
    }
  }

  void _showLoadError(Object error) {
    if (!mounted) return;
    setState(() {
      _loadError = error;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _formatPlaceCategory(String category) {
    const labels = {
      'attraction': 'Điểm tham quan',
      'museum': 'Bảo tàng',
      'gallery': 'Phòng trưng bày',
      'viewpoint': 'Điểm ngắm cảnh',
      'park': 'Công viên',
      'garden': 'Vườn',
      'nature_reserve': 'Khu bảo tồn',
      'arts_centre': 'Trung tâm nghệ thuật',
      'theatre': 'Nhà hát',
      'cinema': 'Rạp chiếu phim',
      'marketplace': 'Chợ',
      'castle': 'Di tích lịch sử',
      'monument': 'Di tích lịch sử',
      'memorial': 'Đài tưởng niệm',
      'archaeological_site': 'Di tích khảo cổ',
    };
    return labels[category] ?? 'Địa điểm tham quan';
  }

  void _fitMapToPlaces() {
    if (_places.isEmpty) return;
    final points = [_hotelPoint, ..._places.map((place) => place.point)];
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(44),
        maxZoom: 15.5,
      ),
    );
  }

  double _distanceInKilometers(LatLng point) {
    return const Distance().as(LengthUnit.Kilometer, _hotelPoint, point);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          _hotelAddress,
          style: TextStyle(
            color: Color(0xFF59636D),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 230,
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _hotelPoint,
                initialZoom: 14.5,
                minZoom: 11,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'app_mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _hotelPoint,
                      width: 44,
                      height: 44,
                      child: const _NearbyMapMarker(
                        icon: Icons.hotel_rounded,
                        color: Color(0xFF1B6EEB),
                      ),
                    ),
                    for (final place in _places)
                      Marker(
                        point: place.point,
                        width: 38,
                        height: 38,
                        child: const _NearbyMapMarker(
                          icon: Icons.local_activity_rounded,
                          color: Color(0xFFE56A35),
                          small: true,
                        ),
                      ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(
                            color: Color(0xFF394550),
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vị trí khách sạn được đánh dấu màu xanh; các địa điểm gần đó màu cam. Vị trí ghim khách sạn là ước tính theo khu vực Thảo Điền.',
          style: TextStyle(
            color: Color(0xFF7D858D),
            fontSize: 11,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Địa điểm vui chơi gần đây',
          style: TextStyle(
            color: Color(0xFF19232D),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: AppLoadingIndicator(size: 24),
            ),
          )
        else if (_loadError != null)
          _buildLoadError()
        else if (_places.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Chưa tìm thấy địa điểm có dữ liệu trên bản đồ trong bán kính 1,8 km.',
              style: TextStyle(
                color: Color(0xFF59636D),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          )
        else
          ..._places.take(12).map(_buildPlaceTile),
      ],
    );
  }

  Widget _buildLoadError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Không tải được danh sách địa điểm gần đây. Vui lòng kiểm tra kết nối rồi thử lại.',
            style: TextStyle(
              color: Color(0xFF9D3D24),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadNearbyPlaces,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceTile(_NearbyPlace place) {
    final distance = _distanceInKilometers(place.point);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFFFF1E9),
        child: Icon(Icons.local_activity_rounded, color: Color(0xFFE56A35)),
      ),
      title: Text(
        place.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF26323D),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      subtitle: Text(place.category),
      trailing: Text(
        distance < 1
            ? '${(distance * 1000).round()} m'
            : '${distance.toStringAsFixed(1)} km',
        style: const TextStyle(color: Color(0xFF6D747B), fontSize: 12),
      ),
      onTap: () => _mapController.move(place.point, 16),
    );
  }
}

class _NearbyMapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool small;

  const _NearbyMapMarker({
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: small ? 28 : 36,
      shadows: const [
        Shadow(color: Colors.white, blurRadius: 4),
        Shadow(color: Colors.white, blurRadius: 8),
      ],
    );
  }
}
