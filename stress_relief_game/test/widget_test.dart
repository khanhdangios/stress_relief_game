import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stress_relief_game/main.dart';

void main() {
  testWidgets('Calm Pop renders the playable game surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CalmPopApp());
    await tester.pump();

    expect(find.text('Calm Pop'), findsOneWidget);
    expect(find.text('Điểm'), findsOneWidget);
    expect(find.text('Combo'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    await tester.tapAt(const Offset(200, 300));
    await tester.pump();
  });
}
