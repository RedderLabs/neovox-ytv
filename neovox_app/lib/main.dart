import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/audio_service.dart' as neo;
import 'services/api_service.dart';
import 'screens/player_screen.dart';
import 'theme/cyber_theme.dart';

late neo.NeovoxAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar audio service (Foreground Service en Android, AVAudioSession en iOS)
  audioHandler = await AudioService.init(
    builder: () => neo.NeovoxAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.redderlabs.neovox.audio',
      androidNotificationChannelName: 'NEOVOX Audio',
      androidNotificationOngoing: true,
    ),
  );

  runApp(const NeovoxApp());
}

class NeovoxApp extends StatelessWidget {
  const NeovoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEOVOX YT-V',
      debugShowCheckedModeBanner: false,
      theme: CyberTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('neovox_account');
    if (saved != null && saved.length == 16) {
      _api.setAccount(saved);
      setState(() {
        _loggedIn = true;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _createAccount() async {
    setState(() => _loading = true);
    try {
      final num = await _api.createAccount();
      _api.setAccount(num);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('neovox_account', num);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: CyberTheme.bgCard,
          title: const Text('CUENTA CREADA',
              style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, letterSpacing: 2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tu numero de cuenta:',
                  style: TextStyle(fontSize: 11, color: CyberTheme.textSecondary)),
              const SizedBox(height: 8),
              SelectableText(
                num.replaceAllMapped(RegExp(r'(\d{4})(?=\d)'), (m) => '${m[1]} '),
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  letterSpacing: 3,
                  color: CyberTheme.accentGlow,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Guarda este numero. Es tu unico identificador.',
                  style: TextStyle(fontSize: 10, color: CyberTheme.danger)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ENTRAR'),
            ),
          ],
        ),
      );

      setState(() {
        _loggedIn = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creando cuenta')),
      );
    }
  }

  Future<void> _login(String number) async {
    setState(() => _loading = true);
    try {
      final ok = await _api.login(number);
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('neovox_account', number);
        setState(() {
          _loggedIn = true;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CUENTA NO ENCONTRADA')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ERROR DE CONEXION')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loggedIn) {
      return PlayerScreen(audioHandler: audioHandler, api: _api);
    }
    return _LoginScreen(
      onCreateAccount: _createAccount,
      onLogin: _login,
    );
  }
}

class _LoginScreen extends StatefulWidget {
  final VoidCallback onCreateAccount;
  final ValueChanged<String> onLogin;

  const _LoginScreen({required this.onCreateAccount, required this.onLogin});

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'NEOVOX',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: CyberTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'YT-V',
                style: TextStyle(fontSize: 16, letterSpacing: 5, color: CyberTheme.textSecondary),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('CREAR CUENTA ANONIMA',
                      style: TextStyle(letterSpacing: 2, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: CyberTheme.inputBorder)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('O', style: TextStyle(color: CyberTheme.textSecondary, fontSize: 11)),
                  ),
                  Expanded(child: Divider(color: CyberTheme.inputBorder)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'NUMERO DE CUENTA',
                  labelStyle: TextStyle(fontSize: 11, letterSpacing: 2),
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(letterSpacing: 3, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final num = _ctrl.text.replaceAll(RegExp(r'\D'), '');
                    if (num.length == 16) widget.onLogin(num);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CyberTheme.accent,
                    side: const BorderSide(color: CyberTheme.accent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('ENTRAR', style: TextStyle(letterSpacing: 2, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tu numero de cuenta es tu unico identificador.\nNo almacenamos datos personales.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: CyberTheme.textSecondary, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
