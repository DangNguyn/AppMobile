import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/api_repository.dart';
import 'api/models.dart';
import 'booking_app.dart' as hotel_booking;
import 'chat_query_parser.dart';

class AiSupportPage extends StatefulWidget {
  const AiSupportPage({
    super.key,
    this.hotelId,
    this.hotelName,
    this.repository,
  });

  final String? hotelId;
  final String? hotelName;
  final ApiRepository? repository;

  @override
  State<AiSupportPage> createState() => _AiSupportPageState();
}

class _AiSupportPageState extends State<AiSupportPage> {
  ApiRepository get _api => widget.repository ?? apiRepository;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final hotel_booking.HotelSearchSelection _hotelSelection;
  final List<_SupportMessage> _messages = [
    const _SupportMessage(
      text:
          'Xin chào! Mình là trợ lý FomoGo. Bạn cần hỗ trợ về khách sạn, phòng, đặt chỗ hay tài khoản?',
      isUser: false,
    ),
  ];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _hotelSelection = hotel_booking.HotelSearchSelection();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _hotelSelection.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;
    _controller.clear();
    setState(() {
      _messages.add(_SupportMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();
    _reply(text);
  }

  Future<void> _reply(String text) async {
    final normalized = _normalize(text);
    try {
      if (_isHotelQuestion(normalized)) {
        await _replyWithHotels(text);
        return;
      }
      if (_isVoucherQuestion(normalized)) {
        await _replyWithVouchers(text);
        return;
      }
      if (_isGuestCapacityQuestion(normalized)) {
        await _replyWithRoomCapacity();
        return;
      }
      if (normalized.contains('dat') ||
          normalized.contains('thanh toan') ||
          normalized.contains('booking')) {
        _addReply(
          'Mình có thể hỗ trợ các vấn đề về đặt phòng và thanh toán. Bạn hãy gửi mã đặt phòng hoặc mô tả rõ vấn đề cần xử lý nhé.',
        );
      } else if (normalized.contains('tai khoan') ||
          normalized.contains('ho so') ||
          normalized.contains('thong tin')) {
        _addReply(
          'Bạn vào Tài khoản → Cài đặt → Thông tin tài khoản để chỉnh sửa và lưu thông tin cá nhân.',
        );
      } else {
        _addReply(
          'Mình đã nhận được câu hỏi của bạn. Bạn có thể nói rõ hơn về khách sạn, phòng, đặt chỗ, thanh toán hoặc tài khoản để mình hỗ trợ chính xác hơn nhé.',
        );
      }
    } on ApiException catch (error) {
      _addReply('Mình chưa tải được dữ liệu lúc này: ${error.message}');
    } catch (_) {
      _addReply('Mình chưa kết nối được với hệ thống. Bạn thử lại sau nhé.');
    }
    _scrollToBottom();
  }

  bool _isVoucherQuestion(String text) =>
      text.contains('voucher') ||
      text.contains('ma giam') ||
      text.contains('giam gia') ||
      text.contains('khuyen mai');

  bool _isHotelQuestion(String text) =>
      text.contains('khach san') ||
      text.contains('hotel') ||
      text.contains('phong') ||
      text.contains('cho nghi');

  bool _isGuestCapacityQuestion(String text) =>
      text.contains('so luong khach') ||
      text.contains('bao nhieu nguoi') ||
      text.contains('toi da') ||
      text.contains('suc chua') ||
      text.contains('max guest') ||
      text.contains('nguoi o');

  Future<void> _replyWithVouchers(String text) async {
    final vouchers = await _api.vouchers();
    final range = ChatQueryParser.priceRange(text);
    final budget = range.maximum ?? range.exact ?? range.minimum;
    final available = vouchers
        .where(_isCurrentlyAvailable)
        .where((voucher) => budget == null || voucher.minOrder <= budget)
        .toList();
    if (!mounted) return;
    if (available.isEmpty) {
      _addReply(
        budget == null
            ? 'Hiện chưa có voucher đang áp dụng cho phòng.'
            : 'Chưa có voucher nào đạt điều kiện với mức đơn dự kiến ${_formatMoney(budget)}.',
      );
      return;
    }
    available.sort((a, b) => budget == null
        ? b.discountValue.compareTo(a.discountValue)
        : _voucherSavings(b, budget).compareTo(_voucherSavings(a, budget)));
    final lines = available.take(8).map((voucher) {
      final discount = voucher.discountType.toLowerCase() == 'percent'
          ? '${voucher.discountValue.toStringAsFixed(0)}%'
          : '${voucher.discountValue.toStringAsFixed(0)}đ';
      final minimum = voucher.minOrder > 0
          ? ', đơn tối thiểu ${_formatMoney(voucher.minOrder)}'
          : '';
      return '• ${voucher.code}: giảm $discount$minimum';
    }).join('\n');
    _addReply(
      'Voucher đang hoạt động${budget == null ? '' : ' phù hợp với đơn khoảng ${_formatMoney(budget)}'}:\n$lines\n\nAPI sẽ kiểm tra lại điều kiện và số tiền giảm khi bạn áp dụng mã ở bước đặt phòng.',
      vouchers: available.take(8).toList(),
    );
  }

  Future<void> _replyWithHotels(String text) async {
    final normalized = _normalize(text);
    final city = ChatQueryParser.city(normalized);
    final requestedGuests = ChatQueryParser.guests(normalized);
    final guests = requestedGuests ?? 2;
    final nights = ChatQueryParser.nights(normalized) ?? 1;
    final priceRange = ChatQueryParser.priceRange(text);
    var hotels = await _api.hotels();
    if (widget.hotelId != null && widget.hotelId!.isNotEmpty && city == null) {
      hotels = hotels.where((hotel) => hotel.id == widget.hotelId).toList();
    }
    if (city != null) {
      final targetCity = _normalize(city);
      hotels = hotels
          .where((hotel) =>
              _normalize('${hotel.city} ${hotel.address}').contains(targetCity))
          .toList();
    }
    if (hotels.isEmpty) {
      _addReply(
        'Mình chưa tìm thấy khách sạn${city == null ? '' : ' ở $city'} trong dữ liệu hiện tại. Bạn thử một địa điểm khác nhé.',
      );
      return;
    }

    final candidates = city == null ? hotels.take(12).toList() : hotels;
    final results = await Future.wait(candidates.map((hotel) async {
      try {
        final roomTypes = await _api.roomTypes(hotel.id);
        final roomsForGuests = roomTypes
            .where((room) =>
                room.maxGuests >= guests && priceRange.matches(room.basePrice))
            .toList()
          ..sort((a, b) => a.basePrice.compareTo(b.basePrice));
        if (roomsForGuests.isNotEmpty) {
          return _HotelRecommendation(
            hotel: hotel,
            roomType: roomsForGuests.first,
          );
        }
        return roomTypes.isEmpty &&
                requestedGuests == null &&
                priceRange.minimum == null &&
                priceRange.maximum == null &&
                priceRange.exact == null
            ? _HotelRecommendation(hotel: hotel)
            : null;
      } on ApiException {
        final hasPriceConstraint = requestedGuests != null ||
            priceRange.minimum != null ||
            priceRange.maximum != null ||
            priceRange.exact != null;
        return hasPriceConstraint ? null : _HotelRecommendation(hotel: hotel);
      }
    }));
    final suitableHotels = results.whereType<_HotelRecommendation>().toList()
      ..sort((a, b) => (a.roomType?.basePrice ?? double.maxFinite)
          .compareTo(b.roomType?.basePrice ?? double.maxFinite));
    if (suitableHotels.isEmpty) {
      _addReply(
        'Mình chưa tìm thấy loại phòng phù hợp cho $guests người${city == null ? '' : ' ở $city'}${priceRange.description.isEmpty ? '' : ' với giá ${priceRange.description}'}. Bạn thử điều chỉnh số khách, khoảng giá hoặc thành phố nhé.',
      );
      return;
    }

    final recommendations = suitableHotels.take(5).toList();
    final nightlyEstimate = recommendations.first.roomType?.basePrice;
    final subtotalEstimate =
        nightlyEstimate == null ? null : nightlyEstimate * nights;
    List<Voucher> suitableVouchers = const [];
    try {
      suitableVouchers = (await _api.vouchers())
          .where(_isCurrentlyAvailable)
          .where((voucher) =>
              subtotalEstimate == null || voucher.minOrder <= subtotalEstimate)
          .toList()
        ..sort((a, b) => subtotalEstimate == null
            ? b.discountValue.compareTo(a.discountValue)
            : _voucherSavings(b, subtotalEstimate)
                .compareTo(_voucherSavings(a, subtotalEstimate)));
    } on ApiException {
      // Hotel suggestions remain useful when the voucher API is unavailable.
    }
    if (!mounted) return;
    final voucherSummary = suitableVouchers.isEmpty
        ? 'Chưa có voucher phù hợp với giá tham khảo này.'
        : 'Voucher có thể phù hợp theo giá tham khảo: ${suitableVouchers.take(3).map((voucher) => voucher.code).join(', ')}. API sẽ xác nhận mức giảm cuối cùng khi đặt phòng.';
    _addReply(
      'Mình tìm được ${suitableHotels.length} khách sạn${city == null ? '' : ' tại $city'} có loại phòng phù hợp cho $guests người${priceRange.description.isEmpty ? '' : ' với giá ${priceRange.description}'}. Gợi ý được lọc từ dữ liệu khách sạn và sức chứa phòng trên API. $voucherSummary\n\nChạm vào thẻ khách sạn để chọn ngày và xem phòng còn trống.',
      hotels: recommendations,
      vouchers: suitableVouchers.take(3).toList(),
    );
  }

  String _normalize(String value) => ChatQueryParser.normalize(value);

  Future<void> _replyWithRoomCapacity() async {
    final hotelId = widget.hotelId;
    if (hotelId == null || hotelId.isEmpty) {
      _addReply(
        'Bạn đang hỏi sức chứa phòng. Hãy mở cuộc trò chuyện từ trang khách sạn cụ thể để mình trả đúng số khách tối đa của từng loại phòng.',
      );
      return;
    }
    final roomTypes = await _api.roomTypes(hotelId);
    if (!mounted) return;
    if (roomTypes.isEmpty) {
      _addReply(
          'Mình chưa nhận được thông tin sức chứa phòng của khách sạn này.');
      return;
    }
    final lines = roomTypes.map((room) {
      final capacity = room.maxGuests > 0
          ? '${room.maxGuests} người'
          : 'chưa cập nhật sức chứa';
      return '• ${room.name}: tối đa $capacity';
    }).join('\n');
    _addReply(
      _hotelNameSuffix(
        'Số khách tối đa theo loại phòng:\n$lines\n\nSố người thực tế còn phụ thuộc số phòng bạn chọn và thông tin đặt phòng.',
      ),
    );
  }

  bool _isCurrentlyAvailable(Voucher voucher) {
    if (voucher.status.toLowerCase() != 'active') return false;
    final now = DateTime.now();
    if (voucher.startDate != null && now.isBefore(voucher.startDate!)) {
      return false;
    }
    if (voucher.endDate != null && now.isAfter(voucher.endDate!)) {
      return false;
    }
    return true;
  }

  String _hotelNameSuffix(String message) {
    final hotelName = widget.hotelName;
    if (hotelName == null || hotelName.isEmpty) return message;
    return 'Tại $hotelName:\n$message';
  }

  String _formatMoney(double value) =>
      '${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';

  double _voucherSavings(Voucher voucher, double subtotal) =>
      voucher.discountType.toLowerCase() == 'percent'
          ? subtotal * voucher.discountValue / 100
          : voucher.discountValue;

  Widget _hotelRecommendationCard(_HotelRecommendation recommendation) {
    final hotel = recommendation.hotel;
    final roomType = recommendation.roomType;
    return SizedBox(
      width: 278,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => hotel_booking.HotelDetailPage(
                selection: _hotelSelection,
                hotelName: hotel.name,
                hotelId: hotel.id,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: double.infinity,
                child: FutureBuilder<List<String>>(
                  future: _api.hotelImages(hotel.id),
                  builder: (context, snapshot) {
                    final images = snapshot.data ?? const <String>[];
                    if (images.isNotEmpty) {
                      return Image.network(
                        images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _hotelImageFallback(),
                      );
                    }
                    return _hotelImageFallback();
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hotel.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hotel.address.isEmpty ? hotel.city : hotel.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7785),
                          fontSize: 12,
                        ),
                      ),
                      if (roomType != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          '${roomType.name} · tối đa ${roomType.maxGuests} khách',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Từ ${_formatMoney(roomType.basePrice)}/đêm',
                          style: const TextStyle(
                            color: Color(0xFF1674C5),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ] else
                        const Text(
                          'Chưa có dữ liệu loại phòng',
                          style: TextStyle(
                            color: Color(0xFF6B7785),
                            fontSize: 11,
                          ),
                        ),
                      const Spacer(),
                      const Text(
                        'Chạm để xem khách sạn →',
                        style: TextStyle(
                          color: Color(0xFF315F9C),
                          fontSize: 11,
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

  Widget _hotelImageFallback() => const ColoredBox(
        color: Color(0xFFEAF1F8),
        child: Center(
          child: Icon(Icons.hotel_rounded, color: Color(0xFF315F9C)),
        ),
      );

  Widget _voucherCard(Voucher voucher) {
    final discount = voucher.discountType.toLowerCase() == 'percent'
        ? '${voucher.discountValue.toStringAsFixed(0)}%'
        : _formatMoney(voucher.discountValue);
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined,
              color: Color(0xFF315F9C), size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${voucher.code} · giảm $discount${voucher.minOrder > 0 ? ' từ ${_formatMoney(voucher.minOrder)}' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _addReply(
    String text, {
    List<_HotelRecommendation> hotels = const [],
    List<Voucher> vouchers = const [],
  }) {
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(
        _SupportMessage(
          text: text,
          isUser: false,
          hotels: hotels,
          vouchers: vouchers,
        ),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1F38),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Trợ lý FomoGo', textAlign: TextAlign.center),
            Text(
              widget.hotelName == null
                  ? 'Luôn sẵn sàng hỗ trợ'
                  : 'Đang hỗ trợ về ${widget.hotelName}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFFBFD8FF)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, index) {
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Đang soạn trả lời...'),
                    ),
                  );
                }
                final message = _messages[index];
                final alignment = message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start;
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: alignment,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? const Color(0xFF2A6EEB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.isUser
                                  ? Colors.white
                                  : const Color(0xFF243247),
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (message.hotels.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width - 48,
                            height: 198,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: message.hotels.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, hotelIndex) =>
                                  _hotelRecommendationCard(
                                message.hotels[hotelIndex],
                              ),
                            ),
                          ),
                        ],
                        if (message.vouchers.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ...message.vouchers.map(_voucherCard),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn hỗ trợ',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isTyping ? null : _sendMessage,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportMessage {
  const _SupportMessage({
    required this.text,
    required this.isUser,
    this.hotels = const [],
    this.vouchers = const [],
  });

  final String text;
  final bool isUser;
  final List<_HotelRecommendation> hotels;
  final List<Voucher> vouchers;
}

class _HotelRecommendation {
  const _HotelRecommendation({required this.hotel, this.roomType});

  final Hotel hotel;
  final RoomType? roomType;
}
