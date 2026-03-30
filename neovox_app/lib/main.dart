import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/audio_service.dart' as neo;
import 'services/api_service.dart';
import 'screens/home_shell.dart';
import 'theme/cyber_theme.dart';

late neo.NeovoxAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class NeovoxApp extends StatefulWidget {
  const NeovoxApp({super.key});

  @override
  State<NeovoxApp> createState() => _NeovoxAppState();
}

class _NeovoxAppState extends State<NeovoxApp> {
  bool _isDark = true;

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
      CT.setBrightness(_isDark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEOVOX YT-V',
      debugShowCheckedModeBanner: false,
      theme: _isDark ? CyberTheme.darkTheme : CyberTheme.lightTheme,
      home: AuthGate(
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const AuthGate({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

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
      final entered = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _AccountShowScreen(accountNumber: num),
        ),
      );

      if (entered == true) {
        setState(() {
          _loggedIn = true;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CT.bgCard,
          content: Text('ERROR: ${e.toString().length > 60 ? e.toString().substring(0, 60) : e}',
              style: CyberTheme.mono.copyWith(color: CT.dangerBright)),
        ),
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
          SnackBar(
            backgroundColor: CT.bgCard,
            content: Text('CUENTA NO ENCONTRADA',
                style: CyberTheme.mono.copyWith(color: CT.dangerBright)),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CT.bgCard,
          content: Text('ERROR DE CONEXION',
              style: CyberTheme.mono.copyWith(color: CT.dangerBright)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: CT.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CT.accentGlow,
                ),
              ),
              const SizedBox(height: 16),
              Text('CONECTANDO...',
                  style: CyberTheme.mono.copyWith(
                      fontSize: 10, letterSpacing: 2, color: CT.textSecondary)),
            ],
          ),
        ),
      );
    }
    if (_loggedIn) {
      return HomeShell(
        audioHandler: audioHandler,
        api: _api,
        onToggleTheme: widget.onToggleTheme,
        isDark: widget.isDark,
      );
    }
    return _AuthScreen(
      onCreateAccount: _createAccount,
      onLogin: _login,
    );
  }
}

// ── AUTH SCREEN ──
class _AuthScreen extends StatefulWidget {
  final VoidCallback onCreateAccount;
  final ValueChanged<String> onLogin;

  const _AuthScreen({required this.onCreateAccount, required this.onLogin});

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  final _ctrl = TextEditingController();
  bool _showLogin = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: CyberTheme.panelDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CT.dotOn,
                        boxShadow: [BoxShadow(color: CT.dotOn.withValues(alpha: 0.6), blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('NEOVOX', style: CyberTheme.orbitron.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 6, color: CT.textHeader)),
                    const SizedBox(width: 6),
                    Text('YT-V', style: CyberTheme.mono.copyWith(
                      fontSize: 14, letterSpacing: 3, color: CT.textSecondary)),
                  ],
                ),
                const SizedBox(height: 28),

                if (!_showLogin) ...[
                  Text('NUEVA CUENTA', style: CyberTheme.orbitron.copyWith(
                    fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3, color: CT.textTitle)),
                  const SizedBox(height: 12),
                  Text('Sin email. Sin contrasena. Solo un numero.',
                      style: CyberTheme.mono.copyWith(
                          fontSize: 12, letterSpacing: 1, color: CT.textSecondary, height: 1.6)),
                  const SizedBox(height: 20),
                  _primaryButton('GENERAR CUENTA ANONIMA', widget.onCreateAccount),
                  _divider(),
                  _secondaryButton('YA TENGO UNA CUENTA', () => setState(() => _showLogin = true)),
                ] else ...[
                  Text('INICIAR SESION', style: CyberTheme.orbitron.copyWith(
                    fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3, color: CT.textTitle)),
                  const SizedBox(height: 12),
                  Text('Escribe tu numero de cuenta (16 digitos).',
                      style: CyberTheme.mono.copyWith(
                          fontSize: 12, letterSpacing: 1, color: CT.textSecondary)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: CT.inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CT.inputBorder),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _AccountNumberFormatter(),
                      ],
                      style: CyberTheme.mono.copyWith(
                          fontSize: 20, letterSpacing: 4, color: CT.inputColor),
                      decoration: InputDecoration(
                        hintText: '0000 0000 0000 0000',
                        hintStyle: CyberTheme.mono.copyWith(
                            fontSize: 20, letterSpacing: 6, color: CT.inputPlaceholder),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x14FF4444),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0x33FF4444)),
                      ),
                      child: Text(_error!, textAlign: TextAlign.center,
                          style: CyberTheme.mono.copyWith(
                              fontSize: 11, letterSpacing: 1, color: CT.dangerBright)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _primaryButton('INICIAR SESION', () {
                    final num = _ctrl.text.replaceAll(RegExp(r'\D'), '');
                    if (num.length != 16) {
                      setState(() => _error = 'EL NUMERO DEBE TENER 16 DIGITOS');
                      return;
                    }
                    widget.onLogin(num);
                  }),
                  _divider(),
                  _secondaryButton('CREAR CUENTA NUEVA', () => setState(() => _showLogin = false)),
                ],

                const SizedBox(height: 24),
                Text(
                  'Tu numero de cuenta es el unico identificador que necesitas.\nNo almacenamos datos personales.',
                  textAlign: TextAlign.center,
                  style: CyberTheme.mono.copyWith(
                      fontSize: 10, letterSpacing: 1, color: CT.textSecondary, height: 1.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0c1e4a), Color(0xFF081430)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CT.addBorder),
        ),
        alignment: Alignment.center,
        child: Text(text, style: CyberTheme.orbitron.copyWith(
          fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: CT.addText)),
      ),
    );
  }

  Widget _secondaryButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CT.inputBorder),
        ),
        alignment: Alignment.center,
        child: Text(text, style: CyberTheme.mono.copyWith(
          fontSize: 11, letterSpacing: 2, color: CT.textSecondary)),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: CT.inputBorder, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('O', style: CyberTheme.mono.copyWith(
                fontSize: 10, letterSpacing: 2, color: CT.textSecondary)),
          ),
          Expanded(child: Divider(color: CT.inputBorder, height: 1)),
        ],
      ),
    );
  }
}

// ── ACCOUNT SHOW SCREEN (after creating account) ──
class _AccountShowScreen extends StatefulWidget {
  final String accountNumber;
  const _AccountShowScreen({required this.accountNumber});

  @override
  State<_AccountShowScreen> createState() => _AccountShowScreenState();
}

class _AccountShowScreenState extends State<_AccountShowScreen> {
  bool _confirmed = false;
  bool _copied = false;

  String get _formatted => widget.accountNumber.replaceAllMapped(
      RegExp(r'(\d{4})(?=\d)'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: CyberTheme.panelDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CT.dotOn,
                        boxShadow: [BoxShadow(color: CT.dotOn.withValues(alpha: 0.6), blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('NEOVOX', style: CyberTheme.orbitron.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 6, color: CT.textHeader)),
                    const SizedBox(width: 6),
                    Text('YT-V', style: CyberTheme.mono.copyWith(
                      fontSize: 14, letterSpacing: 3, color: CT.textSecondary)),
                  ],
                ),
                const SizedBox(height: 28),

                Text('TU NUMERO DE CUENTA', style: CyberTheme.orbitron.copyWith(
                  fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3, color: CT.textTitle)),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: CT.authWarningBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CT.authWarningBorder),
                  ),
                  child: Text(
                    'Guardalo. Lo necesitaras para iniciar sesion.',
                    textAlign: TextAlign.center,
                    style: CyberTheme.mono.copyWith(
                        fontSize: 12, letterSpacing: 1, color: CT.accentGlow, height: 1.6),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: CT.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CT.inputBorder),
                  ),
                  child: SelectableText(
                    _formatted,
                    textAlign: TextAlign.center,
                    style: CyberTheme.mono.copyWith(
                        fontSize: 26, letterSpacing: 4, color: CT.textTitle),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.accountNumber));
                        setState(() => _copied = true);
                        Future.delayed(const Duration(seconds: 2),
                            () { if (mounted) setState(() => _copied = false); });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: CT.inputBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: CT.inputBorder),
                        ),
                        child: Text(
                          _copied ? 'COPIADO' : 'COPIAR',
                          style: CyberTheme.orbitron.copyWith(
                              fontSize: 10, letterSpacing: 2, color: CT.accentGlow),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () => setState(() => _confirmed = !_confirmed),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: _confirmed ? CT.accentGlow : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: CT.accentGlow),
                        ),
                        child: _confirmed
                            ? Icon(Icons.check, size: 12, color: CT.bg)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Confirmo que he guardado mi numero de cuenta',
                          style: CyberTheme.mono.copyWith(
                              fontSize: 11, letterSpacing: 1, color: CT.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _confirmed ? () => Navigator.pop(context, true) : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: _confirmed
                          ? const LinearGradient(colors: [Color(0xFF0c1e4a), Color(0xFF081430)])
                          : null,
                      color: _confirmed ? null : CT.inputBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _confirmed ? CT.addBorder : CT.inputBorder),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: _confirmed ? 1.0 : 0.35,
                      child: Text('ENTRAR', style: CyberTheme.orbitron.copyWith(
                        fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: CT.addText)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Opacity(
                  opacity: 0.6,
                  child: Text(
                    'Tu numero de cuenta es el unico identificador que necesitas.\nNo almacenamos datos personales.',
                    textAlign: TextAlign.center,
                    style: CyberTheme.mono.copyWith(
                        fontSize: 10, letterSpacing: 1, color: CT.textSecondary, height: 1.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Account Number Formatter ──
class _AccountNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
