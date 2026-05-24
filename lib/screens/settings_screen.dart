/// Settings screen: Bluelink credentials and pod setup info.
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

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:konapod/services/app_provider.dart';
import 'package:konapod/services/bluelink_service.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/setup_dialog.dart';

/// Settings screen — Bluelink credentials and app preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscurePin = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    const storage = FlutterSecureStorage();
    final username = await storage.read(key: 'bl_username') ?? '';
    final password = await storage.read(key: 'bl_password') ?? '';
    final pin = await storage.read(key: 'bl_pin') ?? '';
    setState(() {
      _emailCtrl.text = username;
      _passCtrl.text = password;
      _pinCtrl.text = pin;
    });
  }

  Future<void> _save() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'bl_username', value: _emailCtrl.text.trim());
    await storage.write(key: 'bl_password', value: _passCtrl.text);
    await storage.write(key: 'bl_pin', value: _pinCtrl.text.trim());
    setState(() => _saved = true);
    Future.delayed(
      const Duration(seconds: 2),
      () => mounted ? setState(() => _saved = false) : null,
    );
  }

  Future<void> _clearAndLogout() async {
    await context.read<AppProvider>().logout();
    _emailCtrl.clear();
    _passCtrl.clear();
    _pinCtrl.clear();
  }

  /// Run each prerequisite check in turn and show live progress in a dialog.
  Future<void> _testConnection() async {
    final steps = <_DiagStep>[];
    final notifier = ValueNotifier<int>(0); // increment to trigger rebuild

    void addOrUpdate({required String label, bool? ok, String? detail}) {
      if (steps.isNotEmpty && steps.last.ok == null) {
        steps[steps.length - 1] = _DiagStep(label: label, ok: ok, detail: detail);
      } else {
        steps.add(_DiagStep(label: label, ok: ok, detail: detail));
      }
      notifier.value++;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DiagDialog(steps: steps, notifier: notifier),
    );

    Future<void> tick(String label, Future<String?> Function() work) async {
      addOrUpdate(label: label); // in-progress
      String? err;
      try {
        err = await work();
      } catch (e) {
        err = e.toString();
      }
      addOrUpdate(label: label, ok: err == null, detail: err);
    }

    // 1. Python with hyundai_kia_connect_api available?
    String? pythonCmd;
    await tick('Python + hyundai_kia_connect_api found', () async {
      final home = Platform.environment['HOME'] ?? '';
      final candidates = [
        '$home/.local/share/konapod/venv/bin/python',
        '$home/.konapod-venv/bin/python',
        'python3',
        'python',
      ];
      for (final cmd in candidates) {
        try {
          final ver = await Process.run(cmd, ['--version']);
          if (ver.exitCode != 0) continue;
          final imp = await Process.run(
            cmd,
            ['-c', 'import hyundai_kia_connect_api'],
          );
          if (imp.exitCode == 0) {
            pythonCmd = cmd;
            return null; // found one that has the library
          }
        } catch (_) {
          continue;
        }
      }
      return 'hyundai_kia_connect_api not found in any Python.\n\n'
          'Option A (simplest):\n'
          '  pip install hyundai-kia-connect-api --break-system-packages\n\n'
          'Option B (venv):\n'
          '  python3 -m venv ~/.local/share/konapod/venv\n'
          '  ~/.local/share/konapod/venv/bin/pip install hyundai-kia-connect-api';
    });
    if (pythonCmd == null) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) _showDiagResult(steps);
      return;
    }

    // 3. bluelink_fetch.py present?
    final svc = BluelinkService();
    String? scriptPath;
    await tick('bluelink_fetch.py found', () async {
      final path = svc.findScript();
      if (!File(path).existsSync()) {
        return 'Script not found at:\n$path\n\n'
            'Place bluelink_fetch.py next to the app binary.';
      }
      scriptPath = path;
      return null;
    });
    if (scriptPath == null) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) _showDiagResult(steps);
      return;
    }

    // 4. Credentials entered?
    final username = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final pin = _pinCtrl.text.trim();
    await tick('Credentials entered', () async {
      if (username.isEmpty || password.isEmpty || pin.isEmpty) {
        return 'Email, password, and PIN must all be filled in.';
      }
      return null;
    });
    if (steps.last.ok == false) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) _showDiagResult(steps);
      return;
    }

    // 5. Network call to Bluelink API.
    await tick('Bluelink API login (up to 90s)…', () async {
      try {
        final result = await Process.run(
          pythonCmd!,
          [scriptPath!, username, password, pin],
          stdoutEncoding: const SystemEncoding(),
          stderrEncoding: const SystemEncoding(),
        ).timeout(const Duration(seconds: 90));
        final stdout = (result.stdout as String).trim();
        final stderr = (result.stderr as String).trim();
        if (result.exitCode != 0 || stdout.isEmpty) {
          return 'Exit code ${result.exitCode}\n'
              '${stderr.isNotEmpty ? "stderr: $stderr" : "No output"}';
        }
        if (!stdout.contains('"vehicles"')) {
          return 'Unexpected output:\n'
              '${stdout.substring(0, stdout.length.clamp(0, 300))}';
        }
        return null;
      } on Exception catch (e) {
        return e.toString();
      }
    });

    if (mounted) Navigator.of(context).pop();
    if (mounted) _showDiagResult(steps);
  }

  void _showDiagResult(List<_DiagStep> steps) {
    final allOk = steps.every((s) => s.ok == true);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              allOk ? Icons.check_circle : Icons.error_outline,
              color: allOk ? HyundaiColors.success : HyundaiColors.error,
            ),
            const Gap(8),
            Text(allOk ? 'Connection OK' : 'Connection failed'),
          ],
        ),
        content: SingleChildScrollView(
          child: _DiagStepList(steps: steps),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Bluelink Credentials'),
          const Gap(4),
          Text(
            'Credentials are stored locally on this device. '
            'They are used to fetch live data via the bluelink_fetch.py script.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Gap(16),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Bluelink Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const Gap(12),
          TextField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Bluelink Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const Gap(12),
          TextField(
            controller: _pinCtrl,
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Bluelink PIN',
              prefixIcon: const Icon(Icons.pin_outlined),
              counterText: '',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
          ),
          const Gap(20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_saved ? Icons.check : Icons.save_outlined),
                label: Text(_saved ? 'Saved!' : 'Save Credentials'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _saved ? HyundaiColors.success : HyundaiColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const Gap(12),
              OutlinedButton.icon(
                onPressed: _clearAndLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Clear & Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HyundaiColors.error,
                  side: const BorderSide(color: HyundaiColors.error),
                ),
              ),
            ],
          ),
          const Gap(12),
          OutlinedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.network_check, size: 18),
            label: const Text('Test Connection'),
            style: OutlinedButton.styleFrom(
              foregroundColor: HyundaiColors.primary,
              side: const BorderSide(color: HyundaiColors.primary),
            ),
          ),
          const Gap(32),
          const _SectionTitle('Solid Pod'),
          const Gap(4),
          Text(
            'Vehicle snapshots are saved to your Solid Pod under konapod/. '
            'Log in to your pod using the pod login button in the app bar.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Gap(32),
          const _SectionTitle('Bluelink setup'),
          const Gap(4),
          Text(
            'Live vehicle data requires the hyundai_kia_connect_api Python '
            'library and the bluelink_fetch.py script.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Gap(10),
          OutlinedButton.icon(
            onPressed: _showSetupInstructions,
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('View setup instructions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: HyundaiColors.primary,
              side: const BorderSide(color: HyundaiColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetupInstructions() {
    showDialog<void>(
      context: context,
      builder: (_) => const SetupDialog(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}

// ── Diagnostic step model ─────────────────────────────────────────────────────

class _DiagStep {
  final String label;
  final bool? ok; // null = in progress
  final String? detail;
  const _DiagStep({required this.label, this.ok, this.detail});
}

// ── Live progress dialog ──────────────────────────────────────────────────────

class _DiagDialog extends StatelessWidget {
  final List<_DiagStep> steps;
  final ValueNotifier<int> notifier;
  const _DiagDialog({required this.steps, required this.notifier});

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Testing connection…'),
        content: SingleChildScrollView(
          child: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (_, __, ___) => _DiagStepList(steps: steps),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
}

// ── Step list widget ──────────────────────────────────────────────────────────

class _DiagStepList extends StatelessWidget {
  final List<_DiagStep> steps;
  const _DiagStepList({required this.steps});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in steps) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: s.ok == null
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        s.ok! ? Icons.check_circle : Icons.cancel,
                        size: 18,
                        color: s.ok!
                            ? HyundaiColors.success
                            : HyundaiColors.error,
                      ),
              ),
              const Gap(6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: s.ok == false ? HyundaiColors.error : null,
                      ),
                    ),
                    if (s.detail != null) ...[
                      const Gap(2),
                      Text(
                        s.detail!,
                        style: TextStyle(
                          fontSize: 11,
                          color: s.ok == false
                              ? HyundaiColors.error
                              : cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Gap(10),
        ],
      ],
    );
  }
}
