part of 'booking_app.dart';

class RoomBookingPage extends StatefulWidget {
  final String hotelName;
  final HotelSearchSelection selection;
  final String? hotelId;
  final RoomType? roomType;

  const RoomBookingPage({
    super.key,
    required this.hotelName,
    required this.selection,
    this.hotelId,
    this.roomType,
  });

  @override
  State<RoomBookingPage> createState() => _RoomBookingPageState();
}

class _RoomBookingPageState extends State<RoomBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _requestController = TextEditingController();
  int _step = 0;
  Voucher? _selectedVoucher;
  double? _discountAmount;
  double? _validatedTotalAmount;
  String? _selectedPaymentMethod;
  SavedPaymentCard? _selectedPaymentCard;
  bool _isSubmitting = false;
  bool _isProcessingPayment = false;
  List<String> _availableRoomIds = const [];
  Booking? _pendingBooking;
  Payment? _pendingPayment;
  late final Future<void> _savedPaymentCardLoad;

  int get _nights => widget.selection.dateRange.duration.inDays.clamp(1, 365);
  int get _nightlyRate => widget.roomType?.basePrice.round() ?? 1250000;

  double get _subtotal =>
      (_nightlyRate * _nights * widget.selection.roomCount).toDouble();

  double get _discount => _discountAmount ?? 0;

  double get _total => _validatedTotalAmount ?? _subtotal - _discount;

  Future<Booking?> _ensureBooking() async {
    if (_pendingBooking != null) return _pendingBooking;
    if (widget.hotelId == null || _availableRoomIds.isEmpty || _isSubmitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.hotelId == null
                ? 'Đã ghi nhận phương thức thanh toán. Đây là bản xem trước.'
                : 'Chưa xác định được phòng trống từ API.',
          ),
        ),
      );
      return null;
    }
    setState(() => _isSubmitting = true);
    try {
      final booking = await apiRepository.createBooking(
        hotelId: widget.hotelId!,
        roomIds: _availableRoomIds.take(widget.selection.roomCount).toList(),
        checkIn: _dateOnly(widget.selection.dateRange.start),
        checkOut: _dateOnly(widget.selection.dateRange.end),
        adults: widget.selection.adultCount,
        children: widget.selection.childCount,
        bookingEmail: _emailController.text.trim(),
        voucherCode: _selectedVoucher?.code,
      );
      await apiRepository.addBookingGuest(
        bookingId: booking.id,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );
      _pendingBooking = booking;
      return booking;
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continuePayment() async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);
    try {
      final navigator = Navigator.of(context);
      await _savedPaymentCardLoad;
      if (!mounted) return;
      if (_selectedPaymentMethod == 'card' && _selectedPaymentCard == null) {
        await _chooseNewPaymentCard();
        if (!mounted || _selectedPaymentCard == null) return;
      }
      final booking = await _ensureBooking();
      if (booking == null || !mounted) return;
      try {
        final method = _selectedPaymentMethod == 'qr' ? 'qr' : 'card';
        if (_pendingPayment?.paymentMethod != method) {
          _pendingPayment = await apiRepository.createPayment(
            bookingId: booking.id,
            method: method,
          );
        }
      } on ApiException catch (error) {
        if (error.statusCode == 409) {
          final completedPayment = await _findCompletedPayment(booking.id);
          if (!mounted) return;
          if (completedPayment != null) {
            await _showSuccessScreen(completedPayment);
            return;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
        }
        return;
      }
      if (_selectedPaymentMethod == 'qr') {
        try {
          final qr = await apiRepository.paymentQr(_pendingPayment!.id);
          if (!navigator.mounted) return;
          final completed = await showModalBottomSheet<bool>(
            context: navigator.context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => _PaymentQrSheet(
              qrContent: '${qr['qr_content'] ?? ''}',
            ),
          );
          if (completed == true && mounted) await _simulatePayment();
        } on ApiException catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(error.message)));
          }
        }
        return;
      }
      if (_selectedPaymentMethod == 'card') {
        await _simulatePayment();
        return;
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _simulatePayment() async {
    if (!mounted || _pendingPayment == null || _pendingBooking == null) return;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final loadingDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PaymentLoadingDialog(),
    );
    Payment? payment;
    ApiException? paymentError;
    try {
      payment = await apiRepository.simulatePayment(
        paymentId: _pendingPayment!.id,
        result: 'success',
      );
    } on ApiException catch (error) {
      paymentError = error;
    } finally {
      if (rootNavigator.canPop()) rootNavigator.pop();
      await loadingDialog;
    }
    if (!mounted) return;

    if (paymentError != null) {
      final error = paymentError;
      if (error.statusCode == 409) {
        final completedPayment = await _findCompletedPayment(
          _pendingBooking!.id,
        );
        if (!mounted) return;
        if (completedPayment != null) {
          await _showSuccessScreen(completedPayment);
          return;
        }
      }
      if (error.statusCode == 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cổng thanh toán chưa xác nhận giao dịch. Đơn vẫn đang chờ xử lý; vui lòng thử lại sau.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
      return;
    }

    if (payment == null || !_isPaymentSuccessful(payment.status)) {
      final completedPayment = await _findCompletedPayment(
        _pendingBooking!.id,
      );
      if (!mounted) return;
      if (completedPayment != null) {
        await _showSuccessScreen(completedPayment);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thanh toán chưa được xác nhận. Đơn vẫn đang chờ xử lý.',
          ),
        ),
      );
      return;
    }
    await _showSuccessScreen(payment);
  }

  Future<Payment?> _findCompletedPayment(String bookingId) async {
    try {
      final payments = await apiRepository.payments(bookingId);
      for (final payment in payments.reversed) {
        if (_isPaymentSuccessful(payment.status)) {
          try {
            return await apiRepository.payment(payment.id);
          } on ApiException {
            return payment;
          }
        }
      }
    } on ApiException {
      // Keep the original payment error visible when the status lookup fails.
    }
    return null;
  }

  Future<void> _showSuccessScreen(Payment payment) async {
    if (!mounted || _pendingBooking == null) return;
    final emailFeedback = _paymentEmailFeedback(payment, _pendingBooking!);
    if (emailFeedback != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(emailFeedback)));
    }
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => BookingSuccessScreen(
          booking: _pendingBooking!,
          payment: payment,
        ),
      ),
    );
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadAvailableRooms();
    _loadCurrentUser();
    _savedPaymentCardLoad = _loadSavedPaymentCard();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await apiRepository.me();
      if (!mounted) return;
      setState(() {
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = user.fullName;
        }
        if (_phoneController.text.trim().isEmpty) {
          _phoneController.text = user.phone;
        }
        if (_emailController.text.trim().isEmpty) {
          _emailController.text = user.email;
        }
      });
    } on ApiException {
      // The guest can still enter contact details manually if not signed in.
    }
  }

  Future<void> _loadSavedPaymentCard() async {
    final cards = await SavedPaymentCardStore.loadCards();
    if (!mounted || cards.isEmpty) return;
    setState(() => _selectedPaymentCard = cards.first);
  }

  Future<void> _chooseNewPaymentCard() async {
    final card = await Navigator.of(context).push<SavedPaymentCard>(
      MaterialPageRoute<SavedPaymentCard>(
        builder: (_) => const AddPaymentCardPage(
          submitLabel: 'Dùng thẻ này',
        ),
      ),
    );
    if (card != null && mounted) {
      await SavedPaymentCardStore.saveCard(card);
      if (!mounted) return;
      setState(() => _selectedPaymentCard = card);
    }
  }

  Future<void> _loadAvailableRooms() async {
    if (widget.hotelId == null) return;
    try {
      final rooms = await apiRepository.availableRooms(
        hotelId: widget.hotelId!,
        checkIn: _dateOnly(widget.selection.dateRange.start),
        checkOut: _dateOnly(widget.selection.dateRange.end),
        roomTypeId: widget.roomType?.id,
      );
      if (mounted) {
        setState(
            () => _availableRoomIds = rooms.map((room) => room.id).toList());
      }
    } on ApiException {
      // The submit action surfaces the actionable API error; no mutation is retried.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  String _formatVnd(num amount) {
    final digits = amount.round().toString();
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
    final validation = await showModalBottomSheet<VoucherValidation>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetAnimationStyle,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _VoucherSelectionSheet(
        currentSubtotal: _subtotal,
      ),
    );
    if (!mounted || validation == null) return;
    setState(() {
      _selectedVoucher = validation.voucher;
      _discountAmount = validation.discountAmount;
      _validatedTotalAmount = validation.totalAmount;
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
        backgroundColor: const Color(0xFF0E1F38),
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
        actions: [
          if (MediaQuery.viewInsetsOf(context).bottom > 0)
            TextButton.icon(
              onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
              icon: const Icon(Icons.keyboard_hide_rounded),
              label: const Text('Xong'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
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
                          style: TextStyle(fontWeight: FontWeight.w400),
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
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).unfocus(),
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
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                              color: Color(0xFF0E1F38),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedVoucher == null
                                    ? 'Chọn phiếu giảm giá hoặc coupon'
                                    : '${_selectedVoucher!.code} · Giảm ${_formatVnd(_discount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Text(
                              _selectedVoucher == null ? 'Chọn' : 'Đổi',
                              style: const TextStyle(
                                color: Color(0xFF0E1F38),
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
                        if (_selectedVoucher != null) ...[
                          const SizedBox(height: 10),
                          _priceLine(
                            'Ưu đãi ${_selectedVoucher!.code}',
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
                      : _isSubmitting || _isProcessingPayment
                          ? null
                          : _continuePayment,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E1F38),
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
                        : _selectedPaymentMethod == 'card' &&
                                _selectedPaymentCard == null
                            ? 'Nhập thông tin thẻ'
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
          key: const ValueKey('booking_total_card'),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1F38),
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
          id: 'qr',
          title: 'VietQR',
          subtitle: 'Quét mã bằng ứng dụng ngân hàng',
          icon: Icons.qr_code_2_rounded,
          color: const Color(0xFF0E1F38),
        ),
        _paymentOption(
          id: 'card',
          title: 'Thẻ thanh toán',
          subtitle: _selectedPaymentCard == null
              ? 'Visa · Mastercard · JCB · AMEX'
              : '${_selectedPaymentCard!.cardType} •••• ${_selectedPaymentCard!.lastFour}',
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF34495E),
        ),
        if (_selectedPaymentMethod == 'card') ...[
          if (_selectedPaymentCard != null)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFFF4F8FE),
              child: ListTile(
                leading: const Icon(Icons.credit_card_rounded),
                title: Text(
                  '${_selectedPaymentCard!.cardType} •••• ${_selectedPaymentCard!.lastFour}',
                ),
                subtitle: Text(
                  '${_selectedPaymentCard!.holder} · Hết hạn ${_selectedPaymentCard!.expiry}',
                ),
                trailing: TextButton(
                  onPressed: _chooseNewPaymentCard,
                  child: const Text('Đổi thẻ'),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _chooseNewPaymentCard,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Nhập thẻ mới'),
              ),
            ),
        ],
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
          color: selected ? const Color(0xFF0E1F38) : const Color(0xFFE5E9ED),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          _selectedPaymentMethod = id;
        }),
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
                        ? const Color(0xFF0E1F38)
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
                            color: Color(0xFF0E1F38),
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
                        fontWeight: FontWeight.w400,
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
              Icon(icon, color: const Color(0xFF0E1F38), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF19232D),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
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
        borderSide: const BorderSide(color: Color(0xFF0E1F38), width: 1.5),
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

class _VoucherSelectionSheet extends StatefulWidget {
  const _VoucherSelectionSheet({
    required this.currentSubtotal,
  });

  final double currentSubtotal;

  @override
  State<_VoucherSelectionSheet> createState() => _VoucherSelectionSheetState();
}

class _VoucherSelectionSheetState extends State<_VoucherSelectionSheet> {
  late Future<List<Voucher>> _vouchers;
  final Map<String, VoucherValidation> _validatedVouchers = {};
  final Map<String, String> _eligibilityReasons = {};
  final Map<String, String> _validationErrors = {};
  String? _loadingCode;

  @override
  void initState() {
    super.initState();
    _vouchers = _loadVouchers();
  }

  Future<List<Voucher>> _loadVouchers() async {
    final saved = await voucherStorageService.getSavedVoucherCodes();
    final savedCodes = saved.map((code) => code.trim().toUpperCase()).toSet();
    final vouchersByCode = <String, Voucher>{};
    for (final voucher in await apiRepository.vouchers()) {
      vouchersByCode[voucher.code.toUpperCase()] = voucher;
    }

    // The public list contains only active vouchers. Fetch saved codes missing
    // from it individually so expired/inactive saved vouchers can remain visible
    // as disabled choices with the API's actual eligibility response.
    for (final code in savedCodes) {
      if (vouchersByCode.containsKey(code)) continue;
      try {
        final voucher = await apiRepository.voucher(code);
        vouchersByCode[voucher.code.toUpperCase()] = voucher;
      } on ApiException catch (error) {
        _eligibilityReasons[code] = error.message;
      }
    }

    final vouchers = vouchersByCode.values.toList();

    // Ask the backend about each voucher separately. This lets the backend
    // apply voucher-specific rules instead of assuming every code only has a
    // minimum-order condition.
    await Future.wait(vouchers.map((voucher) async {
      final key = voucher.code.toUpperCase();
      try {
        _validatedVouchers[key] = await apiRepository.validateVoucher(
          code: voucher.code,
          subtotal: widget.currentSubtotal,
        );
      } on ApiException catch (error) {
        if (error.statusCode == 400 || error.statusCode == 404) {
          _eligibilityReasons[key] = error.message;
        } else {
          _validationErrors[key] = error.message;
        }
      }
    }));

    vouchers.sort((first, second) {
      final firstCode = first.code.toUpperCase();
      final secondCode = second.code.toUpperCase();
      final savedOrder = (savedCodes.contains(secondCode) ? 1 : 0)
          .compareTo(savedCodes.contains(firstCode) ? 1 : 0);
      if (savedOrder != 0) return savedOrder;
      final usableOrder = (_validatedVouchers.containsKey(secondCode) ? 1 : 0)
          .compareTo(_validatedVouchers.containsKey(firstCode) ? 1 : 0);
      if (usableOrder != 0) return usableOrder;
      return first.code.compareTo(second.code);
    });
    return vouchers;
  }

  String _formatVnd(num value) =>
      '${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';

  String _formatDate(DateTime? value) {
    if (value == null) return 'Không xác định';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> _apply(Voucher voucher) async {
    final key = voucher.code.toUpperCase();
    if (!_validatedVouchers.containsKey(key)) return;
    setState(() => _loadingCode = voucher.code);
    try {
      final validation = await apiRepository.validateVoucher(
        code: voucher.code,
        subtotal: widget.currentSubtotal,
      );
      if (mounted) Navigator.of(context).pop(validation);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadingCode = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Column(
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
              const SizedBox(height: 18),
              const Text(
                'Chọn mã giảm giá',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Tạm tính: ${_formatVnd(widget.currentSubtotal)}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Voucher>>(
                  future: _vouchers,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: AppLoadingIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Không thể tải mã: ${snapshot.error}'));
                    }
                    final vouchers = snapshot.data ?? const <Voucher>[];
                    if (vouchers.isEmpty) {
                      return const Center(child: Text('Chưa có mã giảm giá.'));
                    }
                    return ListView.separated(
                      itemCount: vouchers.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final voucher = vouchers[index];
                        final voucherKey = voucher.code.toUpperCase();
                        final valid =
                            _validatedVouchers.containsKey(voucherKey);
                        final isPercent = voucher.discountType == 'percent';
                        return Opacity(
                          opacity: valid ? 1 : 0.5,
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: valid
                                    ? const Color(0xFFB9D5FF)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer_rounded,
                                    color: Color(0xFF2A6EEB),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          voucher.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          isPercent
                                              ? 'Giảm ${voucher.discountValue.round()}%'
                                              : 'Giảm ${_formatVnd(voucher.discountValue)}',
                                          style: const TextStyle(
                                            color: Color(0xFF1688C7),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          valid
                                              ? 'HSD ${_formatDate(voucher.endDate)}'
                                              : _eligibilityReasons[
                                                      voucherKey] ??
                                                  _validationErrors[
                                                      voucherKey] ??
                                                  'Chưa xác minh được điều kiện',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: valid && _loadingCode == null
                                        ? () => _apply(voucher)
                                        : null,
                                    child: Text(
                                      _loadingCode == voucher.code
                                          ? 'Đang kiểm tra'
                                          : 'Áp dụng',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomAmenityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dense;

  const _RoomAmenityItem(
      {required this.icon, required this.label, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 6 : 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 15 : 17, color: const Color(0xFF0E1F38)),
          SizedBox(width: dense ? 5 : 7),
          Text(
            label,
            maxLines: dense ? 1 : null,
            overflow: dense ? TextOverflow.ellipsis : null,
            style: TextStyle(
              color: Color(0xFF394550),
              fontSize: dense ? 11 : 13,
              fontWeight: FontWeight.w300,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0E1F38)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFF394550),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
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
        Icon(icon, size: 18, color: const Color(0xFF0E1F38)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF6D747B), fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF26323D),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
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
                                ? const Color(0xFF0E1F38)
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
              Icon(icon, color: const Color(0xFF0E1F38), size: 22),
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
            color:
                isSelected ? const Color(0xFF0E1F38) : const Color(0xFFF5F5F7),
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
