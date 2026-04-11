import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class ApiService {
  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        // For FormData uploads, remove the default 'application/json'
        // Content-Type so the browser (web) or Dio (native) can auto-set
        // 'multipart/form-data; boundary=...' with the correct boundary.
        if (options.data is FormData) {
          options.headers.remove('Content-Type');
          final fd = options.data as FormData;
          debugPrint('[ApiService] FormData upload: ${fd.files.length} files, '
              'boundary=${fd.boundary}');
          for (final f in fd.files) {
            debugPrint('[ApiService]   part name="${f.key}" '
                'filename="${f.value.filename}" '
                'contentType=${f.value.contentType}');
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          debugPrint('[ApiService] 401 Unauthorized — token may be expired');
        }
        return handler.next(error);
      },
    ));
  }

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  // ── GET ───────────────────────────────────────────
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // ── POST ──────────────────────────────────────────
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  // ── PATCH ─────────────────────────────────────────
  Future<Response> patch(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    return _dio.patch(
      path,
      data: data,
      cancelToken: cancelToken,
    );
  }

  // ── DELETE ────────────────────────────────────────
  Future<Response> delete(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete(
      path,
      data: data,
      cancelToken: cancelToken,
    );
  }

  // ── Multipart Upload ─────────────────────────────
  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    return _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
  }
}
