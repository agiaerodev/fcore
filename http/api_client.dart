import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../models/impersonation_session.dart';

enum TokenRefreshResult {
  success,
  /// The backend (or a locally expired/missing refresh token) definitively
  /// rejected the session. Tokens have been deleted.
  rejected,
  /// The refresh could not reach the backend (no internet, timeout, 5xx...).
  /// Tokens are preserved so the session survives until connectivity returns.
  unavailable,
}

/// Returns true when [error] means the backend could not be reached or did not
/// give a definitive answer (offline, timeout, 5xx). In these cases the local
/// session must be preserved.
bool isNetworkOrServerUnavailableError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.cancel:
        return true;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        return status >= 500 || status == 408 || status == 429;
      case DioExceptionType.unknown:
        return error.response == null;
      case DioExceptionType.badCertificate:
        return false;
    }
  }

  // BaseApiService converts DioExceptions into plain Exceptions.
  final message = error.toString().toLowerCase();
  final httpStatus = RegExp(r'http (\d{3})').firstMatch(message);
  if (httpStatus != null) {
    final status = int.parse(httpStatus.group(1)!);
    return status >= 500 || status == 408 || status == 429;
  }
  return message.contains('no internet connection') ||
      message.contains('timeout') ||
      message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('network is unreachable') ||
      message.contains('connection error') ||
      message.contains('request cancelled');
}

class ApiClient {
  static const _tokenRefreshBuffer = Duration(seconds: 30);

  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  VoidCallback? onUnauthorized;
  bool _isHandlingUnauthorized = false;
  Future<TokenRefreshResult>? _refreshingToken;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      migrateOnAlgorithmChange: true,
      migrateWithBackup: true,
      resetOnError: false,
    ),
  );

  // In-memory copy of the access token and its expiration, so requests don't
  // hit SecureStorage every time. ApiClient is the only writer of these keys,
  // so saveToken()/deleteTokens() keep it in sync.
  String? _accessToken;
  DateTime? _expiresAt;
  Future<void>? _sessionLoad;
  int _sessionVersion = 0;
  int _identityVersion = 0;
  bool _isChangingIdentity = false;
  Map<String, dynamic>? _impersonation;
  Future<void> _impersonationWrites = Future<void>.value();
  static const _impersonationKey = 'impersonationSession';

  bool get isImpersonating => _impersonation != null;
  int get identityVersion => _identityVersion;

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

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: onRequest,
        onResponse: (response, handler) {
          if (_isStaleRequest(response.requestOptions)) {
            handler.reject(_identityChangedError(response.requestOptions));
          } else {
            handler.next(response);
          }
        },
        onError: onError,
      ),
    );
    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  }

  // ========================
  // Interceptors
  // ========================

  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra.putIfAbsent('identityVersion', () => _identityVersion);
    if (_isChangingIdentity || _isStaleRequest(options)) {
      handler.reject(_identityChangedError(options));
      return;
    }
    var token = await getToken();
    if (token != null &&
        token.isNotEmpty &&
        options.extra['skipTokenRefresh'] != true &&
        await _isTokenExpiringSoon()) {
      final result = await refreshTokenWithResult();
      if (result == TokenRefreshResult.rejected) {
        _notifyUnauthorized();
        handler.reject(
          DioException(
            requestOptions: options,
            message: 'Unable to refresh the access token',
          ),
        );
        return;
      }
      if (result == TokenRefreshResult.unavailable) {
        // Keep the session: the backend could not be reached.
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'No internet connection',
          ),
        );
        return;
      }
      token = await getToken();
    }

    if (_isChangingIdentity || _isStaleRequest(options)) {
      handler.reject(_identityChangedError(options));
      return;
    }
    if (token != null &&
        token.isNotEmpty &&
        !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = token;
    }

    return handler.next(options);
  }

  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isStaleRequest(err.requestOptions)) {
      return handler.reject(_identityChangedError(err.requestOptions));
    }
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;
      final canRetry =
          requestOptions.extra['skipTokenRefresh'] != true &&
          requestOptions.extra['retriedAfterRefresh'] != true;

      final refreshResult = canRetry
          ? await refreshTokenWithResult()
          : TokenRefreshResult.rejected;

      if (_isStaleRequest(requestOptions)) {
        return handler.reject(_identityChangedError(requestOptions));
      }
      if (refreshResult == TokenRefreshResult.unavailable) {
        // The refresh endpoint is unreachable; don't destroy the session.
        return handler.reject(
          DioException(
            requestOptions: requestOptions,
            type: DioExceptionType.connectionError,
            message: 'No internet connection',
          ),
        );
      }

      if (refreshResult == TokenRefreshResult.success) {
        try {
          final newToken = await getToken();
          requestOptions.extra['retriedAfterRefresh'] = true;
          if (newToken != null && newToken.isNotEmpty) {
            requestOptions.headers['Authorization'] = newToken;
          } else {
            requestOptions.headers.remove('Authorization');
          }
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          if (retryError.response?.statusCode == 401) {
            _notifyUnauthorized();
            return handler.reject(retryError);
          }
          return handler.next(retryError);
        }
      }

      _notifyUnauthorized();
      return handler.reject(err);
    }

    return handler.next(err);
  }

  void _notifyUnauthorized() {
    if (_isHandlingUnauthorized) return;
    setHandlingUnauthorized(true);
    onUnauthorized?.call();
  }

  bool _isStaleRequest(RequestOptions options) =>
      options.extra['identityVersion'] != _identityVersion;

  DioException _identityChangedError(RequestOptions options) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    message: 'Session identity changed',
  );

  // ========================
  // Token Handling
  // ========================

  Future<void> saveToken(
    String accessToken,
    DateTime expiresAt, {
    String? refreshToken,
    DateTime? refreshExpiresAt,
  }) async {
    if (isImpersonating) {
      await _updateImpersonation({
        'accessToken': accessToken,
        'expiresIn': expiresAt.toUtc().toIso8601String(),
        if (refreshToken != null) 'refreshToken': refreshToken,
        if (refreshExpiresAt != null)
          'refreshExpiresIn': refreshExpiresAt.toUtc().toIso8601String(),
      });
      _setSession(accessToken, expiresAt.toUtc());
      return;
    }
    // Memory first: in-flight requests use the new token right away.
    _setSession(accessToken, expiresAt.toUtc());
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(
      key: 'expiresIn',
      value: expiresAt.toUtc().toIso8601String(),
    );
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: 'refreshToken', value: refreshToken);
    }
    if (refreshExpiresAt != null) {
      await _storage.write(
        key: 'refreshExpiresIn',
        value: refreshExpiresAt.toUtc().toIso8601String(),
      );
    }
  }

  Future<void> deleteTokens() async {
    if (isImpersonating) {
      // Only invalidate the temporary token. The original credentials remain
      // untouched until AuthProvider restores the original user.
      _setSession(null, null);
      return;
    }
    // Memory first: stop sending the token even if a delete fails.
    _setSession(null, null);
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'expiresIn');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'refreshExpiresIn');
    await _storage.delete(key: _cachedUserKey);
    await clearCache();
  }

  // ========================
  // Cached user (offline session restore)
  // ========================

  static const _cachedUserKey = 'cachedUser';

  Future<void> saveCachedUser(Map<String, dynamic> user) async {
    try {
      if (isImpersonating) {
        await _updateImpersonation({_cachedUserKey: user});
        return;
      }
      await _storage.write(key: _cachedUserKey, value: jsonEncode(user));
    } catch (e) {
      _logger.w('Unable to cache user data', error: e);
    }
  }

  Future<Map<String, dynamic>?> readCachedUser() async {
    try {
      await _ensureSessionLoaded();
      if (isImpersonating) {
        return Map<String, dynamic>.from(
          _impersonation![_cachedUserKey] as Map,
        );
      }
      final raw = await _storage.read(key: _cachedUserKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (e) {
      _logger.w('Unable to read cached user data', error: e);
      return null;
    }
  }

  Future<bool> refreshToken() async =>
      await refreshTokenWithResult() == TokenRefreshResult.success;

  Future<TokenRefreshResult> refreshTokenWithResult() async {
    if (_isChangingIdentity) return TokenRefreshResult.unavailable;
    final activeRefresh = _refreshingToken;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _refreshToken();
    _refreshingToken = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshingToken, refresh)) {
        _refreshingToken = null;
      }
    });
  }

  Future<TokenRefreshResult> _refreshToken() async {
    try {
      final refreshToken = await _readSessionValue('refreshToken');
      final refreshExpiresAt = await _readSessionValue('refreshExpiresIn');
      final parsedRefreshExpiration = DateTime.tryParse(
        refreshExpiresAt ?? '',
      )?.toUtc();
      if (refreshToken == null ||
          refreshToken.isEmpty ||
          parsedRefreshExpiration == null ||
          !parsedRefreshExpiration.isAfter(DateTime.now().toUtc())) {
        await deleteTokens();
        return TokenRefreshResult.rejected;
      }

      final currentAccessToken = await getToken() ?? '';
      final bearerRefreshToken = refreshToken.startsWith('Bearer ')
          ? refreshToken
          : 'Bearer $refreshToken';

      final response = await dio.post(
        '/profile/v1/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {'skipTokenRefresh': true},
          headers: {
            'x-bearer-token': currentAccessToken,
            'Authorization': bearerRefreshToken,
          },
        ),
      );

      final responseData = response.data;
      final data = responseData is Map && responseData['data'] is Map
          ? responseData['data']
          : responseData;

      if (data is! Map) {
        throw Exception('Invalid refresh token response');
      }
      final accessToken = data['userToken'] as String?;
      final expiresIso = data['expiresIn'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;
      final refreshExpiresIso = data['refreshExpiresIn'] as String?;

      if (accessToken == null || expiresIso == null) {
        throw Exception('Invalid refresh token response');
      }

      final expirationDate = DateTime.parse(expiresIso).toUtc();
      final refreshExpirationDate = refreshExpiresIso == null
          ? null
          : DateTime.parse(refreshExpiresIso).toUtc();
      await saveToken(
        accessToken,
        expirationDate,
        refreshToken: newRefreshToken ?? refreshToken,
        refreshExpiresAt: refreshExpirationDate ?? parsedRefreshExpiration,
      );

      return TokenRefreshResult.success;
    } catch (e) {
      if (isNetworkOrServerUnavailableError(e)) {
        _logger.w('Token refresh unavailable (offline/server). Keeping session.',
            error: e);
        return TokenRefreshResult.unavailable;
      }
      _logger.e('Token refresh failed', error: e);
      await deleteTokens();
      return TokenRefreshResult.rejected;
    }
  }

  Future<bool> isTokenExpired() async {
    await _ensureSessionLoaded();
    final expiresAt = _expiresAt;
    if (expiresAt == null) return true;

    return DateTime.now().toUtc().isAfter(expiresAt);
  }

  Future<bool> _isTokenExpiringSoon() async {
    await _ensureSessionLoaded();
    final expiresAt = _expiresAt;
    if (expiresAt == null) return true;

    final refreshDeadline = DateTime.now().toUtc().add(_tokenRefreshBuffer);
    return !expiresAt.isAfter(refreshDeadline);
  }

  Future<String?> getToken() async {
    await _ensureSessionLoaded();
    return _accessToken;
  }

  /// Loads the session from SecureStorage only once. If the read fails
  /// (e.g. iOS Keychain locked), it is not memoized so the next call retries.
  Future<void> _ensureSessionLoaded() {
    final pending = _sessionLoad;
    if (pending != null) return pending;

    final load = _loadSession();
    _sessionLoad = load;
    load.catchError((_) {
      if (identical(_sessionLoad, load)) _sessionLoad = null;
    });
    return load;
  }

  Future<void> _loadSession() async {
    final version = _sessionVersion;
    final temporary = await _storage.read(key: _impersonationKey);
    if (version != _sessionVersion) return;
    if (temporary != null) {
      final session = Map<String, dynamic>.from(jsonDecode(temporary) as Map);
      final token = session['accessToken'] as String;
      final expiresAt = DateTime.parse(session['expiresIn'] as String).toUtc();
      if (session[_cachedUserKey] is! Map || session['originalUser'] is! Map) {
        throw const FormatException('Invalid stored impersonation session.');
      }
      _impersonation = session;
      _accessToken = token;
      _expiresAt = expiresAt;
      return;
    }
    final token = await _storage.read(key: 'accessToken');
    final expiresAtStr = await _storage.read(key: 'expiresIn');
    // saveToken()/deleteTokens() ran during the read: their value wins.
    if (version != _sessionVersion) return;

    _accessToken = token;
    _expiresAt = DateTime.tryParse(expiresAtStr ?? '')?.toUtc();
  }

  void _setSession(String? token, DateTime? expiresAt) {
    _sessionVersion++;
    _accessToken = token;
    _expiresAt = expiresAt;
    _sessionLoad = Future.value();
  }

  Future<String?> _readSessionValue(String key) async {
    await _ensureSessionLoaded();
    return isImpersonating
        ? _impersonation![key] as String?
        : _storage.read(key: key);
  }

  Future<void> _updateImpersonation(Map<String, dynamic> updates) {
    final identity = _identityVersion;
    final write = _impersonationWrites.then((_) async {
      if (_isChangingIdentity ||
          identity != _identityVersion ||
          !isImpersonating) {
        throw StateError('The impersonation session has changed.');
      }
      final session = {..._impersonation!, ...updates};
      await _storage.write(key: _impersonationKey, value: jsonEncode(session));
      _impersonation = session;
    });
    _impersonationWrites = write.onError((Object error, StackTrace stack) {
      _logger.e(
        'Unable to persist impersonation',
        error: error,
        stackTrace: stack,
      );
    });
    return write;
  }

  Future<void> beginImpersonation(
    ImpersonationSession session,
    Map<String, dynamic> originalUser,
  ) => _changeIdentity(() async {
    if (isImpersonating) {
      throw StateError('End the current impersonation before starting another.');
    }
    if (_accessToken == null) {
      throw StateError('The original session is not available.');
    }
    final temporary = <String, dynamic>{
      'accessToken': session.token,
      'expiresIn': session.expiresAt.toIso8601String(),
      'refreshToken': session.refreshToken,
      'refreshExpiresIn': session.refreshExpiresAt?.toIso8601String(),
      _cachedUserKey: session.user,
      'originalUser': originalUser,
    };
    // A separate atomic record preserves every original credential and context.
    await _storage.write(key: _impersonationKey, value: jsonEncode(temporary));
    _impersonation = temporary;
    _setSession(session.token, session.expiresAt);
  });

  Future<Map<String, dynamic>> endImpersonation() => _changeIdentity(() async {
    if (!isImpersonating) {
      throw StateError('There is no active impersonation.');
    }
    final user = Map<String, dynamic>.from(
      _impersonation!['originalUser'] as Map,
    );
    final token = await _storage.read(key: 'accessToken');
    final expiration = await _storage.read(key: 'expiresIn');
    if (token == null || expiration == null) {
      throw StateError('The original session is not available.');
    }
    final expiresAt = DateTime.parse(expiration).toUtc();
    await _storage.delete(key: _impersonationKey);
    _impersonation = null;
    _setSession(token, expiresAt);
    return user;
  });

  Future<T> _changeIdentity<T>(Future<T> Function() change) async {
    await _ensureSessionLoaded();
    final refresh = _refreshingToken;
    if (refresh != null) await refresh;
    if (_isChangingIdentity) {
      throw StateError('A session change is already in progress.');
    }
    _isChangingIdentity = true;
    try {
      await _impersonationWrites;
      await clearCache();
      final result = await change();
      _identityVersion++;
      setHandlingUnauthorized(false);
      return result;
    } finally {
      _isChangingIdentity = false;
    }
  }

  Future<void> clearCache() async {
    await cacheOptions.store?.clean();
  }

  void setHandlingUnauthorized(bool value) {
    _isHandlingUnauthorized = value;
  }
}
