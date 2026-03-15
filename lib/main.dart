import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';
import 'services/app_provider.dart';
import 'app_scaffold.dart.~1~';
import 'constants/app.dart';
import 'theme/hyundai_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const KonapodApp(),
    ),
  );
}

class KonapodApp extends StatelessWidget {
  const KonapodApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use standard MaterialApp with light + dark themes.
    // SolidThemeToggleConfig in SolidScaffold handles the runtime toggle
    // via SolidThemeNotifier which drives themeMode from shared_preferences.
    return MaterialApp(
      title: appName,
      theme: hyundaiLightTheme(),
      darkTheme: hyundaiDarkTheme(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: SolidLogin(
        required: false,
        appDirectory: appDirectory,
        title: appName.toUpperCase(),
        child: const _AutoLoginWrapper(),
      ),
    );
  }
}

class _AutoLoginWrapper extends StatefulWidget {
  const _AutoLoginWrapper();
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: HyundaiColors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('H',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(appName,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 32),
            const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white54, strokeWidth: 2)),
          ]),
        ),
      );
    }
    return const AppScaffold();
  }
}
