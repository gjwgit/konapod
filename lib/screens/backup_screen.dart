/// BackupScreen — full Pod data backup (export) and restore (import).
///
/// Export writes a single JSON file containing every konapod data file.
/// Import reads such a file back and restores all data to the Pod.
///
// Time-stamp: <2026-06-09>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:solidpod/solidpod.dart' show getWebId;

import 'package:konapod/services/app_provider.dart';
import 'package:konapod/services/backup_service.dart';
import 'package:konapod/theme/hyundai_theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _status;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      final webId = await getWebId();
      if (mounted) {
        setState(() => _loggedIn = webId != null && webId.isNotEmpty);
      }
    } catch (_) {
      if (mounted) setState(() => _loggedIn = false);
    }
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _status = 'Reading data from your Pod…';
    });
    try {
      final json = await BackupService.exportAll();

      if (kIsWeb) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup not supported on web.')),
        );
        return;
      }

      final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save konapod backup',
        fileName: 'konapod-backup-$stamp.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (savePath == null) {
        setState(() => _status = null);
        return;
      }
      await File(savePath).writeAsBytes(utf8.encode(json));
      if (!mounted) return;
      setState(() => _status = 'Backup saved to $savePath');
      messenger.showSnackBar(SnackBar(content: Text('Saved to $savePath')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Export failed: $e');
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);

    // Restoring overwrites Pod data — confirm first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'This will write the backup\'s data to your Pod, overwriting any '
          'files with the same name. This cannot be undone.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _status = 'Selecting backup file…';
    });
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select konapod backup JSON',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _status = null);
        return;
      }
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (!mounted) return;
        setState(() => _status = 'Could not read file.');
        return;
      }

      setState(() => _status = 'Restoring data to your Pod…');
      final res = await BackupService.importAll(utf8.decode(bytes));

      if (!mounted) return;
      if (res.error != null) {
        setState(() => _status = res.error);
        messenger.showSnackBar(SnackBar(content: Text(res.error!)));
      } else {
        // Reload data so the rest of the app reflects the restore.
        if (mounted) {
          await context.read<AppProvider>().loadFromPod();
        }
        final msg = res.failed == 0
            ? 'Restored ${res.restored} files successfully.'
            : 'Restored ${res.restored} files, ${res.failed} failed.';
        if (!mounted) return;
        setState(() => _status = msg);
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Import failed: $e');
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _loggedIn;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup & Restore',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Export all of your konapod Pod data to a single JSON file you '
            'can keep as a backup, then import it later to restore '
            'everything — status snapshots, log book and battery records.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (!loggedIn)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HyundaiColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'You need to be logged in to your Pod to back up or restore.',
              ),
            ),
          if (!loggedIn) const SizedBox(height: 16),
          Row(
            children: [
              MarkdownTooltip(
                message: '**Export**\n\n'
                    'Read all data from your Pod and save it to a JSON '
                    'backup file on this device.',
                child: FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export backup'),
                  onPressed: (_busy || !loggedIn) ? null : _export,
                ),
              ),
              const SizedBox(width: 12),
              MarkdownTooltip(
                message: '**Import**\n\n'
                    'Restore Pod data from a previously saved JSON backup '
                    'file. Overwrites files of the same name.',
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Import backup'),
                  onPressed: (_busy || !loggedIn) ? null : _import,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_busy)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Working…'),
              ],
            ),
          if (_status != null && !_busy)
            Text(
              _status!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
