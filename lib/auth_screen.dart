import 'package:flutter/material.dart';

import 'additional_info_screen.dart';
import 'onboarding_widgets.dart';
import 'user_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    if (email.isEmpty || mobile.isEmpty) return;
    await userService.saveContactInfo(email: email, mobile: mobile);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdditionalInfoScreen(homeBuilder: widget.homeBuilder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPageShell(
      banner: OnboardingBanner(
        height: MediaQuery.sizeOf(context).height * 0.3,
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 8,
            ),
            child: IconButton(
              key: const ValueKey('auth_close_button'),
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      title: 'Đăng nhập / Đăng ký',
      subtitle:
          'Nhập email và số điện thoại để tiếp tục khám phá cùng FomoGo.',
      footer: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _emailController,
          builder: (context, emailValue, _) => ValueListenableBuilder<TextEditingValue>(
            valueListenable: _mobileController,
            builder: (context, mobileValue, _) => OnboardingPrimaryButton(
            key: const ValueKey('auth_continue_button'),
            label: 'Tiếp tục',
            enabled: emailValue.text.trim().isNotEmpty &&
                mobileValue.text.trim().isNotEmpty,
            onPressed: _continue,
            ),
          ),
      ),
      children: [
          OnboardingTextField(
            fieldKey: const ValueKey('auth_email_field'),
            controller: _emailController,
            label: 'Email',
            hint: 'Nhập email của bạn',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 9),
          OnboardingTextField(
            fieldKey: const ValueKey('auth_mobile_field'),
            controller: _mobileController,
            label: 'Số điện thoại di động',
            hint: 'Nhập số điện thoại của bạn',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 9),
          const Text(
            'Ví dụ: yourname@email.com và +84901234567',
          style: TextStyle(color: Color(0xFF78838E), fontSize: 13),
        ),
      ],
    );
  }
}
