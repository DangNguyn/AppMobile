import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/api_repository.dart';
import 'api/models.dart';

class AiSupportPage extends StatefulWidget {
  const AiSupportPage({
    super.key,
    this.hotelId,
    this.hotelName,
  });

  final String? hotelId;
  final String? hotelName;

  @override
  State<AiSupportPage> createState() => _AiSupportPageState();
}

class _AiSupportPageState extends State<AiSupportPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_SupportMessage> _messages = [
    const _SupportMessage(
      text:
          'Xin chào! Mình là trợ lý FomoGo. Bạn cần hỗ trợ về khách sạn, phòng, đặt chỗ hay tài khoản?',
      isUser: false,
    ),
  ];
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
    final normalized = text.toLowerCase();
    try {
      if (_isVoucherQuestion(normalized)) {
        await _replyWithVouchers();
        return;
      }
      if (_isGuestCapacityQuestion(normalized)) {
        await _replyWithRoomCapacity();
        return;
      }
      if (normalized.contains('khách sạn') ||
          normalized.contains('hotel') ||
          normalized.contains('phòng')) {
        final hotels = await apiRepository.hotels();
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(
            _SupportMessage(
              text: hotels.isEmpty
                  ? 'Mình chưa tìm thấy dữ liệu khách sạn lúc này. Bạn thử lại sau nhé.'
                  : 'Mình đã tìm thấy ${hotels.length} khách sạn trong hệ thống. Bạn có thể về trang chủ để xem và đặt phòng.',
              isUser: false,
            ),
          );
        });
      } else if (normalized.contains('đặt') ||
          normalized.contains('thanh toán') ||
          normalized.contains('booking')) {
        _addReply(
          'Mình có thể hỗ trợ các vấn đề về đặt phòng và thanh toán. Bạn hãy gửi mã đặt phòng hoặc mô tả rõ vấn đề cần xử lý nhé.',
        );
      } else if (normalized.contains('tài khoản') ||
          normalized.contains('hồ sơ') ||
          normalized.contains('thông tin')) {
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
      text.contains('mã giảm') ||
      text.contains('giảm giá') ||
      text.contains('khuyến mãi');

  bool _isGuestCapacityQuestion(String text) =>
      text.contains('số lượng khách') ||
      text.contains('bao nhiêu người') ||
      text.contains('tối đa') ||
      text.contains('sức chứa') ||
      text.contains('max guest') ||
      text.contains('người ở');

  Future<void> _replyWithVouchers() async {
    final vouchers = await apiRepository.vouchers();
    final available = vouchers.where(_isCurrentlyAvailable).toList();
    if (!mounted) return;
    if (available.isEmpty) {
      _addReply(
        _hotelNameSuffix('Hiện chưa có voucher đang áp dụng cho phòng.'),
      );
      return;
    }
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
      _hotelNameSuffix(
        'Các voucher đang có thể áp dụng theo điều kiện đơn phòng:\n$lines\n\nBạn nhập mã voucher ở bước đặt phòng để hệ thống kiểm tra chính xác giá trị đơn.',
      ),
    );
  }

  Future<void> _replyWithRoomCapacity() async {
    final hotelId = widget.hotelId;
    if (hotelId == null || hotelId.isEmpty) {
      _addReply(
        'Bạn đang hỏi sức chứa phòng. Hãy mở cuộc trò chuyện từ trang khách sạn cụ thể để mình trả đúng số khách tối đa của từng loại phòng.',
      );
      return;
    }
    final roomTypes = await apiRepository.roomTypes(hotelId);
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

  void _addReply(String text) {
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_SupportMessage(text: text, isUser: false));
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trợ lý FomoGo'),
            Text(
              widget.hotelName == null
                  ? 'Luôn sẵn sàng hỗ trợ'
                  : 'Đang hỗ trợ về ${widget.hotelName}',
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
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.only(bottom: 10),
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
  const _SupportMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
