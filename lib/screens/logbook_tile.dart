/// LogbookTile — entry tile and mini chip for the log book screen.
///
// Time-stamp: <Sunday 2026-04-05 09:58:48 +1000 Graham Williams>
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

// ── Entry tile ────────────────────────────────────────────────────────────────

class LogEntryTile extends StatelessWidget {
  final LogEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LogEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date column
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Text(
                    entry.timestamp.day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    _monthAbbr(entry.timestamp.month),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    entry.timestamp.year.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            // Divider line
            Container(
              width: 2,
              height: 56,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const Gap(12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _fmtTime(entry.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (entry.odometerKm != null) ...[
                        Text(
                          '  ·  ',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        Icon(
                          Icons.speed_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const Gap(2),
                        Text(
                          '${entry.odometerKm!.toStringAsFixed(0)} km',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(4),
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const Gap(2),
                    Text(
                      entry.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  // Start readings row
                  if (entry.hasStartReadings) ...[
                    const Gap(6),
                    _ReadingRow(
                      label: 'Start',
                      odo: entry.startOdometerKm,
                      batt: entry.startBatteryLevelPercent,
                      remain: entry.startBatteryRemainKwh,
                      range: entry.startEvRangeKm,
                      cs: cs,
                    ),
                  ],
                  // End readings row
                  if (entry.hasEndReadings) ...[
                    const Gap(4),
                    _ReadingRow(
                      label: 'End',
                      odo: entry.odometerKm,
                      batt: entry.batteryLevelPercent,
                      remain: entry.batteryRemainKwh,
                      range: entry.evRangeKm,
                      cs: cs,
                    ),
                  ],
                  // Location chip
                  if (entry.latitude != null && entry.longitude != null) ...[
                    const Gap(4),
                    Wrap(
                      children: [
                        LogMiniChip(
                          Icons.location_on_outlined,
                          entry.locationAddress?.isNotEmpty == true
                              ? entry.locationAddress!.split(',').first
                              : '${entry.latitude!.toStringAsFixed(3)}, '
                                  '${entry.longitude!.toStringAsFixed(3)}',
                          cs,
                        ),
                      ],
                    ),
                  ],
                  // Charging summary row
                  if (entry.hasChargeData) ...[
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          if (entry.chargeVendor != null)
                            LogMiniChip(
                              Icons.ev_station_outlined,
                              entry.chargeVendor!,
                              cs,
                            ),
                          if (entry.chargeEnergyKwh != null)
                            LogMiniChip(
                              Icons.speed,
                              '${entry.chargeEnergyKwh!.toStringAsFixed(1)} kWh',
                              cs,
                            ),
                          if (entry.chargeRateKwh != null)
                            LogMiniChip(
                              Icons.bolt,
                              '${entry.chargeRateKwh!.toStringAsFixed(1)} kW',
                              cs,
                            ),
                          if (entry.chargeDurationMinutes != null)
                            LogMiniChip(
                              Icons.timer_outlined,
                              _fmtDuration(entry.chargeDurationMinutes!),
                              cs,
                            ),
                          if (entry.chargeTotalCost != null)
                            LogMiniChip(
                              Icons.attach_money,
                              entry.chargeTotalCost!.toStringAsFixed(2),
                              cs,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  String _monthAbbr(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m];
}

class LogMiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const LogMiniChip(this.icon, this.label, this.cs, {super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.onSurfaceVariant),
          const Gap(2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      );
}

// ── Reading row (start or end) ────────────────────────────────────────────────

class _ReadingRow extends StatelessWidget {
  final String label;
  final double? odo;
  final double? batt;
  final double? remain;
  final double? range;
  final ColorScheme cs;

  const _ReadingRow({
    required this.label,
    required this.odo,
    required this.batt,
    required this.remain,
    required this.range,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 10,
              children: [
                if (odo != null)
                  LogMiniChip(
                    Icons.speed_outlined,
                    '${odo!.toStringAsFixed(0)} km',
                    cs,
                  ),
                if (batt != null)
                  LogMiniChip(
                    Icons.battery_charging_full,
                    '${batt!.toStringAsFixed(0)}%',
                    cs,
                  ),
                if (remain != null)
                  LogMiniChip(
                    Icons.bolt,
                    '${(remain! / 3600).toStringAsFixed(1)} kWh',
                    cs,
                  ),
                if (range != null)
                  LogMiniChip(
                    Icons.route_outlined,
                    '${range!.toStringAsFixed(0)} km',
                    cs,
                  ),
              ],
            ),
          ),
        ],
      );
}
