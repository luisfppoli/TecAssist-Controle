import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/core/widgets/app_bottom_navigation.dart';

void main() {
  testWidgets('exibe os cinco destinos principais', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavigation(currentIndex: 0),
        ),
      ),
    );

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('aciona o callback correspondente ao destino selecionado', (
    tester,
  ) async {
    int? indiceSelecionado;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 0,
            onTap: (index) => indiceSelecionado = index,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    expect(indiceSelecionado, 4);

    await tester.tap(find.byIcon(Icons.construction_outlined));
    expect(indiceSelecionado, 3);
  });

  testWidgets('destaca visualmente o destino atual', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavigation(currentIndex: 2),
        ),
      ),
    );

    final iconeSelecionado = tester.widget<Icon>(
      find.byIcon(Icons.calendar_month_outlined),
    );
    final iconeNaoSelecionado = tester.widget<Icon>(
      find.byIcon(Icons.home_rounded),
    );

    expect(iconeSelecionado.size, 32);
    expect(iconeNaoSelecionado.size, 29);
  });
}
