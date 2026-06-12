import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  late Dio _dio;
  final Dio _refreshDio = Dio();
  final _storage = const FlutterSecureStorage();
  late final PersistCookieJar _cookieJar;
  Future<String?>? _refreshFuture;
  Future<void>? _initFuture;

  Future<void> Function()? onSessionExpired;

  Future<void> init() async {
    if (_initFuture != null) return _initFuture;
    _initFuture = _init();
    return _initFuture;
  }

  Future<void> _init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${appDocDir.path}/.cookies/';
    _cookieJar = PersistCookieJar(storage: FileStorage(dirPath));
    _dio.interceptors.add(CookieManager(_cookieJar));
    _refreshDio.interceptors.add(CookieManager(_cookieJar));
  }

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _refreshDio.options.baseUrl = _dio.options.baseUrl;
    _refreshDio.options.connectTimeout = _dio.options.connectTimeout;
    _refreshDio.options.receiveTimeout = _refreshDio.options.receiveTimeout;

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip token for public endpoints like fetching churches
          if (options.path != '/churches') {
            final token = await _storage.read(key: "token");
            if (token != null) {
              options.headers["Authorization"] = "Bearer $token";
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              e.requestOptions.path != "/auth/refresh") {
            final currentToken = await _storage.read(key: "token");
            final requestToken = e.requestOptions.headers["Authorization"]
                ?.toString()
                .replaceFirst("Bearer ", "");

            String? newToken;
            if (currentToken != null && currentToken != requestToken) {
              newToken = currentToken;
            } else {
              newToken = await _refreshToken();
            }

            if (newToken != null) {
              final options = e.requestOptions;
              options.headers["Authorization"] = "Bearer $newToken";
              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (retryError) {
                if (retryError is DioException) {
                  return handler.next(retryError);
                }
                return handler.reject(
                  DioException(requestOptions: options, error: retryError),
                );
              }
            } else {
              if (onSessionExpired != null) await onSessionExpired!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<String?> _refreshToken() {
    _refreshFuture ??= _performTokenRefresh();
    return _refreshFuture!;
  }

  Future<String?> _performTokenRefresh() async {
    try {
      final response = await _refreshDio.post('/auth/refresh');
      if (response.statusCode == 200) {
        final newToken = response.data['accessToken'];
        await _storage.write(key: "token", value: newToken);
        return newToken;
      }
    } catch (e) {
      debugPrint("Token refresh failed: $e");
      return null;
    } finally {
      _refreshFuture = null;
    }
    return null;
  }

  Future<Response> get(
    String url, {
    Map<String, dynamic>? params,
    Options? options,
  }) => _dio.get(url, queryParameters: params, options: options);
  Future<Response> post(String url, dynamic data) => _dio.post(url, data: data);
  Future<Response> put(String url, dynamic data) => _dio.put(url, data: data);
  Future<Response> delete(String url, {dynamic data}) =>
      _dio.delete(url, data: data);
  Future<Response> patch(String url, dynamic data) =>
      _dio.patch(url, data: data);
}

final apiService = ApiService();
