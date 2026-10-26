import 'package:intl/intl.dart';

final NumberFormat _vndNumberFormat = NumberFormat('#,##0', 'vi_VN');
final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

String formatVnd(num? amount) => '${_vndNumberFormat.format(amount ?? 0)} đ';

String formatVietnameseDate(DateTime? date, {String emptyValue = '—'}) =>
    date == null ? emptyValue : _dateFormat.format(date);

String formatBookingDate(String? value, {String emptyValue = '—'}) {
  final rawValue = value?.trim();
  if (rawValue == null || rawValue.isEmpty) return emptyValue;

  final parsed = DateTime.tryParse(rawValue);
  if (parsed == null) return rawValue;

  // Keep the calendar date supplied by the API; converting UTC to local time
  // can shift a midnight check-in to the previous day in Vietnam.
  return _dateFormat.format(DateTime(parsed.year, parsed.month, parsed.day));
}
