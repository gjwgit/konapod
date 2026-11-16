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
import 'package:konapod/pages/log_finish_time_field.dart';
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
  /// inputs change — but only while the energy delivered field is blank,
  /// since that field takes precedence as the energy figure.
  final TextEditingController? startRemainCtrl;

  /// Optional controller holding the end battery remaining value (in kWh).
  /// See [startRemainCtrl] for behaviour.
  final TextEditingController? endRemainCtrl;

  /// When the entry starts — the editor's date and time. The finish time is
  /// this plus the duration, so editing the finish time sets the duration.
  /// Passed in rather than read from [entry] because the editor lets the
  /// user change it.
  final DateTime startTimestamp;

  const LogChargeSection({
    super.key,
    this.entry,
    this.endReadingsContent,
    this.startRemainCtrl,
    this.endRemainCtrl,
    required this.startTimestamp,
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

  /// The average charge rate, worked out by [_recalcAvgRate] and not saved.
  final _avgRate = TextEditingController();

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

    // Auto-recalc total cost when the energy delivered, the cost/kWh, or
    // either remain value changes.
    _energy.addListener(_recalcTotalCost);
    _costPerKwh.addListener(_recalcTotalCost);
    widget.startRemainCtrl?.addListener(_recalcTotalCost);
    widget.endRemainCtrl?.addListener(_recalcTotalCost);

    // The finish time is displayed beside the duration, so it has to be
    // redrawn whenever the duration is edited.
    _durationHours.addListener(_durationChanged);
    _durationMinutes.addListener(_durationChanged);

    // 20261116 gjw Keep the average charge rate up to date with the energy
    // charged and the duration it took.

    for (final c in _avgRateInputs) {
      c?.addListener(_recalcAvgRate);
    }
    _recalcAvgRate();
  }

  /// The fields the average charge rate is worked out from.

  List<Listenable?> get _avgRateInputs => [
        _energy,
        _durationHours,
        _durationMinutes,
        widget.startRemainCtrl,
        widget.endRemainCtrl,
      ];

  @override
  void dispose() {
    for (final c in _avgRateInputs) {
      c?.removeListener(_recalcAvgRate);
    }
    _energy.removeListener(_recalcTotalCost);
    _costPerKwh.removeListener(_recalcTotalCost);
    widget.startRemainCtrl?.removeListener(_recalcTotalCost);
    widget.endRemainCtrl?.removeListener(_recalcTotalCost);
    _durationHours.removeListener(_durationChanged);
    _durationMinutes.removeListener(_durationChanged);
    _vendor.dispose();
    _energy.dispose();
    _rate.dispose();
    _durationHours.dispose();
    _durationMinutes.dispose();
    _costPerKwh.dispose();
    _totalCost.dispose();
    _avgRate.dispose();
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

  void _durationChanged() {
    if (mounted) setState(() {});
  }

  /// When the charge finished — the entry's date and time plus the duration
  /// — or null while the duration is blank.

  DateTime? get _finish {
    final mins = _readDurationMinutes();
    return mins == null
        ? null
        : widget.startTimestamp.add(Duration(minutes: mins));
  }

  /// Pick the finish date and time, and store the result as a duration. A
  /// finish before the start becomes a zero duration rather than a negative
  /// one.

  Future<void> _pickFinish() async {
    final start = widget.startTimestamp;
    final initial = _finish ?? start;
    var lastDate = DateTime.now().add(const Duration(days: 1));
    // A long duration can already put the finish beyond tomorrow, and the
    // date picker requires the initial date to be within its range.
    if (initial.isAfter(lastDate)) lastDate = initial;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(start.year, start.month, start.day),
      lastDate: lastDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final mins =
        DateTime(date.year, date.month, date.day, time.hour, time.minute)
            .difference(start)
            .inMinutes
            .clamp(0, 9999);
    // Writing the controllers fires [_durationChanged], which redraws the
    // finish time.
    _durationHours.text = (mins ~/ 60).toString();
    _durationMinutes.text = (mins % 60).toString();
  }

  /// Recalculate total cost from energy delivered × cost/kWh and update the
  /// total cost field. The energy delivered field is the energy figure; when
  /// it is blank the battery remaining delta stands in for it. Only fires
  /// when both inputs are present and the energy is positive.

  void _recalcTotalCost() {
    final costPerKwh = double.tryParse(_costPerKwh.text.trim());
    if (costPerKwh == null || costPerKwh <= 0) return;

    final energy = _energyKwh;
    if (energy == null || energy <= 0) return;

    final newTotal = (energy * costPerKwh).toStringAsFixed(2);
    if (_totalCost.text != newTotal) {
      _totalCost.text = newTotal;
    }
  }

  /// The energy charged: the energy delivered field, or while that is blank
  /// the battery remaining delta. Null when neither is known.
  ///
  /// 20261116 gjw Shared by the total cost and the average charge rate so
  /// the two always work from the same figure.

  double? get _energyKwh {
    final delivered = double.tryParse(_energy.text.trim());
    if (delivered != null) return delivered;
    final startRemain = double.tryParse(
      widget.startRemainCtrl?.text.trim() ?? '',
    );
    final endRemain = double.tryParse(widget.endRemainCtrl?.text.trim() ?? '');
    if (startRemain == null || endRemain == null) return null;
    return endRemain - startRemain;
  }

  /// Work out the average charge rate as the energy charged over the
  /// duration, left blank until both are known and positive.

  void _recalcAvgRate() {
    final energy = _energyKwh;
    final mins = _readDurationMinutes();
    _avgRate.text = (energy == null || energy <= 0 || mins == null || mins == 0)
        ? ''
        : (energy * 60 / mins).toStringAsFixed(1);
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
          // Rate + Energy
          //
          // 20261116 gjw The rate comes first: it is the charger's setting,
          // and the energy delivered is the outcome of charging at it. It is
          // the maximum rate; the average follows the energy.
          //
          // 20261116 gjw The average charge rate, worked out from the energy
          // charged and the duration, ends the line. A Wrap rather than a
          // Row so that on a narrow window it drops to the next line instead
          // of overflowing.

          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              LabeledValueField(
                labelText: 'Max charge rate',
                unit: 'kW',
                controller: _rate,
              ),
              LabeledValueField(
                labelText: 'Energy delivered',
                unit: 'kWh',
                controller: _energy,
              ),
              LabeledValueField(
                labelText: 'Average charge rate',
                unit: 'kW',
                controller: _avgRate,
                readOnly: true,
                note: 'calculated',
                noteTooltip: '**Average Charge Rate**\n\n'
                    'The energy delivered divided by the duration, or the '
                    'rise in battery remaining while energy delivered is '
                    'blank. It is worked out each time and not saved.',
              ),
            ],
          ),
          const Gap(10),
          // The finish time + the duration (split into hours + minutes) it
          // implies, either of which can be edited to set the other.
          //
          // 20261116 gjw The finish time now comes first, then the duration.

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LogFinishTimeField(
                  finish: _finish,
                  onTap: _pickFinish,
                ),
              ),
              const Gap(16),
              Row(
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
            ],
          ),
          const Gap(10),
          // Cost per kWh + total cost
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Gap(16),
              Expanded(
                child: TextField(
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
              ),
            ],
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
