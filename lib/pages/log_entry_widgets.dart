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
                    Text(
                      address!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  Text(
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

  const LogReadingsGrid({
    super.key,
    required this.odoCtrl,
    required this.battCtrl,
    required this.remainCtrl,
    required this.rangeCtrl,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // First row: odo + battery (or just battery if no odo)
          Row(
            children: [
              if (odoCtrl != null) ...[
                Expanded(
                  child: TextField(
                    controller: odoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Odometer',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'km',
                    ),
                  ),
                ),
                const Gap(8),
              ],
              Expanded(
                child: TextField(
                  controller: battCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Battery',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: '%',
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          // Second row: remaining + range
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: remainCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Remaining',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'kWh',
                  ),
                ),
              ),
              const Gap(8),
              Expanded(
                child: TextField(
                  controller: rangeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'EV Range',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'km',
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}
