// Unit tests for the battery % → kWh fit and the log entry field it fills.
//
// Runs without a live Pod: pure fit arithmetic and controller behaviour.

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:konapod/models/battery_observation.dart';
import 'package:konapod/pages/log_entry_widgets.dart';
import 'package:konapod/pages/remain_kwh_filler.dart';
import 'package:konapod/services/battery_kwh_estimator.dart';

/// Observations on the line kWh = 0.64 × % (a 64 kWh pack).

List<BatteryObservation> lineObs(List<double> pcts) => [
      for (final pct in pcts)
        BatteryObservation(
          timestamp: DateTime(2026, 9, 14),
          batteryPct: pct,
          rangeKm: pct * 4,
          remainKwh: pct * 0.64,
        ),
    ];

void main() {
  group('BatteryKwhEstimator.fit', () {
    test('recovers the slope of a linear set of observations', () {
      final est = BatteryKwhEstimator.fit(lineObs([20, 40, 55, 70, 90]))!;
      expect(est.slope, closeTo(0.64, 0.001));
      expect(est.intercept, closeTo(0, 0.001));
      expect(est.sampleCount, 5);
      expect(est.estimate(50), closeTo(32, 0.05));
    });

    test('never estimates below zero', () {
      // A fit that crosses zero above 0% — kWh = 0.7 × % − 3.

      final est = BatteryKwhEstimator.fit([
        for (final pct in [20.0, 40.0, 60.0, 80.0, 95.0])
          BatteryObservation(
            timestamp: DateTime(2026, 9, 14),
            batteryPct: pct,
            rangeKm: pct * 4,
            remainKwh: pct * 0.7 - 3,
          ),
      ])!;
      expect(est.intercept, closeTo(-3, 0.001));
      expect(est.estimate(0), 0);
      expect(est.estimate(50), closeTo(32, 0.001));
    });

    test('declines to fit too few readings', () {
      expect(BatteryKwhEstimator.fit(lineObs([20, 50, 80, 90])), isNull);
    });

    test('declines to fit too narrow a span of percentages', () {
      expect(BatteryKwhEstimator.fit(lineObs([50, 52, 54, 56, 58])), isNull);
    });

    test('ignores observations with no kWh reading', () {
      final obs = [
        ...lineObs([20, 40, 60, 80, 95]),
        BatteryObservation(
          timestamp: DateTime(2026, 9, 14),
          batteryPct: 30,
          rangeKm: 120,
        ),
      ];
      expect(BatteryKwhEstimator.fit(obs)!.sampleCount, 5);
    });

    test('declines a set with no kWh readings at all', () {
      final obs = [
        for (final pct in [20.0, 40.0, 60.0, 80.0, 95.0])
          BatteryObservation(
            timestamp: DateTime(2026, 9, 14),
            batteryPct: pct,
            rangeKm: pct * 4,
          ),
      ];
      expect(BatteryKwhEstimator.fit(obs), isNull);
    });
  });

  group('RemainKwhFiller', () {
    late TextEditingController pct;
    late TextEditingController remain;
    late RemainKwhFiller filler;
    final estimator = BatteryKwhEstimator.fit(lineObs([20, 40, 55, 70, 90]))!;

    setUp(() {
      pct = TextEditingController();
      remain = TextEditingController();
      filler = RemainKwhFiller(pctCtrl: pct, remainCtrl: remain)
        ..estimator = estimator;
    });

    tearDown(() {
      filler.dispose();
      pct.dispose();
      remain.dispose();
    });

    test('fills a blank field from the battery percentage', () {
      pct.text = '50';
      expect(remain.text, '32.0');
      expect(filler.isEstimate, isTrue);
    });

    test('follows the percentage while the value is its own estimate', () {
      pct.text = '50';
      pct.text = '75';
      expect(remain.text, '48.0');
    });

    test('leaves a reading alone', () {
      remain.text = '41.3';
      pct.text = '50';
      expect(remain.text, '41.3');
      expect(filler.isEstimate, isFalse);
    });

    test('gives way to a value typed over the estimate', () {
      pct.text = '50';
      remain.text = '30.0';
      expect(filler.isEstimate, isFalse);
      pct.text = '60';
      expect(remain.text, '30.0');
    });

    test('estimates again when a reading is cleared away', () {
      pct.text = '50';
      remain.text = '41.3';
      remain.text = '';
      expect(remain.text, '32.0');
      expect(filler.isEstimate, isTrue);
    });

    test('takes the estimate back out when the percentage goes', () {
      pct.text = '50';
      pct.text = '';
      expect(remain.text, isEmpty);
      expect(filler.isEstimate, isFalse);
    });

    testWidgets('marks the readings grid estimated only while it is', (
      tester,
    ) async {
      final range = TextEditingController();
      late void Function(VoidCallback) rebuild;
      final noted = RemainKwhFiller(
        pctCtrl: pct,
        remainCtrl: remain,
        onChanged: () => rebuild(() {}),
      );
      filler.dispose();
      pct.text = '50';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return LogReadingsGrid(
                  odoCtrl: null,
                  battCtrl: pct,
                  remainCtrl: remain,
                  rangeCtrl: range,
                  remainFiller: noted,
                );
              },
            ),
          ),
        ),
      );
      expect(find.text(RemainKwhFiller.noteLabel), findsNothing);

      noted.estimator = estimator;
      await tester.pump();
      expect(find.text('32.0'), findsOneWidget);
      expect(find.text(RemainKwhFiller.noteLabel), findsOneWidget);

      // The Remaining field is the second of the three in the grid.

      await tester.enterText(find.byType(TextField).at(1), '41.3');
      await tester.pump();
      expect(find.text(RemainKwhFiller.noteLabel), findsNothing);

      noted.dispose();
      range.dispose();
    });

    test('does nothing without a fit', () {
      final bare = RemainKwhFiller(pctCtrl: pct, remainCtrl: remain);
      filler.dispose();
      pct.text = '50';
      expect(remain.text, isEmpty);
      bare.dispose();
    });
  });
}
