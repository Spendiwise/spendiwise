import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tryout/lib/screens/forecast_screen.dart'; // Adjust path

void main() {
  testWidgets('renders forecast chart if data is available', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ForecastScreen()));
    await tester.pump();

    // Assume CustomPaint is used for the chart
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Forecast'), findsOneWidget);
  });
}
