import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'user_service.dart';
import 'ui_motion.dart';

const _accountNavy = Color(0xFF0E1F38);
const _accountBlue = _accountNavy;
const _accountBlueLight = Color(0xFF173D69);
const _bronze = Color(0xFF9A5A38);

@immutable
class AccountProfileData {
  const AccountProfileData({
    this.fullName = 'Huy Nguyễn',
    this.username = 'Phc_gscmsp',
    this.bio = '',
    this.dateOfBirth = '2006-07-11',
    this.gender = 'Nam',
    this.city = '',
    this.email = '',
    this.mobile = '',
  });

  final String fullName;
  final String username;
  final String bio;
  final String dateOfBirth;
  final String gender;
  final String city;
  final String email;
  final String mobile;

  AccountProfileData copyWith({
    String? fullName,
    String? username,
    String? bio,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? email,
    String? mobile,
  }) {
    return AccountProfileData(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
    );
  }

  Map<String, String> toJson() => {
        'fullName': fullName,
        'username': username,
        'bio': bio,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'city': city,
        'email': email,
        'mobile': mobile,
      };
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AccountProfileData _profile = const AccountProfileData();
  SavedUserData _savedUserData = const SavedUserData();
  late final Future<void> _initialSavedDataLoad;

  @override
  void initState() {
    super.initState();
    _initialSavedDataLoad = _loadSavedUserData();
  }

  Future<void> _loadSavedUserData() async {
    final savedData = await userService.getSavedUserData();
    final onboardingCompleted = await userService.isOnboardingCompleted();
    if (!mounted) return;
    final info = savedData.userInfo;
    setState(() {
      _savedUserData = savedData;
      if (onboardingCompleted) {
        _profile = _profile.copyWith(
          fullName: info.name,
          bio: '',
          dateOfBirth: info.birthDate,
          gender: info.gender,
          city: '',
          email: savedData.email,
          mobile: savedData.mobile,
        );
      } else if (info.name.isNotEmpty) {
        _profile = _profile.copyWith(
          fullName: info.name,
          dateOfBirth: info.birthDate,
          gender: info.gender,
          email: savedData.email,
          mobile: savedData.mobile,
        );
      }
    });
  }

  void _openDetail(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountDetailPage(
          title: title,
          description: description,
          icon: icon,
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    await _initialSavedDataLoad;
    if (!mounted) return;
    final updatedProfile = await Navigator.of(context).push<AccountProfileData>(
      MaterialPageRoute<AccountProfileData>(
        builder: (_) => EditAccountProfilePage(profile: _profile),
      ),
    );
    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
      await userService.saveUserInfo(
        name: updatedProfile.fullName,
        birthDate: updatedProfile.dateOfBirth,
        gender: updatedProfile.gender,
      );
      await userService.saveContactInfo(
        email: updatedProfile.email,
        mobile: updatedProfile.mobile,
      );
      await _loadSavedUserData();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin cá nhân')),
        );
    }
  }

  Future<void> _openSettings() async {
    final updatedProfile = await Navigator.of(context).push<AccountProfileData>(
      MaterialPageRoute<AccountProfileData>(
        builder: (_) => SettingsPage(
          profile: _profile,
          onLogout: widget.onLogout,
        ),
      ),
    );
    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
    }
    if (mounted) await _loadSavedUserData();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF2F5F8),
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 18,
                16,
                22,
              ),
              key: const ValueKey('account_header'),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bronze, Color(0xFF7F432D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chào mừng, ${_profile.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4D9CB),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 9),
                          child: Text(
                            '★ VIP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 9),
                          child: Text(
                            'Bronze',
                            style: TextStyle(
                              color: Color(0xFF40261D),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: 'Cài đặt',
                    onPressed: _openSettings,
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            sliver: SliverList.list(
              children: [
                _ProfileCard(
                  profile: _profile,
                  onOpenProfile: () => _openDetail(
                    context,
                    title: 'Hồ sơ của tôi',
                    description:
                        'Xem và cập nhật thông tin cá nhân dùng cho các chuyến đi của bạn.',
                    icon: Icons.person_outline_rounded,
                  ),
                  onEditProfile: _editProfile,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 10),
                  child:
                      _AccountSectionHeading('Tính năng dành cho thành viên'),
                ),
                _SavedAccountDataCard(data: _savedUserData),
                const Padding(
                  padding: EdgeInsets.only(top: 18, bottom: 10),
                  child: _AccountSectionHeading('Thanh toán & Hoàn tiền'),
                ),
                _AccountOptionCard(
                  items: [
                    _AccountOption(
                      icon: Icons.credit_card_outlined,
                      title: 'Thanh toán',
                      subtitle: 'Thêm hoặc quản lý các thẻ đã lưu',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PaymentMethodsPage(),
                        ),
                      ),
                    ),
                    _AccountOption(
                      icon: Icons.currency_exchange_rounded,
                      title: 'Hoàn tiền',
                      subtitle:
                          'Theo dõi yêu cầu hoàn tiền và thông tin nhận tiền',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RefundPage(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _AccountOptionCard(
                  items: [
                    _AccountOption(
                      icon: Icons.settings_outlined,
                      title: 'Cài đặt',
                      subtitle: 'Tùy chỉnh cài đặt cho tài khoản',
                      onTap: _openSettings,
                    ),
                    _AccountOption(
                      icon: Icons.help_outline_rounded,
                      title: 'Trung tâm hỗ trợ',
                      subtitle: 'Tìm câu trả lời cho những thắc mắc của bạn',
                      onTap: () => _openDetail(
                        context,
                        title: 'Trung tâm hỗ trợ',
                        description:
                            'Xem các câu hỏi thường gặp hoặc liên hệ đội ngũ hỗ trợ để được trợ giúp về chuyến đi.',
                        icon: Icons.help_outline_rounded,
                      ),
                    ),
                    _AccountOption(
                      icon: Icons.mail_outline_rounded,
                      title: 'Liên hệ chúng tôi',
                      subtitle: 'Gửi góp ý hoặc liên hệ với đội ngũ FomoGo',
                      onTap: () => _openDetail(
                        context,
                        title: 'Liên hệ chúng tôi',
                        description:
                            'Chúng tôi luôn sẵn sàng lắng nghe góp ý để cải thiện trải nghiệm du lịch của bạn.',
                        icon: Icons.mail_outline_rounded,
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

class _SavedAccountDataCard extends StatelessWidget {
  const _SavedAccountDataCard({required this.data});

  final SavedUserData data;

  @override
  Widget build(BuildContext context) {
    final info = data.userInfo;
    return Card(
      key: const ValueKey('saved_account_data_card'),
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E9ED)),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.fact_check_outlined, color: _accountBlue),
        title: const Text(
          'Thông tin đã lưu',
          style: TextStyle(
            color: _accountNavy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: [
          _SavedDataTile(
            icon: Icons.person_outline_rounded,
            title: 'Tên cá nhân',
            value: info.name,
          ),
          _SavedDataTile(
            icon: Icons.cake_outlined,
            title: 'Ngày sinh',
            value: info.birthDate,
          ),
          _SavedDataTile(
            icon: Icons.alternate_email_rounded,
            title: 'Email',
            value: data.email,
          ),
          _SavedDataTile(
            icon: Icons.phone_iphone_rounded,
            title: 'Số điện thoại',
            value: data.mobile,
          ),
          _SavedDataTile(
            icon: Icons.payments_outlined,
            title: 'Tiền tệ ưa thích',
            value: data.currency,
          ),
          _SavedDataTile(
            icon: Icons.language_rounded,
            title: 'Ngôn ngữ ưu tiên',
            value: data.language,
          ),
          _SavedDataTile(
            icon: Icons.notifications_active_outlined,
            title: 'Thông báo',
            value: data.notificationEnabled ? 'Đã bật' : 'Đã tắt',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _SavedDataTile extends StatelessWidget {
  const _SavedDataTile({
    required this.icon,
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: _accountBlue, size: 21),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        value.isEmpty ? 'Chưa cập nhật' : value,
        style: const TextStyle(
          color: Color(0xFF687482),
          fontWeight: FontWeight.w400,
        ),
      ),
      shape: showDivider
          ? const Border(
              bottom: BorderSide(color: Color(0xFFE9EDF1)),
            )
          : null,
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  final AccountProfileData profile;
  final Future<void> Function() onLogout;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AccountProfileData _profile = widget.profile;
  String _paymentCurrency = 'VND';
  String _rewardCurrency = 'VND';
  String _language = 'Tiếng Việt';

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final currency = await userService.getCurrency();
    final language = await userService.getLanguage();
    if (!mounted) return;
    setState(() {
      _paymentCurrency = currency;
      _language = language;
    });
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<AccountProfileData>(
      MaterialPageRoute<AccountProfileData>(
        builder: (_) => EditAccountProfilePage(profile: _profile),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  Future<void> _chooseValue({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetAnimationStyle,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Text(
                title,
                style: const TextStyle(
                  color: _accountNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(option),
                trailing: selected == option
                    ? const Icon(Icons.check_circle, color: _accountBlue)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (result != null) onSelected(result);
  }

  void _openDetail(String title, String description, IconData icon) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountDetailPage(
          title: title,
          description: description,
          icon: icon,
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.dialogAnimationStyle,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<AccountProfileData>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_profile);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF0F4),
        appBar: AppBar(
          backgroundColor: _accountBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'Cài đặt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _SettingsSectionHeader('Tài khoản & Bảo mật'),
            _SettingsRow(
              key: const ValueKey('settings_account_info'),
              icon: Icons.person_outline_rounded,
              title: 'Thông tin tài khoản',
              onTap: _editProfile,
            ),
            _SettingsRow(
              key: const ValueKey('settings_password_security'),
              icon: Icons.verified_user_outlined,
              title: 'Mật khẩu & Bảo mật',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PasswordSecurityPage(),
                ),
              ),
            ),
            _SettingsRow(
              icon: Icons.lock_outline_rounded,
              title: 'Thiết lập chế độ riêng tư',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacySettingsPage(),
                ),
              ),
            ),
            const _SettingsSectionHeader('Cài đặt'),
            _SettingsRow(
              title: 'Tiền tệ thanh toán',
              trailingValue: _paymentCurrency,
              onTap: () => _chooseValue(
                title: 'Tiền tệ thanh toán',
                options: const ['VND', 'USD', 'EUR'],
                selected: _paymentCurrency,
                onSelected: (value) {
                  setState(() => _paymentCurrency = value);
                  userService.saveCurrency(value);
                },
              ),
            ),
            _SettingsRow(
              title: 'Ngôn ngữ',
              trailingValue: _language,
              onTap: () => _chooseValue(
                title: 'Ngôn ngữ',
                options: const ['Tiếng Việt', 'English'],
                selected: _language,
                onSelected: (value) {
                  setState(() => _language = value);
                  userService.saveLanguage(value);
                },
              ),
            ),
            _SettingsRow(
              title: 'Tiền tệ phần thưởng',
              trailingValue: _rewardCurrency,
              onTap: () => _chooseValue(
                title: 'Tiền tệ phần thưởng',
                options: const ['VND', 'USD', 'EUR'],
                selected: _rewardCurrency,
                onSelected: (value) => setState(() => _rewardCurrency = value),
              ),
            ),
            const SizedBox(height: 14),
            _SettingsRow(
              icon: Icons.notifications_active_outlined,
              title: 'Cài đặt thông báo',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationSettingsPage(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _SettingsRow(
              title: 'Phiên bản ứng dụng',
              trailingValue: '1.0.0',
              showChevron: false,
            ),
            _SettingsRow(
              title: 'Điều khoản & Điều kiện',
              onTap: () => _openDetail(
                'Điều khoản & Điều kiện',
                'Thông tin điều khoản sử dụng ứng dụng sẽ được cập nhật tại đây.',
                Icons.description_outlined,
              ),
            ),
            _SettingsRow(
              title: 'Chính sách quyền riêng tư',
              onTap: () => _openDetail(
                'Chính sách quyền riêng tư',
                'Thông tin về cách dữ liệu tài khoản được quản lý sẽ được cập nhật tại đây.',
                Icons.privacy_tip_outlined,
              ),
            ),
            _SettingsRow(
              title: 'About Us',
              onTap: () => _openDetail(
                'About Us',
                'FomoGo đồng hành cùng bạn trong những chuyến đi và trải nghiệm lưu trú.',
                Icons.travel_explore_rounded,
              ),
            ),
            _SettingsRow(
              title: 'Quy chế hoạt động',
              onTap: () => _openDetail(
                'Quy chế hoạt động',
                'Thông tin quy chế hoạt động sẽ được cập nhật tại đây.',
                Icons.rule_folder_outlined,
              ),
            ),
            const SizedBox(height: 14),
            _SettingsRow(
              icon: Icons.power_settings_new_rounded,
              title: 'Đăng xuất',
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _privateProfile = false;
  bool _privateReviews = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final privateProfile = await userService.getPrivateProfilePref();
    final privateReviews = await userService.getPrivateReviewsPref();
    if (!mounted) return;
    setState(() {
      _privateProfile = privateProfile;
      _privateReviews = privateReviews;
      _isLoaded = true;
    });
  }

  Future<void> _setPrivateProfile(bool value) async {
    setState(() => _privateProfile = value);
    await userService.savePrivateProfilePref(value);
  }

  Future<void> _setPrivateReviews(bool value) async {
    setState(() => _privateReviews = value);
    await userService.savePrivateReviewsPref(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: _accountNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Hồ sơ riêng tư',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoaded
          ? ListView(
              children: [
                _PrivacySettingTile(
                  key: const ValueKey('private_profile_switch'),
                  switchKey: const ValueKey('private_profile_toggle'),
                  title: 'Đặt tab Bộ sưu tập thành Riêng tư',
                  description:
                      'Nếu bạn đặt cài đặt này thành riêng tư, các bộ sưu tập đã xuất bản của bạn sẽ không có sẵn cho những người khác xem trên hồ sơ của bạn.',
                  value: _privateProfile,
                  onChanged: _setPrivateProfile,
                ),
                const SizedBox(height: 12),
                _PrivacySettingTile(
                  key: const ValueKey('private_reviews_switch'),
                  switchKey: const ValueKey('private_reviews_toggle'),
                  title: 'Đặt tab Đánh giá thành Riêng tư',
                  description:
                      'Nếu bạn đặt cài đặt này thành riêng tư, các bài đánh giá đã xuất bản của bạn sẽ không có sẵn cho những người khác xem trên hồ sơ của bạn.',
                  value: _privateReviews,
                  onChanged: _setPrivateReviews,
                ),
              ],
            )
          : const Center(
              child: AppLoadingIndicator(size: 24),
            ),
    );
  }
}

class _PrivacySettingTile extends StatelessWidget {
  const _PrivacySettingTile({
    super.key,
    required this.switchKey,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 16, 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF303840),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF899199),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              key: switchKey,
              value: value,
              activeTrackColor: _accountNavy,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordSecurityPage extends StatefulWidget {
  const PasswordSecurityPage({super.key});

  @override
  State<PasswordSecurityPage> createState() => _PasswordSecurityPageState();
}

class _PasswordSecurityPageState extends State<PasswordSecurityPage> {
  String? _pin;
  bool _trustedDevice = false;

  Future<void> _editPin() async {
    final updatedPin = await showDialog<String>(
      context: context,
      animationStyle: AppMotion.dialogAnimationStyle,
      builder: (_) => _PinDialog(currentPin: _pin),
    );
    if (updatedPin == null || !mounted) return;

    final isUpdate = _pin != null;
    setState(() => _pin = updatedPin);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isUpdate ? 'Mã PIN đã được cập nhật' : 'Mã PIN đã được thiết lập',
          ),
        ),
      );
  }

  Future<void> _confirmAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.dialogAnimationStyle,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text(
          'Sau khi xóa, bạn có thể mất quyền truy cập vào thông tin tài khoản '
          'và các dữ liệu liên quan. Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel_account_deletion'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            key: const ValueKey('confirm_account_deletion'),
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Ứng dụng chưa kết nối dịch vụ xóa tài khoản. Chưa có dữ liệu nào bị xóa.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: _accountNavy,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Mật khẩu & Bảo mật',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        children: [
          _SecuritySettingTile(
            icon: Icons.pin_outlined,
            title: 'PIN',
            description:
                'Giữ tài khoản của bạn an toàn bằng cách cài mã PIN để xác minh một số hoạt động trong ứng dụng.',
            trailing: TextButton(
              key: const ValueKey('edit_security_pin_button'),
              onPressed: _editPin,
              child:
                  Text(_pin == null ? 'Thiết lập mã PIN' : 'Cập nhật mã PIN'),
            ),
          ),
          const SizedBox(height: 12),
          _SecuritySettingTile(
            icon: Icons.smartphone_rounded,
            title: 'Thiết bị này đáng tin',
            description:
                'Xác minh nhanh hơn và giao dịch liền mạch hơn với thiết bị của bạn.',
            trailing: Switch(
              key: const ValueKey('trusted_device_switch'),
              value: _trustedDevice,
              activeTrackColor: _accountNavy,
              onChanged: (value) => setState(() => _trustedDevice = value),
            ),
          ),
          const SizedBox(height: 12),
          _SecuritySettingTile(
            icon: Icons.person_off_outlined,
            title: 'Xóa tài khoản',
            description:
                'Sau khi tài khoản bị xóa, bạn sẽ không thể truy xuất dữ liệu của mình. Hành động này không thể hoàn tác.',
            trailing: TextButton(
              key: const ValueKey('delete_account_button'),
              onPressed: _confirmAccountDeletion,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecuritySettingTile extends StatelessWidget {
  const _SecuritySettingTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: _accountBlueLight, size: 25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF202A33),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF858E96),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.currentPin});

  final String? currentPin;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String? _validatePin(String? value) {
    if (value == null || !RegExp(r'^\d{4,6}$').hasMatch(value)) {
      return 'Nhập mã PIN gồm 4 đến 6 chữ số';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_newPinController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.currentPin == null ? 'Thiết lập mã PIN' : 'Cập nhật mã PIN'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.currentPin != null)
                TextFormField(
                  key: const ValueKey('current_security_pin_field'),
                  controller: _currentPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Mã PIN hiện tại'),
                  validator: (value) {
                    if (value != widget.currentPin) {
                      return 'Mã PIN hiện tại không đúng';
                    }
                    return null;
                  },
                ),
              TextFormField(
                key: const ValueKey('new_security_pin_field'),
                controller: _newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mã PIN mới'),
                validator: _validatePin,
              ),
              TextFormField(
                key: const ValueKey('confirm_security_pin_field'),
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Xác nhận mã PIN'),
                validator: (value) {
                  if (value != _newPinController.text) {
                    return 'Mã PIN xác nhận không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('save_security_pin_button'),
          style: FilledButton.styleFrom(backgroundColor: _accountNavy),
          onPressed: _submit,
          child: const Text('Lưu mã PIN'),
        ),
      ],
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF4A535C),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.title,
    this.icon,
    this.trailingValue,
    this.showChevron = true,
    this.onTap,
  });

  final String title;
  final IconData? icon;
  final String? trailingValue;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E9ED))),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFF71808B), size: 24),
                const SizedBox(width: 18),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF505A64),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              if (trailingValue != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailingValue!,
                  style: const TextStyle(
                    color: Color(0xFF9299A0),
                    fontSize: 14,
                  ),
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _accountBlue,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _bookingUpdates = true;
  bool _promotions = true;
  bool _travelInspiration = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final enabled = await userService.getNotificationPref();
    if (!mounted) return;
    setState(() {
      _bookingUpdates = enabled;
      _promotions = enabled;
    });
  }

  void _saveNotificationPreference() {
    userService.saveNotificationPref(
      _bookingUpdates || _promotions || _travelInspiration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        backgroundColor: _accountBlue,
        foregroundColor: Colors.white,
        title: const Text('Cài đặt thông báo'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          SwitchListTile(
            value: _bookingUpdates,
            activeTrackColor: _accountBlue,
            title: const Text('Cập nhật đặt phòng'),
            subtitle: const Text('Thông báo trạng thái đặt chỗ và thanh toán'),
            onChanged: (value) {
              setState(() => _bookingUpdates = value);
              _saveNotificationPreference();
            },
          ),
          SwitchListTile(
            value: _promotions,
            activeTrackColor: _accountBlue,
            title: const Text('Ưu đãi và khuyến mãi'),
            subtitle: const Text('Nhận thông tin về ưu đãi mới'),
            onChanged: (value) {
              setState(() => _promotions = value);
              _saveNotificationPreference();
            },
          ),
          SwitchListTile(
            value: _travelInspiration,
            activeTrackColor: _accountBlue,
            title: const Text('Cảm hứng du lịch'),
            subtitle: const Text('Gợi ý điểm đến và nội dung du lịch'),
            onChanged: (value) {
              setState(() => _travelInspiration = value);
              _saveNotificationPreference();
            },
          ),
        ],
      ),
    );
  }
}

class EditAccountProfilePage extends StatefulWidget {
  const EditAccountProfilePage({super.key, required this.profile});

  final AccountProfileData profile;

  @override
  State<EditAccountProfilePage> createState() => _EditAccountProfilePageState();
}

class _EditAccountProfilePageState extends State<EditAccountProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _cityController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late String _dateOfBirth;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _fullNameController = TextEditingController(text: profile.fullName);
    _usernameController = TextEditingController(text: profile.username);
    _bioController = TextEditingController(text: profile.bio);
    _cityController = TextEditingController(text: profile.city);
    _emailController = TextEditingController(text: profile.email);
    _mobileController = TextEditingController(text: profile.mobile);
    _dateOfBirth = profile.dateOfBirth;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  String _displayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day} thg ${date.month} ${date.year}';
  }

  Future<void> _pickDate() async {
    final initialDate = DateTime.tryParse(_dateOfBirth) ?? DateTime(2000);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected != null) {
      setState(() {
        _dateOfBirth =
            '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      widget.profile.copyWith(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        dateOfBirth: _dateOfBirth,
        city: _cityController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
      ),
    );
  }

  InputDecoration _fieldDecoration({Widget? suffixIcon, String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      suffixIcon: suffixIcon,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8DDE3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8DDE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accountBlue, width: 1.5),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF697481),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      );

  Widget _sectionHeading(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF17202C),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (action != null)
            Text(
              action,
              style: const TextStyle(
                color: _accountBlue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        backgroundColor: _accountBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Thông tin tài khoản',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_accountBlue, _accountBlueLight],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            key: const ValueKey('profile_username_field'),
                            controller: _usernameController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              prefixText: '@',
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              color: _accountBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Vui lòng nhập tên người dùng'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('profile_bio_field'),
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 160,
                    decoration: _fieldDecoration().copyWith(
                      hintText: 'Hãy kể cho người khác về bản thân bạn.',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionHeading('Dữ liệu cá nhân', action: 'Chỉnh sửa'),
                  _fieldLabel('Họ tên'),
                  TextFormField(
                    key: const ValueKey('profile_name_field'),
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration(),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập họ tên'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Ngày sinh'),
                  InkWell(
                    key: const ValueKey('profile_birth_date_field'),
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _fieldDecoration(
                        suffixIcon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 20,
                        ),
                      ),
                      child: Text(_displayDate(_dateOfBirth)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Thành phố cư trú'),
                  TextFormField(
                    key: const ValueKey('profile_city_field'),
                    controller: _cityController,
                    decoration: _fieldDecoration(hintText: 'Chưa đặt'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeading('Email', action: 'Thêm'),
                  const Text(
                    'Email dùng để đăng nhập và nhận thông báo tài khoản.',
                    style: TextStyle(
                      color: Color(0xFF7D858D),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('profile_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDecoration(hintText: 'Email'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isNotEmpty &&
                          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                        return 'Vui lòng nhập email hợp lệ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeading('Số di động', action: 'Thêm'),
                  const Text(
                    'Số điện thoại có thể dùng để đăng nhập và nhận thông báo.',
                    style: TextStyle(
                      color: Color(0xFF7D858D),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('profile_mobile_field'),
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: _fieldDecoration(hintText: 'Số điện thoại'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          key: const ValueKey('save_profile_button'),
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: _accountBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Lưu thay đổi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onOpenProfile,
    required this.onEditProfile,
  });

  final AccountProfileData profile;
  final VoidCallback onOpenProfile;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: const Color(0x1A0E1F38),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      key: const ValueKey('account_profile_card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile.fullName.isEmpty
                        ? '?'
                        : profile.fullName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: _accountBlue,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF17202C),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Thành viên FomoGo',
                        style: TextStyle(
                          color: Color(0xFF727C89),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '0 bài viết',
                        style: TextStyle(
                          color: Color(0xFF727C89),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Chỉnh sửa hồ sơ',
                  onPressed: onEditProfile,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F7FC),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: _accountBlue,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpenProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: _accountBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Xem hồ sơ của tôi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSectionHeading extends StatelessWidget {
  const _AccountSectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF303B49),
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AccountOption {
  const _AccountOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _AccountOptionCard extends StatelessWidget {
  const _AccountOptionCard({required this.items});

  final List<_AccountOption> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x120E1F38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _AccountOptionTile(item: items[index]),
            if (index < items.length - 1)
              const Divider(height: 1, indent: 56, color: Color(0xFFE9EDF2)),
          ],
        ],
      ),
    );
  }
}

class _AccountOptionTile extends StatelessWidget {
  const _AccountOptionTile({required this.item});

  final _AccountOption item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: Icon(item.icon, color: const Color(0xFF687482), size: 25),
      title: Text(
        item.title,
        style: const TextStyle(
          color: Color(0xFF17202C),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          item.subtitle,
          style: const TextStyle(
            color: Color(0xFF79828D),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: _accountBlue,
        size: 26,
      ),
    );
  }
}

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final List<SavedPaymentCard> _cards = [];

  Future<void> _addCard() async {
    final card = await Navigator.of(context).push<SavedPaymentCard>(
      MaterialPageRoute<SavedPaymentCard>(
        builder: (_) => const AddPaymentCardPage(),
      ),
    );
    if (card != null && mounted) {
      setState(() => _cards.add(card));
    }
  }

  void _showCardInfo() {
    showDialog<void>(
      context: context,
      animationStyle: AppMotion.dialogAnimationStyle,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.security_rounded, color: _accountBlue),
        title: const Text('Thanh toán an toàn'),
        content: const Text(
          'Thông tin thẻ được bảo vệ khi thanh toán. Bản giao diện này chỉ lưu nhãn thẻ và 4 số cuối để minh họa; không lưu số thẻ đầy đủ hoặc mã bảo mật.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _accountBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Thẻ của tôi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Thông tin thanh toán',
            onPressed: _showCardInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: _cards.isEmpty
          ? _EmptyPaymentMethods(onAddCard: _addCard)
          : _PaymentCardList(
              cards: _cards,
              onAddCard: _addCard,
              onRemoveCard: (card) => setState(() => _cards.remove(card)),
            ),
    );
  }
}

class _EmptyPaymentMethods extends StatelessWidget {
  const _EmptyPaymentMethods({required this.onAddCard});

  final VoidCallback onAddCard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      children: [
        const SizedBox(
          height: 230,
          child: _PaymentIllustration(),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tận hưởng thanh toán liền mạch với thẻ đã lưu',
                style: TextStyle(
                  color: Color(0xFF30343A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Lưu đến 10 thẻ tín dụng/thẻ ghi nợ để thanh toán thuận tiện. Thông tin thanh toán được bảo vệ; bản xem trước này chỉ lưu nhãn thẻ và 4 số cuối.',
                style: TextStyle(
                  color: Color(0xFF60666D),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton(
            key: const ValueKey('add_payment_card_button'),
            onPressed: onAddCard,
            style: FilledButton.styleFrom(
              backgroundColor: _accountBlue,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Thêm thẻ tín dụng/thẻ ghi nợ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentIllustration extends StatelessWidget {
  const _PaymentIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 14,
          child: Container(
            width: 220,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FC),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          left: 30,
          top: 38,
          child: Icon(
            Icons.add,
            size: 24,
            color: Colors.lightGreen.shade600,
          ),
        ),
        Positioned(
          right: 34,
          top: 46,
          child: Icon(
            Icons.auto_awesome,
            size: 25,
            color: Colors.lightGreen.shade600,
          ),
        ),
        Positioned(
          right: 30,
          top: 72,
          child: Transform.rotate(
            angle: -0.28,
            child: Container(
              width: 130,
              height: 82,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accountBlueLight, _accountNavy],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330E1F38),
                    blurRadius: 12,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Icon(
                      Icons.nfc_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Text(
                      '••••  ••••  ••••',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 70,
          bottom: 13,
          child: Container(
            width: 112,
            height: 186,
            decoration: BoxDecoration(
              color: const Color(0xFFF36A36),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(56),
                bottom: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Column(
              children: [
                SizedBox(height: 18),
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFFFD4B8),
                  child: Icon(
                    Icons.person_rounded,
                    size: 54,
                    color: Color(0xFF8D4A34),
                  ),
                ),
                SizedBox(height: 8),
                Icon(
                  Icons.phone_iphone_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SavedPaymentCard {
  const SavedPaymentCard({
    required this.holder,
    required this.lastFour,
    required this.cardType,
    required this.expiry,
  });

  final String holder;
  final String lastFour;
  final String cardType;
  final String expiry;
}

class _PaymentCardList extends StatelessWidget {
  const _PaymentCardList({
    required this.cards,
    required this.onAddCard,
    required this.onRemoveCard,
  });

  final List<SavedPaymentCard> cards;
  final VoidCallback onAddCard;
  final ValueChanged<SavedPaymentCard> onRemoveCard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Phương thức thanh toán',
          style: TextStyle(
            color: _accountNavy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        for (final card in cards)
          Card(
            color: const Color(0xFFF4F8FE),
            child: ListTile(
              leading: const Icon(
                Icons.credit_card_rounded,
                color: _accountBlue,
                size: 30,
              ),
              title: Text('${card.cardType} •••• ${card.lastFour}'),
              subtitle: Text('${card.holder} · Hết hạn ${card.expiry}'),
              trailing: IconButton(
                tooltip: 'Xóa thẻ',
                onPressed: () => onRemoveCard(card),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('add_another_payment_card_button'),
          onPressed: onAddCard,
          icon: const Icon(Icons.add_card_rounded),
          label: const Text('Thêm thẻ khác'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Chỉ hiển thị 4 số cuối của thẻ trong giao diện.',
          style: TextStyle(color: Color(0xFF737D89), fontSize: 12),
        ),
      ],
    );
  }
}

class AddPaymentCardPage extends StatefulWidget {
  const AddPaymentCardPage({super.key});

  @override
  State<AddPaymentCardPage> createState() => _AddPaymentCardPageState();
}

class _AddPaymentCardPageState extends State<AddPaymentCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _securityCodeController = TextEditingController();
  final _holderController = TextEditingController();
  bool _obscureSecurityCode = true;

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _securityCodeController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  String _detectCardType(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5') || number.startsWith('2')) return 'Mastercard';
    if (number.startsWith('34') || number.startsWith('37')) {
      return 'American Express';
    }
    if (number.startsWith('35')) return 'JCB';
    return 'Thẻ ngân hàng';
  }

  bool _passesLuhn(String number) {
    var sum = 0;
    var doubleDigit = false;
    for (var index = number.length - 1; index >= 0; index--) {
      var digit = int.parse(number[index]);
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleDigit = !doubleDigit;
    }
    return sum % 10 == 0;
  }

  String? _validateExpiry(String? value) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value ?? '');
    if (match == null) return 'Nhập ngày hết hạn dạng MM/YY';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return 'Tháng hết hạn không hợp lệ';
    final expiryEnd = DateTime(year, month + 1);
    if (!expiryEnd.isAfter(DateTime.now())) {
      return 'Thẻ đã hết hạn';
    }
    return null;
  }

  void _saveCard() {
    if (!_formKey.currentState!.validate()) return;
    final cardNumber = _numberController.text.replaceAll(RegExp(r'\D'), '');
    final expiry = _expiryController.text.trim();
    Navigator.of(context).pop(
      SavedPaymentCard(
        holder: _holderController.text.trim(),
        lastFour: cardNumber.substring(cardNumber.length - 4),
        cardType: _detectCardType(cardNumber),
        expiry: expiry,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3D8DE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3D8DE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accountBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _accountBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Thêm thẻ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: _accountBlue,
                  size: 20,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Thanh toán an toàn',
                    style: TextStyle(
                      color: Color(0xFF606A76),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                for (final brand in ['MC', 'VISA', 'AMEX', 'JCB'])
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      brand,
                      style: TextStyle(
                        color: brand == 'AMEX'
                            ? const Color(0xFF1477B8)
                            : brand == 'MC'
                                ? const Color(0xFFCC3C3C)
                                : const Color(0xFF183E8A),
                        fontSize: brand == 'VISA' ? 13 : 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE6E9ED)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0E1F38),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextFormField(
                    key: const ValueKey('payment_card_number_field'),
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration(
                      'Số thẻ',
                    ).copyWith(counterText: ''),
                    validator: (value) {
                      final number =
                          (value ?? '').replaceAll(RegExp(r'\D'), '');
                      if (number.length != 16 ||
                          !_passesLuhn(number)) {
                        return 'Số thẻ phải đủ 16 chữ số';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('payment_card_expiry_field'),
                          controller: _expiryController,
                          keyboardType: TextInputType.datetime,
                          maxLength: 5,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d/]'),
                            ),
                          ],
                          decoration: _fieldDecoration(
                            'MM/YY',
                          ).copyWith(counterText: ''),
                          validator: _validateExpiry,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('payment_card_cvv_field'),
                          controller: _securityCodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: _obscureSecurityCode,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _fieldDecoration(
                            'Mã 3–4 số',
                            suffixIcon: IconButton(
                              tooltip: _obscureSecurityCode
                                  ? 'Hiện mã bảo mật'
                                  : 'Ẩn mã bảo mật',
                              onPressed: () => setState(
                                () => _obscureSecurityCode =
                                    !_obscureSecurityCode,
                              ),
                              icon: Icon(
                                _obscureSecurityCode
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 19,
                              ),
                            ),
                          ).copyWith(counterText: ''),
                          validator: (value) => value == null ||
                                  !RegExp(r'^\d{3,4}$').hasMatch(value)
                              ? 'Nhập mã bảo mật 3–4 số'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('payment_card_holder_field'),
                    controller: _holderController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration('Tên ghi trên thẻ'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập tên ghi trên thẻ'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text.rich(
              TextSpan(
                style: TextStyle(
                  color: Color(0xFF747D86),
                  fontSize: 12,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text:
                        'Khi thêm thẻ, bạn đồng ý với Điều khoản và Chính sách quyền riêng tư của FomoGo.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('confirm_add_payment_card_button'),
                onPressed: _saveCard,
                style: FilledButton.styleFrom(
                  backgroundColor: _accountBlue,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Thêm thẻ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Số thẻ và mã bảo mật chỉ dùng để kiểm tra biểu mẫu; ứng dụng không lưu các thông tin này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8A929A),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RefundPage extends StatefulWidget {
  const RefundPage({super.key});

  @override
  State<RefundPage> createState() => _RefundPageState();
}

class _RefundPageState extends State<RefundPage> {
  final List<_RefundBankAccount> _bankAccounts = [];
  static const int _refundBalance = 0;

  Future<void> _addBankAccount() async {
    final account = await showModalBottomSheet<_RefundBankAccount>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetAnimationStyle,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddRefundBankAccountSheet(),
    );
    if (account != null && mounted) {
      setState(() => _bankAccounts.add(account));
    }
  }

  void _showHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _RefundHistoryPage(),
      ),
    );
  }

  void _showRefundInfo() {
    showDialog<void>(
      context: context,
      animationStyle: AppMotion.dialogAnimationStyle,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.account_balance_wallet_outlined,
            color: _accountBlue),
        title: const Text('Số dư hoàn tiền'),
        content: const Text(
          'Một số khoản hoàn tiền có thể được chuyển thành số dư để sử dụng cho đặt phòng tiếp theo. Số dư thực tế sẽ được cập nhật khi kết nối dữ liệu tài khoản.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Số dư hoàn tiền hiện chưa đủ để rút.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _accountBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Số dư hoàn tiền & trạng thái hoàn tiền',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Thông tin số dư hoàn tiền',
            onPressed: _showRefundInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_accountNavy, _accountBlueLight],
            stops: [0.0, 0.66],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _RefundBalanceCard(
              balance: _refundBalance,
              onViewHistory: _showHistory,
              onWithdraw: _showWithdrawNotice,
            ),
            const SizedBox(height: 14),
            _BankAccountsCard(
              accounts: _bankAccounts,
              onAddAccount: _addBankAccount,
              onRemoveAccount: (account) =>
                  setState(() => _bankAccounts.remove(account)),
            ),
            const SizedBox(height: 20),
            const _RefundBookingCard(),
            const SizedBox(height: 12),
            const _RefundEmptyIllustration(),
          ],
        ),
      ),
    );
  }
}

class _RefundBalanceCard extends StatelessWidget {
  const _RefundBalanceCard({
    required this.balance,
    required this.onViewHistory,
    required this.onWithdraw,
  });

  final int balance;
  final VoidCallback onViewHistory;
  final VoidCallback onWithdraw;

  String get _formattedBalance {
    final digits = balance.toString();
    final groups = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      final start = end - 3 < 0 ? 0 : end - 3;
      groups.insert(0, digits.substring(start, end));
    }
    return groups.join('.');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180E1F38),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: const Color(0xFFF4FAFF),
            child: InkWell(
              key: const ValueKey('refund_balance_info_button'),
              onTap: () => showDialog<void>(
                context: context,
                animationStyle: AppMotion.dialogAnimationStyle,
                builder: (context) => AlertDialog(
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _accountBlue,
                  ),
                  title: const Text('Số dư hoàn tiền'),
                  content: const Text(
                    'Khoản hoàn tiền đủ điều kiện có thể được cộng vào số dư và dùng cho đặt phòng tiếp theo.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đã hiểu'),
                    ),
                  ],
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _accountBlue,
                      size: 25,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đôi khi, khoản hoàn tiền sẽ được chuyển thành Số dư Hoàn tiền để dùng cho các đặt chỗ sau.',
                        style: TextStyle(
                          color: Color(0xFF46515D),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _accountBlue, size: 23),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư hoàn tiền',
                  style: TextStyle(
                    color: Color(0xFF303943),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '$_formattedBalance VND',
                      style: const TextStyle(
                        color: Color(0xFF20252B),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      key: const ValueKey('refund_history_button'),
                      onPressed: onViewHistory,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFD9F2FF),
                        foregroundColor: const Color(0xFF075F9D),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Xem lịch sử',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9EDF2)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 48,
              child: FilledButton(
                key: const ValueKey('withdraw_refund_button'),
                onPressed: balance > 0 ? onWithdraw : null,
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: const Color(0xFFF0F1F3),
                  disabledForegroundColor: const Color(0xFF9AA0A6),
                  backgroundColor: _accountBlue,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Số dư rút tiền',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundBankAccount {
  const _RefundBankAccount({
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
  });

  final String bankName;
  final String accountHolder;
  final String accountNumber;
}

class _BankAccountsCard extends StatelessWidget {
  const _BankAccountsCard({
    required this.accounts,
    required this.onAddAccount,
    required this.onRemoveAccount,
  });

  final List<_RefundBankAccount> accounts;
  final VoidCallback onAddAccount;
  final ValueChanged<_RefundBankAccount> onRemoveAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160E1F38),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  accounts.isEmpty
                      ? 'Thêm tài khoản ngân hàng để nhận hoàn tiền và rút tiền nhanh chóng.'
                      : 'Tài khoản nhận tiền hoàn',
                  style: const TextStyle(
                    color: Color(0xFF48535F),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                key: const ValueKey('add_refund_bank_account_button'),
                onPressed: onAddAccount,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFD9F2FF),
                  foregroundColor: const Color(0xFF075F9D),
                  minimumSize: const Size(92, 42),
                  shape: const StadiumBorder(),
                ),
                child: Text(accounts.isEmpty ? 'Thêm' : 'Thêm khác'),
              ),
            ],
          ),
          for (final account in accounts) ...[
            const Divider(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F4FF),
                child: Icon(Icons.account_balance_rounded, color: _accountBlue),
              ),
              title: Text(account.bankName),
              subtitle: Text(
                '${account.accountHolder} · •••• ${account.accountNumber.substring(account.accountNumber.length - 4)}',
              ),
              trailing: IconButton(
                tooltip: 'Xóa tài khoản ngân hàng',
                onPressed: () => onRemoveAccount(account),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddRefundBankAccountSheet extends StatefulWidget {
  const _AddRefundBankAccountSheet();

  @override
  State<_AddRefundBankAccountSheet> createState() =>
      _AddRefundBankAccountSheetState();
}

class _AddRefundBankAccountSheetState
    extends State<_AddRefundBankAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  String _bankName = 'Vietcombank';

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _RefundBankAccount(
        bankName: _bankName,
        accountHolder: _holderController.text.trim(),
        accountNumber: _numberController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DDE3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Thêm tài khoản ngân hàng',
                  style: TextStyle(
                    color: _accountNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _bankName,
                  decoration: const InputDecoration(
                    labelText: 'Ngân hàng',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    'Vietcombank',
                    'Techcombank',
                    'BIDV',
                    'VietinBank',
                    'MB Bank',
                    'ACB',
                  ]
                      .map(
                        (bank) => DropdownMenuItem(
                          value: bank,
                          child: Text(bank),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _bankName = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('refund_bank_account_holder_field'),
                  controller: _holderController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Tên chủ tài khoản',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên chủ tài khoản'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('refund_bank_account_number_field'),
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tài khoản',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || !RegExp(r'^\d{6,20}$').hasMatch(value)
                          ? 'Vui lòng nhập số tài khoản hợp lệ'
                          : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('save_refund_bank_account_button'),
                    onPressed: _saveAccount,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accountBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Lưu tài khoản'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RefundHistoryPage extends StatelessWidget {
  const _RefundHistoryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        backgroundColor: _accountBlue,
        foregroundColor: Colors.white,
        title: const Text('Lịch sử hoàn tiền'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: _accountBlue,
                size: 54,
              ),
              SizedBox(height: 14),
              Text(
                'Chưa có giao dịch hoàn tiền',
                style: TextStyle(
                  color: _accountNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Các cập nhật hoàn tiền sẽ xuất hiện tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF707B87), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefundBookingCard extends StatelessWidget {
  const _RefundBookingCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const ValueKey('refund_booking_card'),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tính năng đặt chỗ bằng số dư sẽ sớm khả dụng.'),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE5F4FF),
                child: Icon(Icons.hotel_rounded, color: _accountBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đặt chỗ ngay với Số dư Hoàn tiền',
                      style: TextStyle(
                        color: Color(0xFF26313D),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Khám phá khách sạn và dùng số dư để thanh toán đặt phòng.',
                      style: TextStyle(
                        color: Color(0xFF65707C),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _accountBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefundEmptyIllustration extends StatelessWidget {
  const _RefundEmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 250,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FF),
              borderRadius: BorderRadius.circular(120),
            ),
          ),
          Positioned(
            bottom: 22,
            child: Container(
              width: 190,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF8ED8F7),
                borderRadius: BorderRadius.circular(42),
              ),
            ),
          ),
          const Positioned(
            bottom: 54,
            child: Icon(
              Icons.hotel_rounded,
              color: Colors.white,
              size: 92,
            ),
          ),
          Positioned(
            top: 18,
            child: Icon(
              Icons.savings_rounded,
              color: Colors.orange.shade700,
              size: 68,
            ),
          ),
          Positioned(
            top: 50,
            right: 90,
            child: Icon(
              Icons.nightlight_round,
              color: Colors.orange.shade800,
              size: 23,
            ),
          ),
          Positioned(
            top: 35,
            left: 95,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.lightGreen.shade600,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _accountNavy,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: _accountBlue, size: 28),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: _accountNavy,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF687482),
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
