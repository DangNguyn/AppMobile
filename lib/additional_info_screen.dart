import 'package:flutter/material.dart';

import 'onboarding_widgets.dart';
import 'user_service.dart';

class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _gender;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: onboardingNavy,
              ),
        ),
        child: child!,
      ),
    );
    if (selectedDate == null) return;
    setState(() {
      _birthDateController.text =
          '${selectedDate.day.toString().padLeft(2, '0')}/'
          '${selectedDate.month.toString().padLeft(2, '0')}/'
          '${selectedDate.year}';
    });
  }

  Future<void> _finish({required bool saveInfo}) async {
    if (_isSaving) return;
    if (saveInfo && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    if (saveInfo) {
      await userService.saveUserInfo(
        name: _nameController.text,
        birthDate: _birthDateController.text,
        gender: _gender ?? '',
      );
    }
    await userService.saveOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: widget.homeBuilder),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPageShell(
      banner: OnboardingBanner(
        height: onboardingBannerHeight(context),
        child: Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
      ),
      title: 'Thông tin bổ sung',
      subtitle:
          'Hoàn thiện hồ sơ để việc đặt chỗ và trải nghiệm của bạn thuận tiện hơn.',
      footer: Column(
        children: [
          OnboardingPrimaryButton(
            key: const ValueKey('additional_save_button'),
            label: 'Lưu',
            enabled: !_isSaving,
            onPressed: () => _finish(saveInfo: true),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('additional_skip_button'),
            onPressed: _isSaving ? null : () => _finish(saveInfo: false),
            style: TextButton.styleFrom(
              foregroundColor: onboardingBlue,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Bỏ qua bước này'),
          ),
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingTextField(
                fieldKey: const ValueKey('additional_name_field'),
                controller: _nameController,
                label: 'Tên cá nhân',
                hint: 'Nhập tên của bạn',
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên cá nhân';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              OnboardingTextField(
                fieldKey: const ValueKey('additional_birth_date_field'),
                controller: _birthDateController,
                label: 'Ngày sinh',
                hint: 'Chọn ngày sinh của bạn',
                readOnly: true,
                onTap: _selectBirthDate,
              ),
              const SizedBox(height: 20),
              const Text(
                'Giới tính',
                style: TextStyle(
                  color: onboardingNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              RadioGroup<String>(
                groupValue: _gender,
                onChanged: (value) => setState(() => _gender = value),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        key: const ValueKey('additional_gender_male'),
                        contentPadding: EdgeInsets.zero,
                        activeColor: onboardingBlue,
                        title: const Text('Nam'),
                        value: 'Nam',
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        key: const ValueKey('additional_gender_female'),
                        contentPadding: EdgeInsets.zero,
                        activeColor: onboardingBlue,
                        title: const Text('Nữ'),
                        value: 'Nữ',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
