import 'dart:convert';

import 'package:app_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notification inbox lists content and opens article details',
      (tester) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'fomogo_notifications_guest': jsonEncode([
        {
          'id': 'read-1',
          'type': 'article',
          'title': 'Khám phá: Kỳ quan thiên nhiên: Vịnh Hạ Long',
          'message': 'Du ngoạn du thuyền và khám phá hang động.',
          'targetId': 'Kỳ quan thiên nhiên: Vịnh Hạ Long',
          'location': 'Hạ Long, Quảng Ninh',
          'image':
              'https://images.unsplash.com/photo-1528127269322-539801943592',
          'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
          'isRead': true,
        },
        {
          'id': 'unread-1',
          'type': 'article',
          'title': 'Gợi ý chuyến đi: Đảo ngọc Phú Quốc: Biển xanh cát trắng',
          'message': 'Khám phá biển xanh Phú Quốc.',
          'targetId': 'Đảo ngọc Phú Quốc: Biển xanh cát trắng',
          'location': 'Phú Quốc, Kiên Giang',
          'image':
              'https://images.unsplash.com/photo-1519046904884-53103b34b206',
          'createdAt': now.toIso8601String(),
          'isRead': false,
        },
      ]),
    });

    await tester.pumpWidget(
      const MaterialApp(home: CustomerSupportPage(initialTab: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khám phá: Kỳ quan thiên nhiên: Vịnh Hạ Long'),
        findsOneWidget);
    expect(find.text('Gợi ý chuyến đi: Đảo ngọc Phú Quốc: Biển xanh cát trắng'),
        findsOneWidget);
    await tester.tap(
      find.text('Gợi ý chuyến đi: Đảo ngọc Phú Quốc: Biển xanh cát trắng'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đảo ngọc Phú Quốc: Biển xanh cát trắng'), findsWidgets);
  });
}
