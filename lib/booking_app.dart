import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'api/api_client.dart';
import 'api/api_repository.dart';
import 'api/models.dart';

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
