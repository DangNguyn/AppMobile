import 'dart:convert';

import 'package:app_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'fomogo_notifications_guest': jsonEncode([
        {
          'id': 'unread-test',
          'type': 'article',
          'title': 'Thông báo chưa đọc',
          'message': 'Nội dung test',
          'targetId': 'article-id',
          'location': 'Hạ Long',
          'image': '',
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
        },
      ]),
    });
  });

  testWidgets('chat icon opens inbox before starting a conversation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CustomerSupportIconButton()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Thông báo'), findsNothing);
    expect(find.byTooltip('Hỗ trợ khách hàng'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                const Color(0xFFFF2D72),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Hỗ trợ khách hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Hộp thư đến'), findsOneWidget);
    expect(find.text('Bắt đầu cuộc trò chuyện'), findsOneWidget);

    await tester.ensureVisible(find.text('Bắt đầu cuộc trò chuyện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu cuộc trò chuyện'));
    await tester.pumpAndSettle();

    expect(find.text('Trợ lý FomoGo'), findsOneWidget);
    expect(find.text('Luôn sẵn sàng hỗ trợ'), findsOneWidget);
    final titleCenter = tester.getCenter(find.text('Trợ lý FomoGo')).dx;
    final subtitleCenter =
        tester.getCenter(find.text('Luôn sẵn sàng hỗ trợ')).dx;
    expect((titleCenter - subtitleCenter).abs(), lessThan(1));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Cuộc trò chuyện mới'), findsOneWidget);
  });
}
