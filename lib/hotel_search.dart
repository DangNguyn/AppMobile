part of 'booking_app.dart';

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
      sheetAnimationStyle: AppMotion.sheetAnimationStyle,
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
      sheetAnimationStyle: AppMotion.sheetAnimationStyle,
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
