import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_mobile/booking_app.dart' as hotel_booking;
import 'package:app_mobile/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'user_name': 'Huy Nguyễn',
      'user_birth_date': '2006-07-11',
      'user_gender': 'Nam',
    });
  });

  testWidgets('Onboarding saves preferences and user details to account', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng bạn đến với FomoGo'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('onboarding_banner'))).dy,
      0,
    );
    expect(find.text('Đăng nhập / Đăng ký'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD - Đô la Mỹ (USD)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('welcome_continue_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thông báo ứng dụng'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('onboarding_banner'))).height,
      greaterThanOrEqualTo(180),
    );
    for (final key in const [
      ValueKey('notification_benefit_booking'),
      ValueKey('notification_benefit_updates'),
      ValueKey('notification_benefit_offers'),
      ValueKey('enable_notifications_button'),
      ValueKey('skip_notifications_button'),
    ]) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(844));
    }
    final bookingBenefit = tester.getRect(
      find.byKey(const ValueKey('notification_benefit_booking')),
    );
    final updatesBenefit = tester.getRect(
      find.byKey(const ValueKey('notification_benefit_updates')),
    );
    final offersBenefit = tester.getRect(
      find.byKey(const ValueKey('notification_benefit_offers')),
    );
    expect(updatesBenefit.top - bookingBenefit.bottom, lessThanOrEqualTo(13));
    expect(offersBenefit.top - updatesBenefit.bottom, lessThanOrEqualTo(13));
    expect(
      tester
              .getTopLeft(
                find.byKey(const ValueKey('enable_notifications_button')),
              )
              .dy -
          offersBenefit.bottom,
      lessThanOrEqualTo(210),
    );
    await tester.tap(find.byKey(const ValueKey('enable_notifications_button')));
    await tester.pumpAndSettle();

    final continueButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey('auth_continue_button')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(continueButton.onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('auth_email_field')),
      'huy@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth_mobile_field')),
      '+84901234567',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth_continue_button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Nam').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nam').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('additional_name_field')),
      'Huy Nguyễn',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('additional_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Mã giảm số lượng có hạn'), findsOneWidget);
    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('saved_account_data_card')),
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Thông tin đã lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Huy Nguyễn').first, findsOneWidget);
    expect(find.text('huy@example.com'), findsOneWidget);
    expect(find.text('+84901234567'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('Đã bật'), findsOneWidget);
    expect(find.text('Nam'), findsOneWidget);
  });

  testWidgets(
    'Skipping onboarding details keeps contact but leaves profile blank',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('welcome_continue_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skip_notifications_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth_email_field')),
        'huy@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_mobile_field')),
        '+84901234567',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth_continue_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('additional_skip_button')));
      await tester.pumpAndSettle();

      expect(find.text('Mã giảm số lượng có hạn'), findsOneWidget);
      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('saved_account_data_card')),
        250,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Thông tin đã lưu'));
      await tester.pumpAndSettle();
      expect(find.text('+84901234567'), findsOneWidget);
      expect(find.text('Đã tắt'), findsOneWidget);
      expect(find.text('Chưa cập nhật'), findsWidgets);
    },
  );

  testWidgets(
    'Auth close button sits below status bar and returns to notifications',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('welcome_continue_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('skip_notifications_button')));
      await tester.pumpAndSettle();

      final closeButton = find.byKey(const ValueKey('auth_close_button'));
      expect(tester.getTopLeft(closeButton).dy, greaterThanOrEqualTo(12));
      expect(tester.getSize(closeButton), const Size(48, 48));
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Thông báo ứng dụng'), findsOneWidget);
    },
  );

  testWidgets('Logout clears saved customer data and restarts onboarding', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'user_currency': 'USD',
      'user_language': 'English',
      'user_notification_enabled': true,
      'user_email_phone': 'old@example.com',
      'user_name': 'Old User',
      'user_birth_date': '01/01/1990',
      'user_gender': 'Nam',
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();

    final settingsScrollable = find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Đăng xuất'),
      250,
      scrollable: settingsScrollable,
    );
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất').last);
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng bạn đến với FomoGo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('welcome_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skip_notifications_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth_email_field')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth_mobile_field')),
      '+84901234567',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth_continue_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('additional_name_field')),
      'New User',
    );
    await tester.ensureVisible(find.text('Nam').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nam').last);
    await tester.ensureVisible(
      find.byKey(const ValueKey('additional_save_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('additional_save_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('saved_account_data_card')),
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Thông tin đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('new@example.com'), findsOneWidget);
    expect(find.text('Old User'), findsNothing);
    expect(find.text('New User').first, findsOneWidget);
    expect(find.text('USD'), findsNothing);
    expect(find.text('Đã tắt'), findsOneWidget);
  });

  testWidgets('Home hotel search panel stays within 30 percent of screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(SearchPanel)).height,
      lessThanOrEqualTo(844 * 0.3),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('home_search_blue_background')))
          .width,
      tester.getSize(find.byType(SearchPanel)).width,
    );
    expect(
      tester.getBottomLeft(find.byType(PromoStrip)).dy,
      greaterThan(tester.getBottomLeft(find.byType(SearchPanel)).dy),
    );
    final blueBackgroundBottom = tester
        .getBottomLeft(
          find.byKey(const ValueKey('home_search_blue_background')),
        )
        .dy;
    final searchFormBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('home_search_form')))
        .dy;
    expect(
      (blueBackgroundBottom - searchFormBottom).abs(),
      lessThanOrEqualTo(2),
    );
    expect(
      tester.getBottomLeft(find.byType(PromoStrip)).dy,
      greaterThan(blueBackgroundBottom),
    );
    expect(find.text('Địa điểm'), findsOneWidget);
    expect(find.text('Bản đồ'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);
    final homeLogo = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/fomogo_logo.png',
      ),
    );
    expect(homeLogo.width, 112);
    expect(homeLogo.height, 50);
    final discountCircle = find.descendant(
      of: find.byType(DiscountIconButton),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(discountCircle).width, 36);
    expect(tester.getSize(discountCircle).height, 36);
    final supportIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(CustomerSupportIconButton),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.chat_bubble_outline_rounded,
        ),
      ),
    );
    expect(supportIcon.size, 21);
  });

  testWidgets('Booking page provides database-ready coupon and hotel widgets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt chỗ của tôi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa có đặt chỗ, nhưng thế giới đang mời gọi bạn'),
      findsOneWidget,
    );

    final bookingScrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Thư viện Coupon'),
      250,
      scrollable: bookingScrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('Thư viện Coupon'), findsOneWidget);
    expect(find.text('Ưu đãi dành cho đặt phòng khách sạn'), findsOneWidget);
    expect(find.text('Vé máy bay'), findsNothing);
    expect(find.text('Khách sạn'), findsNothing);
    expect(find.text('Vé vui chơi'), findsNothing);
    expect(find.text('Ngân hàng'), findsNothing);
    expect(find.byIcon(Icons.confirmation_num_outlined), findsWidgets);
    expect(find.text('Giảm đến 1 triệu vé máy bay'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Đề xuất tuyệt vời'),
      250,
      scrollable: bookingScrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('Đề xuất tuyệt vời'), findsOneWidget);
    expect(
      find.text('Khách sạn phù hợp cho chuyến đi của bạn'),
      findsOneWidget,
    );
    expect(find.text('Hoạt động du lịch'), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsWidgets);
    expect(find.text('Grand Royal Riverside Hue'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Tất cả giao dịch và hoạt động khác'),
      250,
      scrollable: bookingScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Tất cả giao dịch và hoạt động khác'), findsOneWidget);
    expect(find.text('Hoàn tiền'), findsOneWidget);
  });

  testWidgets('Booking page opens the hotel booking workflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt chỗ của tôi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tìm và đặt phòng khách sạn'));
    await tester.pumpAndSettle();

    expect(find.byType(hotel_booking.TravelHomePage), findsOneWidget);
  });

  testWidgets('Home, booking and saved typography follows Explore sizing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final homeSectionTitle = tester.widget<Text>(
      find.text('Mã giảm số lượng có hạn'),
    );
    expect(homeSectionTitle.style?.fontSize, 17);

    final homePromo = tester.widget<RichText>(find.byType(RichText).first);
    expect((homePromo.text as TextSpan).style?.fontSize, 19);

    await tester.tap(find.text('Đặt chỗ của tôi'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('Đặt chỗ')).style?.fontSize, 22);
    expect(
      tester.widget<Text>(find.text('Bạn đã xem qua')).style?.fontSize,
      17,
    );

    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khách sạn đã lưu'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Khách sạn đã lưu  →')).style?.fontSize,
      15,
    );
    expect(
      tester.widget<Text>(find.text('Tạo bộ sưu tập mới')).style?.fontSize,
      15,
    );
  });

  testWidgets('Account navigation shows profile and account options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Huy Nguyễn'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/fomogo_logo.png',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/fomogo_mark.png',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();

    expect(find.text('Huy Nguyễn'), findsOneWidget);
    expect(find.text('Chào mừng, Huy Nguyễn'), findsOneWidget);
    expect(find.text('Thành viên FomoGo'), findsOneWidget);
    expect(find.text('★ VIP'), findsOneWidget);
    expect(find.text('Bronze'), findsOneWidget);
    expect(find.text('Bạn là Bronze Priority của chúng tôi'), findsNothing);
    expect(find.text('Thông tin hành khách'), findsNothing);
    expect(find.text('Thông tin đã lưu'), findsOneWidget);
    final headerBottom = tester.getBottomLeft(
      find.byKey(const ValueKey('account_header')),
    );
    final profileTop = tester.getTopLeft(
      find.byKey(const ValueKey('account_profile_card')),
    );
    expect(profileTop.dy, greaterThanOrEqualTo(headerBottom.dy));

    final accountScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Thông tin đã lưu'),
      300,
      scrollable: accountScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Thông tin đã lưu'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Trung tâm hỗ trợ'),
      300,
      scrollable: accountScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Trung tâm hỗ trợ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Liên hệ chúng tôi'),
      300,
      scrollable: accountScrollable,
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Gửi góp ý hoặc liên hệ với đội ngũ FomoGo'),
      findsOneWidget,
    );
  });

  testWidgets('Profile pencil opens editable fields and saves profile data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin tài khoản'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile_username_field')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profile_bio_field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile_birth_date_field')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profile_gender_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile_city_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('profile_name_field')),
      'Phúc Huy Nguyễn',
    );
    final editorScrollable = find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile_email_field')),
      250,
      scrollable: editorScrollable,
    );
    expect(find.byKey(const ValueKey('profile_email_field')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile_mobile_field')),
      250,
      scrollable: editorScrollable,
    );
    expect(find.byKey(const ValueKey('profile_mobile_field')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save_profile_button')));
    await tester.pumpAndSettle();

    expect(find.text('Phúc Huy Nguyễn'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('account_header')),
                  matching: find.byType(Text),
                )
                .first,
          )
          .data,
      'Chào mừng, Phúc Huy Nguyễn',
    );
    expect(find.text('Đã cập nhật thông tin cá nhân'), findsOneWidget);
  });

  testWidgets(
    'Account payment item opens card management and adds a masked card',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();

      final accountScrollable = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Thanh toán'),
        300,
        scrollable: accountScrollable,
      );
      await tester.tap(find.text('Thanh toán'));
      await tester.pumpAndSettle();

      expect(find.text('Thẻ của tôi'), findsOneWidget);
      expect(
        find.text('Tận hưởng thanh toán liền mạch với thẻ đã lưu'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('add_payment_card_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('add_payment_card_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('payment_card_holder_field')),
        'Huy Nguyen',
      );
      await tester.enterText(
        find.byKey(const ValueKey('payment_card_number_field')),
        '4242424242424242',
      );
      await tester.enterText(
        find.byKey(const ValueKey('payment_card_expiry_field')),
        '12/30',
      );
      await tester.enterText(
        find.byKey(const ValueKey('payment_card_cvv_field')),
        '123',
      );
      await tester.tap(
        find.byKey(const ValueKey('confirm_add_payment_card_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phương thức thanh toán'), findsOneWidget);
      expect(find.text('Visa •••• 4242'), findsOneWidget);
      expect(find.text('Huy Nguyen · Hết hạn 12/30'), findsOneWidget);
      expect(find.text('4242424242424242'), findsNothing);
      expect(find.text('123'), findsNothing);
    },
  );

  testWidgets(
    'Account refund item opens refund balance and bank account flow',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();

      final accountScrollable = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      final refundTile = find.ancestor(
        of: find.text('Hoàn tiền'),
        matching: find.byType(ListTile),
      );
      await tester.scrollUntilVisible(
        refundTile,
        300,
        scrollable: accountScrollable,
      );
      await tester.ensureVisible(refundTile);
      await tester.pumpAndSettle();
      await tester.tap(refundTile);
      await tester.pumpAndSettle();

      expect(
        find.text('Số dư hoàn tiền & trạng thái hoàn tiền'),
        findsOneWidget,
      );
      expect(find.text('0 VND'), findsOneWidget);
      expect(
        find.text(
          'Đôi khi, khoản hoàn tiền sẽ được chuyển thành Số dư Hoàn tiền để dùng cho các đặt chỗ sau.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('withdraw_refund_button')),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('refund_history_button')));
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử hoàn tiền'), findsOneWidget);
      expect(find.text('Chưa có giao dịch hoàn tiền'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('add_refund_bank_account_button')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('refund_bank_account_holder_field')),
        'HUY NGUYEN',
      );
      await tester.enterText(
        find.byKey(const ValueKey('refund_bank_account_number_field')),
        '1234567890',
      );
      await tester.tap(
        find.byKey(const ValueKey('save_refund_bank_account_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('HUY NGUYEN · •••• 7890'), findsOneWidget);
      expect(find.text('1234567890'), findsNothing);
    },
  );

  testWidgets('Account settings opens settings screen and controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt'), findsNothing);
    final accountScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final settingsTile = find.ancestor(
      of: find.text('Cài đặt'),
      matching: find.byType(ListTile),
    );
    await tester.scrollUntilVisible(
      settingsTile,
      300,
      scrollable: accountScrollable,
    );
    await tester.ensureVisible(settingsTile);
    await tester.pumpAndSettle();
    await tester.tap(settingsTile);
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản & Bảo mật'), findsOneWidget);
    expect(find.text('Tiền tệ thanh toán'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings_password_security')));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu & Bảo mật'), findsOneWidget);
    expect(find.text('Thiết bị này đáng tin'), findsOneWidget);
    expect(find.text('Xóa tài khoản'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit_security_pin_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new_security_pin_field')),
      '1234',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm_security_pin_field')),
      '1234',
    );
    await tester.tap(find.byKey(const ValueKey('save_security_pin_button')));
    await tester.pumpAndSettle();
    expect(find.text('Cập nhật mã PIN'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit_security_pin_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('current_security_pin_field')),
      '1234',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new_security_pin_field')),
      '5678',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm_security_pin_field')),
      '5678',
    );
    await tester.tap(find.byKey(const ValueKey('save_security_pin_button')));
    await tester.pumpAndSettle();
    expect(find.text('Mã PIN đã được cập nhật'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trusted_device_switch')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('trusted_device_switch')))
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('delete_account_button')));
    await tester.pumpAndSettle();
    expect(find.text('Xóa tài khoản?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel_account_deletion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete_account_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_account_deletion')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có dữ liệu nào bị xóa'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiền tệ thanh toán'));
    await tester.pumpAndSettle();
    expect(find.text('USD'), findsOneWidget);
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    expect(find.text('USD'), findsOneWidget);

    final settingsScrollable = find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Điều khoản & Điều kiện'),
      250,
      scrollable: settingsScrollable,
    );
    expect(find.text('Điều khoản & Điều kiện'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cài đặt thông báo'),
      250,
      scrollable: settingsScrollable,
    );
    await tester.tap(find.text('Cài đặt thông báo'));
    await tester.pumpAndSettle();
    expect(find.text('Cập nhật đặt phòng'), findsOneWidget);
    expect(find.text('Ưu đãi và khuyến mãi'), findsOneWidget);
  });

  testWidgets('Privacy settings toggles persist after reopening', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();

    final accountScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final settingsTile = find.ancestor(
      of: find.text('Cài đặt'),
      matching: find.byType(ListTile),
    );
    await tester.scrollUntilVisible(
      settingsTile,
      300,
      scrollable: accountScrollable,
    );
    await tester.tap(settingsTile);
    await tester.pumpAndSettle();

    final settingsScrollable = find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;
    final privacyItem = find.text('Thiết lập chế độ riêng tư');
    await tester.scrollUntilVisible(
      privacyItem,
      200,
      scrollable: settingsScrollable,
    );
    await tester.tap(privacyItem);
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ riêng tư'), findsOneWidget);
    expect(find.text('Đặt tab Bộ sưu tập thành Riêng tư'), findsOneWidget);
    expect(find.text('Đặt tab Đánh giá thành Riêng tư'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('private_profile_toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('private_reviews_toggle')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(privacyItem);
    await tester.tap(privacyItem);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('private_profile_toggle')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('private_reviews_toggle')))
          .value,
      isTrue,
    );
  });

  testWidgets('Explore navigation shows searchable travel articles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    expect(find.text('Khám phá Việt Nam'), findsOneWidget);
    expect(find.text('Kỳ quan thiên nhiên: Vịnh Hạ Long'), findsOneWidget);
    expect(find.text('10 bài viết'), findsOneWidget);

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Phú Quốc');
    await tester.pumpAndSettle();

    expect(find.text('Đảo ngọc Phú Quốc: Biển xanh cát trắng'), findsOneWidget);
    expect(find.text('Kỳ quan thiên nhiên: Vịnh Hạ Long'), findsNothing);

    const addedDestinations = {
      'Hồ Chí Minh': 'Sài Gòn không ngủ: Nhịp sống giữa lòng thành phố',
      'Nha Trang': 'Nha Trang: Hẹn nhau bên vịnh biển xanh',
      'Hà Nội': 'Hà Nội: Một vòng phố cổ và hương vị thủ đô',
      'Đà Lạt': 'Đà Lạt mộng mơ: Thành phố của ngàn thông',
      'Huế': 'Cố đô Huế: Dấu xưa bên dòng sông Hương',
    };
    for (final destination in addedDestinations.entries) {
      await tester.enterText(searchField, destination.key);
      await tester.pumpAndSettle();
      expect(find.text(destination.value), findsOneWidget);
    }

    await tester.tap(find.text('Cố đô Huế: Dấu xưa bên dòng sông Hương'));
    await tester.pumpAndSettle();

    final detailScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Hình ảnh điểm đến'),
      300,
      scrollable: detailScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Hình ảnh điểm đến'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Theo dấu di sản cố đô'),
      300,
      scrollable: detailScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Theo dấu di sản cố đô'), findsOneWidget);

    final travelTip = find.textContaining('Mẹo nhỏ:');
    await tester.scrollUntilVisible(
      travelTip,
      300,
      scrollable: detailScrollable,
    );
    await tester.pumpAndSettle();
    expect(travelTip, findsOneWidget);
  });

  testWidgets('Saved Explore articles appear only under saved information', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Lưu bài viết').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin đã lưu'), findsOneWidget);
    expect(find.text('Khách sạn đã lưu'), findsOneWidget);
    expect(find.text('Kỳ quan thiên nhiên: Vịnh Hạ Long'), findsOneWidget);
    expect(find.text('1 bài viết du lịch'), findsOneWidget);

    await tester.tap(find.text('Khách sạn đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Kỳ quan thiên nhiên: Vịnh Hạ Long'), findsNothing);
    expect(find.text('Khách sạn đã lưu  →'), findsOneWidget);

    await tester.tap(find.text('Thông tin đã lưu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bỏ lưu bài viết'));
    await tester.pumpAndSettle();
    expect(find.text('Bài viết bạn lưu sẽ xuất hiện tại đây'), findsOneWidget);
  });
}
