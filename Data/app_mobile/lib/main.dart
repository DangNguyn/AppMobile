import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const List<String> _availableDestinations = [
  'Đà Nẵng',
  'Nha Trang',
  'Hồ Chí Minh',
  'Hà Nội',
  'Đà Lạt',
  'Phú Quốc',
  'Hội An',
  'Hạ Long',
  'Huế',
  'Sa Pa',
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel booking UI',
      scrollBehavior: const FixedEdgeScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
        fontFamily: 'Roboto',
      ),
      home: const TravelHomePage(),
    );
  }
}

class FixedEdgeScrollBehavior extends ScrollBehavior {
  const FixedEdgeScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class HotelSearchSelection extends ChangeNotifier {
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().add(const Duration(days: 1)),
    end: DateTime.now().add(const Duration(days: 3)),
  );
  int roomCount = 1;
  int adultCount = 2;
  int childCount = 0;

  void updateDateRange(DateTimeRange value) {
    dateRange = value;
    notifyListeners();
  }

  void updateGuests({
    required int rooms,
    required int adults,
    required int children,
  }) {
    roomCount = rooms;
    adultCount = adults;
    childCount = children;
    notifyListeners();
  }
}

class TravelHomePage extends StatefulWidget {
  const TravelHomePage({super.key});

  @override
  State<TravelHomePage> createState() => _TravelHomePageState();
}

class _TravelHomePageState extends State<TravelHomePage> {
  final ScrollController _scrollController = ScrollController();
  final HotelSearchSelection _hotelSearchSelection = HotelSearchSelection();
  bool _showScrollTopButton = false;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 150;
    if (shouldShow != _showScrollTopButton) {
      setState(() => _showScrollTopButton = shouldShow);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _openHotelSearchResults(String location) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HotelSearchResultsPage(
          location: location,
          selection: _hotelSearchSelection,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _hotelSearchSelection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> navLabels = [
      'Trang chủ',
      'Explore',
      'Đặt chỗ của tôi',
      'Đã lưu',
      'Tài khoản',
    ];

    final List<IconData> navIcons = [
      Icons.home,
      Icons.play_circle_outline,
      Icons.receipt_long_rounded,
      Icons.bookmark_border,
      Icons.account_circle_outlined,
    ];

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
              Expanded(
                child: _selectedNavIndex == 2
                    ? const BookingPage()
                    : _selectedNavIndex == 3
                    ? const SavedPage()
                    : Stack(
                        children: [
                          SingleChildScrollView(
                            controller: _scrollController,
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SearchPanel(
                                  selection: _hotelSearchSelection,
                                  onSearch: _openHotelSearchResults,
                                ),
                                const SizedBox(height: 18),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const PromoStrip(),
                                      const SizedBox(height: 20),
                                      const SectionHeader(
                                        title: 'Mã giảm số lượng có hạn',
                                      ),
                                      const SizedBox(height: 12),
                                      const CouponRow(),
                                      const SizedBox(height: 18),
                                      HotelRowSection(
                                        selection: _hotelSearchSelection,
                                      ),
                                      const SizedBox(height: 20),
                                      const BrandOfferSection(),
                                      const SizedBox(height: 18),
                                      const DiscoverBanner(),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showScrollTopButton)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: ScrollTopButton(onPressed: _scrollToTop),
                            ),
                        ],
                      ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: List.generate(navLabels.length, (index) {
                    final isActive = index == _selectedNavIndex;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedNavIndex = index;
                            _showScrollTopButton = false;
                          });
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              navIcons[index],
                              size: 30,
                              color: isActive
                                  ? const Color(0xFF1B6EEB)
                                  : const Color(0xFF7F8AA0),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              navLabels[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? const Color(0xFF1B6EEB)
                                    : const Color(0xFF7F8AA0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            duration: const Duration(milliseconds: 180),
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
              duration: const Duration(milliseconds: 140),
              style: TextStyle(
                color: Colors.white,
                fontSize: _isHighlighted ? 23 : 19,
                fontWeight: _isHighlighted ? FontWeight.w900 : FontWeight.w500,
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

class DiscountPage extends StatelessWidget {
  const DiscountPage({super.key});

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
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDDE2E7)),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
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

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
            children: const [
              _BookingSectionHeading(title: 'Bạn đã xem qua'),
              SizedBox(height: 30),
              _BookingSectionHeading(title: 'Thư viện Coupon'),
              SizedBox(height: 30),
              _BookingSectionHeading(title: 'Đề xuất'),
              SizedBox(height: 30),
              _BookingSectionHeading(
                title: 'Tất cả giao dịch và hoạt động khác',
              ),
            ],
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

class SearchPanel extends StatefulWidget {
  final HotelSearchSelection selection;
  final ValueChanged<String> onSearch;

  const SearchPanel({
    super.key,
    required this.selection,
    required this.onSearch,
  });

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final List<String> _destinations = _availableDestinations;

  String _selectedLocation = 'Địa điểm';

  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_handleSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant SearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection != widget.selection) {
      oldWidget.selection.removeListener(_handleSelectionChanged);
      widget.selection.addListener(_handleSelectionChanged);
    }
  }

  void _handleSelectionChanged() {
    if (mounted) setState(() {});
  }

  void _searchHotels() {
    if (_selectedLocation == 'Địa điểm') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn điểm đến trước khi tìm kiếm'),
        ),
      );
      return;
    }
    widget.onSearch(_selectedLocation);
  }

  @override
  void dispose() {
    widget.selection.removeListener(_handleSelectionChanged);
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final weekday = <String>[
      'Th 2',
      'Th 3',
      'Th 4',
      'Th 5',
      'Th 6',
      'Th 7',
      'CN',
    ];
    final month = date.month;
    final day = date.day;
    return '${weekday[date.weekday - 1]}, $day thg $month';
  }

  void _pickLocation() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _destinations.length,
                      itemBuilder: (context, index) {
                        final item = _destinations[index];
                        final isSelected = item == _selectedLocation;
                        return ListTile(
                          title: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFF2A6EEB),
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedLocation = selected);
    }
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: widget.selection.dateRange,
      helpText: 'Chọn ngày nhận phòng',
      saveText: 'Xác nhận',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A6EEB),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      widget.selection.updateDateRange(picked);
    }
  }

  void _pickGuestOptions() async {
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
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
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
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop({'room': room, 'adult': adult, 'child': child});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A6EEB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

  @override
  Widget build(BuildContext context) {
    final dateRange = widget.selection.dateRange;
    final nights = dateRange.duration.inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1F38),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 88,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: _pickLocation,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.black,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedLocation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.gps_fixed,
                              color: Color(0xFF2A6EEB),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(right: 60),
                    child: Divider(color: Color(0xFFE3E5E8), thickness: 1.2),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.black87,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)} ($nights đêm)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFE3E5E8), thickness: 1.2),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickGuestOptions,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_alt_outlined,
                            color: Colors.black87,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${widget.selection.roomCount} phòng, ${widget.selection.adultCount} người lớn, ${widget.selection.childCount} trẻ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFEBFF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'Bản đồ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2A6EEB),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: const Color(0xFF2A6EEB),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: _searchHotels,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              child: const Text(
                                'Tìm kiếm',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 0,
            child: Row(
              children: [
                const DiscountIconButton(),
                const SizedBox(width: 18),
                const CustomerSupportIconButton(),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestPickerRow extends StatefulWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const _GuestPickerRow({
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  State<_GuestPickerRow> createState() => _GuestPickerRowState();
}

class _GuestPickerRowState extends State<_GuestPickerRow> {
  late final TextEditingController _controller;
  bool _isEmpty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _GuestPickerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value.toString()) {
      _controller.text = widget.value.toString();
      _isEmpty = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyValue(String raw) {
    if (raw.isEmpty) {
      _isEmpty = true;
      _controller.text = '';
      _controller.selection = TextSelection.fromPosition(
        const TextPosition(offset: 0),
      );
      return;
    }

    final parsed = int.tryParse(raw);
    if (parsed == null) {
      _controller.text = _isEmpty ? '' : widget.value.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      return;
    }

    final clamped = parsed.clamp(widget.minValue, widget.maxValue);
    _isEmpty = false;
    widget.onChanged(clamped);
    if (_controller.text != clamped.toString()) {
      _controller.text = clamped.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentValue = widget.value;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => widget.onChanged(
                (currentValue - 1).clamp(widget.minValue, widget.maxValue),
              ),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 62,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _applyValue,
              ),
            ),
            IconButton(
              onPressed: () => widget.onChanged(
                (currentValue + 1).clamp(widget.minValue, widget.maxValue),
              ),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}

class PromoStrip extends StatelessWidget {
  const PromoStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDA3C74),
        borderRadius: BorderRadius.circular(18),
      ),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
          children: [
            TextSpan(
              text: '10.10',
              style: TextStyle(color: Colors.white),
            ),
            WidgetSpan(child: SizedBox(width: 10)),
            TextSpan(
              text: 'Sàn ưu đãi hot chi có ở EPIC Sale 10.10!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );
  }
}

class CouponRow extends StatefulWidget {
  const CouponRow({super.key});

  @override
  State<CouponRow> createState() => _CouponRowState();
}

class _CouponRowState extends State<CouponRow> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Dành riêng cho bạn',
      'Mã cả ngày',
      'Tổng cực D',
      'Mã khách sạn',
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _TagChip(
          label: labels[index],
          isActive: index == _selectedIndex,
          onTap: () => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2A6EEB) : const Color(0xFFE8EEF8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF2A6EEB),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class HotelRowSection extends StatefulWidget {
  final HotelSearchSelection selection;

  const HotelRowSection({super.key, required this.selection});

  @override
  State<HotelRowSection> createState() => _HotelRowSectionState();
}

class _HotelRowSectionState extends State<HotelRowSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const labels = ['Dành cho bạn', ..._availableDestinations];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khách sạn',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            itemCount: labels.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _InlinePill(
              label: labels[index],
              isSelected: index == _selectedIndex,
              onTap: () => setState(() => _selectedIndex = index),
            ),
          ),
        ),
        if (_selectedIndex == 0) ...[
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        HotelDetailPage(selection: widget.selection),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(width: double.infinity, height: 180),
            ),
          ),
        ],
      ],
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _location = widget.location;
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
    if (mounted) setState(() {});
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
                        setState(() => _location = selectedLocation);
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
    final hotels = List.generate(7, (index) => index + 1);
    final dateRange = widget.selection.dateRange;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF19232D),
        elevation: 0,
        titleSpacing: 0,
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
                      color: Color(0xFF68727C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: hotels.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final hotelNumber = hotels[index];
                return _HotelResultCard(
                  number: hotelNumber,
                  location: _location,
                  rating: 8.8 - index * 0.2,
                  reviewCount: 482 + index * 37,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HotelDetailPage(
                        selection: widget.selection,
                        hotelName: 'Khách sạn $hotelNumber',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelResultCard extends StatelessWidget {
  final int number;
  final String location;
  final double rating;
  final int reviewCount;
  final VoidCallback onTap;

  const _HotelResultCard({
    required this.number,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 112,
                height: 142,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: number.isEven
                        ? const [Color(0xFFB8D7E8), Color(0xFF557D91)]
                        : const [Color(0xFFE9D9C2), Color(0xFF9D7856)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 142,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khách sạn $number',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF202A33),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF525D67),
                          fontSize: 14,
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
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC928),
                            size: 18,
                          ),
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC928),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${rating.toStringAsFixed(1)}/10',
                            style: const TextStyle(
                              color: Color(0xFF1688C7),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '$reviewCount đánh giá',
                        style: const TextStyle(
                          color: Color(0xFF7A838C),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Giá phòng sẽ hiển thị tại đây',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFE56A35),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
      final query =
          '[out:json][timeout:20];'
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
      final response = await http
          .post(
            Uri.https('overpass-api.de', '/api/interpreter'),
            headers: const {
              'User-Agent': 'app_mobile/1.0 (nearby hotel places map)',
              'Accept': 'application/json',
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 25));

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

        final category =
            tags['tourism']?.toString() ??
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
              child: CircularProgressIndicator(color: Color(0xFF1674C5)),
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
          fontWeight: FontWeight.w600,
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

class HotelDetailPage extends StatefulWidget {
  final HotelSearchSelection selection;
  final String hotelName;

  const HotelDetailPage({
    super.key,
    required this.selection,
    this.hotelName = 'Tên khách sạn',
  });

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  bool _isSaved = false;
  bool _isSectionBarVisible = false;
  int _selectedSectionIndex = 0;
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
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: -0.08,
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
      final renderObject = sectionKeys[index].currentContext
          ?.findRenderObject();
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
            child: const Text(
              'Khám phá không gian nghỉ dưỡng thoải mái với các tiện ích phù hợp cho chuyến đi của bạn.',
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
            child: const _HotelNearbyPlacesMap(),
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
    return Material(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RoomDetailPage(
              hotelName: widget.hotelName,
              selection: widget.selection,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
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
                child: const Icon(
                  Icons.bed_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng Deluxe giường đôi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF19232D),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '2 khách · 1 giường đôi',
                      style: TextStyle(color: Color(0xFF6D747B), fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
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
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF7D858D)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.selection.removeListener(_handleSelectionChanged);
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
                    itemCount: _hotelAmenities.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.8,
                        ),
                    itemBuilder: (context, index) {
                      final (icon, label) = _hotelAmenities[index];
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
                  for (final (icon, label) in _hotelAmenities.take(4))
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
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=85',
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
                  widget.hotelName,
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
                    for (var index = 0; index < 5; index++)
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD21F),
                        size: 18,
                      ),
                    const SizedBox(width: 4),
                    const Text(
                      '5.0',
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
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Hồ Chí Minh, Quận 2',
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
                                        '19A Nguyễn Bá Huân, Thảo Điền, Thủ Đức',
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
                                const Tooltip(
                                  message: 'Bản đồ',
                                  child: Icon(
                                    Icons.map_outlined,
                                    color: Color(0xFF1674C5),
                                    size: 26,
                                  ),
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
                widget.hotelName,
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
              slivers: [
                SliverToBoxAdapter(child: _buildHotelHero()),
                SliverToBoxAdapter(child: _buildHotelSections()),
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

class RoomBookingPage extends StatefulWidget {
  final String hotelName;
  final HotelSearchSelection selection;

  const RoomBookingPage({
    super.key,
    required this.hotelName,
    required this.selection,
  });

  @override
  State<RoomBookingPage> createState() => _RoomBookingPageState();
}

class _RoomBookingPageState extends State<RoomBookingPage> {
  static const int _nightlyRate = 1250000;
  static const List<_BookingCoupon> _coupons = [
    _BookingCoupon(
      code: 'TRAVEL10',
      title: 'Giảm 10%',
      description: 'Giảm 10% tổng tiền phòng',
      percentOff: 10,
    ),
    _BookingCoupon(
      code: 'WELCOME100',
      title: 'Giảm 100.000đ',
      description: 'Ưu đãi 100.000đ cho đơn đặt phòng',
      amountOff: 100000,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _requestController = TextEditingController();
  int _step = 0;
  _BookingCoupon? _selectedCoupon;
  String? _selectedPaymentMethod;

  int get _nights => widget.selection.dateRange.duration.inDays.clamp(1, 365);

  int get _subtotal => _nightlyRate * _nights * widget.selection.roomCount;

  int get _discount => _selectedCoupon?.discountFor(_subtotal) ?? 0;

  int get _total => _subtotal - _discount;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  String _formatVnd(int amount) {
    final digits = amount.toString();
    final formatted = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write('.');
      }
      formatted.write(digits[index]);
    }
    return '$formatted ₫';
  }

  void _continueToPayment() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  Future<void> _chooseCoupon() async {
    final couponCode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEE5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chọn mã giảm giá',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_offer_outlined),
                title: const Text('Không sử dụng mã'),
                trailing: _selectedCoupon == null
                    ? const Icon(Icons.check_circle, color: Color(0xFF1674C5))
                    : null,
                onTap: () => Navigator.pop(context, 'none'),
              ),
              for (final coupon in _coupons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.confirmation_number_outlined,
                    color: Color(0xFF1674C5),
                  ),
                  title: Text(coupon.title),
                  subtitle: Text('${coupon.description} · ${coupon.code}'),
                  trailing: _selectedCoupon?.code == coupon.code
                      ? const Icon(Icons.check_circle, color: Color(0xFF1674C5))
                      : null,
                  onTap: () => Navigator.pop(context, coupon.code),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || couponCode == null) return;
    setState(() {
      _selectedCoupon = couponCode == 'none'
          ? null
          : _coupons.firstWhere((coupon) => coupon.code == couponCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = widget.selection.dateRange;
    final guestCount =
        widget.selection.adultCount + widget.selection.childCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0874C9),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: _step == 1 ? 'Quay lại bước đặt' : 'Quay lại chi tiết phòng',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hotelName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              _step == 0 ? 'Bước 1 · Đặt phòng' : 'Bước 2 · Thanh toán',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _step == 0
          ? Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _bookingSection(
                    title: 'Thông tin phòng',
                    icon: Icons.king_bed_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phòng Deluxe giường đôi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19232D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _bookingInfoLine(
                          Icons.calendar_month_outlined,
                          '${dateRange.start.day}/${dateRange.start.month} - ${dateRange.end.day}/${dateRange.end.month} · $_nights đêm',
                        ),
                        const SizedBox(height: 8),
                        _bookingInfoLine(
                          Icons.people_alt_outlined,
                          '${widget.selection.roomCount} phòng · $guestCount khách',
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        const Text(
                          'Tiện ích phòng',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        const Wrap(
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
                              icon: Icons.coffee_maker_outlined,
                              label: 'Ấm đun nước',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _bookingSection(
                    title: 'Thông tin khách hàng',
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      children: [
                        _bookingTextField(
                          controller: _nameController,
                          label: 'Họ và tên',
                          hint: 'Nhập họ tên người lưu trú',
                          icon: Icons.person_outline_rounded,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập họ và tên'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _bookingTextField(
                          controller: _phoneController,
                          label: 'Số điện thoại',
                          hint: 'Nhập số điện thoại',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final phone = value?.trim() ?? '';
                            if (!RegExp(r'^\+?[0-9\s-]{9,15}$')
                                .hasMatch(phone)) {
                              return 'Vui lòng nhập số điện thoại hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _bookingTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'name@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (!RegExp(
                              r"^[\w.!#$%&'*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$",
                            ).hasMatch(email)) {
                              return 'Vui lòng nhập email hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _bookingSection(
                    title: 'Yêu cầu đặc biệt',
                    icon: Icons.chat_bubble_outline_rounded,
                    child: TextField(
                      controller: _requestController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _bookingInputDecoration(
                        hint: 'Ví dụ: phòng tầng cao, giường phụ...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _bookingSection(
                    title: 'Mã giảm giá',
                    icon: Icons.confirmation_number_outlined,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _chooseCoupon,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F8FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE3EAF1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer_outlined,
                              color: Color(0xFF1674C5),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedCoupon == null
                                    ? 'Chọn phiếu giảm giá hoặc coupon'
                                    : '${_selectedCoupon!.title} · ${_selectedCoupon!.code}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _selectedCoupon == null ? 'Chọn' : 'Đổi',
                              style: const TextStyle(
                                color: Color(0xFF1674C5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _bookingSection(
                    title: 'Chi tiết thanh toán',
                    icon: Icons.receipt_long_outlined,
                    child: Column(
                      children: [
                        _priceLine(
                          '$_nights đêm × ${widget.selection.roomCount} phòng',
                          _formatVnd(_subtotal),
                        ),
                        if (_selectedCoupon != null) ...[
                          const SizedBox(height: 10),
                          _priceLine(
                            'Ưu đãi ${_selectedCoupon!.code}',
                            '- ${_formatVnd(_discount)}',
                            valueColor: const Color(0xFF24824B),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _priceLine(
                          'Tổng cộng',
                          _formatVnd(_total),
                          isBold: true,
                        ),
                        const SizedBox(height: 6),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Giá phòng ước tính: 1.250.000 ₫ / đêm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7B858F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          : _buildPaymentStep(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _step == 0
                  ? _continueToPayment
                  : _selectedPaymentMethod == null
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã ghi nhận phương thức thanh toán. Đây là bản xem trước.',
                          ),
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1674C5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _step == 0
                    ? 'Tiếp tục'
                    : _selectedPaymentMethod == null
                    ? 'Chọn phương thức thanh toán'
                    : 'Thanh toán ${_formatVnd(_total)}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0874C9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text(
                'Tổng giá tiền',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                _formatVnd(_total),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.hotelName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(
            color: Color(0xFF19232D),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _paymentOption(
          id: 'vietqr',
          title: 'VietQR',
          subtitle: 'Quét mã bằng ứng dụng ngân hàng',
          icon: Icons.qr_code_2_rounded,
          color: const Color(0xFF0874C9),
        ),
        _paymentOption(
          id: 'wallet',
          title: 'Ví điện tử',
          subtitle: 'Apple Pay · ZaloPay · MoMo · ShopeePay',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF8E44AD),
        ),
        _paymentOption(
          id: 'mobile_banking',
          title: 'Ngân hàng di động',
          subtitle: 'Thanh toán qua ứng dụng ngân hàng',
          icon: Icons.phone_android_rounded,
          color: const Color(0xFF1674C5),
        ),
        _paymentOption(
          id: 'bank_transfer',
          title: 'Chuyển tiền qua VietinBank',
          subtitle: 'Chuyển khoản ngân hàng',
          icon: Icons.account_balance_outlined,
          color: const Color(0xFF1674C5),
        ),
        _paymentOption(
          id: 'card',
          title: 'Thẻ thanh toán',
          subtitle: 'Visa · Mastercard · JCB · AMEX',
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF34495E),
        ),
        _paymentOption(
          id: 'pay_later',
          title: 'Home PayLater',
          subtitle: 'Thanh toán trả sau',
          icon: Icons.schedule_rounded,
          color: const Color(0xFFE05A45),
        ),
        _bookingSection(
          title: 'Mã giảm giá',
          icon: Icons.confirmation_number_outlined,
          child: Row(
            children: [
              const Expanded(
                child: Text('Áp dụng mã giảm giá hoặc phiếu quà tặng'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _step = 0);
                },
                child: const Text('Chỉnh sửa'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = _selectedPaymentMethod == id;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? const Color(0xFF1674C5) : const Color(0xFFE5E9ED),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedPaymentMethod = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF1674C5)
                        : const Color(0xFFBAC4CE),
                    width: selected ? 2 : 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1674C5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF707A84),
                      ),
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

  Widget _bookingSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1674C5), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF19232D),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _bookingInfoLine(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF78838D)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF59636D), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _bookingTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: _bookingInputDecoration(
        label: label,
        hint: hint,
        prefixIcon: icon,
      ),
    );
  }

  InputDecoration _bookingInputDecoration({
    String? label,
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      filled: true,
      fillColor: const Color(0xFFFAFBFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E6EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E6EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1674C5), width: 1.5),
      ),
    );
  }

  Widget _priceLine(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final style = TextStyle(
      color: valueColor ?? const Color(0xFF19232D),
      fontSize: isBold ? 16 : 14,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 12),
        Text(value, style: style),
      ],
    );
  }
}

class _RoomAmenityItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoomAmenityItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF1674C5)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF394550),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomImageNavigationButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoomImageNavigationButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        disabledColor: Colors.white.withValues(alpha: 0.45),
        icon: Icon(icon, size: 28),
      ),
    );
  }
}

class _RoomDetailTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoomDetailTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1674C5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF394550),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomDetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RoomDetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1674C5)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF6D747B), fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF26323D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotelSectionNavigationBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _HotelSectionNavigationBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var index = 0; index < labels.length; index++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onSelect(index),
                      child: Center(
                        child: Text(
                          labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: index == selectedIndex
                                ? const Color(0xFF1674C5)
                                : const Color(0xFF70777E),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 3,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFFE8EBEE)),
                ),
                Align(
                  alignment: Alignment(
                    -1 + (2 * selectedIndex + 1) / labels.length,
                    0,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1 / labels.length,
                    child: const ColoredBox(color: Color(0xFF9BD721)),
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

class _SearchOptionBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SearchOptionBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2A6EEB), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D747B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF19232D),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF7D858D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlinePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InlinePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2A6EEB)
                : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class BrandOfferSection extends StatelessWidget {
  const BrandOfferSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ưu đãi thương hiệu 10.10',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 138,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                SizedBox(
                  width: 130,
                  child: BrandOfferCard(
                    color: Color(0xFFD7C298),
                    title: 'MƯỜNG THANH',
                    discount: '20%',
                  ),
                ),
                SizedBox(width: 14),
                SizedBox(
                  width: 130,
                  child: BrandOfferCard(
                    color: Color(0xFFE5D4A6),
                    title: 'HANOI BLISS',
                    discount: '20%',
                  ),
                ),
                SizedBox(width: 14),
                SizedBox(
                  width: 130,
                  child: BrandOfferCard(
                    color: Color(0xFF3F78D7),
                    title: 'HOTELS & RESORTS',
                    discount: '40%',
                  ),
                ),
                SizedBox(width: 14),
                SizedBox(
                  width: 130,
                  child: BrandOfferCard(
                    color: Color(0xFF59A88A),
                    title: 'MELIÁ HOTELS',
                    discount: '30%',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BrandOfferCard extends StatelessWidget {
  final Color color;
  final String title;
  final String discount;

  const BrandOfferCard({
    super.key,
    required this.color,
    required this.title,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Giảm đến',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            discount,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoverBanner extends StatelessWidget {
  const DiscoverBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vô vàn ưu đãi khác',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD8D4A8), Color(0xFFB8C480)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 22,
                      left: 30,
                      right: 30,
                      bottom: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 18,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 36,
                      bottom: 50,
                      child: Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9D864),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Du lịch',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0E3A91),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Úc',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0E3A91),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Giảm đến',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0E3A91),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '50%',
                      style: TextStyle(
                        fontSize: 36,
                        color: Color(0xFF0E3A91),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ScrollTopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ScrollTopButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EBF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Lên đầu trang',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A6EEB),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
