/// App entry point: initialises providers, theme and SolidLogin wrapper.
///
// Time-stamp: <Monday 2026-03-16 13:55:28 +1100 Graham Williams>
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

// Add the library directive as we have doc entries above. We publish the above
// meta doc lines in the docs.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'app_scaffold.dart';
import 'constants/app.dart';
import 'services/app_provider.dart';
import 'theme/hyundai_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialise SolidUI security key manager to handle all user security key
  // requests.

  SolidSecurityKeyCentralManager.instance;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const KonapodApp(),
    ),
  );
}

class KonapodApp extends StatefulWidget {
  const KonapodApp({super.key});
  @override
  State<KonapodApp> createState() => _KonapodAppState();
}

class _KonapodAppState extends State<KonapodApp> {
  final _themeNotifier = SolidThemeNotifier();

  @override
  void initState() {
    super.initState();
    // Load persisted theme and rebuild MaterialApp whenever it changes.
    _themeNotifier.initialize();
    _themeNotifier.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: hyundaiLightTheme(),
      darkTheme: hyundaiDarkTheme(),
      // Drive themeMode from SolidThemeNotifier so the toggle in
      // SolidScaffold actually changes the app theme.
      themeMode: _themeNotifier.themeMode,
      debugShowCheckedModeBanner: false,
      home: SolidLogin(
        required: false,
        appDirectory: appDirectory,
        title: appName.toUpperCase().replaceAll(' - ', '\n'),
        image: const AssetImage('assets/images/app_image.jpg'),
        logo: const AssetImage('assets/images/app_icon.png'),
        child: _AutoLoginWrapper(themeNotifier: _themeNotifier),
      ),
    );
  }
}

class _AutoLoginWrapper extends StatefulWidget {
  final SolidThemeNotifier themeNotifier;
  const _AutoLoginWrapper({required this.themeNotifier});
  @override
  State<_AutoLoginWrapper> createState() => _AutoLoginWrapperState();
}

class _AutoLoginWrapperState extends State<_AutoLoginWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final provider = context.read<AppProvider>();
    // Try saved Bluelink credentials first; fall back to pod snapshot
    final hasBluelink = await provider.tryAutoLogin();
    if (!hasBluelink) {
      await provider.loadFromPod();
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: HyundaiColors.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: HyundaiColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'H',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return AppScaffold(themeNotifier: widget.themeNotifier);
  }
}
