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
import 'package:konapod/screens/logbook_tile.dart';
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
      body: provider.logLoading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? LogEmptyState(
                  cs: cs,
                  onAdd: () => _addEntry(context, provider),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) => LogEntryTile(
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

class LogEmptyState extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onAdd;

  const LogEmptyState({super.key, required this.cs, required this.onAdd});

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
