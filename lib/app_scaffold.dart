/// Main app scaffold with SolidScaffold, nav menu, app bar and actions.
///
// Time-stamp: <Wednesday 2026-03-18 08:49:07 +1100 Graham Williams>
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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:konapod/constants/app.dart';
import 'package:konapod/screens/history_screen.dart';
import 'package:konapod/screens/settings_screen.dart';
import 'package:konapod/screens/visuals_screen.dart';
import 'package:konapod/services/app_provider.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/pages.dart';

/// Main app scaffold wrapping the SolidScaffold.
/// Provides left nav, top app bar, status bar, and per-section pages.
class AppScaffold extends StatefulWidget {
  final SolidThemeNotifier themeNotifier;
  const AppScaffold({super.key, required this.themeNotifier});
  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final _controller = SolidScaffoldController();

  // Solid Pod login state
  String? _webId;

  // Security key state — tracks whether the user's encryption key is saved.
  // Updated via the onKeyStatusChanged callback from SolidSecurityKeyStatus.

  bool _isKeySaved = false;

  @override
  void initState() {
    super.initState();
    // Listen for errors from the provider and show a dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      // Show any error that occurred before the scaffold was mounted
      // (e.g. failed auto-login on startup).
      if (provider.state == AppState.error && provider.errorMessage != null) {
        _showErrorDialog(provider.errorMessage!);
        provider.clearError();
      }
      // Listen for future errors.
      provider.addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    context.read<AppProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (provider.state == AppState.error && provider.errorMessage != null) {
      _showErrorDialog(provider.errorMessage!);
      provider.clearError();
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            Gap(8),
            Text('Could not fetch data'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final v = provider.selectedVehicle;

    return SolidScaffold(
      controller: _controller,

      showLogout: false,

      // ── Left nav menu ────────────────────────────────────────────────────
      menu: [
        SolidMenuItem(
          title: 'Status',
          icon: Icons.directions_car,
          tooltip: '**Status**\n\nVehicle status including locks, doors, and engine.',
          child: _PageWrapper(
            title: 'Status',
            child: v != null
                ? StatusPage(v: v)
                : NoDataPlaceholder(provider: provider),
          ),
        ),
        SolidMenuItem(
          title: 'Energy',
          icon: Icons.battery_charging_full,
          tooltip: '**Energy**\n\nEV battery, charging status and fuel.',
          child: _PageWrapper(
            title: 'Energy',
            child: v != null
                ? EnergyPage(v: v)
                : NoDataPlaceholder(provider: provider),
          ),
        ),
        SolidMenuItem(
          title: 'Comfort',
          icon: Icons.thermostat,
          tooltip: '**Comfort**\n\nClimate control, tyres and comfort systems.',
          child: _PageWrapper(
            title: 'Comfort',
            child: v != null
                ? ComfortPage(v: v)
                : NoDataPlaceholder(provider: provider),
          ),
        ),
        const SolidMenuItem(
          title: 'Visuals',
          icon: Icons.bar_chart,
          tooltip: '**Visuals**\n\nCharts and visualisations of historical driving data.',
          child: _PageWrapper(
            title: 'Visuals',
            child: VisualsScreen(),
          ),
        ),
        const SolidMenuItem(
          title: 'History',
          icon: Icons.history,
          tooltip: '**History**\n\nBrowse, load and delete archived snapshots\nfrom your Solid Pod.',
          child: _PageWrapper(
            title: 'History',
            child: HistoryScreen(),
          ),
        ),
        const SolidMenuItem(
          title: 'Settings',
          icon: Icons.settings,
          tooltip: '**Settings**\n\nBluelink credentials and app preferences.',
          child: _PageWrapper(
            title: 'Settings',
            child: SettingsScreen(),
          ),
        ),
      ],

      // ── App bar ──────────────────────────────────────────────────────────
      appBar: SolidAppBarConfig(
        title: appName,
        backgroundColor: HyundaiColors.primary,
        versionConfig: const SolidVersionConfig(
          changelogUrl:
              'https://github.com/gjwgit/konapod/blob/dev/CHANGELOG.md',
        ),
        actions: [
          // Bluelink login/refresh button
          if (provider.isAuthenticated)
            SolidAppBarAction(
              icon: provider.isRefreshing ? Icons.hourglass_top : Icons.refresh,
              tooltip: '**Refresh**\n\nFetch the latest data from Bluelink.',
              onPressed: provider.isRefreshing ? () {} : provider.refresh,
              color: Colors.white,
            )
          else
            SolidAppBarAction(
              icon: Icons.car_rental,
              tooltip: '**Login**\n\nConnect to Bluelink to fetch live vehicle data.',
              onPressed: () => _showBluelinkLogin(context, provider),
              color: Colors.white70,
            ),

          // Save to pod button (only when bluelink data loaded)
          if (provider.dataSource == DataSource.bluelink && provider.hasData)
            SolidAppBarAction(
              icon: Icons.cloud_upload_outlined,
              tooltip: '**Save to Pod**\n\nArchive a snapshot of current vehicle status\nto your Solid Pod.',
              onPressed: () => _saveToPod(provider),
              color: Colors.white,
            ),

          // Load from pod button
          SolidAppBarAction(
            icon: Icons.cloud_download_outlined,
            tooltip: '**Load from Pod**\n\nLoad the latest snapshot from your Solid Pod.',
            onPressed: () => _loadFromPod(provider),
            color: Colors.white70,
          ),

          // Export to JSON file
          SolidAppBarAction(
            icon: Icons.download_for_offline_outlined,
            tooltip: '**Export JSON**\n\nSave current vehicle data as a JSON file\nto your Downloads folder.',
            onPressed: provider.hasData ? () => _exportJson(provider) : () {},
            color: provider.hasData ? Colors.white : Colors.white30,
          ),
        ],
      ),

      // ── Status bar ───────────────────────────────────────────────────────
      statusBar: SolidStatusBarConfig(
        loginStatus: SolidLoginStatus(
          webId: _webId,
          onTap: () => _handlePodLoginTap(context),
          loggedInText: 'Pod: Connected',
          loggedOutText: 'Pod: Not connected',
        ),

        // SecurityKey widget — displays a key icon in the bottom-right corner.
        // Tapping it opens the key management popup (view/forget/change key).
        // onKeyStatusChanged keeps _isKeySaved in sync so the icon reflects
        // the current state (key saved vs not saved).

        securityKeyStatus: SolidSecurityKeyStatus(
          isKeySaved: _isKeySaved,
          title: 'KonaPod Security Keys',
          onKeyStatusChanged: (hasKey) {
            setState(() {
              _isKeySaved = hasKey;
            });
          },
          tooltip: '**Security Keys**\n\nManage your Solid Pod encryption key.\nTap to view, change or forget the key.',
        ),
      ),

      // ── Theme toggle ─────────────────────────────────────────────────────
      themeToggle: SolidThemeToggleConfig(
        enabled: true,
        currentThemeMode: widget.themeNotifier.themeMode,
        onToggleTheme: widget.themeNotifier.toggleTheme,
      ),

      // ── About ────────────────────────────────────────────────────────────
      aboutConfig: SolidAboutConfig(
        applicationName: appName,
        applicationVersion: appVersion,
        applicationIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: HyundaiColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'H',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        text: '**$appName** is a Hyundai Bluelink vehicle dashboard '
            'with Solid Pod integration.\n\n'
            '$appDescription\n\n'
            'Vehicle data is fetched via the '
            '[hyundai_kia_connect_api](https://github.com/Hyundai-Kia-Connect/hyundai_kia_connect_api) '
            'Python library and can be archived to your personal Solid Pod.',
        applicationLegalese: '© 2024 Konapod. MIT Licence.',
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _showBluelinkLogin(BuildContext context, AppProvider provider) {
    _controller.navigateToSubpage(const SettingsScreen());
  }

  Future<void> _saveToPod(AppProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.saveToPod();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Snapshot saved to pod!'
              : 'Save failed: ${provider.errorMessage}',
        ),
        backgroundColor: ok ? HyundaiColors.success : HyundaiColors.error,
      ),
    );
  }

  Future<void> _loadFromPod(AppProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.loadFromPod();
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Load failed'),
          backgroundColor: HyundaiColors.error,
        ),
      );
    }
  }

  Future<void> _exportJson(AppProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final rawJson = await provider.getRawJsonForExport();
      if (rawJson == null) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No data to export'),
            backgroundColor: HyundaiColors.error,
          ),
        );
        return;
      }
      final filename =
          'konapod_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.json';
      final home = Platform.environment['HOME'] ?? '.';
      final downloads = Directory('$home/Downloads');
      final dir = downloads.existsSync() ? downloads : Directory(home);
      final file = File('${dir.path}/$filename');
      await file
          .writeAsString(const JsonEncoder.withIndent('  ').convert(rawJson));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Exported to ${file.path}'),
          backgroundColor: HyundaiColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: HyundaiColors.error,
        ),
      );
    }
  }

  void _handlePodLoginTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const SolidPopupLogin(),
      ),
    );
  }
}

// ── Per-section page wrappers ─────────────────────────────────────────────────

class _PageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const _PageWrapper({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
