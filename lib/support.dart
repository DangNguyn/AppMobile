part of 'booking_app.dart';

class DiscountIconButton extends StatefulWidget {
  const DiscountIconButton({super.key});

  @override
  State<DiscountIconButton> createState() => _DiscountIconButtonState();
}

class _DiscountIconButtonState extends State<DiscountIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isHighlighted => _isHovered || _isPressed;

  void _openDiscountPage() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const DiscountPage()));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _openDiscountPage,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: AppMotion.interactionDuration,
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: _isHighlighted ? 2.5 : 1.5,
              ),
              boxShadow: _isHighlighted
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.95),
                        blurRadius: 22,
                        spreadRadius: 7,
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.interactionDuration,
              style: TextStyle(
                color: Colors.white,
                fontSize: _isHighlighted ? 23 : 19,
                fontWeight: _isHighlighted ? FontWeight.w900 : FontWeight.w300,
                shadows: _isHighlighted
                    ? const [Shadow(color: Colors.white, blurRadius: 12)]
                    : const [],
              ),
              child: const Text('%'),
            ),
          ),
        ),
      ),
    );
  }
}

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  late Future<List<Voucher>> _vouchers;
  late Future<List<Hotel>> _hotels;
  final _codeController = TextEditingController();
  final _hotelSelection = HotelSearchSelection();
  final Map<String, Future<List<String>>> _hotelImageRequests = {};
  String _filter = 'all';
  Set<String> _savedCodes = {};

  @override
  void initState() {
    super.initState();
    _vouchers = apiRepository.vouchers();
    _hotels = _loadRecommendedHotels();
    _loadSavedCodes();
  }

  Future<List<Hotel>> _loadRecommendedHotels() async {
    try {
      final hotels = await apiRepository.hotels();
      if (hotels.isNotEmpty) return hotels.take(6).toList();
    } on ApiException {
      return const [];
    }
    return const [];
  }

  @override
  void dispose() {
    _codeController.dispose();
    _hotelSelection.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCodes() async {
    final codes = await voucherStorageService.getSavedVoucherCodes();
    if (mounted) setState(() => _savedCodes = codes.toSet());
  }

  Future<void> _saveVoucher(String code) async {
    await voucherStorageService.saveVoucher(code);
    if (!mounted) return;
    setState(() => _savedCodes = {..._savedCodes, code.toUpperCase()});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu mã vào ví của bạn')),
    );
  }

  Future<void> _applyManualCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    try {
      final voucher = await apiRepository.voucher(code);
      if (!mounted) return;
      await _saveVoucher(voucher.code);
      if (!mounted) return;
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu mã ${voucher.code} vào ví của bạn')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  List<Voucher> _filtered(List<Voucher> vouchers) {
    return vouchers.where((voucher) {
      if (_filter == 'saved') {
        return _savedCodes.contains(voucher.code.toUpperCase());
      }
      if (_filter == 'percent') return voucher.discountType == 'percent';
      if (_filter == 'fixed') return voucher.discountType != 'percent';
      return true;
    }).toList();
  }

  String _formatVnd(double value) =>
      '${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';

  String _formatDate(DateTime? value) {
    if (value == null) return 'Không xác định';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0E1F38),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E1F38),
          foregroundColor: Colors.white,
          title: const Text('Mã giảm giá'),
          elevation: 0,
        ),
        body: FutureBuilder<List<Voucher>>(
          future: _vouchers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoadingIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Không thể tải kho mã: ${snapshot.error}'),
              );
            }
            final vouchers = _filtered(snapshot.data ?? const []);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Nhập mã voucher',
                          prefixIcon:
                              const Icon(Icons.confirmation_number_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _applyManualCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6EEB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Tất cả', 'all'),
                      _filterChip('Đã lưu', 'saved'),
                      _filterChip('Giảm theo %', 'percent'),
                      _filterChip('Giảm tiền mặt', 'fixed'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (vouchers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('Chưa có mã giảm giá phù hợp.')),
                  )
                else ...[
                  const Text(
                    'Mã ưu đãi dành cho bạn',
                    style: TextStyle(
                      color: Color(0xFF0E1F38),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 144,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vouchers.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _voucherCard(vouchers[index])
                              .animate()
                              .fadeIn(
                                delay: AppMotion.entranceStagger * index,
                                duration: AppMotion.entranceDuration,
                              )
                              .slideX(
                                begin: 0.04,
                                duration: AppMotion.entranceDuration,
                              ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _buildDiscoverSection(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: const Color(0xFFDFEBFF),
        labelStyle: TextStyle(
          color: _filter == value
              ? const Color(0xFF2A6EEB)
              : const Color(0xFF4B5563),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _voucherCard(Voucher voucher) {
    final saved = _savedCodes.contains(voucher.code.toUpperCase());
    final isPercent = voucher.discountType == 'percent';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shadowColor: const Color(0x220E1F38),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: SizedBox(
        width: 250,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 56,
                height: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0875F5), Color(0xFF42B8F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isPercent
                                ? '${voucher.discountValue.round()}%'
                                : _formatVnd(voucher.discountValue),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPercent
                          ? 'Giảm ${voucher.discountValue.round()}%'
                          : 'Giảm ${_formatVnd(voucher.discountValue)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF008ACB),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mã ${voucher.code}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF26384D),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tối thiểu ${_formatVnd(voucher.minOrder)}',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'HSD ${_formatDate(voucher.endDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 9,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed:
                              saved ? null : () => _saveVoucher(voucher.code),
                          icon: Icon(saved ? Icons.check : Icons.add, size: 15),
                          label: Text(saved ? 'Đã lưu' : 'Thu thập'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0875F5),
                            disabledForegroundColor: const Color(0xFF2E9B63),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverSection() {
    return FutureBuilder<List<Hotel>>(
      future: _hotels,
      builder: (context, snapshot) {
        final hotels = snapshot.data ?? const <Hotel>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khám phá Việt Nam',
              style: TextStyle(
                color: Color(0xFF0E1F38),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Những điểm lưu trú nổi bật cho hành trình tiếp theo',
              style: TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(
                height: 230,
                child: Center(child: AppLoadingIndicator()),
              )
            else
              hotels.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        'Chưa tải được danh sách khách sạn đề xuất.',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    )
                  : SizedBox(
                      height: 270,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: hotels.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final hotel = hotels[index];
                          final imageRequest = _hotelImageRequests.putIfAbsent(
                            hotel.id,
                            () => apiRepository.hotelImages(hotel.id),
                          );
                          return _hotelCard(hotel, imageRequest)
                              .animate()
                              .fadeIn(
                                delay: AppMotion.entranceStagger * (index + 2),
                                duration: AppMotion.entranceDuration,
                              )
                              .slideY(
                                begin: 0.04,
                                duration: AppMotion.entranceDuration,
                              );
                        },
                      ),
                    ),
          ],
        );
      },
    );
  }

  Widget _hotelCard(Hotel hotel, Future<List<String>> imageRequest) {
    void openHotel() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HotelDetailPage(
            hotelName: hotel.name,
            hotelId: hotel.id,
            selection: _hotelSelection,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: openHotel,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 245,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x180E1F38),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<List<String>>(
                      future: imageRequest,
                      builder: (context, snapshot) {
                        final images = snapshot.data ?? const <String>[];
                        if (images.isNotEmpty) {
                          return Image.network(
                            images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _hotelImageFallback(hotel),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ColoredBox(
                            color: Color(0xFFE8EEF8),
                            child: Center(
                              child: AppLoadingIndicator(size: 20),
                            ),
                          );
                        }
                        return _hotelImageFallback(hotel);
                      },
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Text(
                            'Đề xuất',
                            style: TextStyle(
                              color: Color(0xFF1688C7),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17202C),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel.city.isEmpty ? hotel.address : hotel.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A838C),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC928),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (hotel.starRating ?? 5).toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF1688C7),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => HotelDetailPage(
                                hotelName: hotel.name,
                                hotelId: hotel.id,
                                selection: _hotelSelection,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF2A6EEB),
                            size: 18,
                          ),
                          label: const Text('Xem phòng'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2A6EEB),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hotelImageFallback(Hotel hotel) {
    return const ColoredBox(
      color: Color(0xFFE8EEF8),
      child: Center(
        child: Icon(
          Icons.hotel_rounded,
          color: Color(0xFF2A6EEB),
          size: 48,
        ),
      ),
    );
  }
}

class CustomerSupportIconButton extends StatefulWidget {
  const CustomerSupportIconButton({super.key});

  @override
  State<CustomerSupportIconButton> createState() =>
      _CustomerSupportIconButtonState();
}

class _CustomerSupportIconButtonState extends State<CustomerSupportIconButton> {
  bool _isHovered = false;

  void _openSupportPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CustomerSupportPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: IconButton(
        tooltip: 'Hỗ trợ khách hàng',
        onPressed: _openSupportPage,
        icon: Icon(
          Icons.chat_bubble_outline_rounded,
          color: _isHovered ? const Color(0xFFB8D9FF) : Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

class CustomerSupportPage extends StatefulWidget {
  const CustomerSupportPage({super.key});

  @override
  State<CustomerSupportPage> createState() => _CustomerSupportPageState();
}

class _CustomerSupportPageState extends State<CustomerSupportPage> {
  int _selectedTab = 0;
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Trò chuyện', 'Thông báo'];
    const filters = ['Tất cả', 'Đang tiến hành', 'Đã đóng'];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0E1F38),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.of(context).padding.top + 10,
                  18,
                  16,
                ),
                color: const Color(0xFF0E1F38),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Hộp thư đến',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = index == _selectedTab;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = index),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF2A6EEB)
                                  : const Color(0xFFE1E5E9),
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF2A6EEB)
                                : const Color(0xFF6D747B),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              Expanded(
                child: _selectedTab == 0
                    ? _buildChats(filters)
                    : _buildNotifications(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChats(List<String> filters) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1F38),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Đừng bỏ lỡ phản hồi từ Dịch vụ Khách hàng của chúng tôi!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Nhận thông báo',
                  style: TextStyle(
                    color: Color(0xFF0E1F38),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isSelected = index == _selectedFilter;
              return InkWell(
                onTap: () => setState(() => _selectedFilter = index),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE4F4FC)
                        : const Color(0xFFF5F7F9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    filters[index],
                    style: const TextStyle(
                      color: Color(0xFF0E1F38),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFF2A6EEB),
                    size: 88,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hôm nay chúng tôi có thể giúp gì cho bạn?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF252A30),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn không có yêu cầu nào đang hoạt động. Bắt đầu cuộc trò chuyện mới để được hỗ trợ về đặt chỗ hoặc các câu hỏi khác.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7B8288),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE4F4FC),
                      foregroundColor: const Color(0xFF0E1F38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Bắt đầu cuộc trò chuyện mới',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 18, 18),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.support_agent_rounded, size: 20),
              label: const Text('Cần thêm trợ giúp?'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE4F4FC),
                foregroundColor: const Color(0xFF0E1F38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF2A6EEB),
              size: 80,
            ),
            SizedBox(height: 18),
            Text(
              'Chưa có thông báo',
              style: TextStyle(
                color: Color(0xFF252A30),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
