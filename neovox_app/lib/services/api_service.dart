import 'package:dio/dio.dart';

class ApiService {
  static const _baseUrl = 'https://neovox-ytv-latest.onrender.com';

  static final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static String? accountNumber;

  static Map<String, String> get _authHeaders => {'X-Account-Number': accountNumber ?? ''};

  // ── Account ───────────────────────────────────────────────
  static Future<String> createAccount() async {
    final res = await _dio.post('/api/account/create');
    return res.data['accountNumber'];
  }

  static Future<bool> login(String number) async {
    try {
      final res = await _dio.post('/api/account/login',
          data: {'accountNumber': number},
          options: Options(headers: {'Content-Type': 'application/json'}));
      return res.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  static Future<void> deleteAccount() async {
    await _dio.delete('/api/account', options: Options(headers: _authHeaders));
  }

  // ── Playlists ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPlaylists() async {
    final res = await _dio.get('/api/playlists', options: Options(headers: _authHeaders));
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<Map<String, dynamic>> addPlaylist(String name, String ytId) async {
    final res = await _dio.post('/api/playlists',
        data: {'name': name, 'ytId': ytId},
        options: Options(headers: {..._authHeaders, 'Content-Type': 'application/json'}));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<void> deletePlaylist(String id) async {
    await _dio.delete('/api/playlists/$id', options: Options(headers: _authHeaders));
  }

  // ── Search & Discovery ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> search(String query, {int limit = 25}) async {
    final res = await _dio.get('/api/search', queryParameters: {'q': query, 'limit': limit});
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<List<Map<String, dynamic>>> trending() async {
    final res = await _dio.get('/api/trending');
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<Map<String, dynamic>> getPlaylistItems(String playlistId) async {
    final res = await _dio.get('/api/playlist-items/$playlistId');
    return Map<String, dynamic>.from(res.data);
  }

  // ── Audio ──────────────────────────────────────────────────
  static Future<String> getStreamUrl(String videoId) async {
    final res = await _dio.get('/api/stream-url/$videoId');
    return res.data['url'];
  }

  static String audioProxyUrl(String rawUrl) {
    return '$_baseUrl/api/audio-proxy?url=${Uri.encodeComponent(rawUrl)}';
  }

  // ── Stats ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/api/stats');
    return Map<String, dynamic>.from(res.data);
  }

  static Future<void> registerVisit() async {
    try {
      await _dio.post('/api/visit');
    } catch (_) {}
  }
}
