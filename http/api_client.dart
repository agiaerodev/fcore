import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

class ApiClient {
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  VoidCallback? onUnauthorized;
  bool _isHandlingUnauthorized = false;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final CacheOptions cacheOptions;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    final apiRoute = dotenv.env['API_ROUTE'] ?? '';
    cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.forceCache,
      priority: CachePriority.normal,
      maxStale: const Duration(hours: 1),
    );

    dio = Dio(
      BaseOptions(
        baseUrl: '$apiRoute/api',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: onRequest,
        onError: onError,
      ),
    );
  }

  // ========================
  // Interceptors
  // ========================

  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = '$token';
      _logger.i('TOKEN COMPLETO => $token');
    }

    return handler.next(options);
  }

  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    _logger.w("wilmer error 71: ${err}");
    if (err.response?.statusCode == 401) {
      _logger.w("401 Unauthorized: ${err.response}");
      deleteTokens();
      if (!_isHandlingUnauthorized) {
        setHandlingUnauthorized(true);
        onUnauthorized?.call();
      }

      return handler.reject(err);
    }

    return handler.next(err);
  }

  // ========================
  // Token Handling
  // ========================

  Future<void> saveToken(
      String accessToken,
      DateTime expiresAt,
      ) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(
      key: 'expiresAt',
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  Future<void> deleteTokens() async {// Resetear flag al eliminar tokens
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'expiresAt');
    await clearCache();
  }

  Future<bool> refreshToken() async {
    try {
      final response = await dio.post('/profile/v1/auth/refresh-token');

      final data = response.data;

      final String? accessToken = data['accessToken'];
      final String? expiresIso = data['expiresIn'];

      if (accessToken == null || expiresIso == null) {
        throw Exception('Invalid refresh token response');
      }

      final expirationDate = DateTime.parse(expiresIso).toUtc();

      await saveToken(accessToken, expirationDate);

      return true;
    } catch (e) {
      await deleteTokens();
      return false;
    }
  }

  Future<bool> isTokenExpired() async {
    final expiresAtStr = await _storage.read(key: 'expiresIn');
    if (expiresAtStr == null) return true;

    final expiresIn =
    DateTime.fromMillisecondsSinceEpoch(int.parse(expiresAtStr));

    return DateTime.now().isAfter(expiresIn);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'accessToken');
  }
  Future<void> clearCache() async {
    await cacheOptions.store?.clean();
    _logger.i("Caché de API eliminado correctamente");
  }
  void setHandlingUnauthorized(bool value) {
    _isHandlingUnauthorized = value;
  }
}