import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(String) onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _view = 0; // 0=welcome, 1=show number, 2=login
  String _generatedNumber = '';
  bool _confirmed = false;
  bool _loading = false;
  String? _error;
  final _loginCtrl = TextEditingController();

  Future<void> _createAccount() async {
    setState(() => _loading = true);
    try {
      final num = await ApiService.createAccount();
      setState(() {
        _generatedNumber = num;
        _view = 1;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error al crear cuenta');
    }
  }

  Future<void> _login() async {
    final raw = _loginCtrl.text.replaceAll(' ', '');
    if (raw.length != 16 || int.tryParse(raw) == null) {
      setState(() => _error = 'Debe ser un numero de 16 digitos');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await ApiService.login(raw);
      if (ok) {
        widget.onLogin(raw);
      } else {
        setState(() { _error = 'Cuenta no encontrada'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Error de conexion'; _loading = false; });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatNumber(String n) {
    final clean = n.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(clean[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [cs.primary, const Color(0xFFFC5C7C)]),
                    ),
                    child: const Icon(Icons.music_note_rounded, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text('NEOVOX', style: Theme.of(context).textTheme.headlineLarge?.copyWith(letterSpacing: 4)),
                  const SizedBox(height: 4),
                  Text('Music streaming', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 48),

                  if (_view == 0) _buildWelcome(cs),
                  if (_view == 1) _buildShowNumber(cs),
                  if (_view == 2) _buildLogin(cs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome(ColorScheme cs) {
    return Column(
      children: [
        Text('Bienvenido', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Sin email. Sin contrasena.\nSolo un numero anonimo.',
            style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _createAccount,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Crear cuenta anonima'),
          ),
        ),
        const SizedBox(height: 24),
        _divider(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => setState(() => _view = 2),
            child: const Text('Ya tengo una cuenta'),
          ),
        ),
      ],
    );
  }

  Widget _buildShowNumber(ColorScheme cs) {
    return Column(
      children: [
        Text('Tu numero de cuenta', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.error.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Guardalo. Lo necesitaras para volver a entrar.',
              style: TextStyle(fontSize: 12, color: cs.error), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline),
          ),
          child: Text(_formatNumber(_generatedNumber),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 3, color: cs.primary,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedNumber));
                  _showSnack('Copiado');
                },
                child: const Text('Copiar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showSnack('Numero copiado al portapapeles'),
                child: const Text('Descargar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              activeColor: cs.primary,
            ),
            Text('He guardado mi numero', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmed ? () => widget.onLogin(_generatedNumber) : null,
            child: const Text('Entrar'),
          ),
        ),
      ],
    );
  }

  Widget _buildLogin(ColorScheme cs) {
    return Column(
      children: [
        Text('Iniciar sesion', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Ingresa tu numero de cuenta (16 digitos).',
            style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextField(
          controller: _loginCtrl,
          keyboardType: TextInputType.number,
          maxLength: 19,
          inputFormatters: [_AccountFormatter()],
          decoration: const InputDecoration(
            hintText: '0000 0000 0000 0000',
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.error.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!, style: TextStyle(fontSize: 12, color: cs.error), textAlign: TextAlign.center),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Entrar'),
          ),
        ),
        const SizedBox(height: 24),
        _divider(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => setState(() { _view = 0; _error = null; }),
            child: const Text('Crear cuenta nueva'),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o', style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
      ],
    );
  }
}

class _AccountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) return oldValue;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
