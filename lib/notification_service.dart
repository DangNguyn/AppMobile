import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Small app-level adapter for local notifications. Permission is requested only
/// after the user opts in from onboarding.
class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionGranted = false;
  void Function(String? payload)? _onTap;

  Future<void> initialize({void Function(String? payload)? onTap}) async {
    _onTap = onTap;
    if (_initialized) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_fomogo'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) =>
            _onTap?.call(response.payload),
      );
      _initialized = true;
    } catch (_) {
      // Local inbox remains available if OS notification setup is unavailable.
    }
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      if (Platform.isAndroid) {
        _permissionGranted = await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            true;
      } else if (Platform.isIOS) {
        _permissionGranted = await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
      } else {
        _permissionGranted = true;
      }
    } catch (_) {
      _permissionGranted = false;
    }
    return _permissionGranted;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized || !_permissionGranted) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'fomogo_travel_updates',
            'Cập nhật FomoGo',
            channelDescription: 'Ưu đãi và gợi ý du lịch mới',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (_) {
      // A failed system notification must not interrupt booking or inbox flows.
    }
  }
}
