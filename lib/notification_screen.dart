import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'onboarding_widgets.dart';
import 'user_service.dart';
import 'notification_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  Future<void> _chooseNotifications(
    BuildContext context,
    bool enabled,
  ) async {
    await userService.saveNotificationPref(enabled);
    if (enabled) {
      await AppNotificationService.instance.requestPermission();
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      onboardingPageRoute<void>(
        builder: (_) => AuthScreen(homeBuilder: homeBuilder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPageShell(
      banner: OnboardingBanner(
        height: onboardingBannerHeight(context),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 8,
            ),
            child: const BackButton(color: Colors.white),
          ),
        ),
      ),
      title: 'Bật thông báo cho chuyến đi của bạn',
      subtitle:
          'Bật thông báo để không bỏ lỡ những thông tin quan trọng cho chuyến đi.',
      footer: Column(
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
      children: const [
        _NotificationBenefit(
          key: ValueKey('notification_benefit_booking'),
          icon: Icons.mark_email_unread_rounded,
          title: 'Cập nhật đặt chỗ',
          description: 'Nhận thông tin về trạng thái đặt phòng của bạn.',
        ),
        SizedBox(height: 10),
        _NotificationBenefit(
          key: ValueKey('notification_benefit_updates'),
          icon: Icons.support_agent_rounded,
          title: 'Cập nhật trong thời gian thực',
          description: 'Luôn nắm được thay đổi liên quan đến chuyến đi.',
        ),
        SizedBox(height: 10),
        _NotificationBenefit(
          key: ValueKey('notification_benefit_offers'),
          icon: Icons.local_offer_rounded,
          title: 'Ưu đãi dành riêng cho bạn',
          description: 'Khám phá khuyến mãi và gợi ý phù hợp.',
        ),
      ],
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
