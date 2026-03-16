import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_provider.dart';
import '../services/pod_service.dart';
import '../theme/hyundai_theme.dart';
import '../utils/pod_utils.dart';

/// History screen — browse and load archived status snapshots from the pod.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _files = [];
  bool _loading = true;
  String? _error;

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
            const Icon(Icons.error_outline,
                color: HyundaiColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: HyundaiColors.error),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            const Text(
              'No snapshots saved yet.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = _files[i];
        final isLoaded = provider.loadedFilename == f;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isLoaded
                ? const BorderSide(color: HyundaiColors.accent, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            leading: Icon(
              isLoaded ? Icons.radio_button_checked : Icons.history,
              color: isLoaded ? HyundaiColors.accent : null,
            ),
            title: Text(
              _formatDate(f),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              f,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: isLoaded
                ? const Chip(
                    label: Text('Active'),
                    backgroundColor: HyundaiColors.accent,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 11),
                  )
                : IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Load this snapshot',
                    onPressed: () => _loadFile(f),
                  ),
            onTap: () => _loadFile(f),
          ),
        );
      },
    );
  }
}
