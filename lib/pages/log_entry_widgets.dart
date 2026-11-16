/// LogEntryWidgets — vehicle readings and location display widgets.
///
// Time-stamp: <Thursday 2026-04-02 16:41:55 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:konapod/pages/remain_kwh_filler.dart';
import 'package:konapod/widgets/labeled_value_field.dart';

// ── Location display ──────────────────────────────────────────────────────────

class LogLocationDisplay extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final ColorScheme cs;

  const LogLocationDisplay({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: cs.primary),
            const Gap(8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (address != null && address!.isNotEmpty)
                    SelectableText(
                      address!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  SelectableText(
                    '${latitude.toStringAsFixed(5)}, '
                    '${longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Section label ─────────────────────────────────────────────────────────────

class LogSectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const LogSectionLabel(this.text, this.cs, {super.key});

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

// ── Readings grid (odometer + battery + remaining + range) ───────────────────

class LogReadingsGrid extends StatelessWidget {
  final TextEditingController? odoCtrl;
  final TextEditingController battCtrl;
  final TextEditingController remainCtrl;
  final TextEditingController rangeCtrl;

  /// Fills the kWh field from the battery % where the car reported no kWh
  /// reading. Null when no estimate is on offer.
  final RemainKwhFiller? remainFiller;

  const LogReadingsGrid({
    super.key,
    required this.odoCtrl,
    required this.battCtrl,
    required this.remainCtrl,
    required this.rangeCtrl,
    this.remainFiller,
  });

  /// Width of each input box: narrower than the default so all four
  /// readings fit across the editor on one line.

  static const _fieldWidth = 80.0;

  // 20261116 gjw All four readings on a single line rather than two rows of
  // two. A Wrap rather than a Row so that on a narrow window the later
  // readings drop to the next line instead of overflowing.

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (odoCtrl != null)
            LabeledValueField(
              labelText: 'Odometer',
              unit: 'km',
              controller: odoCtrl!,
              keyboardType: TextInputType.number,
              fieldWidth: _fieldWidth,
            ),
          LabeledValueField(
            labelText: 'Battery',
            unit: '%',
            controller: battCtrl,
            fieldWidth: _fieldWidth,
          ),
          LabeledValueField(
            labelText: 'EV Range',
            unit: 'km',
            controller: rangeCtrl,
            fieldWidth: _fieldWidth,
          ),
          LabeledValueField(
            labelText: 'Remaining',
            unit: 'kWh',
            controller: remainCtrl,
            fieldWidth: _fieldWidth,
            note: remainFiller != null && remainFiller!.isEstimate
                ? RemainKwhFiller.noteLabel
                : null,
            noteTooltip: remainFiller?.noteTooltip,
          ),
        ],
      );
}
