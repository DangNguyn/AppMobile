import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const onboardingNavy = Color(0xFF0E1F38);
const onboardingBlue = Color(0xFF2A6EEB);
const onboardingPaleBlue = Color(0xFFE8F1FF);

class OnboardingBanner extends StatelessWidget {
  const OnboardingBanner({
    super.key,
    required this.height,
    this.imageUrl =
        'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=85',
    this.child,
  });

  final double height;
  final String imageUrl;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('onboarding_banner'),
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF159CEB), onboardingNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white70,
                  size: 96,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC0E1F38)],
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: onboardingBlue,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF9AA2AA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class OnboardingTextField extends StatelessWidget {
  const OnboardingTextField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
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
}

class OnboardingPageShell extends StatelessWidget {
  const OnboardingPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.banner,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? banner;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (banner != null) banner!,
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: onboardingNavy,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF687482),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...children,
                  ],
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
