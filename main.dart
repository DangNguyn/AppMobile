import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class TravelHomePage extends StatefulWidget {
  const TravelHomePage({super.key});

  @override
  State<TravelHomePage> createState() => _TravelHomePageState();
}

class _TravelHomePageState extends State<TravelHomePage> {
  final ScrollController _scrollController = ScrollController();
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

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
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
                                const SearchPanel(),
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
                                      const HotelRowSection(),
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
                        color: Colors.white.withOpacity(0.95),
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
            color: Colors.black.withOpacity(0.08),
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
            color: Colors.black.withOpacity(0.08),
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
  const SearchPanel({super.key});

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final List<String> _destinations = [
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

  String _selectedLocation = 'Địa điểm';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().add(const Duration(days: 1)),
    end: DateTime.now().add(const Duration(days: 3)),
  );
  int _roomCount = 1;
  int _adultCount = 2;
  int _childCount = 0;

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
      initialDateRange: _dateRange,
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
      setState(() => _dateRange = picked);
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
        int room = _roomCount;
        int adult = _adultCount;
        int child = _childCount;

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
      setState(() {
        _roomCount = result['room'] ?? _roomCount;
        _adultCount = result['adult'] ?? _adultCount;
        _childCount = result['child'] ?? _childCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights = _dateRange.duration.inDays;

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
                              '${_formatDate(_dateRange.start)} - ${_formatDate(_dateRange.end)} ($nights đêm)',
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
                              '$_roomCount phòng, $_adultCount người lớn, $_childCount trẻ',
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
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A6EEB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
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
  const HotelRowSection({super.key});

  @override
  State<HotelRowSection> createState() => _HotelRowSectionState();
}

class _HotelRowSectionState extends State<HotelRowSection> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    const labels = ['Lên đến 250K/đ', 'Sắp hết', 'Giá tốt', 'Ưu đãi hôm nay'];

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
              onTap: () => setState(
                () => _selectedIndex = _selectedIndex == index ? -1 : index,
              ),
            ),
          ),
        ),
      ],
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
              color: Colors.white.withOpacity(0.9),
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
                          color: Colors.white.withOpacity(0.2),
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
                          color: Colors.green.withOpacity(0.25),
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
                          color: Colors.white.withOpacity(0.2),
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
