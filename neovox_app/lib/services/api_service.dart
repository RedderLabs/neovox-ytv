import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class ApiService {
  static const _prodUrl = 'https://neovox-ytv-latest.onrender.com';
  static const _devUrlWeb = 'http://localhost:3000';
  static const _devUrlEmulator = 'http://10.0.2.2:3000';

  static String? _resolvedBase;

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static String? accountNumber;

  /// Tries dev URL first, falls back to prod if unreachable
  static Future<String> _getBaseUrl() async {
    if (_resolvedBase != null) return _resolvedBase!;

    if (!kDebugMode) {
      _resolvedBase = _prodUrl;
      return _resolvedBase!;
    }

    final devUrl = kIsWeb ? _devUrlWeb : _devUrlEmulator;
    try {
      await Dio().get('$devUrl/api/stats',
          options: Options(receiveTimeout: const Duration(seconds: 3)));
      _resolvedBase = devUrl;
      debugLog('API: usando $devUrl (local)');
    } catch (_) {
      _resolvedBase = _prodUrl;
      debugLog('API: local no disponible, usando $_prodUrl');
    }
    return _resolvedBase!;
  }

  static void debugLog(String msg) {
    if (kDebugMode) print(msg);
  }

  static Future<String> _url(String path) async => '${await _getBaseUrl()}$path';

  static Map<String, String> get _authHeaders => {'X-Account-Number': accountNumber ?? ''};

  // ── Account ───────────────────────────────────────────────
  static Future<String> createAccount() async {
    final res = await _dio.post(await _url('/api/account/create'));
    return res.data['accountNumber'];
  }

  static Future<bool> login(String number) async {
    try {
      final res = await _dio.post(await _url('/api/account/login'),
          data: {'accountNumber': number},
          options: Options(headers: {'Content-Type': 'application/json'}));
      return res.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  static Future<void> deleteAccount() async {
    await _dio.delete(await _url('/api/account'), options: Options(headers: _authHeaders));
  }

  // ── Playlists ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPlaylists() async {
    final res = await _dio.get(await _url('/api/playlists'), options: Options(headers: _authHeaders));
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<Map<String, dynamic>> addPlaylist(String name, String ytId) async {
    final res = await _dio.post(await _url('/api/playlists'),
        data: {'name': name, 'ytId': ytId},
        options: Options(headers: {..._authHeaders, 'Content-Type': 'application/json'}));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<void> deletePlaylist(String id) async {
    await _dio.delete(await _url('/api/playlists/$id'), options: Options(headers: _authHeaders));
  }

  // ── Search & Discovery ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> search(String query, {int limit = 25}) async {
    final res = await _dio.get(await _url('/api/search'), queryParameters: {'q': query, 'limit': limit});
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<List<Map<String, dynamic>>> trending() async {
    final res = await _dio.get(await _url('/api/trending'));
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<Map<String, dynamic>> getPlaylistItems(String playlistId) async {
    final res = await _dio.get(await _url('/api/playlist-items/$playlistId'));
    return Map<String, dynamic>.from(res.data);
  }

  // ── Stats ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get(await _url('/api/stats'));
    return Map<String, dynamic>.from(res.data);
  }

  static Future<void> registerVisit() async {
    try {
      await _dio.post(await _url('/api/visit'));
    } catch (_) {}
  }
}
