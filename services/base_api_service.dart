import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../http/api_client.dart';
import '../utils/helpers.dart';

class BaseApiService {
  final Dio _dio = ApiClient().dio;

  Options _buildOptions(Map<String, dynamic>? config) {
    final bool refresh = config?['refresh'] ?? false;

    return ApiClient().cacheOptions
        .copyWith(
          // Si refresh es true -> CachePolicy.refreshForceCache (obliga al backend)
          // Si refresh es false -> CachePolicy.forceCache (usa cache si tiene < 1 hora)
          policy: refresh
              ? CachePolicy.refreshForceCache
              : CachePolicy.forceCache,
        )
        .toOptions()
        ..connectTimeout = const Duration(seconds: 10)
        ..receiveTimeout = const Duration(seconds: 15)
        ..sendTimeout = const Duration(seconds: 15);
  }

  // ========== INDEX ==========
  Future<dynamic> index(String route, {Map<String, dynamic>? config}) async {
    try {
      final Map<String, dynamic> params = Map.from(config?['params'] ?? {});

      if (params.containsKey('filter') && params['filter'] is Map) {
        params['filter'] = jsonEncode(params['filter']);
      }

      final res = await _dio.get(
        route,
        queryParameters: params.isNotEmpty ? params : null,
        options: _buildOptions(config),
      );

      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      rethrow;
    }
  }

  // ========== GET ==========
  Future<dynamic> get(
    String route, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? data,
    Map<String, dynamic>? config,
  }) async {
    try {
      final finalRoute = replaceParamsApiRoute(route, data ?? {});
      final queryParams = params ?? config?['params'];

      final res = await _dio.get(
        finalRoute,
        queryParameters: queryParams,
        options: _buildOptions(config),
      );
      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<dynamic> create(String route, Map<String, dynamic> data) async {
    final snakeData = toSnakeCaseMap(data);
    final res = await _dio.post(route, data: {'attributes': snakeData});
    return res.data;
  }

  Future<dynamic> post(String route, Map<String, dynamic> data) async {
    try {
      final snakeData = toSnakeCaseMap(data);
      final finalRoute = replaceParamsApiRoute(route, data);
      print(finalRoute);
      print(snakeData);
      final res = await _dio.post(finalRoute, data: snakeData);
      print(res);
      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<dynamic> patch(
    String route,
    Map<String, dynamic> data, {
    Map<String, dynamic>? config,
  }) async {
    try {
      final snakeData = toSnakeCaseMap(data);
      final finalRoute = replaceParamsApiRoute(route, data);
      final res = await _dio.patch(
        finalRoute,
        data: snakeData,
        options: _buildOptions(config),
      );
      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<dynamic> postRaw(
    String route,
    dynamic data, {
    Map<String, dynamic>? config,
  }) async {
    try {
      final res = await _dio.post(
        route,
        data: toSnakeCaseDeep(data),
        options: _buildOptions(config),
      );
      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<dynamic> putRaw(
    String route,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _dio.put(
        route,
        data: data,
        options: Options(headers: headers),
      );
      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ========== UPDATE ==========
  Future<dynamic> update(
      String route,
      dynamic id,
      Map<String, dynamic> data, {
        Map<String, dynamic>? config,
      }) async {
    try {
      final snakeData = toSnakeCaseMap(data);

      final res = await _dio.put(
        '$route/$id',
        data: {'attributes': snakeData},
        options: _buildOptions(config),
      );

      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

// ========== SHOW ==========
  Future<dynamic> show(
      String route, [
        dynamic id,
        Map<String, dynamic>? config,
      ]) async {
    try {
      final Map<String, dynamic> params = Map.from(config?['params'] ?? {});

      final url = id != null ? '$route/$id' : route;

      if (params.containsKey('filter') && params['filter'] is Map) {
        params['filter'] = jsonEncode(params['filter']);
      }

      final res = await _dio.get(
        url,
        queryParameters: params.isNotEmpty ? params : null,
        options: _buildOptions(config),
      );

      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      print("--- ❌ Unexpected Error ---");
      print(e);
      rethrow;
    }
  }

// ========== DELETE ==========
  Future<dynamic> delete(
      String route,
      dynamic id, {
        Map<String, dynamic>? config,
      }) async {
    try {
      final res = await _dio.delete(
        '$route/$id',
        options: _buildOptions(config),
      );

      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Never _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        throw Exception('Connection timeout');

      case DioExceptionType.sendTimeout:
        throw Exception('Send timeout');

      case DioExceptionType.receiveTimeout:
        throw Exception('Receive timeout');

      case DioExceptionType.badCertificate:
        throw Exception('Bad SSL certificate');

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;

        String errorMsg = 'Server error';
        if (data is Map) {
          final messages = data['messages'];
          if (messages is List && messages.isNotEmpty) {
            final first = messages.first;
            if (first is Map && first['message'] is String) {
              errorMsg = first['message'] as String;
            }
          }
        } else if (data != null) {
          errorMsg = data.toString();
        }

        throw Exception('HTTP $status - $errorMsg');

      case DioExceptionType.cancel:
        throw Exception('Request cancelled');

      case DioExceptionType.connectionError:
        throw Exception('No internet connection');

      case DioExceptionType.unknown:
      default:
        throw Exception(
          e.message ?? 'Unknown error',
        );
    }
  }
}
