/// LogbookScreen — view, add and manage vehicle log book entries.
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
import 'package:provider/provider.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/pages/log_entry_edit.dart';
import 'package:konapod/services/app_provider.dart';
import 'package:konapod/theme/hyundai_theme.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  @override
  void initState() {
    super.initState();
    // Load log entries from pod when the screen is first shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadLogFromPod();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = provider.logEntries;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: entries.isEmpty
          ? _EmptyState(cs: cs, onAdd: () => _addEntry(context, provider))
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) => _EntryTile(
                entry: entries[i],
                onTap: () => _editEntry(context, entries[i], provider),
                onDelete: () => _deleteEntry(context, entries[i], provider),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEntry(context, provider),
        tooltip: 'New log entry',
        backgroundColor: HyundaiColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _addEntry(
    BuildContext context,
    AppProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final entry = await showDialog<LogEntry>(
      context: context,
      builder: (_) => LogEntryEdit(vehicle: provider.selectedVehicle),
    );
    if (entry != null) {
      provider.addLogEntry(entry);
      await provider.saveLogToPod();
      messenger.showSnackBar(
        const SnackBar(content: Text('Log entry saved.')),
      );
    }
  }

  Future<void> _editEntry(
    BuildContext context,
    LogEntry entry,
    AppProvider provider,
  ) async {
    final updated = await showDialog<LogEntry>(
      context: context,
      builder: (_) => LogEntryEdit(
        entry: entry,
        vehicle: provider.selectedVehicle,
      ),
    );
    if (updated != null) {
      provider.updateLogEntry(updated);
      await provider.saveLogToPod();
    }
  }

  void _deleteEntry(
    BuildContext context,
    LogEntry entry,
    AppProvider provider,
  ) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          'Delete "${entry.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        provider.deleteLogEntry(entry.id);
        provider.saveLogToPod();
      }
    });
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onAdd;

  const _EmptyState({required this.cs, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 64,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const Gap(16),
              const Text(
                'No log entries yet',
                style: TextStyle(fontSize: 16),
              ),
              const Gap(8),
              Text(
                'Tap + to record a service, charge, trip or note.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const Gap(24),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add first entry'),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      );
}

// ── Entry tile ────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  final LogEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntryTile({
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
                  // Battery readings row
                  if (_hasReadings(entry)) ...[
                    const Gap(6),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (entry.batteryLevelPercent != null)
                          _MiniChip(
                            Icons.battery_charging_full,
                            '${entry.batteryLevelPercent!.toStringAsFixed(0)}%',
                            cs,
                          ),
                        if (entry.batteryRemainKwh != null)
                          _MiniChip(
                            Icons.bolt,
                            '${(entry.batteryRemainKwh! / 3600).toStringAsFixed(1)} kWh',
                            cs,
                          ),
                        if (entry.evRangeKm != null)
                          _MiniChip(
                            Icons.route_outlined,
                            '${entry.evRangeKm!.toStringAsFixed(0)} km',
                            cs,
                          ),
                        if (entry.latitude != null && entry.longitude != null)
                          _MiniChip(
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

  bool _hasReadings(LogEntry e) =>
      e.batteryLevelPercent != null ||
      e.batteryRemainKwh != null ||
      e.evRangeKm != null ||
      e.latitude != null;

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

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _MiniChip(this.icon, this.label, this.cs);

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
