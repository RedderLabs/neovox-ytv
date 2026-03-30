import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/scanlines_widget.dart';

class ProfilePage extends StatefulWidget {
  final ApiService api;
  const ProfilePage({super.key, required this.api});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _copied = false;
  bool _deleting = false;

  String get _account => widget.api.accountNumber ?? '';
  String get _formatted => _account.replaceAllMapped(
      RegExp(r'(\d{4})(?=\d)'), (m) => '${m[1]} ');

  Future<void> _copyAccount() async {
    await Clipboard.setData(ClipboardData(text: _account));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('neovox_account');
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: CyberTheme.panelDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 36, color: CT.dangerBright),
              const SizedBox(height: 16),
              Text('ELIMINAR CUENTA', style: CyberTheme.orbitron.copyWith(
                fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2, color: CT.dangerBright)),
              const SizedBox(height: 12),
              Text(
                'Se eliminaran todas tus playlists y datos de cuenta. Esta accion no se puede deshacer.',
                textAlign: TextAlign.center,
                style: CyberTheme.mono.copyWith(
                  fontSize: 12, letterSpacing: 1, color: CT.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CT.inputBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text('CANCELAR', style: CyberTheme.mono.copyWith(
                            fontSize: 11, letterSpacing: 2, color: CT.textSecondary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x30FF4444),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CT.dangerBright),
                        ),
                        alignment: Alignment.center,
                        child: Text('ELIMINAR', style: CyberTheme.orbitron.copyWith(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            letterSpacing: 2, color: CT.dangerBright)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await widget.api.deleteAccount();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('neovox_account');
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      setState(() => _deleting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CT.bgCard,
          content: Text('ERROR AL ELIMINAR CUENTA',
              style: CyberTheme.mono.copyWith(color: CT.dangerBright)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Account info panel
          Container(
            decoration: CyberTheme.panelDecoration,
            child: Stack(
              children: [
                const ScanlinesOverlay(),
                const CornerAccents(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: CT.isDark
                                ? [const Color(0xFF0d1f5c), const Color(0xFF071540)]
                                : [const Color(0xFFc0d0f0), const Color(0xFFa0b8e0)],
                          ),
                          border: Border.all(color: CT.borderPanel),
                        ),
                        child: Icon(Icons.person_rounded, size: 30, color: CT.accent),
                      ),
                      const SizedBox(height: 16),
                      Text('CUENTA ANONIMA', style: CyberTheme.orbitron.copyWith(
                        fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3, color: CT.textTitle)),
                      const SizedBox(height: 20),

                      // Account number
                      Text('NUMERO DE CUENTA', style: CyberTheme.mono.copyWith(
                        fontSize: 10, letterSpacing: 2, color: CT.labelColor)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: CT.inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CT.inputBorder),
                        ),
                        child: SelectableText(
                          _formatted,
                          textAlign: TextAlign.center,
                          style: CyberTheme.mono.copyWith(
                              fontSize: 22, letterSpacing: 4, color: CT.textTitle),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Copy button
                      GestureDetector(
                        onTap: _copyAccount,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: CT.inputBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: CT.inputBorder),
                          ),
                          child: Text(
                            _copied ? 'COPIADO' : 'COPIAR NUMERO',
                            style: CyberTheme.orbitron.copyWith(
                                fontSize: 10, letterSpacing: 2, color: CT.accentGlow),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Guarda este numero para iniciar sesion en otros dispositivos',
                        textAlign: TextAlign.center,
                        style: CyberTheme.mono.copyWith(
                            fontSize: 10, letterSpacing: 1, color: CT.textSecondary, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Container(
            decoration: CyberTheme.panelAltDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACCIONES', style: CyberTheme.orbitron.copyWith(
                  fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: CT.textHeader)),
                const SizedBox(height: 16),

                // Logout
                _actionButton(
                  icon: Icons.logout_rounded,
                  label: 'CERRAR SESION',
                  sublabel: 'Volver a la pantalla de inicio',
                  onTap: _logout,
                ),
                const SizedBox(height: 8),

                // Delete account
                _actionButton(
                  icon: Icons.delete_forever_rounded,
                  label: 'ELIMINAR CUENTA',
                  sublabel: 'Borrar cuenta y todas las playlists',
                  onTap: _deleting ? null : _deleteAccount,
                  isDanger: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CT.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CT.inputBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CT.dotOn,
                    boxShadow: [BoxShadow(color: CT.dotOn.withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DESARROLLADO POR REDDERLABS.COM',
                    style: CyberTheme.mono.copyWith(
                        fontSize: 11, letterSpacing: 2, color: CT.textSecondary),
                  ),
                ),
                Text(
                  'NEOVOX YT-V',
                  style: CyberTheme.mono.copyWith(
                      fontSize: 10, letterSpacing: 1,
                      color: CT.textSecondary.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String sublabel,
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CT.plBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDanger
              ? CT.danger
              : CT.plBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDanger ? CT.dangerBright : CT.btnFill),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: CyberTheme.orbitron.copyWith(
                    fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700,
                    color: isDanger ? CT.dangerBright : CT.plName)),
                  const SizedBox(height: 2),
                  Text(sublabel, style: CyberTheme.mono.copyWith(
                    fontSize: 10, color: CT.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: CT.counterColor),
          ],
        ),
      ),
    );
  }
}
