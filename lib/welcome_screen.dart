import 'package:flutter/material.dart';
import 'notification_screen.dart';
import 'onboarding_widgets.dart';
import 'user_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _currency = 'VND';
  String _language = 'Tiếng Việt';

  Future<void> _continue() async {
    await userService.saveCurrency(_currency);
    await userService.saveLanguage(_language);
    if (!mounted) return;

    Navigator.of(context).push(
      onboardingPageRoute<void>(
        builder: (_) => NotificationScreen(homeBuilder: widget.homeBuilder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPageShell(
      banner: OnboardingBanner(
        height: onboardingBannerHeight(context),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Image.asset(
              'assets/images/fomogo_logo.png',
              width: 145,
              height: 64,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      title: 'Chào mừng bạn đến với FomoGo',
      subtitle: 'Khám phá và đặt phòng cho những chuyến đi đáng nhớ.',
      footer: OnboardingPrimaryButton(
        key: const ValueKey('welcome_continue_button'),
        label: 'Tiếp tục',
        onPressed: _continue,
      ),
      children: [
        _PreferenceDropdown<String>(
          key: const ValueKey('onboarding_currency_dropdown'),
          label: 'Tiền tệ ưa thích',
          value: _currency,
          options: const {
            'VND': 'VND - Vietnamese Dong (VND)',
            'USD': 'USD - Đô la Mỹ (USD)',
            'EUR': 'EUR - Euro (EUR)',
          },
          onChanged: (value) => setState(() => _currency = value),
        ),
        const SizedBox(height: 22),
        _PreferenceDropdown<String>(
          key: const ValueKey('onboarding_language_dropdown'),
          label: 'Ngôn ngữ ưu tiên',
          value: _language,
          options: const {
            'Tiếng Việt': 'Tiếng Việt',
            'English': 'English',
          },
          onChanged: (value) => setState(() => _language = value),
        ),
      ],
    );
  }
}

class _PreferenceDropdown<T> extends StatelessWidget {
  const _PreferenceDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: onboardingNavy,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F9FC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueGrey.shade100),
            ),
          ),
          items: options.entries
              .map(
                (entry) => DropdownMenuItem<T>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ],
    );
  }
}
