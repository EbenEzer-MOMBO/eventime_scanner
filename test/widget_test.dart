// Tests de demarrage de l'application.
//
// AppBootstrap effectue un controle de version reseau avant d'ouvrir le login
// ou l'accueil : on verifie ici que MyApp se construit et affiche l'ecran de
// demarrage, sans dependre de l'API.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventime_scanner/main.dart';

void main() {
  testWidgets('MyApp se construit sans agent connecte',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AppBootstrap), findsOneWidget);
  });

  testWidgets('MyApp se construit avec un agent connecte',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(
      isLoggedIn: true,
      id_agent: '1',
      nom_agent: 'Agent',
      matricule_agent: 'mat001',
      id_org: '1',
    ));

    expect(find.byType(AppBootstrap), findsOneWidget);
  });
}
