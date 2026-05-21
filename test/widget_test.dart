import 'package:bancofalabella_app2/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows demo scoring dashboard', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(demoMode: true, userEmail: 'demo@cliente.pe'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Banco Falabella'), findsOneWidget);
    expect(find.textContaining('Modo demo activo'), findsOneWidget);
    expect(find.text('Credito preaprobado'), findsOneWidget);
    expect(find.byIcon(Icons.speed_outlined), findsOneWidget);
  });
}
