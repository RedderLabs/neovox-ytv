import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'library_page.dart';
import 'settings_page.dart';
import '../widgets/mini_player.dart';
import '../widgets/full_player.dart';

class HomeShell extends StatefulWidget {
  final VoidCallback onLogout;
  const HomeShell({super.key, required this.onLogout});

  @override
  State<HomeShell> createState() => HomeShellState();

  static HomeShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeShellState>();
}

class HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  bool _fullPlayerOpen = false;

  void openFullPlayer() => setState(() => _fullPlayerOpen = true);
  void closeFullPlayer() => setState(() => _fullPlayerOpen = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    const HomePage(),
                    const SearchPage(),
                    const LibraryPage(),
                    SettingsPage(onLogout: widget.onLogout),
                  ],
                ),
              ),
              // Mini Player
              StreamBuilder<Track?>(
                stream: audioHandler.trackStream,
                builder: (context, snap) {
                  if (snap.data == null && audioHandler.currentTrack == null) {
                    return const SizedBox.shrink();
                  }
                  return MiniPlayerWidget(onTap: openFullPlayer);
                },
              ),
              // Bottom Nav
              _buildBottomNav(context),
            ],
          ),
          // Full Player overlay
          if (_fullPlayerOpen)
            FullPlayerWidget(onClose: closeFullPlayer),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Buscar'),
            BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Biblioteca'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
          ],
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
