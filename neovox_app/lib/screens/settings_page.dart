import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsPage({super.key, required this.onLogout});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _stats;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final s = await ApiService.getStats();
      if (mounted) setState(() => _stats = s);
    } catch (_) {}
  }

  String get _formattedAccount {
    final acc = ApiService.accountNumber ?? '';
    final buf = StringBuffer();
    for (int i = 0; i < acc.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(acc[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text('Ajustes', style: Theme.of(context).appBarTheme.titleTextStyle),
          ),

          // Account
          _sectionLabel('Cuenta'),
          _settingsItem(
            icon: Icons.person_rounded,
            title: 'Numero de cuenta',
            subtitle: _formattedAccount,
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: ApiService.accountNumber ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado')));
              },
            ),
          ),
          _settingsItem(
            icon: Icons.logout_rounded,
            title: 'Cerrar sesion',
            subtitle: 'Volver a la pantalla de login',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesion'),
                  content: const Text('Seguro que quieres salir?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () { Navigator.pop(ctx); widget.onLogout(); },
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Appearance
          _sectionLabel('Apariencia'),
          _settingsItem(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Tema oscuro',
            subtitle: 'Cambiar entre claro y oscuro',
            trailing: Switch(
              value: isDark,
              onChanged: (v) {
                final mode = v ? ThemeMode.dark : ThemeMode.light;
                NeovoxApp.themeNotifier.value = mode;
                prefs.setString('theme', v ? 'dark' : 'light');
              },
              activeColor: cs.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Stats
          _sectionLabel('Estadisticas'),
          if (_stats != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  _statCard('Visitas totales', '${_stats!['totalVisits'] ?? '-'}', cs),
                  _statCard('Usuarios unicos', '${_stats!['uniqueUsers'] ?? '-'}', cs),
                  _statCard('Visitas hoy', '${_stats!['todayVisits'] ?? '-'}', cs),
                  _statCard('Online desde', _formatDate(_stats!['launchedAt']), cs),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                Text('NEOVOX Music v2.0', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text('Desarrollado por RedderLabs',
                    style: TextStyle(fontSize: 12, color: cs.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
      child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null),
      onTap: onTap,
    );
  }

  Widget _statCard(String label, String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.primary)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(ts is int ? ts : int.tryParse('$ts') ?? 0);
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
