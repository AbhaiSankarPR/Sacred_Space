import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  late Dio _dio;
  final Dio _refreshDio = Dio(); 
  final _storage = const FlutterSecureStorage();
  
  Future<void> Function()? onSessionExpired;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
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
        if (e.response?.statusCode == 401 && e.requestOptions.path != "/user/refresh") {
          final newToken = await _refreshToken();
          if (newToken != null) {
            final options = e.requestOptions;
            options.headers["Authorization"] = "Bearer $newToken";
            return handler.resolve(await _dio.fetch(options));
          } else {
            if (onSessionExpired != null) await onSessionExpired!();
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<String?> _refreshToken() async {
    try {
      final response = await _refreshDio.post("${_dio.options.baseUrl}/user/refresh");
      if (response.statusCode == 200) {
        final newToken = response.data['accessToken'];
        await _storage.write(key: "token", value: newToken);
        return newToken;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Response> get(String url, {Map<String, dynamic>? params}) => _dio.get(url, queryParameters: params);
  Future<Response> post(String url, dynamic data) => _dio.post(url, data: data);
  Future<Response> put(String url, dynamic data) => _dio.put(url, data: data);
  Future<Response> delete(String url) => _dio.delete(url);
  Future<Response> patch(String url, dynamic data) => _dio.patch(url, data: data);
}

final apiService = ApiService();