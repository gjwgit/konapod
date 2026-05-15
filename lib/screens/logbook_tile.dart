/// LogbookTile — entry tile and mini chip for the log book screen.
///
// Time-stamp: <Monday 2026-04-13 16:04:59 +1000 Graham Williams>
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
  final double? prevOdometerKm;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LogEntryTile({
    super.key,
    required this.entry,
    this.prevOdometerKm,
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
                  // Top row: time only (odo moved to title line below).
                  // For charging entries we hide the time here too — it
                  // appears next to the Start row instead.
                  if (!entry.hasChargeData)
                    Text(
                      _fmtTime(entry.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  if (!entry.hasChargeData) const Gap(4),
                  // Title line: title · odo · (+kWh charge added, if any).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (entry.odometerKm != null &&
                          prevOdometerKm != null) ...[
                        Text(
                          '  ·  ',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        Icon(
                          Icons.route_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const Gap(2),
                        Text(
                          'traveled +${(entry.odometerKm! - prevOdometerKm!).toStringAsFixed(0)} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (entry.chargeEnergyKwh != null) ...[
                        Text(
                          '  ·  ',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        Icon(Icons.bolt, size: 12, color: cs.onSurfaceVariant),
                        const Gap(2),
                        Text(
                          'charged +${entry.chargeEnergyKwh!.toStringAsFixed(1)} kWh',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
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
                      time: entry.hasChargeData
                          ? _fmtTime(entry.timestamp)
                          : null,
                      odo: entry.hasChargeData ? null : entry.startOdometerKm,
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
                      time: (entry.hasChargeData &&
                              entry.chargeDurationMinutes != null)
                          ? _fmtTime(
                              entry.timestamp.add(
                                Duration(minutes: entry.chargeDurationMinutes!),
                              ),
                            )
                          : null,
                      odo: entry.hasChargeData ? null : entry.odometerKm,
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
                              ? entry.locationAddress!
                                  .split(',')
                                  .take(3)
                                  .map((s) => s.trim())
                                  .join(', ')
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
                          if (entry.chargeVendor != null ||
                              entry.chargeRateKwh != null)
                            LogMiniChip(
                              Icons.ev_station_outlined,
                              [
                                if (entry.chargeVendor != null)
                                  entry.chargeVendor!,
                                if (entry.chargeRateKwh != null)
                                  '${entry.chargeRateKwh!.toStringAsFixed(1)} kW',
                              ].join(' @ '),
                              cs,
                            ),
                          if (entry.chargeEnergyKwh != null)
                            LogMiniChip(
                              Icons.bolt,
                              '${entry.chargeEnergyKwh!.toStringAsFixed(1)} kWh',
                              cs,
                            ),
                          if (entry.chargeTotalCost != null)
                            LogMiniChip(
                              Icons.attach_money,
                              entry.chargeCostPerKwh != null
                                  ? '${entry.chargeCostPerKwh!.toStringAsFixed(2)}/kWh'
                                      '   =   \$${entry.chargeTotalCost!.toStringAsFixed(2)}'
                                  : entry.chargeTotalCost!.toStringAsFixed(2),
                              cs,
                            ),
                          if (entry.startEvRangeKm != null &&
                              entry.evRangeKm != null)
                            LogMiniChip(
                              Icons.route_outlined,
                              '+${(entry.evRangeKm! - entry.startEvRangeKm!).toStringAsFixed(0)} km',
                              cs,
                            ),
                          if (entry.chargeDurationMinutes != null)
                            LogMiniChip(
                              Icons.timer_outlined,
                              _fmtDuration(entry.chargeDurationMinutes!),
                              cs,
                            ),
                          // km added per hour of charging
                          if (entry.startEvRangeKm != null &&
                              entry.evRangeKm != null &&
                              entry.chargeDurationMinutes != null &&
                              entry.chargeDurationMinutes! > 0)
                            LogMiniChip(
                              Icons.speed_outlined,
                              '${((entry.evRangeKm! - entry.startEvRangeKm!) / (entry.chargeDurationMinutes! / 60)).toStringAsFixed(0)} km/h',
                              cs,
                            ),
                          // cost per km added
                          if (entry.chargeTotalCost != null &&
                              entry.startEvRangeKm != null &&
                              entry.evRangeKm != null &&
                              (entry.evRangeKm! - entry.startEvRangeKm!) > 0)
                            LogMiniChip(
                              Icons.attach_money,
                              '${(entry.chargeTotalCost! / (entry.evRangeKm! - entry.startEvRangeKm!)).toStringAsFixed(3)}/km',
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
  final String? time;
  final double? odo;
  final double? batt;
  final double? remain;
  final double? range;
  final ColorScheme cs;

  const _ReadingRow({
    required this.label,
    this.time,
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
          if (time != null) ...[
            Text(
              time!,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const Gap(10),
          ],
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
