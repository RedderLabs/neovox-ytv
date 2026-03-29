import 'package:dio/dio.dart';
import '../models/playlist.dart';

class ApiService {
  final Dio _dio;
  String? _accountNumber;

  // Cambiar a tu URL de producción
  static const String baseUrl = 'https://neovox-ytv-latest.onrender.com';

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  void setAccount(String accountNumber) {
    _accountNumber = accountNumber;
    _dio.options.headers['X-Account-Number'] = accountNumber;
  }

  String? get accountNumber => _accountNumber;

  // ── Auth ──
  Future<String> createAccount() async {
    final res = await _dio.post('/api/account/create');
    return res.data['accountNumber'] as String;
  }

  Future<bool> login(String accountNumber) async {
    try {
      await _dio.post('/api/account/login',
          data: {'accountNumber': accountNumber});
      setAccount(accountNumber);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  // ── Playlists ──
  Future<List<Playlist>> getPlaylists() async {
    final res = await _dio.get('/api/playlists');
    return (res.data as List)
        .map((j) => Playlist.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Playlist> addPlaylist(String name, String ytId) async {
    final res = await _dio.post('/api/playlists', data: {
      'name': name,
      'ytId': ytId,
    });
    return Playlist.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deletePlaylist(String id) async {
    await _dio.delete('/api/playlists/$id');
  }
}
