/// ObservationTable — battery readings data table.
///
// Time-stamp: <2026-05-04>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:konapod/models/battery_observation.dart';

class ObservationTable extends StatelessWidget {
  final List<BatteryObservation> observations;
  final void Function(BatteryObservation)? onDelete;

  const ObservationTable({
    super.key,
    required this.observations,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM yyyy  HH:mm');
    // Show newest first.
    final rows = observations.reversed.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${observations.length} observation'
                '${observations.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowHeight: 32,
            dataRowMinHeight: 28,
            dataRowMaxHeight: 36,
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('%'), numeric: true),
              DataColumn(label: Text('Range km'), numeric: true),
              DataColumn(label: Text('kWh'), numeric: true),
              DataColumn(label: Text('km/kWh'), numeric: true),
              DataColumn(label: Text('kWh/100km'), numeric: true),
              DataColumn(label: Text('Odo km'), numeric: true),
              DataColumn(label: Text('')),
            ],
            rows: rows.map((o) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      fmt.format(o.timestamp),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.batteryPct.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.rangeKm.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.remainKwh != null
                          ? o.remainKwh!.toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.remainKwh != null && o.remainKwh! > 0
                          ? (o.rangeKm / o.remainKwh!).toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.remainKwh != null && o.rangeKm > 0
                          ? (o.remainKwh! / o.rangeKm * 100).toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.odometerKm != null
                          ? o.odometerKm!.toStringAsFixed(0)
                          : '—',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    onDelete != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete this observation',
                            onPressed: () => onDelete!(o),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── kWh scatter plots (% vs kWh, Range vs kWh) ───────────────────────────────
