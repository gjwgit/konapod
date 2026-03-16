import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';
import 'constants/app.dart';
import 'services/app_provider.dart';
import 'theme/hyundai_theme.dart';
import 'widgets/sections_status.dart';
import 'widgets/pages.dart';

import 'screens/history_screen.dart';
import 'screens/visuals_screen.dart';
import 'screens/settings_screen.dart';

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
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final v = provider.selectedVehicle;

    return SolidScaffold(
      controller: _controller,

      // ── Left nav menu ────────────────────────────────────────────────────
      menu: [
        SolidMenuItem(
          title: 'Status',
          icon: Icons.directions_car,
          tooltip: 'Vehicle status — locks, doors, engine',
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
          tooltip: 'Battery, charging and fuel',
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
          tooltip: 'Climate, tyres and comfort systems',
          child: _PageWrapper(
            title: 'Comfort',
            child: v != null
                ? ComfortPage(v: v)
                : NoDataPlaceholder(provider: provider),
          ),
        ),
        SolidMenuItem(
          title: 'Visuals',
          icon: Icons.bar_chart,
          tooltip: 'Charts and visualisations of historical driving data',
          child: _PageWrapper(
            title: 'Visuals',
            child: const VisualsScreen(),
          ),
        ),
        SolidMenuItem(
          title: 'History',
          icon: Icons.history,
          tooltip: 'Browse and load archived snapshots from your Solid Pod',
          child: _PageWrapper(
            title: 'History',
            child: const HistoryScreen(),
          ),
        ),
        SolidMenuItem(
          title: 'Settings',
          icon: Icons.settings,
          tooltip: 'Bluelink credentials and app preferences',
          child: _PageWrapper(
            title: 'Settings',
            child: const SettingsScreen(),
          ),
        ),
      ],

      // ── App bar ──────────────────────────────────────────────────────────
      appBar: SolidAppBarConfig(
        title: appName,
        backgroundColor: HyundaiColors.primary,
        versionConfig: SolidVersionConfig(
          changelogUrl:
              'https://github.com/gjwgit/konapod/blob/dev/CHANGELOG.md',
        ),
        actions: [
          // Bluelink login/refresh button
          if (provider.isAuthenticated)
            SolidAppBarAction(
              icon: provider.isRefreshing
                  ? Icons.hourglass_top
                  : Icons.refresh,
              tooltip: 'Refresh from Bluelink',
              onPressed: provider.isRefreshing ? () {} : provider.refresh,
              color: Colors.white,
            )
          else
            SolidAppBarAction(
              icon: Icons.car_rental,
              tooltip: 'Login to Bluelink',
              onPressed: () => _showBluelinkLogin(context, provider),
              color: Colors.white70,
            ),

          // Save to pod button (only when bluelink data loaded)
          if (provider.dataSource == DataSource.bluelink &&
              provider.hasData)
            SolidAppBarAction(
              icon: Icons.cloud_upload_outlined,
              tooltip: 'Save snapshot to Solid Pod',
              onPressed: () => _saveToPod(context, provider),
              color: Colors.white,
            ),

          // Load from pod button
          SolidAppBarAction(
            icon: Icons.cloud_download_outlined,
            tooltip: 'Load latest snapshot from Solid Pod',
            onPressed: () => _loadFromPod(context, provider),
            color: Colors.white70,
          ),

          // Export to JSON file
          SolidAppBarAction(
            icon: Icons.download_for_offline_outlined,
            tooltip: 'Export current status to JSON file',
            onPressed: provider.hasData
                ? () => _exportJson(context, provider)
                : () {},
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
          tooltip: 'Manage your Solid Pod encryption key',
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
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: HyundaiColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text('H',
                style: TextStyle(color: Colors.white,
                    fontSize: 26, fontWeight: FontWeight.w900)),
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

  Future<void> _saveToPod(BuildContext ctx, AppProvider provider) async {
    final ok = await provider.saveToPod();
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Snapshot saved to pod!'
          : 'Save failed: ${provider.errorMessage}'),
      backgroundColor: ok ? HyundaiColors.success : HyundaiColors.error,
    ));
  }

  Future<void> _loadFromPod(BuildContext ctx, AppProvider provider) async {
    final ok = await provider.loadFromPod();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(provider.errorMessage ?? 'Load failed'),
        backgroundColor: HyundaiColors.error,
      ));
    }
  }

  Future<void> _exportJson(BuildContext ctx, AppProvider provider) async {
    try {
      final rawJson = await provider.getRawJsonForExport();
      if (rawJson == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('No data to export'),
          backgroundColor: HyundaiColors.error,
        ));
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
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Exported to ${file.path}'),
        backgroundColor: HyundaiColors.success,
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: HyundaiColors.error,
      ));
    }
  }

  void _handlePodLoginTap(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const SolidPopupLogin(),
    ));
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
