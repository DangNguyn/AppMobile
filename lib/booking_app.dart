import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/api_repository.dart';
import 'api/models.dart';
import 'destination_images.dart';
import 'advanced_hotel_filter.dart';
import 'voucher_storage_service.dart';
import 'ui_motion.dart';
import 'account_page.dart';

part 'support.dart';
part 'booking.dart';
part 'hotel_search.dart';
part 'hotel.dart';
part 'hotel_detail.dart';
part 'room_detail.dart';
part 'room_booking.dart';
part 'home_widgets.dart';

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
        textTheme: AppTypography.textTheme,
        pageTransitionsTheme: appPageTransitionsTheme,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF1674C5),
          circularTrackColor: Color(0xFFDCE7F1),
          linearTrackColor: Color(0xFFDCE7F1),
        ),
      ),
      home: const TravelHomePage(),
    );
  }
}

class _MockVietQrSheet extends StatefulWidget {
  const _MockVietQrSheet();

  @override
  State<_MockVietQrSheet> createState() => _MockVietQrSheetState();
}

class _MockVietQrSheetState extends State<_MockVietQrSheet> {
  Timer? _timer;
  int _seconds = 7;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds <= 1) {
        _timer?.cancel();
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Thanh toán bằng VietQR',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Container(
                width: 190,
                height: 190,
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: CustomPaint(painter: _MockQrPainter()),
              ),
              const SizedBox(height: 14),
              const Text('Ngân hàng MB · TRAVEL CÙNG CƯ',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('STK 0123456789 · Nội dung: BOOKING DEMO',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Tự động ghi nhận sau $_seconds giây',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Tôi đã hoàn tất chuyển khoản'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0E1F38);
    const cell = 9.0;
    for (var row = 0; row < 18; row++) {
      for (var column = 0; column < 18; column++) {
        final finder = (row < 5 && column < 5) ||
            (row < 5 && column > 12) ||
            (row > 12 && column < 5);
        if (finder || (row * 7 + column * 11) % 5 < 2) {
          canvas.drawRect(
            Rect.fromLTWH(column * cell, row * cell, cell - 1, cell - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaymentQrSheet extends StatelessWidget {
  const _PaymentQrSheet({required this.qrContent});

  final String qrContent;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Thanh toán bằng VietQR',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (qrContent.isEmpty)
                const Text('Không nhận được nội dung mã QR.')
              else
                QrImageView(
                  data: qrContent,
                  size: 220,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              const SizedBox(height: 14),
              const Text(
                'Đây là mã QR thanh toán mô phỏng cho Demo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Tôi đã hoàn tất chuyển khoản'),
                ),
              ),
            ],
          ),
        ),
      );
}
class _PaymentLoadingDialog extends StatelessWidget {
  const _PaymentLoadingDialog();

  @override
  Widget build(BuildContext context) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            SizedBox(width: 16),
            Expanded(child: Text('Đang kết nối cổng thanh toán...')),
          ],
        ),
      );
}

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E9B63), size: 84),
                const SizedBox(height: 18),
                const Text('Thanh toán thành công!',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Đơn đặt phòng đã được xác nhận',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ),
                    child: const Text('Tiếp tục khám phá'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
      duration: AppMotion.pageDuration,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                  child:
                                      ScrollTopButton(onPressed: _scrollToTop),
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
                                    : FontWeight.w300,
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
