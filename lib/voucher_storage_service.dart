import 'package:shared_preferences/shared_preferences.dart';

class VoucherStorageService {
  static const _savedVoucherCodesKey = 'saved_voucher_codes';

  Future<void> saveVoucher(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final codes = preferences.getStringList(_savedVoucherCodesKey) ?? [];
    if (!codes.contains(normalizedCode)) {
      codes.add(normalizedCode);
      await preferences.setStringList(_savedVoucherCodesKey, codes);
    }
  }

  Future<List<String>> getSavedVoucherCodes() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_savedVoucherCodesKey) ?? const [];
  }

  Future<bool> isVoucherSaved(String code) async {
    final codes = await getSavedVoucherCodes();
    return codes.contains(code.trim().toUpperCase());
  }
}

final voucherStorageService = VoucherStorageService();
