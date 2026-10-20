import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_screen.dart';
import 'onboarding_widgets.dart';
import 'ui_motion.dart';
import 'user_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  Future<void> _chooseNotifications(
    BuildContext context,
    bool enabled,
  ) async {
    await userService.saveNotificationPref(enabled);
    if (!context.mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) =>
            AuthScreen(homeBuilder: homeBuilder),
        transitionDuration: AppMotion.pageDuration,
        reverseTransitionDuration: AppMotion.pageDuration,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(22, 8, 22, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnboardingPrimaryButton(
              key: const ValueKey('enable_notifications_button'),
              label: 'Có, Cập nhật cho tôi',
              onPressed: () => _chooseNotifications(context, true),
            ),
            SizedBox(
              height: 38,
              child: TextButton(
                key: const ValueKey('skip_notifications_button'),
                onPressed: () => _chooseNotifications(context, false),
                style: TextButton.styleFrom(foregroundColor: onboardingNavy),
                child: const Text('Để sau'),
              ),
            ),
          ],
        ),
      ),
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
              OnboardingBanner(
                height: (screenHeight * 0.33).clamp(220.0, 330.0),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 38, left: 12),
                    child: BackButton(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Thông báo ứng dụng sẽ thông báo cho bạn về các cập nhật...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onboardingNavy,
                          fontSize: 22,
                          height: 1.16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bật thông báo để không bỏ lỡ những thông tin quan trọng cho chuyến đi của bạn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF687482),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _NotificationBenefit(
                        key: ValueKey('notification_benefit_booking'),
                        icon: Icons.mark_email_unread_rounded,
                        title: 'Cập nhật đặt chỗ',
                        description:
                            'Nhận thông tin về trạng thái đặt phòng của bạn.',
                      ),
                      const SizedBox(height: 10),
                      const _NotificationBenefit(
                        key: ValueKey('notification_benefit_updates'),
                        icon: Icons.support_agent_rounded,
                        title: 'Cập nhật trong thời gian thực',
                        description:
                            'Luôn nắm được thay đổi liên quan đến chuyến đi.',
                      ),
                      const SizedBox(height: 10),
                      const _NotificationBenefit(
                        key: ValueKey('notification_benefit_offers'),
                        icon: Icons.local_offer_rounded,
                        title: 'Ưu đãi dành riêng cho bạn',
                        description: 'Khám phá khuyến mãi và gợi ý phù hợp.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBenefit extends StatelessWidget {
  const _NotificationBenefit({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEDF0F4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: onboardingPaleBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: onboardingBlue, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: onboardingNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF78838E),
                    fontSize: 12,
                    height: 1.2,
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
