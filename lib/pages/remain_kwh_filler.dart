/// RemainKwhFiller — stand an estimate in for a missing kWh reading.
///
// Time-stamp: <Sunday 2026-09-14 10:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/widgets.dart';

import 'package:konapod/services/battery_kwh_estimator.dart';

/// Keeps a battery remaining (kWh) field in step with a battery % field
/// whenever there is no measured kWh to show.
///
/// The car does not always report the energy remaining, and a hand-written
/// entry rarely has it, but battery % and kWh are all but linear — see the
/// % vs kWh plot under Energy — so [BatteryKwhEstimator] fills the gap.
///
/// Only a blank field, or one still holding an earlier estimate, is written
/// to: a figure the user typed or fetched from the car is left alone.

class RemainKwhFiller {
  final TextEditingController pctCtrl;
  final TextEditingController remainCtrl;

  /// Called whenever the field changes between holding an estimate and
  /// holding a reading, so the caller can show or hide the estimated note.
  final VoidCallback? onChanged;

  /// Shown under the field while it holds an estimate.
  static const noteLabel = 'estimated';

  BatteryKwhEstimator? _estimator;

  /// The estimate last written, which is how our own value is told from one
  /// the user typed.
  String? _written;

  RemainKwhFiller({
    required this.pctCtrl,
    required this.remainCtrl,
    this.onChanged,
  }) {
    pctCtrl.addListener(_fill);
    remainCtrl.addListener(_remainEdited);
  }

  /// Whether the field holds an estimate rather than a reading.

  bool get isEstimate => _written != null && remainCtrl.text == _written;

  /// Where the estimate came from, for the note's tooltip.

  String get noteTooltip {
    final est = _estimator;
    if (est == null) return '**Estimated**\n\nNo kWh reading was available.';
    return '**Estimated Energy Remaining**\n\n'
        'No kWh reading was available, so this is estimated from the battery '
        'percentage — a fit over ${est.sampleCount} recorded observations, '
        'about ${est.slope.toStringAsFixed(2)} kWh per 1%.\n\n'
        'Type over it if you have a reading from the car.';
  }

  /// Take up the fit, once the observations have loaded, and fill straight
  /// away.

  set estimator(BatteryKwhEstimator? value) {
    _estimator = value;
    _fill();
  }

  void _fill() {
    final est = _estimator;
    if (est == null) return;
    // 20260914 gjw A reading, from the user or the car, is left as it stands.

    if (remainCtrl.text.trim().isNotEmpty && !isEstimate) return;
    final pct = double.tryParse(pctCtrl.text.trim());
    // 20260914 gjw A cleared or unreadable percentage leaves nothing to
    // estimate from, so take the estimate back out again.

    final text = pct == null ? '' : est.estimate(pct).toStringAsFixed(1);
    if (remainCtrl.text == text) return;
    _written = text.isEmpty ? null : text;
    remainCtrl.text = text;
    onChanged?.call();
  }

  void _remainEdited() {
    // 20260914 gjw An empty field is exactly when the estimate is wanted —
    // whether the user cleared it or a Bluelink fetch found no kWh reading.

    if (remainCtrl.text.trim().isEmpty) {
      if (_written != null) {
        _written = null;
        onChanged?.call();
      }
      _fill();
      return;
    }
    // 20260914 gjw The estimate has been typed over, so it is a reading now.

    if (_written == null || remainCtrl.text == _written) return;
    _written = null;
    onChanged?.call();
  }

  void dispose() {
    pctCtrl.removeListener(_fill);
    remainCtrl.removeListener(_remainEdited);
  }
}
