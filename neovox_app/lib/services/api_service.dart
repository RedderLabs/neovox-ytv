import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class ApiService {
  static String get _baseUrl {
    if (kDebugMode && kIsWeb) return 'http://localhost:3000';
    if (kDebugMode) return 'http://10.0.2.2:3000'; // Android emulator
    return 'https://neovox-ytv-latest.onrender.com';
  }

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static String? accountNumber;

  static String _url(String path) => '$_baseUrl$path';

  static Map<String, String> get _authHeaders => {'X-Account-Number': accountNumber ?? ''};

  // ── Account ───────────────────────────────────────────────
  static Future<String> createAccount() async {
    final res = await _dio.post(_url('/api/account/create'));
    return res.data['accountNumber'];
  }

  static Future<bool> login(String number) async {
    try {
      final res = await _dio.post(_url('/api/account/login'),
          data: {'accountNumber': number},
          options: Options(headers: {'Content-Type': 'application/json'}));
      return res.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  static Future<void> deleteAccount() async {
    await _dio.delete(_url('/api/account'), options: Options(headers: _authHeaders));
  }

  // ── Playlists ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPlaylists() async {
    final res = await _dio.get(_url('/api/playlists'), options: Options(headers: _authHeaders));
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<Map<String, dynamic>> addPlaylist(String name, String ytId) async {
    final res = await _dio.post(_url('/api/playlists'),
        data: {'name': name, 'ytId': ytId},
        options: Options(headers: {..._authHeaders, 'Content-Type': 'application/json'}));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<void> deletePlaylist(String id) async {
    await _dio.delete(_url('/api/playlists/$id'), options: Options(headers: _authHeaders));
  }

  // ── Search & Discovery ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> search(String query, {int limit = 25}) async {
    final res = await _dio.get(_url('/api/search'), queryParameters: {'q': query, 'limit': limit});
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<List<Map<String, dynamic>>> trending() async {
    final res = await _dio.get(_url('/api/trending'));
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<Map<String, dynamic>> getPlaylistItems(String playlistId) async {
    final res = await _dio.get(_url('/api/playlist-items/$playlistId'));
    return Map<String, dynamic>.from(res.data);
  }

  // ── Audio ─────────────────────────────────────────────────
  static Future<String> getStreamUrl(String videoId) async {
    final res = await _dio.get(_url('/api/stream-url/$videoId'));
    final url = res.data['url'] as String;
    return '$_baseUrl/api/audio-proxy?url=${Uri.encodeComponent(url)}';
  }

  // ── Stats ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get(_url('/api/stats'));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<void> registerVisit() async {
    try {
      await _dio.post(_url('/api/visit'));
    } catch (_) {}
  }
}
