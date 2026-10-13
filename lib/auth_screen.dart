import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/api_repository.dart';
import 'onboarding_widgets.dart';
import 'user_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isSubmitting = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _fullNameController.dispose();
    _registerEmailController.dispose();
    _phoneController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setMode(bool loginMode) {
    if (_isLoginMode == loginMode || _isSubmitting) return;
    setState(() => _isLoginMode = loginMode);
  }

  Future<void> _submit() async {
    final form = _isLoginMode ? _loginFormKey : _registerFormKey;
    if (!(form.currentState?.validate() ?? false) || _isSubmitting) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      if (_isLoginMode) {
        await _login();
      } else {
        await _register();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(_messageForApiError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _login() async {
    final email = _loginEmailController.text.trim();
    final user =
        await apiRepository.login(email, _loginPasswordController.text);
    await userService.saveContactInfo(
      email: email,
      mobile: user.phone,
    );
    await userService.saveUserInfo(
      name: user.fullName,
      birthDate: '',
      gender: '',
    );
    await userService.saveOnboardingCompleted(true);
    if (!mounted) return;
    _showMessage('Đăng nhập thành công.');
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: widget.homeBuilder),
      (route) => false,
    );
  }

  Future<void> _register() async {
    final email = _registerEmailController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _registerPasswordController.text;
    final confirmation = _confirmPasswordController.text;
    if (password != confirmation) {
      throw const ApiException(400, 'Mật khẩu xác nhận không trùng khớp.');
    }

    await apiRepository.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    // The register endpoint intentionally does not issue a JWT. Log in with
    // the newly-created credentials so registration results in an active
    // session instead of leaving the user on the auth screen.
    final user = await apiRepository.login(email, password);
    await userService.saveContactInfo(
      email: user.email.isNotEmpty ? user.email : email,
      mobile: user.phone.isNotEmpty ? user.phone : phone,
    );
    await userService.saveUserInfo(
      name: user.fullName.isNotEmpty ? user.fullName : fullName,
      birthDate: '',
      gender: '',
    );
    await userService.saveOnboardingCompleted(true);

    if (!mounted) return;
    _showMessage('Đăng ký thành công. Chào mừng bạn đến với FomoGo.');
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: widget.homeBuilder),
      (route) => false,
    );
  }

  String _messageForApiError(ApiException error) {
    if (!_isLoginMode && error.statusCode == 409) {
      return 'Email hoặc Số điện thoại đã được đăng ký. Vui lòng đổi tài khoản khác hoặc Đăng nhập.';
    }
    if (_isLoginMode && (error.statusCode == 401 || error.statusCode == 404)) {
      return 'Email hoặc mật khẩu không chính xác.';
    }
    return error.message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập $label.';
    return null;
  }

  String? _password(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
    return null;
  }

  String? _email(String? value) {
    final requiredError = _required(value, 'email');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
      return 'Email không hợp lệ.';
    }
    return null;
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
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      title: _isLoginMode ? 'Đăng nhập' : 'Đăng ký',
      subtitle: _isLoginMode
          ? 'Đăng nhập để tiếp tục khám phá và đặt phòng cùng FomoGo.'
          : 'Tạo tài khoản để bắt đầu hành trình cùng FomoGo.',
      footer: _buildSubmitButton(),
      children: [
        _buildModeToggle(),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isLoginMode ? _buildLoginForm() : _buildRegisterForm(),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _modeButton(label: 'Đăng nhập', loginMode: true),
          _modeButton(label: 'Đăng ký', loginMode: false),
        ],
      ),
    );
  }

  Widget _modeButton({required String label, required bool loginMode}) {
    final selected = _isLoginMode == loginMode;
    return Expanded(
      child: InkWell(
        onTap: () => _setMode(loginMode),
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x140E1F38),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  selected ? const Color(0xFF0E1F38) : const Color(0xFF78838E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login_form'),
        children: [
          OnboardingTextField(
            fieldKey: const ValueKey('auth_email_field'),
            controller: _loginEmailController,
            label: 'Email',
            hint: 'Nhập email của bạn',
            keyboardType: TextInputType.emailAddress,
            validator: _email,
          ),
          const SizedBox(height: 12),
          _passwordField(
            fieldKey: const ValueKey('auth_password_field'),
            controller: _loginPasswordController,
            label: 'Mật khẩu',
            obscureText: _obscureLoginPassword,
            onToggle: () => setState(
              () => _obscureLoginPassword = !_obscureLoginPassword,
            ),
            validator: _password,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showMessage(
                'Vui lòng liên hệ hỗ trợ để khôi phục mật khẩu.',
              ),
              child: const Text('Quên mật khẩu?'),
            ),
          ),
          TextButton(
            key: const ValueKey('auth_register_shortcut'),
            onPressed: _isSubmitting ? null : () => _setMode(false),
            child: const Text('Chưa có tài khoản? Đăng ký ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register_form'),
        children: [
          OnboardingTextField(
            fieldKey: const ValueKey('auth_full_name_field'),
            controller: _fullNameController,
            label: 'Họ và tên',
            hint: 'Nhập họ và tên',
            textCapitalization: TextCapitalization.words,
            validator: (value) => _required(value, 'họ và tên'),
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            fieldKey: const ValueKey('auth_register_email_field'),
            controller: _registerEmailController,
            label: 'Email',
            hint: 'Nhập email của bạn',
            keyboardType: TextInputType.emailAddress,
            validator: _email,
          ),
          const SizedBox(height: 12),
          OnboardingTextField(
            fieldKey: const ValueKey('auth_phone_field'),
            controller: _phoneController,
            label: 'Số điện thoại',
            hint: 'Nhập số điện thoại của bạn',
            keyboardType: TextInputType.phone,
            validator: (value) => _required(value, 'số điện thoại'),
          ),
          const SizedBox(height: 12),
          _passwordField(
            fieldKey: const ValueKey('auth_register_password_field'),
            controller: _registerPasswordController,
            label: 'Mật khẩu',
            obscureText: _obscureRegisterPassword,
            onToggle: () => setState(
              () => _obscureRegisterPassword = !_obscureRegisterPassword,
            ),
            validator: _password,
          ),
          const SizedBox(height: 12),
          _passwordField(
            fieldKey: const ValueKey('auth_confirm_password_field'),
            controller: _confirmPasswordController,
            label: 'Nhập lại mật khẩu',
            obscureText: _obscureConfirmPassword,
            onToggle: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            validator: (value) {
              final passwordError = _password(value);
              if (passwordError != null) return passwordError;
              if (value != _registerPasswordController.text) {
                return 'Mật khẩu xác nhận không trùng khớp.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Tối thiểu 8 ký tự',
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: onboardingBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return OnboardingPrimaryButton(
      key: const ValueKey('auth_continue_button'),
      label: _isLoginMode ? 'Đăng nhập' : 'Tạo tài khoản',
      enabled: !_isSubmitting,
      onPressed: _submit,
    );
  }
}
