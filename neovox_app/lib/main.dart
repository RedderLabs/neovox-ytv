import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/audio_service.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_shell.dart';
import 'screens/auth_screen.dart';

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  await initAudioService();
  runApp(const NeovoxApp());
}

class NeovoxApp extends StatefulWidget {
  const NeovoxApp({super.key});

  static final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  @override
  State<NeovoxApp> createState() => _NeovoxAppState();
}

class _NeovoxAppState extends State<NeovoxApp> {
  @override
  void initState() {
    super.initState();
    final saved = prefs.getString('theme') ?? 'dark';
    NeovoxApp.themeNotifier.value = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: NeovoxApp.themeNotifier,
      builder: (_, themeMode, __) {
        final isDark = themeMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF5F5F8),
        ));
        return MaterialApp(
          title: 'NEOVOX Music',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    final acc = prefs.getString('neovox_account');
    if (acc != null && acc.length == 16) {
      ApiService.accountNumber = acc;
      _loggedIn = true;
      ApiService.registerVisit();
    }
  }

  void _onLogin(String accountNumber) {
    prefs.setString('neovox_account', accountNumber);
    ApiService.accountNumber = accountNumber;
    ApiService.registerVisit();
    setState(() => _loggedIn = true);
  }

  void onLogout() {
    prefs.remove('neovox_account');
    ApiService.accountNumber = null;
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn) {
      return HomeShell(onLogout: onLogout);
    }
    return AuthScreen(onLogin: _onLogin);
  }
}
