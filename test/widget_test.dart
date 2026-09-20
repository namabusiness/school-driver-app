import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_driver_app/app_controller.dart';
import 'package:school_driver_app/main.dart';
import 'package:school_driver_app/screens.dart';

void main() {
  testWidgets('login validation and dashboard render', (tester) async {
    await tester.pumpWidget(const DriverApp());
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('SIGN IN'));
    await tester.pump();
    expect(find.textContaining('Enter your phone/email'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'driver@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('SIGN IN'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Good morning,'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('START TRIP'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('START TRIP'), findsOneWidget);
  });

  testWidgets('trip state renders active and completed screens', (
    tester,
  ) async {
    final controller = AppController();
    await controller.startTrip();
    await tester.pumpWidget(
      MaterialApp(home: ActiveTripScreen(controller: controller)),
    );
    expect(find.text('LIVE'), findsOneWidget);

    await controller.endTrip();
    await tester.pumpWidget(
      MaterialApp(home: TripCompletedScreen(controller: controller)),
    );
    expect(find.text('Trip Completed'), findsOneWidget);
    controller.dispose();
  });
}
