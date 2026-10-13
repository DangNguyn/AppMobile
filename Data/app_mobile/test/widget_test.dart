// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/main.dart';

void main() {
  testWidgets('home screen shows booking search UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Gần tôi'), findsOneWidget);
    expect(find.text('Bản đồ'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);
    expect(find.text('Ưu đãi thương hiệu 10.10'), findsOneWidget);
  });
}
