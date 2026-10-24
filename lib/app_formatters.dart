import 'package:intl/intl.dart';

final NumberFormat _vndNumberFormat = NumberFormat('#,##0', 'vi_VN');
final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

String formatVnd(num? amount) => '${_vndNumberFormat.format(amount ?? 0)} đ';

String formatVietnameseDate(DateTime? date, {String emptyValue = '—'}) =>
    date == null ? emptyValue : _dateFormat.format(date);
