import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'account_page.dart';
import 'booking_app.dart' as hotel_booking;
import 'destination_images.dart';
import 'explore_page.dart';
import 'onboarding_widgets.dart';
import 'splash_screen.dart';
import 'user_service.dart';
import 'welcome_screen.dart';
import 'api/api_client.dart';
import 'api/api_repository.dart';
import 'api/models.dart';
import 'voucher_storage_service.dart';
import 'ui_motion.dart';

enum VietnameseInputMode { telex, vni }

class _SavedConversation {
  const _SavedConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<_AiMessage> messages;
  final DateTime updatedAt;
}

class _ConversationStore {
  static const _key = 'fomogo_saved_conversations';

  static Future<List<_SavedConversation>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return <_SavedConversation>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <_SavedConversation>[];
    return decoded
        .whereType<Map>()
        .map((item) {
          final messages = (item['messages'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (message) => _AiMessage(
                  text: '${message['text'] ?? ''}',
                  isUser: message['isUser'] == true,
                ),
              )
              .where((message) => message.text.isNotEmpty)
              .toList();
          return _SavedConversation(
            id: '${item['id'] ?? ''}',
            title: '${item['title'] ?? 'Cuộc trò chuyện'}',
            messages: messages,
            updatedAt: DateTime.tryParse('${item['updatedAt'] ?? ''}') ??
                DateTime.fromMillisecondsSinceEpoch(0),
          );
        })
        .where((conversation) => conversation.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> save(_SavedConversation conversation) async {
    final conversations = await load();
    final index =
        conversations.indexWhere((item) => item.id == conversation.id);
    if (index == -1) {
      conversations.insert(0, conversation);
    } else {
      conversations[index] = conversation;
    }
    await _write(conversations);
  }

  static Future<void> delete(String id) async {
    final conversations = await load();
    conversations.removeWhere((conversation) => conversation.id == id);
    await _write(conversations);
  }

  static Future<void> _write(List<_SavedConversation> conversations) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(
        conversations
            .map(
              (conversation) => {
                'id': conversation.id,
                'title': conversation.title,
                'updatedAt': conversation.updatedAt.toIso8601String(),
                'messages': conversation.messages
                    .map((message) => {
                          'text': message.text,
                          'isUser': message.isUser,
                        })
                    .toList(),
              },
            )
            .toList(),
      ),
    );
  }
}

class VietnameseUnicodeInput {
  static String convert(String value, VietnameseInputMode mode) {
    return value.replaceAllMapped(
      RegExp(r'[^\s]+'),
      (match) => _convertWord(match.group(0)!, mode),
    );
  }

  static String _convertWord(String word, VietnameseInputMode mode) {
    var result = word;
    String? tone;
    if (mode == VietnameseInputMode.telex &&
        result.length > 1 &&
        'sfrxj'.contains(result[result.length - 1].toLowerCase())) {
      tone = result[result.length - 1].toLowerCase();
      result = result.substring(0, result.length - 1);
    } else if (mode == VietnameseInputMode.vni &&
        result.length > 1 &&
        '12345'.contains(result[result.length - 1])) {
      tone = result[result.length - 1];
      result = result.substring(0, result.length - 1);
    }

    if (!RegExp(r'[aeiouyăâêôơưAEIOUYĂÂÊÔƠƯ]').hasMatch(result)) {
      return word;
    }

    if (mode == VietnameseInputMode.telex) {
      result = result
          .replaceAll('dd', 'đ')
          .replaceAll('DD', 'Đ')
          .replaceAll('aa', 'â')
          .replaceAll('AA', 'Â')
          .replaceAll('aw', 'ă')
          .replaceAll('AW', 'Ă')
          .replaceAll('ee', 'ê')
          .replaceAll('EE', 'Ê')
          .replaceAll('oo', 'ô')
          .replaceAll('OO', 'Ô')
          .replaceAll('ow', 'ơ')
          .replaceAll('OW', 'Ơ')
          .replaceAll('uw', 'ư')
          .replaceAll('UW', 'Ư');
    } else {
      result = result
          .replaceAll('a6', 'â')
          .replaceAll('A6', 'Â')
          .replaceAll('a8', 'ă')
          .replaceAll('A8', 'Ă')
          .replaceAll('e6', 'ê')
          .replaceAll('E6', 'Ê')
          .replaceAll('o6', 'ô')
          .replaceAll('O6', 'Ô')
          .replaceAll('o7', 'ơ')
          .replaceAll('O7', 'Ơ')
          .replaceAll('u7', 'ư')
          .replaceAll('U7', 'Ư')
          .replaceAll('d9', 'đ')
          .replaceAll('D9', 'Đ');
    }

    if (tone == null) return result;
    final toneIndex = mode == VietnameseInputMode.telex
        ? <String, int>{'s': 1, 'f': 2, 'r': 3, 'x': 4, 'j': 5}[tone]!
        : int.parse(tone);
    for (var index = result.length - 1; index >= 0; index--) {
      final accented = _addTone(result[index], toneIndex);
      if (accented != result[index]) {
        return result.substring(0, index) +
            accented +
            result.substring(index + 1);
      }
    }
    return result;
  }

  static String _addTone(String character, int tone) {
    const toneMaps = [
      {
        'a': 'á',
        'ă': 'ắ',
        'â': 'ấ',
        'e': 'é',
        'ê': 'ế',
        'i': 'í',
        'o': 'ó',
        'ô': 'ố',
        'ơ': 'ớ',
        'u': 'ú',
        'ư': 'ứ',
        'y': 'ý',
        'A': 'Á',
        'Ă': 'Ắ',
        'Â': 'Ấ',
        'E': 'É',
        'Ê': 'Ế',
        'I': 'Í',
        'O': 'Ó',
        'Ô': 'Ố',
        'Ơ': 'Ớ',
        'U': 'Ú',
        'Ư': 'Ứ',
        'Y': 'Ý',
      },
      {
        'a': 'à',
        'ă': 'ằ',
        'â': 'ầ',
        'e': 'è',
        'ê': 'ề',
        'i': 'ì',
        'o': 'ò',
        'ô': 'ồ',
        'ơ': 'ờ',
        'u': 'ù',
        'ư': 'ừ',
        'y': 'ỳ',
        'A': 'À',
        'Ă': 'Ằ',
        'Â': 'Ầ',
        'E': 'È',
        'Ê': 'Ề',
        'I': 'Ì',
        'O': 'Ò',
        'Ô': 'Ồ',
        'Ơ': 'Ờ',
        'U': 'Ù',
        'Ư': 'Ừ',
        'Y': 'Ỳ',
      },
      {
        'a': 'ả',
        'ă': 'ẳ',
        'â': 'ẩ',
        'e': 'ẻ',
        'ê': 'ể',
        'i': 'ỉ',
        'o': 'ỏ',
        'ô': 'ổ',
        'ơ': 'ở',
        'u': 'ủ',
        'ư': 'ử',
        'y': 'ỷ',
        'A': 'Ả',
        'Ă': 'Ẳ',
        'Â': 'Ẩ',
        'E': 'Ẻ',
        'Ê': 'Ể',
        'I': 'Ỉ',
        'O': 'Ỏ',
        'Ô': 'Ổ',
        'Ơ': 'Ở',
        'U': 'Ủ',
        'Ư': 'Ử',
        'Y': 'Ỷ',
      },
      {
        'a': 'ã',
        'ă': 'ẵ',
        'â': 'ẫ',
        'e': 'ẽ',
        'ê': 'ễ',
        'i': 'ĩ',
        'o': 'õ',
        'ô': 'ỗ',
        'ơ': 'ỡ',
        'u': 'ũ',
        'ư': 'ữ',
        'y': 'ỹ',
        'A': 'Ã',
        'Ă': 'Ẵ',
        'Â': 'Ẫ',
        'E': 'Ẽ',
        'Ê': 'Ễ',
        'I': 'Ĩ',
        'O': 'Õ',
        'Ô': 'Ỗ',
        'Ơ': 'Ỡ',
        'U': 'Ũ',
        'Ư': 'Ữ',
        'Y': 'Ỹ',
      },
      {
        'a': 'ạ',
        'ă': 'ặ',
        'â': 'ậ',
        'e': 'ẹ',
        'ê': 'ệ',
        'i': 'ị',
        'o': 'ọ',
        'ô': 'ộ',
        'ơ': 'ợ',
        'u': 'ụ',
        'ư': 'ự',
        'y': 'ỵ',
        'A': 'Ạ',
        'Ă': 'Ặ',
        'Â': 'Ậ',
        'E': 'Ẹ',
        'Ê': 'Ệ',
        'I': 'Ị',
        'O': 'Ọ',
        'Ô': 'Ộ',
        'Ơ': 'Ợ',
        'U': 'Ụ',
        'Ư': 'Ự',
        'Y': 'Ỵ',
      },
    ];
    return toneMaps[tone - 1][character] ?? character;
  }
}

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
        pageTransitionsTheme: appPageTransitionsTheme,
      ),
      home: SplashScreen(homeBuilder: (_) => const TravelHomePage()),
    );
  }
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: userService.isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Không thể tải dữ liệu ứng dụng: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: onboardingBlue),
            ),
          );
        }
        if (!snapshot.data!) {
          return WelcomeScreen(homeBuilder: (_) => const TravelHomePage());
        }
        return const TravelHomePage();
      },
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
  final hotel_booking.HotelSearchSelection _hotelSearchSelection =
      hotel_booking.HotelSearchSelection();
  final Set<String> _savedArticleTitles = {};
  bool _showScrollTopButton = false;
  int _selectedNavIndex = 0;

  void _toggleSavedArticle(TravelArticle article) {
    setState(() {
      if (!_savedArticleTitles.add(article.title)) {
        _savedArticleTitles.remove(article.title);
      }
    });
  }

  Future<void> _restartOnboardingAfterLogout() async {
    unawaited(apiRepository.client.clearToken());
    await userService.clearCustomerData();
    if (!mounted) return;
    _savedArticleTitles.clear();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            WelcomeScreen(homeBuilder: (_) => const TravelHomePage()),
      ),
      (route) => false,
    );
  }

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
        builder: (_) => hotel_booking.HotelSearchResultsPage(
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
                child: _selectedNavIndex == 1
                    ? ExplorePage(
                        savedArticleTitles: _savedArticleTitles,
                        onToggleSaved: _toggleSavedArticle,
                        onExploreDestination: _openHotelSearchResults,
                      )
                    : _selectedNavIndex == 2
                        ? BookingPage(
                            onFindHotel: () {
                              setState(() {
                                _selectedNavIndex = 0;
                                _showScrollTopButton = false;
                              });
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                            },
                          )
                        : _selectedNavIndex == 3
                            ? SavedPage(
                                selection: _hotelSearchSelection,
                                savedArticles: allTravelArticles
                                    .where(
                                      (article) => _savedArticleTitles
                                          .contains(article.title),
                                    )
                                    .toList(),
                                onRemoveArticle: _toggleSavedArticle,
                                onOpenArticle: (article) =>
                                    Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => TravelArticleDetailPage(
                                      article: article,
                                      onExploreDestination:
                                          _openHotelSearchResults,
                                    ),
                                  ),
                                ),
                              )
                            : _selectedNavIndex == 4
                                ? AccountScreen(
                                    onLogout: _restartOnboardingAfterLogout)
                                : Stack(
                                    children: [
                                      SingleChildScrollView(
                                        controller: _scrollController,
                                        physics: const ClampingScrollPhysics(),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            SearchPanel(
                                              selection: _hotelSearchSelection,
                                              onSearch: _openHotelSearchResults,
                                            ),
                                            const SizedBox(height: 26),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 18,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SectionHeader(
                                                    title:
                                                        'Ưu đãi từ voucher',
                                                  ),
                                                  const SizedBox(height: 12),
                                                  const _HomeVoucherSection(),
                                                  const SizedBox(height: 16),
                                                  HotelRowSection(
                                                      selection:
                                                          _hotelSearchSelection),
                                                  const SizedBox(height: 20),
                                                  BrandOfferSection(
                                                    selection:
                                                        _hotelSearchSelection,
                                                  ),
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
                                          child: ScrollTopButton(
                                              onPressed: _scrollToTop),
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
                            if (index == 0)
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  isActive
                                      ? const Color(0xFF1B6EEB)
                                      : const Color(0xFF7F8AA0),
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  'assets/images/fomogo_mark.png',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'FomoGo',
                                ),
                              )
                            else
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
            width: 36,
            height: 36,
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
                fontSize: _isHighlighted ? 20 : 17,
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
    return const hotel_booking.DiscountPage();
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
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          tooltip: 'Hỗ trợ khách hàng',
          onPressed: _openSupportPage,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.chat_bubble_outline_rounded,
            color: _isHovered ? const Color(0xFFB8D9FF) : Colors.white,
            size: 21,
          ),
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

Future<bool> _confirmConversationDeletion(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa cuộc trò chuyện'),
      content: const Text('Bạn có muốn xóa tin nhắn này không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Không'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFE4E6),
            foregroundColor: const Color(0xFFDC2626),
          ),
          child: const Text('Có'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _CustomerSupportPageState extends State<CustomerSupportPage> {
  int _selectedTab = 0;
  int _selectedFilter = 0;
  List<_SavedConversation> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversations = await _ConversationStore.load();
    if (mounted) setState(() => _conversations = conversations);
  }

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
          child: _conversations.isEmpty
              ? Center(
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
                          onPressed: _openNewConversation,
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final userMessages = conversation.messages
                        .where((message) => message.isUser)
                        .toList();
                    final preview =
                        userMessages.isEmpty ? null : userMessages.last.text;
                    return Dismissible(
                      key: ValueKey(conversation.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final confirmed =
                            await _confirmConversationDeletion(context);
                        if (!confirmed) return false;
                        await _ConversationStore.delete(conversation.id);
                        if (mounted) _loadConversations();
                        return true;
                      },
                      child: ListTile(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AiConversationPage(
                                conversation: conversation,
                              ),
                            ),
                          );
                          _loadConversations();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: const Color(0xFFF5F8FC),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE4F4FC),
                          child: Icon(Icons.chat_bubble_outline_rounded,
                              color: Color(0xFF2A6EEB)),
                        ),
                        title: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          preview ?? 'Chưa có tin nhắn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 18, 18),
            child: FilledButton.icon(
              onPressed: _openNewConversation,
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

  void _openNewConversation() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const AiConversationPage(),
          ),
        )
        .then((_) => _loadConversations());
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

class AiConversationPage extends StatefulWidget {
  const AiConversationPage({
    super.key,
    this.conversation,
  });

  final _SavedConversation? conversation;

  @override
  State<AiConversationPage> createState() => _AiConversationPageState();
}

class _AiConversationPageState extends State<AiConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesController = ScrollController();
  late final String _conversationId;
  late final List<_AiMessage> _messages;
  bool _isTyping = false;
  late final hotel_booking.HotelSearchSelection _hotelSearchSelection;

  @override
  void initState() {
    super.initState();
    final saved = widget.conversation;
    _conversationId =
        saved?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _messages = saved == null
        ? [
            const _AiMessage(
              text:
                  'Xin chào! Mình là trợ lý FomoGo. Bạn có thể hỏi mình về khách sạn, phòng trống hoặc cách sử dụng tài khoản nhé.',
              isUser: false,
            ),
          ]
        : List<_AiMessage>.from(saved.messages);
    _hotelSearchSelection = hotel_booking.HotelSearchSelection();
    _saveConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesController.dispose();
    _hotelSearchSelection.dispose();
    super.dispose();
  }

  void _sendMessage([String? suggestedMessage]) {
    final text = (suggestedMessage ?? _messageController.text).trim();
    if (text.isEmpty || _isTyping) return;
    _messageController.clear();
    setState(() {
      _messages.add(_AiMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _saveConversation();
    _scrollToBottom();
    _respondTo(text);
  }

  Future<void> _respondTo(String text) async {
    final normalized = _normalize(text);
    try {
      if (_isHotelSearch(normalized)) {
        final hotels = await apiRepository.hotels();
        final city = _cityFromMessage(normalized);
        final filtered = city == null
            ? hotels
            : hotels
                .where((hotel) => _normalize('${hotel.city} ${hotel.address}')
                    .contains(_normalize(city)))
                .toList();

        if (_isRoomRequest(normalized)) {
          if (filtered.isEmpty) {
            _addAssistantMessage(
              'Mình chưa tìm thấy khách sạn phù hợp${city == null ? '' : ' ở $city'} để kiểm tra phòng trống.',
            );
            return;
          }
          final today = DateTime.now();
          final tomorrow = today.add(const Duration(days: 1));
          final availableByHotel = await Future.wait(
            filtered.map(
              (hotel) => apiRepository
                  .availableRooms(
                    hotelId: hotel.id,
                    checkIn: _dateString(today),
                    checkOut: _dateString(tomorrow),
                  )
                  .then((rooms) => (hotel: hotel, rooms: rooms)),
            ),
          );
          final available = availableByHotel
              .where((result) => result.rooms.isNotEmpty)
              .toList();
          if (available.isNotEmpty) {
            final result = available.first;
            _addAssistantMessage(
              'Mình tìm thấy ${result.rooms.length} phòng trống tại ${result.hotel.name}${city == null ? '' : ' ở $city'}.',
              rooms: result.rooms,
            );
          } else {
            _addAssistantMessage(
              'Hiện chưa có phòng trống${city == null ? '' : ' ở $city'} cho ngày mai.',
            );
          }
          return;
        }

        _addAssistantMessage(
          filtered.isEmpty
              ? 'Mình chưa tìm thấy khách sạn phù hợp ở ${city ?? 'khu vực này'}. Bạn thử đổi địa điểm hoặc hỏi mình về một thành phố khác nhé.'
              : 'Mình tìm thấy ${filtered.length} khách sạn${city == null ? '' : ' ở $city'} phù hợp. Bạn vuốt để xem và chọn một khách sạn để xem phòng trống.',
          hotels: filtered,
        );
        return;
      }

      if (_isAccountQuestion(normalized)) {
        _addAssistantMessage(_accountHelpFor(normalized));
        return;
      }

      _addAssistantMessage(
        'Mình đã nhận được yêu cầu của bạn. Bạn có thể nói rõ thêm điều bạn muốn tìm hoặc thao tác cần thực hiện để mình hỗ trợ chính xác hơn nhé.',
      );
    } on ApiException catch (error) {
      _addAssistantMessage(
          'Mình chưa thể tải dữ liệu lúc này: ${error.message}');
    } catch (_) {
      _addAssistantMessage(
        'Mình chưa kết nối được với dữ liệu khách sạn. Bạn thử lại sau ít phút nhé.',
      );
    }
  }

  void _addAssistantMessage(String text,
      {List<Hotel> hotels = const [], List<Room> rooms = const []}) {
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_AiMessage(
        text: text,
        isUser: false,
        hotels: hotels,
        rooms: rooms,
      ));
    });
    _saveConversation();
    _scrollToBottom();
  }

  Future<void> _saveConversation() {
    final firstUserMessage = _messages
        .where((message) => message.isUser)
        .map((message) => message.text.trim())
        .firstWhere((text) => text.isNotEmpty,
            orElse: () => 'Cuộc trò chuyện mới');
    final title = firstUserMessage.length > 42
        ? '${firstUserMessage.substring(0, 42)}…'
        : firstUserMessage;
    return _ConversationStore.save(
      _SavedConversation(
        id: _conversationId,
        title: title,
        messages: List<_AiMessage>.from(_messages),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _openHotelDetail(Hotel hotel) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => hotel_booking.HotelDetailPage(
          selection: _hotelSearchSelection,
          hotelName: hotel.name,
          hotelId: hotel.id,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesController.hasClients) {
        _messagesController.animateTo(
          _messagesController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isHotelSearch(String text) =>
      text.contains('khach san') ||
      text.contains('hotel') ||
      text.contains('phong trong') ||
      text.contains('phong nao') ||
      text.contains('con bao nhieu');

  bool _isRoomRequest(String text) =>
      text.contains('phong') ||
      text.contains('room') ||
      text.contains('cho nghi') ||
      text.contains('luu tru');

  bool _isAccountQuestion(String text) =>
      text.contains('dang xuat') ||
      text.contains('tai khoan') ||
      text.contains('thong tin ca nhan') ||
      text.contains('doi mat khau') ||
      text.contains('cap nhat thong tin');

  String _accountHelpFor(String text) {
    if (text.contains('dang xuat')) {
      return 'Để đăng xuất: 1) Vào mục Tài khoản ở thanh điều hướng dưới cùng. 2) Nhấn biểu tượng Cài đặt ở góc phải. 3) Chọn “Đăng xuất” và xác nhận. Mình sẽ đưa bạn về màn hình chào mừng sau khi đăng xuất.';
    }
    if (text.contains('doi mat khau')) {
      return 'Bạn vào Tài khoản → Cài đặt → Bảo mật để đổi mật khẩu. Hãy dùng mật khẩu mới đủ mạnh và không chia sẻ cho người khác nhé.';
    }
    if (text.contains('thong tin') || text.contains('cap nhat')) {
      return 'Bạn vào Tài khoản → chọn “Chỉnh sửa hồ sơ”. Tại đây có thể cập nhật họ tên, ngày sinh, giới tính, email và số điện thoại, sau đó nhấn Lưu thay đổi.';
    }
    return 'Bạn vào mục Tài khoản ở thanh điều hướng dưới cùng để quản lý hồ sơ, cài đặt và bảo mật. Nếu muốn chỉnh thông tin, chọn “Chỉnh sửa hồ sơ”.';
  }

  String _normalize(String value) {
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
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
      'đ': 'd',
    };
    var result = value.toLowerCase();
    replacements.forEach((from, to) {
      result = result.replaceAll(from, to);
    });
    return result.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  }

  String? _cityFromMessage(String text) {
    const cities = [
      'da lat',
      'da nang',
      'nha trang',
      'ha noi',
      'ho chi minh',
      'phu quoc',
      'hoi an',
      'ha long',
      'hue',
      'sa pa',
    ];
    for (final city in cities) {
      if (text.contains(city)) return city == 'da lat' ? 'Đà Lạt' : city;
    }
    return null;
  }

  String _dateString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F38),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF2A6EEB),
              child: Icon(Icons.auto_awesome, size: 19, color: Colors.white),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trợ lý FomoGo', style: TextStyle(fontSize: 17)),
                Text('Luôn sẵn sàng hỗ trợ',
                    style: TextStyle(fontSize: 11, color: Color(0xFFBFD8FF))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa cuộc trò chuyện',
            onPressed: () async {
              final confirmed = await _confirmConversationDeletion(context);
              if (!confirmed) return;
              await _ConversationStore.delete(_conversationId);
              if (mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _messagesController,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingBubble();
                }
                return _AiMessageBubble(
                  message: _messages[index],
                  onHotelSelected: _openHotelDetail,
                );
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 4,
                autocorrect: false,
                enableSuggestions: true,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isTyping ? null : _sendMessage,
              icon: const Icon(Icons.arrow_upward_rounded),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2A6EEB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiMessage {
  const _AiMessage({
    required this.text,
    required this.isUser,
    this.hotels = const [],
    this.rooms = const [],
  });

  final String text;
  final bool isUser;
  final List<Hotel> hotels;
  final List<Room> rooms;
}

class _AiMessageBubble extends StatelessWidget {
  const _AiMessageBubble({
    required this.message,
    required this.onHotelSelected,
  });

  final _AiMessage message;
  final void Function(Hotel hotel) onHotelSelected;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: message.isUser ? const Color(0xFF2A6EEB) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(message.isUser ? 18 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 18),
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x120E1F38), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: message.isUser ? Colors.white : const Color(0xFF243247),
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          bubble,
          if (message.hotels.isNotEmpty) ...[
            const SizedBox(height: 10),
            _HotelAiSlider(
              hotels: message.hotels,
              onHotelSelected: onHotelSelected,
            ),
          ],
          if (message.rooms.isNotEmpty) ...[
            const SizedBox(height: 10),
            _RoomAiSlider(rooms: message.rooms),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Chip(
            avatar:
                Icon(Icons.auto_awesome, size: 16, color: Color(0xFF2A6EEB)),
            label: Text('Đang tìm thông tin...'),
            backgroundColor: Colors.white,
          ),
        ),
      );
}

class _HotelAiSlider extends StatelessWidget {
  const _HotelAiSlider({
    required this.hotels,
    required this.onHotelSelected,
  });

  final List<Hotel> hotels;
  final void Function(Hotel hotel) onHotelSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 188,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: hotels.length,
          separatorBuilder: (_, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final hotel = hotels[index];
            return SizedBox(
              width: 246,
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 76,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1674C5), Color(0xFF73C8F5)],
                        ),
                      ),
                      child: FutureBuilder<List<String>>(
                        future: apiRepository.hotelImages(hotel.id),
                        builder: (context, snapshot) {
                          final images = snapshot.data ?? const <String>[];
                          if (images.isNotEmpty) {
                            return Image.network(
                              images.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, error, stackTrace) =>
                                  _hotelImageFallback(),
                            );
                          }
                          return _hotelImageFallback();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 5),
                      child: Text(
                        hotel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        hotel.address.isEmpty ? hotel.city : hotel.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF718096)),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => onHotelSelected(hotel),
                        child: const Text('Xem phòng trống'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _hotelImageFallback() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1674C5), Color(0xFF73C8F5)],
          ),
        ),
        child: Center(
          child: Icon(Icons.hotel_rounded, color: Colors.white, size: 38),
        ),
      );
}

class _RoomAiSlider extends StatelessWidget {
  const _RoomAiSlider({required this.rooms});

  final List<Room> rooms;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 122,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: rooms.length,
          separatorBuilder: (_, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final room = rooms[index];
            return FutureBuilder<List<String>>(
              future: apiRepository.roomTypeImages(room.roomTypeId),
              builder: (context, snapshot) => Container(
                width: 198,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8E4F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((snapshot.data ?? const <String>[]).isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          snapshot.data!.first,
                          height: 48,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => const Icon(
                            Icons.bedroom_parent_outlined,
                            color: Color(0xFF2A6EEB),
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.bedroom_parent_outlined,
                          color: Color(0xFF2A6EEB)),
                    const SizedBox(height: 5),
                    Text(
                      room.roomTypeName ?? 'Phòng ${room.roomNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Phòng ${room.roomNumber} · ${room.basePrice == null ? 'Liên hệ' : '${room.basePrice!.toStringAsFixed(0)}đ/đêm'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.onFindHotel});

  final VoidCallback onFindHotel;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late Future<List<Booking>> _bookings;
  bool _showAllBookings = false;

  @override
  void initState() {
    super.initState();
    _bookings = _loadBookings();
  }

  Future<List<Booking>> _loadBookings() async {
    final results = await Future.wait<dynamic>([
      apiRepository.bookings(),
      apiRepository.me(),
    ]);
    final bookings = results[0] as List<Booking>;
    final user = results[1] as ApiUser;
    final profileGuest = BookingGuest(
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
    );
    return Future.wait(bookings.map((booking) async {
      final detail = await apiRepository.booking(booking.id);
      final guests = await apiRepository.bookingGuests(booking.id);
      return booking.copyWith(
        rooms: detail.rooms,
        guest: guests.isEmpty ? profileGuest : guests.first,
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
                                fontSize: 13,
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
                        fontSize: 22,
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              FutureBuilder<List<Booking>>(
                future: _bookings,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BookingSectionHeading(
                          title: 'Lịch sử đặt phòng',
                        ),
                        SizedBox(height: 24),
                        Center(child: CircularProgressIndicator()),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BookingSectionHeading(
                          title: 'Lịch sử đặt phòng',
                        ),
                        const SizedBox(height: 10),
                        _BookingHistoryMessage(
                          message: 'Không thể tải lịch sử đơn hàng.',
                          actionLabel: 'Thử lại',
                          onPressed: () =>
                              setState(() => _bookings = _loadBookings()),
                        ),
                      ],
                    );
                  }
                  final bookings = snapshot.data ?? const <Booking>[];
                  if (bookings.isEmpty) {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BookingSectionHeading(
                          title: 'Lịch sử đặt phòng',
                        ),
                        SizedBox(height: 10),
                        _BookingEmptyState(),
                      ],
                    );
                  }
                  final visibleBookings = _showAllBookings
                      ? bookings
                      : bookings.take(1).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: _BookingSectionHeading(
                              title: 'Lịch sử đặt phòng',
                            ),
                          ),
                          if (bookings.length > 1)
                            TextButton.icon(
                              key: const ValueKey('toggle_booking_history'),
                              onPressed: () => setState(
                                () => _showAllBookings = !_showAllBookings,
                              ),
                              icon: Icon(
                                _showAllBookings
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                              ),
                              label: Text(
                                _showAllBookings
                                    ? 'Thu gọn'
                                    : 'Xem thêm ${bookings.length - 1} đơn',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: [
                            for (final booking in visibleBookings) ...[
                              _HistoryBookingCard(booking: booking),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onFindHotel,
                icon: const Icon(Icons.hotel_outlined),
                label: const Text('Tìm và đặt phòng khách sạn'),
              ),
              const SizedBox(height: 20),
              _BookingSectionTitle(
                title: 'Thư viện Coupon',
                subtitle: 'Ưu đãi dành cho đặt phòng khách sạn',
                icon: Icons.local_offer_outlined,
              ),
              const SizedBox(height: 10),
              const _SavedVoucherCarousel(),
              const SizedBox(height: 20),
              _BookingSectionTitle(
                title: 'Đề xuất tuyệt vời',
                subtitle: 'Khách sạn phù hợp cho chuyến đi của bạn',
                icon: Icons.local_fire_department_rounded,
              ),
              const SizedBox(height: 10),
              const _RecommendationHotelCarousel(),
              const SizedBox(height: 22),
              const _BookingSectionHeading(
                title: 'Tất cả giao dịch và hoạt động khác',
              ),
              const SizedBox(height: 14),
              const _BookingActivityShortcuts(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryBookingCard extends StatelessWidget {
  const _HistoryBookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final status = _historyStatus(booking.status);
    final guest = booking.guest;
    final room = booking.rooms.isEmpty ? null : booking.rooms.first;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => hotel_booking.BookingDetailPage(booking: booking),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0E1F38),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hotel_rounded, color: Color(0xFF1674C5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      booking.hotelName ?? 'Khách sạn',
                      style: const TextStyle(
                        color: Color(0xFF17202C),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _HistoryStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${room?.roomType ?? booking.roomTypeName ?? 'Phòng đã đặt'} · Phòng ${room?.roomNumber ?? '—'}',
                style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
              ),
              const SizedBox(height: 7),
              Text(
                '${booking.checkIn} - ${booking.checkOut}',
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Tổng thanh toán: ${_formatHistoryMoney(booking.totalAmount)}',
                style: const TextStyle(
                  color: Color(0xFF17202C),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (guest != null) ...[
                const SizedBox(height: 7),
                Text(
                  '${guest.fullName} · ${guest.phone ?? ''}',
                  style: const TextStyle(color: Color(0xFF4B5563)),
                ),
                Text(
                  guest.email ?? '',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingHistoryMessage extends StatelessWidget {
  const _BookingHistoryMessage({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      );
}

class _HistoryStatusBadge extends StatelessWidget {
  const _HistoryStatusBadge({required this.status});
  final _HistoryStatus status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${status.icon} ${status.label}',
          style: TextStyle(
            color: status.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _HistoryStatus {
  const _HistoryStatus(this.label, this.icon, this.color);
  final String label;
  final String icon;
  final Color color;
}

_HistoryStatus _historyStatus(String value) {
  switch (value.toLowerCase()) {
    case 'confirmed':
      return const _HistoryStatus('Đã xác nhận', '✓', Color(0xFF168A55));
    case 'cancelled':
      return const _HistoryStatus('Đã hủy', '×', Color(0xFFC0392B));
    default:
      return const _HistoryStatus('Chờ xác nhận', '⏳', Color(0xFFE08A00));
  }
}

String _formatHistoryMoney(double? value) {
  final digits = (value ?? 0).round().toString();
  final formatted = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      formatted.write('.');
    }
    formatted.write(digits[index]);
  }
  return '$formatted đ';
}

class _BookingEmptyState extends StatelessWidget {
  const _BookingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE6F5FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EDF6)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFD8F0FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.luggage_outlined,
              color: Color(0xFF1688D4),
              size: 38,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chưa có đặt chỗ, nhưng thế giới đang mời gọi bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF17202C),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sau khi đặt, vé điện tử hoặc voucher sẽ xuất hiện tại đây. Hãy bắt đầu chuyến đi mới của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF737E8A),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE0E8EF)),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'Không tìm thấy lượt đặt phòng?',
                style: TextStyle(color: Color(0xFF77818B), fontSize: 12),
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng tra cứu đặt phòng sẽ sớm có mặt.'),
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFDDF2FF),
                  foregroundColor: const Color(0xFF1768A8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Lấy lại thông tin đặt phòng',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingSectionTitle extends StatelessWidget {
  const _BookingSectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF2A6EEB), size: 19),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF202833),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF858E98), fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF1688E8),
          size: 28,
        ),
      ],
    );
  }
}

class _SavedVoucherCarousel extends StatefulWidget {
  const _SavedVoucherCarousel();

  @override
  State<_SavedVoucherCarousel> createState() => _SavedVoucherCarouselState();
}

class _SavedVoucherCarouselState extends State<_SavedVoucherCarousel> {
  late Future<List<Voucher>> _vouchers;

  @override
  void initState() {
    super.initState();
    _vouchers = _loadSavedVouchers();
  }

  Future<List<Voucher>> _loadSavedVouchers() async {
    final savedCodes = (await voucherStorageService.getSavedVoucherCodes())
        .map((code) => code.toUpperCase())
        .toSet();
    if (savedCodes.isEmpty) return const [];
    final vouchers = await apiRepository.vouchers();
    return vouchers
        .where((voucher) => savedCodes.contains(voucher.code.toUpperCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Voucher>>(
      future: _vouchers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return _SavedSectionMessage(
            message: 'Không thể tải mã đã lưu.',
            onRetry: () => setState(() => _vouchers = _loadSavedVouchers()),
          );
        }
        final vouchers = snapshot.data ?? const <Voucher>[];
        if (vouchers.isEmpty) {
          return const _SavedSectionMessage(
            message: 'Mã voucher bạn lưu sẽ xuất hiện tại đây.',
          );
        }
        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vouchers.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _SavedVoucherCard(voucher: vouchers[index]),
          ),
        );
      },
    );
  }
}

class _SavedVoucherCard extends StatelessWidget {
  const _SavedVoucherCard({required this.voucher});

  final Voucher voucher;

  @override
  Widget build(BuildContext context) {
    final isPercent = voucher.discountType == 'percent';
    return Container(
      width: 250,
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFDCE8F7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100875F5),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0875F5), Color(0xFF42B8F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isPercent
                            ? '${voucher.discountValue.round()}%'
                            : _formatMainVnd(voucher.discountValue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
                      : 'Giảm ${_formatMainVnd(voucher.discountValue)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF008ACB),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mã ${voucher.code}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17202C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Tối thiểu ${_formatMainVnd(voucher.minOrder)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D8995),
                    fontSize: 9,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'HSD ${_formatMainDate(voucher.endDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E9B63),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Đã lưu',
                      style: TextStyle(
                        color: Color(0xFF2E9B63),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationHotelCarousel extends StatefulWidget {
  const _RecommendationHotelCarousel();

  @override
  State<_RecommendationHotelCarousel> createState() =>
      _RecommendationHotelCarouselState();
}

class _RecommendationHotelCarouselState
    extends State<_RecommendationHotelCarousel> {
  late Future<List<Hotel>> _hotels;
  final Map<String, Future<List<String>>> _images = {};

  @override
  void initState() {
    super.initState();
    _hotels = apiRepository.hotels();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hotel>>(
      future: _hotels,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 274,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return _SavedSectionMessage(
            message: 'Không thể tải khách sạn đề xuất.',
            onRetry: () => setState(() => _hotels = apiRepository.hotels()),
          );
        }
        final hotels = snapshot.data ?? const <Hotel>[];
        if (hotels.isEmpty) {
          return const _SavedSectionMessage(
            message: 'Chưa có khách sạn đề xuất.',
          );
        }
        return SizedBox(
          height: 274,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hotels.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              final imageRequest = _images.putIfAbsent(
                hotel.id,
                () => apiRepository.hotelImages(hotel.id),
              );
              return _RecommendationHotelCard(
                hotel: hotel,
                imageRequest: imageRequest,
              );
            },
          ),
        );
      },
    );
  }
}

class _RecommendationHotelCard extends StatelessWidget {
  const _RecommendationHotelCard({
    required this.hotel,
    required this.imageRequest,
  });

  final Hotel hotel;
  final Future<List<String>> imageRequest;

  @override
  Widget build(BuildContext context) {
    void openHotel() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => hotel_booking.HotelDetailPage(
            hotelName: hotel.name,
            hotelId: hotel.id,
            selection: hotel_booking.HotelSearchSelection(),
          ),
        ),
      );
    }

    return Container(
      width: 218,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E5F2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openHotel,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 118,
                width: double.infinity,
                child: FutureBuilder<List<String>>(
                  future: imageRequest,
                  builder: (context, snapshot) {
                    final images = snapshot.data ?? const <String>[];
                    if (images.isNotEmpty) {
                      return Image.network(
                        images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _mainHotelFallback(),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ColoredBox(
                        color: Color(0xFFE7EEF5),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return _mainHotelFallback();
                  },
                ),
              ),
              Container(
                height: 34,
                width: double.infinity,
                color: const Color(0xFF2869AA),
                alignment: Alignment.center,
                child: const Text(
                  'Đề xuất',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17202C),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hotel.city.isEmpty ? hotel.address : hotel.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7D8995),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC928),
                          size: 17,
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
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF2A6EEB),
                          size: 18,
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
}

class _SavedSectionMessage extends StatelessWidget {
  const _SavedSectionMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Center(
        child: onRetry == null
            ? Text(message, style: const TextStyle(color: Color(0xFF7D8995)))
            : TextButton(onPressed: onRetry, child: Text(message)),
      ),
    );
  }
}

String _formatMainVnd(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '$bufferđ';
}

String _formatMainDate(DateTime? date) {
  if (date == null) return '--/--/----';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

Widget _mainHotelFallback() {
  return const ColoredBox(
    color: Color(0xFFE7EEF5),
    child: Center(
      child: Icon(Icons.hotel_rounded, color: Color(0xFF9AA9B8), size: 34),
    ),
  );
}

class _BookingActivityShortcuts extends StatelessWidget {
  const _BookingActivityShortcuts();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.receipt_long_outlined, 'Tất cả giao dịch'),
      (Icons.manage_search_rounded, 'Lấy lại thông tin'),
      (Icons.currency_exchange_rounded, 'Hoàn tiền'),
      (Icons.rate_review_outlined, 'Đánh giá & nhận xét'),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 112,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EDF3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0E1F38),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$1, color: const Color(0xFF1688D4), size: 25),
                const Spacer(),
                Text(
                  item.$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF27303B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class SavedPage extends StatelessWidget {
  const SavedPage({
    super.key,
    required this.selection,
    required this.savedArticles,
    required this.onRemoveArticle,
    required this.onOpenArticle,
  });

  final hotel_booking.HotelSearchSelection selection;
  final List<TravelArticle> savedArticles;
  final ValueChanged<TravelArticle> onRemoveArticle;
  final ValueChanged<TravelArticle> onOpenArticle;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
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
                              fontSize: 13,
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
          Material(
            color: const Color(0xFFF7F8FA),
            child: const TabBar(
              labelColor: Color(0xFF2A6EEB),
              unselectedLabelColor: Color(0xFF7D858D),
              indicatorColor: Color(0xFF2A6EEB),
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Thông tin đã lưu'),
                Tab(text: 'Khách sạn đã lưu'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF7F8FA),
              child: TabBarView(
                children: [
                  _SavedArticlesTab(
                    articles: savedArticles,
                    onRemoveArticle: onRemoveArticle,
                    onOpenArticle: onOpenArticle,
                  ),
                  _SavedHotelsTab(selection: selection),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedHotelsTab extends StatefulWidget {
  const _SavedHotelsTab({required this.selection});

  final hotel_booking.HotelSearchSelection selection;

  @override
  State<_SavedHotelsTab> createState() => _SavedHotelsTabState();
}

class _SavedHotelsTabState extends State<_SavedHotelsTab> {
  late Future<List<FavoriteHotel>> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = apiRepository.favorites();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FavoriteHotel>>(
        future: _favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
              children: const [
                _SavedProductsCard(),
                SizedBox(height: 18),
                _SavedCollectionsCard(),
              ],
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _favorites = apiRepository.favorites();
                }),
                child: Text('${snapshot.error}\nThử lại',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final favorites = snapshot.data ?? const <FavoriteHotel>[];
          if (favorites.isEmpty) {
            return const Center(child: Text('Chưa có khách sạn yêu thích.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
            itemCount: favorites.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final hotel = favorites[index];
              return _SavedHotelCard(
                hotel: hotel,
                imageRequest: apiRepository.hotelImages(hotel.id),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => hotel_booking.HotelDetailPage(
                        hotelName: hotel.name,
                        hotelId: hotel.id,
                        selection: widget.selection,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _favorites = apiRepository.favorites();
                    });
                  }
                },
                onRemove: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await apiRepository.removeFavorite(hotel.id);
                    if (mounted) {
                      setState(() {
                        _favorites = apiRepository.favorites();
                      });
                    }
                  } on ApiException catch (error) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  }
                },
              );
            },
          );
        },
      );
}

class _SavedHotelCard extends StatelessWidget {
  const _SavedHotelCard({
    required this.hotel,
    required this.imageRequest,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteHotel hotel;
  final Future<List<String>> imageRequest;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: FutureBuilder<List<String>>(
                  future: imageRequest,
                  builder: (context, snapshot) {
                    final images = snapshot.data;
                    final image = images != null && images.isNotEmpty
                        ? images.first
                        : null;
                    if (image == null || image.isEmpty) {
                      return const ColoredBox(
                        color: Color(0xFFE5F1FF),
                        child: Icon(Icons.hotel_rounded, color: Color(0xFF0875F5), size: 36),
                      );
                    }
                    return Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFE5F1FF),
                        child: Icon(Icons.hotel_rounded, color: Color(0xFF0875F5), size: 36),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hotel.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF172536))),
                      const SizedBox(height: 5),
                      Text([hotel.city, hotel.address].where((text) => text.trim().isNotEmpty).join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF778391))),
                      const SizedBox(height: 7),
                      Row(children: [
                        if (hotel.starRating != null) ...[
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 17),
                          const SizedBox(width: 3),
                          Text(hotel.starRating!.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF445266))),
                          const SizedBox(width: 8),
                        ],
                        const Text('Xem chi tiết', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0875F5))),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0875F5)),
                      ]),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Bỏ lưu khách sạn',
                onPressed: onRemove,
                icon: const Icon(Icons.bookmark_remove_outlined, color: Color(0xFF778391)),
              ),
            ],
          ),
        ),
      );
}

class _SavedArticlesTab extends StatelessWidget {
  const _SavedArticlesTab({
    required this.articles,
    required this.onRemoveArticle,
    required this.onOpenArticle,
  });

  final List<TravelArticle> articles;
  final ValueChanged<TravelArticle> onRemoveArticle;
  final ValueChanged<TravelArticle> onOpenArticle;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                color: Color(0xFF2A6EEB),
                size: 54,
              ),
              SizedBox(height: 12),
              Text(
                'Bài viết bạn lưu sẽ xuất hiện tại đây',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF58616D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        Text(
          '${articles.length} bài viết du lịch',
          style: const TextStyle(
            color: Color(0xFF17202C),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...articles.map(
          (article) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SavedArticleCard(
              article: article,
              onRemove: () => onRemoveArticle(article),
              onTap: () => onOpenArticle(article),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedArticleCard extends StatelessWidget {
  const _SavedArticleCard({
    required this.article,
    required this.onRemove,
    required this.onTap,
  });

  final TravelArticle article;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: double.infinity,
                child: DestinationImage(
                  location: article.location,
                  networkUrl: article.imageUrl,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF17202C),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF2A6EEB),
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              article.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF66707D),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Bỏ lưu bài viết',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: onRemove,
                            icon: const Icon(
                              Icons.bookmark_rounded,
                              color: Color(0xFF2A6EEB),
                              size: 19,
                            ),
                          ),
                        ],
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
              'Khách sạn đã lưu  →',
              style: TextStyle(
                color: Color(0xFF2A6EEB),
                fontSize: 15,
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
                      'Hãy sắp xếp khách sạn yêu thích!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF19232D),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tạo danh sách khách sạn yêu thích để lên kế hoạch cho chuyến đi tiếp theo.',
                      style: TextStyle(
                        fontSize: 12,
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
                fontSize: 15,
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
  const SearchPanel({
    super.key,
    required this.selection,
    required this.onSearch,
  });

  final hotel_booking.HotelSearchSelection selection;
  final ValueChanged<String> onSearch;

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

  @override
  void dispose() {
    widget.selection.removeListener(_handleSelectionChanged);
    super.dispose();
  }

  void _handleSelectionChanged() {
    if (mounted) setState(() {});
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
  Widget build(BuildContext context) {
    final dateRange = widget.selection.dateRange;
    final nights = dateRange.duration.inDays;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 37,
            child: DecoratedBox(
              key: const ValueKey('home_search_blue_background'),
              decoration: const BoxDecoration(
                color: Color(0xFF0E1F38),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 56,
              ),
              child: Transform.translate(
                offset: const Offset(0, 12),
                child: Column(
                  children: [
                    Container(
                      key: const ValueKey('home_search_form'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFE91E63), width: 2),
                          left: BorderSide(color: Color(0xFFE91E63), width: 2),
                          right: BorderSide(color: Color(0xFFE91E63), width: 2),
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _pickLocation,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.black,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 9),
                                      Text(
                                        _selectedLocation,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F1FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.gps_fixed,
                                      color: Color(0xFF2A6EEB),
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 7),
                            child: Divider(height: 1, color: Color(0xFFE3E5E8)),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDateRange,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                      horizontal: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          color: Colors.black87,
                                          size: 17,
                                        ),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}\n$nights đêm',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              height: 1.25,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 34,
                                width: 1,
                                color: const Color(0xFFE3E5E8),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickGuestOptions,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                      horizontal: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.people_alt_outlined,
                                          color: Colors.black87,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            '${widget.selection.roomCount} phòng · ${widget.selection.adultCount} người lớn · ${widget.selection.childCount} trẻ',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              height: 1.25,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDFEBFF),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Bản đồ',
                                      style: TextStyle(
                                        fontSize: 13,
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
                                  borderRadius: BorderRadius.circular(11),
                                  child: InkWell(
                                    onTap: _searchHotels,
                                    borderRadius: BorderRadius.circular(11),
                                    child: Container(
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Tìm kiếm',
                                        style: TextStyle(
                                          fontSize: 13,
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
                    const PromoStrip(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 14,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/fomogo_logo.png',
                  width: 112,
                  height: 50,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  semanticLabel: 'FomoGo',
                ),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DiscountIconButton(),
                    SizedBox(width: 12),
                    CustomerSupportIconButton(),
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDA3C74),
        border: Border.all(color: const Color(0xFFE91E63), width: 2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
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
                fontSize: 12,
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
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );
  }
}

class _HomeVoucherData {
  const _HomeVoucherData({required this.vouchers, required this.savedCodes});

  final List<Voucher> vouchers;
  final Set<String> savedCodes;
}

class _HomeVoucherSection extends StatefulWidget {
  const _HomeVoucherSection();

  @override
  State<_HomeVoucherSection> createState() => _HomeVoucherSectionState();
}

class _HomeVoucherSectionState extends State<_HomeVoucherSection> {
  late Future<_HomeVoucherData> _data;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _data = _loadVouchers();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isActiveToday(Voucher voucher, DateTime today) {
    if (voucher.status.toLowerCase() != 'active') return false;
    final start = voucher.startDate;
    final end = voucher.endDate;
    if (start != null && _dateOnly(today).isBefore(_dateOnly(start))) {
      return false;
    }
    if (end != null && _dateOnly(today).isAfter(_dateOnly(end))) return false;
    return true;
  }

  Future<_HomeVoucherData> _loadVouchers() async {
    final results = await Future.wait<dynamic>([
      apiRepository.vouchers(),
      voucherStorageService.getSavedVoucherCodes(),
    ]);
    final today = DateTime.now();
    final vouchers = (results[0] as List<Voucher>)
        .where((voucher) => _isActiveToday(voucher, today))
        .toList();
    final savedCodes = (results[1] as List<String>)
        .map((code) => code.toUpperCase())
        .toSet();
    return _HomeVoucherData(vouchers: vouchers, savedCodes: savedCodes);
  }

  bool _isPercent(Voucher voucher) =>
      voucher.discountType.toLowerCase() == 'percent';

  Future<void> _saveVoucher(
    Voucher voucher,
    Set<String> savedCodes,
  ) async {
    await voucherStorageService.saveVoucher(voucher.code);
    if (!mounted) return;
    setState(() => savedCodes.add(voucher.code.toUpperCase()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu mã ${voucher.code}')),
    );
  }

  Widget _buildFilter(String type, String label) {
    final selected = type == _selectedType;
    return Material(
      color: selected ? const Color(0xFF0875F5) : const Color(0xFFF1F5FA),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _selectedType = type),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF0875F5),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher, Set<String> savedCodes) {
    final isPercent = _isPercent(voucher);
    final isSaved = savedCodes.contains(voucher.code.toUpperCase());
    final discountLabel = isPercent
        ? '${voucher.discountValue.round()}%'
        : _formatMainVnd(voucher.discountValue);

    return Container(
      width: 300,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100E1F38),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFE5F1FF),
                child: Icon(
                  isPercent
                      ? Icons.percent_rounded
                      : Icons.local_offer_rounded,
                  color: const Color(0xFF176FC1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPercent ? 'Voucher giảm theo %' : 'Voucher giảm số tiền',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF8A95A3), size: 19),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Giảm $discountLabel',
            style: const TextStyle(
              color: Color(0xFF17202C),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã ${voucher.code} · Đơn tối thiểu ${_formatMainVnd(voucher.minOrder)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF727D89), fontSize: 11),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  'HSD ${_formatMainDate(voucher.endDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 11,
                  ),
                ),
              ),
              FilledButton(
                onPressed: isSaved
                    ? null
                    : () => _saveVoucher(voucher, savedCodes),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(88, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: const Color(0xFFDFF3FF),
                  foregroundColor: const Color(0xFF075F9D),
                  disabledBackgroundColor: const Color(0xFFE4F4EC),
                  disabledForegroundColor: const Color(0xFF258353),
                ),
                child: Text(isSaved ? 'Đã lưu' : 'Lưu mã'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeVoucherData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return Row(
            children: [
              const Expanded(child: Text('Không thể tải voucher lúc này.')),
              TextButton(
                onPressed: () => setState(() => _data = _loadVouchers()),
                child: const Text('Thử lại'),
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final vouchers = data.vouchers;
        if (vouchers.isEmpty) {
          return const Text(
            'Hiện chưa có voucher đang áp dụng.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 13),
          );
        }

        final hasPercent = vouchers.any(_isPercent);
        final hasFixed = vouchers.any((voucher) => !_isPercent(voucher));
        final visibleVouchers = vouchers.where((voucher) {
          if (_selectedType == 'percent') return _isPercent(voucher);
          if (_selectedType == 'fixed') return !_isPercent(voucher);
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilter('all', 'Tất cả'),
                  if (hasPercent) ...[
                    const SizedBox(width: 8),
                    _buildFilter('percent', 'Giảm theo %'),
                  ],
                  if (hasFixed) ...[
                    const SizedBox(width: 8),
                    _buildFilter('fixed', 'Giảm số tiền'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleVouchers.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _buildVoucherCard(
                  visibleVouchers[index],
                  data.savedCodes,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class HotelRowSection extends StatefulWidget {
  const HotelRowSection({super.key, required this.selection});

  final hotel_booking.HotelSearchSelection selection;

  @override
  State<HotelRowSection> createState() => _HotelRowSectionState();
}

class _HotelRowSectionState extends State<HotelRowSection> {
  late Future<List<Hotel>> _hotels;
  final Map<String, Future<List<String>>> _hotelImageRequests = {};

  @override
  void initState() {
    super.initState();
    _hotels = apiRepository.hotels();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khách sạn',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Hotel>>(
          future: _hotels,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 112);
            }
            if (snapshot.hasError) {
              return Row(
                children: [
                  Expanded(child: Text('${snapshot.error}')),
                  TextButton(
                    onPressed: () =>
                        setState(() => _hotels = apiRepository.hotels()),
                    child: const Text('Thử lại'),
                  ),
                ],
              );
            }
            final hotels = snapshot.data ?? const <Hotel>[];
            if (hotels.isEmpty) return const Text('Chưa có khách sạn.');
            return SizedBox(
              height: 246,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hotels.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final hotel = hotels[index];
                  final imageRequest = _hotelImageRequests.putIfAbsent(
                    hotel.id,
                    () => apiRepository.hotelImages(hotel.id),
                  );
                  return SizedBox(
                    width: 222,
                    child: _HomeHotelCard(
                      hotel: hotel,
                      imageRequest: imageRequest,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => hotel_booking.HotelDetailPage(
                            hotelName: hotel.name,
                            hotelId: hotel.id,
                            selection: widget.selection,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HomeHotelCard extends StatelessWidget {
  const _HomeHotelCard({
    required this.hotel,
    required this.imageRequest,
    required this.onTap,
  });

  final Hotel hotel;
  final Future<List<String>> imageRequest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = hotel.starRating ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E5F2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 126,
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
                                DestinationImage(
                              location: hotel.city,
                              networkUrl:
                                  'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=85',
                            ),
                          );
                        }
                        return DestinationImage(
                          location: hotel.city,
                          networkUrl:
                              'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=85',
                        );
                      },
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x99000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          child: Text(
                            'Đề xuất',
                            style: TextStyle(
                              color: Color(0xFF1674C5),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 9,
                      child: Text(
                        hotel.city.isEmpty ? 'Việt Nam' : hotel.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF17202C),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hotel.address.isEmpty
                            ? 'Địa chỉ đang cập nhật'
                            : hotel.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF707984),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC928),
                            size: 17,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : 'Mới',
                            style: const TextStyle(
                              color: Color(0xFF1688C7),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Xem phòng',
                            style: TextStyle(
                              color: Color(0xFF1674C5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF1674C5),
                            size: 18,
                          ),
                        ],
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

class BrandOfferSection extends StatefulWidget {
  const BrandOfferSection({super.key, required this.selection});

  final hotel_booking.HotelSearchSelection selection;

  @override
  State<BrandOfferSection> createState() => _BrandOfferSectionState();
}

class _BrandHotelOffer {
  const _BrandHotelOffer({
    required this.hotel,
    required this.imageUrl,
    required this.voucher,
    required this.discountAmount,
  });

  final Hotel hotel;
  final String imageUrl;
  final Voucher voucher;
  final double discountAmount;
}

class _BrandOfferSectionState extends State<BrandOfferSection> {
  late Future<List<_BrandHotelOffer>> _offers;

  @override
  void initState() {
    super.initState();
    _offers = _loadOffers();
  }

  bool _isVoucherActive(Voucher voucher, DateTime today) {
    if (voucher.status.toLowerCase() != 'active') return false;
    final start = voucher.startDate;
    final end = voucher.endDate;
    if (start != null && _dateOnly(today).isBefore(_dateOnly(start))) {
      return false;
    }
    if (end != null && _dateOnly(today).isAfter(_dateOnly(end))) return false;
    return true;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<List<_BrandHotelOffer>> _loadOffers() async {
    final data = await Future.wait<dynamic>([
      apiRepository.hotels(),
      apiRepository.vouchers(),
    ]);
    final hotels = data[0] as List<Hotel>;
    final today = DateTime.now();
    final vouchers = (data[1] as List<Voucher>)
        .where((voucher) => _isVoucherActive(voucher, today))
        .toList();
    final nights = widget.selection.dateRange.duration.inDays.clamp(1, 365);
    final rooms = widget.selection.roomCount;

    final results = await Future.wait(hotels.map((hotel) async {
      try {
        final details = await Future.wait<dynamic>([
          apiRepository.roomTypes(hotel.id),
          apiRepository.hotelImages(hotel.id),
        ]);
        final roomTypes = details[0] as List<RoomType>;
        final images = details[1] as List<String>;
        final prices = roomTypes
            .map((roomType) => roomType.basePrice)
            .where((price) => price > 0)
            .toList();
        if (prices.isEmpty || images.isEmpty || images.first.isEmpty) {
          return null;
        }
        prices.sort();
        final subtotal = prices.first * nights * rooms;
        final applicable =
            vouchers.where((voucher) => voucher.minOrder <= subtotal).toList();
        if (applicable.isEmpty) return null;

        double estimatedDiscount(Voucher voucher) {
          final amount = voucher.discountType.toLowerCase() == 'percent'
              ? subtotal * voucher.discountValue / 100
              : voucher.discountValue;
          return amount.clamp(0, subtotal).toDouble();
        }

        applicable.sort(
            (a, b) => estimatedDiscount(b).compareTo(estimatedDiscount(a)));
        final bestVoucher = applicable.first;
        return _BrandHotelOffer(
          hotel: hotel,
          imageUrl: images.first,
          voucher: bestVoucher,
          discountAmount: estimatedDiscount(bestVoucher),
        );
      } catch (_) {
        return null;
      }
    }));

    final offers = results.whereType<_BrandHotelOffer>().toList()
      ..sort((a, b) => b.discountAmount.compareTo(a.discountAmount));
    return offers;
  }

  String _formatVnd(num value) {
    final digits = value.round().toString();
    final formatted = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write('.');
      }
      formatted.write(digits[index]);
    }
    return '${formatted.toString()}đ';
  }

  void _openHotel(_BrandHotelOffer offer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => hotel_booking.HotelDetailPage(
          hotelName: offer.hotel.name,
          hotelId: offer.hotel.id,
          selection: widget.selection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ưu đãi thương hiệu 10.10',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 198,
          child: FutureBuilder<List<_BrandHotelOffer>>(
            future: _offers,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Không thể tải ưu đãi khách sạn.'),
                );
              }
              final offers = snapshot.data ?? const <_BrandHotelOffer>[];
              if (offers.isEmpty) {
                return const Center(
                  child: Text('Hiện chưa có voucher phù hợp với khách sạn.'),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: offers.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _BrandHotelOfferCard(
                  offer: offers[index],
                  discountText:
                      offers[index].voucher.discountType.toLowerCase() ==
                              'percent'
                          ? '${offers[index].voucher.discountValue.round()}%'
                          : _formatVnd(offers[index].voucher.discountValue),
                  minOrderText: _formatVnd(offers[index].voucher.minOrder),
                  onTap: () => _openHotel(offers[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BrandHotelOfferCard extends StatelessWidget {
  const _BrandHotelOfferCard({
    required this.offer,
    required this.discountText,
    required this.minOrderText,
    required this.onTap,
  });

  final _BrandHotelOffer offer;
  final String discountText;
  final String minOrderText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Material(
        color: const Color(0xFF0E1F38),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                offer.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFFB8D7E8),
                  child:
                      Icon(Icons.hotel_rounded, color: Colors.white, size: 42),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22000000),
                      Color(0x33000000),
                      Color(0xE60E1F38),
                    ],
                    stops: [0, 0.35, 1],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    offer.voucher.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1269D3),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.hotel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Giảm đến $discountText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8ED2FF),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đơn từ $minOrderText · Xem khách sạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
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
    );
  }
}

class DiscoverBanner extends StatefulWidget {
  const DiscoverBanner({super.key});

  @override
  State<DiscoverBanner> createState() => _DiscoverBannerState();
}

class _DiscoverBannerState extends State<DiscoverBanner> {
  static const _voucherImages = [
    'assets/images/voucher_1.jpg',
    'assets/images/voucher_2.jpg',
    'assets/images/voucher_3.jpg',
    'assets/images/voucher_4.jpg',
  ];

  late Future<List<Voucher>> _vouchers;

  @override
  void initState() {
    super.initState();
    _vouchers = _loadActiveVouchers();
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  Future<List<Voucher>> _loadActiveVouchers() async {
    final today = DateTime.now();
    final vouchers = await apiRepository.vouchers();
    return vouchers.where((voucher) {
      if (voucher.status.toLowerCase() != 'active') return false;
      final start = voucher.startDate;
      final end = voucher.endDate;
      if (start != null && _dateOnly(today).isBefore(_dateOnly(start))) return false;
      if (end != null && _dateOnly(today).isAfter(_dateOnly(end))) return false;
      return voucher.code.trim().isNotEmpty;
    }).toList();
  }

  void _openDetails(Voucher voucher, int index) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _VoucherPromotionDetailPage(
        voucher: voucher,
        imageAsset: _voucherImages[index % _voucherImages.length],
      ),
    ));
  }

  Widget _offerCard(Voucher voucher, int index) {
    final isPercent = voucher.discountType.toLowerCase() == 'percent';
    final discount = isPercent
        ? '${voucher.discountValue.round()}%'
        : _formatMainVnd(voucher.discountValue);
    return SizedBox(
      width: 292,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetails(voucher, index),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 146,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(_voucherImages[index % _voucherImages.length], fit: BoxFit.cover),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC071D33)],
                  ))),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text(voucher.code, style: const TextStyle(color: Color(0xFF0875F5), fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                  Positioned(
                    left: 14, right: 14, bottom: 12,
                    child: Text('Giảm $discount', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isPercent ? 'Ưu đãi giảm theo phần trăm' : 'Ưu đãi giảm số tiền', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF172536))),
                    const SizedBox(height: 4),
                    Text('Đơn tối thiểu ${_formatMainVnd(voucher.minOrder)}', style: const TextStyle(fontSize: 12, color: Color(0xFF778391))),
                  ])),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF0875F5)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vô vàn ưu đãi khác',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Voucher>>(
          future: _vouchers,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Chưa tải được ưu đãi. Vui lòng thử lại sau.', style: TextStyle(color: Color(0xFF778391), fontSize: 13));
            }
            if (!snapshot.hasData) {
              return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
            }
            final vouchers = snapshot.data!;
            if (vouchers.isEmpty) {
              return const Text('Hiện chưa có voucher khả dụng.', style: TextStyle(color: Color(0xFF778391), fontSize: 13));
            }
            return SizedBox(
              height: 235,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: vouchers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) => _offerCard(vouchers[index], index),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VoucherPromotionDetailPage extends StatelessWidget {
  const _VoucherPromotionDetailPage({
    required this.voucher,
    required this.imageAsset,
  });

  final Voucher voucher;
  final String imageAsset;

  String get _discount => voucher.discountType.toLowerCase() == 'percent'
      ? '${voucher.discountValue.round()}%'
      : _formatMainVnd(voucher.discountValue);

  @override
  Widget build(BuildContext context) {
    final isPercent = voucher.discountType.toLowerCase() == 'percent';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Chi tiết ưu đãi'), backgroundColor: const Color(0xFF0E1F38), foregroundColor: Colors.white),
      body: ListView(padding: EdgeInsets.zero, children: [
        Image.asset(imageAsset, height: 230, fit: BoxFit.cover),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ưu đãi giảm $_discount', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF172536))),
            const SizedBox(height: 10),
            Text(isPercent ? 'Giảm ${voucher.discountValue.round()}% trên đơn hàng đủ điều kiện.' : 'Giảm ${_formatMainVnd(voucher.discountValue)} trên đơn hàng đủ điều kiện.', style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF4F5D6D))),
            const SizedBox(height: 8),
            Text('Giá trị đơn tối thiểu: ${_formatMainVnd(voucher.minOrder)}', style: const TextStyle(fontSize: 15, color: Color(0xFF4F5D6D))),
            if (voucher.startDate != null || voucher.endDate != null) ...[
              const SizedBox(height: 8),
              Text('Thời hạn: ${voucher.startDate == null ? 'đang áp dụng' : _formatMainDate(voucher.startDate)} – ${_formatMainDate(voucher.endDate)}', style: const TextStyle(fontSize: 15, color: Color(0xFF4F5D6D))),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF2F7FC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDDE8F3))),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MÃ ƯU ĐÃI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF778391))),
                  const SizedBox(height: 6),
                  SelectableText(voucher.code, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0875F5))),
                ])),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: voucher.code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép mã ưu đãi')));
                  },
                  icon: const Icon(Icons.copy_rounded), label: const Text('Sao chép'),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            const Text('Nhập mã này trong ô voucher ở bước đặt phòng. Điều kiện áp dụng được hệ thống kiểm tra theo đơn hàng.', style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF778391))),
            const SizedBox(height: 26),
            const Divider(height: 1, color: Color(0xFFE8EDF3)),
            const SizedBox(height: 24),
            const Text('Lên kế hoạch chuyến đi thuận tiện hơn', style: TextStyle(fontSize: 20, height: 1.25, fontWeight: FontWeight.w900, color: Color(0xFF172536))),
            const SizedBox(height: 8),
            const Text('Một vài gợi ý hữu ích khi tìm và đặt phòng trực tuyến. Các nội dung dưới đây chỉ mang tính tham khảo, không phải điều kiện của mã ưu đãi.', style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF778391))),
            const SizedBox(height: 16),
            const _TravelBookingTip(
              icon: Icons.event_available_rounded,
              title: 'Chọn ngày phù hợp',
              description: 'Xác định ngày nhận và trả phòng trước khi tìm kiếm để dễ so sánh tổng chi phí cho toàn bộ kỳ nghỉ.',
            ),
            const SizedBox(height: 10),
            const _TravelBookingTip(
              icon: Icons.location_on_outlined,
              title: 'Ưu tiên vị trí thuận tiện',
              description: 'Kiểm tra khu vực lưu trú so với điểm tham quan, phương tiện di chuyển và những nơi bạn dự định ghé thăm.',
            ),
            const SizedBox(height: 10),
            const _TravelBookingTip(
              icon: Icons.fact_check_outlined,
              title: 'Đọc kỹ thông tin phòng',
              description: 'Xem loại phòng, số khách, tiện nghi và chính sách nhận phòng trước khi xác nhận đặt chỗ.',
            ),
            const SizedBox(height: 10),
            const _TravelBookingTip(
              icon: Icons.payments_outlined,
              title: 'So sánh tổng giá',
              description: 'Đối chiếu giá cho toàn bộ thời gian lưu trú và kiểm tra lại thông tin khách trước khi thanh toán.',
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE59A00)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mẹo nhỏ: sau khi sao chép mã, hãy nhập mã ở bước đặt phòng và kiểm tra phần giảm giá được áp dụng trước khi thanh toán.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF66542E)),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TravelBookingTip extends StatelessWidget {
  const _TravelBookingTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0875F5), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF172536))),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF667384))),
              ],
            ),
          ),
        ],
      ),
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
