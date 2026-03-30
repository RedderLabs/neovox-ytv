import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';
import '../widgets/track_list_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Track> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  bool get wantKeepAlive => true;

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _searched = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _doSearch(q.trim()));
  }

  Future<void> _doSearch(String q) async {
    setState(() { _loading = true; _searched = true; });
    try {
      final data = await ApiService.search(q);
      if (mounted) {
        setState(() {
          _results = data.map((j) => Track.fromJson(j)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _playTrack(Track track) {
    final idx = _results.indexOf(track);
    audioHandler.playQueue(_results, idx >= 0 ? idx : 0);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              onSubmitted: (q) { if (q.trim().isNotEmpty) _doSearch(q.trim()); },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Buscar canciones, artistas...',
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() { _results = []; _searched = false; });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? _emptyState(Icons.travel_explore_rounded, 'Busca tu musica favorita')
                    : _results.isEmpty
                        ? _emptyState(Icons.search_off_rounded, 'Sin resultados')
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: _results.length,
                            itemBuilder: (context, i) => TrackListTile(
                              track: _results[i],
                              onTap: () => _playTrack(_results[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(height: 12),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
