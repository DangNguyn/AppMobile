import 'dart:convert';

import 'package:app_mobile/ai_support_page.dart';
import 'package:app_mobile/api/api_client.dart';
import 'package:app_mobile/api/api_repository.dart';
import 'package:app_mobile/chat_query_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Chat recommends matching hotels and active vouchers from API',
      (tester) async {
    final client = MockClient((request) async {
      final path = request.url.path;
      final Object body;
      if (path == '/api/hotels') {
        body = {
          'data': [
            {
              'id': 'hotel-da-nang',
              'name': 'Khách sạn Gia đình Đà Nẵng',
              'city': 'Đà Nẵng',
              'address': 'Sơn Trà, Đà Nẵng',
              'star_rating': 4,
            },
            {
              'id': 'hotel-ha-noi',
              'name': 'Khách sạn Hà Nội',
              'city': 'Hà Nội',
              'address': 'Ba Đình, Hà Nội',
            },
            {
              'id': 'hotel-expensive',
              'name': 'Khách sạn cao cấp Đà Nẵng',
              'city': 'Đà Nẵng',
              'address': 'Ngũ Hành Sơn, Đà Nẵng',
            },
          ],
        };
      } else if (path == '/api/hotels/hotel-da-nang/room-types') {
        body = {
          'data': [
            {
              'id': 'family-room',
              'hotel_id': 'hotel-da-nang',
              'name': 'Phòng gia đình',
              'max_guests': 4,
              'base_price': 1500000,
            },
          ],
        };
      } else if (path == '/api/hotels/hotel-expensive/room-types') {
        body = {
          'data': [
            {
              'id': 'premium-room',
              'hotel_id': 'hotel-expensive',
              'name': 'Phòng cao cấp',
              'max_guests': 4,
              'base_price': 2500000,
            },
          ],
        };
      } else if (path == '/api/vouchers') {
        body = {
          'data': [
            {
              'id': 'voucher-family',
              'code': 'FAMILY20',
              'discount_type': 'percent',
              'discount_value': 20,
              'min_order': 1000000,
              'status': 'active',
            },
          ],
        };
      } else if (path == '/api/hotels/hotel-da-nang/images') {
        body = {'data': <Object>[]};
      } else {
        return http.Response('Not found', 404);
      }
      return http.Response(
        jsonEncode(body),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final repository = ApiRepository(client: ApiClient(client: client));

    await tester.pumpWidget(
      MaterialApp(home: AiSupportPage(repository: repository)),
    );
    await tester.enterText(
      find.byType(TextField),
      'Đề xuất khách sạn ở Đà Nẵng phù hợp cho 4 người, ngân sách dưới 2 triệu một đêm',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Khách sạn Gia đình Đà Nẵng'), findsOneWidget);
    expect(find.text('Khách sạn Hà Nội'), findsNothing);
    expect(find.text('Khách sạn cao cấp Đà Nẵng'), findsNothing);
    expect(find.textContaining('tối đa 4 khách'), findsOneWidget);
    expect(find.textContaining('FAMILY20'), findsWidgets);
  });

  testWidgets('Chat filters hotels by a minimum nightly room price',
      (tester) async {
    final client = MockClient((request) async {
      final path = request.url.path;
      final Object body;
      if (path == '/api/hotels') {
        body = {
          'data': [
            {
              'id': 'hotel-over-five',
              'name': 'Khách sạn trên 5 triệu',
              'city': 'Nha Trang',
              'address': 'Trần Phú, Nha Trang',
            },
            {
              'id': 'hotel-under-five',
              'name': 'Khách sạn dưới 5 triệu',
              'city': 'Nha Trang',
              'address': 'Nha Trang',
            },
          ],
        };
      } else if (path == '/api/hotels/hotel-over-five/room-types') {
        body = {
          'data': [
            {
              'id': 'room-over-five',
              'hotel_id': 'hotel-over-five',
              'name': 'Phòng hướng biển',
              'max_guests': 2,
              'base_price': 6000000,
            },
          ],
        };
      } else if (path == '/api/hotels/hotel-under-five/room-types') {
        body = {
          'data': [
            {
              'id': 'room-under-five',
              'hotel_id': 'hotel-under-five',
              'name': 'Phòng tiêu chuẩn',
              'max_guests': 2,
              'base_price': 4000000,
            },
          ],
        };
      } else if (path == '/api/vouchers' ||
          path == '/api/hotels/hotel-over-five/images') {
        body = {'data': <Object>[]};
      } else {
        return http.Response('Not found: $path', 404);
      }
      return http.Response(
        jsonEncode(body),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final repository = ApiRepository(client: ApiClient(client: client));

    await tester.pumpWidget(
      MaterialApp(home: AiSupportPage(repository: repository)),
    );
    await tester.enterText(
      find.byType(TextField),
      'Tìm phòng tại Nha Trang giá phòng phải trên 5triệu 1 đêm, cho 2 người',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Khách sạn trên 5 triệu'), findsOneWidget);
    expect(find.text('Khách sạn dưới 5 triệu'), findsNothing);
  });

  test('Vietnamese chat query parser handles the reported query', () {
    const message =
        'Tìm phòng tại Nha Trang giá phòng phải trên 5triệu 1 đêm, cho 2 người';
    final normalized = ChatQueryParser.normalize(message);
    final price = ChatQueryParser.priceRange(message);

    expect(ChatQueryParser.city(normalized), 'Nha Trang');
    expect(ChatQueryParser.guests(normalized), 2);
    expect(ChatQueryParser.nights(normalized), 1);
    expect(price.minimum, 5000000);
    expect(price.matches(6000000), isTrue);
    expect(price.matches(4000000), isFalse);
  });
}
