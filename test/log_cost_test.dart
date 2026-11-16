// Widget tests for the cost per kWh and total cost of a charging session.
//
// Runs without a live Pod: only the charge section's form behaviour.

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:konapod/pages/log_charge_section.dart';

/// The charge section with charging switched on, so its fields are shown.

Future<void> pumpCharge(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LogChargeSection(startTimestamp: DateTime(2026, 11, 16)),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(Switch));
  await tester.pump();
}

Finder get energy => find.byType(TextField).at(2);
Finder get costPerKwh => find.widgetWithText(TextField, 'Cost per kWh');
Finder get totalCost => find.widgetWithText(TextField, 'Total cost');

String textOf(WidgetTester tester, Finder f) =>
    tester.widget<TextField>(f).controller!.text;

/// The note under a field: "calculated", or null.

String? helperOf(WidgetTester tester, Finder f) =>
    tester.widget<TextField>(f).decoration!.helperText;

void main() {
  testWidgets('a total with no cost per kWh works out a calculated one', (
    tester,
  ) async {
    await pumpCharge(tester);
    await tester.enterText(energy, '20');
    await tester.enterText(totalCost, '10');
    await tester.pump();

    expect(textOf(tester, costPerKwh), '0.50');
    expect(helperOf(tester, costPerKwh), 'calculated');
    expect(helperOf(tester, totalCost), isNull);

    // The user's total is left as entered, not worked back from the
    // rounded cost per kWh.

    expect(textOf(tester, totalCost), '10');

    // It follows the total and the energy while still calculated.

    await tester.enterText(totalCost, '12');
    await tester.pump();
    expect(textOf(tester, costPerKwh), '0.60');

    await tester.enterText(energy, '24');
    await tester.pump();
    expect(textOf(tester, costPerKwh), '0.50');
    expect(textOf(tester, totalCost), '12');
  });

  testWidgets('typing a cost per kWh replaces the calculated one', (
    tester,
  ) async {
    await pumpCharge(tester);
    await tester.enterText(energy, '20');
    await tester.enterText(totalCost, '10');
    await tester.pump();

    await tester.enterText(costPerKwh, '0.40');
    await tester.pump();

    // No longer calculated, so it now drives the total, which is noted as
    // calculated in its turn.

    expect(textOf(tester, totalCost), '8.00');
    expect(helperOf(tester, costPerKwh), isNull);
    expect(helperOf(tester, totalCost), 'calculated');

    // A total typed over it is the user's, and no longer overwrites the
    // entered cost per kWh.

    await tester.enterText(totalCost, '15');
    await tester.pump();
    expect(textOf(tester, costPerKwh), '0.40');
    expect(helperOf(tester, totalCost), isNull);
  });

  testWidgets('clearing the cost per kWh clears a calculated total', (
    tester,
  ) async {
    await pumpCharge(tester);
    await tester.enterText(energy, '20');
    await tester.enterText(costPerKwh, '0.40');
    await tester.pump();
    expect(textOf(tester, totalCost), '8.00');

    await tester.enterText(costPerKwh, '');
    await tester.pump();
    expect(textOf(tester, totalCost), '');
  });

  testWidgets('clearing the total clears a calculated cost per kWh', (
    tester,
  ) async {
    await pumpCharge(tester);
    await tester.enterText(energy, '20');
    await tester.enterText(totalCost, '10');
    await tester.pump();
    expect(textOf(tester, costPerKwh), '0.50');

    await tester.enterText(totalCost, '');
    await tester.pump();
    expect(textOf(tester, costPerKwh), '');
  });
}
