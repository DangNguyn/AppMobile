/// Extracts common Vietnamese travel search details from a chat message.
/// Search results still come from the hotel API; this only interprets the
/// customer's words into filters.
class ChatQueryParser {
  static const Map<String, String> _diacritics = {
    'a': 'àáạảãăằắặẳẵâầấậẩẫ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
  };

  static String normalize(String value) {
    var result = value.toLowerCase().replaceAll('đ', 'd');
    for (final entry in _diacritics.entries) {
      for (final character in entry.value.split('')) {
        result = result.replaceAll(character, entry.key);
      }
    }
    return result.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').trim();
  }

  static String? city(String normalizedText) {
    const cities = <String, String>{
      'da nang': 'Đà Nẵng',
      'nha trang': 'Nha Trang',
      'ho chi minh': 'Hồ Chí Minh',
      'ha noi': 'Hà Nội',
      'da lat': 'Đà Lạt',
      'phu quoc': 'Phú Quốc',
      'hoi an': 'Hội An',
      'ha long': 'Hạ Long',
      'hue': 'Huế',
      'sa pa': 'Sa Pa',
    };
    for (final entry in cities.entries) {
      if (normalizedText.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static int? guests(String text) {
    final match = RegExp(
      r'(\d+)\s*(?:nguoi|khach|guest|guests)',
    ).firstMatch(text);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static int? nights(String text) {
    final match = RegExp(r'(\d+)\s*(?:dem|night|nights)').firstMatch(text);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static ChatPriceRange priceRange(String text) {
    var normalized = text.toLowerCase().replaceAll('đ', 'd');
    for (final entry in _diacritics.entries) {
      for (final character in entry.value.split('')) {
        normalized = normalized.replaceAll(character, entry.key);
      }
    }
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9.,\s]'), ' ');
    final amount = r'([\d.,]+)\s*(trieu|tr|million|k|nghin|ngan)?';
    final minimumMatch = RegExp(
      '(?<operator>tren|hon|tu|toi thieu|it nhat|at least|above|over)\\s*$amount',
    ).firstMatch(normalized);
    final maximumMatch = RegExp(
      '(?<operator>den|toi|duoi|toi da|khong qua|ngan sach|budget|at most|under|below)\\s*$amount',
    ).firstMatch(normalized);
    final exactMatch = minimumMatch == null && maximumMatch == null
        ? RegExp('(?:gia|price)\\s*(?:phong)?\\s*(?:la|khoang)?\\s*$amount')
            .firstMatch(normalized)
        : null;
    return ChatPriceRange(
      minimum: minimumMatch == null
          ? null
          : _parseAmount(minimumMatch.group(2)!, minimumMatch.group(3)),
      maximum: maximumMatch == null
          ? null
          : _parseAmount(maximumMatch.group(2)!, maximumMatch.group(3)),
      exact: exactMatch == null
          ? null
          : _parseAmount(exactMatch.group(1)!, exactMatch.group(2)),
      minimumExclusive: minimumMatch != null &&
          const {'tren', 'hon', 'above', 'over'}
              .contains(minimumMatch.namedGroup('operator')),
      maximumExclusive: maximumMatch != null &&
          const {'duoi', 'under', 'below'}
              .contains(maximumMatch.namedGroup('operator')),
    );
  }

  static double? _parseAmount(String raw, String? unit) {
    var normalized = raw;
    if (RegExp(r'^\d{1,3}(?:[.,]\d{3})+$').hasMatch(normalized)) {
      normalized = normalized.replaceAll(RegExp(r'[.,]'), '');
    } else {
      normalized = normalized.replaceAll(',', '.');
    }
    final value = double.tryParse(normalized);
    if (value == null) return null;
    return switch (unit) {
      'trieu' || 'tr' || 'million' => value * 1000000,
      'k' || 'nghin' || 'ngan' => value * 1000,
      _ => value,
    };
  }
}

class ChatPriceRange {
  const ChatPriceRange({
    this.minimum,
    this.maximum,
    this.exact,
    this.minimumExclusive = false,
    this.maximumExclusive = false,
  });

  final double? minimum;
  final double? maximum;
  final double? exact;
  final bool minimumExclusive;
  final bool maximumExclusive;

  bool matches(double? value) {
    if (value == null) {
      return minimum == null && maximum == null && exact == null;
    }
    if (minimum != null &&
        (minimumExclusive ? value <= minimum! : value < minimum!)) {
      return false;
    }
    if (maximum != null &&
        (maximumExclusive ? value >= maximum! : value > maximum!)) {
      return false;
    }
    if (exact != null && value != exact) return false;
    return true;
  }

  String get description {
    if (minimum != null && maximum != null) {
      return 'từ ${_money(minimum!)} đến ${_money(maximum!)}';
    }
    if (minimum != null) {
      return '${minimumExclusive ? 'trên' : 'từ'} ${_money(minimum!)}';
    }
    if (maximum != null) {
      return '${maximumExclusive ? 'dưới' : 'tối đa'} ${_money(maximum!)}';
    }
    if (exact != null) return 'khoảng ${_money(exact!)}';
    return '';
  }

  static String _money(double value) {
    final rounded = value.round();
    final digits = rounded.toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$groupedđ/đêm';
  }
}
