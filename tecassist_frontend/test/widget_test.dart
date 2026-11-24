import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/core/widgets/app_bottom_navigation.dart';

void main() {
  testWidgets('TecAssist renderiza a barra de navegação principal', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('TecAssist')),
          bottomNavigationBar: AppBottomNavigation(currentIndex: 0),
        ),
      ),
    );

    expect(find.text('TecAssist'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });
}
