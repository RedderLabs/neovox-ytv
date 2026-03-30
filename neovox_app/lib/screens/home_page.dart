import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';
import '../widgets/track_list_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  List<Track> _trending = [];
  List<Playlist> _playlists = [];
  bool _loadingTrending = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loadTrending();
    _loadPlaylists();
  }

  Future<void> _loadTrending() async {
    try {
      final data = await ApiService.trending();
      if (mounted) {
        setState(() {
          _trending = data.map((j) => Track.fromJson(j)).toList();
          _loadingTrending = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTrending = false);
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final data = await ApiService.getPlaylists();
      if (mounted) {
        setState(() {
          _playlists = data.map((j) => Playlist.fromJson(j)).toList();
        });
      }
    } catch (_) {}
  }

  void _playTrack(Track track, List<Track> list) {
    final idx = list.indexOf(track);
    audioHandler.playQueue(list, idx >= 0 ? idx : 0);
  }

  Future<void> _quickPlayPlaylist(Playlist pl) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cargando ${pl.name}...')));
    try {
      final data = await ApiService.getPlaylistItems(pl.ytId);
      final items = (data['items'] as List).map((j) => Track.fromJson(j)).toList();
      if (items.isNotEmpty) {
        audioHandler.playQueue(items, 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar playlist')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Inicio'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  setState(() => _loadingTrending = true);
                  _loadData();
                },
              ),
            ],
          ),

          // Quick Picks
          if (_playlists.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Acceso rapido', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _playlists.length > 6 ? 6 : _playlists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final pl = _playlists[i];
                    return ActionChip(
                      avatar: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                        child: Icon(Icons.music_note, size: 14, color: Theme.of(context).colorScheme.primary),
                      ),
                      label: Text(pl.name, style: const TextStyle(fontSize: 13)),
                      onPressed: () => _quickPlayPlaylist(pl),
                      shape: StadiumBorder(side: BorderSide(color: Theme.of(context).dividerColor)),
                      backgroundColor: Theme.of(context).cardColor,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // Trending
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Tendencias', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),

          if (_loadingTrending)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
            )
          else if (_trending.isEmpty)
            SliverToBoxAdapter(
              child: _emptyState(Icons.trending_up_rounded, 'No se pudieron cargar tendencias'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => TrackListTile(
                  track: _trending[i],
                  onTap: () => _playTrack(_trending[i], _trending),
                ),
                childCount: _trending.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(height: 12),
          Text(text, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
