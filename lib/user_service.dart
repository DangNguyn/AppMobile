import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class UserInfo {
  const UserInfo({
    this.name = '',
    this.birthDate = '',
    this.gender = '',
    this.city = '',
  });

  final String name;
  final String birthDate;
  final String gender;
  final String city;
}

@immutable
class SavedUserData {
  const SavedUserData({
    this.currency = 'VND',
    this.language = 'Tiếng Việt',
    this.notificationEnabled = false,
    this.email = '',
    this.mobile = '',
    this.emailPhone = '',
    this.userInfo = const UserInfo(),
  });

  final String currency;
  final String language;
  final bool notificationEnabled;
  final String email;
  final String mobile;
  @Deprecated('Use email and mobile instead.')
  final String emailPhone;
  final UserInfo userInfo;
}

class UserService {
  final ValueNotifier<int> notificationPreferenceRevision = ValueNotifier(0);

  static const _currencyKey = 'user_currency';
  static const _languageKey = 'user_language';
  static const _notificationKey = 'user_notification_enabled';
  static const _bookingUpdatesKey = 'notification_booking_updates';
  static const _promotionNotificationsKey = 'notification_promotions';
  static const _travelInspirationKey = 'notification_travel_inspiration';
  static const _emailKey = 'user_email';
  static const _mobileKey = 'user_mobile';
  static const _emailPhoneKey = 'user_email_phone';
  static const _nameKey = 'user_name';
  static const _birthDateKey = 'user_birth_date';
  static const _genderKey = 'user_gender';
  static const _cityKey = 'user_city';
  static const _privateProfileKey = 'privacy_private_profile';
  static const onboardingCompletedKey = 'onboarding_completed';

  Future<void> saveCurrency(String currency) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_currencyKey, currency);
  }

  Future<String> getCurrency() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_currencyKey) ?? 'VND';
  }

  Future<void> saveLanguage(String language) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, language);
  }

  Future<String> getLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_languageKey) ?? 'Tiếng Việt';
  }

  Future<void> saveNotificationPref(bool isEnabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationKey, isEnabled);
    await preferences.setBool(_bookingUpdatesKey, isEnabled);
    await preferences.setBool(_promotionNotificationsKey, isEnabled);
    await preferences.setBool(_travelInspirationKey, isEnabled);
    notificationPreferenceRevision.value++;
  }

  Future<bool> getBookingUpdatesPref() =>
      _getNotificationCategory(_bookingUpdatesKey);

  Future<bool> getPromotionNotificationsPref() =>
      _getNotificationCategory(_promotionNotificationsKey);

  Future<bool> getTravelInspirationPref() =>
      _getNotificationCategory(_travelInspirationKey);

  Future<void> saveBookingUpdatesPref(bool enabled) =>
      _saveNotificationCategory(_bookingUpdatesKey, enabled);

  Future<void> savePromotionNotificationsPref(bool enabled) =>
      _saveNotificationCategory(_promotionNotificationsKey, enabled);

  Future<void> saveTravelInspirationPref(bool enabled) =>
      _saveNotificationCategory(_travelInspirationKey, enabled);

  Future<bool> _getNotificationCategory(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(key) ??
        preferences.getBool(_notificationKey) ??
        true;
  }

  Future<void> _saveNotificationCategory(String key, bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, enabled);
    final legacyValue = preferences.getBool(_notificationKey) ?? true;
    final allEnabled =
        (preferences.getBool(_bookingUpdatesKey) ?? legacyValue) ||
            (preferences.getBool(_promotionNotificationsKey) ?? legacyValue) ||
            (preferences.getBool(_travelInspirationKey) ?? legacyValue);
    await preferences.setBool(_notificationKey, allEnabled);
    notificationPreferenceRevision.value++;
  }

  Future<void> savePrivateProfilePref(bool isEnabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privateProfileKey, isEnabled);
  }

  Future<bool> getPrivateProfilePref() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_privateProfileKey) ?? false;
  }

  Future<bool> getNotificationPref() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_notificationKey) ?? false;
  }

  Future<void> saveEmailPhone(String emailPhone) async {
    final preferences = await SharedPreferences.getInstance();
    final value = emailPhone.trim();
    if (value.contains('@')) {
      await preferences.setString(_emailKey, value);
    } else {
      await preferences.setString(_mobileKey, value);
    }
    await preferences.setString(_emailPhoneKey, value);
  }

  Future<void> saveContactInfo({
    required String email,
    required String mobile,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final trimmedEmail = email.trim();
    final trimmedMobile = mobile.trim();
    await preferences.setString(_emailKey, trimmedEmail);
    await preferences.setString(_mobileKey, trimmedMobile);
    await preferences.setString(
      _emailPhoneKey,
      trimmedEmail.isNotEmpty ? trimmedEmail : trimmedMobile,
    );
  }

  Future<String> getEmail() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_emailKey) ??
        ((preferences.getString(_emailPhoneKey) ?? '').contains('@')
            ? preferences.getString(_emailPhoneKey) ?? ''
            : '');
  }

  Future<String> getMobile() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_mobileKey) ??
        ((preferences.getString(_emailPhoneKey) ?? '').contains('@')
            ? ''
            : preferences.getString(_emailPhoneKey) ?? '');
  }

  Future<String> getEmailPhone() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_emailPhoneKey) ?? '';
  }

  Future<void> saveUserInfo({
    required String name,
    required String birthDate,
    required String gender,
    String city = '',
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nameKey, name.trim());
    await preferences.setString(_birthDateKey, birthDate);
    await preferences.setString(_genderKey, gender);
    await preferences.setString(_cityKey, city);
  }

  Future<UserInfo> getUserInfo() async {
    final preferences = await SharedPreferences.getInstance();
    return UserInfo(
      name: preferences.getString(_nameKey) ?? '',
      birthDate: preferences.getString(_birthDateKey) ?? '',
      gender: preferences.getString(_genderKey) ?? '',
      city: preferences.getString(_cityKey) ?? '',
    );
  }

  Future<SavedUserData> getSavedUserData() async {
    final currency = await getCurrency();
    final language = await getLanguage();
    final notificationEnabled = await getNotificationPref();
    final email = await getEmail();
    final mobile = await getMobile();
    final emailPhone = await getEmailPhone();
    final userInfo = await getUserInfo();
    return SavedUserData(
      currency: currency,
      language: language,
      notificationEnabled: notificationEnabled,
      email: email,
      mobile: mobile,
      emailPhone: emailPhone,
      userInfo: userInfo,
    );
  }

  Future<bool> isOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(onboardingCompletedKey) ?? false;
  }

  Future<void> saveOnboardingCompleted(bool completed) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(onboardingCompletedKey, completed);
  }

  Future<void> clearCustomerData() async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in [
      _currencyKey,
      _languageKey,
      _notificationKey,
      _bookingUpdatesKey,
      _promotionNotificationsKey,
      _travelInspirationKey,
      _emailKey,
      _mobileKey,
      _emailPhoneKey,
      _nameKey,
      _birthDateKey,
      _genderKey,
      _cityKey,
      _privateProfileKey,
      'privacy_private_collections',
      'privacy_private_reviews',
      onboardingCompletedKey,
    ]) {
      await preferences.remove(key);
    }
  }
}

final userService = UserService();
