/// LogChargeSection — self-contained charging session form widget.
///
// Time-stamp: <Friday 2026-03-28 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/widgets/labeled_value_field.dart';

/// Holds the values read from a [LogChargeSection].

class ChargeValues {
  final String? vendor;
  final double? energyKwh;
  final double? rateKwh;
  final int? durationMinutes;
  final double? costPerKwh;
  final double? totalCost;

  const ChargeValues({
    this.vendor,
    this.energyKwh,
    this.rateKwh,
    this.durationMinutes,
    this.costPerKwh,
    this.totalCost,
  });

  bool get isEmpty =>
      vendor == null &&
      energyKwh == null &&
      rateKwh == null &&
      durationMinutes == null &&
      costPerKwh == null &&
      totalCost == null;
}

/// A self-contained charging session form.
///
/// Access current values via [LogChargeSectionState.currentValues] through
/// a [GlobalKey]:
///
/// ```dart
/// final _chargeKey = GlobalKey<LogChargeSectionState>();
/// // In build:
/// LogChargeSection(key: _chargeKey, entry: existingEntry)
/// // On save:
/// final charge = _chargeKey.currentState!.currentValues;
/// ```

class LogChargeSection extends StatefulWidget {
  /// Existing entry to pre-populate fields, if editing.
  final LogEntry? entry;

  /// Optional widget rendered inside the charging section (below the charge
  /// fields) when the charging toggle is on. Used by the parent to inject
  /// the end vehicle readings + Fetch from Bluelink button.
  final Widget? endReadingsContent;

  /// Optional controller holding the start battery remaining value (in kWh,
  /// as a text string). When provided together with [endRemainCtrl], the
  /// total cost field is auto-recalculated as
  /// `(endRemain − startRemain) × costPerKwh` whenever any of those three
  /// inputs change.
  final TextEditingController? startRemainCtrl;

  /// Optional controller holding the end battery remaining value (in kWh).
  /// See [startRemainCtrl] for behaviour.
  final TextEditingController? endRemainCtrl;

  const LogChargeSection({
    super.key,
    this.entry,
    this.endReadingsContent,
    this.startRemainCtrl,
    this.endRemainCtrl,
  });

  @override
  State<LogChargeSection> createState() => LogChargeSectionState();
}

class LogChargeSectionState extends State<LogChargeSection> {
  late bool _showCharge;
  late final TextEditingController _vendor;
  late final TextEditingController _energy;
  late final TextEditingController _rate;
  late final TextEditingController _durationHours;
  late final TextEditingController _durationMinutes;
  late final TextEditingController _costPerKwh;
  late final TextEditingController _totalCost;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _showCharge = e?.hasChargeData ?? false;
    _vendor = TextEditingController(text: e?.chargeVendor ?? '');
    _energy = TextEditingController(
      text: e?.chargeEnergyKwh?.toStringAsFixed(1) ?? '',
    );
    _rate = TextEditingController(
      text: e?.chargeRateKwh?.toStringAsFixed(1) ?? '',
    );
    // Duration is stored as a single integer (minutes) but edited as two
    // fields: hours and minutes. Split on init, combine on read.
    final mins = e?.chargeDurationMinutes;
    _durationHours = TextEditingController(
      text: mins == null ? '' : (mins ~/ 60).toString(),
    );
    _durationMinutes = TextEditingController(
      text: mins == null ? '' : (mins % 60).toString(),
    );
    _costPerKwh = TextEditingController(
      text: e?.chargeCostPerKwh?.toStringAsFixed(2) ?? '',
    );
    _totalCost = TextEditingController(
      text: e?.chargeTotalCost?.toStringAsFixed(2) ?? '',
    );

    // Auto-recalc total cost when cost/kWh or either remain value changes.
    _costPerKwh.addListener(_recalcTotalCost);
    widget.startRemainCtrl?.addListener(_recalcTotalCost);
    widget.endRemainCtrl?.addListener(_recalcTotalCost);
  }

  @override
  void dispose() {
    _costPerKwh.removeListener(_recalcTotalCost);
    widget.startRemainCtrl?.removeListener(_recalcTotalCost);
    widget.endRemainCtrl?.removeListener(_recalcTotalCost);
    _vendor.dispose();
    _energy.dispose();
    _rate.dispose();
    _durationHours.dispose();
    _durationMinutes.dispose();
    _costPerKwh.dispose();
    _totalCost.dispose();
    super.dispose();
  }

  /// Combine the hours and minutes fields back into a single minute count.
  /// Returns null when both fields are blank; treats blank fields in one
  /// half as zero (so "2h" with empty minutes is 120 min, and ":30m" with
  /// empty hours is 30 min).
  int? _readDurationMinutes() {
    final hStr = _durationHours.text.trim();
    final mStr = _durationMinutes.text.trim();
    if (hStr.isEmpty && mStr.isEmpty) return null;
    final h = int.tryParse(hStr) ?? 0;
    final m = int.tryParse(mStr) ?? 0;
    return h * 60 + m;
  }

  /// Recalculate total cost from delta charge × cost/kWh and update the
  /// total cost field. Only fires when all three inputs are present and
  /// the resulting delta is positive.

  void _recalcTotalCost() {
    final costPerKwh = double.tryParse(_costPerKwh.text.trim());
    if (costPerKwh == null || costPerKwh <= 0) return;

    final startRemain = double.tryParse(
      widget.startRemainCtrl?.text.trim() ?? '',
    );
    final endRemain = double.tryParse(
      widget.endRemainCtrl?.text.trim() ?? '',
    );
    if (startRemain == null || endRemain == null) return;

    final delta = endRemain - startRemain;
    if (delta <= 0) return;

    final newTotal = (delta * costPerKwh).toStringAsFixed(2);
    if (_totalCost.text != newTotal) {
      _totalCost.text = newTotal;
    }
  }

  /// Read current values from the form. Returns null fields for empty inputs.

  ChargeValues get currentValues {
    if (!_showCharge) return const ChargeValues();
    return ChargeValues(
      vendor: _vendor.text.trim().isEmpty ? null : _vendor.text.trim(),
      energyKwh: double.tryParse(_energy.text.trim()),
      rateKwh: double.tryParse(_rate.text.trim()),
      durationMinutes: _readDurationMinutes(),
      costPerKwh: double.tryParse(_costPerKwh.text.trim()),
      totalCost: double.tryParse(_totalCost.text.trim()),
    );
  }

  /// Populate derived fields calculated from Bluelink end-of-charge data.

  void populateFromBluelink({
    required int durationMinutes,
    double? energyKwh,
    double? totalCost,
  }) {
    _durationHours.text = (durationMinutes ~/ 60).toString();
    _durationMinutes.text = (durationMinutes % 60).toString();
    if (energyKwh != null) _energy.text = energyKwh.toStringAsFixed(1);
    if (totalCost != null) _totalCost.text = totalCost.toStringAsFixed(2);
  }

  /// Current cost per kWh entered by the user (for use by parent).

  double? get costPerKwh => double.tryParse(_costPerKwh.text.trim());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle row
        Row(
          children: [
            _Label('Charging Session', cs),
            const Spacer(),
            Switch(
              value: _showCharge,
              onChanged: (v) => setState(() => _showCharge = v),
            ),
          ],
        ),
        if (_showCharge) ...[
          // End vehicle readings — injected by parent, shown first
          if (widget.endReadingsContent != null) widget.endReadingsContent!,
          const Gap(12),
          _Label('Charging Details', Theme.of(context).colorScheme),
          const Gap(8),
          // Vendor
          TextField(
            controller: _vendor,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              labelText: 'Vendor / Network',
              hintText: 'e.g. Chargefox, NRMA, Tesla',
              prefixIcon: Icon(Icons.store_outlined, size: 18),
            ),
          ),
          const Gap(10),
          // Energy + Rate
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: LabeledValueField(
                  labelText: 'Energy delivered',
                  unit: 'kWh',
                  controller: _energy,
                ),
              ),
              const Gap(16),
              Flexible(
                child: LabeledValueField(
                  labelText: 'Charge rate',
                  unit: 'kW',
                  controller: _rate,
                ),
              ),
            ],
          ),
          const Gap(10),
          // Duration (split into hours + minutes) + Cost per kWh
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LabeledValueField(
                      labelText: 'Duration',
                      unit: 'h',
                      controller: _durationHours,
                      keyboardType: TextInputType.number,
                      fieldWidth: 56,
                    ),
                    const Gap(8),
                    LabeledValueField(
                      labelText: ' ',
                      unit: 'm',
                      controller: _durationMinutes,
                      keyboardType: TextInputType.number,
                      fieldWidth: 56,
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Expanded(
                child: TextField(
                  controller: _costPerKwh,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    labelText: 'Cost per kWh',
                    prefixText: r'$ ',
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          // Total cost
          TextField(
            controller: _totalCost,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              labelText: 'Total cost',
              prefixText: r'$ ',
            ),
          ),
        ],
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const _Label(this.text, this.cs);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      );
}
