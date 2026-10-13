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
