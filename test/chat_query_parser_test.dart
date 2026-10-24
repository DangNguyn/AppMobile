import 'package:app_mobile/chat_query_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('understands Vietnamese city, guest count, nights and minimum price',
      () {
    const message =
        'Tìm phòng tại Nha Trang giá phòng phải trên 5triệu 1 đêm, cho 2 người';
    final normalized = ChatQueryParser.normalize(message);
    final price = ChatQueryParser.priceRange(message);

    expect(ChatQueryParser.city(normalized), 'Nha Trang');
    expect(ChatQueryParser.guests(normalized), 2);
    expect(ChatQueryParser.nights(normalized), 1);
    expect(price.minimum, 5000000);
    expect(price.maximum, isNull);
    expect(price.matches(6000000), isTrue);
    expect(price.matches(5000000), isFalse);
    expect(price.matches(4000000), isFalse);
  });

  test('understands upper and bounded nightly price requests', () {
    final upper = ChatQueryParser.priceRange('ngân sách dưới 2.000.000đ/đêm');
    expect(upper.maximum, 2000000);
    expect(upper.matches(1500000), isTrue);
    expect(upper.matches(2000000), isFalse);
    expect(upper.matches(2500000), isFalse);

    final range = ChatQueryParser.priceRange(
      'phòng từ 1,5 triệu đến 3 triệu mỗi đêm',
    );
    expect(range.minimum, 1500000);
    expect(range.maximum, 3000000);
    expect(range.matches(2000000), isTrue);
    expect(range.matches(3500000), isFalse);
  });
}
