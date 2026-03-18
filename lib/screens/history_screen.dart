/// History screen: browse, load and delete Solid Pod snapshots.
///
// Time-stamp: <Monday 2026-03-16 22:01:12 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Claude, Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:konapod/services/app_provider.dart';
import 'package:konapod/services/pod_service.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/utils/pod_utils.dart';

/// History screen — browse, load, and delete archived snapshots from the pod.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _files = [];
  bool _loading = true;
  String? _error;
  String? _deleting; // filename currently being deleted

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final files = await PodService.listStatusFiles();
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load history: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadFile(String filename) async {
    final provider = context.read<AppProvider>();
    final ok = await provider.loadPodFile(filename);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded $filename'),
          backgroundColor: HyundaiColors.success,
        ),
      );
    }
  }

  Future<void> _confirmDelete(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete snapshot?'),
        content: Text(
          'This will permanently delete:\n\n$filename\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: HyundaiColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteFile(filename);
  }

  Future<void> _deleteFile(String filename) async {
    setState(() => _deleting = filename);
    final error = await PodService.deleteStatusFile(filename);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $error'),
          backgroundColor: HyundaiColors.error,
        ),
      );
    } else {
      setState(() => _files.remove(filename));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted $filename'),
          backgroundColor: HyundaiColors.success,
        ),
      );
      // If the deleted file was the active one, clear it in the provider.
      final provider = context.read<AppProvider>();
      if (provider.loadedFilename == filename) provider.clearLoadedFile();
    }
    setState(() => _deleting = null);
  }

  String _formatDate(String filename) {
    final dt = parseStatusFilename(filename);
    if (dt == null) return filename;
    return DateFormat('dd MMM yyyy  HH:mm:ss').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: HyundaiColors.error,
              size: 48,
            ),
            const Gap(16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: HyundaiColors.error),
            ),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: _loadList,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
            ),
            const Gap(16),
            const Text(
              'No snapshots saved yet.',
              style: TextStyle(fontSize: 16),
            ),
            const Gap(8),
            Text(
              'Log in to Bluelink and tap Save to Pod to create a snapshot.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final provider = context.watch<AppProvider>();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      separatorBuilder: (_, __) => const Gap(8),
      itemBuilder: (_, i) {
        final f = _files[i];
        final isLoaded = provider.loadedFilename == f;
        final isDeleting = _deleting == f;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isLoaded
                ? const BorderSide(color: HyundaiColors.accent, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            leading: isDeleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isLoaded ? Icons.radio_button_checked : Icons.history,
                    color: isLoaded ? HyundaiColors.accent : null,
                  ),
            title: Text(
              _formatDate(f),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(f, style: const TextStyle(fontSize: 11)),
            trailing: isDeleting
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoaded)
                        const Chip(
                          label: Text('Active'),
                          backgroundColor: HyundaiColors.accent,
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        )
                      else
                        IconButton(
                          icon: MarkdownTooltip(
                            message: 'Load this snapshot into the dashboard.',
                            child: const Icon(Icons.download_outlined),
                          ),
                          onPressed: () => _loadFile(f),
                        ),
                      IconButton(
                        icon: MarkdownTooltip(
                          message: '**Delete** this snapshot permanently\n\nThis cannot be undone.',
                          child: const Icon(Icons.delete_outline),
                        ),
                        color: HyundaiColors.error,
                        onPressed: isDeleting ? null : () => _confirmDelete(f),
                      ),
                    ],
                  ),
            onTap: isDeleting ? null : () => _loadFile(f),
          ),
        );
      },
    );
  }
}
