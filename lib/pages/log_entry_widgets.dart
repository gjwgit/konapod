/// LogEntryWidgets — vehicle readings and location display widgets.
///
// Time-stamp: <Friday 2026-03-27 18:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

// ── Vehicle readings display ──────────────────────────────────────────────────

class LogReadingsRow extends StatelessWidget {
  final double? batteryLevel;
  final double? evRange;
  final double? batteryRemainKwh;
  final ColorScheme cs;

  const LogReadingsRow({
    super.key,
    required this.batteryLevel,
    required this.evRange,
    required this.batteryRemainKwh,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (batteryLevel == null && evRange == null && batteryRemainKwh == null) {
      return Text(
        'No live vehicle data — connect to Bluelink for auto-fill.',
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (batteryLevel != null)
          LogReadingChip(
            icon: Icons.battery_charging_full,
            label: '${batteryLevel!.toStringAsFixed(0)}%',
            hint: 'Battery',
            cs: cs,
          ),
        if (batteryRemainKwh != null)
          LogReadingChip(
            icon: Icons.bolt,
            label: '${(batteryRemainKwh! / 3600).toStringAsFixed(1)} kWh',
            hint: 'Remaining (kJ÷3600)',
            cs: cs,
          ),
        if (evRange != null)
          LogReadingChip(
            icon: Icons.route_outlined,
            label: '${evRange!.toStringAsFixed(0)} km',
            hint: 'EV Range',
            cs: cs,
          ),
      ],
    );
  }
}

// ── Reading chip ──────────────────────────────────────────────────────────────

class LogReadingChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final ColorScheme cs;

  const LogReadingChip({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: hint,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
}

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

  const LogSectionLabel(this.text, this.cs);

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
