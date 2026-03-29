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

  const LogChargeSection({super.key, this.entry});

  @override
  State<LogChargeSection> createState() => LogChargeSectionState();
}

class LogChargeSectionState extends State<LogChargeSection> {
  late bool _showCharge;
  late final TextEditingController _vendor;
  late final TextEditingController _energy;
  late final TextEditingController _rate;
  late final TextEditingController _duration;
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
    _duration = TextEditingController(
      text: e?.chargeDurationMinutes?.toString() ?? '',
    );
    _costPerKwh = TextEditingController(
      text: e?.chargeCostPerKwh?.toStringAsFixed(4) ?? '',
    );
    _totalCost = TextEditingController(
      text: e?.chargeTotalCost?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _vendor.dispose();
    _energy.dispose();
    _rate.dispose();
    _duration.dispose();
    _costPerKwh.dispose();
    _totalCost.dispose();
    super.dispose();
  }

  /// Read current values from the form. Returns null fields for empty inputs.

  ChargeValues get currentValues {
    if (!_showCharge) return const ChargeValues();
    return ChargeValues(
      vendor: _vendor.text.trim().isEmpty ? null : _vendor.text.trim(),
      energyKwh: double.tryParse(_energy.text.trim()),
      rateKwh: double.tryParse(_rate.text.trim()),
      durationMinutes: int.tryParse(_duration.text.trim()),
      costPerKwh: double.tryParse(_costPerKwh.text.trim()),
      totalCost: double.tryParse(_totalCost.text.trim()),
    );
  }

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
            children: [
              Expanded(
                child: TextField(
                  controller: _energy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    labelText: 'Energy delivered',
                    suffixText: 'kWh',
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: TextField(
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    labelText: 'Charge rate',
                    suffixText: 'kW',
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          // Duration + Cost per kWh
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    labelText: 'Duration',
                    suffixText: 'min',
                  ),
                ),
              ),
              const Gap(10),
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
