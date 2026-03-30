import 'package:flutter/material.dart';
import '../services/audio_service.dart' as neo;
import '../services/api_service.dart';
import '../theme/cyber_theme.dart';
import 'player_page.dart';
import 'playlists_page.dart';
import 'profile_page.dart';
import 'help_page.dart';

class HomeShell extends StatefulWidget {
  final neo.NeovoxAudioHandler audioHandler;
  final ApiService api;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const HomeShell({
    super.key,
    required this.audioHandler,
    required this.api,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentTab = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PlayerPage(audioHandler: widget.audioHandler, api: widget.api),
      PlaylistsPage(
        audioHandler: widget.audioHandler,
        api: widget.api,
        onPlaylistLoaded: () {
          // Al cargar una playlist, cambiar al tab HOME para ver los tracks
          setState(() => _currentTab = 0);
        },
      ),
      ProfilePage(api: widget.api),
      const HelpPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CT.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CT.bg,
        border: Border(
          bottom: BorderSide(color: CT.borderPanel, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CT.dotOn,
              boxShadow: [
                BoxShadow(color: CT.dotOn.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('NEOVOX', style: CyberTheme.orbitron.copyWith(
            fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 5, color: CT.textHeader)),
          const SizedBox(width: 6),
          Text('YT-V', style: CyberTheme.mono.copyWith(
            fontSize: 12, letterSpacing: 3, color: CT.textSecondary)),
          const Spacer(),
          // Theme toggle
          GestureDetector(
            onTap: widget.onToggleTheme,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: CT.inputBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CT.borderPanel),
              ),
              child: Icon(
                widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 14,
                color: CT.accentGlow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: CT.navBg,
        border: Border(
          top: BorderSide(color: CT.navBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _navItem(0, Icons.album_rounded, 'HOME'),
              _navItem(1, Icons.library_music_rounded, 'VAULT'),
              _navItem(2, Icons.person_rounded, 'PERFIL'),
              _navItem(3, Icons.help_outline_rounded, 'AYUDA'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? CT.navActive : CT.navInactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: CyberTheme.orbitron.copyWith(
                fontSize: 8,
                letterSpacing: 1,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? CT.navActive : CT.navInactive,
              ),
            ),
            if (active)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: CT.navActive,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(color: CT.navActive.withValues(alpha: 0.5), blurRadius: 6),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
