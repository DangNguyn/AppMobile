import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/api_repository.dart';
import 'api/models.dart';
import 'destination_images.dart';
import 'ui_motion.dart';

class AdvancedHotelFilterPage extends StatefulWidget {
  const AdvancedHotelFilterPage({
    super.key,
    required this.location,
    required this.initialHotels,
    required this.onHotelLiked,
  });

  final String location;
  final List<Hotel> initialHotels;
  final ValueChanged<Hotel> onHotelLiked;

  @override
  State<AdvancedHotelFilterPage> createState() => _AdvancedHotelFilterPageState();
}

class _AdvancedHotelFilterPageState extends State<AdvancedHotelFilterPage>
    with SingleTickerProviderStateMixin {
  late List<Hotel> _hotels;
  late List<Hotel> _allHotels;
  final Map<String, Future<List<String>>> _imageRequests = {};
  double _dragX = 0;
  bool _loading = false;
  bool _isFilterEmpty = false;
  int _seenCount = 0;
  int _totalCount = 0;
  double _minimumPrice = 0;
  double _maximumPrice = 35000000;
  double? _minimumRating;
  final Set<String> _selectedAmenities = {};
  final Set<String> _selectedVibes = {};
  Map<String, List<String>> _hotelAmenities = {};
  Map<String, List<String>> _hotelVibes = {};
  Map<String, double> _hotelPrices = {};
  late final AnimationController _exitController;
  Animation<double>? _exitAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _hotels = List.of(widget.initialHotels);
    _allHotels = List.of(widget.initialHotels);
    _totalCount = _hotels.length;
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addListener(() {
        final animation = _exitAnimation;
        if (animation != null && mounted) setState(() => _dragX = animation.value);
      });
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  Future<List<String>> _imagesFor(Hotel hotel) =>
      _imageRequests.putIfAbsent(hotel.id, () => apiRepository.hotelImages(hotel.id));

  Future<void> _openFilters() async {
    final facets = await Future.wait(_allHotels.map((hotel) async {
      try {
        final results = await Future.wait([
          apiRepository.hotelAmenities(hotel.id),
          apiRepository.hotelVibes(hotel.id),
          apiRepository.roomTypes(hotel.id),
        ]);
        final amenities = (results[0] as List<HotelAmenity>)
            .map((item) => item.name.trim()).where((name) => name.isNotEmpty).toList();
        final vibes = (results[1] as List<HotelAmenity>)
            .map((item) => item.name.trim()).where((name) => name.isNotEmpty).toList();
        final prices = (results[2] as List<RoomType>).map((room) => room.basePrice).where((price) => price > 0).toList();
        return (hotel.id, amenities, vibes, prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b));
      } catch (_) {
        return (hotel.id, <String>[], <String>[], null);
      }
    }));
    if (!mounted) return;
    _hotelAmenities = {for (final item in facets) item.$1: item.$2};
    _hotelVibes = {for (final item in facets) item.$1: item.$3};
    _hotelPrices = {for (final item in facets) if (item.$4 != null) item.$1: item.$4!};
    const amenities = [
      'Hồ bơi', 'Wifi miễn phí', 'Sân Golf', 'Spa & Massage',
      'Phòng Gym & Fitness', 'Bãi biển riêng', 'Nhà hàng ẩm thực',
      'Quầy Bar / Sky Lounge', 'Dịch vụ đưa đón sân bay',
      'Khu vui chơi trẻ em (Kids Club)',
    ];
    const vibes = [
      'Romantic', 'Luxury & Elegant', 'Vintage & Heritage',
      'Nature & Wellness', 'Family Friendly', 'Beachfront Vibes',
      'Modern & Dynamic',
    ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF8F2),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(builder: (context, update) {
        Widget chips(List<String> options, Set<String> selected) => Wrap(spacing: 8, runSpacing: 4, children: options.map((value) => FilterChip(
          label: Text(value), selected: selected.contains(value),
          selectedColor: const Color(0xFFDCE7F1), checkmarkColor: const Color(0xFF173B68),
          onSelected: (enabled) => update(() { enabled ? selected.add(value) : selected.remove(value); }),
        )).toList());
        Widget section(String title, IconData icon, Widget child) => Container(
          width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE0E6EA))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: const Color(0xFFB48A3C)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF173B68)))]), const SizedBox(height: 10), child]),
        );
        return SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * .88, child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(children: [
            Row(children: [const Expanded(child: Text('Bộ lọc nâng cao', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF173B68))),), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
            Expanded(child: ListView(children: [
              section('Giá tiền / đêm', Icons.payments_rounded, Column(children: [
                RangeSlider(values: RangeValues(_minimumPrice, _maximumPrice), min: 0, max: 35000000, divisions: 70, activeColor: const Color(0xFF173B68), labels: RangeLabels(_formatVnd(_minimumPrice), _formatVnd(_maximumPrice)), onChanged: (range) => update(() { _minimumPrice = range.start; _maximumPrice = range.end; })),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formatVnd(_minimumPrice)), Text(_formatVnd(_maximumPrice))]),
                const Text('Giá thấp nhất theo loại phòng từ API.', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ])),
              section('Tiện ích', Icons.spa_rounded, chips(amenities, _selectedAmenities)),
              section('Đánh giá theo sao', Icons.star_rounded, Wrap(spacing: 7, children: [for (final rating in <double?>[null, 5, 4, 3, 2, 1]) ChoiceChip(label: Text(rating == null ? 'Tất cả' : '${rating.toInt()} ★'), selected: _minimumRating == rating, onSelected: (_) => update(() => _minimumRating = rating))])),
              section('Phong cách khách sạn', Icons.apartment_rounded, chips(vibes, _selectedVibes)),
            ])),
            Row(children: [TextButton(onPressed: () => update(() { _minimumPrice = 0; _maximumPrice = 35000000; _minimumRating = null; _selectedAmenities.clear(); _selectedVibes.clear(); }), child: const Text('Đặt lại')), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () { _applyFilters(); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB99A5B), foregroundColor: Colors.white), child: const Text('Xem khách sạn')))]),
          ]),
        )));
      }),
    );
  }

  String _formatVnd(double value) => '${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ';

  List<Hotel> _filteredHotels() => _allHotels.where((hotel) {
    final price = _hotelPrices[hotel.id];
    if ((_minimumPrice > 0 || _maximumPrice < 35000000) && (price == null || price < _minimumPrice || price > _maximumPrice)) return false;
    if (_minimumRating != null && (hotel.starRating ?? 0) < _minimumRating!) return false;
    final hotelAmenities = _hotelAmenities[hotel.id] ?? const <String>[];
    if (_selectedAmenities.any((selection) => !_matchesAmenity(hotelAmenities, selection))) return false;
    final hotelVibes = _hotelVibes[hotel.id] ?? const <String>[];
    if (_selectedVibes.any((selection) => !_matchesText(hotelVibes, selection))) return false;
    return true;
  }).toList();

  void _applyFilters() {
    final filtered = _filteredHotels();
    setState(() { _hotels = filtered; _seenCount = 0; _totalCount = filtered.length; _dragX = 0; _isFilterEmpty = filtered.isEmpty; });
  }

  String _key(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u00c0-\u024f]'), '');

  bool _matchesText(List<String> values, String selected) {
    final needle = _key(selected);
    return values.any((value) => _key(value).contains(needle) || needle.contains(_key(value)));
  }

  bool _matchesAmenity(List<String> values, String selected) {
    final aliases = switch (selected) {
      'Hồ bơi' => ['pool', 'swimming', 'hồ bơi', 'be boi'],
      'Wifi miễn phí' => ['wifi', 'wi fi', 'internet', 'wireless'],
      'Sân Golf' => ['golf'],
      'Spa & Massage' => ['spa', 'massage'],
      'Phòng Gym & Fitness' => ['gym', 'fitness', 'thể hình'],
      'Bãi biển riêng' => ['beach', 'bãi biển'],
      'Nhà hàng ẩm thực' => ['restaurant', 'nhà hàng', 'ẩm thực'],
      'Quầy Bar / Sky Lounge' => ['bar', 'lounge'],
      'Dịch vụ đưa đón sân bay' => ['airport', 'shuttle', 'đưa đón', 'sân bay'],
      'Khu vui chơi trẻ em (Kids Club)' => ['kids club', 'child', 'trẻ em'],
      _ => [selected],
    };
    return values.any((value) {
      final key = _key(value);
      return aliases.any((alias) => key.contains(_key(alias)));
    });
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final all = await apiRepository.hotels();
      final needle = _normalize(widget.location);
      final refreshed = all.where((hotel) {
        final city = _normalize(hotel.city);
        return city.isNotEmpty
            ? city == needle
            : _normalize(hotel.address).contains(needle);
      }).toList();
      if (mounted) {
        setState(() {
          _hotels = refreshed;
          _allHotels = List.of(refreshed);
          _seenCount = 0;
          _totalCount = refreshed.length;
        });
      }
    } catch (_) {
      if (mounted) {
        final fallback = List<Hotel>.of(widget.initialHotels);
        setState(() {
          _hotels = fallback;
          _allHotels = List.of(fallback);
          _seenCount = 0;
          _totalCount = fallback.length;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _finishSwipe(Hotel hotel, double velocity) {
    if (_isAnimating) return;
    if (_dragX.abs() < 75 && velocity.abs() < 350) {
      setState(() => _dragX = 0);
      return;
    }
    final liked = _dragX.abs() >= 75 ? _dragX > 0 : velocity > 0;
    _dismiss(hotel, liked, velocity);
  }

  Future<void> _dismiss(Hotel hotel, bool liked, [double velocity = 0]) async {
    if (_isAnimating || _hotels.isEmpty || _hotels.first.id != hotel.id) return;
    final width = MediaQuery.sizeOf(context).width;
    final targetX = liked ? width * 1.25 : -width * 1.25;
    final startX = _dragX;
    final distance = (targetX - startX).abs();
    final velocityDuration = velocity.abs() > 350
        ? (distance / velocity.abs() * 1000).round().clamp(180, 380).toInt()
        : 380;
    setState(() => _isAnimating = true);
    _exitController
      ..duration = Duration(milliseconds: velocityDuration)
      ..reset();
    _exitAnimation = Tween<double>(begin: startX, end: targetX).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOutCubic),
    );
    await _exitController.forward();
    if (!mounted) return;
    setState(() {
      _hotels.removeAt(0);
      _seenCount++;
      _dragX = 0;
      _isAnimating = false;
    });
    if (liked) widget.onHotelLiked(hotel);
  }

  @override
  Widget build(BuildContext context) {
    final hotel = _hotels.isEmpty ? null : _hotels.first;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F38),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
        ),
        clipBehavior: Clip.antiAlias,
        flexibleSpace: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 22, bottom: 24),
            child: IgnorePointer(
              child: Opacity(
                opacity: .58,
                child: SizedBox(
                  width: 92,
                  height: 34,
                  child: Image.asset(
                    'assets/images/fomogo_logo.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    semanticLabel: 'FomoGO',
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text('Khám phá khách sạn'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(widget.location, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _loading
              ? const Center(child: AppLoadingIndicator(color: Color(0xFF173B68)))
              : hotel == null && _isFilterEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Không có tìm kiếm nào',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF52647A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _openFilters,
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('Bộ lọc nâng cao'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF173B68),
                              side: const BorderSide(color: Color(0xFFD5DFE8)),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ],
                      ),
                    )
                  : hotel == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hotel_rounded, color: Color(0xFF173B68), size: 58),
                          const SizedBox(height: 16),
                          const Text('HẾT KHÁCH SẠN MẤT RỒI',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF102A50), fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Xem lại'),
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF173B68), foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openFilters,
                                icon: const Icon(Icons.tune_rounded, size: 18),
                                label: const Text('Bộ lọc nâng cao'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF173B68),
                                  side: const BorderSide(color: Color(0xFFD5DFE8)),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 42),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFD5DFE8)),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        size: 18, color: Color(0xFF173B68)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        hotel.address.isNotEmpty
                                            ? hotel.address
                                            : hotel.city.isNotEmpty
                                                ? hotel.city
                                                : widget.location,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF173B68),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 10, 16, 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x120E1F38),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    color: Color(0xFFB48A3C), size: 24),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'G\u1ee3i \u00fd\ncho b\u1ea1n',
                                      style: TextStyle(
                                        color: Color(0xFF26364A),
                                        fontSize: 16,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Container(
                                      width: 58,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE4C68F),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final cardHeight = constraints.maxHeight;
                              final backCount = _hotels.length > 2 ? 2 : _hotels.length - 1;
                              return Center(
                                child: SizedBox(
                                  height: cardHeight,
                                  width: constraints.maxWidth - 88,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      for (var depth = backCount; depth >= 1; depth--)
                                        Positioned.fill(
                                          top: depth * 12,
                                          left: depth * 8,
                                          right: depth * 8,
                                          bottom: -depth * 2,
                                          child: Transform.scale(
                                            scale: 1 - depth * 0.035,
                                            alignment: Alignment.topCenter,
                                            child: _HotelSwipeCard(
                                              hotel: _hotels[depth],
                                              location: widget.location,
                                              images: _imagesFor(_hotels[depth]),
                                              index: _seenCount + depth + 1,
                                              total: _totalCount,
                                            ),
                                          ),
                                        ),
                                      Positioned.fill(
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            if (!_isAnimating) setState(() => _dragX += details.delta.dx);
                                          },
                                          onPanEnd: (details) => _finishSwipe(hotel, details.velocity.pixelsPerSecond.dx),
                                          child: Transform.translate(
                                            offset: Offset(_dragX, 0),
                                            child: Transform.rotate(
                                              angle: _dragX / 900,
                                              child: _HotelSwipeCard(
                                                hotel: hotel,
                                                location: widget.location,
                                                images: _imagesFor(hotel),
                                                index: _seenCount + 1,
                                                total: _totalCount,
                                                dragX: _dragX,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '${(_seenCount + 1).clamp(1, _totalCount)} / $_totalCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF52647A), fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _DeckActionButton(icon: Icons.close_rounded, color: const Color(0xFFFF6B6B), onTap: () => _dismiss(hotel, false)),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Vuốt trái để bỏ qua',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Color(0xFF52647A), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    _DeckActionButton(icon: Icons.favorite_rounded, color: const Color(0xFF56D6A0), onTap: () => _dismiss(hotel, true)),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Vuốt phải để xem chi tiết',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Color(0xFF52647A), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
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

class _DeckActionButton extends StatefulWidget {
  const _DeckActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_DeckActionButton> createState() => _DeckActionButtonState();
}

class _DeckActionButtonState extends State<_DeckActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: _pressed ? 1.12 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 5,
          child: InkWell(
            customBorder: const CircleBorder(),
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            onTap: widget.onTap,
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(widget.icon, color: widget.color, size: 29),
            ),
          ),
        ),
      );
}

class _ExperienceTag extends StatelessWidget {
  const _ExperienceTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3EA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: const Color(0xFFB48A3C)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF52647A),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _HotelSwipeCard extends StatelessWidget {
  const _HotelSwipeCard({
    required this.hotel,
    required this.location,
    required this.images,
    required this.index,
    required this.total,
    this.dragX = 0,
  });

  final Hotel hotel;
  final String location;
  final Future<List<String>> images;
  final int index;
  final int total;
  final double dragX;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x26102A50), blurRadius: 18, spreadRadius: 1, offset: Offset(0, 7))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<List<String>>(
                  future: images,
                  builder: (context, snapshot) {
                    final availableImages = snapshot.data
                            ?.where((value) => value.isNotEmpty)
                            .toList() ??
                        const <String>[];
                    final url = availableImages.isEmpty ? null : availableImages.first;
                    if (url != null) {
                      return Image.network(url, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackImage());
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(color: const Color(0xFFE8ECF2),
                          child: const Center(child: AppLoadingIndicator()));
                    }
                    return _fallbackImage();
                  },
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD9000000)],
                      stops: [0.42, 1],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
                if ((hotel.starRating ?? 0) > 0)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB400), size: 16),
                        const SizedBox(width: 3),
                        Text('${hotel.starRating}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                if (dragX.abs() > 20)
                  Align(
                    alignment: dragX > 0 ? Alignment.topLeft : Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: dragX > 0 ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(dragX > 0 ? 'THÍCH' : 'BỎ QUA',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: .22), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 23),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xCC0E1F38), borderRadius: BorderRadius.circular(18)),
                    child: Text('$index / $total', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF26364A), fontSize: 16, height: 1.2, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFB48A3C), size: 26),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFF6B829B), size: 17),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.address.isNotEmpty ? hotel.address : hotel.city.isNotEmpty ? hotel.city : location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF6B829B), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ExperienceTag(
                        icon: Icons.local_activity_rounded,
                        label: 'Vui ch\u01a1i',
                      ),
                      const SizedBox(width: 6),
                      _ExperienceTag(
                        icon: Icons.spa_rounded,
                        label: 'Ngh\u1ec9 d\u01b0\u1ee1ng',
                      ),
                      const SizedBox(width: 6),
                      _ExperienceTag(
                        icon: Icons.beach_access_rounded,
                        label: 'Resort',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() => DestinationImage(
        location: hotel.city.isEmpty ? location : hotel.city,
        networkUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=85',
      );
}
