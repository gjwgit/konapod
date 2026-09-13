/// BatteryKwhEstimator — battery energy remaining from a battery percent.
///
// Time-stamp: <Sunday 2026-09-14 10:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:math';

import 'package:konapod/models/battery_observation.dart';

/// A least-squares fit of battery energy remaining (kWh) against battery
/// state of charge (%) over the recorded observations.
///
/// The two are all but linear — the % vs kWh plot under Energy is a straight
/// line — so a fit over past readings stands in for a kWh figure the car
/// never reported.

class BatteryKwhEstimator {
  /// Energy per one percent of charge.
  final double slope;

  /// Fitted energy at 0%. Small, and non-zero only because the fit follows
  /// the observed range rather than being forced through the origin.
  final double intercept;

  /// How many observations the fit is over.
  final int sampleCount;

  const BatteryKwhEstimator({
    required this.slope,
    required this.intercept,
    required this.sampleCount,
  });

  /// Fewer readings than this, or a narrower span of battery percentages,
  /// and the slope is not worth trusting.

  static const _minSamples = 5;
  static const _minPctSpan = 15.0;

  /// Fit over every observation carrying a kWh reading, or null when there
  /// is too little data to fit.

  static BatteryKwhEstimator? fit(List<BatteryObservation> observations) {
    final pts = observations.where((o) => o.remainKwh != null).toList();
    if (pts.length < _minSamples) return null;

    final xs = pts.map((o) => o.batteryPct).toList();
    final ys = pts.map((o) => o.remainKwh!).toList();
    if (xs.reduce(max) - xs.reduce(min) < _minPctSpan) return null;

    final n = pts.length;
    final sx = xs.reduce((a, b) => a + b);
    final sy = ys.reduce((a, b) => a + b);
    final sxy = List.generate(n, (i) => xs[i] * ys[i]).reduce((a, b) => a + b);
    final sx2 = xs.map((x) => x * x).reduce((a, b) => a + b);

    final denom = n * sx2 - sx * sx;
    if (denom == 0) return null;
    final slope = (n * sxy - sx * sy) / denom;
    // 20260914 gjw A flat or falling line means the readings disagree with
    // physics; no estimate is better than a wrong one.

    if (!slope.isFinite || slope <= 0) return null;

    return BatteryKwhEstimator(
      slope: slope,
      intercept: (sy - slope * sx) / n,
      sampleCount: n,
    );
  }

  /// Energy remaining at [batteryPct], never negative.

  double estimate(double batteryPct) =>
      max(0.0, slope * batteryPct + intercept);
}
