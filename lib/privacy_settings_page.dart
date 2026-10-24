import 'package:flutter/material.dart';

import 'user_service.dart';

const _privacyNavy = Color(0xFF0E1F38);

/// Shared privacy controls opened from both account settings and the profile.
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _privateProfile = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final privateProfile = await userService.getPrivateProfilePref();
    if (!mounted) return;
    setState(() {
      _privateProfile = privateProfile;
      _isLoaded = true;
    });
  }

  Future<void> _setPrivateProfile(bool value) async {
    setState(() => _privateProfile = value);
    await userService.savePrivateProfilePref(value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          backgroundColor: _privacyNavy,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'Quyền riêng tư',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: _isLoaded
            ? ListView(
                children: [
                  _PrivacySettingTile(
                    key: const ValueKey('private_profile_switch'),
                    switchKey: const ValueKey('private_profile_toggle'),
                    title: 'Đặt hồ sơ thành riêng tư',
                    description:
                        'Khi bật chế độ này, người khác sẽ không thể xem hồ sơ và bài viết của bạn.',
                    value: _privateProfile,
                    onChanged: _setPrivateProfile,
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      );
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
  Widget build(BuildContext context) => Material(
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
                activeTrackColor: _privacyNavy,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      );
}
